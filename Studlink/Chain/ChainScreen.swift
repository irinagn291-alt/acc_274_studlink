import SwiftUI

/// Root. The proving chain never leaves. Other destinations arrive as sheets.
@MainActor
struct ChainScreen: View {
    @Environment(ChainStore.self) private var store
    @Bindable var chrome: ChainChrome
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var type = TypeScale()

    @State private var ready = false
    @State private var showSpinner = false
    @State private var now = Date()

    var body: some View {
        Group {
            if ready {
                board
            } else if showSpinner {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.background)
            } else {
                Palette.background.ignoresSafeArea()
            }
        }
        .tint(Palette.accent)
        .task { await boot() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                now = Date()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = Date()
        }
        .sheet(item: $chrome.sheet) { sheet in
            sheetBody(sheet)
                .presentationDetents(sheet.detents)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $chrome.swageLink) { link in
            SwageSheet(
                link: link,
                now: now,
                onPick: { outcome in
                    commitSwage(link: link, outcome: outcome)
                    chrome.swageLink = nil
                },
                onDismiss: { chrome.swageLink = nil }
            )
        }
        .fullScreenCover(isPresented: $chrome.showOnboarding) {
            OnboardingCover {
                OnboardingGate.markComplete()
                chrome.showOnboarding = false
                chrome.applyLaunchReview()
            }
        }
    }

    private var board: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetWords
            if store.book.cards.isEmpty {
                EmptyBoard(
                    art: "sdl_EmptyHome",
                    headline: "No chain yet",
                    line: "Add a fixture card and shackle your first pick. The chain scores only when every link holds.",
                    actionTitle: "Add a fixture card",
                    action: { chrome.openFixtures(.card) }
                )
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.background.ignoresSafeArea())
    }

    /// Word destinations, not a tab bar. The chain stays on this screen.
    private var sheetWords: some View {
        let destinations = sheetDestinations
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
                brandMark
                Spacer(minLength: Spacing.s1)
                destinations
            }
            VStack(alignment: .leading, spacing: 0) {
                brandMark
                destinations
            }
        }
        .padding(.horizontal, Spacing.s2)
        .padding(.top, Spacing.s1)
        .padding(.bottom, Spacing.s1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.background)
    }

    private var brandMark: some View {
        Text("STUDLINK")
            .font(type.mark)
            .tracking(type.markTracking)
            .foregroundStyle(Palette.ink)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var sheetDestinations: some View {
        HStack(spacing: Spacing.s1) {
            sheetWord("Chain", selected: chrome.sheet == nil) {
                chrome.sheet = nil
            }
            sheetWord("Fixtures", selected: chrome.sheet == .fixtures) {
                chrome.openFixtures(.card)
            }
            sheetWord("House", selected: chrome.sheet == .proofHouse) {
                chrome.sheet = .proofHouse
            }
            sheetWord("Season", selected: chrome.sheet == .season) {
                chrome.sheet = .season
            }
            sheetWord("Settings", selected: chrome.sheet == .settings) {
                chrome.sheet = .settings
            }
        }
    }

    private func sheetWord(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(type.caption.weight(selected ? .bold : .semibold))
                .underline(selected, color: Palette.ink)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, Spacing.s1)
                .frame(minHeight: Spacing.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var populated: some View {
        let chain = store.focusedChain(now: now)
        let card = store.focusedCard(now: now)
        let links = chain?.links ?? []
        let load = chain?.proof.displayedLoad ?? 0
        let swageCount = chain.map { MarkLedger.swageCount(in: store.book.marks, chainID: $0.id) } ?? 0
        let canProve = (chain?.proof.isMade ?? false) && links.count >= 2
        let canShackle = chain == nil || (chain?.proof.isBare == true) || (chain?.proof.isMade == true)
        let total = card?.fixtures.count ?? links.count
        let openFixtures = (card?.fixtures ?? []).filter { fixture in
            !links.contains(where: { $0.fixture.id == fixture.id })
        }
        let regular = horizontalSizeClass == .regular
        let partIndex: Int? = {
            if case .parted(_, let at) = chain?.proof { return at }
            return nil
        }()

        let board = VStack(alignment: .leading, spacing: Spacing.s2) {
            if let reason = chrome.refusal {
                Text(LinkLabel.refusal(reason))
                    .font(type.body)
                    .foregroundStyle(Palette.ink)
                    .padding(Spacing.s2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hairlineFill()
                    .accessibilityLabel(LinkLabel.refusal(reason))
            }
            if store.lastPersistError != nil {
                BoardError(
                    title: "The last save did not finish",
                    line: "Your chain is still on screen. Try writing the book again.",
                    retry: { Task { await store.flush() } }
                )
            }
            let head = ChainHeadPlate(
                load: load,
                linkCount: links.count,
                total: total,
                canProve: canProve,
                proved: chain?.proof.isProved == true,
                parted: chain?.proof.isParted == true,
                swageLeft: chain?.proof.isMade == true && swageCount == 0,
                onProof: commitProof
            )
            let canvas = Group {
                if !links.isEmpty {
                    ChainCanvas(
                        links: links,
                        partIndex: partIndex,
                        rattleTick: chrome.rattleTick,
                        holdPulse: chrome.holdPulse,
                        reveal: chrome.didReveal,
                        reduceMotion: reduceMotion,
                        onSwage: { link in
                            guard chain?.proof.isMade == true else { return }
                            chrome.swageLink = link
                        }
                    )
                }
            }
            let openBoard = OpenCardBoard(
                fixtures: openFixtures,
                onOpen: { chrome.openFixtures(.card) }
            )
            let shackle = ShackleControl(
                enabled: canShackle,
                remaining: openFixtures.count,
                action: { chrome.openFixtures(.card) }
            )

            if regular {
                HStack(alignment: .top, spacing: Spacing.s2) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        head
                        cardStrip(card: card, linkCount: links.count)
                        seasonPulse
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        canvas
                        openBoard
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                shackle
            } else {
                head
                cardStrip(card: card, linkCount: links.count)
                canvas
                openBoard
                shackle
            }
        }
        .padding(.horizontal, Spacing.s2)
        .padding(.bottom, Spacing.s1)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            if !chrome.didReveal {
                chrome.didReveal = true
            }
        }

        return ScrollView {
            board
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var seasonPulse: some View {
        let points = SeasonTotals.points(from: store.book.marks)
        let longest = SeasonTotals.longestWhole(from: store.book.marks)
        return Button {
            chrome.sheet = .season
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text("SEASON SO FAR")
                    .font(type.mark)
                    .tracking(type.markTracking)
                    .foregroundStyle(Palette.ink)
                    .textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Figures.int(points))
                            .font(type.figure)
                            .foregroundStyle(Palette.ink)
                        Text("Points banked")
                            .font(type.body)
                            .foregroundStyle(Palette.ink)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Figures.int(longest))
                            .font(type.figure)
                            .foregroundStyle(Palette.ink)
                        Text("Longest whole chain")
                            .font(type.body)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 0)
                }
                Text("Open season")
                    .font(type.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, Spacing.s2)
                    .frame(minHeight: Spacing.hit)
                    .contentShape(Rectangle())
                    .overlay(
                        Radius.chipShape.strokeBorder(Palette.ink.opacity(0.28), lineWidth: Radius.hairline)
                    )
            }
            .padding(Spacing.s2)
            .frame(maxWidth: .infinity, minHeight: Spacing.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .hairlineFill()
        .accessibilityLabel("Season so far. \(Figures.int(points)) points. Longest whole chain \(Figures.int(longest)) links.")
        .accessibilityHint("Opens season totals.")
    }

    private func cardStrip(card: Card?, linkCount: Int) -> some View {
        let total = card?.fixtures.count ?? 0
        let day = card.map { Figures.dayLabel($0.dayKey) } ?? "This week"
        return Button {
            chrome.openFixtures(.card)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS WEEK'S CARD")
                        .font(type.mark)
                        .tracking(type.markTracking)
                        .foregroundStyle(Palette.ink)
                        .textCase(.uppercase)
                    Text("\(day). \(Figures.int(linkCount)) of \(Figures.int(total)) picked")
                        .font(type.body)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.s1)
                Text("Open card")
                    .font(type.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, Spacing.s2)
                    .frame(minWidth: Spacing.hit, minHeight: Spacing.hit)
                    .contentShape(Rectangle())
                    .overlay(
                        Radius.chipShape.strokeBorder(Palette.ink.opacity(0.28), lineWidth: Radius.hairline)
                    )
            }
            .padding(Spacing.s2)
            .frame(maxWidth: .infinity, minHeight: Spacing.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .hairlineFill()
        .accessibilityLabel("Open this week's fixture card")
        .accessibilityHint("Add the next pick from the card, or settle after kickoff.")
    }

    @ViewBuilder
    private func sheetBody(_ sheet: BoardSheet) -> some View {
        switch sheet {
        case .fixtures:
            FixturesScreen(lane: $chrome.fixturesLane, now: now) { chrome.sheet = nil }
        case .proofHouse:
            ProofHouseScreen { chrome.sheet = nil }
        case .season:
            SeasonScreen { chrome.sheet = nil }
        case .settings:
            SettingsScreen(
                onClose: { chrome.sheet = nil },
                onReplayOnboarding: {
                    chrome.sheet = nil
                    OnboardingGate.reopen()
                    chrome.showOnboarding = true
                }
            )
        }
    }

    private func boot() async {
        let spinner = Task {
            try await Task.sleep(for: .milliseconds(150))
            showSpinner = true
        }
        await store.bootstrap()
        spinner.cancel()
        ready = true
        chrome.showOnboarding = !OnboardingGate.isComplete()
        if !chrome.showOnboarding {
            chrome.applyLaunchReview()
        }
    }

    private func commitProof() {
        guard let chain = store.focusedChain(now: now) else { return }
        let result = store.apply(.proof, now: now, chainID: chain.id)
        handle(result, success: {
            chrome.flashSuccess()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
    }

    private func commitSwage(link: Link, outcome: Outcome) {
        guard let chain = store.focusedChain(now: now) else { return }
        let result = store.apply(.swage(Swage(linkID: link.id, outcome: outcome)), now: now, chainID: chain.id)
        handle(result, success: {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
    }

    private func handle(_ result: FoldResult, success: () -> Void) {
        if let refusal = result.refusal {
            chrome.showRefusal(refusal)
            return
        }
        chrome.refusal = nil
        success()
    }
}
