import Foundation

/// How often a fixture, or an outcome, parts a proved chain.
struct PartRate: Sendable, Equatable, Identifiable {
    var id: String
    var homeSide: String
    var awaySide: String
    var parts: Int
    var appearances: Int

    var rate: Double {
        guard appearances > 0 else { return 0 }
        return Double(parts) / Double(appearances)
    }

    var hasResult: Bool { appearances > 0 }

    var hitRate: Double {
        guard appearances > 0 else { return 0 }
        return Double(appearances - parts) / Double(appearances)
    }
}

struct OutcomePartRate: Sendable, Equatable, Identifiable {
    var outcome: Outcome
    var parts: Int
    var appearances: Int

    var id: String { outcome.rawValue }

    var rate: Double {
        guard appearances > 0 else { return 0 }
        return Double(parts) / Double(appearances)
    }
}
