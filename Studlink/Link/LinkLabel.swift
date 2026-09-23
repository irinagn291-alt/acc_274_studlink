import Foundation

/// Spoken and drawn words for a Link. Colour is never the only signal.
enum LinkLabel {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func spoken(link: Link, index: Int) -> String {
        let number = whole.string(from: NSNumber(value: index + 1)) ?? "\(index + 1)"
        let pair = "\(link.fixture.trimmedHome) versus \(link.fixture.trimmedAway)"
        return "Link \(number), \(pair), \(outcomeWord(link.outcome)), \(settleWord(link.settle))"
    }

    static func pair(_ fixture: Fixture) -> String {
        "\(fixture.trimmedHome) v \(fixture.trimmedAway)"
    }

    static func picksStatus(isLocked: Bool) -> String {
        isLocked ? "Picks locked" : "Picks made"
    }

    static func chainStatus(picked: Int, total: Int, load: Int) -> String {
        "\(count(picked)) of \(count(total)) picked - \(count(load)) points if the chain holds"
    }

    static func unstartedHint(count value: Int) -> String {
        if value == 1 {
            return "1 unstarted pick can still be changed before proof"
        }
        return "\(count(value)) unstarted picks can still be changed before proof"
    }

    static func settleSummary(linked: Int, open: Int) -> String {
        "\(count(linked)) linked picks and \(count(open)) open slots"
    }

    static func payoutHeading() -> String {
        "This week's payout"
    }

    static func proveAction(locked: Bool) -> String {
        locked ? "Chain locked" : "Prove chain"
    }

    static func addNextPick() -> String {
        "Add the next pick"
    }

    static func addNextPickLine(remaining: Int, locked: Bool) -> String {
        if locked {
            return "This chain takes no more picks"
        }
        if remaining == 0 {
            return "Every fixture is already on the chain"
        }
        if remaining == 1 {
            return "1 fixture still open this week"
        }
        return "\(count(remaining)) fixtures still open this week"
    }

    static func stillOpenHeading() -> String {
        "Still open this week"
    }

    static func pickThisFixture() -> String {
        "Tap to pick Home, Draw, or Away"
    }

    static func changeLeft(available: Bool) -> String {
        available
            ? "You can still change one pick before you lock the chain"
            : "The one pick change on this chain is used"
    }

    static func linksOnChainHeading() -> String {
        "Links on this chain"
    }

    static func fixtureRateLabel(appearances: Int, hitRate: Double) -> String {
        if appearances == 0 {
            return "No result yet"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: hitRate)) ?? "0%"
    }

    private static func count(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func fixturesSectionTitle(cardDay: DayKey, now: Date, kickoffs: [Date], calendar: Calendar = .current) -> String {
        let today = DayKey(now, calendar: calendar)
        let allOnCardDay = kickoffs.allSatisfy { DayKey($0, calendar: calendar) == cardDay }
        if cardDay == today && allOnCardDay {
            return "Today's fixtures"
        }
        return "Fixtures on this card"
    }

    static func outcomeWord(_ outcome: Outcome) -> String {
        switch outcome {
        case .home:
            "Home"
        case .draw:
            "Draw"
        case .away:
            "Away"
        }
    }

    static func settleWord(_ settle: LinkSettle) -> String {
        switch settle {
        case .open:
            "open"
        case .hold:
            "holds"
        case .snap:
            "parts"
        case .voided:
            "void"
        }
    }

    static func settleMark(_ settle: LinkSettle) -> String {
        switch settle {
        case .open:
            "OPEN"
        case .hold:
            "HOLD"
        case .snap:
            "SNAP"
        case .voided:
            "VOID"
        }
    }

    static func refusal(_ reason: FoldRefusal) -> String {
        switch reason {
        case .fixtureAlreadyLinked:
            "That fixture is already on the chain."
        case .secondSwage:
            "This chain already used its one swage."
        case .kickoffPassed:
            "Kickoff has passed. This link cannot be swaged."
        case .frozen:
            "This chain is proved. No more links or swages."
        case .underTwoLinks:
            "Proof needs at least two links."
        case .notMade:
            "Forge a link before you prove."
        case .notProved:
            "Prove the chain before you settle."
        case .blankSides:
            "Both sides need a name."
        case .missingLink:
            "That link is not on this chain."
        }
    }
}
