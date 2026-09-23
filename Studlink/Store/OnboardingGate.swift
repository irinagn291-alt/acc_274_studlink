import Foundation

/// Versioned onboarding flag. Seed writes the same key on Simulator.
enum OnboardingGate {
    static func isComplete(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: DemoSeed.onboardingKey)
    }

    static func markComplete(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: DemoSeed.onboardingKey)
    }

    static func reopen(defaults: UserDefaults = .standard) {
        defaults.set(false, forKey: DemoSeed.onboardingKey)
    }
}
