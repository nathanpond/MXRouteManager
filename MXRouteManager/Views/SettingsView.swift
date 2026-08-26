//
//  SettingsView.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("MXRoute Credentials") {
                Text("API key, server, and username fields arrive in Phase 2.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 200)
    }
}

#Preview {
    SettingsView()
}
