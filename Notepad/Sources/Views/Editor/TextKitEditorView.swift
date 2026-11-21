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

        // Background tap to focus anywhere
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        textView.addGestureRecognizer(tapGesture)

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        // Do not overwrite text or selection while user is actively typing to prevent dropped keystrokes
        if !uiView.isFirstResponder && uiView.text != text {
            uiView.text = text
        }
        if uiView.font?.pointSize != fontSize {
            uiView.font = UIFont.systemFont(ofSize: fontSize)
        }
        if !uiView.isFirstResponder && selectedRange.location != NSNotFound && uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextKitEditorView
        private var isInternalChange = false

        init(_ parent: TextKitEditorView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard !isInternalChange else { return }
            isInternalChange = true
            parent.text = textView.text
            parent.onTextChange?(textView.text)
            isInternalChange = false
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = gesture.view as? UITextView else { return }
            if !tv.isFirstResponder {
                tv.becomeFirstResponder()
            }
        }
    }
}
#endif
