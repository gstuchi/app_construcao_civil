import XCTest

/* A aba "Vale a pena?" (etapa 4, PR 4a), com os falsos da análise (`dados: "analise"`): as obras elegíveis são as não
   vendidas com gastos, na ordem do documento (Casa Alphaville, com venda estimada de R$ 1.450.000,00; Sobrado Granja Viana,
   sem estimada; …). */
final class ValeAPenaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirAAba(_ extra: [String: String] = [:]) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "analise", extra: extra)
        app.abrirAba("valeAPena")
        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10), "a aba abriu")
        return app
    }

    /// A aba fica no meio da cápsula, e o + some nela, como em Ajustes e como no site. Os campos nascem com a primeira obra
    /// elegível, o preço na venda estimada dela e os meses em 0, com o − desabilitado.
    @MainActor func testAAbaAbreComOsCamposESemOMais() {
        let app = abrirAAba()
        let aba = app.buttons["aba-valeAPena"]
        XCTAssertTrue(aba.isSelected)
        XCTAssertEqual(aba.label, "Vale a pena?")
        XCTAssertEqual(aba.value as? String, "2 de 3")
        XCTAssertTrue(app.buttons["botaoMais"].waitForNonExistence(timeout: 3), "o + some nessa aba")
        XCTAssertEqual(app.elemento("tituloValeAPena").label, "Será que vale a pena?")
        XCTAssertEqual(app.buttons["simObra"].value as? String, "Casa Alphaville")
        XCTAssertEqual(app.elemento("simPreco").value as? String, "R$\u{00A0}1.450.000,00")
        XCTAssertEqual(app.elemento("simMeses").value as? String, "0 meses")
        XCTAssertFalse(app.buttons["simMenos"].isEnabled, "em 0, o − não anda")
        XCTAssertTrue(app.buttons["simMais"].isEnabled)
    }

    /// O + e o − andam os meses de um em um, e o texto falado acompanha ("1 mês", "2 meses").
    @MainActor func testOsMesesAndamDeUmEmUm() {
        let app = abrirAAba()
        let meses = app.elemento("simMeses"), mais = app.buttons["simMais"], menos = app.buttons["simMenos"]
        mais.tap()
        XCTAssertEqual(meses.value as? String, "1 mês")
        XCTAssertTrue(menos.isEnabled)
        mais.tap()
        XCTAssertEqual(meses.value as? String, "2 meses")
        menos.tap()
        menos.tap()
        XCTAssertEqual(meses.value as? String, "0 meses")
        XCTAssertFalse(menos.isEnabled)
    }

    /// Sem ter digitado, trocar de obra troca o preço: o Sobrado não tem venda estimada, e o campo fica vazio; de volta à
    /// Casa, a estimada dela.
    @MainActor func testTrocarDeObraTrocaOPrecoEnquantoNaoDigitou() {
        let app = abrirAAba()
        let obra = app.buttons["simObra"], preco = app.elemento("simPreco")
        obra.tap()
        let sobrado = app.buttons["Sobrado Granja Viana"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5), "a lista das obras elegíveis")
        XCTAssertFalse(app.buttons["Casa Tamboré 4"].exists, "a vendida fica fora da lista")
        XCTAssertFalse(app.buttons["Casa Cotia"].exists, "a obra sem gastos também")
        sobrado.tap()
        XCTAssertTrue(obra.waitForExistence(timeout: 5))
        XCTAssertEqual(obra.value as? String, "Sobrado Granja Viana")
        XCTAssertEqual(preco.value as? String, "sem preço")
        obra.tap()
        let casa = app.buttons["Casa Alphaville"].firstMatch
        XCTAssertTrue(casa.waitForExistence(timeout: 5))
        casa.tap()
        XCTAssertEqual(obra.value as? String, "Casa Alphaville")
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00")
    }

    /// Os campos moram no app, não na tela da aba: ir a Ajustes e voltar não zera a obra nem os meses.
    @MainActor func testOsCamposFicamAoTrocarDeAba() {
        let app = abrirAAba()
        app.buttons["simMais"].tap()
        app.buttons["simMais"].tap()
        app.buttons["simObra"].tap()
        let sobrado = app.buttons["Sobrado Granja Viana"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
        sobrado.tap()
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        app.abrirAba("valeAPena")
        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Granja Viana")
        XCTAssertEqual(app.elemento("simMeses").value as? String, "2 meses")
    }

    /// Com a obra e o preço, o veredito aparece no bloco sólido, num elemento só para o VoiceOver, e acompanha os meses.
    /// Sem preço (o Sobrado não tem venda estimada), a frase do site toma o lugar dele.
    @MainActor func testOVereditoAcompanhaOsCampos() {
        let app = abrirAAba()
        let veredito = app.elemento("simVeredito")
        XCTAssertTrue(veredito.waitForExistence(timeout: 5), "a Casa Alphaville tem venda estimada: a conta já aparece")
        XCTAssertTrue(veredito.label.hasPrefix("Vale a pena, "), veredito.label)
        XCTAssertTrue(veredito.label.contains("% ao mês, vendendo hoje, banco paga 1%"), veredito.label)
        XCTAssertFalse(app.elemento("simSemPreco").exists)
        app.buttons["simMais"].tap()
        XCTAssertTrue(veredito.label.contains(", vendendo daqui a 1 mês, "), veredito.label)
        app.buttons["simObra"].tap()
        let sobrado = app.buttons["Sobrado Granja Viana"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
        sobrado.tap()
        let semPreco = app.elemento("simSemPreco")
        XCTAssertTrue(semPreco.waitForExistence(timeout: 5))
        XCTAssertEqual(semPreco.label, "Digite o preço de venda pra ver a conta.")
        XCTAssertFalse(veredito.exists, "sem preço não há veredito")
    }

    /// A faixa "Onde a sua venda cai": uma imagem com a frase dos três valores para o VoiceOver, a pílula do lado em que a
    /// venda caiu e a lista com o custo, o empate e a venda. A Casa Alphaville custou R$ 842.317,45 e tem a venda estimada em
    /// R$ 1.450.000,00: cai acima do banco. Sem preço, a faixa some com o veredito.
    @MainActor func testAFaixaMostraOndeAVendaCai() {
        let app = abrirAAba()
        let faixa = app.elemento("simFaixa")
        XCTAssertTrue(faixa.waitForExistence(timeout: 5))
        XCTAssertTrue(faixa.label.hasPrefix("Custo R$\u{00A0}842.317,45, empata com o banco em R$\u{00A0}"), faixa.label)
        XCTAssertTrue(faixa.label.hasSuffix(", sua venda R$\u{00A0}1.450.000,00"), faixa.label)
        XCTAssertEqual(app.elemento("simPilula").label, "acima do banco")
        XCTAssertEqual(app.elemento("simFaixa-custo").label, "custo (bruto)")
        XCTAssertEqual(app.elemento("simFaixa-custo").value as? String, "R$\u{00A0}842.317,45")
        XCTAssertEqual(app.elemento("simFaixa-empate").label, "empata com o banco")
        XCTAssertEqual(app.elemento("simFaixa-venda").value as? String, "R$\u{00A0}1.450.000,00")
        // As três linhas ficam embaixo da faixa, na ordem do custo, do empate e da venda.
        let linhas = ["custo", "empate", "venda"].map { app.elemento("simFaixa-\($0)").frame.minY }
        XCTAssertEqual(linhas, linhas.sorted())
        XCTAssertGreaterThan(linhas[0], faixa.frame.maxY)
        app.buttons["simObra"].tap()
        let sobrado = app.buttons["Sobrado Granja Viana"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
        sobrado.tap()
        XCTAssertTrue(app.elemento("simSemPreco").waitForExistence(timeout: 5))
        XCTAssertFalse(faixa.exists, "sem preço não há faixa")
    }

    /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
    @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
        let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
        XCTAssertEqual(app.elemento("simSemObra").label, "— crie uma obra com gastos —")
        XCTAssertFalse(app.buttons["simObra"].exists)
        XCTAssertFalse(app.elemento("simVeredito").exists, "sem obra, só os campos")
        XCTAssertFalse(app.elemento("simSemPreco").exists)
    }
}
