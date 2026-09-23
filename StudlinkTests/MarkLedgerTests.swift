import XCTest
@testable import Studlink

final class MarkLedgerTests: XCTestCase {
    func test_rebuildFromMarksAlone_reproducesHouseAndSeason() {
        let book = DemoSeed.makeBook(now: FoldFixtures.now)
        let house = ProofHouse.rebuild(from: book.marks)

        XCTAssertEqual(house.count, 2)

        let whole = house.first(where: { !$0.voided })
        let parted = house.first(where: { $0.voided })
        XCTAssertEqual(whole?.linkCount, 3)
        XCTAssertEqual(whole?.load, 9)
        XCTAssertEqual(whole?.holds.count, 3)
        XCTAssertNil(whole?.snap)

        XCTAssertEqual(parted?.linkCount, 5)
        XCTAssertEqual(parted?.load, 0)
        XCTAssertEqual(parted?.partIndex, 3)
        XCTAssertEqual(parted?.holds.count, 3)
        XCTAssertEqual(parted?.snap?.partIndex, 3)

        XCTAssertEqual(SeasonTotals.points(from: book.marks), 9)
        XCTAssertEqual(SeasonTotals.longestWhole(from: book.marks), 3)

        let live = book.cards.first(where: { $0.fixtures.count == 6 })
        let rates = SeasonTotals.partRates(from: book.marks, fixtures: live?.fixtures ?? [])
        XCTAssertTrue(rates.contains(where: { $0.parts == 1 && $0.homeSide == "Dunlow" }))
        XCTAssertTrue(rates.contains(where: { $0.homeSide == "Kenning" && !$0.hasResult }))
        XCTAssertEqual(
            rates.first(where: { $0.homeSide == "Kenning" }).map { LinkLabel.fixtureRateLabel(appearances: $0.appearances, hitRate: $0.hitRate) },
            "No result yet"
        )
        XCTAssertTrue(rates.allSatisfy { fixture in
            ["Millbridge", "Redharbor", "Castlewick", "Dunlow", "Barrowmere", "Kenning"].contains(fixture.homeSide)
        })

        let curve = LengthCurve.points(from: book.marks)
        XCTAssertTrue(curve.contains(where: { $0.length == 3 && $0.provedWhole == 1 }))
        XCTAssertTrue(curve.contains(where: { $0.length == 5 && $0.provedWhole == 0 && $0.attempted == 1 }))
    }

    func test_marksAreAppendOnly_unknownKindSkipped() throws {
        let mark = Mark.proof(
            ProofMark(
                id: UUID(),
                chainID: UUID(),
                dayKey: DayKey(rawValue: 20_240_101),
                linkCount: 2,
                load: 4,
                recordedAt: FoldFixtures.now
            )
        )
        var book = ChainBook.empty
        book.marks = [mark]
        let data = try ChainBookCodec.encoder().encode(book)
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return XCTFail("json")
        }
        var marks = json["marks"] as? [[String: Any]] ?? []
        marks.append(["kind": "unknown", "payload": ["id": UUID().uuidString]])
        json["marks"] = marks
        let tainted = try JSONSerialization.data(withJSONObject: json)
        let decoded = try XCTUnwrap(ChainBookCodec.decode(tainted))
        XCTAssertEqual(decoded.marks.count, 1)
        if case .proof(let payload) = decoded.marks[0] {
            XCTAssertEqual(payload.load, 4)
        } else {
            XCTFail("kept ProofMark")
        }
    }
}
