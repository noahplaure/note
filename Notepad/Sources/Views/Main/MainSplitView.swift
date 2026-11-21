import SwiftUI

public struct MainSplitView: View {
    @Bindable public var viewModel: NoteListViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(viewModel: NoteListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FolderListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 400)
        } detail: {
            if let note = viewModel.selectedNote {
                NoteEditorView(
                    viewModel: NoteEditorViewModel(
                        note: note,
                        storageService: viewModel.storageService,
                        searchIndexService: viewModel.searchIndexService,
                        spotlightService: viewModel.spotlightService
                    )
                )
            } else {
                detailEmptyPlaceholder
            }
        }
        .accentColor(Color(hex: "#FFD60A"))
        .onAppear {
            viewModel.loadData()
        }
    }

    private var detailEmptyPlaceholder: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "note.text")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "#FFD60A").opacity(0.8))

                Text("No Note Selected")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Select a note from the sidebar or tap the button below to create one.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                Button {
                    _ = viewModel.createNote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Create Note")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#FFD60A"))
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}
