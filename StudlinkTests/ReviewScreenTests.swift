import XCTest
@testable import Studlink

final class ReviewScreenTests: XCTestCase {
    func test_parseTodayLogGoalsAndExtras() {
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "goals"]), .goals)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "chain"]), .chain)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "canvas"]), .canvas)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "fixtures"]), .fixtures)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "proofhouse"]), .proofhouse)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "season"]), .season)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "settings"]), .settings)
        XCTAssertEqual(ReviewScreen.parse(arguments: ["-ReviewScreen", "SeAsOn"]), .season)
    }

    func test_parseMissingOrUnknown() {
        XCTAssertNil(ReviewScreen.parse(arguments: []))
        XCTAssertNil(ReviewScreen.parse(arguments: ["-ReviewScreen"]))
        XCTAssertNil(ReviewScreen.parse(arguments: ["-ReviewScreen", "unknown"]))
        XCTAssertNil(ReviewScreen.parse(arguments: ["today"]))
    }
}
