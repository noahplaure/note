import Testing
import Foundation
@testable import Notepad

@Suite("Search Index FTS5 Tests")
struct SearchIndexTests {
    @Test("FTS5 Indexing and Full-Text Search")
    func testIndexingAndSearch() async {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_fts5_\(UUID().uuidString).sqlite").path
        let service = SearchIndexService(customPath: dbPath)

        let note1 = Note(
            id: UUID(),
            title: "Swift 6 Strict Concurrency",
            content: "Modern Swift concurrency uses actors, async-await, and Sendable protocols to prevent data races.",
            folder: "Development"
        )

        let note2 = Note(
            id: UUID(),
            title: "Shopping List",
            content: "Buy apples, milk, and dark coffee beans for the morning.",
            folder: "Personal"
        )

        await service.indexNote(note1)
        await service.indexNote(note2)

        let resultsSwift = await service.search(query: "concurrency")
        #expect(resultsSwift.count == 1)
        #expect(resultsSwift[0].noteId == note1.id)
        #expect(resultsSwift[0].title == "Swift 6 Strict Concurrency")

        let resultsCoffee = await service.search(query: "coffee")
        #expect(resultsCoffee.count == 1)
        #expect(resultsCoffee[0].noteId == note2.id)

        // Test deletion
        await service.removeNote(id: note1.id)
        let resultsAfterDelete = await service.search(query: "concurrency")
        #expect(resultsAfterDelete.isEmpty)

        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
