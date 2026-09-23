import Foundation

/// One match on a Card: kickoff plus the two sides. Event in this lexicon.
struct Fixture: Codable, Sendable, Hashable, Identifiable, Equatable {
    var id: UUID
    var kickoff: Date
    var homeSide: String
    var awaySide: String

    init(
        id: UUID = UUID(),
        kickoff: Date,
        homeSide: String,
        awaySide: String
    ) {
        self.id = id
        self.kickoff = kickoff
        self.homeSide = homeSide
        self.awaySide = awaySide
    }

    var trimmedHome: String {
        homeSide.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAway: String {
        awaySide.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasNamedSides: Bool {
        !trimmedHome.isEmpty && !trimmedAway.isEmpty
    }
}
