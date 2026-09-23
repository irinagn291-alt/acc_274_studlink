import Foundation

/// Append-only ledger entry. Never mutated, never compacted.
enum Mark: Sendable, Equatable {
    case proof(ProofMark)
    case hold(HoldMark)
    case snap(SnapMark)
    case swage(SwageMark)

    var chainID: UUID {
        switch self {
        case .proof(let mark):
            mark.chainID
        case .hold(let mark):
            mark.chainID
        case .snap(let mark):
            mark.chainID
        case .swage(let mark):
            mark.chainID
        }
    }

    var recordedAt: Date {
        switch self {
        case .proof(let mark):
            mark.recordedAt
        case .hold(let mark):
            mark.recordedAt
        case .snap(let mark):
            mark.recordedAt
        case .swage(let mark):
            mark.recordedAt
        }
    }
}

extension Mark: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case payload
    }

    private enum Kind: String, Codable {
        case proof
        case hold
        case snap
        case swage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .proof(let mark):
            try container.encode(Kind.proof, forKey: .kind)
            try container.encode(mark, forKey: .payload)
        case .hold(let mark):
            try container.encode(Kind.hold, forKey: .kind)
            try container.encode(mark, forKey: .payload)
        case .snap(let mark):
            try container.encode(Kind.snap, forKey: .kind)
            try container.encode(mark, forKey: .payload)
        case .swage(let mark):
            try container.encode(Kind.swage, forKey: .kind)
            try container.encode(mark, forKey: .payload)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .proof:
            self = .proof(try container.decode(ProofMark.self, forKey: .payload))
        case .hold:
            self = .hold(try container.decode(HoldMark.self, forKey: .payload))
        case .snap:
            self = .snap(try container.decode(SnapMark.self, forKey: .payload))
        case .swage:
            self = .swage(try container.decode(SwageMark.self, forKey: .payload))
        }
    }
}
