import Algorithms
import Foundation

/// One bucket on the Chain Length versus Proved-whole curve.
struct LengthPoint: Sendable, Equatable, Identifiable {
    var length: Int
    var provedWhole: Int
    var attempted: Int

    var id: Int { length }

    var wholeRate: Double {
        guard attempted > 0 else { return 0 }
        return Double(provedWhole) / Double(attempted)
    }
}

/// Season curve. Uses `chunked(on:)` so length buckets stay in chain order.
enum LengthCurve {
    static func points(from marks: [Mark]) -> [LengthPoint] {
        let entries = ProofHouse.rebuild(from: marks).sorted { $0.linkCount < $1.linkCount }
        var curve: [LengthPoint] = []
        for (length, group) in entries.chunked(on: \.linkCount) {
            let attempted = group.count
            let whole = group.filter { !$0.voided }.count
            curve.append(LengthPoint(length: length, provedWhole: whole, attempted: attempted))
        }
        return curve
    }
}
