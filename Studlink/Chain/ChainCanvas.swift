import SwiftUI

/// One column of fixture links. Spine stays inside each row, never across the stack.
struct ChainCanvas: View {
    var links: [Link]
    var partIndex: Int?
    var rattleTick: Int
    var holdPulse: Bool
    var reveal: Bool
    var reduceMotion: Bool
    var onSwage: (Link) -> Void

    private var type = TypeScale()
    @State private var rattle: CGFloat = 0

    init(
        links: [Link],
        partIndex: Int?,
        rattleTick: Int,
        holdPulse: Bool,
        reveal: Bool,
        reduceMotion: Bool,
        onSwage: @escaping (Link) -> Void
    ) {
        self.links = links
        self.partIndex = partIndex
        self.rattleTick = rattleTick
        self.holdPulse = holdPulse
        self.reveal = reveal
        self.reduceMotion = reduceMotion
        self.onSwage = onSwage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(LinkLabel.linksOnChainHeading())
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.ink)
                .textCase(.uppercase)
            ForEach(Array(links.enumerated()), id: \.element.id) { index, link in
                linkRow(link: link, index: index)
            }
        }
        .offset(x: rattle)
        .onChange(of: rattleTick) { _, _ in
            runRattle()
        }
    }

    @ViewBuilder
    private func linkRow(link: Link, index: Int) -> some View {
        let delay = revealDelay(index: index)
        let partedHere = partIndex == index
        let voided = partIndex.map { index > $0 } ?? false
        Button {
            onSwage(link)
        } label: {
            HStack(alignment: .center, spacing: Spacing.s2) {
                rowSpine(parted: partedHere)
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(LinkLabel.pair(link.fixture))
                        .font(type.linkFace)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                        Text("Pick \(LinkLabel.outcomeWord(link.outcome))")
                            .font(type.body)
                            .foregroundStyle(Palette.ink)
                        Text(LinkLabel.settleMark(link.settle))
                            .font(type.mark)
                            .tracking(type.markTracking)
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: Spacing.s1)
                        Text("Link \(Figures.int(index + 1)) of \(Figures.int(links.count))")
                            .font(type.caption)
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    if voided {
                        Text("Void after the snap")
                            .font(type.caption)
                            .foregroundStyle(Palette.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s2)
            .frame(maxWidth: .infinity, minHeight: Spacing.hit + Spacing.s3, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .offset(x: partedHere ? Spacing.s1 : 0)
        .scaleEffect(holdPulse && link.settle == .hold ? 0.98 : 1)
        .hairlineFill(corner: index.isMultiple(of: 2) ? Radius.chip : Radius.card)
        .opacity(reveal || reduceMotion ? 1 : 0)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .easeOut(duration: 0.28).delay(delay),
            value: reveal
        )
        .accessibilityLabel(LinkLabel.spoken(link: link, index: index))
        .accessibilityHint("Opens swage if this fixture has not kicked off.")
    }

    /// Gutter mark clipped to this row. Never a rule across the stack.
    private func rowSpine(parted: Bool) -> some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            context.stroke(
                path,
                with: .color(parted ? Palette.accent : Palette.muted.opacity(0.45)),
                lineWidth: Radius.hairline
            )
            let stud = CGRect(x: (size.width - 6) / 2, y: (size.height - 6) / 2, width: 6, height: 6)
            context.fill(Path(ellipseIn: stud), with: .color(Palette.ink))
        }
        .frame(width: Spacing.s2, height: Spacing.s5)
        .clipped()
        .accessibilityHidden(true)
    }

    private func revealDelay(index: Int) -> Double {
        min(Double(index) * 0.05, 0.36)
    }

    private func runRattle() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.06)) { rattle = Spacing.s1 }
        withAnimation(.easeInOut(duration: 0.06).delay(0.06)) { rattle = -Spacing.s1 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.12)) { rattle = 0 }
    }
}
