import Foundation

public final class MarkdownParser: @unchecked Sendable {
    public init() {}

    public func parse(_ markdown: String) -> MarkdownDocument {
        let lines = markdown.components(separatedBy: .newlines)
        var blocks: [BlockNode] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Blank line
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Div alignment wrapper check: <div align="...">...</div>
            if let divMatch = MarkdownHTMLHelper.parseDivAlignment(from: trimmed) {
                let inner = divMatch.content
                if inner.hasPrefix("#") {
                    if let heading = parseHeadingLine(inner, forcedAlignment: divMatch.alignment) {
                        blocks.append(heading)
                        i += 1
                        continue
                    }
                }
                let inlines = parseInlines(inner)
                blocks.append(.paragraph(inlines: inlines, alignment: divMatch.alignment))
                i += 1
                continue
            }

            // Fenced code block: ```lang or ~~~lang
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let fence = String(trimmed.prefix(3))
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count {
                    let cLine = lines[i]
                    if cLine.trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                        i += 1
                        break
                    }
                    codeLines.append(cLine)
                    i += 1
                }
                blocks.append(.codeBlock(language: lang, code: codeLines.joined(separator: "\n")))
                continue
            }

            // Thematic break: ---, ***, ___ (at least 3 characters)
            if isThematicBreak(trimmed) {
                blocks.append(.thematicBreak)
                i += 1
                continue
            }

            // Heading: # to ######
            if let heading = parseHeadingLine(trimmed, forcedAlignment: .left) {
                blocks.append(heading)
                i += 1
                continue
            }

            // Blockquote: > text
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    let qLine = lines[i].trimmingCharacters(in: .whitespaces)
                    let text = qLine.dropFirst().trimmingCharacters(in: .whitespaces)
                    quoteLines.append(text)
                    i += 1
                }
                let innerDoc = parse(quoteLines.joined(separator: "\n"))
                blocks.append(.blockquote(children: innerDoc.blocks))
                continue
            }

            // GFM Table: header row with | and next row is delimiter with |---|
            if isTableRow(trimmed) && i + 1 < lines.count && isTableDelimiterRow(lines[i + 1].trimmingCharacters(in: .whitespaces)) {
                let table = parseTable(lines: lines, startIndex: &i)
                blocks.append(.table(tableData: table))
                continue
            }

            // Task list item: - [ ] or - [x] or * [ ] or * [x]
            if isTaskListItem(trimmed) {
                var taskItems: [TaskItemNode] = []
                while i < lines.count && isTaskListItem(lines[i].trimmingCharacters(in: .whitespaces)) {
                    let itemLine = lines[i].trimmingCharacters(in: .whitespaces)
                    let (isCompleted, content) = parseTaskItem(itemLine)
                    taskItems.append(TaskItemNode(isCompleted: isCompleted, inlines: parseInlines(content)))
                    i += 1
                }
                blocks.append(.taskList(items: taskItems))
                continue
            }

            // Bullet list item: - , * , + 
            if isBulletListItem(trimmed) {
                var listItems: [ListItemNode] = []
                while i < lines.count && isBulletListItem(lines[i].trimmingCharacters(in: .whitespaces)) && !isTaskListItem(lines[i].trimmingCharacters(in: .whitespaces)) {
                    let itemLine = lines[i].trimmingCharacters(in: .whitespaces)
                    let content = parseBulletItemContent(itemLine)
                    listItems.append(ListItemNode(inlines: parseInlines(content)))
                    i += 1
                }
                blocks.append(.bulletList(items: listItems))
                continue
            }

            // Ordered list item: 1. 
            if isOrderedListItem(trimmed) {
                var listItems: [ListItemNode] = []
                let startIndex = parseOrderedListStartIndex(trimmed)
                while i < lines.count && isOrderedListItem(lines[i].trimmingCharacters(in: .whitespaces)) {
                    let itemLine = lines[i].trimmingCharacters(in: .whitespaces)
                    let content = parseOrderedItemContent(itemLine)
                    listItems.append(ListItemNode(inlines: parseInlines(content)))
                    i += 1
                }
                blocks.append(.orderedList(startIndex: startIndex, items: listItems))
                continue
            }

            // Standard Paragraph: accumulate until blank line or block start
            var paraLines: [String] = []
            while i < lines.count {
                let pLine = lines[i]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)
                if pTrimmed.isEmpty || pTrimmed.hasPrefix("#") || pTrimmed.hasPrefix("```") ||
                   pTrimmed.hasPrefix("~~~") || isThematicBreak(pTrimmed) || pTrimmed.hasPrefix(">") ||
                   isTableRow(pTrimmed) || isTaskListItem(pTrimmed) || isBulletListItem(pTrimmed) ||
                   isOrderedListItem(pTrimmed) || pTrimmed.hasPrefix("<div") {
                    break
                }
                paraLines.append(pLine)
                i += 1
            }

            if !paraLines.isEmpty {
                let joined = paraLines.joined(separator: "\n")
                let inlines = parseInlines(joined)
                blocks.append(.paragraph(inlines: inlines, alignment: .left))
            }
        }

        return MarkdownDocument(blocks: blocks)
    }

    // MARK: - Inline Parsing

    public func parseInlines(_ text: String) -> [InlineNode] {
        if text.isEmpty { return [] }
        var result: [InlineNode] = []
        var cursor = text.startIndex

        while cursor < text.endIndex {
            let remaining = text[cursor...]

            // Image: ![alt](url)
            if remaining.hasPrefix("!["),
               let closeBracket = remaining.firstIndex(of: "]"),
               remaining.index(after: closeBracket) < text.endIndex,
               text[remaining.index(after: closeBracket)] == "(",
               let closeParen = text[remaining.index(after: closeBracket)...].firstIndex(of: ")") {
                let alt = String(text[text.index(cursor, offsetBy: 2)..<closeBracket])
                let urlStart = text.index(closeBracket, offsetBy: 2)
                let url = String(text[urlStart..<closeParen])
                result.append(.image(alt: alt, url: url))
                cursor = text.index(after: closeParen)
                continue
            }

            // Link: [text](url)
            if remaining.hasPrefix("["),
               let closeBracket = remaining.firstIndex(of: "]"),
               remaining.index(after: closeBracket) < text.endIndex,
               text[remaining.index(after: closeBracket)] == "(",
               let closeParen = text[remaining.index(after: closeBracket)...].firstIndex(of: ")") {
                let title = String(text[text.index(after: cursor)..<closeBracket])
                let urlStart = text.index(closeBracket, offsetBy: 2)
                let destination = String(text[urlStart..<closeParen])
                result.append(.link(title: title, destination: destination))
                cursor = text.index(after: closeParen)
                continue
            }

            // Inline Code: `code`
            if remaining.hasPrefix("`") {
                let afterTick = text.index(after: cursor)
                if let nextTick = text[afterTick...].firstIndex(of: "`") {
                    let code = String(text[afterTick..<nextTick])
                    result.append(.code(code))
                    cursor = text.index(after: nextTick)
                    continue
                }
            }

            // Underline: <u>text</u>
            if remaining.lowercased().hasPrefix("<u>") {
                let startTagEnd = text.index(cursor, offsetBy: 3)
                if let endTagRange = text[startTagEnd...].range(of: "</u>", options: .caseInsensitive) {
                    let inner = String(text[startTagEnd..<endTagRange.lowerBound])
                    result.append(.underline(parseInlines(inner)))
                    cursor = endTagRange.upperBound
                    continue
                }
            }

            // Highlight: <mark style="background:#RRGGBB">text</mark> or <mark>text</mark>
            if remaining.lowercased().hasPrefix("<mark") {
                if let tagEnd = remaining.firstIndex(of: ">") {
                    let tagContent = String(text[cursor...tagEnd])
                    var colorHex = "#FFD60A"
                    if let bgRange = tagContent.range(of: "background:") {
                        let colorPart = tagContent[bgRange.upperBound...].components(separatedBy: CharacterSet(charactersIn: "\";>"))
                        if let first = colorPart.first?.trimmingCharacters(in: .whitespaces), !first.isEmpty {
                            colorHex = first
                        }
                    }
                    let innerStart = text.index(after: tagEnd)
                    if let closeRange = text[innerStart...].range(of: "</mark>", options: .caseInsensitive) {
                        let inner = String(text[innerStart..<closeRange.lowerBound])
                        result.append(.highlight(colorHex: colorHex, inlines: parseInlines(inner)))
                        cursor = closeRange.upperBound
                        continue
                    }
                }
            }

            // Text Color: <span style="color:#RRGGBB">text</span>
            if remaining.lowercased().hasPrefix("<span") {
                if let tagEnd = remaining.firstIndex(of: ">") {
                    let tagContent = String(text[cursor...tagEnd])
                    var colorHex = "#FFFFFF"
                    if let cRange = tagContent.range(of: "color:") {
                        let colorPart = tagContent[cRange.upperBound...].components(separatedBy: CharacterSet(charactersIn: "\";>"))
                        if let first = colorPart.first?.trimmingCharacters(in: .whitespaces), !first.isEmpty {
                            colorHex = first
                        }
                    }
                    let innerStart = text.index(after: tagEnd)
                    if let closeRange = text[innerStart...].range(of: "</span>", options: .caseInsensitive) {
                        let inner = String(text[innerStart..<closeRange.lowerBound])
                        result.append(.textColor(colorHex: colorHex, inlines: parseInlines(inner)))
                        cursor = closeRange.upperBound
                        continue
                    }
                }
            }

            // Bold: **text** or __text__
            if remaining.hasPrefix("**") || remaining.hasPrefix("__") {
                let marker = String(remaining.prefix(2))
                let innerStart = text.index(cursor, offsetBy: 2)
                if let closeRange = text[innerStart...].range(of: marker) {
                    let inner = String(text[innerStart..<closeRange.lowerBound])
                    result.append(.bold(parseInlines(inner)))
                    cursor = closeRange.upperBound
                    continue
                }
            }

            // Strikethrough: ~~text~~
            if remaining.hasPrefix("~~") {
                let innerStart = text.index(cursor, offsetBy: 2)
                if let closeRange = text[innerStart...].range(of: "~~") {
                    let inner = String(text[innerStart..<closeRange.lowerBound])
                    result.append(.strikethrough(parseInlines(inner)))
                    cursor = closeRange.upperBound
                    continue
                }
            }

            // Italic: *text* or _text_
            if remaining.hasPrefix("*") || remaining.hasPrefix("_") {
                let marker = String(remaining.prefix(1))
                let innerStart = text.index(cursor, offsetBy: 1)
                if let closeRange = text[innerStart...].range(of: marker) {
                    let inner = String(text[innerStart..<closeRange.lowerBound])
                    // Only treat as italic if not empty and doesn't span newlines
                    if !inner.isEmpty && !inner.contains("\n") {
                        result.append(.italic(parseInlines(inner)))
                        cursor = closeRange.upperBound
                        continue
                    }
                }
            }

            // Plain text chunk until next special character
            let specialChars = CharacterSet(charactersIn: "*_`[<!~")
            var nextSpecialIndex = cursor
            while nextSpecialIndex < text.endIndex {
                let char = text[nextSpecialIndex]
                if let scalar = char.unicodeScalars.first, specialChars.contains(scalar) {
                    break
                }
                nextSpecialIndex = text.index(after: nextSpecialIndex)
            }

            if nextSpecialIndex == cursor {
                // Char was a special char that didn't form a token, treat as single text char
                result.append(.text(String(text[cursor])))
                cursor = text.index(after: cursor)
            } else {
                let plain = String(text[cursor..<nextSpecialIndex])
                result.append(.text(plain))
                cursor = nextSpecialIndex
            }
        }

        return mergeAdjacentTextNodes(result)
    }

    private func mergeAdjacentTextNodes(_ inlines: [InlineNode]) -> [InlineNode] {
        var merged: [InlineNode] = []
        for node in inlines {
            if case .text(let str) = node {
                if case .text(let prevStr)? = merged.last {
                    merged.removeLast()
                    merged.append(.text(prevStr + str))
                } else {
                    merged.append(node)
                }
            } else {
                merged.append(node)
            }
        }
        return merged
    }

    // MARK: - Block Parsing Helpers

    private func parseHeadingLine(_ line: String, forcedAlignment: TextAlignment) -> BlockNode? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex && line[idx] == "#" && level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        guard level > 0 && idx < line.endIndex && line[idx] == " " else {
            return nil
        }
        let text = String(line[idx...]).trimmingCharacters(in: .whitespaces)
        return .heading(level: level, inlines: parseInlines(text), alignment: forcedAlignment)
    }

    private func isThematicBreak(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        if stripped.count < 3 { return false }
        return stripped.allSatisfy { $0 == "-" } ||
               stripped.allSatisfy { $0 == "*" } ||
               stripped.allSatisfy { $0 == "_" }
    }

    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.contains("|")
    }

    private func isTableDelimiterRow(_ line: String) -> Bool {
        guard isTableRow(line) else { return false }
        let clean = line.trimmingCharacters(in: CharacterSet(charactersIn: "| \t"))
        let parts = clean.components(separatedBy: "|")
        guard !parts.isEmpty else { return false }
        return parts.allSatisfy { part in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            return trimmed.contains("-") && trimmed.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private func parseTable(lines: [String], startIndex: inout Int) -> TableModel {
        let headerLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let delimiterLine = lines[startIndex + 1].trimmingCharacters(in: .whitespaces)
        startIndex += 2

        let headers = splitTableRow(headerLine)
        let alignments = parseTableAlignments(delimiterLine, count: headers.count)

        var rows: [[String]] = []
        while startIndex < lines.count {
            let rowLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
            guard isTableRow(rowLine) else { break }
            let cells = splitTableRow(rowLine)
            rows.append(cells)
            startIndex += 1
        }

        return TableModel(headers: headers, alignments: alignments, rows: rows)
    }

    private func splitTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        let parts = trimmed.components(separatedBy: "|")
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func parseTableAlignments(_ line: String, count: Int) -> [ColumnAlignment] {
        let parts = splitTableRow(line)
        var alignments: [ColumnAlignment] = []
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            let hasLeftColon = trimmed.hasPrefix(":")
            let hasRightColon = trimmed.hasSuffix(":")
            if hasLeftColon && hasRightColon {
                alignments.append(.center)
            } else if hasLeftColon {
                alignments.append(.left)
            } else if hasRightColon {
                alignments.append(.right)
            } else {
                alignments.append(.none)
            }
        }
        while alignments.count < count {
            alignments.append(.none)
        }
        return alignments
    }

    private func isTaskListItem(_ line: String) -> Bool {
        return line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") ||
               line.hasPrefix("* [ ] ") || line.hasPrefix("* [x] ") || line.hasPrefix("* [X] ")
    }

    private func parseTaskItem(_ line: String) -> (isCompleted: Bool, content: String) {
        let isDone = line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") || line.hasPrefix("* [x] ") || line.hasPrefix("* [X] ")
        let content = String(line.dropFirst(6))
        return (isDone, content)
    }

    private func isBulletListItem(_ line: String) -> Bool {
        return line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    private func parseBulletItemContent(_ line: String) -> String {
        return String(line.dropFirst(2))
    }

    private func isOrderedListItem(_ line: String) -> Bool {
        guard let dotIndex = line.firstIndex(of: ".") else { return false }
        let numStr = String(line[..<dotIndex])
        guard Int(numStr) != nil else { return false }
        let remainder = line[dotIndex...]
        return remainder.hasPrefix(". ")
    }

    private func parseOrderedListStartIndex(_ line: String) -> Int {
        guard let dotIndex = line.firstIndex(of: ".") else { return 1 }
        let numStr = String(line[..<dotIndex])
        return Int(numStr) ?? 1
    }

    private func parseOrderedItemContent(_ line: String) -> String {
        guard let dotIndex = line.firstIndex(of: ".") else { return line }
        let remainder = line[dotIndex...]
        return String(remainder.dropFirst(2))
    }
}
