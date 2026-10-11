import XCTest

final class EntradaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testEntrarComEmailESenhaAbreAsObras() {
        let app = abrirApp()
        app.digitar("giovani@exemplo.com", em: "email")
        app.digitar("Casa2026x", em: "senha", seguro: true)
        app.buttons["entrar"].tap()
        XCTAssertTrue(app.elemento("obra-o3").waitForExistence(timeout: 10))
    }

    @MainActor func testMensagensDoFormulario() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["entrar"].waitForExistence(timeout: 10))
        app.buttons["entrar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite seu e-mail.")
        app.digitar("giovani@exemplo.com", em: "email")
        app.buttons["entrar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite a senha.")
        app.digitar("Errada123", em: "senha", seguro: true)
        app.buttons["entrar"].tap()
        let mensagem = app.staticTexts["mensagemEntrada"]
        XCTAssertTrue(mensagem.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "E-mail ou senha incorretos."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
    }

    /// Como no site: "Esqueci minha senha" usa o e-mail digitado no próprio cartão.
    @MainActor func testEsqueciASenha() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["esqueciSenha"].waitForExistence(timeout: 10))
        app.buttons["esqueciSenha"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite seu e-mail no campo acima primeiro.")
        app.digitar("ninguem@exemplo.com", em: "email")
        app.buttons["esqueciSenha"].tap()
        let mensagem = app.staticTexts["mensagemEntrada"]
        expectation(for: NSPredicate(format: "label == %@", "E-mail ou senha incorretos."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
        let campo = app.textFields["email"]
        campo.tap()
        campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + "giovani@exemplo.com")
        app.buttons["esqueciSenha"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Enviamos um link de redefinição pro seu e-mail."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
    }

    @MainActor func testAppleVemAntesDoGoogle() {
        let app = abrirApp()
        let apple = app.buttons["entrarComApple"], google = app.buttons["entrarComGoogle"]
        XCTAssertTrue(apple.waitForExistence(timeout: 10))
        XCTAssertTrue(google.exists)
        XCTAssertLessThan(apple.frame.minY, google.frame.minY, "Guideline 4.8: Apple acima do Google")
    }

    /// Apple, Google e Entrar com 52 pt, como no mockup aprovado e no site.
    @MainActor func testBotoesDaEntradaCom52Pontos() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["entrar"].waitForExistence(timeout: 10))
        for id in ["entrarComApple", "entrarComGoogle", "entrar"] {
            XCTAssertEqual(app.buttons[id].frame.height, 52, accuracy: 0.5, id)
        }
    }

    /// O caminho comum: tocar em Entrar com o teclado aberto. A cápsula fica no lugar e não salta depois.
    /// O XCUITest só lê a tela quando o app fica ocioso, depois que o teclado fecha: os ~0,35 s em que a
    /// cápsula nascia em cima do teclado (conferência da T10, D10) só aparecem nos quadros de um vídeo.
    @MainActor func testEntrarComOTecladoAbertoDeixaACapsulaNoLugar() {
        let app = abrirApp()
        app.digitar("giovani@exemplo.com", em: "email")
        app.digitar("Casa2026x", em: "senha", seguro: true)
        XCTAssertTrue(app.keyboards.firstMatch.exists, "teclado aberto")
        app.buttons["entrar"].tap()
        let aba = app.buttons["aba-obras"]
        XCTAssertTrue(aba.waitForExistence(timeout: 10))
        let primeiro = aba.frame
        let base = app.windows.firstMatch.frame.maxY
        XCTAssertEqual(primeiro.maxY + 4, base - 22, accuracy: 1, "a cápsula nasce 22 pt acima da borda (veio em \(primeiro))")
        sleep(2)
        XCTAssertEqual(aba.frame.minY, primeiro.minY, accuracy: 0.5, "a cápsula não salta depois que o teclado fecha")
    }
}
