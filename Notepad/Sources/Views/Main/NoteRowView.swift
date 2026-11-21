import SwiftUI

public struct NoteRowView: View {
    public let note: Note

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#FFD60A"))
                }

                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text(note.formattedModifiedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text(note.previewSnippet)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8E8E93"))
                .lineLimit(2)

            // Badges row
            HStack(spacing: 6) {
                if !note.folder.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(note.folder)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
                }

                if note.hasImages {
                    Image(systemName: "photo")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if note.hasCodeBlocks {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                if note.hasTables {
                    Image(systemName: "tablecells")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if note.hasChecklists {
                    Image(systemName: "checklist")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}
