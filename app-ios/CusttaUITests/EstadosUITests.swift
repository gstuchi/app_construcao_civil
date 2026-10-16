import XCTest

/* Os estados da etapa 2, parte 3, e o gasto numa obra vendida: a lista vazia que convida ao +; o + que avisa enquanto os
   dados não chegam; o gasto lançado de dentro de uma vendida, que vai para uma aberta escolhida na linha "Obra"; sem
   conexão, gravar continua; o "Não salvou" que não passa sozinho alerta uma vez e tocar na pílula tenta de novo. */
@MainActor
final class EstadosUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSemConexaoGravarContinua() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 10))
        XCTAssertEqual(pilula.label, "Sem conexão")
        let pronta = app.buttons["acao-marcarPronta"]
        app.rolarAte(pronta)
        pronta.tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5), "a fase muda na hora, sem rede")
        XCTAssertEqual(pilula.label, "Sem conexão")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testNaoSalvouAlertaUmaVezETocarTentaDeNovo() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        app.rolarAte(pronta)
        pronta.tap()
        let alerta = app.alerts["Não salvou na nuvem"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Confira sua conexão e conta; toque no aviso para tentar novamente."].exists)
        alerta.buttons["Tentar de novo"].tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3))
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 5))
        XCTAssertFalse(alerta.waitForExistence(timeout: 3), "o mesmo erro não alerta de novo")
        XCTAssertEqual(pilula.label, "Não salvou")
        pilula.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3), "tocar na pílula tenta de novo")
        XCTAssertFalse(alerta.waitForExistence(timeout: 3))
        XCTAssertEqual(pilula.label, "Não salvou")
    }
}
