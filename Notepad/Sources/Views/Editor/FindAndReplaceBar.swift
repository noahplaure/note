import SwiftUI

public struct FindAndReplaceBar: View {
    @Bindable public var viewModel: NoteEditorViewModel

    public init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Find Row
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    TextField("Find in note", text: $viewModel.findQuery)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                        .onChange(of: viewModel.findQuery) { _, _ in
                            viewModel.updateFindMatches()
                        }

                    if !viewModel.matchRanges.isEmpty {
                        Text("\(viewModel.currentMatchIndex + 1) of \(viewModel.matchRanges.count)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else if !viewModel.findQuery.isEmpty {
                        Text("0 found")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 8, borderOpacity: 0.1)

                Button {
                    viewModel.findPrevious()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 32)
                }
                .liquidGlass(cornerRadius: 8)
                .disabled(viewModel.matchRanges.isEmpty)

                Button {
                    viewModel.findNext()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 32)
                }
                .liquidGlass(cornerRadius: 8)
                .disabled(viewModel.matchRanges.isEmpty)

                Button {
                    withAnimation {
                        viewModel.isFindAndReplaceVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
                .liquidGlass(cornerRadius: 8)
            }

            // Replace Row
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    TextField("Replace with", text: $viewModel.replaceQuery)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 8, borderOpacity: 0.1)

                Button("Replace") {
                    viewModel.replaceCurrent()
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 8)
                .disabled(viewModel.matchRanges.isEmpty)

                Button("All") {
                    viewModel.replaceAll()
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 8)
                .disabled(viewModel.matchRanges.isEmpty)
            }
        }
        .padding(10)
        .liquidGlass(cornerRadius: 12)
        .padding(.horizontal)
    }
}
