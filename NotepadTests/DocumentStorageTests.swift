import Testing
import Foundation
@testable import Notepad

@Suite("Document Storage Service Tests")
struct DocumentStorageTests {
    @Test("Save, read and delete notes from filesystem")
    func testStorageLifecycle() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_storage_\(UUID().uuidString)", isDirectory: true)
        let storage = DocumentStorageService(customBaseURL: tempDir)

        // 1. Create and save note
        var note = Note(
            id: UUID(),
            title: "Storage Test Note",
            content: "Testing filesystem storage and atomic persistence.",
            folder: "TestingFolder",
            pinned: true
        )

        let savedNote = try await storage.saveNote(note)
        #expect(savedNote.fileURL != nil)

        // 2. Read note
        guard let url = savedNote.fileURL else {
            #expect(Bool(false), "Missing fileURL")
            return
        }
        let readNote = try await storage.readNote(from: url)
        #expect(readNote.id == note.id)
        #expect(readNote.title == "Storage Test Note")
        #expect(readNote.folder == "TestingFolder")
        #expect(readNote.pinned == true)

        // 3. Load all notes
        let allNotes = try await storage.loadAllNotes()
        #expect(allNotes.count == 1)

        // 4. Asset saving
        let dummyData = "ImageBytes".data(using: .utf8)!
        let assetPath = try await storage.saveAsset(data: dummyData, fileExtension: "jpg")
        #expect(assetPath.hasPrefix("assets/"))

        let resolvedURL = await storage.resolveAssetURL(relativePath: assetPath)
        #expect(FileManager.default.fileExists(atPath: resolvedURL.path))

        // 5. Delete note
        try await storage.deleteNote(readNote)
        let afterDelete = try await storage.loadAllNotes()
        #expect(afterDelete.isEmpty)

        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("Folder creation and listing")
    func testFolderManagement() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_folders_\(UUID().uuidString)", isDirectory: true)
        let storage = DocumentStorageService(customBaseURL: tempDir)

        let folder = try await storage.createFolder(name: "Projects")
        #expect(folder.name == "Projects")

        let folders = try await storage.listFolders()
        #expect(folders.count == 1)
        #expect(folders[0].name == "Projects")

        try? FileManager.default.removeItem(at: tempDir)
    }
}
