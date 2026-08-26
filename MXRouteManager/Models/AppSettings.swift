//
//  AppSettings.swift
//  MXRouteManager
//
//  Single observable source of truth for MXRoute credentials: server
//  hostname and DirectAdmin username persist via @AppStorage, while
//  whether an API key exists is tracked as a stored flag mutated by
//  saveAPIKey/removeAPIKey. The API key itself is never held here —
//  it lives only in the Keychain (via KeychainService).
//

import SwiftUI
import Foundation

@Observable
final class AppSettings {
    enum Keys {
        static let serverHostname = "mxroute.serverHostname"
        static let username = "mxroute.username"
    }

    @ObservationIgnored @AppStorage(Keys.serverHostname) private var storedServerHostname: String = ""
    @ObservationIgnored @AppStorage(Keys.username) private var storedUsername: String = ""

    private let keychain: KeychainService

    private(set) var hasAPIKey: Bool

    init(store: UserDefaults = .standard, keychain: KeychainService = .shared) {
        _storedServerHostname = AppStorage(wrappedValue: "", Keys.serverHostname, store: store)
        _storedUsername = AppStorage(wrappedValue: "", Keys.username, store: store)
        self.keychain = keychain
        self.hasAPIKey = keychain.hasKey
    }

    var serverHostname: String {
        get { access(keyPath: \.serverHostname); return storedServerHostname }
        set { withMutation(keyPath: \.serverHostname) { storedServerHostname = newValue } }
    }

    var username: String {
        get { access(keyPath: \.username); return storedUsername }
        set { withMutation(keyPath: \.username) { storedUsername = newValue } }
    }

    var isConfigured: Bool {
        !serverHostname.trimmed.isEmpty && !username.trimmed.isEmpty && hasAPIKey
    }

    func saveAPIKey(_ key: String) throws {
        try keychain.save(key.trimmed)
        hasAPIKey = true
    }

    func removeAPIKey() throws {
        try keychain.delete()
        hasAPIKey = false
    }

    func normalize() {
        serverHostname = serverHostname.trimmed
        username = username.trimmed
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
