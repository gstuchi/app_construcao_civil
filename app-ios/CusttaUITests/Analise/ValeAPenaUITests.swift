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

    /// A tabela do site, "Relatório da simulação": sete linhas na Casa Alphaville (a última é o preço por m², porque ela tem
    /// área), cada uma um elemento com os dois valores, pelo bruto e pelo corrigido. Sem preço, a tabela some.
    @MainActor func testATabelaDaSimulacao() {
        let app = abrirAAba()
        let custo = app.elemento("simTabela-0")
        app.rolarAte(custo)
        XCTAssertEqual(custo.label, "Custo até a venda")
        XCTAssertTrue((custo.value as? String ?? "").hasPrefix("Pelo bruto R$\u{00A0}842.317,45, pelo corrigido R$\u{00A0}"), "\(String(describing: custo.value))")
        XCTAssertEqual(app.elemento("simTabela-1").label, "Venda")
        XCTAssertEqual(app.elemento("simTabela-1").value as? String, "Pelo bruto R$\u{00A0}1.450.000,00, pelo corrigido R$\u{00A0}1.450.000,00")
        XCTAssertEqual(app.elemento("simTabela-2").label, "Lucro")
        XCTAssertTrue((app.elemento("simTabela-2").value as? String ?? "").hasPrefix("Pelo bruto R$\u{00A0}607.682,55, "))
        XCTAssertEqual((3...6).map { app.elemento("simTabela-\($0)").label },
                       ["% sobre o custo", "% sobre a venda", "Rendimento ao mês", "Preço por m² (300 m²)"])
        XCTAssertEqual(app.elemento("simTabela-6").value as? String, "Pelo bruto R$\u{00A0}4.833,33, pelo corrigido R$\u{00A0}4.833,33")
        XCTAssertFalse(app.elemento("simTabela-7").exists, "sete linhas")
    }

    /// O + para em 120 meses, como o campo do site. O app abre já em 119 pelo gancho de Debug (`-custta.simMeses`), para
    /// o teste não dar 120 toques.
    @MainActor func testOsMesesParamEm120() {
        let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: ["-custta.simMeses", "119"])
        let meses = app.elemento("simMeses"), mais = app.buttons["simMais"]
        XCTAssertTrue(meses.waitForExistence(timeout: 10))
        XCTAssertEqual(meses.value as? String, "119 meses")
        XCTAssertTrue(mais.isEnabled)
        mais.tap()
        XCTAssertEqual(meses.value as? String, "120 meses")
        XCTAssertFalse(mais.isEnabled, "em 120, o + não anda")
        XCTAssertTrue(app.elemento("simVeredito").label.contains(", vendendo daqui a 120 meses, "), app.elemento("simVeredito").label)
        app.buttons["simMenos"].tap()
        XCTAssertEqual(meses.value as? String, "119 meses")
        XCTAssertTrue(mais.isEnabled)
    }

    /// A obra com menos de 1 mês (o Sobrado Vila Nova começou neste mês): não há taxa ao mês, e o veredito sai pelo preço
    /// contra o custo corrigido, com a frase do site (decisão 5 da parte 2: manter o site).
    @MainActor func testObraComMenosDeUmMesNaoTemTaxa() {
        let app = abrirAAba()
        app.buttons["simObra"].tap()
        let vilaNova = app.buttons["Sobrado Vila Nova"]
        XCTAssertTrue(vilaNova.waitForExistence(timeout: 5))
        vilaNova.tap()
        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Vila Nova")
        XCTAssertEqual(app.elemento("simPreco").value as? String, "R$\u{00A0}1.100.000,00", "a venda estimada dela")
        let veredito = app.elemento("simVeredito")
        XCTAssertTrue(veredito.waitForExistence(timeout: 5))
        XCTAssertTrue(veredito.label.hasPrefix("Vale a pena, sem taxa ao mês, "), veredito.label)
        XCTAssertTrue(veredito.label.contains("menos de 1 mês"), veredito.label)
    }

    /// As teclas do preço (decisão do Giovani de 24/11): o toque na linha do preço troca a cápsula de abas pelas teclas, com
    /// o valor à vista. O OK sem digitar devolve a cápsula e deixa tudo como estava: o preço segue acompanhando a venda
    /// estimada (o Sobrado não tem, e o campo fica vazio).
    @MainActor func testAsTeclasAbremComOValorEOOkSemDigitarNaoMudaNada() {
        let app = abrirAAba()
        let preco = app.elemento("simPreco"), teclas = app.elemento("teclasDoPreco"), ok = app.buttons["teclasDoPreco-ok"]
        XCTAssertFalse(teclas.exists, "fechadas até o toque no preço")
        preco.tap()
        XCTAssertTrue(ok.waitForExistence(timeout: 5), "as teclas do preço")
        XCTAssertEqual(app.elemento("teclasDoPreco-titulo").label, "Preço de venda")
        XCTAssertEqual(ok.label, "OK")
        XCTAssertTrue(app.abasDaCapsula.isEmpty, "as teclas tomam o lugar da cápsula de abas")
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00", "o valor fica à vista")
        XCTAssertLessThanOrEqual(preco.frame.maxY, teclas.frame.minY, "a linha do preço fica acima das teclas")
        ok.tap()
        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
        XCTAssertFalse(ok.exists)
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00")
        escolherObraDepoisDasTeclas(app, "Sobrado Granja Viana")
        XCTAssertEqual(preco.value as? String, "sem preço", "nada foi digitado: o preço ainda acompanha a venda estimada")
    }

    /// A primeira tecla substitui o valor à vista, e as seguintes entram pela direita, com a conta acompanhando cada uma:
    /// R$ 800.000,00 na Casa Alphaville (custou R$ 842.317,45) rende menos que o banco. Apagado até o fim, o campo fica vazio
    /// e a frase do site volta; depois do OK ele não retorna à venda estimada, nem trocando de obra (campo tocado, como no site).
    @MainActor func testAPrimeiraTeclaSubstituiOValorEAContaAcompanha() {
        let app = abrirAAba()
        let preco = app.elemento("simPreco"), ok = app.buttons["teclasDoPreco-ok"]
        preco.tap()
        XCTAssertTrue(ok.waitForExistence(timeout: 5))
        app.buttons["tecla-8"].tap()
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}0,08", "parte do zero, e não do R$ 1.450.000,00 que estava à vista")
        for tecla in ["tecla-0", "tecla-00", "tecla-00", "tecla-00"] { app.buttons[tecla].tap() }
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}800.000,00")
        let veredito = app.elemento("simVeredito")
        XCTAssertTrue(veredito.label.hasPrefix("Rende menos que o banco, "), veredito.label)
        XCTAssertEqual(app.elemento("simPilula").label, "abaixo do banco")
        for _ in 1...9 { app.buttons["tecla-del"].tap() }
        XCTAssertEqual(preco.value as? String, "sem preço")
        XCTAssertTrue(app.elemento("simSemPreco").waitForExistence(timeout: 5), "sem preço, a frase do site")
        XCTAssertFalse(veredito.exists)
        ok.tap()
        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5))
        XCTAssertEqual(preco.value as? String, "sem preço", "o campo apagado não volta para a venda estimada")
        escolherObraDepoisDasTeclas(app, "Sobrado Vila Nova")
        XCTAssertEqual(preco.value as? String, "sem preço", "nem trocando para uma obra com venda estimada")
    }

    /// Escolhe a obra no menu logo depois do OK das teclas. O OK devolve a cápsula antes de a rolagem assentar, e o toque no
    /// menu nesse meio se perdia; e a escolha chega depois de o menu fechar, então a leitura sem espera pegava a obra de antes
    /// (Lupa, no iOS 26.5: 1 queda em 25 e 2 em 40). Espera as teclas saírem, toca de novo se o item não aparecer, como o
    /// `digitarComFoco`, e espera a obra trocar.
    @MainActor private func escolherObraDepoisDasTeclas(_ app: XCUIApplication, _ nome: String) {
        XCTAssertTrue(app.elemento("teclasDoPreco").waitForNonExistence(timeout: 5), "as teclas fecharam")
        let obra = app.buttons["simObra"], item = app.buttons[nome]
        for _ in 0..<3 {
            guard !item.exists else { break }
            obra.tap()
            _ = item.waitForExistence(timeout: 3)
        }
        XCTAssertTrue(item.exists, "\(nome) no menu da obra")
        item.tap()
        let trocou = NSPredicate { _, _ in obra.value as? String == nome }
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: trocou, object: nil)], timeout: 5), .completed,
                       "a obra escolhida: \(String(describing: obra.value))")
    }

    /// Na letra máxima, a linha do preço nasce mais embaixo, e as teclas são mais altas que a cápsula: ao abrir, a linha
    /// sobe o que falta para ficar inteira acima delas, e abaixo da barra de cima.
    @MainActor func testNaLetraMaximaALinhaDoPrecoFicaAcimaDasTeclas() {
        let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
        let preco = app.elemento("simPreco"), teclas = app.elemento("teclasDoPreco")
        app.rolarAte(preco)
        preco.tap()
        XCTAssertTrue(app.buttons["teclasDoPreco-ok"].waitForExistence(timeout: 5), "as teclas do preço")
        // A rolagem que põe a linha à vista termina depois de as teclas aparecerem: espera o quadro assentar.
        let acima = NSPredicate { _, _ in preco.frame.maxY <= teclas.frame.minY + 0.5 }
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: acima, object: nil)], timeout: 5), .completed,
                       "a linha do preço (\(preco.frame)) acima das teclas (\(teclas.frame))")
        XCTAssertGreaterThanOrEqual(preco.frame.minY, app.navigationBars.firstMatch.frame.maxY, "e abaixo da barra de cima")
        app.buttons["tecla-5"].tap()
        XCTAssertEqual(preco.value as? String, "R$\u{00A0}0,05")
    }

    /// O que a auditoria do Xcode não vê nesta tela (prova da Lupa na fatia 8, com defeito plantado): o alvo pequeno e o
    /// título preso numa linha. Os alvos se medem pelo quadro: 44 pt, e o − e o + com 72 na maior letra. Nela, os títulos
    /// da faixa e da tabela não cabem numa linha de 53 pt e têm de quebrar: o quadro passa de duas linhas.
    @MainActor func testOsAlvosTem44PontosEOsTitulosQuebramNaMaiorLetra() {
        var app = abrirAAba()
        for id in ["simObra", "simPreco", "simMenos", "simMais"] {
            let alvo = app.elemento(id).frame
            XCTAssertGreaterThanOrEqual(min(alvo.width, alvo.height), 44, "\(id): \(alvo)")
        }
        app.elemento("simPreco").tap()
        let ok = app.buttons["teclasDoPreco-ok"]
        XCTAssertTrue(ok.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(min(ok.frame.width, ok.frame.height), 44, "o OK das teclas: \(ok.frame)")
        app.terminate()
        app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                       argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
        for id in ["simMenos", "simMais"] {
            let alvo = app.elemento(id).frame
            XCTAssertGreaterThanOrEqual(min(alvo.width, alvo.height), 72, "\(id) na maior letra: \(alvo)")
        }
        for id in ["simTituloDaFaixa", "simTituloDaTabela"] {
            let titulo = app.elemento(id)
            XCTAssertTrue(titulo.exists, id)
            XCTAssertGreaterThanOrEqual(titulo.frame.height, 106, "\(id) em duas linhas ou mais na maior letra: \(titulo.frame)")
            XCTAssertLessThanOrEqual(titulo.frame.width, app.frame.width - 68, "\(id) dentro das bordas de 34 pt: \(titulo.frame)")
        }
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
