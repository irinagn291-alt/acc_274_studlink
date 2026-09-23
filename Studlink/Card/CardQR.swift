import Foundation

/// Wire DTO for a Card QR payload. Mirrors the compact JSON, then maps to Card.
struct CardWire: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var dayKey: Int
    var fixtures: [FixtureWire]
}

struct FixtureWire: Codable, Sendable, Equatable {
    var id: String
    var kickoff: TimeInterval
    var homeSide: String
    var awaySide: String
}

enum CardQRError: Error, Equatable, Sendable {
    case decode
    case empty
    case invalidFixture
}

/// Local Card interchange. Two phones share a fixture list with no server.
enum CardQR {
    static func payload(for card: Card) throws -> Data {
        guard !card.fixtures.isEmpty else { throw CardQRError.empty }
        let wire = CardWire(
            schemaVersion: 1,
            dayKey: card.dayKey.rawValue,
            fixtures: card.fixtures.map { fixture in
                FixtureWire(
                    id: fixture.id.uuidString,
                    kickoff: fixture.kickoff.timeIntervalSince1970,
                    homeSide: fixture.homeSide,
                    awaySide: fixture.awaySide
                )
            }
        )
        return try ChainBookCodec.encoder().encode(wire)
    }

    static func card(from payload: Data) throws -> Card {
        let wire: CardWire
        do {
            wire = try ChainBookCodec.decoder().decode(CardWire.self, from: payload)
        } catch {
            throw CardQRError.decode
        }
        guard !wire.fixtures.isEmpty else { throw CardQRError.empty }
        var fixtures: [Fixture] = []
        fixtures.reserveCapacity(wire.fixtures.count)
        for item in wire.fixtures {
            guard let id = UUID(uuidString: item.id), !item.homeSide.isEmpty, !item.awaySide.isEmpty else {
                throw CardQRError.invalidFixture
            }
            fixtures.append(
                Fixture(
                    id: id,
                    kickoff: Date(timeIntervalSince1970: item.kickoff),
                    homeSide: item.homeSide,
                    awaySide: item.awaySide
                )
            )
        }
        return Card(dayKey: DayKey(rawValue: wire.dayKey), fixtures: fixtures)
    }
}
