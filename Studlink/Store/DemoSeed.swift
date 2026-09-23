import Foundation

/// Simulator-only product seed. Never planted on a device.
enum DemoSeed {
    static let key = "sdl.demo.version"
    static let version = "sdl.demo.v4"
    static let onboardingKey = "sdl.onboarding.v1"

    /// One Card of six fixtures, a three-link made chain, plus two settled chains.
    static func makeBook(now: Date, calendar: Calendar = .current) -> ChainBook {
        let liveDay = DayKey(now, calendar: calendar)
        let wholeDay = DayKey(now.addingTimeInterval(-14 * 24 * 60 * 60), calendar: calendar)
        let partedDay = DayKey(now.addingTimeInterval(-21 * 24 * 60 * 60), calendar: calendar)

        let kicks = sameDayKickoffs(now: now, count: 6, calendar: calendar)
        let liveCard = Card(
            dayKey: liveDay,
            fixtures: [
                fixture("Millbridge", "Oakford", kicks[0]),
                fixture("Redharbor", "Linmere", kicks[1]),
                fixture("Castlewick", "South Fen", kicks[2]),
                fixture("Dunlow", "Hartsfield", kicks[3]),
                fixture("Barrowmere", "Whitecliff", kicks[4]),
                fixture("Kenning", "Portavon", kicks[5]),
            ]
        )

        let wholeCard = Card(
            dayKey: wholeDay,
            fixtures: [
                fixture("Millbridge", "Oakford", now.addingTimeInterval(-20 * 24 * 60 * 60)),
                fixture("Redharbor", "Linmere", now.addingTimeInterval(-20 * 24 * 60 * 60 + 3600)),
                fixture("Castlewick", "South Fen", now.addingTimeInterval(-20 * 24 * 60 * 60 + 7200)),
            ]
        )

        let partedCard = Card(
            dayKey: partedDay,
            fixtures: [
                fixture("Millbridge", "Oakford", now.addingTimeInterval(-28 * 24 * 60 * 60)),
                fixture("Redharbor", "Linmere", now.addingTimeInterval(-28 * 24 * 60 * 60 + 3600)),
                fixture("Castlewick", "South Fen", now.addingTimeInterval(-28 * 24 * 60 * 60 + 7200)),
                fixture("Dunlow", "Hartsfield", now.addingTimeInterval(-28 * 24 * 60 * 60 + 10_800)),
                fixture("Barrowmere", "Whitecliff", now.addingTimeInterval(-28 * 24 * 60 * 60 + 14_400)),
            ]
        )

        var book = ChainBook.empty
        book.upsert(liveCard)
        book.upsert(wholeCard)
        book.upsert(partedCard)

        let live = play(
            card: liveCard,
            picks: [
                (liveCard.fixtures[0], .home),
                (liveCard.fixtures[1], .draw),
                (liveCard.fixtures[2], .away),
            ],
            prove: false,
            results: [:],
            now: now
        )
        book.chains.append(live.chain)
        book.marks.append(contentsOf: live.marks)

        let whole = play(
            card: wholeCard,
            picks: [
                (wholeCard.fixtures[0], .home),
                (wholeCard.fixtures[1], .home),
                (wholeCard.fixtures[2], .draw),
            ],
            prove: true,
            results: [
                wholeCard.fixtures[0].id: .home,
                wholeCard.fixtures[1].id: .home,
                wholeCard.fixtures[2].id: .draw,
            ],
            now: now
        )
        book.chains.append(whole.chain)
        book.marks.append(contentsOf: whole.marks)

        let parted = play(
            card: partedCard,
            picks: [
                (partedCard.fixtures[0], .away),
                (partedCard.fixtures[1], .home),
                (partedCard.fixtures[2], .draw),
                (partedCard.fixtures[3], .home),
                (partedCard.fixtures[4], .away),
            ],
            prove: true,
            results: [
                partedCard.fixtures[0].id: .away,
                partedCard.fixtures[1].id: .home,
                partedCard.fixtures[2].id: .draw,
                partedCard.fixtures[3].id: .away,
            ],
            now: now
        )
        book.chains.append(parted.chain)
        book.marks.append(contentsOf: parted.marks)

        return book
    }

    private static func fixture(_ home: String, _ away: String, _ kickoff: Date) -> Fixture {
        Fixture(kickoff: kickoff, homeSide: home, awaySide: away)
    }

    /// Kickoffs stay on the card day so a Today header never lists tomorrow.
    static func sameDayKickoffs(now: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: now)
        let next = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(86_400)
        let last = next.addingTimeInterval(-30)
        let earliest = now.addingTimeInterval(90)
        if earliest < last, count > 0 {
            let usable = last.timeIntervalSince(earliest)
            let step = count > 1 ? usable / TimeInterval(count - 1) : 0
            return (0..<count).map { earliest.addingTimeInterval(step * TimeInterval($0)) }
        }
        return (0..<count).map { offset in
            last.addingTimeInterval(TimeInterval(offset - (count - 1)) * 20)
        }
    }

    private static func play(
        card: Card,
        picks: [(Fixture, Outcome)],
        prove: Bool,
        results: [UUID: Outcome],
        now: Date
    ) -> (chain: Chain, marks: [Mark]) {
        var proof: Proof = .bare
        var marks: [Mark] = []
        let chainID = UUID()
        var context = FoldContext(chainID: chainID, dayKey: card.dayKey, now: now, swageCount: 0)

        for pick in picks {
            let result = ChainFold.reduce(
                state: proof,
                event: .shackle(Shackle(fixture: pick.0, outcome: pick.1)),
                context: context
            )
            proof = result.state
            marks.append(contentsOf: result.marks)
        }

        if prove {
            let proved = ChainFold.reduce(state: proof, event: .proof, context: context)
            proof = proved.state
            marks.append(contentsOf: proved.marks)
            if !results.isEmpty {
                context.swageCount = MarkLedger.swageCount(in: marks, chainID: chainID)
                let settled = ChainFold.reduce(
                    state: proof,
                    event: .settle(results: results),
                    context: context
                )
                proof = settled.state
                marks.append(contentsOf: settled.marks)
            }
        }

        return (Chain(id: chainID, cardDayKey: card.dayKey, proof: proof), marks)
    }
}
