import Algorithms
import Collections
import Foundation

/// Bare | Made | Proved | Parted. The single fold every verb goes through.
enum ChainFold {
    /// Architecture entry: `ChainFold.reduce(state:event:)` over the Proof ADT.
    static func reduce(state: Proof, event: ChainEvent, context: FoldContext) -> FoldResult {
        switch event {
        case .shackle(let shackle):
            return shackleLink(state: state, shackle: shackle)
        case .swage(let swage):
            return swageLink(state: state, swage: swage, context: context)
        case .proof:
            return prove(state: state, context: context)
        case .settle(let results):
            return settle(state: state, results: results, context: context)
        }
    }

    private static func shackleLink(state: Proof, shackle: Shackle) -> FoldResult {
        switch state {
        case .bare, .made:
            break
        case .proved, .parted:
            return .unchanged(state, refusal: .frozen)
        }

        let fixture = shackle.fixture
        guard fixture.hasNamedSides else {
            return .unchanged(state, refusal: .blankSides)
        }

        let claimed = OrderedSet(state.links.map(\.fixture.id))
        guard !claimed.contains(fixture.id) else {
            return .unchanged(state, refusal: .fixtureAlreadyLinked)
        }

        let link = Link(fixture: fixture, outcome: shackle.outcome)
        let links = state.links + [link]
        return FoldResult(state: .made(links: links), marks: [], slack: nil, refusal: nil)
    }

    private static func swageLink(state: Proof, swage: Swage, context: FoldContext) -> FoldResult {
        switch state {
        case .bare:
            return .unchanged(state, slack: .empty)
        case .made(let links):
            guard context.swageCount == 0 else {
                return .unchanged(state, refusal: .secondSwage)
            }
            guard let index = links.firstIndex(where: { $0.id == swage.linkID }) else {
                return .unchanged(state, refusal: .missingLink)
            }
            let current = links[index]
            guard context.now < current.fixture.kickoff else {
                return .unchanged(state, refusal: .kickoffPassed)
            }
            var next = links
            next[index] = current.replacing(outcome: swage.outcome)
            let mark = Mark.swage(
                SwageMark(
                    id: UUID(),
                    chainID: context.chainID,
                    linkID: current.id,
                    fixtureID: current.fixture.id,
                    from: current.outcome,
                    to: swage.outcome,
                    recordedAt: context.now
                )
            )
            return FoldResult(state: .made(links: next), marks: [mark], slack: nil, refusal: nil)
        case .proved, .parted:
            return .unchanged(state, refusal: .frozen)
        }
    }

    private static func prove(state: Proof, context: FoldContext) -> FoldResult {
        switch state {
        case .bare:
            return .unchanged(state, slack: .empty)
        case .made(let links):
            guard links.count >= 2 else {
                return .unchanged(state, refusal: .underTwoLinks)
            }
            let load = ProofLoad(linkCount: links.count)
            let mark = Mark.proof(
                ProofMark(
                    id: UUID(),
                    chainID: context.chainID,
                    dayKey: context.dayKey,
                    linkCount: links.count,
                    load: load.points,
                    recordedAt: context.now
                )
            )
            return FoldResult(
                state: .proved(links: links, load: load),
                marks: [mark],
                slack: nil,
                refusal: nil
            )
        case .proved, .parted:
            return .unchanged(state, refusal: .frozen)
        }
    }

    private static func settle(
        state: Proof,
        results: [UUID: Outcome],
        context: FoldContext
    ) -> FoldResult {
        switch state {
        case .bare:
            return .unchanged(state, slack: .empty)
        case .made:
            return .unchanged(state, refusal: .notProved)
        case .parted:
            return .unchanged(state, refusal: .frozen)
        case .proved(let links, let load):
            return settleProved(links: links, load: load, results: results, context: context)
        }
    }

    private static func settleProved(
        links: [Link],
        load: ProofLoad,
        results: [UUID: Outcome],
        context: FoldContext
    ) -> FoldResult {
        let decided = Array(links.prefix(while: { results[$0.fixture.id] != nil }))
        var working = links
        var marks: [Mark] = []

        for (index, link) in decided.indexed() {
            guard let typed = results[link.fixture.id] else {
                break
            }
            if typed == link.outcome {
                working[index] = link.withSettle(.hold)
                marks.append(
                    .hold(
                        HoldMark(
                            id: UUID(),
                            chainID: context.chainID,
                            linkID: link.id,
                            fixtureID: link.fixture.id,
                            homeSide: link.fixture.homeSide,
                            awaySide: link.fixture.awaySide,
                            outcome: link.outcome,
                            index: index,
                            recordedAt: context.now
                        )
                    )
                )
            } else {
                working[index] = link.withSettle(.snap)
                if index + 1 < working.count {
                    for later in (index + 1)..<working.count {
                        working[later] = working[later].withSettle(.voided)
                    }
                }
                marks.append(
                    .snap(
                        SnapMark(
                            id: UUID(),
                            chainID: context.chainID,
                            linkID: link.id,
                            fixtureID: link.fixture.id,
                            homeSide: link.fixture.homeSide,
                            awaySide: link.fixture.awaySide,
                            picked: link.outcome,
                            result: typed,
                            partIndex: index,
                            recordedAt: context.now
                        )
                    )
                )
                return FoldResult(
                    state: .parted(links: working, atIndex: index),
                    marks: marks,
                    slack: nil,
                    refusal: nil
                )
            }
        }

        return FoldResult(
            state: .proved(links: working, load: load),
            marks: marks,
            slack: nil,
            refusal: nil
        )
    }
}
