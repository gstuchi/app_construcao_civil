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

    /// O título solto a 16 pt da borda; a cápsula de metadados a 16 e o texto dela (a fase e "começou em …") a 34 (ajuste 2
    /// do mockup), na letra padrão e na máxima; o título pequeno da barra no nome da obra, maior na letra máxima.
    func testTituloECapsulaDeMetadadosNaGrade() {
        var alturas: [CGFloat] = []
        for argumentos in [[], maiorLetra] {
            let app = abrirVitrine(argumentos)
            XCTAssertEqual(app.elemento("vitrine-titulo").frame.minX, 16, accuracy: 0.5, "\(argumentos)")
            let capsula = app.elemento("vitrine-metadados")
            XCTAssertEqual(capsula.frame.minX, 16, accuracy: 0.5, "\(argumentos)")
            // A etiqueta da fase começa a 34; o texto dela, 12 pt para dentro (EtiquetaDeFase).
            XCTAssertEqual(capsula.staticTexts["Em construção"].frame.minX, 34 + 12, accuracy: 0.5, "\(argumentos)")
            let inicio = capsula.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'começou em'")).firstMatch
            XCTAssertEqual(inicio.frame.minX, 34, accuracy: 0.5, "\(argumentos)")
            XCTAssertEqual(app.elemento("tituloPequenoDaBarra").label, "Casa Alphaville")
            alturas.append(app.elemento("tituloPequenoDaBarra").frame.height)
            app.terminate()
        }
        // O título da barra lê a letra de fora dela: de 16 pt na padrão a 20 na máxima.
        XCTAssertGreaterThan(alturas[1] / alturas[0], 1.2, "\(alturas)")
    }

    /// O número mono é um elemento só, que o VoiceOver lê inteiro, com o texto do núcleo; o maior valor, na letra máxima,
    /// fica dentro do bloco, entre as bordas de 34 pt.
    func testNumeroMonoLidoInteiroECabeNaLetraMaxima() {
        let app = abrirVitrine(maiorLetra)
        XCTAssertEqual(app.elemento("vitrine-total").label, "R$\u{a0}842.317,45")
        let maior = app.elemento("vitrine-maiorValor")
        app.rolarAte(maior)
        XCTAssertEqual(maior.label, "R$\u{a0}1.000.000.000,00")
        XCTAssertEqual(maior.frame.minX, 34, accuracy: 0.5)
        XCTAssertLessThanOrEqual(maior.frame.maxX, app.frame.width - 34 + 0.5)
    }
}
