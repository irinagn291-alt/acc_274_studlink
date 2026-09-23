import Foundation
import Observation

/// Actor-isolated seam. UI never touches UserDefaults or the file.
@MainActor
@Observable
final class ChainStore {
    private(set) var book: ChainBook
    private(set) var lastPersistError: String?

    private let defaults: UserDefaults
    private let disk: ChainBookDisk
    private var persistTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, directory: URL? = nil) {
        self.defaults = defaults
        let folder = directory ?? Self.defaultDirectory()
        disk = ChainBookDisk(directory: folder)
        book = .empty
    }

    func bootstrap(plantDemo: Bool = true) async {
        if let data = defaults.data(forKey: ChainBook.rootKey), let loaded = ChainBookCodec.decode(data) {
            book = loaded
        } else if let loaded = await disk.load() {
            book = loaded
        } else {
            book = .empty
        }
        #if targetEnvironment(simulator)
        if plantDemo {
            plantDemoIfNeeded()
        }
        #endif
    }

    /// Applies the fold to memory first, then debounces encode by 400ms.
    @discardableResult
    func apply(_ event: ChainEvent, now: Date, chainID: UUID) -> FoldResult {
        guard var chain = book.chain(id: chainID) else {
            return .unchanged(.bare, slack: .empty)
        }
        let context = FoldContext(
            chainID: chain.id,
            dayKey: chain.cardDayKey,
            now: now,
            swageCount: MarkLedger.swageCount(in: book.marks, chainID: chain.id)
        )
        let result = ChainFold.reduce(state: chain.proof, event: event, context: context)
        guard result.accepted else {
            return result
        }
        chain.proof = result.state
        book.replace(chain)
        book.marks.append(contentsOf: result.marks)
        schedulePersist()
        return result
    }

    func openChain(for card: Card) -> UUID {
        book.upsert(card)
        if let existing = book.chains.first(where: { $0.cardDayKey == card.dayKey }) {
            return existing.id
        }
        let chain = Chain(cardDayKey: card.dayKey, proof: .bare)
        book.chains.append(chain)
        schedulePersist()
        return chain.id
    }

    func importCard(_ card: Card) {
        _ = openChain(for: card)
    }

    func openFixtures(on chain: Chain) -> [Fixture] {
        guard let card = book.card(dayKey: chain.cardDayKey) else { return [] }
        let taken = Set(chain.links.map(\.fixture.id))
        return card.fixtures.filter { !taken.contains($0.id) }
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        let snapshot = book
        do {
            let data = try await disk.save(snapshot)
            defaults.set(data, forKey: ChainBook.rootKey)
            lastPersistError = nil
        } catch {
            lastPersistError = String(describing: error)
        }
    }

    func resetAllData() async {
        persistTask?.cancel()
        persistTask = nil
        book = .empty
        lastPersistError = nil
        defaults.removeObject(forKey: ChainBook.rootKey)
        do {
            try await disk.reset()
        } catch {
            lastPersistError = String(describing: error)
        }
    }

    func handleScenePhaseLeavingActive() async {
        await flush()
    }

    #if targetEnvironment(simulator)
    func plantDemoIfNeeded(now: Date = Date()) {
        let hasPrimarySurface = !book.cards.isEmpty && !book.chains.isEmpty
        let seededVersion = defaults.string(forKey: DemoSeed.key)
        let needsSeed = !hasPrimarySurface || seededVersion != DemoSeed.version
        if needsSeed {
            // Keep simulator covers non-blank, and allow deterministic reseeds per seed version.
            book = DemoSeed.makeBook(now: now)
            schedulePersist()
        }
        defaults.set(DemoSeed.version, forKey: DemoSeed.key)
        defaults.set(true, forKey: DemoSeed.onboardingKey)
    }
    #endif

    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    private static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Studlink", isDirectory: true)
    }
}
