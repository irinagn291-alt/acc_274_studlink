import SwiftUI

/// Manual results. Each true link holds. The first miss parts the chain.
struct SettlePass: View {
    var now: Date
    var onBackToHome: () -> Void = {}

    @Environment(ChainStore.self) private var store
    private var type = TypeScale()
    @State private var picks: [UUID: Outcome] = [:]
    @State private var settleError: String?

    init(now: Date, onBackToHome: @escaping () -> Void = {}) {
        self.now = now
        self.onBackToHome = onBackToHome
    }

    var body: some View {
        let chain = store.focusedChain(now: now)
        let card = store.focusedCard(now: now)
        let fixtures = card?.fixtures ?? []
        let proved = chain?.proof.isProved == true
        let parted = chain?.proof.isParted == true
        let links = Dictionary(uniqueKeysWithValues: (chain?.links ?? []).map { ($0.fixture.id, $0) })
        let linked = chain?.links.count ?? 0
        let open = max(0, fixtures.count - linked)
        let canProve = (chain?.proof.isMade == true) && linked >= 2

        Group {
            if fixtures.isEmpty {
                emptyBoard
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        if let message = settleError {
                            BoardError(
                                title: "Settlement did not apply",
                                line: message,
                                retry: { settleError = nil }
                            )
                        }
                        header(linked: linked, open: open, parted: parted, chain: chain)
                        ForEach(fixtures) { fixture in
                            resultRow(fixture, link: links[fixture.id], parted: parted)
                        }
                    }
                    .padding(.bottom, Spacing.dock)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !parted {
                        settleButton(proved: proved, canProve: canProve, chain: chain)
                            .padding(.horizontal, Spacing.s2)
                            .padding(.top, Spacing.s2)
                            .padding(.bottom, Spacing.s2)
                            .frame(maxWidth: .infinity)
                            .background(Palette.background)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Palette.muted.opacity(0.28))
                                    .frame(height: Radius.hairline)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyBoard: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            PaperCollage(name: "sdl_EmptyList", maxSide: 160)
                .frame(maxWidth: .infinity)
            Text("Nothing to settle")
                .font(type.chainDisplay)
                .tracking(type.displayTracking)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Add fixtures on the Card lane, then prove the chain and save results here.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func header(linked: Int, open: Int, parted: Bool, chain: Chain?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(LinkLabel.settleSummary(linked: linked, open: open))
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if parted {
                if case .parted(_, let at) = chain?.proof {
                    Text("This chain parted at link \(Figures.int(at + 1)). Later links are void.")
                        .font(type.body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("This chain parted. The score is now zero.")
                        .font(type.body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Mark the real Home, Draw, or Away for each fixture, then use the button below.")
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LinkLabel.settleSummary(linked: linked, open: open))
    }

    private func resultRow(_ fixture: Fixture, link: Link?, parted: Bool) -> some View {
        let pair = LinkLabel.pair(fixture)
        let pickWord = link.map { LinkLabel.outcomeWord($0.outcome) } ?? "Not picked"
        let settled = link.map { $0.settle != .open } ?? false
        let canEdit = !parted && !settled
        let selected = picks[fixture.id] ?? link?.outcome

        return VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(pair)
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Your pick: \(pickWord)")
                .font(type.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if settled, let link {
                Text("Result: \(LinkLabel.settleWord(link.settle).capitalized)")
                    .font(type.caption)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.s1) {
                ForEach(Outcome.allCases, id: \.self) { outcome in
                    resultChoice(
                        outcome: outcome,
                        fixtureID: fixture.id,
                        pair: pair,
                        selected: selected == outcome,
                        canEdit: canEdit
                    )
                }
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill(corner: Radius.chip)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(pair). Your pick: \(pickWord)")
    }

    private func resultChoice(
        outcome: Outcome,
        fixtureID: UUID,
        pair: String,
        selected: Bool,
        canEdit: Bool
    ) -> some View {
        let title = LinkLabel.outcomeWord(outcome)
        let style = OutcomeChipStyle(selected: selected)
        return Button(title) {
            picks[fixtureID] = outcome
        }
        .buttonStyle(style)
        .disabled(!canEdit)
        .accessibilityLabel("Result \(title) for \(pair)")
    }

    private func settleButton(proved: Bool, canProve: Bool, chain: Chain?) -> some View {
        let title = proved ? "Save results" : "Prove chain"
        return Button(title) {
            if proved {
                commit(chain: chain)
            } else {
                prove(chain: chain)
            }
        }
        .buttonStyle(ChainButtonStyle())
        .disabled(proved ? picks.isEmpty : !canProve)
        .accessibilityLabel(title)
    }

    private func prove(chain: Chain?) {
        guard let chain else {
            settleError = LinkLabel.refusal(.notMade)
            return
        }
        let result = store.apply(.proof, now: now, chainID: chain.id)
        if let refusal = result.refusal {
            settleError = LinkLabel.refusal(refusal)
            return
        }
        settleError = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func commit(chain: Chain?) {
        guard let chain, chain.proof.isProved else {
            settleError = "Prove the chain before you settle."
            return
        }
        let result = store.settleOpenPrefix(results: picks, chainID: chain.id, now: now)
        if let refusal = result.refusal {
            settleError = LinkLabel.refusal(refusal)
            return
        }
        settleError = nil
        if result.marks.contains(where: { mark in
            if case .hold = mark { return true }
            if case .snap = mark { return true }
            return false
        }) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
