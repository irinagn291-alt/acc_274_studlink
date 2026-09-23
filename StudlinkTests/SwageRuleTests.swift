import XCTest
@testable import Studlink

final class SwageRuleTests: XCTestCase {
    func test_swage_replacesUnstartedLinkOnce() {
        let first = FoldFixtures.fixture("Selby", "Croft")
        let second = FoldFixtures.fixture("Upton", "Dale")
        let made = FoldFixtures.make(links: [(first, .home), (second, .draw)])
        let linkID = made.state.links[0].id
        let result = ChainFold.reduce(
            state: made.state,
            event: .swage(Swage(linkID: linkID, outcome: .away)),
            context: FoldFixtures.context(swageCount: 0)
        )
        XCTAssertTrue(result.accepted)
        XCTAssertTrue(result.state.isMade)
        XCTAssertEqual(result.state.links[0].outcome, .away)
        XCTAssertEqual(result.state.links[0].id, linkID)
        XCTAssertEqual(result.marks.count, 1)
        if case .swage(let mark) = result.marks[0] {
            XCTAssertEqual(mark.from, .home)
            XCTAssertEqual(mark.to, .away)
        } else {
            XCTFail("expected SwageMark")
        }
    }

    func test_secondSwage_isRefused() {
        let first = FoldFixtures.fixture("Yorke", "Fenn")
        let second = FoldFixtures.fixture("Holt", "Rye")
        let made = FoldFixtures.make(links: [(first, .home), (second, .home)])
        let refused = ChainFold.reduce(
            state: made.state,
            event: .swage(Swage(linkID: made.state.links[0].id, outcome: .draw)),
            context: FoldFixtures.context(swageCount: 1)
        )
        XCTAssertEqual(refused.refusal, .secondSwage)
        XCTAssertEqual(refused.state.links[0].outcome, .home)
        XCTAssertTrue(refused.marks.isEmpty)
    }

    func test_swage_afterKickoff_isRefused() {
        let past = FoldFixtures.fixture(
            "Ashford",
            "Nene",
            kickoff: FoldFixtures.now.addingTimeInterval(-60)
        )
        let future = FoldFixtures.fixture("Pembridge", "Cale")
        let made = FoldFixtures.make(links: [(past, .home), (future, .draw)])
        let refused = ChainFold.reduce(
            state: made.state,
            event: .swage(Swage(linkID: made.state.links[0].id, outcome: .away)),
            context: FoldFixtures.context(now: FoldFixtures.now, swageCount: 0)
        )
        XCTAssertEqual(refused.refusal, .kickoffPassed)
    }

    func test_swage_onProved_isFrozen() {
        let a = FoldFixtures.fixture("Millbridge", "Oakford")
        let b = FoldFixtures.fixture("Redharbor", "Linmere")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .away)], then: .proof)
        let refused = ChainFold.reduce(
            state: proved.state,
            event: .swage(Swage(linkID: proved.state.links[0].id, outcome: .draw)),
            context: FoldFixtures.context()
        )
        XCTAssertEqual(refused.refusal, .frozen)
    }
}
