import SwiftUI

// MARK: - Palette (exact colors from the Android theme)

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }

    static let hotRed = Color(hex: 0xE50914)        // signature crimson
    static let hotOrange = Color(hex: 0xE50914)     // secondary accent (same crimson)

    static let darkBg = Color(hex: 0x080808)        // main background — near-black
    static let darkBg2 = Color(hex: 0x121212)       // top bars / panels
    static let darkSurface = Color(hex: 0x1A1A1A)   // cards & surfaces
    static let darkSurface2 = Color(hex: 0x222222)  // elevated surfaces
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xA3A3A3) // muted gray
    static let dividerColor = Color(hex: 0x2A2A2A)
}

// MARK: - Shared visual language (gradients, glass, glow)

extension LinearGradient {
    /// Vertical gradient used on cards and panels.
    static let brandCard = LinearGradient(colors: [.darkSurface2, .darkSurface], startPoint: .top, endPoint: .bottom)
    /// Deeper gradient for hero / top strips.
    static let brandPanel = LinearGradient(colors: [.darkSurface2, .darkSurface, .darkBg], startPoint: .top, endPoint: .bottom)
}

extension View {
    /// Frosted-glass surface: translucent dark fill + light sheen + hairline border.
    func glass(cornerRadius: CGFloat = 20, alpha: Double = 0.62, tint: Color = .darkSurface, border: Bool = true) -> some View {
        self.background(
            ZStack {
                tint.opacity(alpha)
                LinearGradient(
                    colors: [.white.opacity(0.10), .white.opacity(0.02), .white.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if border {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
    }

    /// Card background with the brand gradient and rounded corners.
    func brandCardStyle(cornerRadius: CGFloat = 16) -> some View {
        self.background(LinearGradient.brandCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    /// Crimson glow shadow for primary buttons and selected items.
    func glow(radius: CGFloat = 12) -> some View {
        self.shadow(color: Color.hotRed.opacity(0.55), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Typography-ish helpers to match the Android look

extension Font {
    static let heroTitle = Font.system(size: 24, weight: .bold)
}
