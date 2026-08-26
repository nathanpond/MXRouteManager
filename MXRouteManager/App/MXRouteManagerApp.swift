//
//  MXRouteManagerApp.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import SwiftUI

@main
struct MXRouteManagerApp: App {
    var body: some Scene {
        MenuBarExtra("MXRoute Manager", systemImage: "envelope.badge") {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
