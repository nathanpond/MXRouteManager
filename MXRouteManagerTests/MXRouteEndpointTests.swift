//
//  MXRouteEndpointTests.swift
//  MXRouteManagerTests
//
//  Tests for listEmailAccounts(domain:) and createForwarder(domain:alias:destinations:),
//  the two endpoints added on top of plan 03-02's request pipeline. A new file
//  rather than appending to MXRouteClientTests.swift: it keeps this plan's diff
//  disjoint from plan 03-02's file and keeps each suite readable.
//
//  Every test wraps its body in `withMockNetwork` (MockURLProtocol.swift):
//  `MockURLProtocol.handler` is a single `nonisolated(unsafe) static` shared
//  with MXRouteClientTests, and `@Suite(.serialized)` only serializes tests
//  within one suite — it does not stop this suite from running concurrently
//  with that one, which caused cross-suite test flakiness before the lock
//  was added.
//

import Testing
import Foundation
@testable import MXRouteManager

private func makeClient() -> MXRouteClient {
    MXRouteClient(
        credentials: MXRouteCredentials(server: "eagle.mxlogin.com", username: "testuser", apiKey: "test-key-123")!,
        session: makeMockSession(),
        baseURL: mockBaseURL
    )
}

private final class RequestBox: @unchecked Sendable {
    var request: URLRequest?
    var callCount = 0
}

@Suite(.serialized)
struct MXRouteEndpointTests {

    // MARK: - listEmailAccounts

    @Test
    func emailAccountsUsesTheDomainScopedPath() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.request = request
                let body = #"{"success":true,"data":[]}"#.data(using: .utf8)!
                return (makeResponse(200, url: request.url!), body)
            }

            let client = makeClient()
            _ = try await client.listEmailAccounts(domain: "example.com")

            #expect(box.request?.url?.absoluteString == "https://api.mxroute.test/domains/example.com/email-accounts")
            #expect(box.request?.httpMethod == "GET")
        }
    }

    @Test
    func emailAccountsDecodeAndSortByAddress() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                let body = """
                {"success":true,"data":[
                    {"username":"zoe","email":"zoe@example.com","quota":1024,"usage":256.5,"limit":9600,"sent":42,"suspended":false},
                    {"username":"alice","email":"alice@example.com","quota":1024,"usage":10,"limit":9600,"sent":1,"suspended":false}
                ]}
                """.data(using: .utf8)!
                return (makeResponse(200, url: request.url!), body)
            }

            let client = makeClient()
            let accounts = try await client.listEmailAccounts(domain: "example.com")

            #expect(accounts.map(\.email) == ["alice@example.com", "zoe@example.com"])
            let zoe = try #require(accounts.first { $0.email == "zoe@example.com" })
            #expect(zoe.usage == 256.5)
        }
    }

    @Test
    func domainIsEncodedAsASinglePathSegment() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.request = request
                let body = #"{"success":true,"data":[]}"#.data(using: .utf8)!
                return (makeResponse(200, url: request.url!), body)
            }

            let client = makeClient()
            _ = try await client.listEmailAccounts(domain: "ex ample.com/../admin")

            let request = try #require(box.request)
            let urlString = try #require(request.url?.absoluteString)
            #expect(!urlString.contains(" "))
            #expect(!urlString.contains("/../"))
            #expect(urlString.contains("%2F") == true)
            #expect(urlString.contains("%20") == true)
            #expect(urlString.hasPrefix("https://api.mxroute.test/domains/"))
        }
    }

    @Test
    func emailAccountsSurfacesNotFound() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                let body = #"{"success":false,"error":{"code":"NOT_FOUND","message":"Domain not found"}}"#.data(using: .utf8)!
                return (makeResponse(404, url: request.url!), body)
            }

            let client = makeClient()
            do {
                _ = try await client.listEmailAccounts(domain: "example.com")
                Issue.record("expected a throw")
            } catch let error as MXRouteError {
                #expect(error == .api(code: "NOT_FOUND", message: "Domain not found", field: nil))
            }
        }
    }

    @Test
    func blankDomainThrowsWithoutARequest() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.callCount += 1
                let body = #"{"success":true,"data":[]}"#.data(using: .utf8)!
                return (makeResponse(200, url: request.url!), body)
            }

            let client = makeClient()
            do {
                _ = try await client.listEmailAccounts(domain: "   ")
                Issue.record("expected a throw")
            } catch let error as MXRouteError {
                #expect(error == .invalidRequest(message: "Choose a domain before loading its email accounts."))
            }
            #expect(box.callCount == 0)
        }
    }

    // MARK: - createForwarder

    @Test
    func createForwarderPostsAliasAndDestinations() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.request = request
                let body = #"{"success":true,"data":{"alias":"sales","email":"sales@example.com","destinations":["me@example.com"]}}"#.data(using: .utf8)!
                return (makeResponse(201, url: request.url!), body)
            }

            let client = makeClient()
            _ = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["me@example.com"])

            let request = try #require(box.request)
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://api.mxroute.test/domains/example.com/forwarders")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let bodyData = try #require(request.capturedBody)
            let json = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
            #expect(json["alias"] as? String == "sales")
            #expect(json["destinations"] as? [String] == ["me@example.com"])
        }
    }

    @Test
    func createForwarderReturnsTheDecodedForwarder() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                let body = #"{"success":true,"data":{"alias":"sales","email":"sales@example.com","destinations":["me@example.com"]}}"#.data(using: .utf8)!
                return (makeResponse(201, url: request.url!), body)
            }

            let client = makeClient()
            let forwarder = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["me@example.com"])

            #expect(forwarder == Forwarder(alias: "sales", email: "sales@example.com", destinations: ["me@example.com"]))
        }
    }

    @Test
    func createForwarderSynthesizesResultWhenBodyIsEmpty() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                (makeResponse(201, url: request.url!), Data())
            }

            let client = makeClient()
            let forwarder = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["me@example.com"])

            #expect(forwarder.alias == "sales")
            #expect(forwarder.email == "sales@example.com")
            #expect(forwarder.destinations == ["me@example.com"])
        }
    }

    @Test
    func duplicateAliasSurfacesConflict() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                let body = #"{"success":false,"error":{"code":"CONFLICT","message":"Forwarder already exists"}}"#.data(using: .utf8)!
                return (makeResponse(409, url: request.url!), body)
            }

            let client = makeClient()
            do {
                _ = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["me@example.com"])
                Issue.record("Expected createForwarder to throw")
            } catch let error as MXRouteError {
                #expect(error == .api(code: "CONFLICT", message: "Forwarder already exists", field: nil))
                #expect(error.code == "CONFLICT")
            }
        }
    }

    @Test
    func validationErrorCarriesTheField() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            MockURLProtocol.handler = { request in
                let body = #"{"success":false,"error":{"code":"VALIDATION_ERROR","message":"Invalid alias","field":"alias"}}"#.data(using: .utf8)!
                return (makeResponse(400, url: request.url!), body)
            }

            let client = makeClient()
            do {
                _ = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["me@example.com"])
                Issue.record("Expected createForwarder to throw")
            } catch let error as MXRouteError {
                #expect(error == .api(code: "VALIDATION_ERROR", message: "Invalid alias", field: "alias"))
                let description = try #require(error.errorDescription)
                #expect(description.contains("Invalid alias"))
                #expect(description.contains("alias"))
            }
        }
    }

    @Test
    func emptyAliasOrDestinationsThrowWithoutARequest() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.callCount += 1
                let body = #"{"success":true,"data":{"alias":"sales","email":"sales@example.com","destinations":["me@example.com"]}}"#.data(using: .utf8)!
                return (makeResponse(201, url: request.url!), body)
            }

            let client = makeClient()

            do {
                _ = try await client.createForwarder(domain: "example.com", alias: "   ", destinations: ["me@example.com"])
                Issue.record("expected a throw")
            } catch let error as MXRouteError {
                guard case .invalidRequest = error else {
                    Issue.record("expected .invalidRequest, got \(error)")
                    return
                }
            }
            do {
                _ = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: ["  "])
                Issue.record("expected a throw")
            } catch let error as MXRouteError {
                guard case .invalidRequest = error else {
                    Issue.record("expected .invalidRequest, got \(error)")
                    return
                }
            }
            #expect(box.callCount == 0)
        }
    }

    @Test
    func destinationsAreTrimmedBeforeSending() async throws {
        try await withMockNetwork {
            defer { MockURLProtocol.handler = nil }
            let box = RequestBox()
            MockURLProtocol.handler = { request in
                box.request = request
                return (makeResponse(201, url: request.url!), Data())
            }

            let client = makeClient()
            _ = try await client.createForwarder(domain: "example.com", alias: "sales", destinations: [" me@example.com ", ""])

            let request = try #require(box.request)
            let bodyData = try #require(request.capturedBody)
            let json = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
            #expect(json["destinations"] as? [String] == ["me@example.com"])
        }
    }
}
