//
//  KeychainServiceTests.swift
//  MXRouteManagerTests
//
//  Round-trip tests for KeychainService against an isolated
//  service/account pair so the real "MXRouteManager" / "api-key"
//  Keychain item is never touched.
//

import Testing
import Foundation
@testable import MXRouteManager

private func makeService() -> KeychainService {
    KeychainService(service: "MXRouteManager.tests", account: "test-api-key")
}

@Suite(.serialized)
struct KeychainServiceTests {

    @Test func saveThenLoadReturnsTheSameKey() throws {
        let service = makeService()
        defer { try? service.delete() }

        try service.save("test-key-abc123")
        #expect(try service.load() == "test-key-abc123")
    }

    @Test func savingTwiceOverwrites() throws {
        let service = makeService()
        defer { try? service.delete() }

        try service.save("first")
        try service.save("second")
        #expect(try service.load() == "second")
    }

    @Test func loadReturnsNilWhenAbsent() throws {
        let service = makeService()
        defer { try? service.delete() }

        try service.delete()
        #expect(try service.load() == nil)
    }

    @Test func deleteIsIdempotent() throws {
        let service = makeService()
        defer { try? service.delete() }

        #expect(throws: Never.self) { try service.delete() }
        #expect(throws: Never.self) { try service.delete() }
    }
}
