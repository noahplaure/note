import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public enum SyntaxTokenType: Sendable, Hashable {
    case keyword
    case type
    case string
    case number
    case comment
    case function
    case property
    case preprocessor
    case plain
}

public struct SyntaxTheme: Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String

    // Hex strings
    public var backgroundHex: String
    public var plainHex: String
    public var keywordHex: String
    public var typeHex: String
    public var stringHex: String
    public var numberHex: String
    public var commentHex: String
    public var functionHex: String
    public var propertyHex: String
    public var preprocessorHex: String

    public init(
        id: String,
        name: String,
        backgroundHex: String = "#1E1E1E",
        plainHex: String = "#D4D4D4",
        keywordHex: String = "#C586C0",
        typeHex: String = "#4EC9B0",
        stringHex: String = "#CE9178",
        numberHex: String = "#B5CEA8",
        commentHex: String = "#6A9955",
        functionHex: String = "#DCDCAA",
        propertyHex: String = "#9CDCFE",
        preprocessorHex: String = "#569CD6"
    ) {
        self.id = id
        self.name = name
        self.backgroundHex = backgroundHex
        self.plainHex = plainHex
        self.keywordHex = keywordHex
        self.typeHex = typeHex
        self.stringHex = stringHex
        self.numberHex = numberHex
        self.commentHex = commentHex
        self.functionHex = functionHex
        self.propertyHex = propertyHex
        self.preprocessorHex = preprocessorHex
    }

    public func hex(for token: SyntaxTokenType) -> String {
        switch token {
        case .keyword: return keywordHex
        case .type: return typeHex
        case .string: return stringHex
        case .number: return numberHex
        case .comment: return commentHex
        case .function: return functionHex
        case .property: return propertyHex
        case .preprocessor: return preprocessorHex
        case .plain: return plainHex
        }
    }

    public static let vsCodeDarkPlus = SyntaxTheme(
        id: "vscode-dark",
        name: "VS Code Dark+",
        backgroundHex: "#1E1E1E",
        plainHex: "#D4D4D4",
        keywordHex: "#C586C0",
        typeHex: "#4EC9B0",
        stringHex: "#CE9178",
        numberHex: "#B5CEA8",
        commentHex: "#6A9955",
        functionHex: "#DCDCAA",
        propertyHex: "#9CDCFE",
        preprocessorHex: "#569CD6"
    )

    public static let xcodeDark = SyntaxTheme(
        id: "xcode-dark",
        name: "Xcode Dark",
        backgroundHex: "#1F1F24",
        plainHex: "#E3E3E3",
        keywordHex: "#FC5FA3",
        typeHex: "#5DD8FF",
        stringHex: "#FC6A5D",
        numberHex: "#D0BF69",
        commentHex: "#6C7986",
        functionHex: "#A167E6",
        propertyHex: "#41A1C0",
        preprocessorHex: "#FD8F3F"
    )

    public static let monokai = SyntaxTheme(
        id: "monokai",
        name: "Monokai",
        backgroundHex: "#272822",
        plainHex: "#F8F8F2",
        keywordHex: "#F92672",
        typeHex: "#66D9EF",
        stringHex: "#E6DB74",
        numberHex: "#AE81FF",
        commentHex: "#75715E",
        functionHex: "#A6E22E",
        propertyHex: "#FD971F",
        preprocessorHex: "#F92672"
    )

    public static let allThemes: [SyntaxTheme] = [
        .vsCodeDarkPlus,
        .xcodeDark,
        .monokai
    ]
}
