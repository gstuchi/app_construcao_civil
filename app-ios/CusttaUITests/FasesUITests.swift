import XCTest

/* Fases e venda (etapa 2, parte 3), com as obras da vitrine: a Casa Alphaville em construção (v1), o Sobrado Granja Viana
   pronto (v2) e a Casa Tamboré 4 vendida (v3). Mudar entre construção e pronta não pergunta; a venda vai em dois passos
   (teclado de valor, depois a data) e grava a fase vendida; desfazer pergunta com o texto do site e volta para pronta. */
@MainActor
final class FasesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testMarcarComoProntaEVoltarPraConstrucaoSemPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        XCTAssertFalse(app.buttons["acao-registrarVenda"].exists, "a construção não se vende")
        app.rolarAte(pronta)
        pronta.tap()
        let voltar = app.buttons["acao-voltarConstrucao"]
        XCTAssertTrue(voltar.waitForExistence(timeout: 5), "pronta: voltar e registrar venda")
        XCTAssertTrue(app.buttons["acao-registrarVenda"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists, "mudar a fase não pergunta (o mudarFase do site)")
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        app.rolarAte(voltar)
        voltar.tap()
        XCTAssertTrue(app.buttons["acao-marcarPronta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
    }

    func testDesfazerVendaPerguntaComOTextoDoSite() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let desfazer = app.buttons["acao-desfazerVenda"]
        XCTAssertTrue(desfazer.waitForExistence(timeout: 10))
        app.rolarAte(desfazer)
        desfazer.tap()
        let alerta = app.alerts["Desfazer a venda?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["A obra volta pra “Pronta”."].exists)
        alerta.buttons["Cancelar"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"), "cancelar não muda nada")
        app.rolarAte(desfazer)
        desfazer.tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Desfazer venda"].tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("Venda estimada"), "a venda saiu; volta a estimativa")
    }
}
