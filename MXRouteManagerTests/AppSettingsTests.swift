//
//  AppSettingsTests.swift
//  MXRouteManagerTests
//
//  Persistence, isConfigured, and API-key state tests for AppSettings
//  against an isolated UserDefaults suite and an isolated Keychain
//  service/account pair — never the app's real shared defaults or
//  the real shared Keychain item.
//

import Testing
import Foundation
@testable import MXRouteManager

private func makeSuite() -> (UserDefaults, String) {
    let name = "AppSettingsTests.\(UUID().uuidString)"
    return (UserDefaults(suiteName: name)!, name)
}

private func makeKeychain() -> KeychainService {
    KeychainService(service: "MXRouteManager.tests.settings", account: "test-api-key")
}

@Suite(.serialized)
struct AppSettingsTests {

    @Test func valuesPersistAcrossInstances() throws {
        let (defaults, name) = makeSuite()
        let keychain = makeKeychain()
        defer {
            defaults.removePersistentDomain(forName: name)
            try? keychain.delete()
        }

        let first = AppSettings(store: defaults, keychain: keychain)
        first.serverHostname = "eagle.mxlogin.com"
        first.username = "npond"

        let second = AppSettings(store: defaults, keychain: keychain)
        #expect(second.serverHostname == "eagle.mxlogin.com")
        #expect(second.username == "npond")
    }

    @Test func isConfiguredRequiresAllThreeCredentials() throws {
        let (defaults, name) = makeSuite()
        let keychain = makeKeychain()
        defer {
            defaults.removePersistentDomain(forName: name)
            try? keychain.delete()
        }

        let settings = AppSettings(store: defaults, keychain: keychain)
        #expect(settings.isConfigured == false)

        settings.serverHostname = "eagle.mxlogin.com"
        #expect(settings.isConfigured == false)

        settings.username = "npond"
        #expect(settings.isConfigured == false)

        try settings.saveAPIKey("abc")
        #expect(settings.isConfigured == true)
    }

    @Test func savingAndRemovingTheKeyFlipsHasAPIKey() throws {
        let (defaults, name) = makeSuite()
        let keychain = makeKeychain()
        defer {
            defaults.removePersistentDomain(forName: name)
            try? keychain.delete()
        }

        let settings = AppSettings(store: defaults, keychain: keychain)
        settings.serverHostname = "eagle.mxlogin.com"
        settings.username = "npond"

        try settings.saveAPIKey("abc")
        #expect(settings.hasAPIKey == true)
        #expect(settings.isConfigured == true)

        try settings.removeAPIKey()
        #expect(settings.hasAPIKey == false)
        #expect(settings.isConfigured == false)
    }

    @Test func whitespaceOnlyValuesDoNotCount() throws {
        let (defaults, name) = makeSuite()
        let keychain = makeKeychain()
        defer {
            defaults.removePersistentDomain(forName: name)
            try? keychain.delete()
        }

        let settings = AppSettings(store: defaults, keychain: keychain)
        settings.serverHostname = "   "
        settings.username = "npond"
        try settings.saveAPIKey("abc")

        #expect(settings.isConfigured == false)

        settings.normalize()
        #expect(settings.serverHostname == "")
    }
}
