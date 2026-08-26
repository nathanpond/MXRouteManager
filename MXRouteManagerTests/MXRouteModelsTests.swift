//
//  MXRouteModelsTests.swift
//  MXRouteManagerTests
//
//  Pure decoding tests for the MXRoute API envelope/models plus
//  user-facing description tests for MXRouteError. No networking
//  of any kind — the URLProtocol harness lives in a later plan.
//

import Testing
import Foundation
@testable import MXRouteManager

private func decode<T: Decodable & Sendable>(_ type: T.Type, _ json: String) throws -> APIEnvelope<T> {
    try JSONDecoder().decode(APIEnvelope<T>.self, from: Data(json.utf8))
}

struct MXRouteModelsTests {

    @Test func domainsEnvelopeDecodes() throws {
        let envelope = try decode([String].self, """
        {"success":true,"data":["example.com","mydomain.org"]}
        """)
        #expect(envelope.success == true)
        #expect(envelope.data == ["example.com", "mydomain.org"])
        #expect(envelope.error == nil)
    }

    @Test func emailAccountsEnvelopeDecodes() throws {
        let envelope = try decode([EmailAccount].self, """
        {"success":true,"data":[{"username":"your_mailbox","email":"your_mailbox@example.com","quota":1024,"usage":256.5,"limit":9600,"sent":42,"suspended":false}]}
        """)
        let accounts = try #require(envelope.data)
        #expect(accounts.count == 1)
        let account = accounts[0]
        #expect(account.usage == 256.5)
        #expect(account.quota == 1024)
        #expect(account.suspended == false)
        #expect(account.id == account.email)
    }

    @Test func emailAccountToleratesMissingCounters() throws {
        let envelope = try decode([EmailAccount].self, """
        {"success":true,"data":[{"username":"a","email":"a@example.com"}]}
        """)
        let accounts = try #require(envelope.data)
        let account = try #require(accounts.first)
        #expect(account.quota == 0)
        #expect(account.usage == 0)
        #expect(account.limit == 0)
        #expect(account.sent == 0)
        #expect(account.suspended == false)
    }

    @Test func forwarderEnvelopeDecodes() throws {
        let envelope = try decode(Forwarder.self, """
        {"success":true,"data":{"alias":"sales","email":"sales@example.com","destinations":["me@example.com"]}}
        """)
        let forwarder = try #require(envelope.data)
        #expect(forwarder.alias == "sales")
        #expect(forwarder.email == "sales@example.com")
        #expect(forwarder.destinations == ["me@example.com"])
    }

    @Test func errorEnvelopeCarriesCodeMessageAndField() throws {
        let envelope = try decode(Forwarder.self, """
        {"success":false,"error":{"code":"VALIDATION_ERROR","message":"Invalid alias","field":"alias"}}
        """)
        #expect(envelope.success == false)
        #expect(envelope.data == nil)
        #expect(envelope.error == APIErrorBody(code: "VALIDATION_ERROR", message: "Invalid alias", field: "alias"))
    }

    @Test func errorEnvelopeWithoutFieldDecodes() throws {
        let envelope = try decode(Forwarder.self, """
        {"success":false,"error":{"code":"UNAUTHORIZED","message":"Invalid API credentials"}}
        """)
        #expect(envelope.error?.field == nil)
    }

    @Test func envelopeWithNoDataDecodes() throws {
        let envelope = try decode(Forwarder.self, """
        {"success":true}
        """)
        #expect(envelope.success == true)
        #expect(envelope.data == nil)
    }

    @Test func errorDescriptionsAreUserReadable() throws {
        let cases: [MXRouteError] = [
            .notConfigured,
            .unauthorized(message: "Invalid API credentials"),
            .api(code: "CONFLICT", message: "Forwarder already exists", field: nil),
            .api(code: "VALIDATION_ERROR", message: "Invalid alias", field: "alias"),
            .network(message: "The Internet connection appears to be offline."),
        ]

        for error in cases {
            let description = try #require(error.errorDescription)
            #expect(!description.isEmpty)
        }

        #expect(MXRouteError.unauthorized(message: "Invalid API credentials").errorDescription == "Invalid API credentials")

        let fieldDescription = try #require(
            MXRouteError.api(code: "VALIDATION_ERROR", message: "Invalid alias", field: "alias").errorDescription
        )
        #expect(fieldDescription.contains("Invalid alias"))
        #expect(fieldDescription.contains("alias"))

        let networkDescription = try #require(
            MXRouteError.network(message: "The Internet connection appears to be offline.").errorDescription
        )
        #expect(networkDescription.contains("The Internet connection appears to be offline."))
    }

    @Test func errorCodeIsExposed() throws {
        #expect(MXRouteError.api(code: "CONFLICT", message: "x", field: nil).code == "CONFLICT")
        #expect(MXRouteError.notConfigured.code == nil)
    }
}
