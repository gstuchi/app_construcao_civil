import XCTest

final class AjustesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirAjustes(rede: String? = nil) -> XCUIApplication {
        let app = abrirApp(conta: "senha", rede: rede)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testContaESair() {
        let app = abrirAjustes()
        XCTAssertTrue(app.staticTexts["nomeConta"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["nomeConta"].label, "Giovani Stuchi")
        XCTAssertEqual(app.staticTexts["emailConta"].value as? String, "giovani@exemplo.com")
        XCTAssertEqual(app.staticTexts["versao"].label, "Versão 2.0 (1)")
        XCTAssertEqual(app.buttons["sair"].frame.height, 52, accuracy: 0.5, "botão cheio do mockup")
        app.buttons["sair"].tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5), "confirmação pelo alerta do sistema")
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10), "voltou para a tela de entrar")
    }

    @MainActor func testSairSemInternetPedeParaConectar() {
        let app = abrirAjustes(rede: "offline")
        app.buttons["sair"].tap()
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.alerts["Conecte à internet e aguarde a sincronização antes de sair."].waitForExistence(timeout: 10))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["sair"].exists, "continua em Ajustes")
    }

    @MainActor func testSairDoTopoPedeConfirmacaoECancelarFica() {
        let app = abrirApp(conta: "senha")
        let topo = app.buttons["sairTopo"]
        XCTAssertTrue(topo.waitForExistence(timeout: 10))
        topo.tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5), "continua em Obras")
    }

    @MainActor func testCapsulaDeAbasTrocaETemNomeEPosicao() {
        let app = abrirApp(conta: "senha")
        let obras = app.buttons["aba-obras"], ajustes = app.buttons["aba-ajustes"]
        XCTAssertTrue(obras.waitForExistence(timeout: 10))
        XCTAssertTrue(obras.isSelected)
        XCTAssertEqual(obras.label, "Obras")
        XCTAssertEqual(ajustes.value as? String, "2 de 2")
        ajustes.tap()
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        XCTAssertTrue(ajustes.isSelected)
        XCTAssertFalse(app.elemento("obra-o1").exists, "só a aba escolhida fica na tela (e no VoiceOver)")
        obras.tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5))
    }

    /// A cápsula fica 22 pt acima da borda, como a barra de abas do sistema (mockup aprovado), nas duas abas.
    /// Ela tem 4 pt de margem em volta das abas.
    @MainActor func testCapsulaFica22PontosAcimaDaBorda() {
        let app = abrirApp(conta: "senha")
        let obras = app.buttons["aba-obras"]
        XCTAssertTrue(obras.waitForExistence(timeout: 10))
        let base = app.windows.firstMatch.frame.maxY
        XCTAssertEqual(obras.frame.maxY + 4, base - 22, accuracy: 1)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["aba-ajustes"].frame.maxY + 4, base - 22, accuracy: 1)
    }
}
