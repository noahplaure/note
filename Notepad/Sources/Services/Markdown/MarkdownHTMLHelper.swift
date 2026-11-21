import Foundation

public enum MarkdownHTMLHelper {
    // Regex or string scanner to parse HTML attributes
    public static func parseDivAlignment(from line: String) -> (alignment: TextAlignment, content: String)? {
        let pattern = #"^<div\s+align=["'](left|center|right|justify)["']\s*>(.*)</div>$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }

        let range = NSRange(location: 0, length: line.utf16.count)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }

        guard let alignRange = Range(match.range(at: 1), in: line),
              let contentRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let alignStr = String(line[alignRange]).lowercased()
        let align = TextAlignment(rawValue: alignStr) ?? .left
        let content = String(line[contentRange])
        return (align, content)
    }

    public static func wrapDivAlignment(_ content: String, alignment: TextAlignment) -> String {
        guard alignment != .left else { return content }
        return "<div align=\"\(alignment.rawValue)\">\(content)</div>"
    }

    public static func wrapHighlight(_ content: String, colorHex: String) -> String {
        return "<mark style=\"background:\(colorHex)\">\(content)</mark>"
    }

    public static func wrapTextColor(_ content: String, colorHex: String) -> String {
        return "<span style=\"color:\(colorHex)\">\(content)</span>"
    }

    public static func wrapUnderline(_ content: String) -> String {
        return "<u>\(content)</u>"
    }
}
