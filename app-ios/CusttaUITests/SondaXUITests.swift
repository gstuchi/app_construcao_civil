import XCTest

/* Sonda temporária, só no proto/ (04/11, D'1 da 2ª revisão): o × da busca e a pílula na VM da CI, na ponta da pilha. Cada
   rodada anexa o print depois do ×, para ler um × que não limpou. Não vai para nenhum commit da main. */
@MainActor final class SondaXUITests: XCTestCase {
    func testTecladoDepoisDoAVencer() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.rolarAte(app.elemento("lancamentos"))
        app.buttons["buscar"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let campo = app.textFields["campoDaBusca"], pilula = app.elemento("lancamentos")
        app.digitarComFoco("ceramica", em: campo)
        sleep(1)
        let aVencer = app.elemento("aVencer"), x = app.buttons["apagarTextoDaBusca"]
        func quadro(_ e: XCUIElement) -> String { e.exists ? "\(e.frame)" : "-" }
        print("sonda-x | antes: teclado \(app.keyboards.firstMatch.exists) pílula \(quadro(pilula)) campo \(quadro(campo)) × \(quadro(x))")
        aVencer.tap()
        for t in [0.1, 0.3, 0.6, 1.0, 2.0] {
            Thread.sleep(forTimeInterval: t == 0.1 ? 0.1 : 0.2)
            print("sonda-x | t≈\(t): teclado \(app.keyboards.firstMatch.exists) pílula \(quadro(pilula)) × \(quadro(x)) campo '\(campo.value ?? "")'")
        }
        x.tap()
        sleep(1)
        let foto = XCTAttachment(screenshot: app.screenshot())
        foto.lifetime = .keepAlways
        add(foto)
        print("sonda-x | depois do ×: campo '\(campo.value ?? "")' pílula \(pilula.label) \(quadro(pilula)) teclado \(app.keyboards.firstMatch.exists)")
    }
}
