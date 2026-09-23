import SwiftUI

/// Sheet destinations over the locked chain. Not a tab bar.
enum BoardSheet: String, Identifiable, Equatable {
    case fixtures
    case proofHouse
    case season
    case settings

    var id: String { rawValue }

    var detents: Set<PresentationDetent> {
        switch self {
        case .settings:
            [.medium, .large]
        case .fixtures, .proofHouse, .season:
            [.large]
        }
    }
}

enum FixturesLane: String, CaseIterable, Identifiable, Equatable {
    case card
    case settle
    case share

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card:
            "Card"
        case .settle:
            "Settle"
        case .share:
            "Share"
        }
    }
}

/// Chain-locked chrome. Review keys land here once, after onboarding.
@MainActor
@Observable
final class ChainChrome {
    var sheet: BoardSheet?
    var fixturesLane: FixturesLane = .card
    var swageLink: Link?
    var showOnboarding = false
    var refusal: FoldRefusal?
    var rattleTick = 0
    var holdPulse = false
    var successFlash = false
    var didReveal = false
    private var launchReview: ReviewScreen?
    private var didReadLaunchArguments = false
    private var reviewConsumed = false
    private let launchArguments: () -> [String]

    init(launchArguments: @escaping () -> [String] = { ProcessInfo.processInfo.arguments }) {
        self.launchArguments = launchArguments
    }

    func openFixtures(_ lane: FixturesLane = .card) {
        fixturesLane = lane
        sheet = .fixtures
    }

    func applyLaunchReview() {
        guard !reviewConsumed else { return }
        guard OnboardingGate.isComplete() else { return }
        readLaunchReviewIfNeeded()
        reviewConsumed = true
        guard let screen = launchReview else { return }

        switch screen {
        case .today, .chain, .canvas:
            fixturesLane = .card
            sheet = nil
        case .log:
            fixturesLane = .settle
            sheet = .fixtures
        case .goals, .season:
            sheet = .season
        case .fixtures:
            fixturesLane = .card
            sheet = .fixtures
        case .proofhouse:
            sheet = .proofHouse
        case .settings:
            sheet = .settings
        }
    }

    private func readLaunchReviewIfNeeded() {
        guard !didReadLaunchArguments else { return }
        didReadLaunchArguments = true
        launchReview = ReviewScreen.parse(arguments: launchArguments())
    }

    func showRefusal(_ reason: FoldRefusal) {
        refusal = reason
        if reason == .secondSwage {
            rattleTick += 1
        }
    }

    func flashSuccess() {
        successFlash = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            successFlash = false
        }
    }

    func pulseHold() {
        holdPulse = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            holdPulse = false
        }
    }
}
