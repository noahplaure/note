import SwiftUI
import Observation

@Observable
@MainActor
public final class SettingsViewModel {
    public var fontSize: Double {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "editor_font_size")
        }
    }

    public var codeFontFamily: String {
        didSet {
            UserDefaults.standard.set(codeFontFamily, forKey: "code_font_family")
        }
    }

    public var selectedThemeId: String {
        didSet {
            UserDefaults.standard.set(selectedThemeId, forKey: "syntax_theme_id")
        }
    }

    public var autoDetectLanguage: Bool {
        didSet {
            UserDefaults.standard.set(autoDetectLanguage, forKey: "auto_detect_language")
        }
    }

    public var totalNotesCount: Int = 0
    public var totalFoldersCount: Int = 0
    public var totalAssetsSizeString: String = "0 KB"
    public var isReindexing: Bool = false
    public var reindexSuccess: Bool = false

    private let storageService: DocumentStorageService
    private let searchIndexService: SearchIndexService

    public init(
        storageService: DocumentStorageService = DocumentStorageService(),
        searchIndexService: SearchIndexService = SearchIndexService()
    ) {
        self.storageService = storageService
        self.searchIndexService = searchIndexService

        let savedSize = UserDefaults.standard.double(forKey: "editor_font_size")
        self.fontSize = savedSize > 0 ? savedSize : 16.0

        let savedFont = UserDefaults.standard.string(forKey: "code_font_family")
        self.codeFontFamily = savedFont ?? "SF Mono"

        let savedTheme = UserDefaults.standard.string(forKey: "syntax_theme_id")
        self.selectedThemeId = savedTheme ?? SyntaxTheme.vsCodeDarkPlus.id

        self.autoDetectLanguage = UserDefaults.standard.bool(forKey: "auto_detect_language")
    }

    public var currentTheme: SyntaxTheme {
        SyntaxTheme.allThemes.first(where: { $0.id == selectedThemeId }) ?? .vsCodeDarkPlus
    }

    public func refreshStorageStats() {
        Task {
            let notes = (try? await storageService.loadAllNotes()) ?? []
            let folders = (try? await storageService.listFolders()) ?? []
            let assetsDir = storageService.assetsDirectory

            var totalBytes: Int64 = 0
            if let files = try? FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: [.fileSizeKey]) {
                for fileURL in files {
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let size = values.fileSize {
                        totalBytes += Int64(size)
                    }
                }
            }

            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.countStyle = .file
            let sizeString = formatter.string(fromByteCount: totalBytes)

            await MainActor.run {
                self.totalNotesCount = notes.count
                self.totalFoldersCount = folders.count
                self.totalAssetsSizeString = sizeString
            }
        }
    }

    public func reindexAll() {
        isReindexing = true
        reindexSuccess = false
        Task {
            let notes = (try? await storageService.loadAllNotes()) ?? []
            await searchIndexService.rebuild(notes: notes)
            await MainActor.run {
                self.isReindexing = false
                self.reindexSuccess = true
                HapticManager.notification(.success)
            }
        }
    }
}
