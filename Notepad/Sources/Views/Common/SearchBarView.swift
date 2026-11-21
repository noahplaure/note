import SwiftUI

public struct SearchBarView: View {
    @Binding public var text: String
    public var isFilterActive: Bool
    public var onFilterTap: () -> Void

    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, isFilterActive: Bool = false, onFilterTap: @escaping () -> Void = {}) {
        self._text = text
        self.isFilterActive = isFilterActive
        self.onFilterTap = onFilterTap
    }

    public var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))

                TextField("Search notes, code, tags...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .autocorrectionDisabled()

                if !text.isEmpty {
                    Button {
                        text = ""
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "#1C1C1E"))
            .cornerRadius(10)

            Button(action: onFilterTap) {
                Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(isFilterActive ? Color(hex: "#FFD60A") : .secondary)
            }

            if isFocused || !text.isEmpty {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false
                        hideKeyboard()
                    }
                }
                .foregroundColor(Color(hex: "#FFD60A"))
                .font(.system(size: 15))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}
