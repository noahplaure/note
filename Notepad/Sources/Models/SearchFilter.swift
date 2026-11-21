import Foundation

public enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case modifiedDescending = "Date Modified (Newest)"
    case modifiedAscending = "Date Modified (Oldest)"
    case createdDescending = "Date Created (Newest)"
    case createdAscending = "Date Created (Oldest)"
    case titleAscending = "Title (A-Z)"
    case titleDescending = "Title (Z-A)"

    public var id: String { rawValue }
}

public enum DateFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Any Time"
    case today = "Today"
    case pastWeek = "Past 7 Days"
    case pastMonth = "Past 30 Days"

    public var id: String { rawValue }
}

public struct SearchFilter: Sendable, Hashable, Equatable {
    public var query: String = ""
    public var folderId: String? = nil
    public var dateFilter: DateFilter = .all
    public var hasImages: Bool = false
    public var hasCode: Bool = false
    public var hasTables: Bool = false
    public var pinnedOnly: Bool = false

    public init(
        query: String = "",
        folderId: String? = nil,
        dateFilter: DateFilter = .all,
        hasImages: Bool = false,
        hasCode: Bool = false,
        hasTables: Bool = false,
        pinnedOnly: Bool = false
    ) {
        self.query = query
        self.folderId = folderId
        self.dateFilter = dateFilter
        self.hasImages = hasImages
        self.hasCode = hasCode
        self.hasTables = hasTables
        self.pinnedOnly = pinnedOnly
    }

    public var isActive: Bool {
        !query.isEmpty ||
        folderId != nil ||
        dateFilter != .all ||
        hasImages ||
        hasCode ||
        hasTables ||
        pinnedOnly
    }
}
