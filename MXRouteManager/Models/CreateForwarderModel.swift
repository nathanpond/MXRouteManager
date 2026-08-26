//
//  CreateForwarderModel.swift
//  MXRouteManager
//
//  The observable state machine behind the create-forwarder popover: domain
//  loading, the persisted last-selected domain, per-domain mailbox loading
//  (cached, cancellation-safe), alias validation, and submission against the
//  real MXRouteClient. The view (plan 04-02) renders this and contains no
//  logic of its own.
//

import SwiftUI
import Foundation

/// The state of an asynchronously loaded value. `.failed` always carries
/// already-user-facing text, never a raw `Error` — the view can render it
/// directly.
enum LoadState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

/// The state of the submit action.
enum SubmitState: Equatable {
    case idle
    case submitting
    case succeeded(Forwarder)
    case failed(String)
}

@Observable
@MainActor
final class CreateForwarderModel {
    enum Keys {
        static let lastDomain = "mxroute.lastDomain"
    }

    private let settings: AppSettings
    private let makeClient: @MainActor (AppSettings) -> MXRouteClient

    @ObservationIgnored @AppStorage(Keys.lastDomain) private var storedLastDomain: String = ""

    private(set) var domains: LoadState<[String]> = .idle
    private(set) var accounts: LoadState<[EmailAccount]> = .idle
    private(set) var submitState: SubmitState = .idle
    var aliasInput: String = ""
    var selectedDestination: String = ""

    /// Which credentials the cached `domains` were fetched with. Reloading on
    /// change is what stops a domain list fetched with the old API key from
    /// surviving a credential edit in Settings.
    @ObservationIgnored private var loadedFingerprint: String?
    @ObservationIgnored private var accountsCache: [String: [EmailAccount]] = [:]

    init(settings: AppSettings, makeClient: (@MainActor (AppSettings) -> MXRouteClient)? = nil) {
        self.settings = settings
        self.makeClient = makeClient ?? { MXRouteClient.live(settings: $0) }
    }

    // MARK: - Persisted selection

    var selectedDomain: String {
        get { access(keyPath: \.selectedDomain); return storedLastDomain }
        set { withMutation(keyPath: \.selectedDomain) { storedLastDomain = newValue } }
    }

    // MARK: - Derived state

    var aliasValidation: AliasValidation { AliasValidator.validate(aliasInput) }

    /// The address as it will actually exist, for the live preview under the field.
    var previewAddress: String? {
        guard let alias = aliasValidation.normalizedAlias, !selectedDomain.isEmpty else { return nil }
        return "\(alias)@\(selectedDomain)"
    }

    var canSubmit: Bool {
        aliasValidation.normalizedAlias != nil
            && !selectedDomain.isEmpty
            && !selectedDestination.isEmpty
            && submitState != .submitting
    }

    /// Never includes the API key itself — it is not in `AppSettings` and
    /// must never be.
    private var credentialFingerprint: String {
        "\(settings.serverHostname)|\(settings.username)|\(settings.hasAPIKey)"
    }

    // MARK: - Loading

    func loadDomains(force: Bool = false) async {
        let fingerprint = credentialFingerprint

        if !force, case .loaded = domains, loadedFingerprint == fingerprint {
            // Early return is what makes the second popover open instant;
            // without it every open re-hits the network.
            return
        }

        if loadedFingerprint != fingerprint {
            // Mailboxes fetched under other credentials are meaningless.
            accountsCache = [:]
        }

        domains = .loading
        do {
            let list = try await makeClient(settings).listDomains()
            guard !Task.isCancelled else { return }
            loadedFingerprint = fingerprint
            domains = .loaded(list)
            reconcileSelectedDomain(with: list)
        } catch {
            guard !Task.isCancelled else { return }
            domains = .failed(Self.message(for: error))
        }
    }

    /// Stops a remembered domain that has since been removed from MXRoute
    /// (or a first-ever launch with "") from leaving the picker bound to a
    /// value that is not in its options — SwiftUI renders that as a blank
    /// picker with no way out.
    private func reconcileSelectedDomain(with list: [String]) {
        if list.isEmpty {
            selectedDomain = ""
        } else if !list.contains(selectedDomain) {
            selectedDomain = list[0]
        }
    }

    func loadAccounts(for domain: String, force: Bool = false) async {
        guard !domain.isEmpty else {
            accounts = .idle
            selectedDestination = ""
            return
        }

        if !force, let cached = accountsCache[domain] {
            accounts = .loaded(cached)
            reconcileDestination(with: cached)
            return
        }

        accounts = .loading
        // A destination from the previous domain must never survive a
        // domain switch — submitting it would forward to a mailbox on a
        // different domain.
        selectedDestination = ""

        do {
            let list = try await makeClient(settings).listEmailAccounts(domain: domain)
            // Both guards are required: Task.isCancelled covers the
            // fast-switch case via .task(id:) cancellation, and the
            // domain == selectedDomain check covers a response that lands
            // after a re-selection the task-id did not distinguish.
            guard !Task.isCancelled, domain == selectedDomain else { return }
            accountsCache[domain] = list
            accounts = .loaded(list)
            reconcileDestination(with: list)
        } catch {
            guard !Task.isCancelled, domain == selectedDomain else { return }
            accounts = .failed(Self.message(for: error))
        }
    }

    /// The client already returns accounts sorted by address, so `.first` is
    /// deterministic; do NOT re-sort here.
    private func reconcileDestination(with list: [EmailAccount]) {
        let addresses = list.map(\.email)
        if selectedDestination.isEmpty || !addresses.contains(selectedDestination) {
            selectedDestination = list.first?.email ?? ""
        }
    }

    // MARK: - Submit

    func submit() async {
        guard canSubmit, let alias = aliasValidation.normalizedAlias else { return }
        // Captured into locals first so a mid-flight selection change cannot
        // rewrite what gets reported.
        let domain = selectedDomain
        let destination = selectedDestination
        submitState = .submitting
        do {
            // A create is a side effect that already happened on the server;
            // this deliberately does NOT check Task.isCancelled — swallowing
            // the result would leave the user unsure whether the forwarder
            // exists.
            let forwarder = try await makeClient(settings).createForwarder(
                domain: domain, alias: alias, destinations: [destination]
            )
            submitState = .succeeded(forwarder)
        } catch {
            submitState = .failed(Self.message(for: error))
        }
    }

    /// The "Create Another" action. Deliberately KEEPS `selectedDomain` and
    /// `selectedDestination` — the overwhelmingly common repeat case is
    /// another alias on the same domain going to the same mailbox.
    func reset() {
        aliasInput = ""
        submitState = .idle
    }

    private static func message(for error: Error) -> String {
        (error as? MXRouteError)?.errorDescription ?? error.localizedDescription
    }
}
