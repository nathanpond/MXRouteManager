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
    }

    // replaced in Task 2
    private var formSection: some View { EmptyView() }

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
