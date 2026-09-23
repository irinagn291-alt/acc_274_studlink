import Foundation

/// Calendar day as YYYYMMDD. Built from `Calendar.startOfDay`, never wall-clock math.
struct DayKey: RawRepresentable, Codable, Sendable, Hashable, Comparable {
    var rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        rawValue = year * 10_000 + month * 100 + day
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
