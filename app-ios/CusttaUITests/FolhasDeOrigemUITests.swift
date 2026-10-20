import XCTest
import notify

/* As folhas de origem da etapa 3 (PR 2), na obra da vitrine (46 lançamentos, 3 vencimentos em 30 dias, contados de hoje):
   a seta do indicador abre a folha "A pagar · 30 dias" com o resumo, os vencimentos por mês e a frase do que vem depois;
   a obra sem vencimentos abre a folha vazia, que fecha só pelo × e pelo puxar; a obra apagada em outro aparelho fecha a
   folha. A volta à folha de origem: tocar num vencimento empurra a edição na mesma folha; "Salvar" volta na mesma rolagem
   com os números novos (e, na maior letra, a linha que foi para o fim da lista fica à vista); sem mudança, o voltar do
   sistema e a borda voltam; com mudança, o chevron, a borda e o puxar perguntam, a borda sem tocar no botão de baixo e sem
   atrapalhar a rolagem; o toque duplo no "Salvar"; o "Carregando" e o "Não salvou" com a origem aberta; o gasto apagado em
   outro aparelho com a edição aberta. */
@MainActor
final class FolhasDeOrigemUITests: XCTestCase {
    private static let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    /// A obra aberta (v1, a Casa Alphaville do mockup, por padrão).
    private func abrirObra(_ obra: String = "v1", argumentos: [String] = [], gravacao: String? = nil,
                           extra: [String: String] = [:]) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:\(obra)", gravacao: gravacao, argumentos: argumentos, extra: extra)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        return app
    }

    /// A seta do indicador "A pagar · 30 dias": rola até ele e toca; a folha abre com o resumo.
    private func abrirAPagar(_ app: XCUIApplication) {
        let indicador = app.elemento("indicadorAPagar")
        XCTAssertTrue(indicador.waitForExistence(timeout: 5))
        app.rolarAte(indicador)
        indicador.tap()
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForExistence(timeout: 5), "a seta abre a folha do A pagar")
    }

    /// O elemento da folha (o que recebe o toque), e não o da obra por trás dela.
    private func naFolha(_ app: XCUIApplication, _ id: String) -> XCUIElement? {
        app.descendants(matching: .any).matching(identifier: id).allElementsBoundByIndex.first { $0.exists && $0.isHittable }
    }

    private func puxarFolha(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)),
                   withVelocity: .fast, thenHoldForDuration: 0)
    }

    /// Rola a lista da folha (o meio da tela) até o elemento estar inteiro à vista, com o arrasto terminando parado.
    private func rolarNaFolha(_ app: XCUIApplication, ate id: String, tentativas: Int = 12) -> XCUIElement? {
        for _ in 0..<tentativas {
            if let e = naFolha(app, id), e.frame.minY > 100, e.frame.maxY < app.frame.maxY - 40 { return e }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)),
                       withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        return naFolha(app, id)
    }

    /// Toca num vencimento da folha: a edição entra na mesma folha.
    private func editar(_ app: XCUIApplication, _ id: String) {
        guard let linha = rolarNaFolha(app, ate: "gasto-\(id)") else { return XCTFail("a linha \(id) na folha") }
        linha.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "a edição de \(id) entrou na folha")
    }

    /// Muda a descrição (" x" no fim) e fecha o teclado.
    private func mudarDescricao(_ app: XCUIApplication) {
        let campo = app.textFields["descricao"]
        XCTAssertTrue(campo.waitForExistence(timeout: 5))
        for _ in 0..<5 where !app.keyboards.firstMatch.exists { campo.tap(); sleep(1) }
        campo.typeText(" x")
        campo.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "o teclado fecha")
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

    /// Os alertas à vista, pelo título.
    private func alertas(_ app: XCUIApplication) -> [String] { app.alerts.allElementsBoundByIndex.map(\.label) }

    /// Volta na mesma folha: a edição sai e a raiz do A pagar fica, com o × da folha (o resumo, lá no alto, pode estar
    /// fora da parte da lista que a LazyVStack criou).
    private func voltouAoAPagar(_ app: XCUIApplication, _ porque: String) {
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5), porque)
        XCTAssertTrue(app.buttons["fecharFolha"].waitForExistence(timeout: 3), "a folha do A pagar continua aberta")
    }

    /// O voltar do sistema da edição: tem o nome da folha de origem (medido em 20/10).
    private func voltarDoSistema(_ app: XCUIApplication) -> XCUIElement? {
        app.navigationBars.buttons.matching(identifier: "BackButton").allElementsBoundByIndex.first(where: \.isHittable)
    }

    /// AAAA-MM de hoje + `dias`, no fuso do aparelho (o do app).
    private func mes(daquiA dias: Int) -> String {
        let dia = Calendar(identifier: .gregorian).date(byAdding: .day, value: dias, to: .now) ?? .now
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: dia)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    func testASetaDoIndicadorAbreAFolhaDoAPagar() {
        let app = abrirObra()
        let indicador = app.elemento("indicadorAPagar")
        XCTAssertTrue(indicador.waitForExistence(timeout: 5))
        XCTAssertTrue(indicador.label.hasPrefix("A pagar · 30 dias"), indicador.label)
        XCTAssertTrue(indicador.label.contains("Parcelas e gastos futuros"), indicador.label)
        XCTAssertTrue(indicador.elementType == .button, "a linha inteira é o botão: \(indicador.elementType.rawValue)")
        abrirAPagar(app)
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("A pagar · 30 dias"), app.elemento("tituloDaFolha").label)
        let resumo = app.elemento("resumoDoAPagar")
        XCTAssertTrue(resumo.label.contains("R$\u{a0}13.250,00"), resumo.label)
        XCTAssertTrue(resumo.label.contains("3 vencimentos · a partir de amanhã"), resumo.label)
        // Os três vencimentos do indicador, o próximo primeiro (a ordem do aPagar), com a linha da etapa 2.
        let ids = ["g039", "g032", "g045"]
        let linhas = ids.compactMap { naFolha(app, "gasto-\($0)") }
        XCTAssertEqual(linhas.count, 3, "os três vencimentos na folha")
        if linhas.count == 3 {
            XCTAssertLessThan(linhas[0].frame.minY, linhas[1].frame.minY)
            XCTAssertLessThan(linhas[1].frame.minY, linhas[2].frame.minY)
            XCTAssertTrue(linhas[2].label.hasPrefix("Tinta acrílica, parcela 2 de 3. Pintura, Cartão, "), linhas[2].label)
            XCTAssertEqual(linhas[2].value as? String, "R$\u{a0}2.300,00")
        }
        // Agrupados por mês: o cabeçalho do mês do 2º vencimento, com o total dele (o do 3º, se for o mesmo mês).
        let mesDoSegundo = mes(daquiA: 24)
        let total = mes(daquiA: 25) == mesDoSegundo ? "R$\u{a0}8.450,00" : "R$\u{a0}6.150,00"
        let cabecalho = naFolha(app, "mes-\(mesDoSegundo)")
        XCTAssertNotNil(cabecalho, "o cabeçalho do mês")
        XCTAssertTrue(cabecalho?.label.contains(total) == true, cabecalho?.label ?? "")
        if let cabecalho, linhas.count == 3 { XCTAssertLessThan(cabecalho.frame.maxY, linhas[1].frame.minY + 1) }
        // A frase do fim: o que vem depois dos 30 dias está no "A vencer" da obra.
        let ponte = app.elemento("ponteDoAPagar")
        XCTAssertTrue(ponte.exists)
        XCTAssertTrue(ponte.label.hasPrefix("Depois de "), ponte.label)
        XCTAssertTrue(ponte.label.hasSuffix("mais 10 gastos a vencer (R$\u{a0}52.250,00), no \"A vencer\" da obra."), ponte.label)
        let fechar = app.buttons.matching(NSPredicate(format: "label == 'Fechar'")).allElementsBoundByIndex
        XCTAssertEqual(fechar.map(\.identifier), ["fecharFolha"], "só o × se chama Fechar: o botão \"Fechar\" do site sai")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForNonExistence(timeout: 5), "o × fecha")
    }

    func testObraSemVencimentosAbreAFolhaVazia() {
        let app = abrirObra("v2")
        abrirAPagar(app)
        let resumo = app.elemento("resumoDoAPagar")
        XCTAssertTrue(resumo.label.contains("R$\u{a0}0,00"), resumo.label)
        XCTAssertTrue(resumo.label.contains("0 vencimentos · a partir de amanhã"), resumo.label)
        let vazio = app.elemento("aPagarVazio")
        XCTAssertTrue(vazio.exists)
        XCTAssertEqual(vazio.label, "Nenhum gasto previsto para esse período.")
        XCTAssertFalse(app.elemento("ponteDoAPagar").exists, "nada depois dos 30 dias: sem a frase")
        sleep(1)
        XCTAssertTrue(resumo.exists, "vazia, a folha fica aberta")
        puxarFolha(app)
        XCTAssertTrue(resumo.waitForNonExistence(timeout: 5), "puxar fecha, sem perguntar")
    }

    func testAFolhaFechaQuandoOutroAparelhoApagaAObra() {
        let app = abrirObra(extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        abrirAPagar(app)
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.buttons["fecharFolha"].waitForNonExistence(timeout: 10), "a obra sumiu: a folha fecha")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "e a obra volta para a lista")
    }

    // MARK: A volta à folha de origem

    /// O quadro do mockup: a Tinta acrílica (2/3) de R$ 2.300,00 para R$ 2.450,00; o total vai a R$ 13.400,00.
    func testEditarDoAPagarEmpurraAEdicaoESalvarVolta() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        let titulo = app.elemento("tituloDaFolha")
        XCTAssertTrue(titulo.label.hasPrefix("Editar gasto"), titulo.label)
        XCTAssertTrue(titulo.label.hasSuffix("A pagar"), "a origem embaixo do título: \(titulo.label)")
        XCTAssertFalse(app.buttons["fecharFolha"].exists, "sem o ×: o voltar fica no lugar dele")
        XCTAssertFalse(app.buttons["voltarDaEdicao"].exists, "sem mudança, o voltar é o do sistema")
        mudarValor(app, "245000")
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}2.450,00")
        app.buttons["salvarGasto"].tap()
        voltouAoAPagar(app, "Salvar volta ao A pagar")
        let resumo = app.elemento("resumoDoAPagar")
        XCTAssertTrue(resumo.label.contains("R$\u{a0}13.400,00") && resumo.label.contains("3 vencimentos"), resumo.label)
        XCTAssertEqual(naFolha(app, "gasto-g045")?.value as? String, "R$\u{a0}2.450,00", "a linha com o valor novo")
        XCTAssertTrue(app.buttons["fecharFolha"].exists, "e o × da folha de volta")
    }

    /// Na maior letra a lista passa da tela: o "Salvar" volta com a linha no mesmo lugar.
    func testNaMaiorLetraSalvarVoltaNaMesmaRolagem() {
        let app = abrirObra(argumentos: Self.maiorLetra)
        abrirAPagar(app)
        guard let linha = rolarNaFolha(app, ate: "gasto-g045") else { return XCTFail("a Tinta acrílica na folha") }
        let antes = linha.frame.minY
        linha.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5))
        mudarValor(app, "245000")
        app.buttons["salvarGasto"].tap()
        voltouAoAPagar(app, "Salvar volta ao A pagar")
        sleep(1)
        let depois = naFolha(app, "gasto-g045")
        XCTAssertEqual(depois?.value as? String, "R$\u{a0}2.450,00")
        XCTAssertEqual(depois?.frame.minY ?? -1, antes, accuracy: 1, "a lista volta na mesma rolagem")
    }

    /// Na maior letra, o primeiro vencimento com a data trocada para o fim dos 30 dias vai para o fim da lista, fora da vista:
    /// a lista rola o mínimo até ele.
    func testNaMaiorLetraALinhaQueVaiParaOFimFicaAVista() {
        let app = abrirObra(argumentos: Self.maiorLetra + ["-custta.dataDaEdicao", "29"])
        abrirAPagar(app)
        editar(app, "g039")
        app.buttons["salvarGasto"].tap()
        voltouAoAPagar(app, "Salvar volta ao A pagar")
        sleep(1)
        guard let linha = app.descendants(matching: .any).matching(identifier: "gasto-g039").allElementsBoundByIndex.first(where: \.exists)
        else { return XCTFail("a linha continua no A pagar") }
        XCTAssertTrue(app.frame.contains(linha.frame), "a linha que foi para o fim está inteira à vista: \(linha.frame)")
        if let tinta = naFolha(app, "gasto-g045") { XCTAssertLessThan(tinta.frame.minY, linha.frame.minY, "e agora vem depois da Tinta acrílica") }
    }

    func testComMudancaOChevronPerguntaEDescartarVolta() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        XCTAssertEqual(voltarDoSistema(app)?.label, "A pagar · 30 dias")
        mudarDescricao(app)
        let chevron = app.buttons["voltarDaEdicao"]
        XCTAssertTrue(chevron.waitForExistence(timeout: 3), "com mudança, o chevron próprio")
        XCTAssertEqual(chevron.label, "A pagar · 30 dias", "com o rótulo do voltar do sistema")
        XCTAssertNil(voltarDoSistema(app), "no lugar do voltar do sistema")
        chevron.tap()
        let alerta = app.alerts["Você mudou este gasto."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3), "o chevron pergunta")
        XCTAssertTrue(alerta.staticTexts["As mudanças ainda não foram salvas."].exists)
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["salvarGasto"].exists, "continua na edição")
        chevron.tap()
        app.alerts["Você mudou este gasto."].buttons["Descartar mudanças"].tap()
        voltouAoAPagar(app, "Descartar mudanças volta ao A pagar")
        XCTAssertTrue(naFolha(app, "gasto-g045")?.label.hasPrefix("Tinta acrílica, parcela 2 de 3.") == true, "nada foi gravado")
    }

    /// Sem mudança, o voltar do sistema volta (e a borda, com ele).
    func testSemMudancaOVoltarDoSistemaEABordaVoltam() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        XCTAssertFalse(app.buttons["voltarDaEdicao"].exists)
        let voltar = voltarDoSistema(app)
        XCTAssertEqual(voltar?.label, "A pagar · 30 dias", "o voltar do sistema, com o nome da origem")
        voltar?.tap()
        voltouAoAPagar(app, "o voltar do sistema volta ao A pagar")
        editar(app, "g045")
        app.voltarPelaBorda(saindo: app.buttons["salvarGasto"])
        voltouAoAPagar(app, "a borda volta ao A pagar")
    }

    /// Com mudança, o arrasto da borda que passa por cima do "Apagar gasto" pergunta e não toca no botão: com o voltar do
    /// sistema escondido, sem a borda que pergunta, ele virava toque no botão (medido em 19/10).
    func testComMudancaABordaPerguntaSemTocarNoBotaoDeBaixo() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        mudarDescricao(app)
        let apagar = app.buttons["apagarGasto"]
        XCTAssertTrue(apagar.isHittable, "o Apagar gasto à vista")
        let y = apagar.frame.midY
        let origem = app.coordinate(withNormalizedOffset: .zero)
        origem.withOffset(CGVector(dx: 0, dy: y))
            .press(forDuration: 0.05, thenDragTo: origem.withOffset(CGVector(dx: app.frame.width * 0.85, dy: y)))
        let alerta = app.alerts["Você mudou este gasto."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3), "a borda pergunta: \(alertas(app))")
        XCTAssertEqual(alertas(app), ["Você mudou este gasto."], "e não toca no botão de baixo")
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["salvarGasto"].exists, "continua na edição")
        // Descartar pela borda volta ao A pagar, como o chevron.
        origem.withOffset(CGVector(dx: 0, dy: 300)).press(forDuration: 0.05, thenDragTo: origem.withOffset(CGVector(dx: app.frame.width * 0.85, dy: 300)))
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["Descartar mudanças"].tap()
        voltouAoAPagar(app, "Descartar mudanças pela borda volta ao A pagar")
    }

    /// Com mudança (e a borda que pergunta ligada), a rolagem segue: o arrasto vertical rola, no meio e perto da borda.
    func testComMudancaARolagemSegue() {
        let app = abrirObra(argumentos: Self.maiorLetra)
        abrirAPagar(app)
        editar(app, "g045")
        mudarValor(app, "245000")
        XCTAssertTrue(app.buttons["voltarDaEdicao"].waitForExistence(timeout: 3), "com mudança")
        let valor = app.elemento("linhaValor")
        let antes = valor.frame.minY
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)), withVelocity: .slow, thenHoldForDuration: 0.3)
        let meio = valor.frame.minY
        XCTAssertLessThan(meio, antes - 50, "o arrasto no meio rola")
        let borda = app.coordinate(withNormalizedOffset: .zero)
        borda.withOffset(CGVector(dx: 6, dy: app.frame.height * 0.7))
            .press(forDuration: 0.05, thenDragTo: borda.withOffset(CGVector(dx: 6, dy: app.frame.height * 0.45)), withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertLessThan(valor.frame.minY, meio - 50, "o arrasto vertical perto da borda também rola")
        XCTAssertEqual(alertas(app), [], "e nada pergunta")
    }

    func testPuxarComMudancaPerguntaEDescartarFechaTudo() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        mudarDescricao(app)
        puxarFolha(app)
        let alerta = app.alerts["Você mudou este gasto."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 4), "puxar com mudança pergunta")
        XCTAssertTrue(alerta.staticTexts["As mudanças ainda não foram salvas."].exists)
        alerta.buttons["Descartar mudanças"].tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForNonExistence(timeout: 5), "fecha a folha inteira, com o A pagar")
        XCTAssertTrue(app.elemento("tituloDaObra").isHittable, "e mostra a obra")
    }

    func testPuxarSemMudancaFechaTudo() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        puxarFolha(app)
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForNonExistence(timeout: 5), "fecha a folha inteira, sem perguntar")
        XCTAssertEqual(alertas(app), [])
    }

    /// O segundo toque de um toque duplo chega com a edição já voltando: grava uma vez e não derruba o app.
    func testToqueDuploNoSalvarDaEdicaoVoltaUmaVez() {
        let app = abrirObra()
        abrirAPagar(app)
        editar(app, "g045")
        mudarValor(app, "245000")
        app.buttons["salvarGasto"].doubleTap()
        voltouAoAPagar(app, "Salvar volta ao A pagar")
        sleep(1)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.elemento("resumoDoAPagar").label.contains("R$\u{a0}13.400,00"), app.elemento("resumoDoAPagar").label)
        XCTAssertFalse(app.buttons["salvarGasto"].exists, "volta uma vez só, para a lista")
    }

    func testCarregandoNaEdicaoAvisaEFica() {
        let app = abrirObra(argumentos: ["-custta.recusarGravacao", "nao-carregado"])
        abrirAPagar(app)
        editar(app, "g045")
        mudarValor(app, "245000")
        app.buttons["salvarGasto"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["O gasto continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}2.450,00", "o gasto continua na edição")
        XCTAssertTrue(app.buttons["salvarGasto"].exists)
    }

    /// O "Não salvou" de um gasto salvo na edição aparece com a folha de origem aberta (a da raiz espera a folha fechar), e
    /// só sem outro alerta à vista: no iOS 27, um alerta toma o lugar do outro.
    func testNaoSalvouAvisaDentroDaFolhaDeOrigemSemTomarOLugarDeOutroAlerta() {
        let app = abrirObra(gravacao: "recusa", extra: ["CUSTTA_GRAVACAO_ESPERA": "aviso"])
        abrirAPagar(app)
        editar(app, "g045")
        mudarValor(app, "245000")
        app.buttons["salvarGasto"].tap()
        voltouAoAPagar(app, "Salvar volta ao A pagar")
        // Outro alerta à vista quando a recusa chega: a pergunta do chevron, numa edição aberta de novo.
        editar(app, "g032")
        mudarDescricao(app)
        app.buttons["voltarDaEdicao"].tap()
        let pergunta = app.alerts["Você mudou este gasto."]
        XCTAssertTrue(pergunta.waitForExistence(timeout: 3))
        notify_post("br.com.custta.falso.responderGravacao")
        sleep(2)
        XCTAssertEqual(alertas(app), ["Você mudou este gasto."], "o Não salvou espera a pergunta fechar")
        pergunta.buttons["Descartar mudanças"].tap()
        voltouAoAPagar(app, "Descartar mudanças volta ao A pagar")
        let naoSalvou = app.alerts["Não salvou na nuvem"]
        XCTAssertTrue(naoSalvou.waitForExistence(timeout: 5), "o Não salvou aparece dentro da folha de origem: \(alertas(app))")
        naoSalvou.buttons["OK"].tap()
        XCTAssertTrue(naoSalvou.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.elemento("resumoDoAPagar").exists, "e a folha continua aberta")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForNonExistence(timeout: 5))
        XCTAssertFalse(naoSalvou.waitForExistence(timeout: 2), "uma vez só: a cópia da raiz não repete")
    }

    func testGastoApagadoEmOutroAparelhoVoltaAOrigem() {
        let app = abrirObra(extra: ["CUSTTA_APAGAR_REMOTO": "v1/g045@0"])
        abrirAPagar(app)
        editar(app, "g045")
        notify_post("br.com.custta.falso.apagarRemoto")
        voltouAoAPagar(app, "o gasto sumiu: a edição volta ao A pagar, em vez de fechar a folha")
        XCTAssertTrue(app.elemento("resumoDoAPagar").label.contains("2 vencimentos"), app.elemento("resumoDoAPagar").label)
        XCTAssertNil(naFolha(app, "gasto-g045"))
    }
}
