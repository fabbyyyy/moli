import SwiftUI
import UIKit

struct AppTheme {
    struct Colors {
        static let bimboBlue = Color(light: "293572", dark: "A7B4FF")
        static let bimboRed = Color(light: "D33A3A", dark: "FF7C7C")

        static let primaryBlue = bimboBlue
        static let deepNavy = Color(light: "10142F", dark: "F3F5FF")
        static let backgroundGray = Color(light: "F3F4F8", dark: "090B16")
        static let cardWhite = Color(light: "FFFFFF", dark: "171B2F")
        static let mutedGray = Color(light: "7A7D89", dark: "A9AEC2")
        static let softBlue = Color(light: "E9EDF8", dark: "232A4A")
        static let alertYellow = Color(light: "FFF0CC", dark: "352617")
        static let alertOrange = Color(light: "D33A3A", dark: "FF8A8A")
        static let dangerRed = bimboRed
        static let successGray = Color(light: "8B8D98", dark: "B6BAC8")
        static let textPrimary = Color(light: "1A1D2B", dark: "F4F6FF")
        static let warningText = Color(light: "8A2D2D", dark: "FFD1D1")
    }
    
    struct Radii {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    struct Shadows {
        static let card = Shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        static let floating = Shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// Helper for Hex colors
extension Color {
    init(light: String, dark: String) {
        self.init(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: String) {
        let components = Self.rgbaComponents(from: hex)

        self.init(
            .sRGB,
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.opacity
        )
    }

    fileprivate static func rgbaComponents(from hex: String) -> (red: Double, green: Double, blue: Double, opacity: Double) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        return (
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let components = Color.rgbaComponents(from: hex)
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.opacity
        )
    }
}
