import Foundation

/// Season numbers from the mark ledger. Points only. No purse.
enum SeasonTotals {
    static func points(from marks: [Mark]) -> Int {
        ProofHouse.rebuild(from: marks)
            .filter { !$0.voided }
            .reduce(0) { $0 + $1.load }
    }

    static func longestWhole(from marks: [Mark]) -> Int {
        ProofHouse.rebuild(from: marks)
            .filter { !$0.voided }
            .map(\.linkCount)
            .max() ?? 0
    }

    static func partRates(from marks: [Mark], fixtures: [Fixture] = []) -> [PartRate] {
        var parts: [String: (home: String, away: String, parts: Int, seen: Int)] = [:]

        for mark in marks {
            switch mark {
            case .hold(let hold):
                let key = pairKey(hold.homeSide, hold.awaySide)
                var row = parts[key] ?? (hold.homeSide, hold.awaySide, 0, 0)
                row.seen += 1
                parts[key] = row
            case .snap(let snap):
                let key = pairKey(snap.homeSide, snap.awaySide)
                var row = parts[key] ?? (snap.homeSide, snap.awaySide, 0, 0)
                row.seen += 1
                row.parts += 1
                parts[key] = row
            case .proof, .swage:
                break
            }
        }

        for fixture in fixtures {
            let key = pairKey(fixture.trimmedHome, fixture.trimmedAway)
            if parts[key] == nil {
                parts[key] = (fixture.trimmedHome, fixture.trimmedAway, 0, 0)
            }
        }

        return parts
            .map { key, row in
                PartRate(
                    id: key,
                    homeSide: row.home,
                    awaySide: row.away,
                    parts: row.parts,
                    appearances: row.seen
                )
            }
            .sorted { lhs, rhs in
                if lhs.hasResult != rhs.hasResult {
                    return lhs.hasResult && !rhs.hasResult
                }
                if lhs.hitRate != rhs.hitRate {
                    return lhs.hitRate > rhs.hitRate
                }
                return lhs.homeSide < rhs.homeSide
            }
    }

    private static func pairKey(_ home: String, _ away: String) -> String {
        "\(home.localizedLowercase)|\(away.localizedLowercase)"
    }

    static func outcomePartRates(from marks: [Mark]) -> [OutcomePartRate] {
        var tallies: [Outcome: (parts: Int, seen: Int)] = [:]
        for mark in marks {
            switch mark {
            case .hold(let hold):
                var row = tallies[hold.outcome] ?? (0, 0)
                row.seen += 1
                tallies[hold.outcome] = row
            case .snap(let snap):
                var row = tallies[snap.picked] ?? (0, 0)
                row.seen += 1
                row.parts += 1
                tallies[snap.picked] = row
            case .proof, .swage:
                break
            }
        }
        return Outcome.allCases.map { outcome in
            let row = tallies[outcome] ?? (0, 0)
            return OutcomePartRate(outcome: outcome, parts: row.parts, appearances: row.seen)
        }
    }
}
