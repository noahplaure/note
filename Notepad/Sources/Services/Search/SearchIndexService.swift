import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public struct SearchResult: Identifiable, Sendable, Hashable {
    public var id: UUID { noteId }
    public let noteId: UUID
    public let title: String
    public let folder: String
    public let snippet: String
    public let rank: Double

    public init(noteId: UUID, title: String, folder: String, snippet: String, rank: Double) {
        self.noteId = noteId
        self.title = title
        self.folder = folder
        self.snippet = snippet
        self.rank = rank
    }
}

public actor SearchIndexService {
    private var db: OpaquePointer?
    private let dbPath: String

    public init(customPath: String? = nil) {
        if let customPath = customPath {
            self.dbPath = customPath
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            self.dbPath = appSupport.appendingPathComponent("notepad_fts5.sqlite").path
        }
        openDatabase()
        createTable()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            db = nil
        }
    }

    private func createTable() {
        guard let db = db else { return }
        let sql = """
        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
            id UNINDEXED,
            title,
            content,
            folder,
            tags,
            tokenize='unicode61'
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    public func indexNote(_ note: Note) {
        guard let db = db else { return }
        removeNote(id: note.id)

        let insertSQL = "INSERT INTO notes_fts(id, title, content, folder, tags) VALUES(?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            let idStr = note.id.uuidString
            let titleStr = note.title
            let contentStr = note.content
            let folderStr = note.folder
            let tagsStr = note.tags.joined(separator: " ")

            sqlite3_bind_text(stmt, 1, (idStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, (titleStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, (contentStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, (folderStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 5, (tagsStr as NSString).utf8String, -1, SQLITE_TRANSIENT)

            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    public func removeNote(id: UUID) {
        guard let db = db else { return }
        let deleteSQL = "DELETE FROM notes_fts WHERE id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK {
            let idStr = id.uuidString
            sqlite3_bind_text(stmt, 1, (idStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    public func rebuild(notes: [Note]) {
        guard let db = db else { return }
        sqlite3_exec(db, "DELETE FROM notes_fts;", nil, nil, nil)
        for note in notes {
            indexNote(note)
        }
    }

    public func search(query: String) -> [SearchResult] {
        guard let db = db else { return [] }
        let cleanQuery = sanitizeQuery(query)
        guard !cleanQuery.isEmpty else { return [] }

        // FTS5 MATCH query with snippet extraction
        let searchSQL = """
        SELECT id, title, folder, snippet(notes_fts, 2, '<b>', '</b>', '...', 12), rank
        FROM notes_fts
        WHERE notes_fts MATCH ?
        ORDER BY rank;
        """

        var stmt: OpaquePointer?
        var results: [SearchResult] = []

        if sqlite3_prepare_v2(db, searchSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (cleanQuery as NSString).utf8String, -1, SQLITE_TRANSIENT)

            while sqlite3_step(stmt) == SQLITE_ROW {
                if let idRaw = sqlite3_column_text(stmt, 0),
                   let titleRaw = sqlite3_column_text(stmt, 1),
                   let folderRaw = sqlite3_column_text(stmt, 2),
                   let snippetRaw = sqlite3_column_text(stmt, 3) {

                    let idStr = String(cString: idRaw)
                    let title = String(cString: titleRaw)
                    let folder = String(cString: folderRaw)
                    let snippet = String(cString: snippetRaw)
                    let rank = sqlite3_column_double(stmt, 4)

                    if let uuid = UUID(uuidString: idStr) {
                        results.append(SearchResult(
                            noteId: uuid,
                            title: title,
                            folder: folder,
                            snippet: snippet,
                            rank: rank
                        ))
                    }
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    private func sanitizeQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        // Clean characters that break FTS5 syntax
        let safe = trimmed.replacingOccurrences(of: "\"", with: "")
                          .replacingOccurrences(of: "'", with: "")
                          .replacingOccurrences(of: "*", with: "")
        let words = safe.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        // Append prefix matching to last word for instantaneous as-you-type search
        guard !words.isEmpty else { return "" }
        let terms = words.map { "\"\($0)\"*" }
        return terms.joined(separator: " ")
    }
}
