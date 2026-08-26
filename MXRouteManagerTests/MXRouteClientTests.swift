//
//  MXRouteClientTests.swift
//  MXRouteManagerTests
//
//  Auth headers, listDomains decoding, and every MXRouteError mapping,
//  proven against a mocked URLProtocol — never the real network.
//

import Testing
import Foundation
@testable import MXRouteManager

private func testCredentials() -> MXRouteCredentials {
    MXRouteCredentials(server: "eagle.mxlogin.com", username: "testuser", apiKey: "test-key-123")!
}

private func makeClient(credentials: MXRouteCredentials? = testCredentials()) -> MXRouteClient {
    MXRouteClient(credentials: credentials, session: makeMockSession(), baseURL: mockBaseURL)
}

/// Captures a single request across the mock handler's escaping closure
/// without introducing concurrency-checking noise.
private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

@Suite(.serialized)
struct MXRouteClientTests {

    @Test
    func authHeadersAreSentOnEveryRequest() async throws {
        let captured = Box<URLRequest?>(nil)
        MockURLProtocol.handler = { request in
            captured.value = request
            let response = makeResponse(200, url: request.url!)
            let body = Data(#"{"success":true,"data":[]}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        _ = try await client.listDomains()

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == "test-key-123")
        #expect(request.value(forHTTPHeaderField: "X-Server") == "eagle.mxlogin.com")
        #expect(request.value(forHTTPHeaderField: "X-Username") == "testuser")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.url?.absoluteString == "https://api.mxroute.test/domains")
    }

    @Test
    func listDomainsDecodesTheEnvelope() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(200, url: request.url!)
            let body = Data(#"{"success":true,"data":["example.com","mydomain.org"]}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        let domains = try await client.listDomains()
        #expect(domains == ["example.com", "mydomain.org"])
    }

    @Test
    func listDomainsReturnsEmptyArray() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(200, url: request.url!)
            let body = Data(#"{"success":true,"data":[]}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        let domains = try await client.listDomains()
        #expect(domains.isEmpty)
    }

    @Test
    func unauthorizedResponseMapsToUnauthorized() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(401, url: request.url!)
            let body = Data(#"{"success":false,"error":{"code":"UNAUTHORIZED","message":"Invalid API credentials"}}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            #expect(error == .unauthorized(message: "Invalid API credentials"))
        }
    }

    @Test
    func apiErrorBodyMapsToApiCase() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(400, url: request.url!)
            let body = Data(#"{"success":false,"error":{"code":"VALIDATION_ERROR","message":"Invalid domain format","field":"domain"}}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            #expect(error == .api(code: "VALIDATION_ERROR", message: "Invalid domain format", field: "domain"))
        }
    }

    @Test
    func nonJSONServerErrorMapsToHTTPStatus() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(500, url: request.url!)
            let body = Data("<html>oops</html>".utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            switch error {
            case .api(let code, _, _):
                #expect(code == "HTTP_500")
            default:
                Issue.record("expected .api, got \(error)")
            }
            #expect(!(error.errorDescription ?? "").isEmpty)
        }
    }

    @Test
    func unreadableSuccessBodyMapsToDecoding() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(200, url: request.url!)
            let body = Data("{not json".utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            switch error {
            case .decoding:
                break
            default:
                Issue.record("expected .decoding, got \(error)")
            }
        }
    }

    @Test
    func unauthorizedWithoutBodyStillMapsToUnauthorized() async throws {
        MockURLProtocol.handler = { request in
            let response = makeResponse(401, url: request.url!)
            return (response, Data())
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            switch error {
            case .unauthorized:
                break
            default:
                Issue.record("expected .unauthorized, got \(error)")
            }
        }
    }

    @Test
    func missingCredentialsThrowNotConfiguredWithoutARequest() async throws {
        let requestWasMade = Box<Bool>(false)
        MockURLProtocol.handler = { request in
            requestWasMade.value = true
            let response = makeResponse(200, url: request.url!)
            let body = Data(#"{"success":true,"data":[]}"#.utf8)
            return (response, body)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient(credentials: nil)
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            #expect(error == .notConfigured)
        }
        #expect(requestWasMade.value == false)
    }

    @Test
    func transportFailureMapsToNetwork() async throws {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { MockURLProtocol.handler = nil }

        let client = makeClient()
        do {
            _ = try await client.listDomains()
            Issue.record("expected a throw")
        } catch let error as MXRouteError {
            switch error {
            case .network(let message):
                #expect(!message.isEmpty)
            default:
                Issue.record("expected .network, got \(error)")
            }
        }
    }

    @Test
    func credentialsRejectBlankValues() throws {
        #expect(MXRouteCredentials(server: "  ", username: "u", apiKey: "k") == nil)
        #expect(MXRouteCredentials(server: "s", username: "u", apiKey: nil) == nil)

        let credentials = MXRouteCredentials(server: " eagle.mxlogin.com ", username: " user ", apiKey: " key ")
        let unwrapped = try #require(credentials)
        #expect(unwrapped.server == "eagle.mxlogin.com")
        #expect(unwrapped.username == "user")
        #expect(unwrapped.apiKey == "key")
    }
}
