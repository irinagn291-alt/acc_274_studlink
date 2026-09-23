import Foundation

/// Locale numbers and day labels. Views never interpolate a raw count.
@MainActor
enum Figures {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let kickoff: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func int(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? "0"
    }

    static func rate(_ value: Double) -> String {
        percent.string(from: NSNumber(value: value)) ?? "0%"
    }

    static func kickoff(_ date: Date) -> String {
        kickoff.string(from: date)
    }

    static func dayLabel(_ key: DayKey, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar) else {
            return int(key.rawValue)
        }
        return day.string(from: calendar.startOfDay(for: date))
    }

    static func date(from key: DayKey, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = key.rawValue / 10_000
        parts.month = (key.rawValue % 10_000) / 100
        parts.day = key.rawValue % 100
        return calendar.date(from: parts)
    }
}
