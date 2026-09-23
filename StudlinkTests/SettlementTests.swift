import XCTest
@testable import Studlink

final class SettlementTests: XCTestCase {
    func test_settle_beforeProof_isRefused() {
        let a = FoldFixtures.fixture("Castlewick", "South Fen")
        let b = FoldFixtures.fixture("Dunlow", "Hartsfield")
        let made = FoldFixtures.make(links: [(a, .home), (b, .draw)])
        let refused = ChainFold.reduce(
            state: made.state,
            event: .settle(results: [a.id: .home, b.id: .draw]),
            context: FoldFixtures.context()
        )
        XCTAssertEqual(refused.refusal, .notProved)
    }

    func test_allHolds_keepsProvedLoad() {
        let a = FoldFixtures.fixture("Kenning", "Portavon")
        let b = FoldFixtures.fixture("Barrowmere", "Whitecliff")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .away)], then: .proof)
        let settled = ChainFold.reduce(
            state: proved.state,
            event: .settle(results: [a.id: .home, b.id: .away]),
            context: FoldFixtures.context()
        )
        XCTAssertTrue(settled.state.isProved)
        XCTAssertEqual(settled.state.displayedLoad, 4)
        XCTAssertEqual(settled.marks.count, 2)
        XCTAssertEqual(settled.state.links.map(\.settle), [.hold, .hold])
    }

    func test_firstMiss_partsAndVoidsBelow() {
        let a = FoldFixtures.fixture("Otterley", "Wick")
        let b = FoldFixtures.fixture("Marlow", "Tarn")
        let c = FoldFixtures.fixture("Selby", "Croft")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .draw), (c, .away)], then: .proof)
        let settled = ChainFold.reduce(
            state: proved.state,
            event: .settle(results: [a.id: .home, b.id: .home, c.id: .away]),
            context: FoldFixtures.context()
        )
        guard case .parted(let links, let index) = settled.state else {
            return XCTFail("expected parted")
        }
        XCTAssertEqual(index, 1)
        XCTAssertEqual(links.map(\.settle), [.hold, .snap, .voided])
        XCTAssertEqual(settled.state.displayedLoad, 0)
        XCTAssertEqual(settled.marks.count, 2)
        if case .snap(let snap) = settled.marks.last {
            XCTAssertEqual(snap.partIndex, 1)
            XCTAssertEqual(snap.picked, .draw)
            XCTAssertEqual(snap.result, .home)
        } else {
            XCTFail("expected SnapMark")
        }
    }

    func test_unsettledStopsWithoutParting() {
        let a = FoldFixtures.fixture("Upton", "Dale")
        let b = FoldFixtures.fixture("Yorke", "Fenn")
        let proved = FoldFixtures.make(links: [(a, .home), (b, .away)], then: .proof)
        let settled = ChainFold.reduce(
            state: proved.state,
            event: .settle(results: [a.id: .home]),
            context: FoldFixtures.context()
        )
        XCTAssertTrue(settled.state.isProved)
        XCTAssertEqual(settled.state.links.map(\.settle), [.hold, .open])
        XCTAssertEqual(settled.state.displayedLoad, 4)
    }
}
