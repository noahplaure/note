import Foundation

public enum SyntaxLanguage: String, CaseIterable, Identifiable, Sendable {
    case swift = "swift"
    case python = "python"
    case javascript = "javascript"
    case typescript = "typescript"
    case c = "c"
    case cpp = "cpp"
    case java = "java"
    case kotlin = "kotlin"
    case go = "go"
    case rust = "rust"
    case html = "html"
    case css = "css"
    case sql = "sql"
    case bash = "bash"
    case yaml = "yaml"
    case json = "json"
    case xml = "xml"
    case markdown = "markdown"
    case plain = "text"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .c: return "C"
        case .cpp: return "C++"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .go: return "Go"
        case .rust: return "Rust"
        case .html: return "HTML"
        case .css: return "CSS"
        case .sql: return "SQL"
        case .bash: return "Bash / Shell"
        case .yaml: return "YAML"
        case .json: return "JSON"
        case .xml: return "XML"
        case .markdown: return "Markdown"
        case .plain: return "Plain Text"
        }
    }

    public static func match(from string: String) -> SyntaxLanguage {
        let cleaned = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch cleaned {
        case "swift": return .swift
        case "python", "py": return .python
        case "javascript", "js": return .javascript
        case "typescript", "ts": return .typescript
        case "c": return .c
        case "cpp", "c++": return .cpp
        case "java": return .java
        case "kotlin", "kt": return .kotlin
        case "go", "golang": return .go
        case "rust", "rs": return .rust
        case "html", "htm": return .html
        case "css", "scss", "sass": return .css
        case "sql": return .sql
        case "bash", "sh", "zsh": return .bash
        case "yaml", "yml": return .yaml
        case "json": return .json
        case "xml": return .xml
        case "md", "markdown": return .markdown
        default: return .plain
        }
    }

    public static func detect(code: String) -> SyntaxLanguage {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") && trimmed.contains("\":") {
            return .json
        }
        if trimmed.hasPrefix("<!DOCTYPE html") || (trimmed.contains("<html") && trimmed.contains("</html>")) {
            return .html
        }
        if trimmed.hasPrefix("<?xml") || (trimmed.contains("<") && trimmed.contains("</") && trimmed.contains(">")) {
            return .xml
        }
        if trimmed.contains("func ") || trimmed.contains("import SwiftUI") || trimmed.contains("var ") && trimmed.contains("guard let") {
            return .swift
        }
        if trimmed.contains("def ") || trimmed.contains("import numpy") || trimmed.contains("elif ") || trimmed.contains("__init__") {
            return .python
        }
        if trimmed.contains("const ") || trimmed.contains("let ") || trimmed.contains("=>") || trimmed.contains("console.log") {
            return trimmed.contains(": string") || trimmed.contains(": number") ? .typescript : .javascript
        }
        if trimmed.contains("#include <") {
            return trimmed.contains("std::") || trimmed.contains("cout") ? .cpp : .c
        }
        if trimmed.contains("SELECT ") && trimmed.contains(" FROM ") {
            return .sql
        }
        if trimmed.contains("fn main()") || trimmed.contains("let mut ") || trimmed.contains("impl ") {
            return .rust
        }
        if trimmed.contains("package main") || trimmed.contains("func main()") {
            return .go
        }
        if trimmed.hasPrefix("#!/bin/bash") || trimmed.hasPrefix("#!/bin/sh") || trimmed.contains("echo ") {
            return .bash
        }
        return .plain
    }

    public var keywords: Set<String> {
        switch self {
        case .swift:
            return ["import", "let", "var", "func", "struct", "class", "enum", "actor", "protocol",
                    "extension", "init", "deinit", "guard", "if", "else", "switch", "case", "default",
                    "for", "in", "while", "repeat", "return", "throw", "throws", "try", "catch",
                    "public", "private", "fileprivate", "internal", "open", "static", "final",
                    "mutating", "nonmutating", "override", "where", "self", "Self", "super",
                    "async", "await", "some", "any", "typealias", "nil", "true", "false", "break", "continue"]
        case .python:
            return ["def", "class", "import", "from", "as", "return", "if", "elif", "else",
                    "for", "while", "try", "except", "finally", "with", "yield", "lambda",
                    "pass", "break", "continue", "raise", "assert", "global", "nonlocal",
                    "True", "False", "None", "async", "await", "and", "or", "not", "is", "in"]
        case .javascript, .typescript:
            return ["function", "const", "let", "var", "class", "extends", "return", "if", "else",
                    "switch", "case", "default", "for", "while", "do", "break", "continue",
                    "try", "catch", "finally", "throw", "new", "this", "super", "import", "export",
                    "from", "default", "async", "await", "yield", "null", "undefined", "true", "false",
                    "type", "interface", "namespace", "declare", "enum", "as", "readonly"]
        case .c, .cpp:
            return ["int", "char", "float", "double", "void", "bool", "long", "short", "signed", "unsigned",
                    "struct", "class", "enum", "union", "typedef", "sizeof", "auto", "register", "static",
                    "extern", "const", "volatile", "return", "if", "else", "switch", "case", "default",
                    "for", "while", "do", "break", "continue", "goto", "namespace", "using", "public",
                    "protected", "private", "virtual", "template", "typename", "new", "delete", "this",
                    "true", "false", "nullptr", "include", "define", "ifdef", "ifndef", "endif"]
        case .java, .kotlin:
            return ["public", "private", "protected", "class", "interface", "enum", "extends",
                    "implements", "package", "import", "return", "if", "else", "switch", "case",
                    "default", "for", "while", "do", "break", "continue", "try", "catch", "finally",
                    "throw", "throws", "new", "this", "super", "final", "static", "abstract",
                    "void", "int", "boolean", "fun", "val", "var", "when", "is", "null", "true", "false"]
        case .go:
            return ["package", "import", "func", "var", "const", "type", "struct", "interface",
                    "return", "if", "else", "switch", "case", "default", "for", "range", "break",
                    "continue", "go", "select", "chan", "defer", "map", "nil", "true", "false"]
        case .rust:
            return ["fn", "let", "mut", "struct", "enum", "impl", "trait", "pub", "use", "mod",
                    "match", "if", "else", "loop", "while", "for", "in", "return", "break",
                    "continue", "unsafe", "async", "await", "move", "where", "self", "Self",
                    "true", "false", "type", "const", "static", "ref"]
        case .sql:
            return ["SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
                    "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "JOIN", "LEFT", "RIGHT",
                    "INNER", "OUTER", "ON", "GROUP", "BY", "ORDER", "ASC", "DESC", "LIMIT",
                    "HAVING", "AND", "OR", "NOT", "IN", "NULL", "PRIMARY", "KEY", "FOREIGN",
                    "select", "from", "where", "insert", "into", "values", "update", "set",
                    "delete", "create", "table", "alter", "drop", "join", "on", "group", "by", "order"]
        case .bash:
            return ["if", "then", "else", "elif", "fi", "case", "esac", "for", "while", "until",
                    "do", "done", "in", "function", "select", "time", "echo", "export", "source", "local"]
        default:
            return []
        }
    }
}
