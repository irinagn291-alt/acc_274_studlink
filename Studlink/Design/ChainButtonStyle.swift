import SwiftUI

/// Filled capsule for the live verb. Delete and void stay neutral.
struct ChainButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case quiet
        case destructive
    }

    var kind: Kind = .primary
    var isLoading: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    private var type = TypeScale()

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        HStack(spacing: Spacing.s1) {
            if isLoading {
                ProgressView()
                    .tint(kind == .primary ? Palette.surface : Palette.ink)
            }
            configuration.label
                .font(type.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Spacing.hit)
        .padding(.horizontal, Spacing.s2)
        .foregroundStyle(foreground)
        .background(background, in: Capsule())
        .overlay(
            Capsule().strokeBorder(stroke, lineWidth: Radius.hairline)
        )
        .opacity(isEnabled ? 1 : 0.4)
        .scaleEffect(pressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.2), value: pressed)
        .contentShape(Capsule())
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            Palette.surface
        case .quiet, .destructive:
            Palette.ink
        }
    }

    private var background: Color {
        switch kind {
        case .primary:
            Palette.accent
        case .quiet, .destructive:
            Palette.surface
        }
    }

    private var stroke: Color {
        switch kind {
        case .primary:
            Palette.accent
        case .quiet, .destructive:
            Palette.muted.opacity(0.4)
        }
    }
}

/// Selected pick or result. Hairline when idle, accent fill when live.
struct OutcomeChipStyle: ButtonStyle {
    var selected: Bool

    @Environment(\.isEnabled) private var isEnabled
    private var type = TypeScale()

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.s1) {
            if selected {
                Image(systemName: "checkmark")
                    .font(type.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
            configuration.label
                .font(type.body.weight(.semibold))
        }
            .padding(.horizontal, Spacing.s1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.hit)
            .foregroundStyle(Palette.ink)
            .background(selected ? Palette.accent : Palette.surface, in: Radius.chipShape)
            .overlay(
                Radius.chipShape.strokeBorder(
                    selected ? Palette.accent : Palette.muted.opacity(0.35),
                    lineWidth: Radius.hairline
                )
            )
            .opacity(isEnabled ? 1 : (selected ? 0.92 : 0.4))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .contentShape(Radius.chipShape)
    }
}

/// Plain button feedback for icon rows, cards and custom chrome.
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.98
    var pressedOpacity: Double = 0.84

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
