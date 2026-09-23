import XCTest
@testable import Studlink

final class ProofLoadTests: XCTestCase {
    func test_squaredLoad_threePaysNine_sixPaysThirtySix() {
        XCTAssertEqual(ProofLoad(linkCount: 3).points, 9)
        XCTAssertEqual(ProofLoad(linkCount: 6).points, 36)
        XCTAssertEqual(ProofLoad(linkCount: 0).points, 0)
        XCTAssertEqual(ProofLoad(linkCount: 1).points, 1)
        XCTAssertEqual(ProofLoad(linkCount: 2).points, 4)
    }

    func test_displayedLoad_voidsAfterPart() {
        let a = FoldFixtures.fixture("Otterley", "Wick")
        let b = FoldFixtures.fixture("Marlow", "Tarn")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .away)], then: .proof)
        XCTAssertEqual(proved.state.displayedLoad, 4)
        let parted = ChainFold.reduce(
            state: proved.state,
            event: .settle(results: [a.id: .away]),
            context: FoldFixtures.context()
        )
        XCTAssertTrue(parted.state.isParted)
        XCTAssertEqual(parted.state.displayedLoad, 0)
    }
}
