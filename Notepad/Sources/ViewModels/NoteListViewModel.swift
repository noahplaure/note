import SwiftUI
import Observation

@Observable
@MainActor
public final class NoteListViewModel {
    public var notes: [Note] = []
    public var folders: [Folder] = []
    public var selectedFolder: Folder? = Folder.allNotes
    public var selectedNote: Note? = nil

    public var searchFilter: SearchFilter = SearchFilter()
    public var sortOption: SortOption = .modifiedDescending
    public var searchResults: [SearchResult] = []
    public var isSearching: Bool = false
    public var isLoading: Bool = false

    public let storageService: DocumentStorageService
    public let searchIndexService: SearchIndexService
    public let spotlightService: SpotlightIndexService

    private var fileWatcher: FilePresenterCoordinator?

    public init(
        storageService: DocumentStorageService = DocumentStorageService(),
        searchIndexService: SearchIndexService = SearchIndexService(),
        spotlightService: SpotlightIndexService = SpotlightIndexService.shared
    ) {
        self.storageService = storageService
        self.searchIndexService = searchIndexService
        self.spotlightService = spotlightService

        setupFileWatcher()
    }

    private func setupFileWatcher() {
        Task {
            let baseDir = storageService.baseDirectory
            self.fileWatcher = FilePresenterCoordinator(directoryURL: baseDir) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.loadData()
                }
            }
        }
    }

    public func loadData() {
        isLoading = true
        Task {
            do {
                let fetchedNotes = try await storageService.loadAllNotes()
                let fetchedFolders = try await storageService.listFolders()

                await MainActor.run {
                    self.notes = fetchedNotes
                    self.folders = fetchedFolders
                    self.isLoading = false
                }

                // Background index update
                await searchIndexService.rebuild(notes: fetchedNotes)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    public var visibleNotes: [Note] {
        var result = notes

        // 1. Folder filtering
        if let folder = selectedFolder {
            if folder.id == Folder.pinnedNotes.id {
                result = result.filter { $0.pinned }
            } else if folder.id == Folder.recentNotes.id {
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                result = result.filter { $0.modifiedAt >= sevenDaysAgo }
            } else if folder.id != Folder.allNotes.id {
                result = result.filter { $0.folder == folder.relativePath }
            }
        }

        // 2. Search query filter
        if !searchFilter.query.trimmingCharacters(in: .whitespaces).isEmpty {
            let matchedIds = Set(searchResults.map(\.noteId))
            result = result.filter { matchedIds.contains($0.id) }
        }

        // 3. Metadata filters
        if searchFilter.pinnedOnly {
            result = result.filter { $0.pinned }
        }
        if searchFilter.hasImages {
            result = result.filter { $0.hasImages }
        }
        if searchFilter.hasCode {
            result = result.filter { $0.hasCodeBlocks }
        }
        if searchFilter.hasTables {
            result = result.filter { $0.hasTables }
        }
        if searchFilter.dateFilter != .all {
            let calendar = Calendar.current
            let now = Date()
            switch searchFilter.dateFilter {
            case .today:
                result = result.filter { calendar.isDateInToday($0.modifiedAt) }
            case .pastWeek:
                if let past = calendar.date(byAdding: .day, value: -7, to: now) {
                    result = result.filter { $0.modifiedAt >= past }
                }
            case .pastMonth:
                if let past = calendar.date(byAdding: .day, value: -30, to: now) {
                    result = result.filter { $0.modifiedAt >= past }
                }
            case .all:
                break
            }
        }

        // 4. Sorting: Pinned always stays on top (like Apple Notes)
        let sorted = result.sorted { a, b in
            if a.pinned != b.pinned {
                return a.pinned && !b.pinned
            }
            switch sortOption {
            case .modifiedDescending: return a.modifiedAt > b.modifiedAt
            case .modifiedAscending: return a.modifiedAt < b.modifiedAt
            case .createdDescending: return a.createdAt > b.createdAt
            case .createdAscending: return a.createdAt < b.createdAt
            case .titleAscending: return a.title.localizedStandardCompare(b.title) == .orderedAscending
            case .titleDescending: return a.title.localizedStandardCompare(b.title) == .orderedDescending
            }
        }

        return sorted
    }

    public var pinnedNotes: [Note] {
        visibleNotes.filter { $0.pinned }
    }

    public var unpinnedNotes: [Note] {
        visibleNotes.filter { !$0.pinned }
    }

    // MARK: - Actions

    public func createNote(title: String = "New Note", folder: String? = nil) -> Note {
        let targetFolder: String
        if let folder = folder {
            targetFolder = folder
        } else if let sel = selectedFolder, !sel.isSystem {
            targetFolder = sel.relativePath
        } else {
            targetFolder = ""
        }

        let newNote = Note(
            id: UUID(),
            title: title,
            content: "",
            folder: targetFolder,
            pinned: false,
            createdAt: Date(),
            modifiedAt: Date(),
            tags: []
        )

        notes.insert(newNote, at: 0)
        selectedNote = newNote
        HapticManager.impact(.medium)

        Task {
            do {
                let saved = try await storageService.saveNote(newNote)
                await MainActor.run {
                    if let idx = self.notes.firstIndex(where: { $0.id == newNote.id }) {
                        self.notes[idx] = saved
                    }
                    if self.selectedNote?.id == newNote.id {
                        self.selectedNote = saved
                    }
                }
                await searchIndexService.indexNote(saved)
                spotlightService.index(note: saved)
            } catch {
                print("Failed to save new note: \(error.localizedDescription)")
            }
        }

        return newNote
    }

    public func duplicateNote(_ note: Note) {
        var copy = note
        copy.id = UUID()
        copy.title = "\(note.title) Copy"
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        copy.fileURL = nil

        notes.insert(copy, at: 0)
        selectedNote = copy
        HapticManager.notification(.success)

        Task {
            do {
                let saved = try await storageService.saveNote(copy)
                await MainActor.run {
                    if let idx = self.notes.firstIndex(where: { $0.id == copy.id }) {
                        self.notes[idx] = saved
                    }
                }
                await searchIndexService.indexNote(saved)
                spotlightService.index(note: saved)
            } catch {
                print("Failed to duplicate note: \(error)")
            }
        }
    }

    public func togglePin(for note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].pinned.toggle()
        notes[index].modifiedAt = Date()
        let updated = notes[index]
        HapticManager.impact(.light)

        Task {
            _ = try? await storageService.saveNote(updated)
            await searchIndexService.indexNote(updated)
        }
    }

    public func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
        HapticManager.notification(.warning)

        Task {
            try? await storageService.deleteNote(note)
            await searchIndexService.removeNote(id: note.id)
            spotlightService.remove(noteId: note.id)
        }
    }

    public func moveNote(_ note: Note, toFolder relativePath: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].folder = relativePath
        notes[index].modifiedAt = Date()
        let updated = notes[index]
        HapticManager.selection()

        Task {
            do {
                let saved = try await storageService.saveNote(updated)
                await MainActor.run {
                    if let idx = self.notes.firstIndex(where: { $0.id == note.id }) {
                        self.notes[idx] = saved
                    }
                }
            } catch {
                print("Failed to move note: \(error)")
            }
        }
    }

    public func createFolder(name: String) {
        Task {
            do {
                let folder = try await storageService.createFolder(name: name)
                await MainActor.run {
                    self.folders.append(folder)
                    self.folders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                    self.selectedFolder = folder
                }
                HapticManager.notification(.success)
            } catch {
                print("Failed to create folder: \(error)")
            }
        }
    }

    public func renameFolder(_ folder: Folder, newName: String) {
        Task {
            do {
                let renamed = try await storageService.renameFolder(oldRelativePath: folder.relativePath, newName: newName)
                await MainActor.run {
                    if let idx = self.folders.firstIndex(where: { $0.id == folder.id }) {
                        self.folders[idx] = renamed
                    }
                    if self.selectedFolder?.id == folder.id {
                        self.selectedFolder = renamed
                    }
                    self.loadData()
                }
                HapticManager.notification(.success)
            } catch {
                print("Failed to rename folder: \(error)")
            }
        }
    }

    public func deleteFolder(_ folder: Folder) {
        Task {
            do {
                try await storageService.deleteFolder(relativePath: folder.relativePath)
                await MainActor.run {
                    self.folders.removeAll { $0.id == folder.id }
                    if self.selectedFolder?.id == folder.id {
                        self.selectedFolder = Folder.allNotes
                    }
                    self.loadData()
                }
                HapticManager.notification(.warning)
            } catch {
                print("Failed to delete folder: \(error)")
            }
        }
    }

    public func updateSearchQuery(_ query: String) {
        searchFilter.query = query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        Task {
            let results = await searchIndexService.search(query: query)
            await MainActor.run {
                self.searchResults = results
            }
        }
    }
}
