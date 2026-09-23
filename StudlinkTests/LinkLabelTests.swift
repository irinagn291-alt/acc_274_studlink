import XCTest
@testable import Studlink

final class LinkLabelTests: XCTestCase {
    func test_spokenLinkNamesFixturePickAndSettle() {
        let fixture = FoldFixtures.fixture("Arsenal", "Everton")
        let link = Link(fixture: fixture, outcome: .home, settle: .hold)
        XCTAssertEqual(
            LinkLabel.spoken(link: link, index: 2),
            "Link 3, Arsenal versus Everton, Home, holds"
        )
    }

    func test_picksStatusFollowsProofState() {
        XCTAssertEqual(LinkLabel.picksStatus(isLocked: false), "Picks made")
        XCTAssertEqual(LinkLabel.picksStatus(isLocked: true), "Picks locked")
    }

    func test_homeAndSettleCopyNameTheNextTap() {
        XCTAssertEqual(
            LinkLabel.chainStatus(picked: 3, total: 6, load: 9),
            "3 of 6 picked - 9 points if the chain holds"
        )
        XCTAssertEqual(
            LinkLabel.unstartedHint(count: 3),
            "3 unstarted picks can still be changed before proof"
        )
        XCTAssertEqual(
            LinkLabel.unstartedHint(count: 1),
            "1 unstarted pick can still be changed before proof"
        )
        XCTAssertEqual(
            LinkLabel.settleSummary(linked: 3, open: 3),
            "3 linked picks and 3 open slots"
        )
        XCTAssertEqual(LinkLabel.payoutHeading(), "This week's payout")
        XCTAssertEqual(LinkLabel.proveAction(locked: false), "Prove chain")
        XCTAssertEqual(LinkLabel.proveAction(locked: true), "Chain locked")
        XCTAssertEqual(LinkLabel.addNextPick(), "Add the next pick")
        XCTAssertEqual(
            LinkLabel.addNextPickLine(remaining: 3, locked: false),
            "3 fixtures still open this week"
        )
        XCTAssertEqual(
            LinkLabel.changeLeft(available: true),
            "You can still change one pick before you lock the chain"
        )
        XCTAssertEqual(LinkLabel.fixtureRateLabel(appearances: 0, hitRate: 0), "No result yet")
        XCTAssertEqual(LinkLabel.fixtureRateLabel(appearances: 1, hitRate: 0), "0%")
    }

    func test_fixturesSectionTitleMatchesRowDates() {
        let now = FoldFixtures.now
        let today = DayKey(now)
        let sameDay = DemoSeed.sameDayKickoffs(now: now, count: 3)
        XCTAssertEqual(
            LinkLabel.fixturesSectionTitle(cardDay: today, now: now, kickoffs: sameDay),
            "Today's fixtures"
        )
        let tomorrow = now.addingTimeInterval(36 * 60 * 60)
        XCTAssertEqual(
            LinkLabel.fixturesSectionTitle(cardDay: today, now: now, kickoffs: [tomorrow]),
            "Fixtures on this card"
        )
    }

    func test_refusalCopyIsPlain() {
        XCTAssertEqual(LinkLabel.refusal(.secondSwage), "This chain already used its one swage.")
        XCTAssertEqual(LinkLabel.refusal(.underTwoLinks), "Proof needs at least two links.")
        XCTAssertFalse(LinkLabel.refusal(.frozen).contains("—"))
    }
}
