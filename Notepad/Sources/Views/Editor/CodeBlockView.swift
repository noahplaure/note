import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct CodeBlockView: View {
    public let initialLanguage: String
    @Binding public var code: String
    public var onLanguageChange: ((String) -> Void)?

    @State private var selectedLanguage: SyntaxLanguage
    @State private var isCopied: Bool = false
    @State private var theme: SyntaxTheme = .vsCodeDarkPlus

    public init(
        language: String,
        code: Binding<String>,
        onLanguageChange: ((String) -> Void)? = nil
    ) {
        self.initialLanguage = language
        self._code = code
        self.onLanguageChange = onLanguageChange
        let matched = SyntaxLanguage.match(from: language)
        self._selectedLanguage = State(initialValue: matched != .plain ? matched : SyntaxLanguage.detect(code: code.wrappedValue))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Menu {
                    ForEach(SyntaxLanguage.allCases) { lang in
                        Button(lang.displayName) {
                            selectedLanguage = lang
                            onLanguageChange?(lang.rawValue)
                            HapticManager.selection()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedLanguage.displayName)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#FFD60A"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#FFD60A"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }

                Spacer()

                Button {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = code
                    #endif
                    HapticManager.notification(.success)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCopied ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#1E1E24"))

            Divider()
                .background(Color.white.opacity(0.1))

            // Code Display with syntax highlighting and line numbers
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 12) {
                    // Line numbers
                    let lines = code.components(separatedBy: .newlines)
                    VStack(alignment: .trailing, spacing: 3) {
                        ForEach(1...max(1, lines.count), id: \.self) { lineNum in
                            Text("\(lineNum)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                    }
                    .padding(.leading, 8)

                    // Code content
                    let highlighted = SyntaxHighlighter.shared.highlight(
                        code: code,
                        language: selectedLanguage,
                        theme: theme
                    )
                    Text(highlighted)
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.trailing, 12)
                }
                .padding(.vertical, 10)
            }
            .background(Color(hex: theme.backgroundHex))
        }
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        }
    }
}
