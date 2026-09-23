import XCTest
@testable import Studlink

final class CardQRTests: XCTestCase {
    func test_payloadRoundTrip() throws {
        let card = Card(
            dayKey: DayKey(rawValue: 20_260_328),
            fixtures: [
                FoldFixtures.fixture("Millbridge", "Oakford"),
                FoldFixtures.fixture("Redharbor", "Linmere"),
            ]
        )
        let data = try CardQR.payload(for: card)
        let restored = try CardQR.card(from: data)
        XCTAssertEqual(restored, card)
    }

    func test_emptyCard_isInvalid() {
        let card = Card(dayKey: DayKey(rawValue: 20_260_301), fixtures: [])
        XCTAssertThrowsError(try CardQR.payload(for: card)) { error in
            XCTAssertEqual(error as? CardQRError, .empty)
        }
    }

    func test_malformedJSON_isDecodeError() {
        XCTAssertThrowsError(try CardQR.card(from: Data("not-json".utf8))) { error in
            XCTAssertEqual(error as? CardQRError, .decode)
        }
    }
}
