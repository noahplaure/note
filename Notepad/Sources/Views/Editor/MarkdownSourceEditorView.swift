import SwiftUI

public struct MarkdownSourceEditorView: View {
    @Binding public var text: String
    @Binding public var selectedRange: NSRange
    public var fontSize: CGFloat
    public var onTextChange: ((String) -> Void)?

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        selectedRange: Binding<NSRange>,
        fontSize: CGFloat = 15.0,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self._selectedRange = selectedRange
        self.fontSize = fontSize
        self.onTextChange = onTextChange
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line numbers gutter
            let lineCount = max(1, text.components(separatedBy: .newlines).count)
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(1...lineCount, id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: fontSize - 2, design: .monospaced))
                        .foregroundColor(Color.gray.opacity(0.4))
                        .frame(height: fontSize * 1.35)
                }
            }
            .padding(.top, 16)
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .background(Color(hex: "#121214"))

            Divider()
                .background(Color.white.opacity(0.1))

            // Raw Text Editor
            TextEditor(text: $text)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(Color(hex: "#D4D4D4"))
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 80)
                .onChange(of: text) { _, newText in
                    onTextChange?(newText)
                }
        }
        .background(Color.black)
    }
}
