import SwiftUI

/// Foot control. Tap opens this week's card so the next pick can be added.
struct ShackleControl: View {
    var enabled: Bool
    var remaining: Int
    var action: () -> Void

    private var type = TypeScale()

    init(enabled: Bool, remaining: Int, action: @escaping () -> Void) {
        self.enabled = enabled
        self.remaining = remaining
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.s2) {
                Image(systemName: enabled ? "plus" : "lock.fill")
                    .font(type.linkFace)
                    .foregroundStyle(enabled ? Palette.accent : Palette.muted)
                    .frame(width: Spacing.hit, height: Spacing.hit)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(LinkLabel.addNextPick())
                        .font(type.linkFace)
                        .foregroundStyle(enabled ? Palette.ink : Palette.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(LinkLabel.addNextPickLine(remaining: remaining, locked: !enabled))
                        .font(type.caption)
                        .foregroundStyle(Palette.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.s2)
            .frame(maxWidth: .infinity, minHeight: Spacing.hit + Spacing.s2, alignment: .leading)
            .contentShape(Radius.plate)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!enabled)
        .hairlineFill()
        .accessibilityLabel(LinkLabel.addNextPick())
        .accessibilityHint(enabled ? "Opens this week's fixtures so you can add a pick." : "This chain takes no more picks.")
    }
}
