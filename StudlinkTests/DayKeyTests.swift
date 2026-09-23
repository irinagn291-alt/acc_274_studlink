import XCTest
@testable import Studlink

final class DayKeyTests: XCTestCase {
    func test_yyyymmdd_fromStartOfDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 3
        parts.day = 8
        parts.hour = 22
        parts.minute = 15
        let date = try XCTUnwrap(calendar.date(from: parts))
        let key = DayKey(date, calendar: calendar)
        XCTAssertEqual(key.rawValue, 20_260_308)
        XCTAssertEqual(DayKey(calendar.startOfDay(for: date), calendar: calendar), key)
    }

    func test_comparable_ordersDays() {
        XCTAssertTrue(DayKey(rawValue: 20_240_101) < DayKey(rawValue: 20_240_102))
    }
}
