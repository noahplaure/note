import Foundation

public actor DocumentStorageService {
    public let baseDirectory: URL
    public let assetsDirectory: URL

    private let fileManager = FileManager.default

    public init(customBaseURL: URL? = nil) {
        if let customBaseURL = customBaseURL {
            self.baseDirectory = customBaseURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.baseDirectory = documents.appendingPathComponent("Notepad", isDirectory: true)
        }
        self.assetsDirectory = self.baseDirectory.appendingPathComponent("assets", isDirectory: true)
        ensureDirectoriesExist()
    }

    public func ensureDirectoriesExist() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: assetsDirectory.path) {
            try? fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Notes Loading & Reading

    public func loadAllNotes() throws -> [Note] {
        ensureDirectoriesExist()
        var notes: [Note] = []

        let keys: [URLResourceKey] = [.isDirectoryKey, .creationDateKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: baseDirectory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }
            // Ignore anything in assets
            if fileURL.path.contains("/assets/") || fileURL.path.contains("\\assets\\") {
                continue
            }

            if let note = try? readNote(from: fileURL) {
                notes.append(note)
            }
        }

        return notes
    }

    public func readNote(from url: URL) throws -> Note {
        let content = try String(contentsOf: url, encoding: .utf8)
        let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let created = resourceValues?.creationDate ?? Date()
        let modified = resourceValues?.contentModificationDate ?? Date()

        let filenameWithoutExt = url.deletingPathExtension().lastPathComponent
        let parsed = FrontMatterParser.parse(
            rawText: content,
            fallbackTitle: filenameWithoutExt,
            fileDates: (created: created, modified: modified)
        )

        // Derive relative folder
        let relativeFolder = relativeFolderPath(for: url)

        var note = Note(
            id: parsed.metadata.id,
            title: parsed.metadata.title,
            content: parsed.body,
            folder: parsed.metadata.folder.isEmpty ? relativeFolder : parsed.metadata.folder,
            pinned: parsed.metadata.pinned,
            createdAt: parsed.metadata.createdAt,
            modifiedAt: parsed.metadata.modifiedAt,
            tags: parsed.metadata.tags,
            colorHex: parsed.metadata.colorHex,
            fileURL: url
        )

        return note
    }

    // MARK: - Save Note

    public func saveNote(_ note: Note) throws -> Note {
        ensureDirectoriesExist()

        var updatedNote = note
        updatedNote.modifiedAt = Date()

        let folderURL = folderURL(for: updatedNote.folder)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        let targetURL: URL
        if let existingURL = updatedNote.fileURL, fileManager.fileExists(atPath: existingURL.path) {
            // Check if folder or title changed significantly
            let currentFolder = relativeFolderPath(for: existingURL)
            if currentFolder == updatedNote.folder {
                targetURL = existingURL
            } else {
                // Moved folder: remove old, determine new
                try? fileManager.removeItem(at: existingURL)
                targetURL = generateUniqueURL(for: updatedNote, in: folderURL)
            }
        } else {
            targetURL = generateUniqueURL(for: updatedNote, in: folderURL)
        }

        let serialized = FrontMatterParser.serialize(metadata: updatedNote.metadata, body: updatedNote.content)
        guard let data = serialized.data(using: .utf8) else {
            throw DocumentStorageError.serializationFailed
        }

        // Atomic write with data protection
        try data.write(to: targetURL, options: .atomic)

        updatedNote.fileURL = targetURL
        return updatedNote
    }

    public func deleteNote(_ note: Note) throws {
        guard let url = note.fileURL else { return }
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Folders

    public func listFolders() throws -> [Folder] {
        ensureDirectoriesExist()
        var folders: [Folder] = []

        let items = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in items {
            let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues?.isDirectory == true {
                let name = item.lastPathComponent
                if name == "assets" { continue }

                let relative = name
                let count = countNotesInFolder(url: item)
                folders.append(Folder(
                    id: relative,
                    name: name,
                    relativePath: relative,
                    noteCount: count,
                    isSystem: false,
                    icon: "folder"
                ))
            }
        }

        return folders.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func createFolder(name: String) throws -> Folder {
        let sanitized = sanitizeFilename(name)
        guard !sanitized.isEmpty else {
            throw DocumentStorageError.invalidFolderName
        }
        let dirURL = baseDirectory.appendingPathComponent(sanitized, isDirectory: true)
        if !fileManager.fileExists(atPath: dirURL.path) {
            try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }
        return Folder(id: sanitized, name: sanitized, relativePath: sanitized, noteCount: 0)
    }

    public func renameFolder(oldRelativePath: String, newName: String) throws -> Folder {
        let sanitized = sanitizeFilename(newName)
        let oldURL = baseDirectory.appendingPathComponent(oldRelativePath, isDirectory: true)
        let newURL = baseDirectory.appendingPathComponent(sanitized, isDirectory: true)

        guard fileManager.fileExists(atPath: oldURL.path) else {
            throw DocumentStorageError.folderNotFound
        }

        try fileManager.moveItem(at: oldURL, to: newURL)
        let count = countNotesInFolder(url: newURL)
        return Folder(id: sanitized, name: sanitized, relativePath: sanitized, noteCount: count)
    }

    public func deleteFolder(relativePath: String) throws {
        let dirURL = baseDirectory.appendingPathComponent(relativePath, isDirectory: true)
        if fileManager.fileExists(atPath: dirURL.path) {
            try fileManager.removeItem(at: dirURL)
        }
    }

    // MARK: - Assets / Images

    public func saveAsset(data: Data, fileExtension: String = "jpg") throws -> String {
        ensureDirectoriesExist()
        let filename = "\(UUID().uuidString).\(fileExtension.lowercased())"
        let fileURL = assetsDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        return "assets/\(filename)"
    }

    public func resolveAssetURL(relativePath: String) -> URL {
        let clean = relativePath.trimmingCharacters(in: .whitespaces)
        if clean.hasPrefix("assets/") || clean.hasPrefix("assets\\") {
            let filename = String(clean.dropFirst(7))
            return assetsDirectory.appendingPathComponent(filename)
        }
        return baseDirectory.appendingPathComponent(clean)
    }

    // MARK: - Helpers

    private func folderURL(for relativeFolder: String) -> URL {
        if relativeFolder.isEmpty {
            return baseDirectory
        }
        return baseDirectory.appendingPathComponent(relativeFolder, isDirectory: true)
    }

    private func relativeFolderPath(for fileURL: URL) -> String {
        let parentURL = fileURL.deletingLastPathComponent()
        if parentURL.standardizedFileURL.path == baseDirectory.standardizedFileURL.path {
            return ""
        }
        return parentURL.lastPathComponent
    }

    private func countNotesInFolder(url: URL) -> Int {
        guard let items = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return 0
        }
        return items.filter { $0.pathExtension.lowercased() == "md" }.count
    }

    private func generateUniqueURL(for note: Note, in folderURL: URL) -> URL {
        let titleCandidate = sanitizeFilename(note.title)
        let baseName = titleCandidate.isEmpty ? "Note" : titleCandidate
        var candidateURL = folderURL.appendingPathComponent("\(baseName).md")

        var counter = 1
        while fileManager.fileExists(atPath: candidateURL.path) {
            candidateURL = folderURL.appendingPathComponent("\(baseName) \(counter).md")
            counter += 1
        }
        return candidateURL
    }

    private func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let components = name.components(separatedBy: invalidCharacters)
        let clean = components.joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        return String(clean.prefix(80))
    }
}

public enum DocumentStorageError: Error, LocalizedError {
    case serializationFailed
    case invalidFolderName
    case folderNotFound

    public var errorDescription: String? {
        switch self {
        case .serializationFailed: return "Failed to serialize note data."
        case .invalidFolderName: return "The folder name provided is invalid."
        case .folderNotFound: return "The specified folder was not found."
        }
    }
}
