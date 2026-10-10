import XCTest

final class FaltaPoucoUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testContaAppleSoPedeAOrigem() {
        let app = abrirApp(conta: "apple-sem-perfil")
        XCTAssertTrue(app.staticTexts["Só falta contar como você conheceu o Custta."].waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["nome"].exists, "a revisão da Apple reprova pedir o nome de novo")
        app.buttons["origem"].tap()
        app.buttons["Instagram"].tap()
        app.buttons["comecarAUsar"].tap()
        XCTAssertTrue(app.elemento("obra-o3").waitForExistence(timeout: 10))
    }

    @MainActor func testContaGoogleConfirmaONome() {
        let app = abrirApp(conta: "google-sem-perfil")
        XCTAssertTrue(app.staticTexts["Confirme seu nome e conte como conheceu o Custta."].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["nome"].value as? String, "Giovani")
        app.buttons["comecarAUsar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemFaltaPouco"].label, "Conte como conheceu o Custta.")
    }
}
