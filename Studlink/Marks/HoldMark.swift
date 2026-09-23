import Foundation

/// Written when a Link matches the typed result.
struct HoldMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var chainID: UUID
    var linkID: UUID
    var fixtureID: UUID
    var homeSide: String
    var awaySide: String
    var outcome: Outcome
    var index: Int
    var recordedAt: Date
}
