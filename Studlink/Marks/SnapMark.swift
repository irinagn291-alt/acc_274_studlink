import Foundation

/// Written on the first false Link. Parts the chain and voids the load.
struct SnapMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var chainID: UUID
    var linkID: UUID
    var fixtureID: UUID
    var homeSide: String
    var awaySide: String
    var picked: Outcome
    var result: Outcome
    var partIndex: Int
    var recordedAt: Date
}
