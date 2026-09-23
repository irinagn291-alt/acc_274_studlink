import Foundation

/// One past chain rebuilt from marks alone.
struct HouseEntry: Sendable, Equatable, Identifiable {
    var chainID: UUID
    var dayKey: DayKey
    var linkCount: Int
    var load: Int
    var voided: Bool
    var holds: [HoldMark]
    var snap: SnapMark?

    var id: UUID { chainID }

    var partIndex: Int? { snap?.partIndex }
}

/// Ledger reader. Pages are a fold over marks, not live Chain mutation.
enum ProofHouse {
    static func rebuild(from marks: [Mark]) -> [HouseEntry] {
        MarkLedger.proofs(in: marks)
            .sorted { lhs, rhs in
                if lhs.dayKey != rhs.dayKey {
                    return lhs.dayKey > rhs.dayKey
                }
                return lhs.recordedAt > rhs.recordedAt
            }
            .map { proof in
                let snap = MarkLedger.snap(in: marks, chainID: proof.chainID)
                return HouseEntry(
                    chainID: proof.chainID,
                    dayKey: proof.dayKey,
                    linkCount: proof.linkCount,
                    load: snap == nil ? proof.load : 0,
                    voided: snap != nil,
                    holds: MarkLedger.holds(in: marks, chainID: proof.chainID),
                    snap: snap
                )
            }
    }
}
