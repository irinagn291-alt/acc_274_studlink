import SwiftUI

/// One replacement before Proof. Kickoff must still be ahead.
struct SwageSheet: View {
    var link: Link
    var now: Date
    var onPick: (Outcome) -> Void
    var onDismiss: () -> Void

    private var type = TypeScale()

    init(
        link: Link,
        now: Date,
        onPick: @escaping (Outcome) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.link = link
        self.now = now
        self.onPick = onPick
        self.onDismiss = onDismiss
    }

    private var kickoffOpen: Bool {
        now < link.fixture.kickoff
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                PaperCollage(name: "sdl_TwistHero", maxSide: 120)
                    .frame(maxWidth: .infinity)
                Text("Swage this link")
                    .font(type.linkFace)
                    .foregroundStyle(Palette.ink)
                Text(LinkLabel.pair(link.fixture))
                    .font(type.body)
                    .foregroundStyle(Palette.ink)
                Text(Figures.kickoff(link.fixture.kickoff))
                    .font(type.caption)
                    .foregroundStyle(Palette.muted)
                Text("A chain allows one swage, and only before kickoff. The rest of the chain stays.")
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                if kickoffOpen {
                    HStack(spacing: Spacing.s1) {
                        ForEach(Outcome.allCases, id: \.self) { outcome in
                            swageChoice(outcome)
                        }
                    }
                } else {
                    BoardError(
                        title: "Kickoff has passed",
                        line: "This fixture has started. Swage is closed on this link.",
                        retryTitle: "Close",
                        retry: onDismiss
                    )
                }
                Spacer(minLength: Spacing.s2)
            }
            .padding(Spacing.s3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.background)
            .navigationTitle("Swage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: Spacing.hit, height: Spacing.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close swage")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func swageChoice(_ outcome: Outcome) -> some View {
        let title = LinkLabel.outcomeWord(outcome)
        let chosen = outcome == link.outcome
        let style = OutcomeChipStyle(selected: chosen)
        return Button(title) {
            onPick(outcome)
        }
        .buttonStyle(style)
        .accessibilityLabel("Swage to \(title)")
    }
}
