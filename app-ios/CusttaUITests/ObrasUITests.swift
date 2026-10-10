import XCTest

final class ObrasUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testListaNaOrdemDoSiteComOsTotaisDoNucleo() {
        let app = abrirApp(conta: "senha")
        let ids = ["obra-o3", "obra-o1", "obra-o4", "obra-o2"]
        XCTAssertTrue(app.elemento(ids[0]).waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento(ids[1]).exists)
        XCTAssertLessThan(app.elemento(ids[0]).frame.minY, app.elemento(ids[1]).frame.minY, "não vendidas, a mais recente primeiro")
        let casa = app.elemento("obra-o1")
        XCTAssertEqual(casa.label, "Casa Alphaville")
        let valor = casa.value as? String ?? ""
        XCTAssertTrue(valor.contains("Em construção · "), valor)
        XCTAssertTrue(valor.contains("total gasto R$\u{00A0}329.000,00"), valor)
        XCTAssertTrue(valor.contains("82% do orçamento"), valor)
        app.swipeUp()
        let vendida = app.elemento("obra-o2")
        XCTAssertTrue(vendida.waitForExistence(timeout: 5))
        XCTAssertTrue((vendida.value as? String ?? "").contains("112% · passou R$ 60 mil"))
        XCTAssertTrue(app.staticTexts["4 obras"].exists || app.otherElements["4 obras"].exists)
    }

    @MainActor func testComparativoComDuasObrasComGasto() {
        let app = abrirApp(conta: "senha")
        let painel = app.elemento("comparativo")
        for _ in 0..<6 where !painel.exists { app.swipeUp() }
        XCTAssertTrue(painel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Comparativo entre obras"].exists)
        // Só as obras com gasto entram: a o3 (sem gasto) fica de fora.
        XCTAssertEqual(painel.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Terreno novo")).count, 0)
    }

    @MainActor func testSemObrasMostraOVazio() {
        let app = abrirApp(conta: "senha", dados: "vazio")
        XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
    }

    @MainActor func testAbreSemInternetComTudoLa() {
        let app = abrirApp(conta: "senha", rede: "offline")
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 10), "dados do cache sem rede")
        XCTAssertEqual(app.buttons["indicadorSincronizacao"].label, "Sem conexão")
    }

    @MainActor func testErroDeLeituraMostraNaoSincronizouETentaDeNovo() {
        let app = abrirApp(conta: "senha", leitura: "erro")
        let indicador = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(indicador.waitForExistence(timeout: 10))
        XCTAssertEqual(indicador.label, "Não sincronizou")
        XCTAssertTrue(app.elemento("obrasErroLeitura").exists, "a lista explica o erro em vez de carregar para sempre")
        indicador.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 5))
    }

    @MainActor func testDocumentoIlegivelExplicaQueNadaMudou() {
        let app = abrirApp(conta: "senha", leitura: "formato")
        XCTAssertTrue(app.elemento("obrasErroLeitura").waitForExistence(timeout: 10), "nada de carregando para sempre")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Nada foi alterado")).firstMatch.exists)
        XCTAssertTrue(app.buttons["tentarLerDeNovo"].exists)
    }

    @MainActor func testAvisoDeEmailNaoConfirmado() {
        let app = abrirApp(conta: "senha-nao-confirmada")
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        for id in ["reenviarLink", "jaConfirmei"] {
            // Os botões pequenos do mockup (44 pt) ficam em 48, a favor do alvo de toque (conferência da T10).
            XCTAssertEqual(app.buttons[id].frame.height, 48, accuracy: 0.5, id)
        }
        app.buttons["reenviarLink"].tap()
        XCTAssertTrue(app.staticTexts["Link reenviado. Confira também a caixa de spam."].waitForExistence(timeout: 5))
        app.buttons["jaConfirmei"].tap()
        XCTAssertTrue(app.staticTexts["Ainda não recebemos a confirmação. Toque no link do e-mail e tente de novo."].waitForExistence(timeout: 5))
    }
}
