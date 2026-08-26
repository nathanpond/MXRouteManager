//
//  MenuBarContentView.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CreateForwarderModel.self) private var model
    @FocusState private var aliasFocused: Bool

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 12) {
            Text("New Forwarder")
                .font(.headline)

            if settings.isConfigured {
                formSection            // Task 2
                actionSection          // Task 3
            } else {
                unconfiguredSection
            }

            Divider()
            footer
        }
        .padding(16)
        .frame(width: 320)
        .task {
            guard settings.isConfigured else { return }
            await model.loadDomains()
        }
        .task(id: model.selectedDomain) {
            guard settings.isConfigured else { return }
            await model.loadAccounts(for: model.selectedDomain)
        }
        .onChange(of: model.domains) {
            if case .loaded(let domains) = model.domains, !domains.isEmpty, model.submitState == .idle {
                aliasFocused = true
            }
        }
    }

    private var formSection: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            domainField
            aliasField
            destinationField
        }
    }

    private var domainField: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 4) {
            Label("Domain", systemImage: "globe")
                .font(.caption)
                .foregroundStyle(.secondary)
            switch model.domains {
            case .idle, .loading:
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Loading domains…").font(.caption).foregroundStyle(.secondary)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 6) {
                    Text(message).font(.caption).foregroundStyle(.red)
                    Button {
                        Task { await model.loadDomains(force: true) }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                }
            case .loaded(let domains) where domains.isEmpty:
                Text("No domains on this account.").font(.caption).foregroundStyle(.secondary)
            case .loaded(let domains):
                Picker("Domain", selection: $model.selectedDomain) {
                    ForEach(domains, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }

    private var aliasField: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 4) {
            Label("Alias", systemImage: "at")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("sales", text: $model.aliasInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .focused($aliasFocused)
                .onSubmit { if model.canSubmit { Task { await model.submit() } } }

            Group {
                if let reason = model.aliasValidation.errorReason {
                    Text(reason).foregroundStyle(.red)
                } else if let address = model.previewAddress {
                    Text(address).foregroundStyle(.secondary)
                } else {
                    Text(" ")
                }
            }
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.middle)
        }
    }

    private var destinationField: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 4) {
            Label("Forward to", systemImage: "tray.and.arrow.down")
                .font(.caption)
                .foregroundStyle(.secondary)
            switch model.accounts {
            case .idle:
                Text("Choose a domain first.").font(.caption).foregroundStyle(.secondary)
            case .loading:
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Loading mailboxes…").font(.caption).foregroundStyle(.secondary)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 6) {
                    Text(message).font(.caption).foregroundStyle(.red)
                    Button {
                        Task { await model.loadAccounts(for: model.selectedDomain, force: true) }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                }
            case .loaded(let accounts) where accounts.isEmpty:
                Text("No mailboxes on this domain.").font(.caption).foregroundStyle(.secondary)
            case .loaded(let accounts):
                Picker("Forward to", selection: $model.selectedDestination) {
                    ForEach(accounts) { Text($0.email).tag($0.email) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }

    // replaced in Task 3
    private var actionSection: some View { EmptyView() }

    private var unconfiguredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Add your MXRoute credentials to get started.", systemImage: "key")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            SettingsLink { Text("Open Settings…") }
                .simultaneousGesture(TapGesture().onEnded { NSApplication.shared.activate() })
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Label("Settings…", systemImage: "gearshape")
            }
            .simultaneousGesture(TapGesture().onEnded { NSApplication.shared.activate() })

            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}

#Preview {
    let settings = AppSettings()
    return MenuBarContentView()
        .environment(settings)
        .environment(CreateForwarderModel(settings: settings, makeClient: { _ in
            MXRouteClient(credentials: nil)
        }))
}
