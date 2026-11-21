import SwiftUI

#if canImport(UIKit)
import UIKit

public struct TextKitEditorView: UIViewRepresentable {
    @Binding public var text: String
    @Binding public var selectedRange: NSRange
    public var fontSize: CGFloat
    public var onTextChange: ((String) -> Void)?

    public init(
        text: Binding<String>,
        selectedRange: Binding<NSRange>,
        fontSize: CGFloat = 16.0,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self._selectedRange = selectedRange
        self.fontSize = fontSize
        self.onTextChange = onTextChange
    }

    public func makeUIView(context: Context) -> UITextView {
        // TextKit 2 initialization
        let textView = UITextView(usingTextLayoutManager: true)
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = UIColor(hex: "#FFD60A")
        textView.font = UIFont.systemFont(ofSize: fontSize)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.delegate = context.coordinator

        // Custom insets for comfortable writing
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 120, right: 16)
        textView.textContainer.lineFragmentPadding = 0

        textView.text = text
        context.coordinator.lastKnownText = text
        context.coordinator.applyStyling(to: textView.textStorage, text: text, baseFontSize: fontSize)

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        // Handle external text mutations (toolbar actions, mode switch, undo)
        if text != context.coordinator.lastKnownText {
            context.coordinator.lastKnownText = text
            let oldRange = uiView.selectedRange
            uiView.text = text
            context.coordinator.applyStyling(to: uiView.textStorage, text: text, baseFontSize: fontSize)

            let nsLength = (text as NSString).length
            if selectedRange.location != NSNotFound && selectedRange.location + selectedRange.length <= nsLength {
                uiView.selectedRange = selectedRange
            } else if oldRange.location != NSNotFound && oldRange.location + oldRange.length <= nsLength {
                uiView.selectedRange = oldRange
            }
        } else if selectedRange != uiView.selectedRange && selectedRange.location != NSNotFound && selectedRange.location + selectedRange.length <= (text as NSString).length {
            uiView.selectedRange = selectedRange
        }

        if uiView.font?.pointSize != fontSize {
            uiView.font = UIFont.systemFont(ofSize: fontSize)
            context.coordinator.applyStyling(to: uiView.textStorage, text: uiView.text, baseFontSize: fontSize)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextKitEditorView
        var lastKnownText: String = ""
        private var isInternalChange = false

        init(_ parent: TextKitEditorView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard !isInternalChange else { return }
            isInternalChange = true
            let currentText = textView.text ?? ""
            lastKnownText = currentText
            applyStyling(to: textView.textStorage, text: currentText, baseFontSize: parent.fontSize)
            parent.text = currentText
            parent.onTextChange?(currentText)
            isInternalChange = false
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isInternalChange else { return }
            let newRange = textView.selectedRange
            if parent.selectedRange != newRange {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.selectedRange = newRange
                }
            }
        }

        // MARK: - WYSIWYG Styling Engine
        func applyStyling(to textStorage: NSTextStorage, text: String, baseFontSize: CGFloat) {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            guard fullRange.length > 0 else { return }

            textStorage.beginEditing()

            // 1. Reset base styling
            let baseFont = UIFont.systemFont(ofSize: baseFontSize)
            textStorage.addAttribute(.font, value: baseFont, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
            textStorage.removeAttribute(.backgroundColor, range: fullRange)
            textStorage.removeAttribute(.underlineStyle, range: fullRange)
            textStorage.removeAttribute(.strikethroughStyle, range: fullRange)

            let defaultParagraph = NSMutableParagraphStyle()
            defaultParagraph.lineSpacing = 4
            defaultParagraph.alignment = .left
            textStorage.addAttribute(.paragraphStyle, value: defaultParagraph, range: fullRange)

            let hiddenFont = UIFont.systemFont(ofSize: 0.001)
            let hiddenColor = UIColor.clear
            let nsText = text as NSString

            // 2. Headings (# H1, ## H2, ### H3)
            if let h1Regex = try? NSRegularExpression(pattern: "^(#\\s+)(.*)$", options: .anchorsMatchLines) {
                let matches = h1Regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let h1Font = UIFont.systemFont(ofSize: baseFontSize * 1.5, weight: .bold)
                    textStorage.addAttribute(.font, value: h1Font, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                }
            }

            if let h2Regex = try? NSRegularExpression(pattern: "^(##\\s+)(.*)$", options: .anchorsMatchLines) {
                let matches = h2Regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let h2Font = UIFont.systemFont(ofSize: baseFontSize * 1.3, weight: .bold)
                    textStorage.addAttribute(.font, value: h2Font, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                }
            }

            if let h3Regex = try? NSRegularExpression(pattern: "^(###\\s+)(.*)$", options: .anchorsMatchLines) {
                let matches = h3Regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let h3Font = UIFont.systemFont(ofSize: baseFontSize * 1.15, weight: .semibold)
                    textStorage.addAttribute(.font, value: h3Font, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                }
            }

            // 3. Bold (**text**)
            if let boldRegex = try? NSRegularExpression(pattern: "(\\*{2})([^*\\n]+)(\\*{2})", options: []) {
                let matches = boldRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let boldFont = UIFont.boldSystemFont(ofSize: baseFontSize)
                    textStorage.addAttribute(.font, value: boldFont, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                    if match.numberOfRanges > 3 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 3))
                    }
                }
            }

            // 4. Italic (*text*)
            if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)(\\*)([^*\\n]+)(\\*)(?!\\*)", options: []) {
                let matches = italicRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let italicFont = UIFont.italicSystemFont(ofSize: baseFontSize)
                    textStorage.addAttribute(.font, value: italicFont, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                    if match.numberOfRanges > 3 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 3))
                    }
                }
            }

            // 5. Underline (<u>text</u>)
            if let uRegex = try? NSRegularExpression(pattern: "(<u>)(.*?)(<\\/u>)", options: .caseInsensitive) {
                let matches = uRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                        textStorage.addAttribute(.underlineStyle, value: 0, range: match.range(at: 1))
                    }
                    if match.numberOfRanges > 3 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 3))
                        textStorage.addAttribute(.underlineStyle, value: 0, range: match.range(at: 3))
                    }
                }
            }

            // 6. Strikethrough (~~text~~)
            if let strikeRegex = try? NSRegularExpression(pattern: "(~~)([^~\\n]+)(~~)", options: []) {
                let matches = strikeRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                        textStorage.addAttribute(.strikethroughStyle, value: 0, range: match.range(at: 1))
                    }
                    if match.numberOfRanges > 3 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 3))
                        textStorage.addAttribute(.strikethroughStyle, value: 0, range: match.range(at: 3))
                    }
                }
            }

            // 7. Inline code (`code`)
            if let codeRegex = try? NSRegularExpression(pattern: "(`)([^`\\n]+)(`)", options: []) {
                let matches = codeRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let monoFont = UIFont.monospacedSystemFont(ofSize: baseFontSize - 1, weight: .regular)
                    textStorage.addAttribute(.font, value: monoFont, range: match.range)
                    textStorage.addAttribute(.backgroundColor, value: UIColor(white: 0.22, alpha: 0.8), range: match.range)
                    if match.numberOfRanges > 1 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    }
                    if match.numberOfRanges > 3 {
                        textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 3))
                    }
                }
            }

            // 8. Div Alignment (<div align="center|right|justify|left">...</div>)
            if let divRegex = try? NSRegularExpression(pattern: "(<div\\s+align=\"(center|right|justify|left)\">)(.*?)(<\\/div>)", options: [.dotMatchesLineSeparators, .caseInsensitive]) {
                let matches = divRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let alignStr = nsText.substring(with: match.range(at: 2)).lowercased()
                    let paraStyle = NSMutableParagraphStyle()
                    paraStyle.lineSpacing = 4
                    switch alignStr {
                    case "center": paraStyle.alignment = .center
                    case "right": paraStyle.alignment = .right
                    case "justify": paraStyle.alignment = .justified
                    default: paraStyle.alignment = .left
                    }
                    textStorage.addAttribute(.paragraphStyle, value: paraStyle, range: match.range)
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 4))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 4))
                }
            }

            // 9. Highlight Marker (<mark style="background:#hex">...</mark>)
            if let markRegex = try? NSRegularExpression(pattern: "(<mark\\s+style=\"background:\\s*([^\"'>]+)\">)(.*?)(<\\/mark>)", options: [.dotMatchesLineSeparators, .caseInsensitive]) {
                let matches = markRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let hex = nsText.substring(with: match.range(at: 2))
                    let bg = UIColor(hex: hex)
                    let innerRange = match.range(at: 3)
                    textStorage.addAttribute(.backgroundColor, value: bg, range: innerRange)
                    if hex.lowercased().contains("ffd60a") || hex.lowercased().contains("ffff") {
                        textStorage.addAttribute(.foregroundColor, value: UIColor.black, range: innerRange)
                    }
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    textStorage.addAttribute(.backgroundColor, value: UIColor.clear, range: match.range(at: 1))
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 4))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 4))
                    textStorage.addAttribute(.backgroundColor, value: UIColor.clear, range: match.range(at: 4))
                }
            }

            // 10. Text Color (<span style="color:#hex">...</span>)
            if let spanRegex = try? NSRegularExpression(pattern: "(<span\\s+style=\"color:\\s*([^\"'>]+)\">)(.*?)(<\\/span>)", options: [.dotMatchesLineSeparators, .caseInsensitive]) {
                let matches = spanRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let hex = nsText.substring(with: match.range(at: 2))
                    let fg = UIColor(hex: hex)
                    let innerRange = match.range(at: 3)
                    textStorage.addAttribute(.foregroundColor, value: fg, range: innerRange)
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 1))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 1))
                    textStorage.addAttribute(.font, value: hiddenFont, range: match.range(at: 4))
                    textStorage.addAttribute(.foregroundColor, value: hiddenColor, range: match.range(at: 4))
                }
            }

            // 11. Checklists (- [ ] or - [x])
            if let checkRegex = try? NSRegularExpression(pattern: "^(\\s*-\\s*\\[([ xX])\\]\\s+)(.*)$", options: .anchorsMatchLines) {
                let matches = checkRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    let isChecked = nsText.substring(with: match.range(at: 2)).lowercased() == "x"
                    if isChecked {
                        textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: UIColor(hex: "#8E8E93"), range: match.range(at: 3))
                        textStorage.addAttribute(.foregroundColor, value: UIColor(hex: "#30D158"), range: match.range(at: 1))
                    } else {
                        textStorage.addAttribute(.foregroundColor, value: UIColor(hex: "#FFD60A"), range: match.range(at: 1))
                    }
                }
            }

            // 12. Blockquotes (> ...)
            if let quoteRegex = try? NSRegularExpression(pattern: "^(>\\s+)(.*)$", options: .anchorsMatchLines) {
                let matches = quoteRegex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    textStorage.addAttribute(.foregroundColor, value: UIColor(hex: "#A1A1A6"), range: match.range(at: 2))
                    textStorage.addAttribute(.foregroundColor, value: UIColor(hex: "#FFD60A").withAlphaComponent(0.6), range: match.range(at: 1))
                }
            }

            textStorage.endEditing()
        }
    }
}
#endif
