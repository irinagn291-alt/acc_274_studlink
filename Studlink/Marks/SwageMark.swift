import Foundation

/// Written when one unstarted Link is replaced. The fold counts these.
struct SwageMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var chainID: UUID
    var linkID: UUID
    var fixtureID: UUID
    var from: Outcome
    var to: Outcome
    var recordedAt: Date
}
