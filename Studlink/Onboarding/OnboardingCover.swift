import SwiftUI

/// Three panes. Continue is bottom and full width. Skip writes the same flag.
struct OnboardingCover: View {
    var onFinish: () -> Void

    private var type = TypeScale()
    @State private var page = 0

    private let panes: [(art: String, title: String, line: String)] = [
        (
            "sdl_Onboarding1",
            "One chain for the weekend",
            "Link your football picks into a single chain. The chain scores only if every link holds."
        ),
        (
            "sdl_Onboarding2",
            "Shackle, then prove",
            "Tap the open shackle to forge a pick. Proof locks the chain and fixes the load at link count squared."
        ),
        (
            "sdl_Onboarding3",
            "One swage, then settle",
            "Change one unstarted pick before Proof. After the matches, type the real results. The first miss parts the chain."
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack {
                Spacer()
                Button("Skip") {
                    onFinish()
                }
                .font(type.body)
                .foregroundStyle(Palette.muted)
                .frame(minWidth: Spacing.hit, minHeight: Spacing.hit)
                .accessibilityLabel("Skip onboarding")
            }
            VStack(alignment: .leading, spacing: Spacing.s2) {
                PaperCollage(name: panes[page].art, maxSide: 280)
                    .frame(maxWidth: .infinity)
                Text(panes[page].title)
                    .font(type.chainDisplay)
                    .tracking(type.displayTracking)
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(panes[page].line)
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.s1) {
                    ForEach(0..<panes.count, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Palette.accent : Palette.muted.opacity(0.3))
                            .frame(width: index == page ? 24 : 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.s3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Button(page == panes.count - 1 ? "Start proving" : "Continue") {
                if page == panes.count - 1 {
                    onFinish()
                } else {
                    page += 1
                }
            }
            .buttonStyle(ChainButtonStyle())
            .padding(.horizontal, Spacing.s3)
            .padding(.bottom, Spacing.s2)
            .accessibilityLabel(page == panes.count - 1 ? "Start proving" : "Continue")
        }
        .background(Palette.background.ignoresSafeArea())
    }
}
