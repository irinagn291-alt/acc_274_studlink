import XCTest
@testable import Studlink

@MainActor
final class ChainStoreTests: XCTestCase {
    func test_roundTrip_writeReload() async throws {
        let harness = try makeHarness()
        defer { harness.tearDown() }

        let card = Card(
            dayKey: DayKey(rawValue: 20_260_411),
            fixtures: [
                FoldFixtures.fixture("Millbridge", "Oakford"),
                FoldFixtures.fixture("Redharbor", "Linmere"),
                FoldFixtures.fixture("Castlewick", "South Fen"),
            ]
        )
        await harness.store.bootstrap(plantDemo: false)
        let chainID = harness.store.openChain(for: card)
        _ = harness.store.apply(
            .shackle(Shackle(fixture: card.fixtures[0], outcome: .home)),
            now: FoldFixtures.now,
            chainID: chainID
        )
        _ = harness.store.apply(
            .shackle(Shackle(fixture: card.fixtures[1], outcome: .draw)),
            now: FoldFixtures.now,
            chainID: chainID
        )
        _ = harness.store.apply(.proof, now: FoldFixtures.now, chainID: chainID)
        await harness.store.flush()

        let reloaded = ChainStore(defaults: harness.defaults, directory: harness.directory)
        await reloaded.bootstrap(plantDemo: false)
        XCTAssertEqual(reloaded.book.cards.count, 1)
        XCTAssertEqual(reloaded.book.chains.count, 1)
        XCTAssertTrue(reloaded.book.chains[0].proof.isProved)
        XCTAssertEqual(reloaded.book.chains[0].cachedLoad?.points, 4)
        XCTAssertEqual(reloaded.book.marks.count, 1)
    }

    func test_corruptRootFallsBackToEmpty() async throws {
        let harness = try makeHarness()
        defer { harness.tearDown() }
        harness.defaults.set(Data("not-json".utf8), forKey: ChainBook.rootKey)
        try Data("also-bad".utf8).write(to: harness.directory.appendingPathComponent(ChainBookDisk.fileName))
        await harness.store.bootstrap(plantDemo: false)
        XCTAssertEqual(harness.store.book, .empty)
    }

    func test_resetAllData_clearsMemoryAndDisk() async throws {
        let harness = try makeHarness()
        defer { harness.tearDown() }
        await harness.store.bootstrap(plantDemo: false)
        let card = Card(dayKey: DayKey(rawValue: 20_260_501), fixtures: [FoldFixtures.fixture("A", "B")])
        _ = harness.store.openChain(for: card)
        await harness.store.flush()
        await harness.store.resetAllData()
        XCTAssertEqual(harness.store.book, .empty)
        XCTAssertNil(harness.defaults.data(forKey: ChainBook.rootKey))

        let again = ChainStore(defaults: harness.defaults, directory: harness.directory)
        await again.bootstrap(plantDemo: false)
        XCTAssertEqual(again.book, .empty)
    }

    func test_demoSeed_seatsLiveChainAndHouse() {
        let book = DemoSeed.makeBook(now: FoldFixtures.now)
        XCTAssertEqual(book.cards.count, 3)
        let live = book.liveChain
        XCTAssertTrue(live?.proof.isMade ?? false)
        XCTAssertEqual(live?.links.count, 3)
        XCTAssertEqual(MarkLedger.swageCount(in: book.marks, chainID: live?.id ?? UUID()), 0)
        XCTAssertEqual(ProofHouse.rebuild(from: book.marks).count, 2)
        if let live, let card = book.card(dayKey: live.cardDayKey) {
            let open = card.fixtures.filter { fixture in
                !live.links.contains(where: { $0.fixture.id == fixture.id })
            }
            XCTAssertEqual(open.count, 3)
            for fixture in card.fixtures {
                XCTAssertEqual(DayKey(fixture.kickoff), card.dayKey)
                XCTAssertGreaterThan(fixture.kickoff, FoldFixtures.now)
            }
        } else {
            XCTFail("live card")
        }
    }

    private struct Harness {
        var store: ChainStore
        var defaults: UserDefaults
        var directory: URL
        var suiteName: String

        func tearDown() {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }
    }

    private func makeHarness() throws -> Harness {
        let suite = "sdl.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("studlink-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ChainStore(defaults: defaults, directory: directory)
        return Harness(store: store, defaults: defaults, directory: directory, suiteName: suite)
    }
}
