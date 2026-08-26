//
//  SettingsView.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var apiKeyInput: String = ""
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                TextField("Server", text: $settings.serverHostname, prompt: Text("eagle.mxlogin.com"))
                    .autocorrectionDisabled()
                    .onSubmit { settings.normalize() }
                TextField("Username", text: $settings.username, prompt: Text("DirectAdmin username"))
                    .autocorrectionDisabled()
                    .onSubmit { settings.normalize() }
            } header: {
                Text("Connection")
            } footer: {
                Text("The mail server hostname and DirectAdmin username come from your MXRoute welcome email.")
            }

            Section {
                if settings.hasAPIKey {
                    HStack {
                        Label("API key stored in Keychain", systemImage: "checkmark.seal.fill")
                            .symbolRenderingMode(.multicolor)
                        Spacer()
                        Button("Remove", role: .destructive) { removeKey() }
                    }
                }
                SecureField("API Key", text: $apiKeyInput, prompt: Text(settings.hasAPIKey ? "Enter a new key to replace" : "Paste your MXRoute API key"))
                    .onSubmit { saveKey() }
                Button("Save to Keychain") { saveKey() }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("API Key")
            } footer: {
                Text("Create API keys at panel.mxroute.com/api-keys.php.")
            }

            Section {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if let statusMessage {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                } else if !settings.isConfigured {
                    Text("Enter a server, username, and API key to finish setup.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 360)
        .onDisappear { settings.normalize() }
    }

    private func saveKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        do {
            try settings.saveAPIKey(key)
            apiKeyInput = ""
            errorMessage = nil
            statusMessage = "API key saved to Keychain."
        } catch {
            statusMessage = nil
            errorMessage = "Could not save the API key: \(error.localizedDescription)"
        }
    }

    private func removeKey() {
        do {
            try settings.removeAPIKey()
            errorMessage = nil
            statusMessage = "API key removed from Keychain."
        } catch {
            statusMessage = nil
            errorMessage = "Could not remove the API key: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView().environment(AppSettings())
}
