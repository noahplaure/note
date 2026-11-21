import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

public final class SpotlightIndexService: @unchecked Sendable {
    public static let shared = SpotlightIndexService()

    public init() {}

    public func index(note: Note) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .plainText)
        attributeSet.title = note.title
        attributeSet.contentDescription = note.previewSnippet
        attributeSet.textContent = note.content
        attributeSet.contentModificationDate = note.modifiedAt
        attributeSet.keywords = note.tags + [note.folder]

        let item = CSSearchableItem(
            uniqueIdentifier: note.id.uuidString,
            domainIdentifier: "com.notepad.app.notes",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("CoreSpotlight indexing error: \(error.localizedDescription)")
            }
        }
    }

    public func remove(noteId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [noteId.uuidString]) { error in
            if let error = error {
                print("CoreSpotlight deletion error: \(error.localizedDescription)")
            }
        }
    }

    public func removeAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.notepad.app.notes"]) { error in
            if let error = error {
                print("CoreSpotlight clear error: \(error.localizedDescription)")
            }
        }
    }
}
