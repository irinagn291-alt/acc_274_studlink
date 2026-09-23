import SwiftUI

/// Type a week's fixtures by hand. Kickoff, home side, away side.
struct CardEditor: View {
    var now: Date
    var onShackle: (Fixture, Outcome) -> Void

    @Environment(ChainStore.self) private var store
    private var type = TypeScale()
    @State private var home = ""
    @State private var away = ""
    @State private var kickoff = Date()
    @State private var editorError: String?

    init(now: Date, onShackle: @escaping (Fixture, Outcome) -> Void) {
        self.now = now
        self.onShackle = onShackle
    }

    var body: some View {
        let card = store.focusedCard(now: now)
        let chain = store.focusedChain(now: now)
        let taken = Set(chain?.links.map(\.fixture.id) ?? [])
        let fixtures = card?.fixtures ?? []

        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let message = editorError {
                BoardError(
                    title: "That fixture was not added",
                    line: message,
                    retryTitle: "Clear",
                    retry: { editorError = nil }
                )
            }
            addForm
            if fixtures.isEmpty {
                EmptyBoard(
                    art: "sdl_EmptyList",
                    headline: "No fixtures yet",
                    line: "Type a kickoff and both sides, then add them to this week's card.",
                    actionTitle: "Add fixture",
                    action: addFixture
                )
                .frame(minHeight: Spacing.mediaTall)
            } else {
                ForEach(fixtures) { fixture in
                    fixtureRow(fixture, taken: taken, locked: chain?.proof.isProved == true || chain?.proof.isParted == true)
                }
            }
        }
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("NEW FIXTURE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            DatePicker("Kickoff", selection: $kickoff)
                .font(type.body)
                .tint(Palette.accent)
                .frame(minHeight: Spacing.hit)
            TextField("Home side", text: $home)
                .font(type.body)
                .textInputAutocapitalization(.words)
                .padding(Spacing.s2)
                .frame(minHeight: Spacing.hit)
                .hairlineFill(corner: Radius.chip)
            TextField("Away side", text: $away)
                .font(type.body)
                .textInputAutocapitalization(.words)
                .padding(Spacing.s2)
                .frame(minHeight: Spacing.hit)
                .hairlineFill(corner: Radius.chip)
            Button("Add fixture", action: addFixture)
                .buttonStyle(ChainButtonStyle())
                .disabled(!canAdd)
        }
        .padding(Spacing.s2)
        .hairlineFill()
    }

    private var canAdd: Bool {
        !home.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !away.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fixtureRow(_ fixture: Fixture, taken: Set<UUID>, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(LinkLabel.pair(fixture))
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(Figures.kickoff(fixture.kickoff))
                .font(type.caption)
                .foregroundStyle(Palette.muted)
            if taken.contains(fixture.id) {
                Text("On the chain")
                    .font(type.mark)
                    .tracking(type.markTracking)
                    .foregroundStyle(Palette.muted)
                    .textCase(.uppercase)
            } else if locked {
                Text("Chain is locked")
                    .font(type.caption)
                    .foregroundStyle(Palette.muted)
            } else {
                HStack(spacing: Spacing.s1) {
                    ForEach(Outcome.allCases, id: \.self) { outcome in
                        Button(LinkLabel.outcomeWord(outcome)) {
                            onShackle(fixture, outcome)
                        }
                        .buttonStyle(OutcomeChipStyle(selected: false))
                        .accessibilityLabel("Shackle \(LinkLabel.pair(fixture)), \(LinkLabel.outcomeWord(outcome))")
                    }
                }
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private func addFixture() {
        let trimmedHome = home.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAway = away.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHome.isEmpty, !trimmedAway.isEmpty else {
            editorError = "Name both sides before you add the fixture."
            return
        }
        let day = store.focusedCard(now: now)?.dayKey ?? DayKey(now)
        let fixture = Fixture(kickoff: kickoff, homeSide: trimmedHome, awaySide: trimmedAway)
        store.addFixture(fixture, dayKey: day)
        home = ""
        away = ""
        editorError = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
