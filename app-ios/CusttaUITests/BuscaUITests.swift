import XCTest
import notify

/* A busca e o filtro por mês da lista de lançamentos (etapa 3, PR 3; mockup da parte 2, seção 3): buscar com e sem acento,
   pelo tópico e pela descrição, com o texto aparado; o × que fecha e limpa; o mês pelo menu, o chip e o contador; o mês que
   fica sem gasto e não some (achado 1); "Limpar a busca", "Limpar busca e mês" e "Ver todos os meses"; o filtro que zera ao
   trocar de obra; a obra sem gasto, só com a pílula; a lupa que vira × na maior letra; e a mudança vinda de outro
   aparelho com a busca aberta (achado 3). A busca usa a vitrine (os 46
   lançamentos do mockup; as datas contam de hoje), e o mês, o exemplo (datas fixas: a Casa Alphaville do exemplo tem um
   gasto em março e outro em junho de 2025). */
@MainActor
final class BuscaUITests: XCTestCase {
    private func abrirObra(_ obra: String = "v1", dados: String = "vitrine", argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "obra:\(obra)", argumentos: argumentos)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        return app
    }

    /// A lupa abre o campo já com o teclado; o texto entra nele.
    private func buscar(_ app: XCUIApplication, _ texto: String) {
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa)
        lupa.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "a lupa põe o teclado, sem tocar no campo")
        app.digitarComFoco(texto, em: app.textFields["campoDaBusca"])
    }

    /// O botão do mês abre o menu do sistema; o mês é tocado pelo título (o subtítulo traz quantos gastos ele tem).
    private func escolherMes(_ app: XCUIApplication, _ titulo: String) {
        let mes = app.buttons["filtrarPorMes"]
        app.rolarAte(mes)
        mes.tap()
        let item = itemDoMenu(app, titulo)
        XCTAssertTrue(item.waitForExistence(timeout: 5), "o menu mostra \(titulo)")
        item.tap()
    }

    private func itemDoMenu(_ app: XCUIApplication, _ titulo: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", titulo, titulo + ",")).firstMatch
    }

    /// O rótulo do item do menu para o VoiceOver: no iOS 27, o título e a contagem ("Março de 2025, 0 gastos"). No iOS 26
    /// (sonda do run 40157409790), o item do `Menu` tem `label` só com o título, `value` e `identifier` vazios e nenhum
    /// filho com a contagem: o subtítulo é desenhado (o item com contagem tem 60 pt de altura, contra 42 do "Todos os
    /// meses"), mas não chega à acessibilidade. Lá, o teste confere só o título.
    private func rotuloDoItem(_ titulo: String, _ contagem: String) -> String {
        let ios27 = OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(ios27) ? "\(titulo), \(contagem)" : titulo
    }

    private func pilula(_ app: XCUIApplication) -> String { app.elemento("lancamentos").label }

    /// "ceramica" acha o tópico Cerâmica (os porcelanatos e o contrapiso) e "Telhas de cerâmica" (descrição): 12 de 46, com a
    /// soma deles, e o "A vencer" abre sozinho com os 6 que vêm. Com acento, maiúscula e espaço no fim, o mesmo.
    func testBuscarSemAcentoPeloTopicoEPelaDescricao() {
        let app = abrirObra()
        XCTAssertEqual(pilula(app), "Lançamentos, 46")
        buscar(app, "ceramica")
        XCTAssertEqual(app.textFields["campoDaBusca"].label, "Buscar gasto ou tópico", "o rótulo do campo para o VoiceOver")
        XCTAssertLessThan(app.elemento("lancamentos").frame.minY, 200, "a lista rola até a pílula, com o campo embaixo")
        XCTAssertEqual(pilula(app), "Lançamentos, 12 de 46")
        XCTAssertEqual(app.elemento("somaDosAchados").label, "Soma dos achados: R$\u{a0}95.120,30")
        let aVencer = app.elemento("aVencer")
        XCTAssertEqual(aVencer.value as? String, "aberto", "com filtro, o A vencer abre sozinho")
        XCTAssertTrue(aVencer.label.hasPrefix("A vencer, R$\u{a0}36.900,00, 6 gastos"), aVencer.label)
        XCTAssertTrue(app.elemento("gasto-g032").waitForExistence(timeout: 5), "a parcela que vem, de Cerâmica")
        aVencer.tap()
        XCTAssertEqual(aVencer.value as? String, "fechado", "fechado à mão na busca")

        app.buttons["apagarTextoDaBusca"].tap()
        XCTAssertEqual(pilula(app), "Lançamentos, 46", "o × do texto limpa a busca")
        XCTAssertEqual(aVencer.value as? String, "fechado", "sem filtro, o A vencer como a pessoa o deixou")
        let campo = app.textFields["campoDaBusca"]
        app.digitarComFoco("CERÂMICA ", em: campo)
        XCTAssertEqual(pilula(app), "Lançamentos, 12 de 46", "com acento, maiúscula e espaço no fim, o mesmo")
        XCTAssertEqual(aVencer.value as? String, "aberto", "o filtro novo abre o A vencer de novo")
        campo.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "o \"buscar\" do teclado fecha o teclado")
        XCTAssertEqual(campo.value as? String, "CERÂMICA ", "e a busca fica")
        let telhas = app.elemento("gasto-g016")
        app.rolarAte(telhas)
        XCTAssertTrue(telhas.exists, "Telhas de cerâmica entra pela descrição")
        XCTAssertFalse(app.elemento("gasto-g027").exists, "o cimento não entra")
    }

    /// O × ao lado do campo fecha a busca e limpa o texto: a lista volta inteira, com o "A vencer" fechado como estava.
    func testOXFechaABuscaELimpaOTexto() {
        let app = abrirObra()
        buscar(app, "cimento ")
        XCTAssertEqual(pilula(app), "Lançamentos, 2 de 46", "o espaço no fim não atrapalha (achado 16)")
        app.buttons["fecharBusca"].tap()
        XCTAssertTrue(app.textFields["campoDaBusca"].waitForNonExistence(timeout: 5), "o campo sai")
        XCTAssertEqual(pilula(app), "Lançamentos, 46")
        XCTAssertFalse(app.elemento("somaDosAchados").exists)
        XCTAssertEqual(app.elemento("aVencer").value as? String, "fechado")
        app.buttons["buscar"].tap()
        XCTAssertTrue(app.textFields["campoDaBusca"].waitForExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 46", "aberto de novo, o campo vem vazio")
    }

    /// O menu traz "Todos os meses" e os meses com gasto, do mais novo ao mais antigo, com quantos gastos cada um tem; o mês
    /// escolhido vira um chip, a pílula conta "achados/total", e o menu fica com ele marcado. O × do chip tira o filtro.
    func testOMesPeloMenuViraChipEContaOsAchados() {
        let app = abrirObra("o1", dados: "exemplo")
        let mes = app.buttons["filtrarPorMes"]
        app.rolarAte(mes)
        mes.tap()
        let todos = itemDoMenu(app, "Todos os meses"), junho = itemDoMenu(app, "Junho de 2025"), marco = itemDoMenu(app, "Março de 2025")
        XCTAssertTrue(todos.waitForExistence(timeout: 5))
        XCTAssertEqual(junho.label, rotuloDoItem("Junho de 2025", "1 gasto"))
        XCTAssertLessThan(junho.frame.minY, marco.frame.minY, "do mais novo ao mais antigo")
        XCTAssertTrue(todos.isSelected, "sem filtro, a marca em Todos os meses")
        marco.tap()
        XCTAssertEqual(app.elemento("chipDoMes").label, "Março de 2025")
        XCTAssertEqual(pilula(app), "Lançamentos, 1 de 2")
        XCTAssertEqual(app.elemento("somaDosAchados").label, "Soma dos achados: R$\u{a0}98.000,00")
        XCTAssertTrue(app.elemento("gasto-g1").exists)
        XCTAssertFalse(app.elemento("gasto-g2").exists)
        XCTAssertEqual(mes.value as? String, "Março de 2025")
        mes.tap()
        XCTAssertTrue(itemDoMenu(app, "Março de 2025").waitForExistence(timeout: 5))
        XCTAssertTrue(itemDoMenu(app, "Março de 2025").isSelected, "o menu mantém o mês marcado")
        itemDoMenu(app, "Março de 2025").tap()
        app.buttons["tirarOMes"].tap()
        XCTAssertTrue(app.elemento("chipDoMes").waitForNonExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 2")
    }

    /// Achado 1: com março escolhido, apagar o último gasto dele não esconde o filtro. O chip continua em março, a lista diz
    /// "Nenhum gasto em março de 2025." e oferece "Ver todos os meses"; o menu mantém março marcado, com zero.
    func testMesQueFicaSemGastoNaoSome() {
        let app = abrirObra("o1", dados: "exemplo")
        escolherMes(app, "Março de 2025")
        let linha = app.elemento("gasto-g1")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        // Acima da cápsula, como nos testes da etapa 2: com a linha do orçamento nos indicadores, a lista começa mais embaixo.
        app.rolarAte(linha)
        linha.swipeLeft()
        app.buttons["apagar-g1"].tap()
        app.alerts["Apagar este gasto?"].buttons["Apagar"].tap()
        XCTAssertTrue(app.elemento("buscaMesSemGasto").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("buscaMesSemGasto").label, "Nenhum gasto em março de 2025.")
        XCTAssertEqual(app.elemento("chipDoMes").label, "Março de 2025", "o filtro continua à vista")
        XCTAssertEqual(pilula(app), "Lançamentos, 0 de 1")
        let mes = app.buttons["filtrarPorMes"]
        mes.tap()
        let marco = itemDoMenu(app, "Março de 2025")
        XCTAssertTrue(marco.waitForExistence(timeout: 5), "o mês sem gasto continua no menu")
        XCTAssertEqual(marco.label, rotuloDoItem("Março de 2025", "0 gastos"))
        XCTAssertTrue(marco.isSelected)
        marco.tap()
        let verTodos = app.buttons["verTodosOsMeses"]
        app.rolarAte(verTodos)
        verTodos.tap()
        XCTAssertTrue(app.elemento("chipDoMes").waitForNonExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 1")
        XCTAssertTrue(app.elemento("gasto-g2").exists)
    }

    /// Nada achado: o texto do site, onde a busca olha e "Limpar a busca", que limpa o texto (o campo fica aberto).
    func testNadaEncontradoLimpaABusca() {
        let app = abrirObra()
        buscar(app, "azulejo")
        XCTAssertTrue(app.elemento("buscaNadaEncontrado").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("buscaNadaEncontrado").label, "Nada encontrado com esse filtro.")
        XCTAssertTrue(app.staticTexts["A busca olha a descrição e o tópico, com ou sem acento."].exists)
        XCTAssertEqual(pilula(app), "Lançamentos, 0 de 46")
        let limpar = app.buttons["limparFiltro"]
        XCTAssertEqual(limpar.label, "Limpar a busca")
        limpar.tap()
        XCTAssertEqual(pilula(app), "Lançamentos, 46")
        XCTAssertTrue(app.textFields["campoDaBusca"].exists, "o campo continua aberto")
        XCTAssertTrue(app.elemento("aVencer").exists)
    }

    /// Busca e mês juntos valem em E; o × do chip tira só o mês; sem achado, "Limpar busca e mês" tira os dois.
    func testBuscaEMesJuntosLimpaOsDois() {
        let app = abrirObra("o1", dados: "exemplo")
        escolherMes(app, "Junho de 2025")
        buscar(app, "laje")
        XCTAssertEqual(pilula(app), "Lançamentos, 1 de 2", "a laje é de junho")
        app.buttons["tirarOMes"].tap()
        XCTAssertTrue(app.elemento("chipDoMes").waitForNonExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 1 de 2", "sem o mês, a busca fica")
        XCTAssertEqual(app.textFields["campoDaBusca"].value as? String, "laje")
        escolherMes(app, "Março de 2025")
        XCTAssertEqual(pilula(app), "Lançamentos, 0 de 2", "a laje não é de março")
        let limpar = app.buttons["limparFiltro"]
        XCTAssertTrue(limpar.waitForExistence(timeout: 5))
        XCTAssertEqual(limpar.label, "Limpar busca e mês")
        app.rolarAte(limpar)
        limpar.tap()
        XCTAssertTrue(app.elemento("chipDoMes").waitForNonExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 2")
    }

    /// Obra sem gasto: a pílula sem número (o contador do site) e sem a lupa e o mês, que não teriam o que filtrar.
    func testObraSemGastoSoAPilula() {
        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
        XCTAssertEqual(pilula(app), "Lançamentos")
        XCTAssertFalse(app.buttons["buscar"].exists)
        XCTAssertFalse(app.buttons["filtrarPorMes"].exists)
    }

    /// A obra que fica sem gasto segue com a lupa e o mês enquanto há filtro ou busca: com o mês escolhido, e depois, sem o
    /// mês, com a busca aberta, em que a lupa da maior letra é o × que fecha. Fechada a busca, só a pílula.
    func testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes() {
        let app = abrirObra("o4", dados: "exemplo",
                            argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let lupa = app.buttons["buscar"], mes = app.buttons["filtrarPorMes"]
        app.rolarAte(mes, tentativas: 20)                 // na maior letra, as 12 roladas do padrão chegam sem folga
        escolherMes(app, "Junho de 2023")
        // O chip e a soma dos achados, que o mês põe embaixo dos botões, levam o gasto para baixo da dobra, onde a
        // LazyVStack pode ainda não o ter criado (no iOS 26 da CI, não tinha): espera o chip e rola até a linha.
        XCTAssertTrue(app.elemento("chipDoMes").waitForExistence(timeout: 5))
        let linha = app.elemento("gasto-j1")              // o único gasto da obra
        app.rolarAte(linha)
        XCTAssertTrue(linha.exists, "o gasto, depois de rolar")
        linha.swipeLeft()
        app.buttons["apagar-j1"].tap()
        app.alerts["Apagar este gasto?"].buttons["Apagar"].tap()
        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 5))
        XCTAssertTrue(lupa.exists, "sem gasto, o mês escolhido segura a lupa")
        XCTAssertTrue(mes.exists, "e o mês")
        lupa.tap()
        // O "buscar" do teclado o fecha, e a busca fica aberta. Com o menu tocado enquanto o teclado subia, o app deixou de
        // ficar ocioso, e cada passo seguinte esperou 60 s.
        app.digitarComFoco("\n", em: app.textFields["campoDaBusca"])
        escolherMes(app, "Todos os meses")
        XCTAssertTrue(app.elemento("chipDoMes").waitForNonExistence(timeout: 5))
        XCTAssertTrue(lupa.exists, "sem gasto e sem mês, a busca aberta segura a lupa")
        XCTAssertTrue(mes.exists, "e o mês")
        XCTAssertEqual(lupa.label, "Fechar a busca", "na maior letra, a lupa é o × que fecha a busca")
        lupa.tap()
        XCTAssertTrue(app.textFields["campoDaBusca"].waitForNonExistence(timeout: 5))
        XCTAssertFalse(lupa.exists, "sem gasto, sem mês e sem busca, só a pílula")
    }

    /// O filtro vive só na tela: sai da obra e entra em outra (ou na mesma) sem ele.
    func testFiltroZeraAoTrocarDeObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let v1 = app.elemento("obra-v1"), v2 = app.elemento("obra-v2")
        XCTAssertTrue(v1.waitForExistence(timeout: 10))
        v1.tap()
        buscar(app, "cimento")
        XCTAssertEqual(pilula(app), "Lançamentos, 2 de 46")
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(v2.waitForExistence(timeout: 5))
        v2.tap()
        XCTAssertTrue(app.elemento("lancamentos").waitForExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 5")
        XCTAssertFalse(app.textFields["campoDaBusca"].exists)
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(v1.waitForExistence(timeout: 5))
        v1.tap()
        XCTAssertTrue(app.elemento("lancamentos").waitForExistence(timeout: 5))
        XCTAssertEqual(pilula(app), "Lançamentos, 46", "de volta à mesma obra, sem o filtro")
        XCTAssertFalse(app.textFields["campoDaBusca"].exists)
    }

    /// Achado 3: com a busca aberta e o teclado à vista, outro aparelho apaga um dos achados. A lista e a pílula mudam, e
    /// o texto e o foco ficam no campo.
    func testMudancaDeOutroAparelhoNaoTiraOFocoDaBusca() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1/g027@0"])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        buscar(app, "cimen")
        XCTAssertEqual(pilula(app), "Lançamentos, 2 de 46")
        notify_post("br.com.custta.falso.apagarRemoto")
        let ate = Date.now.addingTimeInterval(10)
        while pilula(app) != "Lançamentos, 1 de 45" && Date.now < ate { usleep(200_000) }
        XCTAssertEqual(pilula(app), "Lançamentos, 1 de 45", "o cimento apagado lá sai da lista")
        let campo = app.textFields["campoDaBusca"]
        XCTAssertEqual(campo.value as? String, "cimen", "o texto fica")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "e o teclado também")
        campo.typeText("to")                            // sem o foco, o XCUITest não digita ("no keyboard focus")
        XCTAssertEqual(campo.value as? String, "cimento")
        XCTAssertEqual(pilula(app), "Lançamentos, 1 de 45")
    }

    /// Na maior letra a pílula e os botões ocupam duas linhas, o campo fica com a largura toda e a própria lupa vira ×.
    func testNaMaiorLetraALupaViraXEOCampoTemALarguraToda() {
        let app = abrirObra(argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let lupa = app.buttons["buscar"], pilula = app.elemento("lancamentos")
        app.rolarAte(lupa, tentativas: 20)                // na maior letra, as 12 roladas do padrão não chegam à lupa
        XCTAssertLessThan(lupa.frame.maxY, app.buttons["aba-obras"].frame.minY, "a lupa acima da cápsula, antes do toque")
        XCTAssertGreaterThan(lupa.frame.minY, pilula.frame.maxY, "os botões descem para a linha de baixo")
        XCTAssertEqual(lupa.frame.width, 64, accuracy: 0.5)
        lupa.tap()
        let campo = app.textFields["campoDaBusca"]
        XCTAssertTrue(campo.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["fecharBusca"].exists, "o × ao lado do campo sai")
        XCTAssertEqual(lupa.label, "Fechar a busca")
        XCTAssertGreaterThan(campo.frame.width, app.frame.width - 110, "o campo com a largura toda")
        lupa.tap()
        XCTAssertTrue(campo.waitForNonExistence(timeout: 5), "a lupa, que virou ×, fecha a busca")
        XCTAssertEqual(lupa.label, "Buscar gasto ou tópico")
    }

    /// Sonda temporária do :59 no iOS 26, que sai depois do run: os passos do testBuscarSemAcentoPeloTopicoEPelaDescricao até
    /// a conferência da pílula, com o gancho `-custta.sonda59` nas quatro combinações (a: a rolagem fixa da obra só com o
    /// `-custta.rolagem`; b: a lupa rola de novo até a pílula no `keyboardDidShow`), 3 vezes cada. Imprime no log, com o
    /// prefixo "sonda-59 |", o minY da pílula na conferência do :59 (que pede < 200) e o que ajuda a ler o salto: o minY antes
    /// do toque, quanto o teclado levou, o campo, o alto do teclado e a pílula 2 s depois. Não confere nada além de o campo
    /// abrir (no `digitarComFoco`).
    func testSondaDoPulo59() {
        let n = { (y: CGFloat) in String(format: "%.1f", y) }
        for combo in ["nenhum", "a", "b", "ab"] {
            for i in 1...3 {
                let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.sonda59", combo])
                _ = app.elemento("tituloDaObra").waitForExistence(timeout: 10)
                let pilula = app.elemento("lancamentos"), lupa = app.buttons["buscar"], campo = app.textFields["campoDaBusca"]
                _ = pilula.label                              // a primeira consulta do :59 ("Lançamentos, 46")
                app.rolarAte(lupa)
                let antes = pilula.frame.minY
                let toque = Date.now
                lupa.tap()
                let teclado = app.keyboards.firstMatch.waitForExistence(timeout: 5)
                let ateOTeclado = Date.now.timeIntervalSince(toque)
                app.digitarComFoco("ceramica", em: campo)
                _ = campo.label                               // o rótulo do campo, conferido no :59 antes da pílula
                let y = pilula.frame.minY
                let quadro = campo.frame, alto = app.keyboards.firstMatch.frame.minY
                sleep(2)
                let depois = pilula.frame.minY
                print("sonda-59 | \(combo) | \(i) | \(n(y)) | antes do toque \(n(antes)) · teclado \(teclado ? "sim" : "não") em "
                      + "\(String(format: "%.2f", ateOTeclado)) s · campo \(n(quadro.minY))–\(n(quadro.maxY)) · alto do teclado "
                      + "\(n(alto)) · 2 s depois \(n(depois))")
            }
        }
    }

    /// Sonda temporária do :215 no iOS 26, que sai depois do run: na o4 do exemplo, "Junho de 2023" escolhido no menu do mês
    /// com os passos do testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes até o chip, primeiro na letra padrão (o
    /// controle) e depois na maior letra. Imprime no log, com o prefixo "sonda-215 |", a hora do toque no mês (desde a
    /// abertura), quanto o toque levou (o XCUITest espera o app ficar ocioso, até 60 s), quanto o chip levou depois dele
    /// (espera de até 90 s) e quanto levou uma consulta barata logo depois. Não confere nada além de o menu abrir.
    func testSondaDoMes215() {
        let s = { (t: TimeInterval) in String(format: "%.2f", t) }
        for (letra, argumentos) in [("padrão", [String]()),
                                    ("maior", ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])] {
            let abertura = Date.now
            let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o4", argumentos: argumentos)
            _ = app.elemento("tituloDaObra").waitForExistence(timeout: 10)
            let mes = app.buttons["filtrarPorMes"]
            app.rolarAte(mes, tentativas: 20)
            app.rolarAte(mes)                                 // o escolherMes do :215 rola de novo (já à vista, sai na hora)
            mes.tap()
            let item = itemDoMenu(app, "Junho de 2023")
            XCTAssertTrue(item.waitForExistence(timeout: 5), "o menu abriu (\(letra))")
            let toque = Date.now
            item.tap()
            let tocou = Date.now
            // Uma linha por passo: com o app travado, a consulta que estoura o tempo encerra o teste, e o que veio antes fica.
            print("sonda-215 | \(letra) | toque aos \(s(toque.timeIntervalSince(abertura))) s da abertura · o toque levou "
                  + "\(s(tocou.timeIntervalSince(toque))) s")
            let chip = app.elemento("chipDoMes").waitForExistence(timeout: 90)
            let veio = Date.now
            print("sonda-215 | \(letra) | chip \(chip ? "sim" : "não"), \(s(veio.timeIntervalSince(tocou))) s depois do toque")
            let valor = mes.value as? String ?? "nil"         // a consulta barata: o valor do botão do mês, já à vista
            print("sonda-215 | \(letra) | consulta \(s(Date.now.timeIntervalSince(veio))) s (filtrarPorMes = \(valor))")
        }
    }
}
