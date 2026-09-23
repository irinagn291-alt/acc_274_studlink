import Foundation

/// Palette, face, space, and radius. Views reach tokens only through these accessors.
/// Courier New is the product face. Hex lives here and nowhere else.
enum Tokens {
    enum ColorHex {
        static let background = "#FFFFFF"
        static let surface = "#FFFFFF"
        static let ink = "#000000"
        static let accent = "#A737FF"
        static let muted = "#6B6B6B"
    }

    enum FontName {
        static let display = "Courier New"
    }

    enum Spacing {
        static let unit: Double = 8
    }

    enum Radius {
        static let card: Double = 12
        static let chip: Double = 8
    }
}
