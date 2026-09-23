import Foundation

/// Written when Proof folds Made to Proved. Fixes the squared load.
struct ProofMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var chainID: UUID
    var dayKey: DayKey
    var linkCount: Int
    var load: Int
    var recordedAt: Date
}
