import SwiftUI

/// 12 for plates, 8 for chips. Hairline plus fill is the only elevation.
enum Radius {
    static let card: CGFloat = Tokens.Radius.card
    static let chip: CGFloat = Tokens.Radius.chip
    static let hairline: CGFloat = 1

    static var plate: RoundedRectangle {
        RoundedRectangle(cornerRadius: card, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chip, style: .continuous)
    }
}

struct HairlineFill: ViewModifier {
    var corner: CGFloat = Radius.card

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        content
            .background(Palette.surface, in: shape)
            .overlay(shape.strokeBorder(Palette.muted.opacity(0.28), lineWidth: Radius.hairline))
    }
}

extension View {
    func hairlineFill(corner: CGFloat = Radius.card) -> some View {
        modifier(HairlineFill(corner: corner))
    }
}
