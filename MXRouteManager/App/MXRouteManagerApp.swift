//
//  MXRouteManagerApp.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI

@main
struct MXRouteManagerApp: App {
    @State private var settings: AppSettings
    @State private var createModel: CreateForwarderModel

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _createModel = State(initialValue: CreateForwarderModel(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra("MXRoute Manager", systemImage: "envelope.badge") {
            MenuBarContentView()
                .environment(settings)
                .environment(createModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
