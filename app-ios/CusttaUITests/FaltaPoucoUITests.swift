import XCTest

final class FaltaPoucoUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// "Falta pouco" no topo do cartão, antes do texto, como no site e no mockup.
    @MainActor private func conferirTitulo(_ app: XCUIApplication) {
        let titulo = app.staticTexts["Falta pouco"]
        XCTAssertTrue(titulo.exists, "o título do cartão, como no site e no mockup")
        XCTAssertLessThanOrEqual(titulo.frame.maxY, app.staticTexts["textoFaltaPouco"].frame.minY, "o título vem antes do texto")
    }

    @MainActor func testContaAppleSoPedeAOrigem() {
        let app = abrirApp(conta: "apple-sem-perfil")
        XCTAssertTrue(app.staticTexts["Só falta contar como você conheceu o Custta."].waitForExistence(timeout: 10))
        conferirTitulo(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Você entrou com a Apple.")).firstMatch.exists)
        XCTAssertFalse(app.textFields["nome"].exists, "a revisão da Apple reprova pedir o nome de novo")
        app.buttons["origem"].tap()
        app.buttons["Instagram"].tap()
        app.buttons["comecarAUsar"].tap()
        XCTAssertTrue(app.elemento("obra-o3").waitForExistence(timeout: 10))
    }

    @MainActor func testContaGoogleConfirmaONome() {
        let app = abrirApp(conta: "google-sem-perfil")
        XCTAssertTrue(app.staticTexts["Confirme seu nome e conte como conheceu o Custta."].waitForExistence(timeout: 10))
        conferirTitulo(app)
        XCTAssertEqual(app.textFields["nome"].value as? String, "Giovani")
        let conta = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Você entrou com o Google")).firstMatch
        XCTAssertTrue(conta.exists && conta.label.contains("giovani@gmail.com"), "a conta Google com o e-mail")
        app.buttons["comecarAUsar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemFaltaPouco"].label, "Conte como conheceu o Custta.")
    }

    /// "Usar outra conta" sai pelo ModeloApp.sair: volta para entrar sem o aviso de sessão expirada.
    @MainActor func testUsarOutraContaVoltaParaEntrar() {
        let app = abrirApp(conta: "apple-sem-perfil")
        let outra = app.buttons["usarOutraConta"]
        XCTAssertTrue(outra.waitForExistence(timeout: 10))
        outra.tap()
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10), "voltou para a tela de entrar")
        XCTAssertFalse(app.staticTexts["mensagemEntrada"].exists, "trocar de conta não é sessão expirada")
    }
}
