import Foundation

public struct NoteMetadata: Sendable, Hashable, Codable {
    public var id: UUID
    public var title: String
    public var pinned: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    public var folder: String
    public var tags: [String]
    public var colorHex: String?

    public init(
        id: UUID = UUID(),
        title: String = "New Note",
        pinned: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        folder: String = "",
        tags: [String] = [],
        colorHex: String? = nil
    ) {
        self.id = id
        self.title = title
        self.pinned = pinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.folder = folder
        self.tags = tags
        self.colorHex = colorHex
    }
}
