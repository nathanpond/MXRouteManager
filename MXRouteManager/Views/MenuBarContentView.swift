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
        VStack(alignment: .leading, spacing: 0) {
            header
            content
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .animation(.snappy(duration: 0.2), value: model.submitState)
                .animation(.easeInOut(duration: 0.15), value: model.domains)
                .animation(.easeInOut(duration: 0.15), value: model.accounts)
            Divider()
            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 320)
        .background(.regularMaterial)
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

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tint)
            Text("New Forwarder")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            if settings.isConfigured {
                if case .succeeded = model.submitState {
                    actionSection
                } else {
                    formSection
                    actionSection
                }
            } else {
                unconfiguredSection
            }
        }
    }

    private var formSection: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            domainField
            aliasField
            destinationField
        }
    }

    private var domainField: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 5) {
            Label("Domain", systemImage: "globe")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .imageScale(.small)
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
        return VStack(alignment: .leading, spacing: 5) {
            Label("Alias", systemImage: "at")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .imageScale(.small)
            TextField("sales", text: $model.aliasInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .focused($aliasFocused)
                .onSubmit { if model.canSubmit { Task { await model.submit() } } }

            Group {
                if let reason = model.aliasValidation.errorReason {
                    Text(reason).foregroundStyle(.red)
                } else if let address = model.previewAddress {
                    Text(address)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
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
        return VStack(alignment: .leading, spacing: 5) {
            Label("Forward to", systemImage: "tray.and.arrow.down")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .imageScale(.small)
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

    @ViewBuilder
    private var actionSection: some View {
        switch model.submitState {
        case .succeeded(let forwarder):
            VStack(alignment: .leading, spacing: 8) {
                Label("Forwarder created", systemImage: "checkmark.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.subheadline.weight(.semibold))
                Text("\(forwarder.email) → \(forwarder.destinations.first ?? model.selectedDestination)")
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Create Another") {
                    model.reset()
                    aliasFocused = true
                }
                .keyboardShortcut(.defaultAction)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        Task { await model.submit() }
                    } label: {
                        Label("Create Forwarder", systemImage: "arrow.turn.down.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canSubmit)
                    .keyboardShortcut(.defaultAction)

                    if model.submitState == .submitting {
                        ProgressView().controlSize(.small)
                    }
                }
                if case .failed(let message) = model.submitState {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

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
            .buttonStyle(.borderless)
            .controlSize(.small)

            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
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
