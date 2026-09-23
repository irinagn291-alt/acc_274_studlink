import SwiftUI

/// Named screen wrapper so live ReviewScreen coverage can match Settings.
struct SettingsScreen: View {
    var onClose: () -> Void
    var onReplayOnboarding: () -> Void

    var body: some View {
        SettingsSheet(onClose: onClose, onReplayOnboarding: onReplayOnboarding)
    }
}

/// Notes, onboarding replay, reset, and the contact URL.
struct SettingsSheet: View {
    var onClose: () -> Void
    var onReplayOnboarding: () -> Void

    @Environment(ChainStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var type = TypeScale()
    @State private var confirmReset = false
    @State private var resetting = false

    init(onClose: @escaping () -> Void, onReplayOnboarding: @escaping () -> Void) {
        self.onClose = onClose
        self.onReplayOnboarding = onReplayOnboarding
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    if store.lastPersistError != nil {
                        BoardError(
                            title: "The last save did not finish",
                            line: "Your on-screen chain is still here. Try writing the book again.",
                            retry: { Task { await store.flush() } }
                        )
                    }
                    if store.book.cards.isEmpty && store.book.chains.isEmpty {
                        emptyNote
                    } else {
                        filledNote
                    }
                    notes
                    controls
                    ContactLink()
                        .padding(.horizontal, Spacing.s2)
                        .hairlineFill()
                    pointsLine
                }
                .padding(Spacing.s3)
                .padding(.bottom, Spacing.s4)
            }
            .background(Palette.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: Spacing.hit, height: Spacing.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close settings")
                }
            }
            .confirmationDialog(
                "Reset all chains, cards and marks on this device?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    Task { await reset() }
                }
                Button("Keep data", role: .cancel) {}
            } message: {
                Text("This cannot be undone. The proving book on this phone will be empty.")
            }
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            PaperCollage(name: "sdl_EmptyList", maxSide: 96)
            Text("No book on this phone")
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
            Text("Add a fixture card to start a chain. Reset stays quiet until there is something to clear.")
                .font(type.body)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private var filledNote: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("ON THIS PHONE")
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.muted)
                .textCase(.uppercase)
            Text("\(Figures.int(store.book.cards.count)) cards. \(Figures.int(store.book.chains.count)) chains. \(Figures.int(store.book.marks.count)) marks.")
                .font(type.body)
                .foregroundStyle(Palette.ink)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            note(
                title: "Board",
                line: "Hairline plates, one accent, Courier New on the load. Body copy stays on the system face."
            )
            note(
                title: "VoiceOver",
                line: "Every link is spoken as fixture, pick and settle state. Icon-only chrome has its own label."
            )
            note(
                title: "Reduce Motion",
                line: reduceMotion
                    ? "Reduce Motion is on. The chain reveal is a single fade."
                    : "The chain reveals in a short stagger. Reduce Motion collapses that to one fade."
            )
        }
    }

    private func note(title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(title)
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
            Text(line)
                .font(type.body)
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Button("Replay onboarding", action: onReplayOnboarding)
                .buttonStyle(ChainButtonStyle(kind: .quiet))
            Button("Reset all data") {
                confirmReset = true
            }
            .buttonStyle(ChainButtonStyle(kind: .destructive, isLoading: resetting))
            .disabled(resetting || store.book.cards.isEmpty && store.book.chains.isEmpty)
            .accessibilityLabel("Reset all data")
        }
    }

    private var pointsLine: some View {
        Text("Studlink is a points league only. There is no stake, no balance, no odds and no cash out.")
            .font(type.body)
            .foregroundStyle(Palette.muted)
            .padding(Spacing.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .hairlineFill()
    }

    private func reset() async {
        resetting = true
        await store.resetAllData()
        resetting = false
        onClose()
    }
}
