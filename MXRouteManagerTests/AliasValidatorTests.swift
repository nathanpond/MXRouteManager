//
//  AliasValidatorTests.swift
//  MXRouteManagerTests
//
//  Unit tests for the pure alias validation rules: empty vs valid vs
//  invalid(reason:), normalization, and each specific rejection reason.
//  No mock network needed — AliasValidator touches nothing shared.
//

import Testing
import Foundation
@testable import MXRouteManager

@Suite("Alias validation")
struct AliasValidatorTests {

    @Test func emptyStringIsEmpty() {
        #expect(AliasValidator.validate("") == .empty)
    }

    @Test func whitespaceOnlyIsEmpty() {
        #expect(AliasValidator.validate("   ") == .empty)
    }

    @Test func simpleAliasIsValid() {
        #expect(AliasValidator.validate("sales") == .valid(normalized: "sales"))
    }

    @Test func mixedCaseIsNormalizedToLowercase() {
        #expect(AliasValidator.validate("Sales.Team") == .valid(normalized: "sales.team"))
    }

    @Test func outerWhitespaceIsTrimmed() {
        #expect(AliasValidator.validate("  sales  ") == .valid(normalized: "sales"))
    }

    @Test func allowedPunctuationIsValid() {
        #expect(AliasValidator.validate("first+tag_1-2") == .valid(normalized: "first+tag_1-2"))
    }

    @Test func fullAddressIsInvalidAndMentionsAt() {
        let result = AliasValidator.validate("sales@example.com")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
        #expect(result.errorReason?.contains("@") == true)
    }

    @Test func interiorSpaceIsInvalidAndMentionsSpaces() {
        let result = AliasValidator.validate("my alias")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
        #expect(result.errorReason?.localizedCaseInsensitiveContains("space") == true)
    }

    @Test func disallowedCharacterIsInvalid() {
        let result = AliasValidator.validate("sales!")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
    }

    @Test func leadingDotIsInvalid() {
        let result = AliasValidator.validate(".sales")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
    }

    @Test func trailingDotIsInvalid() {
        let result = AliasValidator.validate("sales.")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
    }

    @Test func doubleDotIsInvalid() {
        let result = AliasValidator.validate("sa..les")
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
    }

    @Test func tooLongIsInvalid() {
        let result = AliasValidator.validate(String(repeating: "a", count: 65))
        guard case .invalid = result else {
            Issue.record("Expected .invalid, got \(result)")
            return
        }
    }

    @Test func maxLengthBoundaryIsValid() {
        let alias = String(repeating: "a", count: 64)
        #expect(AliasValidator.validate(alias) == .valid(normalized: alias))
    }
}
