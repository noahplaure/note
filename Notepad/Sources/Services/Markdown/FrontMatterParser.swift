import Foundation

public enum FrontMatterParser {
    nonisolated(unsafe) private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let standardISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func parse(rawText: String, fallbackTitle: String = "Untitled", fileDates: (created: Date, modified: Date)? = nil) -> (metadata: NoteMetadata, body: String) {
        let trimmed = rawText
        guard trimmed.hasPrefix("---") else {
            let metadata = NoteMetadata(
                id: UUID(),
                title: extractFallbackTitle(from: rawText, fallback: fallbackTitle),
                pinned: false,
                createdAt: fileDates?.created ?? Date(),
                modifiedAt: fileDates?.modified ?? Date(),
                folder: "",
                tags: []
            )
            return (metadata, rawText)
        }

        // Search for closing ---
        let lines = rawText.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            let metadata = NoteMetadata(
                id: UUID(),
                title: extractFallbackTitle(from: rawText, fallback: fallbackTitle),
                pinned: false,
                createdAt: fileDates?.created ?? Date(),
                modifiedAt: fileDates?.modified ?? Date(),
                folder: "",
                tags: []
            )
            return (metadata, rawText)
        }

        var closingIndex: Int? = nil
        for index in 1..<lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = index
                break
            }
        }

        guard let closeIdx = closingIndex else {
            // No closing marker, treat whole file as body
            let metadata = NoteMetadata(
                id: UUID(),
                title: extractFallbackTitle(from: rawText, fallback: fallbackTitle),
                pinned: false,
                createdAt: fileDates?.created ?? Date(),
                modifiedAt: fileDates?.modified ?? Date(),
                folder: "",
                tags: []
            )
            return (metadata, rawText)
        }

        let frontMatterLines = lines[1..<closeIdx]
        var id: UUID = UUID()
        var title: String? = nil
        var pinned: Bool = false
        var createdAt: Date = fileDates?.created ?? Date()
        var modifiedAt: Date = fileDates?.modified ?? Date()
        var folder: String = ""
        var tags: [String] = []
        var colorHex: String? = nil

        for line in frontMatterLines {
            let lineTrimmed = line.trimmingCharacters(in: .whitespaces)
            guard let colonIndex = lineTrimmed.firstIndex(of: ":") else { continue }
            let key = String(lineTrimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces).lowercased()
            let rawValue = String(lineTrimmed[lineTrimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            let value = cleanYamlValue(rawValue)

            switch key {
            case "id":
                if let parsedUUID = UUID(uuidString: value) {
                    id = parsedUUID
                }
            case "title":
                if !value.isEmpty {
                    title = value
                }
            case "pinned":
                pinned = (value.lowercased() == "true" || value == "1" || value.lowercased() == "yes")
            case "createdat", "created_at", "created":
                if let date = parseDate(value) {
                    createdAt = date
                }
            case "modifiedat", "modified_at", "modified":
                if let date = parseDate(value) {
                    modifiedAt = date
                }
            case "folder":
                folder = value
            case "tags":
                tags = parseTags(value)
            case "color", "colorhex", "color_hex":
                colorHex = value.isEmpty ? nil : value
            default:
                break
            }
        }

        // Remaining lines are body
        let bodyLines = lines[(closeIdx + 1)...]
        let body = bodyLines.joined(separator: "\n")

        let finalTitle = title ?? extractFallbackTitle(from: body, fallback: fallbackTitle)

        let metadata = NoteMetadata(
            id: id,
            title: finalTitle,
            pinned: pinned,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            folder: folder,
            tags: tags,
            colorHex: colorHex
        )

        return (metadata, body)
    }

    public static func serialize(metadata: NoteMetadata, body: String) -> String {
        let createdStr = standardISO8601Formatter.string(from: metadata.createdAt)
        let modifiedStr = standardISO8601Formatter.string(from: metadata.modifiedAt)
        let escapedTitle = escapeYamlString(metadata.title)
        let escapedFolder = escapeYamlString(metadata.folder)
        let tagsFormatted = "[" + metadata.tags.map { "\"\(escapeYamlString($0))\"" }.joined(separator: ", ") + "]"

        var output = "---\n"
        output += "id: \(metadata.id.uuidString)\n"
        output += "title: \"\(escapedTitle)\"\n"
        output += "pinned: \(metadata.pinned)\n"
        output += "createdAt: \"\(createdStr)\"\n"
        output += "modifiedAt: \"\(modifiedStr)\"\n"
        if !metadata.folder.isEmpty {
            output += "folder: \"\(escapedFolder)\"\n"
        }
        if !metadata.tags.isEmpty {
            output += "tags: \(tagsFormatted)\n"
        }
        if let color = metadata.colorHex, !color.isEmpty {
            output += "colorHex: \"\(color)\"\n"
        }
        output += "---\n"
        output += body
        return output
    }

    private static func cleanYamlValue(_ value: String) -> String {
        var str = value.trimmingCharacters(in: .whitespaces)
        if (str.hasPrefix("\"") && str.hasSuffix("\"")) || (str.hasPrefix("'") && str.hasSuffix("'")) {
            str.removeFirst()
            str.removeLast()
        }
        return str
    }

    private static func escapeYamlString(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private static func parseDate(_ string: String) -> Date? {
        if let d = iso8601Formatter.date(from: string) { return d }
        if let d = standardISO8601Formatter.date(from: string) { return d }
        return nil
    }

    private static func parseTags(_ string: String) -> [String] {
        var trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            trimmed.removeFirst()
            trimmed.removeLast()
        }
        let parts = trimmed.components(separatedBy: ",")
        return parts.map { cleanYamlValue($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private static func extractFallbackTitle(from content: String, fallback: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                let candidate = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                if !candidate.isEmpty { return candidate }
            } else if !trimmed.isEmpty && !trimmed.hasPrefix("---") {
                return String(trimmed.prefix(60))
            }
        }
        return fallback
    }
}
