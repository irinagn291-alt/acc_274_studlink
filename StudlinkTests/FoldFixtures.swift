import Foundation
@testable import Studlink

enum FoldFixtures {
    static let now = Date(timeIntervalSince1970: 1_700_000_000)

    static func fixture(
        _ home: String,
        _ away: String,
        kickoff: Date = now.addingTimeInterval(3_600),
        id: UUID = UUID()
    ) -> Fixture {
        Fixture(id: id, kickoff: kickoff, homeSide: home, awaySide: away)
    }

    static func context(
        chainID: UUID = UUID(),
        dayKey: DayKey = DayKey(rawValue: 20_240_101),
        now: Date = now,
        swageCount: Int = 0
    ) -> FoldContext {
        FoldContext(chainID: chainID, dayKey: dayKey, now: now, swageCount: swageCount)
    }

    static func make(
        links fixtures: [(Fixture, Outcome)],
        then event: ChainEvent? = nil,
        swageCount: Int = 0,
        now: Date = now
    ) -> FoldResult {
        var state: Proof = .bare
        let ctx = context(now: now, swageCount: swageCount)
        for pair in fixtures {
            let result = ChainFold.reduce(
                state: state,
                event: .shackle(Shackle(fixture: pair.0, outcome: pair.1)),
                context: ctx
            )
            state = result.state
        }
        guard let event else {
            return FoldResult(state: state, marks: [], slack: nil, refusal: nil)
        }
        return ChainFold.reduce(state: state, event: event, context: ctx)
    }
}
