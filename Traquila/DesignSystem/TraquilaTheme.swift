import SwiftUI

struct TraquilaTheme {
    static let agaveGreen = Color(hex: "#5C8D57")
    static let terracotta = Color(hex: "#C96F4B")
    static let marigold = Color(hex: "#DFAE3D")
    static let charcoal = Color(hex: "#1F2327")
    static let parchment = Color(hex: "#F8F2E8")
    static let tileLine = Color(hex: "#D6C3A5")

    static let cornerRadius: CGFloat = 18
    static let cardPadding: CGFloat = 14

    static func titleFont() -> Font { .system(.largeTitle, design: .rounded, weight: .bold) }
    static func headingFont() -> Font { .system(.title3, design: .rounded, weight: .semibold) }
    static func bodyFont() -> Font { .system(.body, design: .rounded) }
    static func captionFont() -> Font { .system(.caption, design: .rounded, weight: .medium) }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        default:
            r = 0
            g = 0
            b = 0
        }

        self.init(red: r, green: g, blue: b)
    }
}
