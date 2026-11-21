import SwiftUI

public struct NoteListView: View {
    @Bindable public var viewModel: NoteListViewModel
    @State private var isFilterSheetPresented: Bool = false
    @State private var noteToMove: Note? = nil

    public init(viewModel: NoteListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                // Search bar
                SearchBarView(
                    text: Binding(
                        get: { viewModel.searchFilter.query },
                        set: { viewModel.updateSearchQuery($0) }
                    ),
                    isFilterActive: viewModel.searchFilter.isActive
                ) {
                    isFilterSheetPresented = true
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // Note list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.visibleNotes.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Notes")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(viewModel.searchFilter.isActive ? "Try adjusting your search or filters." : "Tap the compose button to create a note.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(selection: $viewModel.selectedNote) {
                        // Pinned Section
                        if !viewModel.pinnedNotes.isEmpty && viewModel.selectedFolder?.id != Folder.pinnedNotes.id {
                            Section("Pinned") {
                                ForEach(viewModel.pinnedNotes) { note in
                                    noteRowNavigation(for: note)
                                }
                            }
                            .listRowBackground(Color(hex: "#1C1C1E"))
                        }

                        // Notes Section
                        let normalNotes = viewModel.selectedFolder?.id == Folder.pinnedNotes.id ? viewModel.pinnedNotes : viewModel.unpinnedNotes
                        if !normalNotes.isEmpty {
                            Section(viewModel.pinnedNotes.isEmpty || viewModel.selectedFolder?.id == Folder.pinnedNotes.id ? "" : "Notes") {
                                ForEach(normalNotes) { note in
                                    noteRowNavigation(for: note)
                                }
                            }
                            .listRowBackground(Color(hex: "#1C1C1E"))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(viewModel.selectedFolder?.name ?? "Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundColor(Color(hex: "#FFD60A"))
                }
            }

            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()

                    Text("\(viewModel.visibleNotes.count) Notes")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        _ = viewModel.createNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#FFD60A"))
                    }
                }
            }
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            FilterSheetView(filter: $viewModel.searchFilter)
        }
        .sheet(item: $noteToMove) { note in
            MoveNoteSheet(note: note, folders: viewModel.folders) { targetFolder in
                viewModel.moveNote(note, toFolder: targetFolder)
            }
        }
    }

    private func noteRowNavigation(for note: Note) -> some View {
        NavigationLink(value: note) {
            NoteRowView(note: note)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(for: note)
            } label: {
                Label(note.pinned ? "Unpin" : "Pin", systemImage: note.pinned ? "pin.slash.fill" : "pin.fill")
            }
            .tint(Color(hex: "#FFD60A"))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteNote(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                noteToMove = note
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.purple)
        }
        .contextMenu {
            Button {
                viewModel.togglePin(for: note)
            } label: {
                Label(note.pinned ? "Unpin" : "Pin Note", systemImage: note.pinned ? "pin.slash" : "pin")
            }

            Button {
                viewModel.duplicateNote(note)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Button {
                noteToMove = note
            } label: {
                Label("Move to Folder", systemImage: "folder")
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteNote(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

public struct FilterSheetView: View {
    @Binding public var filter: SearchFilter
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section("Date Modified") {
                        Picker("Modified", selection: $filter.dateFilter) {
                            ForEach(DateFilter.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    Section("Content Contains") {
                        Toggle("Has Images", isOn: $filter.hasImages)
                        Toggle("Has Code Blocks", isOn: $filter.hasCode)
                        Toggle("Has Tables", isOn: $filter.hasTables)
                        Toggle("Pinned Only", isOn: $filter.pinnedOnly)
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    if filter.isActive {
                        Section {
                            Button("Reset All Filters", role: .destructive) {
                                filter = SearchFilter()
                                dismiss()
                            }
                        }
                        .listRowBackground(Color(hex: "#1C1C1E"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#FFD60A"))
                }
            }
        }
    }
}

public struct MoveNoteSheet: View {
    public let note: Note
    public let folders: [Folder]
    public var onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Button {
                        onSelect("")
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundColor(Color(hex: "#FFD60A"))
                            Text("All Notes (Root)")
                                .foregroundColor(.white)
                            Spacer()
                            if note.folder.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#FFD60A"))
                            }
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    ForEach(folders) { folder in
                        Button {
                            onSelect(folder.relativePath)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(Color(hex: "#FFD60A"))
                                Text(folder.name)
                                    .foregroundColor(.white)
                                Spacer()
                                if note.folder == folder.relativePath {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#FFD60A"))
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "#1C1C1E"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Move Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
