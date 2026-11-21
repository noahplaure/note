import Testing
import Foundation
@testable import Notepad

@Suite("YAML Front Matter Tests")
struct FrontMatterTests {
    @Test("Parse YAML front matter with all fields")
    func testFullFrontMatterParse() {
        let input = """
        ---
        id: "550E8400-E29B-41D4-A716-446655440000"
        title: "Architecture Review"
        pinned: true
        createdAt: "2026-11-21T06:00:00Z"
        modifiedAt: "2026-11-21T06:30:00Z"
        folder: "Work"
        tags: ["ios", "swift6"]
        colorHex: "#FFD60A"
        ---
        # Notes
        Body content here.
        """

        let (metadata, body) = FrontMatterParser.parse(rawText: input)

        #expect(metadata.id == UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000"))
        #expect(metadata.title == "Architecture Review")
        #expect(metadata.pinned == true)
        #expect(metadata.folder == "Work")
        #expect(metadata.tags == ["ios", "swift6"])
        #expect(metadata.colorHex == "#FFD60A")
        #expect(body.contains("# Notes"))
        #expect(body.contains("Body content here."))
    }

    @Test("Round trip front matter serialization")
    func testFrontMatterRoundTrip() {
        let originalMetadata = NoteMetadata(
            id: UUID(),
            title: "Round Trip Note",
            pinned: false,
            createdAt: Date(),
            modifiedAt: Date(),
            folder: "Projects",
            tags: ["dev", "testing"],
            colorHex: "#30D158"
        )
        let originalBody = "### Title\n\nSome great note content."

        let serialized = FrontMatterParser.serialize(metadata: originalMetadata, body: originalBody)
        let (parsedMeta, parsedBody) = FrontMatterParser.parse(rawText: serialized)

        #expect(parsedMeta.id == originalMetadata.id)
        #expect(parsedMeta.title == originalMetadata.title)
        #expect(parsedMeta.pinned == originalMetadata.pinned)
        #expect(parsedMeta.folder == originalMetadata.folder)
        #expect(parsedMeta.tags == originalMetadata.tags)
        #expect(parsedMeta.colorHex == originalMetadata.colorHex)
        #expect(parsedBody == originalBody)
    }

    @Test("Fallback when no front matter is present")
    func testNoFrontMatterFallback() {
        let plain = """
        # My Plain Markdown
        This is an imported file without metadata header.
        """
        let (metadata, body) = FrontMatterParser.parse(rawText: plain, fallbackTitle: "Fallback")
        #expect(metadata.title == "My Plain Markdown")
        #expect(metadata.pinned == false)
        #expect(body == plain)
    }
}
