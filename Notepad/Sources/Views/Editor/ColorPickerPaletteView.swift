import SwiftUI

public struct ColorPaletteItem: Identifiable, Sendable {
    public var id: String { hex }
    public let hex: String
    public let name: String
}

public struct ColorPickerPaletteView: View {
    public var isHighlight: Bool
    public var onSelectColor: (String) -> Void
    public var onClear: () -> Void

    @State private var customColor: Color = Color(hex: "#FFD60A")

    public static let presetColors: [ColorPaletteItem] = [
        ColorPaletteItem(hex: "#FFD60A", name: "Yellow"),
        ColorPaletteItem(hex: "#FF9F0A", name: "Orange"),
        ColorPaletteItem(hex: "#FF3B30", name: "Red"),
        ColorPaletteItem(hex: "#FF2D55", name: "Pink"),
        ColorPaletteItem(hex: "#AF52DE", name: "Purple"),
        ColorPaletteItem(hex: "#5856D6", name: "Indigo"),
        ColorPaletteItem(hex: "#007AFF", name: "Blue"),
        ColorPaletteItem(hex: "#32ADE6", name: "Cyan"),
        ColorPaletteItem(hex: "#00C7BE", name: "Teal"),
        ColorPaletteItem(hex: "#30D158", name: "Green"),
        ColorPaletteItem(hex: "#8E8E93", name: "Gray"),
        ColorPaletteItem(hex: "#FFFFFF", name: "White")
    ]

    public init(
        isHighlight: Bool = true,
        onSelectColor: @escaping (String) -> Void,
        onClear: @escaping () -> Void
    ) {
        self.isHighlight = isHighlight
        self.onSelectColor = onSelectColor
        self.onClear = onClear
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isHighlight ? "Highlight Marker Color" : "Text Color")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: onClear) {
                    HStack(spacing: 4) {
                        Image(systemName: "slash.circle")
                        Text("Remove")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                }
            }

            // 12-color grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(Self.presetColors) { item in
                    Button {
                        onSelectColor(item.hex)
                        HapticManager.selection()
                    } label: {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Custom color picker
            HStack {
                Text("Custom Color")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Spacer()

                ColorPicker("", selection: $customColor)
                    .labelsHidden()
                    .onChange(of: customColor) { _, newColor in
                        if let hex = newColor.toHex() {
                            onSelectColor(hex)
                        }
                    }
            }
        }
        .padding()
        .liquidGlass(cornerRadius: 16)
        .frame(maxWidth: 320)
    }
}
