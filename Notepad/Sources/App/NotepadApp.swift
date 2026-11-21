import SwiftUI

@main
struct NotepadApp: App {
    @State private var viewModel = NoteListViewModel()

    init() {
        #if canImport(UIKit)
        // Force OLED dark mode globally
        UIView.appearance().tintColor = UIColor(hex: "#FFD60A")
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainSplitView(viewModel: viewModel)
                .preferredColorScheme(.dark)
                .tint(Color(hex: "#FFD60A"))
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    _ = viewModel.createNote()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button("Find in Notes") {
                    // Activate search
                    viewModel.isSearching = true
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
    }
}
