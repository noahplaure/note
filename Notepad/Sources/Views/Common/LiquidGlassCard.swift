import SwiftUI

public struct LiquidGlassModifier: ViewModifier, Sendable {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double

    public init(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.15) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(hex: "#1C1C1E").opacity(0.85))
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(borderOpacity), lineWidth: 0.5)
                    }
            }
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.15) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}
