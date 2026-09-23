import XCTest
@testable import Studlink

final class StudlinkTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: StudlinkApp.self), "StudlinkApp")
    }
}
