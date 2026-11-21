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
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.delegate = context.coordinator

        // Custom insets for breathing room
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 80, right: 16)
        textView.textContainer.lineFragmentPadding = 0

        textView.text = text
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font?.pointSize != fontSize {
            uiView.font = UIFont.systemFont(ofSize: fontSize)
        }
        if uiView.selectedRange != selectedRange && selectedRange.location != NSNotFound {
            uiView.selectedRange = selectedRange
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextKitEditorView
        private var isUpdating = false

        init(_ parent: TextKitEditorView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.text = textView.text
            parent.onTextChange?(textView.text)
            isUpdating = false
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}
#endif
