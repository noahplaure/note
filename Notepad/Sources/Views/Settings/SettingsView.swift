import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    // Typography
                    Section("Editor Typography") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(Int(viewModel.fontSize)) pt")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }

                            Slider(value: $viewModel.fontSize, in: 12...26, step: 1)
                                .tint(Color(hex: "#FFD60A"))
                        }

                        Picker("Code Font", selection: $viewModel.codeFontFamily) {
                            Text("SF Mono").tag("SF Mono")
                            Text("Menlo").tag("Menlo")
                            Text("Courier New").tag("Courier")
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    // Syntax Highlighting
                    Section("Syntax Highlighting") {
                        Picker("Theme", selection: $viewModel.selectedThemeId) {
                            ForEach(SyntaxTheme.allThemes) { theme in
                                Text(theme.name).tag(theme.id)
                            }
                        }

                        Toggle("Auto-Detect Language", isOn: $viewModel.autoDetectLanguage)
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))

                    // Storage & Indexing
                    Section("Storage & Search Index") {
                        HStack {
                            Text("Total Notes")
                            Spacer()
                            Text("\(viewModel.totalNotesCount)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Folders")
                            Spacer()
                            Text("\(viewModel.totalFoldersCount)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Image Assets Size")
                            Spacer()
                            Text(viewModel.totalAssetsSizeString)
                                .foregroundColor(.secondary)
                        }

                        Button {
                            viewModel.reindexAll()
                        } label: {
                            HStack {
                                Text("Rebuild Search Index (FTS5)")
                                    .foregroundColor(Color(hex: "#FFD60A"))
                                Spacer()
                                if viewModel.isReindexing {
                                    ProgressView()
                                } else if viewModel.reindexSuccess {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color(hex: "#1C1C1E"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#FFD60A"))
                }
            }
            .onAppear {
                viewModel.refreshStorageStats()
            }
        }
    }
}
