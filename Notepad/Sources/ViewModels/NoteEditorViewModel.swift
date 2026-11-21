import SwiftUI
import Observation

@Observable
@MainActor
public final class NoteEditorViewModel {
    public var note: Note
    public var mode: EditorMode = .wysiwyg
    public var title: String
    public var content: String
    public var selectedRange: NSRange = NSRange(location: 0, length: 0)

    // Find and Replace
    public var isFindAndReplaceVisible: Bool = false
    public var findQuery: String = ""
    public var replaceQuery: String = ""
    public var currentMatchIndex: Int = 0
    public var matchRanges: [NSRange] = []

    // Sheets & Popovers
    public var isFormatSheetPresented: Bool = false
    public var isTableSheetPresented: Bool = false
    public var isImageSheetPresented: Bool = false
    public var isInfoSheetPresented: Bool = false
    public var isShareSheetPresented: Bool = false
    public var isSaving: Bool = false

    private let storageService: DocumentStorageService
    private let searchIndexService: SearchIndexService
    private let spotlightService: SpotlightIndexService
    private let debouncer = Debouncer(delay: 0.6)

    public init(
        note: Note,
        storageService: DocumentStorageService = DocumentStorageService(),
        searchIndexService: SearchIndexService = SearchIndexService(),
        spotlightService: SpotlightIndexService = SpotlightIndexService.shared
    ) {
        self.note = note
        self.title = note.title
        self.content = note.content
        self.storageService = storageService
        self.searchIndexService = searchIndexService
        self.spotlightService = spotlightService
    }

    public func updateTitle(_ newTitle: String) {
        self.title = newTitle
        self.note.title = newTitle
        scheduleAutoSave()
    }

    public func updateContent(_ newContent: String) {
        self.content = newContent
        self.note.content = newContent
        scheduleAutoSave()
        if isFindAndReplaceVisible && !findQuery.isEmpty {
            updateFindMatches()
        }
    }

    public func scheduleAutoSave() {
        isSaving = true
        debouncer.call { [weak self] in
            guard let self = self else { return }
            await self.forceSave()
        }
    }

    public func forceSave() async {
        note.title = title
        note.content = content
        note.modifiedAt = Date()

        do {
            let saved = try await storageService.saveNote(note)
            self.note = saved
            self.isSaving = false
            await searchIndexService.indexNote(saved)
            spotlightService.index(note: saved)
        } catch {
            self.isSaving = false
            print("AutoSave failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Formatting Helpers

    public func toggleBold() {
        wrapSelection(prefix: "**", suffix: "**")
    }

    public func toggleItalic() {
        wrapSelection(prefix: "*", suffix: "*")
    }

    public func toggleUnderline() {
        wrapSelection(prefix: "<u>", suffix: "</u>")
    }

    public func toggleStrikethrough() {
        wrapSelection(prefix: "~~", suffix: "~~")
    }

    public func toggleInlineCode() {
        wrapSelection(prefix: "`", suffix: "`")
    }

    public func setHeading(level: Int) {
        let hashes = String(repeating: "#", count: level)
        prefixCurrentLine(with: "\(hashes) ")
    }

    public func toggleBulletList() {
        prefixCurrentLine(with: "- ")
    }

    public func toggleNumberedList() {
        prefixCurrentLine(with: "1. ")
    }

    public func toggleChecklist() {
        prefixCurrentLine(with: "- [ ] ")
    }

    public func toggleBlockquote() {
        prefixCurrentLine(with: "> ")
    }

    public func insertHorizontalRule() {
        insertTextAtCursor("\n\n---\n\n")
    }

    public func setAlignment(_ alignment: TextAlignment) {
        guard alignment != .left else { return }
        wrapSelection(prefix: "<div align=\"\(alignment.rawValue)\">", suffix: "</div>")
    }

    public func applyHighlight(colorHex: String) {
        wrapSelection(prefix: "<mark style=\"background:\(colorHex)\">", suffix: "</mark>")
    }

    public func applyTextColor(colorHex: String) {
        wrapSelection(prefix: "<span style=\"color:\(colorHex)\">", suffix: "</span>")
    }

    public func clearFormatting() {
        let nsText = content as NSString
        guard selectedRange.location != NSNotFound,
              selectedRange.location + selectedRange.length <= nsText.length,
              selectedRange.length > 0 else {
            return
        }

        let selected = nsText.substring(with: selectedRange)
        let cleaned = selected
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "<u>", with: "")
            .replacingOccurrences(of: "</u>", with: "")
            .replacingOccurrences(of: "~~", with: "")
            .replacingOccurrences(of: "`", with: "")

        let newText = nsText.replacingCharacters(in: selectedRange, with: cleaned)
        updateContent(newText)
        selectedRange = NSRange(location: selectedRange.location, length: (cleaned as NSString).length)
        HapticManager.impact(.light)
    }

    public func insertTable(rows: Int = 3, cols: Int = 3) {
        var tableText = "\n\n| "
        for c in 1...cols {
            tableText += "Col \(c) | "
        }
        tableText += "\n| "
        for _ in 1...cols {
            tableText += ":--- | "
        }
        tableText += "\n"
        for r in 1...rows {
            tableText += "| "
            for c in 1...cols {
                tableText += "R\(r)C\(c) | "
            }
            tableText += "\n"
        }
        tableText += "\n"
        insertTextAtCursor(tableText)
    }

    public func insertCodeBlock(language: String, code: String = "") {
        let placeholder = code.isEmpty ? "\n// Write your code here\n" : "\n\(code)\n"
        let block = "\n```\(language)\(placeholder)```\n"
        insertTextAtCursor(block)
    }

    public func insertImage(relativePath: String, alt: String = "Image") {
        let markdown = "\n![\(alt)](\(relativePath))\n"
        insertTextAtCursor(markdown)
    }

    // MARK: - Find and Replace

    public func updateFindMatches() {
        guard !findQuery.isEmpty else {
            matchRanges = []
            currentMatchIndex = 0
            return
        }

        let nsText = content as NSString
        var ranges: [NSRange] = []
        var searchRange = NSRange(location: 0, length: nsText.length)

        while searchRange.location < nsText.length {
            let found = nsText.range(of: findQuery, options: .caseInsensitive, range: searchRange)
            if found.location != NSNotFound {
                ranges.append(found)
                let nextLoc = found.location + max(1, found.length)
                searchRange = NSRange(location: nextLoc, length: nsText.length - nextLoc)
            } else {
                break
            }
        }

        self.matchRanges = ranges
        if currentMatchIndex >= ranges.count {
            currentMatchIndex = max(0, ranges.count - 1)
        }
    }

    public func findNext() {
        guard !matchRanges.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchRanges.count
        selectedRange = matchRanges[currentMatchIndex]
        HapticManager.selection()
    }

    public func findPrevious() {
        guard !matchRanges.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchRanges.count) % matchRanges.count
        selectedRange = matchRanges[currentMatchIndex]
        HapticManager.selection()
    }

    public func replaceCurrent() {
        guard !matchRanges.isEmpty, currentMatchIndex < matchRanges.count else { return }
        let targetRange = matchRanges[currentMatchIndex]
        let nsText = content as NSString
        let newContent = nsText.replacingCharacters(in: targetRange, with: replaceQuery)
        updateContent(newContent)
        updateFindMatches()
        HapticManager.impact(.light)
    }

    public func replaceAll() {
        guard !findQuery.isEmpty else { return }
        let newContent = content.replacingOccurrences(of: findQuery, with: replaceQuery, options: .caseInsensitive)
        updateContent(newContent)
        updateFindMatches()
        HapticManager.notification(.success)
    }

    // MARK: - Text Editing Helpers

    private func wrapSelection(prefix: String, suffix: String) {
        let nsText = content as NSString
        guard selectedRange.location != NSNotFound,
              selectedRange.location + selectedRange.length <= nsText.length else {
            insertTextAtCursor("\(prefix)\(suffix)")
            return
        }

        if selectedRange.length == 0 {
            insertTextAtCursor("\(prefix)\(suffix)")
            selectedRange = NSRange(location: selectedRange.location + (prefix as NSString).length, length: 0)
        } else {
            let selectedText = nsText.substring(with: selectedRange)
            let wrapped = "\(prefix)\(selectedText)\(suffix)"
            let newText = nsText.replacingCharacters(in: selectedRange, with: wrapped)
            updateContent(newText)
            selectedRange = NSRange(location: selectedRange.location + (prefix as NSString).length, length: selectedRange.length)
        }
        HapticManager.impact(.light)
    }

    private func prefixCurrentLine(with prefix: String) {
        let nsText = content as NSString
        let loc = min(selectedRange.location, nsText.length)
        let lineRange = nsText.lineRange(for: NSRange(location: loc, length: 0))
        let line = nsText.substring(with: lineRange)

        let newLine: String
        if line.hasPrefix(prefix) {
            newLine = String(line.dropFirst(prefix.count))
        } else {
            newLine = prefix + line
        }

        let newContent = nsText.replacingCharacters(in: lineRange, with: newLine)
        updateContent(newContent)
        HapticManager.impact(.light)
    }

    private func insertTextAtCursor(_ text: String) {
        let nsText = content as NSString
        let loc = min(selectedRange.location, nsText.length)
        let len = selectedRange.length
        let safeRange = NSRange(location: loc, length: min(len, nsText.length - loc))
        let newContent = nsText.replacingCharacters(in: safeRange, with: text)
        updateContent(newContent)
        selectedRange = NSRange(location: loc + (text as NSString).length, length: 0)
        HapticManager.impact(.light)
    }
}
