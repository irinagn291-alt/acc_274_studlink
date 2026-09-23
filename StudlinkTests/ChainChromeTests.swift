import XCTest
@testable import Studlink

@MainActor
final class ChainChromeTests: XCTestCase {
    func test_applyLaunchReviewReadsArgumentsOnceAfterOnboardingCompletes() {
        withOnboardingComplete(false) {
            var readCount = 0
            let chrome = ChainChrome(launchArguments: {
                readCount += 1
                return ["-ReviewScreen", "log"]
            })

            chrome.applyLaunchReview()
            XCTAssertEqual(readCount, 0)
            XCTAssertNil(chrome.sheet)

            OnboardingGate.markComplete()
            chrome.applyLaunchReview()
            XCTAssertEqual(readCount, 1)
            XCTAssertEqual(chrome.sheet, .fixtures)
            XCTAssertEqual(chrome.fixturesLane, .settle)

            chrome.applyLaunchReview()
            XCTAssertEqual(readCount, 1)
        }
    }

    func test_applyLaunchReviewRoutesCoreAndExtraKeys() {
        withOnboardingComplete(true) {
            assertRoute(["-ReviewScreen", "today"], sheet: nil)
            assertRoute(["-ReviewScreen", "log"], sheet: .fixtures, lane: .settle)
            assertRoute(["-ReviewScreen", "goals"], sheet: .season)

            assertRoute(["-ReviewScreen", "chain"], sheet: nil)
            assertRoute(["-ReviewScreen", "canvas"], sheet: nil)
            assertRoute(["-ReviewScreen", "fixtures"], sheet: .fixtures)
            assertRoute(["-ReviewScreen", "proofhouse"], sheet: .proofHouse)
            assertRoute(["-ReviewScreen", "season"], sheet: .season)
            assertRoute(["-ReviewScreen", "settings"], sheet: .settings)

            assertRoute(["-ReviewScreen", "unknown"], sheet: nil)
        }
    }

    private func assertRoute(
        _ arguments: [String],
        sheet expectedSheet: BoardSheet?,
        lane expectedLane: FixturesLane = .card,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let chrome = ChainChrome(launchArguments: { arguments })
        chrome.applyLaunchReview()
        XCTAssertEqual(chrome.sheet, expectedSheet, file: file, line: line)
        XCTAssertEqual(chrome.fixturesLane, expectedLane, file: file, line: line)
    }

    private func withOnboardingComplete(_ complete: Bool, run: () -> Void) {
        let defaults = UserDefaults.standard
        let key = DemoSeed.onboardingKey
        let previous = defaults.object(forKey: key)
        defaults.set(complete, forKey: key)
        defer {
            if let previous {
                defaults.set(previous, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        run()
    }
}
