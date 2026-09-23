import Foundation

/// Home, Draw, or Away. The only pick a Link may carry.
enum Outcome: String, Codable, Sendable, CaseIterable, Equatable {
    case home
    case draw
    case away
}
