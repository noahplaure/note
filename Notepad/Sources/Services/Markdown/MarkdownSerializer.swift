import Foundation

public final class MarkdownSerializer: @unchecked Sendable {
    public init() {}

    public func serialize(_ document: MarkdownDocument) -> String {
        var blocksOutput: [String] = []

        for block in document.blocks {
            let serializedBlock = serializeBlock(block)
            if !serializedBlock.isEmpty {
                blocksOutput.append(serializedBlock)
            }
        }

        return blocksOutput.joined(separator: "\n\n")
    }

    // MARK: - Block Serialization

    public func serializeBlock(_ block: BlockNode) -> String {
        switch block {
        case .heading(let level, let inlines, let alignment):
            let hashes = String(repeating: "#", count: min(6, max(1, level)))
            let text = serializeInlines(inlines)
            let headingText = "\(hashes) \(text)"
            return MarkdownHTMLHelper.wrapDivAlignment(headingText, alignment: alignment)

        case .paragraph(let inlines, let alignment):
            let text = serializeInlines(inlines)
            return MarkdownHTMLHelper.wrapDivAlignment(text, alignment: alignment)

        case .codeBlock(let language, let code):
            let fence = "```"
            return "\(fence)\(language)\n\(code)\n\(fence)"

        case .blockquote(let children):
            let innerDoc = MarkdownDocument(blocks: children)
            let innerText = serialize(innerDoc)
            let lines = innerText.components(separatedBy: .newlines)
            return lines.map { "> \($0)" }.joined(separator: "\n")

        case .bulletList(let items):
            var lines: [String] = []
            for item in items {
                let text = serializeInlines(item.inlines)
                lines.append("- \(text)")
                if let nested = item.nestedList {
                    let nestedText = serializeBlock(nested)
                    let nestedLines = nestedText.components(separatedBy: .newlines)
                    lines.append(contentsOf: nestedLines.map { "  \($0)" })
                }
            }
            return lines.joined(separator: "\n")

        case .orderedList(let startIndex, let items):
            var lines: [String] = []
            var currentIndex = startIndex
            for item in items {
                let text = serializeInlines(item.inlines)
                lines.append("\(currentIndex). \(text)")
                currentIndex += 1
                if let nested = item.nestedList {
                    let nestedText = serializeBlock(nested)
                    let nestedLines = nestedText.components(separatedBy: .newlines)
                    lines.append(contentsOf: nestedLines.map { "   \($0)" })
                }
            }
            return lines.joined(separator: "\n")

        case .taskList(let items):
            var lines: [String] = []
            for item in items {
                let box = item.isCompleted ? "- [x]" : "- [ ]"
                let text = serializeInlines(item.inlines)
                lines.append("\(box) \(text)")
                if let nested = item.nestedList {
                    let nestedText = serializeBlock(nested)
                    let nestedLines = nestedText.components(separatedBy: .newlines)
                    lines.append(contentsOf: nestedLines.map { "  \($0)" })
                }
            }
            return lines.joined(separator: "\n")

        case .table(let tableData):
            return serializeTable(tableData)

        case .thematicBreak:
            return "---"

        case .rawHTML(let html):
            return html
        }
    }

    // MARK: - Inline Serialization

    public func serializeInlines(_ inlines: [InlineNode]) -> String {
        return inlines.map { serializeInline($0) }.joined()
    }

    public func serializeInline(_ inline: InlineNode) -> String {
        switch inline {
        case .text(let str):
            return str
        case .bold(let inlines):
            return "**\(serializeInlines(inlines))**"
        case .italic(let inlines):
            return "*\(serializeInlines(inlines))*"
        case .underline(let inlines):
            return MarkdownHTMLHelper.wrapUnderline(serializeInlines(inlines))
        case .strikethrough(let inlines):
            return "~~\(serializeInlines(inlines))~~"
        case .code(let str):
            return "`\(str)`"
        case .highlight(let colorHex, let inlines):
            return MarkdownHTMLHelper.wrapHighlight(serializeInlines(inlines), colorHex: colorHex)
        case .textColor(let colorHex, let inlines):
            return MarkdownHTMLHelper.wrapTextColor(serializeInlines(inlines), colorHex: colorHex)
        case .link(let title, let destination):
            return "[\(title)](\(destination))"
        case .image(let alt, let url):
            return "![\(alt)](\(url))"
        }
    }

    // MARK: - Table Serialization

    public func serializeTable(_ table: TableModel) -> String {
        let colCount = table.columnCount
        guard colCount > 0 else { return "" }

        // Headers
        var paddedHeaders = table.headers
        while paddedHeaders.count < colCount {
            paddedHeaders.append("")
        }
        let headerRow = "| " + paddedHeaders.joined(separator: " | ") + " |"

        // Delimiters with alignment
        var delimiterParts: [String] = []
        for i in 0..<colCount {
            let align = i < table.alignments.count ? table.alignments[i] : .none
            switch align {
            case .left:
                delimiterParts.append(":---")
            case .center:
                delimiterParts.append(":---:")
            case .right:
                delimiterParts.append("---:")
            case .none:
                delimiterParts.append("---")
            }
        }
        let delimiterRow = "| " + delimiterParts.joined(separator: " | ") + " |"

        // Rows
        var rowLines: [String] = []
        for row in table.rows {
            var paddedRow = row
            while paddedRow.count < colCount {
                paddedRow.append("")
            }
            let rowLine = "| " + paddedRow.joined(separator: " | ") + " |"
            rowLines.append(rowLine)
        }

        var fullLines = [headerRow, delimiterRow]
        fullLines.append(contentsOf: rowLines)
        return fullLines.joined(separator: "\n")
    }
}
