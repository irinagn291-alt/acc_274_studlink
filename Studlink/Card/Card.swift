import Foundation

/// A week's fixture list, keyed by a YYYYMMDD daykey.
struct Card: Codable, Sendable, Identifiable, Equatable {
    var dayKey: DayKey
    var fixtures: [Fixture]

    var id: DayKey { dayKey }

    init(dayKey: DayKey, fixtures: [Fixture]) {
        self.dayKey = dayKey
        self.fixtures = fixtures
    }
}
