import Foundation

/// The Proof ADT. Every verb folds one of these cases into the next.
enum Proof: Codable, Sendable, Equatable {
    case bare
    case made(links: [Link])
    case proved(links: [Link], load: ProofLoad)
    case parted(links: [Link], atIndex: Int)

    var links: [Link] {
        switch self {
        case .bare:
            []
        case .made(let links):
            links
        case .proved(let links, _):
            links
        case .parted(let links, _):
            links
        }
    }

    var isBare: Bool {
        if case .bare = self { return true }
        return false
    }

    var isMade: Bool {
        if case .made = self { return true }
        return false
    }

    var isProved: Bool {
        if case .proved = self { return true }
        return false
    }

    var isParted: Bool {
        if case .parted = self { return true }
        return false
    }

    /// Live head figure: n squared while made, fixed after Proof, zero after a Snap.
    var displayedLoad: Int {
        switch self {
        case .bare:
            0
        case .made(let links):
            ProofLoad(linkCount: links.count).points
        case .proved(_, let load):
            load.points
        case .parted:
            0
        }
    }
}

/// Points paid by a proved-whole chain: link count squared. Never money.
struct ProofLoad: Codable, Sendable, Equatable, Hashable {
    var points: Int

    init(linkCount: Int) {
        let count = max(0, linkCount)
        points = count * count
    }

    init(points: Int) {
        self.points = points
    }
}

/// One proving chain for one Card. Links live inside the Proof case.
struct Chain: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var cardDayKey: DayKey
    var proof: Proof

    init(id: UUID = UUID(), cardDayKey: DayKey, proof: Proof = .bare) {
        self.id = id
        self.cardDayKey = cardDayKey
        self.proof = proof
    }

    var links: [Link] { proof.links }

    var cachedLoad: ProofLoad? {
        if case .proved(_, let load) = proof {
            return load
        }
        return nil
    }
}

/// Shackle writes a Link from a tapped Fixture and outcome.
struct Shackle: Sendable, Equatable {
    var fixture: Fixture
    var outcome: Outcome
}

/// Swage replaces one unstarted Link. One SwageMark per chain.
struct Swage: Sendable, Equatable {
    var linkID: UUID
    var outcome: Outcome
}

/// The verbs the fold accepts. Clock and daykey stay outside.
enum ChainEvent: Sendable, Equatable {
    case shackle(Shackle)
    case swage(Swage)
    case proof
    case settle(results: [UUID: Outcome])
}

/// Clock, daykey, and SwageMark count. Passed in so the fold has no store.
struct FoldContext: Sendable, Equatable {
    var chainID: UUID
    var dayKey: DayKey
    var now: Date
    var swageCount: Int
}

/// Empty-chain signal. Not a state change.
struct Slack: Sendable, Equatable {
    var reason: String

    static let empty = Slack(reason: "empty")
}

/// Why a verb was refused. The canvas can render these.
enum FoldRefusal: String, Sendable, Equatable {
    case fixtureAlreadyLinked
    case secondSwage
    case kickoffPassed
    case frozen
    case underTwoLinks
    case notMade
    case notProved
    case blankSides
    case missingLink
}

/// Result of one fold step: next Proof, new marks, Slack or a refusal.
struct FoldResult: Sendable, Equatable {
    var state: Proof
    var marks: [Mark]
    var slack: Slack?
    var refusal: FoldRefusal?

    var accepted: Bool {
        slack == nil && refusal == nil
    }

    static func unchanged(_ state: Proof, slack: Slack? = nil, refusal: FoldRefusal? = nil) -> FoldResult {
        FoldResult(state: state, marks: [], slack: slack, refusal: refusal)
    }
}
