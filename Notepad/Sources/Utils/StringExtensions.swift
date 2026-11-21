import Foundation

public extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func strippedMarkdown() -> String {
        return self
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "~~", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "- [ ]", with: "")
            .replacingOccurrences(of: "- [x]", with: "")
            .replacingOccurrences(of: "- [X]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
