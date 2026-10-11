import XCTest

/* "Finalizar saída" com os falsos (CUSTTA_LIMPEZA): a limpeza do cache falha ao sair, ou a abertura já
   encontra a limpeza que falhou; a primeira nova tentativa falha de novo e a segunda dá certo. Cada nova
   tentativa leva 3 s, então o "Limpando…" (depois de 0,5 s) dá para ver. */
final class FinalizarSaidaUITests: XCTestCase {
    static let titulo = "Finalizar saída"
    static let texto = "Suas obras continuam salvas na sua conta. Falta limpar os dados do Custta que ficaram neste iPhone antes de entrar de novo."
    static let erro = "Ainda não foi possível limpar. Suas obras continuam salvas na sua conta. Tente de novo ou feche o Custta e abra outra vez."
    static let botao = "Tentar limpar novamente"

    /// Aberto, tentando, falhou de novo e deu certo, a partir do alerta já aberto.
    @MainActor private func finalizar(_ app: XCUIApplication) {
        let alerta = app.alerts[Self.titulo]
        XCTAssertTrue(alerta.waitForExistence(timeout: 10), "o alerta abre sobre a entrada")
        XCTAssertTrue(alerta.staticTexts[Self.texto].exists)
        XCTAssertEqual(alerta.buttons.count, 1, "um botão só, sem Cancelar: o alerta não fecha sem limpar")
        alerta.buttons[Self.botao].tap()
        XCTAssertTrue(app.elemento("limpando").waitForExistence(timeout: 5), "tentando: \"Limpando…\" no lugar do alerta")
        XCTAssertTrue(alerta.staticTexts[Self.erro].waitForExistence(timeout: 10), "falhou de novo: o alerta volta com o erro")
        alerta.buttons[Self.botao].tap()
        XCTAssertTrue(app.elemento("limpando").waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("limpando").waitForNonExistence(timeout: 10), "deu certo: o escurecido sai")
        XCTAssertFalse(alerta.exists, "sem aviso")
        XCTAssertTrue(app.textFields["email"].isHittable, "a entrada fica livre")
    }

    @MainActor func testLimpezaQueFalhaAoSairPedeParaFinalizar() {
        let app = abrirApp(conta: "senha", limpeza: "falha")
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 10))
        app.buttons["sair"].tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5))
        app.alerts["Sair da conta?"].buttons["Sair"].tap()
        finalizar(app)
    }

    @MainActor func testLimpezaQueFalhouNaAberturaPedeParaFinalizar() {
        finalizar(abrirApp(conta: "nenhuma", limpeza: "abertura"))
    }
}
