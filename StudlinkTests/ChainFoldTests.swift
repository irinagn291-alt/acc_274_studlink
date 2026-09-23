import XCTest
@testable import Studlink

final class ChainFoldTests: XCTestCase {
    func test_shackle_foldsBareToMade() {
        let fixture = FoldFixtures.fixture("Millbridge", "Oakford")
        let result = ChainFold.reduce(
            state: .bare,
            event: .shackle(Shackle(fixture: fixture, outcome: .home)),
            context: FoldFixtures.context()
        )
        XCTAssertTrue(result.accepted)
        XCTAssertTrue(result.state.isMade)
        XCTAssertEqual(result.state.links.count, 1)
        XCTAssertEqual(result.state.links[0].outcome, .home)
    }

    func test_shackle_refusesDuplicateFixture() {
        let fixture = FoldFixtures.fixture("Redharbor", "Linmere")
        let made = FoldFixtures.make(links: [(fixture, .draw)])
        let again = ChainFold.reduce(
            state: made.state,
            event: .shackle(Shackle(fixture: fixture, outcome: .home)),
            context: FoldFixtures.context()
        )
        XCTAssertEqual(again.refusal, .fixtureAlreadyLinked)
        XCTAssertEqual(again.state.links.count, 1)
    }

    func test_shackle_refusesBlankSides() {
        let fixture = FoldFixtures.fixture("  ", "")
        let result = ChainFold.reduce(
            state: .bare,
            event: .shackle(Shackle(fixture: fixture, outcome: .away)),
            context: FoldFixtures.context()
        )
        XCTAssertEqual(result.refusal, .blankSides)
        XCTAssertTrue(result.state.isBare)
    }

    func test_shackle_onProvedIsFrozen() {
        let a = FoldFixtures.fixture("Castlewick", "South Fen")
        let b = FoldFixtures.fixture("Dunlow", "Hartsfield")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .away)], then: .proof)
        XCTAssertTrue(proved.state.isProved)
        let extra = FoldFixtures.fixture("Kenning", "Portavon")
        let refused = ChainFold.reduce(
            state: proved.state,
            event: .shackle(Shackle(fixture: extra, outcome: .draw)),
            context: FoldFixtures.context()
        )
        XCTAssertEqual(refused.refusal, .frozen)
    }

    func test_proof_refusesUnderTwoLinks() {
        let fixture = FoldFixtures.fixture("Barrowmere", "Whitecliff")
        let result = FoldFixtures.make(links: [(fixture, .home)], then: .proof)
        XCTAssertEqual(result.refusal, .underTwoLinks)
        XCTAssertTrue(result.state.isMade)
    }

    func test_proof_onEmptyWritesSlack() {
        let result = ChainFold.reduce(
            state: .bare,
            event: .proof,
            context: FoldFixtures.context()
        )
        XCTAssertEqual(result.slack, .empty)
        XCTAssertTrue(result.state.isBare)
    }

    func test_proof_squaresLoadAndFoldsToProved() {
        let a = FoldFixtures.fixture("Ashford", "Nene")
        let b = FoldFixtures.fixture("Holt", "Rye")
        let c = FoldFixtures.fixture("Pembridge", "Cale")
        let result = FoldFixtures.make(links: [(a, .home), (b, .draw), (c, .away)], then: .proof)
        XCTAssertTrue(result.accepted)
        XCTAssertTrue(result.state.isProved)
        XCTAssertEqual(result.state.displayedLoad, 9)
        XCTAssertEqual(result.marks.count, 1)
        if case .proof(let mark) = result.marks[0] {
            XCTAssertEqual(mark.linkCount, 3)
            XCTAssertEqual(mark.load, 9)
        } else {
            XCTFail("expected ProofMark")
        }
    }
}
