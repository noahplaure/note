import Foundation

public enum TextAlignment: String, Sendable, Hashable, Equatable, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"
    case justify = "justify"

    public var iconName: String {
        switch self {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justify: return "text.justify"
        }
    }
}

public enum ColumnAlignment: String, Sendable, Hashable, Equatable {
    case none = "none"
    case left = "left"
    case center = "center"
    case right = "right"
}

public struct TableModel: Sendable, Hashable, Equatable {
    public var headers: [String]
    public var alignments: [ColumnAlignment]
    public var rows: [[String]]

    public init(headers: [String] = [], alignments: [ColumnAlignment] = [], rows: [[String]] = []) {
        self.headers = headers
        self.alignments = alignments.isEmpty ? Array(repeating: .none, count: headers.count) : alignments
        self.rows = rows
    }

    public var columnCount: Int {
        max(headers.count, rows.first?.count ?? 0)
    }

    public var rowCount: Int {
        rows.count
    }
}

public indirect enum InlineNode: Sendable, Hashable, Equatable {
    case text(String)
    case bold([InlineNode])
    case italic([InlineNode])
    case underline([InlineNode])
    case strikethrough([InlineNode])
    case code(String)
    case highlight(colorHex: String, inlines: [InlineNode])
    case textColor(colorHex: String, inlines: [InlineNode])
    case link(title: String, destination: String)
    case image(alt: String, url: String)

    public var plainText: String {
        switch self {
        case .text(let s), .code(let s):
            return s
        case .bold(let inlines), .italic(let inlines), .underline(let inlines),
             .strikethrough(let inlines), .highlight(_, let inlines), .textColor(_, let inlines):
            return inlines.map(\.plainText).joined()
        case .link(let title, _):
            return title
        case .image(let alt, _):
            return alt
        }
    }
}

public struct ListItemNode: Sendable, Hashable, Equatable {
    public var inlines: [InlineNode]
    public var nestedList: BlockNode?

    public init(inlines: [InlineNode], nestedList: BlockNode? = nil) {
        self.inlines = inlines
        self.nestedList = nestedList
    }
}

public struct TaskItemNode: Sendable, Hashable, Equatable {
    public var isCompleted: Bool
    public var inlines: [InlineNode]
    public var nestedList: BlockNode?

    public init(isCompleted: Bool, inlines: [InlineNode], nestedList: BlockNode? = nil) {
        self.isCompleted = isCompleted
        self.inlines = inlines
        self.nestedList = nestedList
    }
}

public indirect enum BlockNode: Sendable, Hashable, Equatable {
    case heading(level: Int, inlines: [InlineNode], alignment: TextAlignment)
    case paragraph(inlines: [InlineNode], alignment: TextAlignment)
    case codeBlock(language: String, code: String)
    case blockquote(children: [BlockNode])
    case bulletList(items: [ListItemNode])
    case orderedList(startIndex: Int, items: [ListItemNode])
    case taskList(items: [TaskItemNode])
    case table(tableData: TableModel)
    case thematicBreak
    case rawHTML(String)
}

public struct MarkdownDocument: Sendable, Hashable, Equatable {
    public var blocks: [BlockNode]

    public init(blocks: [BlockNode] = []) {
        self.blocks = blocks
    }
}
