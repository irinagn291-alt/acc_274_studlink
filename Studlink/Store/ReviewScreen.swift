import Foundation

/// Launch keys, not tabs. Read once from ProcessInfo after onboarding.
enum ReviewScreen: String, Sendable, CaseIterable, Equatable {
    case today
    case log
    case goals
    case chain
    case canvas
    case fixtures
    case proofhouse
    case season
    case settings

    static func parseLaunchArgument() -> ReviewScreen? {
        parse(arguments: ProcessInfo.processInfo.arguments)
    }

    static func parse(arguments: [String]) -> ReviewScreen? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: flag)
        guard next < arguments.endIndex else { return nil }

        switch arguments[next].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case today.rawValue:
            return .today
        case log.rawValue:
            return .log
        case goals.rawValue:
            return .goals
        case chain.rawValue:
            return .chain
        case canvas.rawValue:
            return .canvas
        case fixtures.rawValue:
            return .fixtures
        case proofhouse.rawValue:
            return .proofhouse
        case season.rawValue:
            return .season
        case settings.rawValue:
            return .settings
        default:
            return nil
        }
    }
}
