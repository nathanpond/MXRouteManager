//
//  AliasValidator.swift
//  MXRouteManager
//
//  A pure judgment of what the user has typed into the alias field: empty,
//  valid (with the normalized, lowercase form that will actually be created),
//  or invalid with a specific human reason. No SwiftUI, no networking, no
//  @Observable — this file is consumed by the nonisolated test target, so
//  pulling in SwiftUI would drag MainActor isolation across that boundary.
//

import Foundation

/// The verdict on what the user has typed into the alias field.
/// `.empty` is deliberately distinct from `.invalid` — an untouched field
/// must disable Create WITHOUT scolding the user with a red error.
nonisolated enum AliasValidation: Equatable {
    case empty
    case valid(normalized: String)
    case invalid(reason: String)

    var normalizedAlias: String? {
        if case .valid(let normalized) = self { return normalized }
        return nil
    }

    /// The message to show under the field, or nil when there is nothing to say.
    var errorReason: String? {
        if case .invalid(let reason) = self { return reason }
        return nil
    }
}

nonisolated enum AliasValidator {
    static let maxLength = 64
    private static let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-+")

    /// Runs the rules below in this exact order — the order is what makes
    /// the message specific instead of generic.
    static func validate(_ raw: String) -> AliasValidation {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        // Pasting a whole address is the single most likely mistake, and
        // "invalid character" would be a useless answer to it.
        if trimmed.contains("@") {
            return .invalid(reason: "Enter just the part before the @.")
        }

        // An interior space survives trimming.
        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return .invalid(reason: "Aliases can't contain spaces.")
        }

        if trimmed.count > maxLength {
            return .invalid(reason: "Keep the alias to \(maxLength) characters or fewer.")
        }

        // Lowercasing here, not at submit time: DirectAdmin stores mailboxes
        // lowercase, so a user typing "Sales" gets sales@… — the confirmation
        // in plan 04-03 must show what was ACTUALLY created, not what was typed.
        let normalized = trimmed.lowercased()

        if normalized.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return .invalid(reason: "Use letters, numbers, and . _ - + only.")
        }

        if normalized.hasPrefix(".") || normalized.hasSuffix(".") {
            return .invalid(reason: "An alias can't start or end with a dot.")
        }

        if normalized.contains("..") {
            return .invalid(reason: "An alias can't contain two dots in a row.")
        }

        return .valid(normalized: normalized)
    }
}
