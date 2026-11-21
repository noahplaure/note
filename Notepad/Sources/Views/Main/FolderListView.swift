import SwiftUI

public struct FolderListView: View {
    @Bindable public var viewModel: NoteListViewModel
    @State private var isNewFolderAlertPresented: Bool = false
    @State private var newFolderName: String = ""
    @State private var isSettingsPresented: Bool = false

    public init(viewModel: NoteListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List(selection: $viewModel.selectedFolder) {
                // System smart folders
                Section {
                    folderRow(folder: Folder.allNotes, count: viewModel.notes.count)
                    folderRow(folder: Folder.pinnedNotes, count: viewModel.notes.filter(\.pinned).count)
                    folderRow(folder: Folder.recentNotes, count: viewModel.notes.filter {
                        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        return $0.modifiedAt >= weekAgo
                    }.count)
                }
                .listRowBackground(Color(hex: "#1C1C1E"))

                // User custom folders
                Section("Folders") {
                    ForEach(viewModel.folders) { folder in
                        folderRow(folder: folder, count: viewModel.notes.filter { $0.folder == folder.relativePath }.count)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteFolder(folder)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                .tint(.red)
                            }
                    }
                }
                .listRowBackground(Color(hex: "#1C1C1E"))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    isNewFolderAlertPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                        Text("New Folder")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#FFD60A"))
                }

                Spacer()

                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#FFD60A"))
                }
            }
        }
        .alert("New Folder", isPresented: $isNewFolderAlertPresented) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") {
                if !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for this folder.")
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
    }

    private func folderRow(folder: Folder, count: Int) -> some View {
        NavigationLink(value: folder) {
            HStack(spacing: 12) {
                Image(systemName: folder.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#FFD60A"))
                    .frame(width: 24)

                Text(folder.name)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}
