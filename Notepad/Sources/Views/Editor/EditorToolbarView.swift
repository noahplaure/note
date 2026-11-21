import SwiftUI

public struct EditorToolbarView: View {
    @Bindable public var viewModel: NoteEditorViewModel

    @State private var isAaPopoverPresented: Bool = false
    @State private var isHighlightPalettePresented: Bool = false
    @State private var isTextColorPalettePresented: Bool = false

    public init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 6) {
            // "Aa" Button opening typography popover
            Button {
                isAaPopoverPresented.toggle()
                HapticManager.selection()
            } label: {
                HStack(spacing: 2) {
                    Text("Aa")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(Color(hex: "#FFD60A"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isAaPopoverPresented ? Color.white.opacity(0.15) : Color.clear)
                .cornerRadius(8)
            }
            .popover(isPresented: $isAaPopoverPresented) {
                typographyPopoverContent
                    .presentationCompactAdaptation(.popover)
            }

            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.2))

            // Scrollable Quick Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Checkbox list
                    quickButton(icon: "checklist") {
                        viewModel.toggleChecklist()
                    }

                    // Table
                    quickButton(icon: "tablecells") {
                        viewModel.isTableSheetPresented = true
                    }

                    // Image
                    quickButton(icon: "photo") {
                        viewModel.isImageSheetPresented = true
                    }

                    // Code block
                    quickButton(icon: "chevron.left.forwardslash.chevron.right") {
                        viewModel.insertCodeBlock(language: "swift")
                    }

                    // Bold
                    quickButton(icon: "bold") {
                        viewModel.toggleBold()
                    }

                    // Italic
                    quickButton(icon: "italic") {
                        viewModel.toggleItalic()
                    }

                    // Underline
                    quickButton(icon: "underline") {
                        viewModel.toggleUnderline()
                    }

                    // Highlight Marker
                    Button {
                        isHighlightPalettePresented.toggle()
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "highlighter")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#FFD60A"))
                            .frame(width: 32, height: 32)
                    }
                    .popover(isPresented: $isHighlightPalettePresented) {
                        ColorPickerPaletteView(isHighlight: true) { hex in
                            viewModel.applyHighlight(colorHex: hex)
                            isHighlightPalettePresented = false
                        } onClear: {
                            viewModel.applyHighlight(colorHex: "transparent")
                            isHighlightPalettePresented = false
                        }
                        .presentationCompactAdaptation(.popover)
                    }

                    // Bullet list
                    quickButton(icon: "list.bullet") {
                        viewModel.toggleBulletList()
                    }

                    // Numbered list
                    quickButton(icon: "list.number") {
                        viewModel.toggleNumberedList()
                    }

                    // Blockquote
                    quickButton(icon: "quote.opening") {
                        viewModel.toggleBlockquote()
                    }

                    // Horizontal rule
                    quickButton(icon: "divide") {
                        viewModel.insertHorizontalRule()
                    }

                    // Find and replace
                    quickButton(icon: "magnifyingglass") {
                        withAnimation {
                            viewModel.isFindAndReplaceVisible.toggle()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 14)
        .padding(.horizontal, 8)
    }

    private func quickButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
        }
    }

    // MARK: - "Aa" Popover Menu
    private var typographyPopoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Typography & Format")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            // Headings
            HStack(spacing: 8) {
                Button("H1") { viewModel.setHeading(level: 1); isAaPopoverPresented = false }
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)

                Button("H2") { viewModel.setHeading(level: 2); isAaPopoverPresented = false }
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)

                Button("H3") { viewModel.setHeading(level: 3); isAaPopoverPresented = false }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)

                Button("Body") { viewModel.setHeading(level: 0); isAaPopoverPresented = false }
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .foregroundColor(.white)

            // Alignments
            HStack(spacing: 8) {
                ForEach(TextAlignment.allCases, id: \.self) { align in
                    Button {
                        viewModel.setAlignment(align)
                        isAaPopoverPresented = false
                    } label: {
                        Image(systemName: align.iconName)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.15))

            // Clear formatting
            Button {
                viewModel.clearFormatting()
                isAaPopoverPresented = false
            } label: {
                HStack {
                    Image(systemName: "clear")
                    Text("Clear Formatting")
                }
                .font(.system(size: 14))
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 280)
        .liquidGlass(cornerRadius: 16)
    }
}
