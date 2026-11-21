import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

public struct HighlightedSpan: Sendable, Hashable {
    public let range: NSRange
    public let type: SyntaxTokenType

    public init(range: NSRange, type: SyntaxTokenType) {
        self.range = range
        self.type = type
    }
}

public final class SyntaxHighlighter: @unchecked Sendable {
    public static let shared = SyntaxHighlighter()

    public init() {}

    public func highlightSpans(code: String, language: SyntaxLanguage) -> [HighlightedSpan] {
        if language == .plain || code.isEmpty {
            return []
        }

        var spans: [HighlightedSpan] = []
        let nsCode = code as NSString
        let length = nsCode.length
        let keywords = language.keywords

        var i = 0
        while i < length {
            let char = nsCode.character(at: i)

            // Line comments: // or # (for python/bash/yaml)
            if (char == 47 /* / */ && i + 1 < length && nsCode.character(at: i + 1) == 47) ||
               (char == 35 /* # */ && (language == .python || language == .bash || language == .yaml)) {
                let start = i
                while i < length && nsCode.character(at: i) != 10 /* \n */ {
                    i += 1
                }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .comment))
                continue
            }

            // Block comments: /* ... */
            if char == 47 /* / */ && i + 1 < length && nsCode.character(at: i + 1) == 42 /* * */ {
                let start = i
                i += 2
                while i + 1 < length && !(nsCode.character(at: i) == 42 && nsCode.character(at: i + 1) == 47) {
                    i += 1
                }
                if i + 1 < length { i += 2 }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .comment))
                continue
            }

            // HTML/XML comments: <!-- ... -->
            if char == 60 /* < */ && i + 3 < length &&
               nsCode.substring(with: NSRange(location: i, length: 4)) == "<!--" {
                let start = i
                i += 4
                while i + 2 < length && !(nsCode.character(at: i) == 45 && nsCode.character(at: i + 1) == 45 && nsCode.character(at: i + 2) == 62) {
                    i += 1
                }
                if i + 2 < length { i += 3 }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .comment))
                continue
            }

            // Strings: "..." or '...'
            if char == 34 /* " */ || (char == 39 /* ' */ && language != .rust) {
                let quote = char
                let start = i
                i += 1
                var escaped = false
                while i < length {
                    let c = nsCode.character(at: i)
                    if escaped {
                        escaped = false
                    } else if c == 92 /* \ */ {
                        escaped = true
                    } else if c == quote {
                        i += 1
                        break
                    } else if c == 10 /* \n */ && !(start + 2 < length && nsCode.character(at: start + 1) == quote && nsCode.character(at: start + 2) == quote) {
                        // Single-line string ended by newline unless triple quotes
                        break
                    }
                    i += 1
                }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .string))
                continue
            }

            // Numbers: 0-9
            if (char >= 48 && char <= 57) && (i == 0 || !isIdentifierChar(nsCode.character(at: i - 1))) {
                let start = i
                while i < length && (isIdentifierChar(nsCode.character(at: i)) || nsCode.character(at: i) == 46 /* . */) {
                    i += 1
                }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .number))
                continue
            }

            // Preprocessor: #import, #include
            if char == 35 /* # */ && (language == .c || language == .cpp || language == .swift) {
                let start = i
                i += 1
                while i < length && isIdentifierChar(nsCode.character(at: i)) {
                    i += 1
                }
                spans.append(HighlightedSpan(range: NSRange(location: start, length: i - start), type: .preprocessor))
                continue
            }

            // Words: Keywords, Types, Function calls, Identifiers
            if isIdentifierStart(char) {
                let start = i
                while i < length && isIdentifierChar(nsCode.character(at: i)) {
                    i += 1
                }
                let wordLen = i - start
                let word = nsCode.substring(with: NSRange(location: start, length: wordLen))

                if keywords.contains(word) {
                    spans.append(HighlightedSpan(range: NSRange(location: start, length: wordLen), type: .keyword))
                } else if isTypeWord(word) {
                    spans.append(HighlightedSpan(range: NSRange(location: start, length: wordLen), type: .type))
                } else if i < length && nsCode.character(at: i) == 40 /* ( */ {
                    spans.append(HighlightedSpan(range: NSRange(location: start, length: wordLen), type: .function))
                }
                continue
            }

            i += 1
        }

        return spans
    }

    public func highlight(code: String, language: SyntaxLanguage, theme: SyntaxTheme = .vsCodeDarkPlus) -> AttributedString {
        var attrStr = AttributedString(code)
        let plainColor = Color(hex: theme.plainHex)
        attrStr.foregroundColor = plainColor
        attrStr.font = .system(.body, design: .monospaced)

        let spans = highlightSpans(code: code, language: language)
        let nsCode = code as NSString

        for span in spans {
            guard span.range.location + span.range.length <= nsCode.length,
                  let range = Range(span.range, in: code),
                  let attrRange = Range(range, in: attrStr) else {
                continue
            }

            let hex = theme.hex(for: span.type)
            attrStr[attrRange].foregroundColor = Color(hex: hex)
        }

        return attrStr
    }

    private func isIdentifierStart(_ c: unichar) -> Bool {
        return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 36 /* $ */
    }

    private func isIdentifierChar(_ c: unichar) -> Bool {
        return isIdentifierStart(c) || (c >= 48 && c <= 57)
    }

    private func isTypeWord(_ word: String) -> Bool {
        guard let first = word.first else { return false }
        return first.isUppercase
    }
}
