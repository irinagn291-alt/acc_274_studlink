import Foundation

/// Presentation reads the book through the store. No UserDefaults in views.
extension ChainStore {
    func focusedChain(now: Date = Date()) -> Chain? {
        let today = DayKey(now)
        return book.chains.first(where: { $0.cardDayKey == today }) ?? book.liveChain
    }

    func focusedCard(now: Date = Date()) -> Card? {
        if let chain = focusedChain(now: now) {
            return book.card(dayKey: chain.cardDayKey)
        }
        return book.cards.first
    }

    func addFixture(_ fixture: Fixture, dayKey: DayKey) {
        var card = book.card(dayKey: dayKey) ?? Card(dayKey: dayKey, fixtures: [])
        card.fixtures.append(fixture)
        _ = openChain(for: card)
    }

    func settleOpenPrefix(results: [UUID: Outcome], chainID: UUID, now: Date = Date()) -> FoldResult {
        guard let chain = book.chain(id: chainID) else {
            return .unchanged(.bare, slack: .empty)
        }
        var filtered: [UUID: Outcome] = [:]
        var addedOpen = false
        for link in chain.links {
            if link.settle == .hold {
                filtered[link.fixture.id] = link.outcome
                continue
            }
            if link.settle == .snap || link.settle == .voided {
                break
            }
            if let typed = results[link.fixture.id] {
                filtered[link.fixture.id] = typed
                addedOpen = true
            } else {
                break
            }
        }
        guard addedOpen else {
            return .unchanged(chain.proof)
        }
        return apply(.settle(results: filtered), now: now, chainID: chainID)
    }
}
