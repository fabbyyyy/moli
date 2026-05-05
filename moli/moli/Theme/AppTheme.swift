import SwiftUI

struct AppTheme {
    struct Colors {
        static let primaryBlue = Color(hex: "26357F")
        static let deepNavy = Color(hex: "10142F")
        static let backgroundGray = Color(hex: "F3F4F8")
        static let cardWhite = Color.white
        static let mutedGray = Color(hex: "7A7D89")
        static let softBlue = Color(hex: "E9EDF8")
        static let alertYellow = Color(hex: "FFF0CC")
        static let alertOrange = Color(hex: "F4A62A")
        static let dangerRed = Color(hex: "EF3340")
        static let successGray = Color(hex: "8B8D98")
        static let textPrimary = Color(hex: "1A1D2B") // Almost black for text
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
    init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
