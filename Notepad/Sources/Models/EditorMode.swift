import Foundation

public enum EditorMode: String, CaseIterable, Identifiable, Sendable {
    case wysiwyg = "WYSIWYG"
    case source = "Source"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .wysiwyg: return "doc.richtext"
        case .source: return "chevron.left.forwardslash.chevron.right"
        }
    }
}
