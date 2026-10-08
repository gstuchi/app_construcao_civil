import XCTest

final class AberturaUITests: XCTestCase {
    @MainActor func testAppAbre() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["abertura"].waitForExistence(timeout: 10))
    }
}
