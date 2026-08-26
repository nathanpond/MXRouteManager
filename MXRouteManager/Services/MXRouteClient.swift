//
//  MXRouteClient.swift
//  MXRouteManager
//
//  The single place the app talks to https://api.mxroute.com. Every request
//  is authenticated with the stored credentials, and every failure leaves
//  here as an MXRouteError — callers never see a raw URLError or a decoding
//  error directly.
//

import Foundation

/// A validated, trimmed snapshot of the three values every MXRoute request
/// needs. A snapshot rather than a `() throws -> MXRouteCredentials`
/// provider closure: `AppSettings` is `@Observable` and MainActor-isolated,
/// so a stored closure capturing it would make the client non-`Sendable`
/// and drag actor-isolation problems into every call site and test. The
/// client is cheap and constructed per user action, so reading credentials
/// at construction time is always fresh enough.
nonisolated struct MXRouteCredentials: Sendable, Equatable {
    let server: String
    let username: String
    let apiKey: String

    init?(server: String, username: String, apiKey: String?) {
        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let apiKey else { return nil }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedServer.isEmpty, !trimmedUsername.isEmpty, !trimmedKey.isEmpty else { return nil }
        self.server = trimmedServer
        self.username = trimmedUsername
        self.apiKey = trimmedKey
    }
}

/// The MXRoute API client. `credentials` is Optional so an unconfigured app
/// is representable; requests then fail with `.notConfigured` before any
/// network call. `session` and `baseURL` are injectable so tests can run
/// against a mocked `URLProtocol` and a fake host without touching the
/// network.
nonisolated struct MXRouteClient: Sendable {
    static let productionBaseURL = URL(string: "https://api.mxroute.com")!

    let credentials: MXRouteCredentials?
    let session: URLSession
    let baseURL: URL

    init(credentials: MXRouteCredentials?, session: URLSession = .shared, baseURL: URL = MXRouteClient.productionBaseURL) {
        self.credentials = credentials
        self.session = session
        self.baseURL = baseURL
    }

    // A domain name goes into the URL path and must be escaped per segment.
    // Plain `.urlPathAllowed` permits `/`, so a hostile or malformed domain
    // string could inject extra path segments — remove it explicitly.
    private static let pathSegmentAllowed: CharacterSet = {
        var set = CharacterSet.urlPathAllowed
        set.remove("/")
        return set
    }()

    private func makeRequest(method: String, pathComponents: [String], body: Data?) throws -> URLRequest {
        guard let credentials else { throw MXRouteError.notConfigured }

        let encodedComponents = pathComponents.map {
            $0.addingPercentEncoding(withAllowedCharacters: Self.pathSegmentAllowed)
        }
        guard encodedComponents.allSatisfy({ $0 != nil }) else {
            throw MXRouteError.invalidRequest(message: "Could not build a URL for \(pathComponents.joined(separator: "/")).")
        }
        let path = encodedComponents.compactMap { $0 }.joined(separator: "/")
        guard let url = URL(string: baseURL.absoluteString + "/" + path) else {
            throw MXRouteError.invalidRequest(message: "Could not build a URL for \(pathComponents.joined(separator: "/")).")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        // A cached domain list would make a re-test after fixing credentials
        // silently return the old answer.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(credentials.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(credentials.server, forHTTPHeaderField: "X-Server")
        request.setValue(credentials.username, forHTTPHeaderField: "X-Username")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }

    /// The single response pipeline every endpoint goes through: build the
    /// request, perform it, check the HTTP status, decode the envelope, and
    /// map any failure to `MXRouteError` in one place.
    private func send<T: Decodable & Sendable>(_ type: T.Type, method: String, pathComponents: [String], body: Data? = nil) async throws -> T? {
        let request = try makeRequest(method: method, pathComponents: pathComponents, body: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as MXRouteError {
            // A mocked URLProtocol can surface an MXRouteError directly; it
            // must not be re-wrapped as a network failure.
            throw error
        } catch {
            throw MXRouteError.network(message: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw MXRouteError.invalidResponse
        }

        var envelope: APIEnvelope<T>?
        var decodingFailure: String?
        if !data.isEmpty {
            do {
                envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
            } catch {
                decodingFailure = error.localizedDescription
            }
        }

        // Checking the status FIRST is what makes an HTML 500 page (which
        // cannot decode) map to a server error rather than a decoding error.
        let succeeded = (200..<300).contains(http.statusCode) && (envelope?.success ?? true)
        if !succeeded {
            throw Self.failure(status: http.statusCode, body: envelope?.error)
        }

        if envelope == nil {
            if let decodingFailure {
                throw MXRouteError.decoding(message: decodingFailure)
            }
            // The body was empty — the 201-create shape.
            return nil
        }

        return envelope?.data
    }

    /// Maps an HTTP status and optional API error body to a single
    /// `MXRouteError`. Not private so tests can exercise the table directly.
    /// Note it maps 401 to `.unauthorized` even when the body decodes —
    /// CONF-04 must distinguish "your key is wrong" from every other failure.
    static func failure(status: Int, body: APIErrorBody?) -> MXRouteError {
        if let body {
            if status == 401 || body.code == "UNAUTHORIZED" {
                return .unauthorized(message: body.message)
            }
            return .api(code: body.code, message: body.message, field: body.field)
        }
        if status == 401 {
            return .unauthorized(message: "MXRoute rejected these credentials.")
        }
        return .api(code: "HTTP_\(status)", message: HTTPURLResponse.localizedString(forStatusCode: status), field: nil)
    }

    func listDomains() async throws -> [String] {
        guard let domains = try await send([String].self, method: "GET", pathComponents: ["domains"]) else {
            throw MXRouteError.decoding(message: "The domains response contained no data.")
        }
        return domains
    }

    /// The domain's mailboxes, sorted by address. Sorting happens here rather
    /// than in the view: Phase 4's destination picker renders this array
    /// directly, and DirectAdmin returns mailboxes in creation order, which
    /// reads as random in a dropdown.
    func listEmailAccounts(domain: String) async throws -> [EmailAccount] {
        let domain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !domain.isEmpty else {
            throw MXRouteError.invalidRequest(message: "Choose a domain before loading its email accounts.")
        }
        guard let accounts = try await send([EmailAccount].self, method: "GET", pathComponents: ["domains", domain, "email-accounts"]) else {
            throw MXRouteError.decoding(message: "The email accounts response contained no data.")
        }
        return accounts.sorted { $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending }
    }

    /// Creates a forwarder. The API declares a `201` with no response body,
    /// so a `nil` result from `send` here means success, not failure — the
    /// fallback below synthesizes the `Forwarder` the server would have
    /// echoed rather than throwing on a request that actually succeeded.
    @discardableResult
    func createForwarder(domain: String, alias: String, destinations: [String]) async throws -> Forwarder {
        let domain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        let alias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let destinations = destinations
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !domain.isEmpty else { throw MXRouteError.invalidRequest(message: "Choose a domain for the forwarder.") }
        guard !alias.isEmpty else { throw MXRouteError.invalidRequest(message: "Enter an alias for the forwarder.") }
        guard !destinations.isEmpty else { throw MXRouteError.invalidRequest(message: "Choose at least one destination for the forwarder.") }

        let body = try JSONEncoder().encode(CreateForwarderBody(alias: alias, destinations: destinations))
        let created = try await send(
            Forwarder.self,
            method: "POST",
            pathComponents: ["domains", domain, "forwarders"],
            body: body
        )
        return created ?? Forwarder(alias: alias, email: "\(alias)@\(domain)", destinations: destinations)
    }
}

/// The POST body for `createForwarder`. File-scope (not nested in the
/// `nonisolated struct`) but still `nonisolated` itself, since it carries no
/// actor-isolated state of its own.
nonisolated private struct CreateForwarderBody: Encodable {
    let alias: String
    let destinations: [String]
}

@MainActor
extension MXRouteClient {
    /// Builds a client from the app's live settings and Keychain. Reads the
    /// key once, here, at construction time — the client never holds a
    /// reference to `AppSettings` or the Keychain itself.
    static func live(settings: AppSettings, keychain: KeychainService = .shared, session: URLSession = .shared) -> MXRouteClient {
        // `(try? keychain.load()) ?? nil` flattens the double Optional; a
        // Keychain read failure becomes "no credentials", which surfaces as
        // `.notConfigured`.
        let key = (try? keychain.load()) ?? nil
        return MXRouteClient(
            credentials: MXRouteCredentials(server: settings.serverHostname, username: settings.username, apiKey: key),
            session: session
        )
    }
}
