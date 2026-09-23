import SwiftUI

/// Named screen wrapper so live ReviewScreen coverage can match Fixtures.
struct FixturesScreen: View {
    @Binding var lane: FixturesLane
    var now: Date
    var onClose: () -> Void

    var body: some View {
        FixturesSheet(lane: $lane, now: now, onClose: onClose)
    }
}

/// Card editor, settle pass, and Share. Segmented lanes, not a nav stack.
struct FixturesSheet: View {
    @Binding var lane: FixturesLane
    var now: Date
    var onClose: () -> Void

    @Environment(ChainStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    private var type = TypeScale()
    @State private var cameraPhase: SharePhase = .intro
    @State private var shareError: String?
    @State private var paste = ""

    init(lane: Binding<FixturesLane>, now: Date, onClose: @escaping () -> Void) {
        _lane = lane
        self.now = now
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.s2) {
                Picker("Lane", selection: $lane) {
                    ForEach(FixturesLane.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: Spacing.hit)
                .accessibilityLabel("Fixtures lane")
                Group {
                    switch lane {
                    case .card:
                        ScrollView {
                            CardEditor(now: now, onShackle: shackle)
                                .padding(.bottom, Spacing.s4)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: Spacing.s2)
                        }
                    case .settle:
                        SettlePass(now: now, onBackToHome: onClose)
                    case .share:
                        ScrollView {
                            shareLane
                                .padding(.bottom, Spacing.s4)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: Spacing.s2)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.s3)
            .padding(.top, Spacing.s2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
            .navigationTitle("Fixtures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: Spacing.hit, height: Spacing.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close fixtures")
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, cameraPhase == .live {
                cameraPhase = .intro
            }
        }
        .onDisappear {
            if cameraPhase == .live {
                cameraPhase = .intro
            }
        }
    }

    @ViewBuilder
    private var shareLane: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let message = shareError {
                BoardError(
                    title: "That card did not import",
                    line: message,
                    retry: { shareError = nil }
                )
            }
            exportPlate
            switch cameraPhase {
            case .intro:
                CameraPermissionView {
                    Task { await beginScan() }
                }
                .frame(minHeight: Spacing.mediaTall)
            case .denied:
                CameraDeniedView()
                    .frame(minHeight: Spacing.mediaTall)
            case .live:
                ZStack {
                    CardScannerView(
                        onPayload: { payload in
                            importPayload(payload)
                            cameraPhase = .intro
                        },
                        onUnavailable: { message in
                            shareError = message
                            cameraPhase = .intro
                        }
                    )
                    ScanReticle()
                }
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.mediaTall)
                .clipShape(Radius.plate)
                .overlay(Radius.plate.strokeBorder(Palette.muted.opacity(0.28), lineWidth: Radius.hairline))
            }
            simulatorTools
        }
    }

    private var exportPlate: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("CARD CODE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            if let card = store.focusedCard(now: now), let image = CardQRRender.image(for: card) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.s2)
                    .hairlineFill()
                    .accessibilityLabel("Card code for \(Figures.dayLabel(card.dayKey))")
            } else {
                Text("Add at least one fixture before a code can be drawn.")
                    .font(type.body)
                    .foregroundStyle(Palette.muted)
                    .padding(Spacing.s2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hairlineFill()
            }
        }
    }

    @ViewBuilder
    private var simulatorTools: some View {
        #if targetEnvironment(simulator)
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("SIMULATOR")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            TextField("Paste a card payload", text: $paste, axis: .vertical)
                .font(type.caption)
                .lineLimit(3...6)
                .padding(Spacing.s2)
                .frame(minHeight: Spacing.hit)
                .hairlineFill(corner: Radius.chip)
            Button("Import typed card") {
                importPayload(paste)
            }
            .buttonStyle(ChainButtonStyle(kind: .quiet))
            .disabled(paste.isEmpty)
            Button("Load a sample week") {
                loadSample()
            }
            .buttonStyle(ChainButtonStyle(kind: .quiet))
        }
        .padding(Spacing.s2)
        .hairlineFill()
        #endif
    }

    private func loadSample() {
        let kick = now.addingTimeInterval(48 * 60 * 60)
        let card = Card(
            dayKey: DayKey(now),
            fixtures: [
                Fixture(kickoff: kick, homeSide: "Northgate", awaySide: "Elm"),
                Fixture(kickoff: kick.addingTimeInterval(3600), homeSide: "Pell", awaySide: "Rowe"),
            ]
        )
        store.importCard(card)
        shareError = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func beginScan() async {
        let status = CameraGate.status()
        switch status {
        case .authorized:
            cameraPhase = .live
        case .denied, .restricted:
            cameraPhase = .denied
        case .notDetermined:
            let next = await CameraGate.request()
            if next == .authorized {
                cameraPhase = .live
            } else {
                cameraPhase = .denied
            }
        @unknown default:
            cameraPhase = .denied
        }
    }

    private func importPayload(_ raw: String) {
        let data = Data(raw.utf8)
        do {
            let card = try CardQR.card(from: data)
            store.importCard(card)
            shareError = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            shareError = "That code is not a Studlink card. Hold the code closer or type the fixtures by hand."
        }
    }

    private func shackle(fixture: Fixture, outcome: Outcome) {
        let chainID: UUID
        if let existing = store.focusedChain(now: now) {
            chainID = existing.id
        } else if let card = store.focusedCard(now: now) {
            chainID = store.openChain(for: card)
        } else {
            return
        }
        let result = store.apply(.shackle(Shackle(fixture: fixture, outcome: outcome)), now: now, chainID: chainID)
        if let refusal = result.refusal {
            shareError = LinkLabel.refusal(refusal)
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onClose()
    }
}

private enum SharePhase {
    case intro
    case live
    case denied
}
