import XCTest

final class AberturaUITests: XCTestCase {
    @MainActor func testAppAbre() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["abertura"].waitForExistence(timeout: 10))
    }
}
