//
//  MXRouteModels.swift
//  MXRouteManager
//
//  The wire format of the MXRoute API — the {success, data} / {success:false,
//  error:{code,message,field}} envelope, the two resource models it carries,
//  and the single MXRouteError the rest of the app renders. Everything here
//  is nonisolated and Sendable so the API client (a later plan) and the
//  nonisolated test target can use these types without actor hops.
//

import Foundation

/// The API's own error payload: a machine-readable code, a human-readable
/// message, and an optional field name for validation errors.
nonisolated struct APIErrorBody: Decodable, Sendable, Equatable {
    let code: String
    let message: String
    let field: String?
}

/// The envelope every MXRoute API response is wrapped in.
///
/// `data` is Optional because some successful responses (e.g. a 201 create)
/// declare no response body — a non-optional `data` would turn that success
/// into a decoding error.
nonisolated struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool
    let data: T?
    let error: APIErrorBody?

    private enum CodingKeys: String, CodingKey {
        case success, data, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decodeIfPresent(T.self, forKey: .data)
        let error = try container.decodeIfPresent(APIErrorBody.self, forKey: .error)
        self.data = data
        self.error = error
        self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? (error == nil)
    }
}

/// A single MXRoute mailbox.
nonisolated struct EmailAccount: Codable, Sendable, Equatable, Identifiable {
    let username: String
    let email: String
    let quota: Int
    let usage: Double
    let limit: Int
    let sent: Int
    let suspended: Bool

    var id: String { email }

    init(
        username: String,
        email: String,
        quota: Int,
        usage: Double,
        limit: Int,
        sent: Int,
        suspended: Bool
    ) {
        self.username = username
        self.email = email
        self.quota = quota
        self.usage = usage
        self.limit = limit
        self.sent = sent
        self.suspended = suspended
    }

    private enum CodingKeys: String, CodingKey {
        case username, email, quota, usage, limit, sent, suspended
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        quota = try container.decodeIfPresent(Int.self, forKey: .quota) ?? 0
        usage = try container.decodeIfPresent(Double.self, forKey: .usage) ?? 0
        limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? 0
        sent = try container.decodeIfPresent(Int.self, forKey: .sent) ?? 0
        suspended = try container.decodeIfPresent(Bool.self, forKey: .suspended) ?? false
    }
}

/// A single MXRoute email forwarder.
nonisolated struct Forwarder: Codable, Sendable, Equatable, Identifiable {
    let alias: String
    let email: String
    let destinations: [String]

    var id: String { email }

    init(alias: String, email: String, destinations: [String]) {
        self.alias = alias
        self.email = email
        self.destinations = destinations
    }

    private enum CodingKeys: String, CodingKey {
        case alias, email, destinations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alias = try container.decode(String.self, forKey: .alias)
        email = try container.decode(String.self, forKey: .email)
        destinations = try container.decodeIfPresent([String].self, forKey: .destinations) ?? []
    }
}

/// The one error type the whole app surfaces. Every case carries a plain
/// String (never an underlying Error) so the whole enum stays Equatable,
/// which lets tests assert exact mapping with `#expect(error == .api(...))`.
nonisolated enum MXRouteError: Error, LocalizedError, Equatable, Sendable {
    case notConfigured
    case invalidRequest(message: String)
    case network(message: String)
    case unauthorized(message: String)
    case api(code: String, message: String, field: String?)
    case decoding(message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your server, username, and API key in Settings first."
        case .invalidRequest(let message):
            return message
        case .network(let message):
            return "Could not reach MXRoute: \(message)"
        case .unauthorized(let message):
            return message.isEmpty ? "MXRoute rejected these credentials." : message
        case .api(_, let message, let field):
            return field.map { "\(message) (\($0))" } ?? message
        case .decoding(let message):
            return "Could not read the MXRoute response: \(message)"
        case .invalidResponse:
            return "MXRoute returned an unexpected response."
        }
    }

    /// The API's own error code, where one exists — lets callers special-case
    /// e.g. CONFLICT (duplicate alias) without string-matching messages.
    var code: String? {
        switch self {
        case .api(let code, _, _):
            return code
        case .unauthorized:
            return "UNAUTHORIZED"
        default:
            return nil
        }
    }
}
