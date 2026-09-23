import Foundation

/// Pure reads over the append-only mark array. Proof House and Season use only this.
enum MarkLedger {
    static func swageCount(in marks: [Mark], chainID: UUID) -> Int {
        marks.reduce(into: 0) { count, mark in
            if case .swage(let payload) = mark, payload.chainID == chainID {
                count += 1
            }
        }
    }

    static func proof(in marks: [Mark], chainID: UUID) -> ProofMark? {
        marks.reversed().compactMap { mark -> ProofMark? in
            if case .proof(let payload) = mark, payload.chainID == chainID {
                return payload
            }
            return nil
        }.first
    }

    static func proofs(in marks: [Mark]) -> [ProofMark] {
        marks.compactMap { mark in
            if case .proof(let payload) = mark {
                return payload
            }
            return nil
        }
    }

    static func holds(in marks: [Mark], chainID: UUID) -> [HoldMark] {
        marks.compactMap { mark in
            if case .hold(let payload) = mark, payload.chainID == chainID {
                return payload
            }
            return nil
        }
        .sorted { $0.index < $1.index }
    }

    static func snap(in marks: [Mark], chainID: UUID) -> SnapMark? {
        marks.compactMap { mark -> SnapMark? in
            if case .snap(let payload) = mark, payload.chainID == chainID {
                return payload
            }
            return nil
        }.first
    }
}
