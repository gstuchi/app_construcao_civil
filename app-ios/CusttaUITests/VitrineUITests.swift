import XCTest

/* A vitrine das peças da identidade nova (etapa 4, PR 1b), que só o Debug abre (CUSTTA_ABRIR=pecas, em Obras): as peças
   sobre a aurora, nas medidas do mockup aprovado, antes de a obra (PR 1c) usá-las. */
@MainActor
final class VitrineUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    private func abrirVitrine(_ argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas", argumentos: argumentos)
        XCTAssertTrue(app.elemento("vitrine-solido").waitForExistence(timeout: 10), "a vitrine das peças")
        return app
    }

    /// A grade de bordas (ajuste 3 do mockup): os blocos a 16 pt das duas bordas da tela e o texto de dentro a 34, na letra
    /// padrão e na máxima, que não muda as bordas.
    func testBlocosNaGradeDeBordas() {
        for argumentos in [[], maiorLetra] {
            let app = abrirVitrine(argumentos)
            let tela = app.frame.width
            for id in ["vitrine-solido", "vitrine-vidro", "vitrine-ambar"] {
                let bloco = app.elemento(id).frame
                XCTAssertEqual(bloco.minX, 16, accuracy: 0.5, "\(id) \(argumentos)")
                XCTAssertEqual(bloco.maxX, tela - 16, accuracy: 0.5, "\(id) \(argumentos)")
            }
            for rotulo in ["Total gasto", "Corrigido pelo banco", "Rende menos que o banco"] {
                XCTAssertEqual(app.staticTexts[rotulo].frame.minX, 34, accuracy: 0.5, "\(rotulo) \(argumentos)")
            }
            app.terminate()
        }
    }
}
