//
//  MenuBarContentView.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI
import AppKit

struct MenuBarContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MXRoute Manager")
                .font(.headline)
            Text("Forwarder creation arrives in a later phase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                SettingsLink {
                    Label("Settings…", systemImage: "gearshape")
                }
                .simultaneousGesture(TapGesture().onEnded {
                    NSApplication.shared.activate()
                })

                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}

#Preview {
    MenuBarContentView()
}
