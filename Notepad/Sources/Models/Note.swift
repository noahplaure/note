import Foundation

public struct Note: Identifiable, Sendable, Hashable, Equatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var folder: String
    public var pinned: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    public var tags: [String]
    public var colorHex: String?
    public var fileURL: URL?

    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        folder: String = "",
        pinned: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        tags: [String] = [],
        colorHex: String? = nil,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.pinned = pinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.tags = tags
        self.colorHex = colorHex
        self.fileURL = fileURL
    }

    public var metadata: NoteMetadata {
        NoteMetadata(
            id: id,
            title: title,
            pinned: pinned,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            folder: folder,
            tags: tags,
            colorHex: colorHex
        )
    }

    public var rawMarkdownWithFrontMatter: String {
        FrontMatterParser.serialize(metadata: metadata, body: content)
    }

    public var characterCount: Int {
        content.count
    }

    public var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    public var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    public var hasImages: Bool {
        content.contains("![") || content.contains("<img")
    }

    public var hasCodeBlocks: Bool {
        content.contains("```")
    }

    public var hasTables: Bool {
        content.contains("|---") || content.contains("|:--") || content.contains("| ---")
    }

    public var hasChecklists: Bool {
        content.contains("- [ ]") || content.contains("- [x]") || content.contains("- [X]")
    }

    public var previewSnippet: String {
        let lines = content.components(separatedBy: .newlines)
        var preview = ""
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("---") {
                continue
            }
            // Strip markdown formatting for snippet
            var cleaned = trimmed
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "`", with: "")
                .replacingOccurrences(of: "~~", with: "")
                .replacingOccurrences(of: "- [ ]", with: "☐ ")
                .replacingOccurrences(of: "- [x]", with: "☑ ")
                .replacingOccurrences(of: "- ", with: "• ")

            if !cleaned.isEmpty {
                if !preview.isEmpty { preview += " " }
                preview += cleaned
                if preview.count > 120 { break }
            }
        }
        return preview.isEmpty ? "No additional text" : String(preview.prefix(120))
    }

    public var formattedModifiedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(modifiedAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: modifiedAt)
        } else if calendar.isDateInYesterday(modifiedAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            return formatter.string(from: modifiedAt)
        }
    }
}
