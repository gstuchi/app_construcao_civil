import XCTest
import notify

/* O detalhe do tópico da etapa 3 (PR 2), aberto pelo gancho por cima da tela Orçamento da Casa Alphaville do mockup: a
   Cerâmica, com o resumo, a linha do orçamento do tópico e as seções "A vencer" e "Pagos", a linha de gasto sem o tópico; a
   Documentação, fora do orçamento, com "Sem valor no orçamento" no lugar da barra; no modo total (a vitrine de sempre), sem a
   linha do orçamento; a obra apagada em outro aparelho fecha a folha. E pelas linhas da tela Orçamento, cada uma um botão
   inteiro: o previsto com gasto abre e o sem gasto não; o fora do orçamento abre; no modo total, o "Gasto por tópico" abre.
   A edição, o apagar e a folha que desce sem gasto são da Tarefa 32. */
@MainActor
final class DetalheDoTopicoUITests: XCTestCase {
    /// A tela Orçamento da Casa Alphaville (v1) com o detalhe do tópico aberto por cima.
    private func abrirDetalhe(_ topico: String, dados: String = "porTopico", extra: [String: String] = [:]) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "orcamento:v1", folha: "topico:v1:\(topico)", extra: extra)
        XCTAssertTrue(app.elemento("resumoDoTopico").waitForExistence(timeout: 10), "resumoDoTopico não apareceu")
        return app
    }

    /// Rola a lista da folha (o meio da tela) até o elemento estar inteiro à vista, com o arrasto terminando parado.
    private func rolarNaFolha(_ app: XCUIApplication, ate id: String, tentativas: Int = 8) -> XCUIElement {
        let e = app.elemento(id)
        for _ in 0..<tentativas {
            if e.exists, e.frame.minY > 100, e.frame.maxY < app.frame.maxY - 40 { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)),
                       withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        return e
    }

    /// As linhas, uma embaixo da outra, na ordem dada.
    private func emOrdem(_ app: XCUIApplication, _ ids: [String], _ contexto: String) {
        let linhas = ids.map { app.elemento("gasto-\($0)") }
        XCTAssertEqual(linhas.filter(\.exists).count, ids.count, "\(contexto): as \(ids.count) linhas na folha")
        for (a, b) in zip(linhas, linhas.dropFirst()) where a.exists && b.exists {
            XCTAssertLessThanOrEqual(a.frame.maxY, b.frame.minY + 1, "\(contexto): \(a.identifier) antes de \(b.identifier)")
        }
    }

    private func confere(_ elemento: XCUIElement, contem textos: [String]) {
        for texto in textos { XCTAssertTrue(elemento.label.contains(texto), "\"\(texto)\" em \"\(elemento.label)\"") }
    }

    /// A tela Orçamento da Casa Alphaville, sem folha aberta: por tópico, ou no modo total com a vitrine de sempre.
    private func abrirOrcamento(_ dados: String = "porTopico") -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "orcamento:v1")
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10), "a tela Orçamento")
        return app
    }

    /// Rola até a linha da tela Orçamento e toca nela a 30 pt da borda da tela, longe do texto, na altura do meio dela; espera o
    /// detalhe subir. Devolve o quadro da linha antes do toque (nil se o detalhe não abriu).
    private func abrirPelaLinha(_ app: XCUIApplication, _ id: String) -> CGRect? {
        let linha = app.elemento(id)
        app.rolarAte(linha)
        let quadro = linha.frame
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 30, dy: quadro.midY)).tap()
        guard app.elemento("resumoDoTopico").waitForExistence(timeout: 5) else {
            XCTFail("resumoDoTopico não apareceu")
            return nil
        }
        return quadro
    }

    /// A linha é um botão de ponta a ponta do cartão (o quadro do VoiceOver e do Controle por Voz), e o × fecha o detalhe.
    private func linhaInteiraEFechar(_ app: XCUIApplication, _ id: String, _ quadro: CGRect) {
        XCTAssertEqual(quadro.width, app.frame.width - 40, accuracy: 1, "\(id): a linha inteira é o botão, \(quadro)")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(app.elemento("resumoDoTopico").waitForNonExistence(timeout: 5), "o × fecha")
        XCTAssertTrue(app.buttons[id].exists, "\(id): a linha é um botão")
    }

    func testDetalheAbreComOResumoEAsSecoes() {
        let app = abrirDetalhe("revest")
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Cerâmica"), app.elemento("tituloDaFolha").label)
        let resumo = app.elemento("resumoDoTopico")
        confere(resumo, contem: ["11 gastos · 9% da obra", "R$\u{a0}76.700,00", "corrigido: R$\u{a0}77.758,20"])
        // A linha do orçamento do tópico, no mesmo grupo, embaixo do corrigido: o previsto e a frase do site.
        let orcamento = app.elemento("orcamentoDoTopico")
        XCTAssertTrue(orcamento.exists, "a linha do orçamento do tópico, no modo por tópico")
        confere(orcamento, contem: ["No orçamento", "R$\u{a0}80.000,00", "Faltam R$ 3,3 mil — 96%"])
        XCTAssertLessThanOrEqual(resumo.frame.maxY, orcamento.frame.minY, "embaixo do corrigido")
        // "A vencer · 6", com o próximo primeiro; a linha de gasto sem o tópico, que o título da folha já diz.
        let aVencer = app.elemento("secao-A vencer")
        XCTAssertEqual(aVencer.label, "A vencer · 6")
        XCTAssertLessThanOrEqual(orcamento.frame.maxY, aVencer.frame.minY, "a seção vem depois do resumo")
        XCTAssertLessThanOrEqual(aVencer.frame.maxY, app.elemento("gasto-g032").frame.minY + 1, "o cabeçalho em cima do grupo")
        emOrdem(app, ["g032", "g033", "g034", "g035", "g036", "g037"], "a vencer")
        let proxima = app.elemento("gasto-g032")
        XCTAssertTrue(proxima.label.hasPrefix("Porcelanato 60×60, parcela 5 de 10. Cartão, "), proxima.label)
        XCTAssertFalse(proxima.label.contains("Cerâmica"), "o tópico sai da linha e do VoiceOver: \(proxima.label)")
        XCTAssertEqual(proxima.value as? String, "R$\u{a0}6.150,00")
        // Depois, "Pagos · 5", com o mais novo primeiro.
        _ = rolarNaFolha(app, ate: "gasto-g021")
        let pagos = app.elemento("secao-Pagos")
        XCTAssertEqual(pagos.label, "Pagos · 5")
        XCTAssertLessThanOrEqual(app.elemento("gasto-g037").frame.maxY, pagos.frame.minY + 1, "\"Pagos\" depois do último a vencer")
        XCTAssertLessThanOrEqual(pagos.frame.maxY, app.elemento("gasto-g031").frame.minY + 1, "o cabeçalho em cima do grupo")
        emOrdem(app, ["g031", "g030", "g029", "g028", "g021"], "pagos")
        let maisAntigo = app.elemento("gasto-g021")
        XCTAssertTrue(maisAntigo.label.hasPrefix("Contrapiso e regularização. Pix, "), maisAntigo.label)
        // Só o × se chama Fechar (o botão "Fechar" do site sai), e ele fecha.
        let fechar = app.buttons.matching(NSPredicate(format: "label == 'Fechar'")).allElementsBoundByIndex
        XCTAssertEqual(fechar.map(\.identifier), ["fecharFolha"], "só o × se chama Fechar")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(resumo.waitForNonExistence(timeout: 5), "o × fecha")
    }

    func testForaDoOrcamentoMostraSemValor() {
        let app = abrirDetalhe("projeto")
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Documentação"), app.elemento("tituloDaFolha").label)
        confere(app.elemento("resumoDoTopico"), contem: ["2 gastos · 3% da obra", "R$\u{a0}22.880,50", "corrigido: R$\u{a0}26.217,37"])
        // No lugar do previsto, da barra e da frase, a frase do fora do orçamento.
        XCTAssertEqual(app.elemento("orcamentoDoTopico").label, "Sem valor no orçamento: não entra na comparação.")
        // Os dois já pagos: só a seção "Pagos".
        XCTAssertFalse(app.elemento("secao-A vencer").exists, "sem gasto a vencer, a seção não aparece")
        XCTAssertEqual(app.elemento("secao-Pagos").label, "Pagos · 2")
        emOrdem(app, ["g003", "g002"], "pagos")
        let linha = app.elemento("gasto-g002")
        XCTAssertTrue(linha.label.hasPrefix("Projeto arquitetônico. Pix, "), linha.label)
    }

    func testNoModoTotalSemLinhaDoOrcamento() {
        let app = abrirDetalhe("revest", dados: "vitrine")
        let resumo = app.elemento("resumoDoTopico")
        confere(resumo, contem: ["11 gastos · 9% da obra", "R$\u{a0}76.700,00", "corrigido: R$\u{a0}77.758,20"])
        XCTAssertFalse(app.elemento("orcamentoDoTopico").exists, "só o total no orçamento: o tópico não tem linha do orçamento")
        let aVencer = app.elemento("secao-A vencer")
        XCTAssertEqual(aVencer.label, "A vencer · 6")
        XCTAssertLessThanOrEqual(resumo.frame.maxY, aVencer.frame.minY, "a seção logo depois do resumo")
        emOrdem(app, ["g032", "g033"], "a vencer")
    }

    func testPrevistoComGastoAbreESemGastoNao() {
        let app = abrirOrcamento()
        guard let quadro = abrirPelaLinha(app, "topicoOrc-revest") else { return }
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Cerâmica"), app.elemento("tituloDaFolha").label)
        confere(app.elemento("resumoDoTopico"), contem: ["11 gastos · 9% da obra", "R$\u{a0}76.700,00"])
        confere(app.elemento("orcamentoDoTopico"), contem: ["No orçamento", "R$\u{a0}80.000,00"])
        linhaInteiraEFechar(app, "topicoOrc-revest", quadro)
        // O Acabamento, sem gasto ("R$ 0,00 / 60 mil"): sem traço de botão, e o toque não abre nada.
        let acabamento = app.elemento("topicoOrc-acabamento")
        app.rolarAte(acabamento)
        XCTAssertTrue(acabamento.label.contains("R$\u{a0}0,00"), acabamento.label)
        XCTAssertFalse(app.buttons["topicoOrc-acabamento"].exists, "sem gasto, a linha não é botão")
        acabamento.tap()
        XCTAssertFalse(app.elemento("resumoDoTopico").waitForExistence(timeout: 2), "sem gasto, a linha não abre o detalhe")
    }

    func testForaDoOrcamentoAbreODetalhe() {
        let app = abrirOrcamento()
        guard let quadro = abrirPelaLinha(app, "foraOrc-projeto") else { return }
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Documentação"), app.elemento("tituloDaFolha").label)
        confere(app.elemento("resumoDoTopico"), contem: ["2 gastos · 3% da obra", "R$\u{a0}22.880,50"])
        XCTAssertEqual(app.elemento("orcamentoDoTopico").label, "Sem valor no orçamento: não entra na comparação.")
        linhaInteiraEFechar(app, "foraOrc-projeto", quadro)
        XCTAssertTrue(app.buttons["foraOrc-pintura"].exists, "toda linha de fora do orçamento é um botão")
    }

    func testGastoPorTopicoAbreODetalheNoModoTotal() {
        let app = abrirOrcamento("vitrine")
        XCTAssertTrue(app.elemento("gastoTopico-terreno").label.contains("38% da obra"), app.elemento("gastoTopico-terreno").label)
        guard let quadro = abrirPelaLinha(app, "gastoTopico-terreno") else { return }
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Terreno"), app.elemento("tituloDaFolha").label)
        // O mesmo "% da obra" da linha que abriu.
        confere(app.elemento("resumoDoTopico"), contem: ["2 gastos · 38% da obra", "R$\u{a0}319.847,85"])
        XCTAssertFalse(app.elemento("orcamentoDoTopico").exists, "só o total no orçamento: sem a linha do orçamento do tópico")
        linhaInteiraEFechar(app, "gastoTopico-terreno", quadro)
    }

    func testObraApagadaEmOutroAparelhoFechaODetalhe() {
        let app = abrirDetalhe("revest", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.buttons["fecharFolha"].waitForNonExistence(timeout: 10), "a obra sumiu: a folha fecha")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "e a tela Orçamento volta para Obras")
    }
}
