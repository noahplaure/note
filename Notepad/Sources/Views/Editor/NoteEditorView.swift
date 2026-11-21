import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct NoteEditorView: View {
    @Bindable public var viewModel: NoteEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var exportedURL: URL? = nil
    @State private var isExportActivityPresented: Bool = false
    @State private var isCustomTablePresented: Bool = false

    public init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Title & Mode Bar
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        TextField("Title", text: $viewModel.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .onChange(of: viewModel.title) { _, newTitle in
                                viewModel.updateTitle(newTitle)
                            }

                        Spacer()

                        // Mode Picker (WYSIWYG vs Source)
                        Picker("Editor Mode", selection: $viewModel.mode) {
                            ForEach(EditorMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Find and replace bar if active
                    if viewModel.isFindAndReplaceVisible {
                        FindAndReplaceBar(viewModel: viewModel)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.top, 8)

                // Editor Content Surface
                ZStack {
                    if viewModel.mode == .wysiwyg {
                        #if canImport(UIKit)
                        TextKitEditorView(
                            text: $viewModel.content,
                            selectedRange: $viewModel.selectedRange,
                            fontSize: 16.0
                        ) { newText in
                            viewModel.updateContent(newText)
                        }
                        #else
                        TextEditor(text: $viewModel.content)
                            .scrollContentBackground(.hidden)
                            .background(Color.black)
                        #endif
                    } else {
                        MarkdownSourceEditorView(
                            text: $viewModel.content,
                            selectedRange: $viewModel.selectedRange,
                            fontSize: 15.0
                        ) { newText in
                            viewModel.updateContent(newText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Keyboard accessory toolbar
            VStack(spacing: 4) {
                if viewModel.isSaving {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Saving...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }

                EditorToolbarView(viewModel: viewModel)
            }
            .padding(.bottom, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Info Button
                Button {
                    viewModel.isInfoSheetPresented = true
                    HapticManager.selection()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: "info")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#FFD60A"))
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)

                // Share Menu
                Menu {
                    Button {
                        if let url = ExportService.shared.exportMarkdownFile(note: viewModel.note) {
                            exportedURL = url
                            isExportActivityPresented = true
                        }
                    } label: {
                        Label("Share as Markdown (.md)", systemImage: "doc.text")
                    }

                    Button {
                        #if canImport(UIKit)
                        if let url = ExportService.shared.exportPDF(note: viewModel.note) {
                            exportedURL = url
                            isExportActivityPresented = true
                        }
                        #endif
                    } label: {
                        Label("Export as PDF", systemImage: "doc.richtext")
                    }

                    Button {
                        if let url = ExportService.shared.exportPlainTextFile(note: viewModel.note) {
                            exportedURL = url
                            isExportActivityPresented = true
                        }
                    } label: {
                        Label("Share as Plain Text", systemImage: "text.alignleft")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#FFD60A"))
                            .offset(y: -1) // Optical centering for upward arrow
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
        // Sheets
        .sheet(isPresented: $viewModel.isTableSheetPresented) {
            TableEditorSheet { table in
                let serializer = MarkdownSerializer()
                let markdownTable = "\n\n" + serializer.serializeTable(table) + "\n\n"
                viewModel.updateContent(viewModel.content + markdownTable)
            }
        }
        .sheet(isPresented: $viewModel.isImageSheetPresented) {
            ImageAttachmentSheet { assetRelativePath in
                viewModel.insertImage(relativePath: assetRelativePath)
            }
        }
        .sheet(isPresented: $viewModel.isInfoSheetPresented) {
            NoteInfoSheet(note: viewModel.note)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $isExportActivityPresented) {
            if let url = exportedURL {
                ShareActivitySheet(activityItems: [url])
            }
        }
        #endif
    }
}

public struct NoteInfoSheet: View {
    public let note: Note
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section("Statistics") {
                        statRow(label: "Words", value: "\(note.wordCount)")
                        statRow(label: "Characters", value: "\(note.characterCount)")
                        statRow(label: "Reading Time", value: "~\(note.readingTimeMinutes) min")
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    Section("Dates & Storage") {
                        statRow(label: "Modified", value: note.formattedModifiedDate)
                        statRow(label: "Folder", value: note.folder.isEmpty ? "All Notes (Root)" : note.folder)
                        if let url = note.fileURL {
                            statRow(label: "File Path", value: url.lastPathComponent)
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    Section("Elements") {
                        statRow(label: "Has Images", value: note.hasImages ? "Yes" : "No")
                        statRow(label: "Has Code Blocks", value: note.hasCodeBlocks ? "Yes" : "No")
                        statRow(label: "Has Tables", value: note.hasTables ? "Yes" : "No")
                        statRow(label: "Has Checklists", value: note.hasChecklists ? "Yes" : "No")
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#FFD60A"))
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.system(.body, design: .monospaced))
        }
    }
}

#if canImport(UIKit)
public struct ShareActivitySheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
