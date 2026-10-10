import XCTest

final class CriarContaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirCriarConta() -> XCUIApplication {
        let app = abrirApp()
        let link = app.buttons["irParaCriarConta"]
        XCTAssertTrue(link.waitForExistence(timeout: 10))
        link.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testChecklistDaSenhaAcompanhaADigitacao() {
        let app = abrirCriarConta()
        app.swipeUp()               // com os botões de 52 pt do mockup, o checklist começa abaixo da dobra
        let tamanho = app.staticTexts["8 caracteres ou mais: falta"]
        XCTAssertTrue(tamanho.waitForExistence(timeout: 5))
        app.digitar("Casa2026x", em: "senhaCadastro", seguro: true)
        XCTAssertTrue(app.staticTexts["8 caracteres ou mais: ok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Um número: ok"].exists)
    }

    @MainActor func testValidacaoNaOrdemDoSiteECriacao() {
        let app = abrirCriarConta()
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "Digite seu nome.")
        app.digitar("Giovani", em: "nome")
        app.digitar("novo@exemplo.com", em: "emailCadastro")
        app.digitar("Casa2026x", em: "senhaCadastro", seguro: true)
        app.digitar("Outra2026x", em: "confirmacao", seguro: true)
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "As senhas não são iguais.")
        let confirmacao = app.secureTextFields["confirmacao"]
        confirmacao.tap()
        app.recusarSenhaForte()
        confirmacao.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10) + "Casa2026x")
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "Conte como conheceu o Custta.")
        app.buttons["origem"].tap()
        app.buttons["Pesquisa no Google"].tap()
        app.buttons["criarConta"].tap()
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10), "conta nova entra no app com o aviso de e-mail")
    }
}
