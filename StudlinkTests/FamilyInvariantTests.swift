import XCTest
@testable import Studlink

/// Family prediction_league invariant:
/// Score = 100 × (1 + confidence/100) if correct, else 0.
/// One pick/event. Must lock before resolve. Score real outcomes — not RNG.
///
/// Studlink pays ProofLoad(linkCount:) on a proved-whole chain, else 0.
/// Confidence is not used here. The shared rules still hold.
final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_onePickPerFixture_lockBeforeResolve_realOutcomesNotRNG() {
        let first = FoldFixtures.fixture("Millbridge", "Oakford")
        let second = FoldFixtures.fixture("Redharbor", "Linmere")
        let ctx = FoldFixtures.context()

        var state: Proof = .bare
        state = ChainFold.reduce(
            state: state,
            event: .shackle(Shackle(fixture: first, outcome: .home)),
            context: ctx
        ).state
        let duplicate = ChainFold.reduce(
            state: state,
            event: .shackle(Shackle(fixture: first, outcome: .away)),
            context: ctx
        )
        XCTAssertEqual(duplicate.refusal, .fixtureAlreadyLinked, "one pick per fixture")

        state = ChainFold.reduce(
            state: state,
            event: .shackle(Shackle(fixture: second, outcome: .draw)),
            context: ctx
        ).state

        let earlySettle = ChainFold.reduce(
            state: state,
            event: .settle(results: [first.id: .home, second.id: .draw]),
            context: ctx
        )
        XCTAssertEqual(earlySettle.refusal, .notProved, "must lock before resolve")

        let locked = ChainFold.reduce(state: state, event: .proof, context: ctx)
        XCTAssertTrue(locked.state.isProved)

        let typed = ChainFold.reduce(
            state: locked.state,
            event: .settle(results: [first.id: .home, second.id: .draw]),
            context: ctx
        )
        XCTAssertTrue(typed.state.isProved)
        XCTAssertEqual(typed.state.displayedLoad, ProofLoad(linkCount: 2).points)
        XCTAssertEqual(typed.state.links.map(\.settle), [.hold, .hold])

        let miss = ChainFold.reduce(
            state: locked.state,
            event: .settle(results: [first.id: .away, second.id: .draw]),
            context: ctx
        )
        XCTAssertTrue(miss.state.isParted)
        XCTAssertEqual(miss.state.displayedLoad, 0)

        // Score real outcomes. Never RNG. Never randomElement().
        XCTAssertEqual(SeasonTotals.points(from: typed.marks), 0)
        XCTAssertEqual(SeasonTotals.points(from: locked.marks + typed.marks), 4)
    }
}
