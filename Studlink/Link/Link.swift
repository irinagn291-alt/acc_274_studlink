import Foundation

/// One pick on one Fixture. Identity is stable across a single Swage.
struct Link: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var fixture: Fixture
    var outcome: Outcome
    var settle: LinkSettle

    init(
        id: UUID = UUID(),
        fixture: Fixture,
        outcome: Outcome,
        settle: LinkSettle = .open
    ) {
        self.id = id
        self.fixture = fixture
        self.outcome = outcome
        self.settle = settle
    }

    func replacing(outcome: Outcome) -> Link {
        Link(id: id, fixture: fixture, outcome: outcome, settle: settle)
    }

    func withSettle(_ settle: LinkSettle) -> Link {
        Link(id: id, fixture: fixture, outcome: outcome, settle: settle)
    }
}

/// How a Link sits after settlement. Open until a Hold, Snap, or void.
enum LinkSettle: String, Codable, Sendable, Equatable {
    case open
    case hold
    case snap
    case voided
}
