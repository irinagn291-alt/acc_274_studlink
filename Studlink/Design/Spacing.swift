import CoreGraphics

/// One unit, only multiples. Views never pick a raw gap.
enum Spacing {
    static let unit: CGFloat = Tokens.Spacing.unit
    static let s1: CGFloat = unit
    static let s2: CGFloat = unit * 2
    static let s3: CGFloat = unit * 3
    static let s4: CGFloat = unit * 4
    static let s5: CGFloat = unit * 5
    static let s6: CGFloat = unit * 6
    static let hit: CGFloat = 44
    /// Primary dock: 44pt verb plus vertical padding on both sides.
    static let dock: CGFloat = hit + s4
    static let plateTall: CGFloat = unit * 24
    static let mediaTall: CGFloat = unit * 35
    static let chartTall: CGFloat = unit * 28
}
