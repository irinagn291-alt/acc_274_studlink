import Foundation

/// Root document: Cards, Chains with embedded Links, and an append-only Marks array.
struct ChainBook: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var cards: [Card]
    var chains: [Chain]
    var marks: [Mark]

    static let currentSchema = 1
    static let rootKey = "sdl.chainbook.v1"
    static let empty = ChainBook(schemaVersion: currentSchema, cards: [], chains: [], marks: [])

    init(
        schemaVersion: Int = ChainBook.currentSchema,
        cards: [Card] = [],
        chains: [Chain] = [],
        marks: [Mark] = []
    ) {
        self.schemaVersion = schemaVersion
        self.cards = cards
        self.chains = chains
        self.marks = marks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        switch version {
        case 1:
            schemaVersion = 1
        default:
            schemaVersion = 1
        }
        cards = Self.decodeSkipping(container, key: .cards)
        chains = Self.decodeSkipping(container, key: .chains)
        marks = Self.decodeSkipping(container, key: .marks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(cards, forKey: .cards)
        try container.encode(chains, forKey: .chains)
        try container.encode(marks, forKey: .marks)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case cards
        case chains
        case marks
    }

    private static func decodeSkipping<T: Decodable>(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> [T] {
        guard let rows = try? container.decode([Failable<T>].self, forKey: key) else {
            return []
        }
        return rows.compactMap(\.value)
    }

    func chain(id: UUID) -> Chain? {
        chains.first(where: { $0.id == id })
    }

    func card(dayKey: DayKey) -> Card? {
        cards.first(where: { $0.dayKey == dayKey })
    }

    var liveChain: Chain? {
        chains.first(where: { $0.proof.isMade }) ?? chains.first
    }

    mutating func replace(_ chain: Chain) {
        if let index = chains.firstIndex(where: { $0.id == chain.id }) {
            chains[index] = chain
        } else {
            chains.append(chain)
        }
    }

    mutating func upsert(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.dayKey == card.dayKey }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
    }
}

/// Decodes one array element or skips it when the payload is unknown.
private struct Failable<T: Decodable>: Decodable {
    var value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

enum ChainBookCodec {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    static func decode(_ data: Data) -> ChainBook? {
        try? decoder().decode(ChainBook.self, from: data)
    }
}
