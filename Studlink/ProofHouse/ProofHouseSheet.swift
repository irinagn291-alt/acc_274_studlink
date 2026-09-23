import SwiftUI

/// Named screen wrapper so live ReviewScreen coverage can match Proof House.
struct ProofHouseScreen: View {
    var onClose: () -> Void

    var body: some View {
        ProofHouseSheet(onClose: onClose)
    }
}

/// Past chains rebuilt from marks. The twist screen: which link parted.
struct ProofHouseSheet: View {
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
                            art: "sdl_ProofHouseEmpty",
                            headline: "No proved chains",
                            line: "Prove a chain of at least two links. House then keeps the load, the holds, and the exact snap.",
                            actionTitle: "Back to the chain",
                            action: onClose
                        )
                    } else {
                        populated(entries)
                    }
                }
            }
            .background(Palette.background)
            .navigationTitle("Proof House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: Spacing.hit, height: Spacing.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close proof house")
                }
            }
        }
    }

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            BoardError(
                title: "House could not read the book",
                line: "The last save failed. Retry the write, then open House again.",
                retry: { Task { await store.flush() } }
            )
            Spacer()
        }
        .padding(Spacing.s3)
    }

    private func populated(_ entries: [HouseEntry]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                twistBanner
                ForEach(entries) { entry in
                    houseCard(entry)
                }
            }
            .padding(Spacing.s3)
            .padding(.bottom, Spacing.s4)
        }
    }

    private var twistBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            PaperCollage(name: "sdl_TwistHero", maxSide: 88)
            Text("Whole or nothing")
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
            Text("A chain pays link count squared, and only if every link holds. The first miss writes a snap, voids the rest, and this page names that link.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private func houseCard(_ entry: HouseEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(alignment: .firstTextBaseline) {
                Text(Figures.dayLabel(entry.dayKey))
                    .font(type.linkFace)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: Spacing.s1)
                Text(Figures.int(entry.load))
                    .font(type.figure)
                    .foregroundStyle(Palette.ink)
                    .accessibilityLabel("Proof load \(Figures.int(entry.load))")
            }
            Text(entry.voided ? "PARTED" : "WHOLE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
            Text("\(Figures.int(entry.linkCount)) links. \(Figures.int(entry.holds.count)) held.")
                .font(type.caption)
                .foregroundStyle(Palette.muted)
            ForEach(uniqueHolds(entry.holds)) { hold in
                Text("Hold \(Figures.int(hold.index + 1)). \(hold.homeSide) v \(hold.awaySide), \(LinkLabel.outcomeWord(hold.outcome)).")
                    .font(type.body)
                    .foregroundStyle(Palette.ink)
            }
            if let snap = entry.snap {
                HStack(alignment: .top, spacing: Spacing.s1) {
                    PaperCollage(name: "sdl_SnapBreak", maxSide: 40)
                    Text("Parted at link \(Figures.int(snap.partIndex + 1)). \(snap.homeSide) v \(snap.awaySide). Pick \(LinkLabel.outcomeWord(snap.picked)), result \(LinkLabel.outcomeWord(snap.result)).")
                        .font(type.body)
                        .foregroundStyle(Palette.ink)
                }
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
        .accessibilityElement(children: .combine)
    }

    private func uniqueHolds(_ holds: [HoldMark]) -> [HoldMark] {
        var seen: Set<Int> = []
        return holds.filter { hold in
            seen.insert(hold.index).inserted
        }
    }
}
