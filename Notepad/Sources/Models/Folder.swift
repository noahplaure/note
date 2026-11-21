import Foundation

public struct Folder: Identifiable, Sendable, Hashable, Equatable {
    public var id: String
    public var name: String
    public var relativePath: String
    public var noteCount: Int
    public var isSystem: Bool
    public var icon: String
    public var colorHex: String?

    public init(
        id: String,
        name: String,
        relativePath: String,
        noteCount: Int = 0,
        isSystem: Bool = false,
        icon: String = "folder",
        colorHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.relativePath = relativePath
        self.noteCount = noteCount
        self.isSystem = isSystem
        self.icon = icon
        self.colorHex = colorHex
    }

    public static let allNotes = Folder(
        id: "__all__",
        name: "All Notes",
        relativePath: "",
        isSystem: true,
        icon: "tray.full"
    )

    public static let pinnedNotes = Folder(
        id: "__pinned__",
        name: "Pinned",
        relativePath: "",
        isSystem: true,
        icon: "pin.fill"
    )

    public static let recentNotes = Folder(
        id: "__recent__",
        name: "Recent",
        relativePath: "",
        isSystem: true,
        icon: "clock.fill"
    )
}
