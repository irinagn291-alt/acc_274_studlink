import SwiftUI

/// Named screen wrapper so live ReviewScreen coverage can match Season.
struct SeasonScreen: View {
    var onClose: () -> Void

    var body: some View {
        SeasonSheet(onClose: onClose)
    }
}

/// Points, longest whole chain, part rates, and the length curve.
struct SeasonSheet: View {
    var onClose: () -> Void

    @Environment(ChainStore.self) private var store
    private var type = TypeScale()

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.lastPersistError != nil && store.book.marks.isEmpty {
                    errorPage
                } else {
                    let entries = ProofHouse.rebuild(from: store.book.marks)
                    if entries.isEmpty {
                        EmptyBoard(
                            art: "sdl_SeasonEmpty",
                            headline: "No season yet",
                            line: "Prove a chain and settle it. Season then totals points, the longest whole chain, and where you over-reach.",
                            actionTitle: "Back to the chain",
                            action: onClose
                        )
                    } else {
                        populated
                    }
                }
            }
            .background(Palette.background)
            .navigationTitle("Season")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: Spacing.hit, height: Spacing.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close season")
                }
            }
        }
    }

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            BoardError(
                title: "Season could not read the book",
                line: "The last save failed. Retry the write, then open Season again.",
                retry: { Task { await store.flush() } }
            )
            Spacer()
        }
        .padding(Spacing.s3)
    }

    private var populated: some View {
        let marks = store.book.marks
        let points = SeasonTotals.points(from: marks)
        let longest = SeasonTotals.longestWhole(from: marks)
        let fixtures = SeasonTotals.partRates(
            from: marks,
            fixtures: store.book.cards.flatMap(\.fixtures)
        )
        let outcomes = SeasonTotals.outcomePartRates(from: marks)
        let curve = LengthCurve.points(from: marks)

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                hero(points: points, longest: longest)
                outcomeTable(outcomes)
                LengthCurveCanvas(points: curve)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Spacing.chartTall)
                    .hairlineFill()
                fixtureBoard(fixtures)
            }
            .padding(.horizontal, Spacing.s3)
            .padding(.top, Spacing.s2)
            .padding(.bottom, Spacing.dock)
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            dock
        }
        .background(Palette.background)
    }

    private var dock: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.muted.opacity(0.2))
                .frame(height: Radius.hairline)
            Button("Back to the chain", action: onClose)
                .buttonStyle(ChainButtonStyle())
                .accessibilityLabel("Back to the chain")
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background)
    }

    private func hero(points: Int, longest: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("POINTS")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            Text(Figures.int(points))
                .font(type.chainDisplay)
                .tracking(type.displayTracking)
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .accessibilityLabel("Season points \(Figures.int(points))")
            Text("Longest whole chain: \(Figures.int(longest)) links.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private func outcomeTable(_ rows: [OutcomePartRate]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("PICK HIT RATE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            ForEach(rows) { row in
                HStack {
                    Text(LinkLabel.outcomeWord(row.outcome))
                        .font(type.body)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text(Figures.rate(row.rate))
                        .font(type.figure)
                        .foregroundStyle(Palette.ink)
                }
                .frame(minHeight: Spacing.hit)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(Spacing.s2)
        .hairlineFill()
    }

    private func fixtureBoard(_ rows: [PartRate]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("FIXTURE HIT RATE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            if rows.isEmpty {
                Text("No settled fixtures yet.")
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                    .frame(minHeight: Spacing.hit, alignment: .leading)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.s2, alignment: .top),
                        GridItem(.flexible(), spacing: Spacing.s2, alignment: .top),
                    ],
                    alignment: .leading,
                    spacing: Spacing.s2
                ) {
                    ForEach(rows) { row in
                        fixtureCell(row)
                    }
                }
            }
        }
        .padding(Spacing.s2)
        .hairlineFill()
    }

    private func fixtureCell(_ row: PartRate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("\(row.homeSide) v \(row.awaySide)")
                .font(type.body)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text(row.hasResult ? Figures.rate(row.hitRate) : "No result yet")
                .font(type.figure)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, minHeight: Spacing.hit + Spacing.s3, alignment: .topLeading)
        .hairlineFill(corner: Radius.chip)
        .accessibilityElement(children: .combine)
    }
}

/// Whole-chain hit rate by chain length, drawn with labelled rows.
struct LengthCurveCanvas: View {
    var points: [LengthPoint]

    private var type = TypeScale()

    init(points: [LengthPoint]) {
        self.points = points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("WHOLE RATE BY CHAIN LENGTH")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            if points.isEmpty {
                Text("No length curve yet.")
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                    .frame(minHeight: Spacing.hit, alignment: .leading)
            } else {
                ForEach(points) { point in
                    row(point)
                }
            }
        }
        .padding(Spacing.s2)
    }

    private func row(_ point: LengthPoint) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
                Text("Chains of \(Figures.int(point.length)) links")
                    .font(type.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: Spacing.s1)
                Text("\(Figures.int(point.provedWhole)) of \(Figures.int(point.attempted)) whole")
                    .font(type.figure)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            HStack(alignment: .center, spacing: Spacing.s2) {
                rateTrack(value: point.wholeRate)
                Text(Figures.rate(point.wholeRate))
                    .font(type.figure)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: Spacing.s6 + Spacing.s3, alignment: .trailing)
                    .layoutPriority(1)
            }
        }
        .frame(minHeight: Spacing.hit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Chains of \(Figures.int(point.length)) links. \(Figures.int(point.provedWhole)) of \(Figures.int(point.attempted)) whole. Hit rate \(Figures.rate(point.wholeRate))."
        )
    }

    private func rateTrack(value: Double) -> some View {
        GeometryReader { geo in
            let clamped = min(max(value, 0), 1)
            let fillWidth = geo.size.width * clamped
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.muted.opacity(0.16))
                    .frame(width: geo.size.width, height: 6)
                if fillWidth > 0.5 {
                    Capsule()
                        .fill(Palette.accent)
                        .frame(width: fillWidth, height: 10)
                }
            }
            .frame(width: geo.size.width, height: 10, alignment: .leading)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}
