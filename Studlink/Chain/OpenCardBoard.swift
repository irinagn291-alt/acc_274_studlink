import SwiftUI

/// Remaining fixtures on this week's card. Fills leftover canvas with the mechanic.
struct OpenCardBoard: View {
    var fixtures: [Fixture]
    var onOpen: () -> Void

    private var type = TypeScale()

    init(fixtures: [Fixture], onOpen: @escaping () -> Void) {
        self.fixtures = fixtures
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(LinkLabel.stillOpenHeading())
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.ink)
                .textCase(.uppercase)
            Text(LinkLabel.addNextPickLine(remaining: fixtures.count, locked: false))
                .font(type.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if fixtures.isEmpty {
                Text(LinkLabel.addNextPickLine(remaining: 0, locked: false))
                    .font(type.caption)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(fixtures) { fixture in
                    Button(action: onOpen) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LinkLabel.pair(fixture))
                                    .font(type.linkFace)
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(LinkLabel.pickThisFixture())
                                    .font(type.caption)
                                    .foregroundStyle(Palette.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(Figures.kickoff(fixture.kickoff))
                                .font(type.caption)
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(Spacing.s2)
                        .frame(maxWidth: .infinity, minHeight: Spacing.hit, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .hairlineFill(corner: Radius.chip)
                    .accessibilityLabel("\(LinkLabel.pair(fixture)). \(LinkLabel.pickThisFixture())")
                }
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .hairlineFill()
    }
}
