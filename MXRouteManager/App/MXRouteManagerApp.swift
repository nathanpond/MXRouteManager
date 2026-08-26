//
//  MXRouteManagerApp.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI

@main
struct MXRouteManagerApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("MXRoute Manager", systemImage: "envelope.badge") {
            MenuBarContentView()
                .environment(settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
