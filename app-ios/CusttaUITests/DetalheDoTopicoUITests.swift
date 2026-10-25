import XCTest
import notify

/* O detalhe do tópico da etapa 3 (PR 2), aberto pelo gancho por cima da tela Orçamento da Casa Alphaville do mockup: a
   Cerâmica, com o resumo, a linha do orçamento do tópico e as seções "A vencer" e "Pagos", a linha de gasto sem o tópico; a
   Documentação, fora do orçamento, com "Sem valor no orçamento" no lugar da barra; no modo total (a vitrine de sempre), sem a
   linha do orçamento; a obra apagada em outro aparelho fecha a folha. E pelas linhas da tela Orçamento, cada uma um botão
   inteiro: o previsto com gasto abre e o sem gasto não; o fora do orçamento abre; no modo total, o "Gasto por tópico" abre.
   De dentro do detalhe: tocar num gasto empurra a edição, com o nome do tópico, e "Salvar" volta na mesma rolagem com os
   números novos (também na maior letra, com as 126 linhas da Mão de obra do topicoLongo); o gasto que troca de tópico sai do
   detalhe; "Apagar" da edição volta com os números novos. Sem gasto no tópico, a folha desce: trocando o tópico do último
   gasto, apagando a compra toda que era o tópico inteiro e arrastando o último; na recusa, ela fica; e quando outro aparelho
   apaga o último gasto com a edição e o "Apagar este gasto?" abertos, ela desce com o alerta, sem gravar nada. */
@MainActor
final class DetalheDoTopicoUITests: XCTestCase {
    private static let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    /// A tela Orçamento da Casa Alphaville (v1) com o detalhe do tópico aberto por cima.
    private func abrirDetalhe(_ topico: String, dados: String = "porTopico", argumentos: [String] = [],
                              extra: [String: String] = [:]) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "orcamento:v1", folha: "topico:v1:\(topico)", argumentos: argumentos,
                           extra: extra)
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
        guard app.elemento("resumoDoTopico").waitForExistence(timeout: 10) else {
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

    // MARK: Editar e apagar de dentro do detalhe

    /// Toca num gasto do detalhe, rolando até ele: a edição entra na mesma folha.
    private func editar(_ app: XCUIApplication, _ id: String) {
        let linha = rolarNaFolha(app, ate: "gasto-\(id)")
        guard linha.exists else { return XCTFail("a linha \(id) no detalhe") }
        linha.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "a edição de \(id) entrou na folha")
    }

    /// O valor no teclado de valor: apaga e digita `teclas`; "Pronto" volta à edição.
    private func mudarValor(_ app: XCUIApplication, _ teclas: String) {
        app.elemento("linhaValor").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for _ in 0..<8 { app.buttons["tecla-del"].tap() }
        for t in teclas { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaValor").waitForExistence(timeout: 5))
    }

    /// Troca o tópico da edição por um da lista "Todos" e volta a ela.
    private func trocarOTopico(_ app: XCUIApplication, para id: String, nome: String) {
        app.elemento("linhaTopico").tap()
        let topico = app.buttons["topico-\(id)"]
        XCTAssertTrue(topico.waitForExistence(timeout: 5), "a lista dos tópicos")
        topico.tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaTopico").value as? String, nome, "o tópico novo na edição")
    }

    /// Volta na mesma folha: a edição sai e o detalhe fica, com o × (o resumo, lá no alto, pode estar fora da parte da lista
    /// que a LazyVStack criou).
    private func voltouAoDetalhe(_ app: XCUIApplication, _ porque: String) {
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5), porque)
        XCTAssertTrue(app.buttons["fecharFolha"].waitForExistence(timeout: 3), "o detalhe continua aberto")
    }

    /// Sem gasto no tópico, a folha desce, como no site, e fica a tela Orçamento: a linha do tópico em R$ 0,00, que não abre
    /// mais o detalhe.
    private func desceu(_ app: XCUIApplication, _ porque: String, linha id: String) {
        guard app.buttons["fecharFolha"].waitForNonExistence(timeout: 5) else { return XCTFail("a folha desceu: \(porque)") }
        XCTAssertFalse(app.elemento("resumoDoTopico").exists, "sem o detalhe")
        let linha = app.elemento(id)
        app.rolarAte(linha)
        XCTAssertTrue(linha.label.contains("R$\u{a0}0,00"), "a tela Orçamento sem o gasto: \(linha.label)")
        XCTAssertFalse(app.buttons[id].exists, "\(id): sem gasto, a linha não abre o detalhe")
    }

    /// Arrasta a linha da folha para a esquerda e toca no "Apagar" dela.
    private func arrastarEApagar(_ app: XCUIApplication, _ id: String) {
        let linha = rolarNaFolha(app, ate: "gasto-\(id)")
        guard linha.exists else { return XCTFail("a linha \(id) no detalhe") }
        linha.swipeLeft()
        let apagar = app.buttons["apagar-\(id)"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 3), "arrastar para a esquerda mostra Apagar, com a folha aberta")
        apagar.tap()
    }

    /// O voltar do sistema da edição: tem o nome da folha de origem.
    private func voltarDoSistema(_ app: XCUIApplication) -> XCUIElement? {
        app.navigationBars.buttons.matching(identifier: "BackButton").allElementsBoundByIndex.first(where: \.isHittable)
    }

    /// O Contrapiso (o pago mais antigo da Cerâmica) de R$ 15.200,00 para R$ 15.800,00, como no mockup: a edição diz
    /// "Cerâmica" no subtítulo e no voltar, e "Salvar" volta na mesma rolagem, com a linha sem o tópico, os números novos e a
    /// linha acesa (a luz de 2 s o XCUITest não vê).
    func testEditarEmpurraComONomeDoTopicoESalvarVoltaAceso() {
        let app = abrirDetalhe("revest")
        let linha = rolarNaFolha(app, ate: "gasto-g021")
        guard linha.exists else { return XCTFail("a linha g021 no detalhe") }
        let antes = linha.frame.minY
        linha.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "tocar no gasto empurra a edição na mesma folha")
        let titulo = app.elemento("tituloDaFolha")
        XCTAssertTrue(titulo.label.hasPrefix("Editar gasto"), titulo.label)
        XCTAssertTrue(titulo.label.hasSuffix("Cerâmica"), "o tópico embaixo do título: \(titulo.label)")
        XCTAssertFalse(app.buttons["fecharFolha"].exists, "sem o ×: o voltar fica no lugar dele")
        XCTAssertEqual(voltarDoSistema(app)?.label, "Cerâmica", "o voltar do sistema, com o nome do tópico")
        mudarValor(app, "1580000")
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}15.800,00")
        app.buttons["salvarGasto"].tap()
        voltouAoDetalhe(app, "Salvar volta ao detalhe")
        sleep(1)
        let depois = app.elemento("gasto-g021")
        XCTAssertEqual(depois.value as? String, "R$\u{a0}15.800,00", "a linha com o valor novo")
        XCTAssertTrue(depois.label.hasPrefix("Contrapiso e regularização. Pix, "), "a linha sem o tópico: \(depois.label)")
        XCTAssertEqual(depois.frame.minY, antes, accuracy: 1, "a lista volta na mesma rolagem")
        confere(app.elemento("resumoDoTopico"), contem: ["11 gastos · 9% da obra", "R$\u{a0}77.300,00", "corrigido: R$\u{a0}78.383,02"])
        confere(app.elemento("orcamentoDoTopico"), contem: ["Faltam R$ 2,7 mil — 97%"])
    }

    /// O Contrapiso para Materiais básicos: "Salvar" volta ao detalhe sem a linha, com os números sem ela; com gasto, a folha
    /// fica.
    func testTrocarOTopicoTiraALinhaDoDetalhe() {
        let app = abrirDetalhe("revest")
        editar(app, "g021")
        trocarOTopico(app, para: "matbasicos", nome: "Materiais básicos")
        app.buttons["salvarGasto"].tap()
        voltouAoDetalhe(app, "Salvar volta ao detalhe")
        XCTAssertTrue(app.elemento("gasto-g021").waitForNonExistence(timeout: 5), "o gasto de outro tópico sai do detalhe")
        confere(app.elemento("resumoDoTopico"), contem: ["10 gastos · 7% da obra", "R$\u{a0}61.500,00"])
        XCTAssertEqual(app.elemento("secao-Pagos").label, "Pagos · 4")
        sleep(1)
        XCTAssertTrue(app.buttons["fecharFolha"].exists, "com gasto, a folha fica")
    }

    /// As Sapatas e baldrames, o único gasto da Fundação, para Materiais básicos: a folha desce.
    func testTrocarOTopicoDoUltimoGastoDesceAFolha() {
        let app = abrirDetalhe("fundacao")
        editar(app, "g006")
        trocarOTopico(app, para: "matbasicos", nome: "Materiais básicos")
        app.buttons["salvarGasto"].tap()
        desceu(app, "o último gasto foi para outro tópico", linha: "topicoOrc-fundacao")
    }

    /// O Contrapiso, à vista: "Apagar gasto" pergunta com o nome e o valor, e "Apagar" volta ao detalhe com os números do
    /// mockup ("10 gastos · 7% da obra", R$ 61.500,00, corrigido R$ 61.929,43 e "77% usado").
    func testApagarAVistaDaEdicaoVoltaComOsNumerosNovos() {
        let app = abrirDetalhe("revest")
        editar(app, "g021")
        app.buttons["apagarGasto"].tap()
        let alerta = app.alerts["Apagar este gasto?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["Contrapiso e regularização · R$\u{a0}15.200,00. Não dá para desfazer."].exists)
        alerta.buttons["Apagar"].tap()
        voltouAoDetalhe(app, "Apagar volta ao detalhe")
        XCTAssertTrue(app.elemento("gasto-g021").waitForNonExistence(timeout: 5), "e a linha sai, no detalhe")
        confere(app.elemento("resumoDoTopico"), contem: ["10 gastos · 7% da obra", "R$\u{a0}61.500,00", "corrigido: R$\u{a0}61.929,43"])
        confere(app.elemento("orcamentoDoTopico"), contem: ["77% usado"])
        sleep(1)
        XCTAssertTrue(app.buttons["fecharFolha"].exists, "com gasto, a folha fica")
    }

    /// As janelas e portas de alumínio em 6x são os 6 gastos das Esquadrias ("Esq. de alumínio"): "Apagar a compra toda" da
    /// edição de uma parcela esvazia o tópico, e a folha desce.
    func testApagarACompraTodaQueEsvaziaOTopicoDesceAFolha() {
        let app = abrirDetalhe("esquadrias")
        confere(app.elemento("resumoDoTopico"), contem: ["6 gastos · "])
        editar(app, "g039")
        app.buttons["apagarGasto"].tap()
        let alerta = app.alerts["Janelas e portas de alumínio (2/6)"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["Apagar a compra toda (6 parcelas)"].tap()
        desceu(app, "a compra toda era o tópico inteiro", linha: "topicoOrc-esquadrias")
    }

    /// Os Tijolos, o único gasto da Alvenaria, arrastados: "Apagar" pergunta, e a folha desce.
    func testArrastarOUltimoGastoDesceAFolha() {
        let app = abrirDetalhe("alvenaria")
        arrastarEApagar(app, "g012")
        let alerta = app.alerts["Apagar este gasto?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3), "a pergunta do gasto à vista")
        alerta.buttons["Apagar"].tap()
        desceu(app, "o último gasto saiu arrastando", linha: "topicoOrc-alvenaria")
    }

    /// A recusa do apagar do último gasto: o alerta do site dentro da folha, nada apagado, e a folha não desce.
    func testCarregandoNoArrastarAvisaNoDetalheENaoDesce() {
        let app = abrirDetalhe("alvenaria", argumentos: ["-custta.recusarGravacao", "nao-carregado"])
        arrastarEApagar(app, "g012")
        app.alerts["Apagar este gasto?"].buttons["Apagar"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3), "o alerta do site, dentro da folha: \(app.alerts.allElementsBoundByIndex.map(\.label))")
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 3))
        sleep(1)
        XCTAssertTrue(app.buttons["fecharFolha"].exists, "na recusa, a folha não desce")
        XCTAssertTrue(app.elemento("gasto-g012").exists, "nada foi apagado")
        confere(app.elemento("resumoDoTopico"), contem: ["1 gasto · "])
    }

    /// Os Tijolos, o único gasto da Alvenaria, com a edição empurrada e o "Apagar este gasto?" aberto: outro aparelho os apaga
    /// (o aviso do teste solta o snapshot sem eles). A folha desce com o alerta, e nada é gravado: toda gravação é recusada
    /// aqui, e uma que saísse traria o "Não salvou na nuvem" depois da descida.
    func testUltimoGastoApagadoEmOutroAparelhoComOAlertaAbertoDesceAFolha() {
        let app = abrirDetalhe("alvenaria", extra: ["CUSTTA_APAGAR_REMOTO": "v1/g012@0", "CUSTTA_GRAVACAO": "recusa"])
        editar(app, "g012")
        app.buttons["apagarGasto"].tap()
        let alerta = app.alerts["Apagar este gasto?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3), "a pergunta, com a edição empurrada")
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 10), "o alerta sai com a folha")
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5), "e a edição também")
        // A edição não tem o ×: o do detalhe voltaria com ele se a folha ficasse, e a descida leva menos que isto.
        sleep(2)
        XCTAssertFalse(app.buttons["fecharFolha"].exists, "a folha desceu: o último gasto saiu em outro aparelho")
        desceu(app, "o último gasto saiu em outro aparelho, com o alerta aberto", linha: "topicoOrc-alvenaria")
        XCTAssertFalse(app.alerts["Não salvou na nuvem"].waitForExistence(timeout: 3), "nada foi gravado: \(app.alerts.allElementsBoundByIndex.map(\.label))")
    }

    /// Na maior letra, a Mão de obra do topicoLongo tem 126 linhas (20 diárias a vencer e 106 pagos): a terceira diária a
    /// vencer, de R$ 350,00 para R$ 450,00, e "Salvar" volta com ela no mesmo lugar (o ×, e não o resumo, diz que o detalhe
    /// ficou: o resumo sai da parte criada).
    func testNaMaiorLetraSalvarVoltaNaMesmaRolagemComCemGastos() {
        let app = abrirDetalhe("maoobra", dados: "topicoLongo", argumentos: Self.maiorLetra)
        let linha = rolarNaFolha(app, ate: "gasto-d103")
        guard linha.exists, linha.isHittable else { return XCTFail("a terceira diária a vencer no detalhe: \(linha.frame)") }
        let antes = linha.frame.minY
        linha.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "a edição entrou na folha")
        mudarValor(app, "45000")
        app.buttons["salvarGasto"].tap()
        voltouAoDetalhe(app, "Salvar volta ao detalhe")
        sleep(1)
        let depois = app.elemento("gasto-d103")
        XCTAssertEqual(depois.value as? String, "R$\u{a0}450,00", "a linha com o valor novo")
        XCTAssertEqual(depois.frame.minY, antes, accuracy: 1, "a lista longa volta na mesma rolagem")
    }
}
