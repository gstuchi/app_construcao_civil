import XCTest

/* Sonda temporária (ramo proto/): os passos do BuscaUITests.testBuscarSemAcentoPeloTopicoEPelaDescricao até o × do texto,
   com o estado a cada passo, para ver por que o × não limpa a busca na VM da CI. */
@MainActor final class SondaXUITests: XCTestCase {
    private func estado(_ app: XCUIApplication, _ passo: String) {
        let x = app.buttons["apagarTextoDaBusca"], campo = app.textFields["campoDaBusca"], av = app.elemento("aVencer")
        let p = app.elemento("lancamentos")
        print("sonda-x3 | \(passo) | teclado \(app.keyboards.firstMatch.exists) | × \(x.exists ? "\(x.frame) toca \(x.isHittable)" : "-")"
              + " | campo '\(campo.exists ? (campo.value as? String ?? "") : "-")' \(campo.exists ? "\(campo.frame)" : "")"
              + " | A vencer \(av.exists ? "\(av.value ?? "-") \(av.frame)" : "-") | pílula \(p.exists ? "\(p.label) \(p.frame)" : "-")")
    }

    func testBuscaComX() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.rolarAte(app.elemento("lancamentos"))
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa)
        lupa.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let campo = app.textFields["campoDaBusca"]
        app.digitarComFoco("ceramica", em: campo)
        estado(app, "digitou")
        XCTAssertTrue(app.elemento("gasto-g032").waitForExistence(timeout: 5))
        estado(app, "g032")
        app.elemento("aVencer").tap()
        estado(app, "tocou A vencer")
        Thread.sleep(forTimeInterval: 1)
        estado(app, "1 s depois")
        app.buttons["apagarTextoDaBusca"].tap()
        estado(app, "tocou ×")
        Thread.sleep(forTimeInterval: 1)
        estado(app, "1 s depois do ×")
    }
}
