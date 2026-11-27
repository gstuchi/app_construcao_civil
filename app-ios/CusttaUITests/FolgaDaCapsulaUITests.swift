import XCTest

/* O fim das listas acima da cápsula de abas. A cápsula entra por uma barra própria, e a altura dela não chega à área segura
   da rolagem de dentro do NavigationStack: com só os 34 pt do indicador de início descontados, a última linha de Obras e
   de Ajustes parava 26 pt atrás dela (Verniz, 24/11). Cada tela rola até o fim, e o teste mede o ar entre o fim do
   conteúdo (o elemento mais baixo da rolagem) e o topo da cápsula: 24 pt em Obras e Ajustes, 48 na obra, nos Afazeres, no
   Orçamento e no "Vale a pena?", na letra padrão e na maior (Afazeres, por ora, só na padrão). E a busca da obra com o
   teclado: a cápsula e a lista ficam paradas. */
final class FolgaDaCapsulaUITests: XCTestCase {
    private let parado = ["-custta.reduzirMovimento", "YES"]
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    /// A medida aceita 4 pt para cada lado: o elemento mais baixo pode ter um respiro próprio dentro da linha.
    private let tolerancia: CGFloat = 4

    /// O topo da cápsula: os botões das abas ficam 4 pt para dentro do vidro dela.
    @MainActor private func topoDaCapsula(_ app: XCUIApplication) -> CGFloat {
        app.buttons["aba-obras"].frame.minY - 4
    }

    /// O fim do conteúdo, lido de um retrato só da árvore. Na List (uma collectionView), o maior `maxY` entre as linhas e
    /// o que elas contêm. Na ScrollView, o fim do conteúdo dela, o filho de primeiro nível que não é da altura da tela: o
    /// quadro de um texto pode crescer com o que ele desenha atrás (o halo da versão, em Ajustes, dava 137 pt de altura), e
    /// a árvore traz contêineres da altura da tela, que terminam atrás da cápsula.
    @MainActor private func fimDoConteudo(_ app: XCUIApplication) throws -> CGFloat {
        let lista = app.collectionViews.firstMatch
        if !lista.exists {
            let retrato = try app.scrollViews.firstMatch.snapshot()
            // Pela altura, com 1 pt de folga: o contêiner da altura da tela pode vir com o topo em -1e-13.
            return retrato.children.filter { $0.frame.height > 0 && abs($0.frame.height - retrato.frame.height) > 1 }
                .map(\.frame.maxY).max() ?? 0
        }
        let retrato = try lista.snapshot()
        let borda = retrato.frame.maxY - 1
        var fim: CGFloat = 0
        func varrer(_ no: XCUIElementSnapshot) {
            for filho in no.children {
                let f = filho.frame
                if f.height > 0, f.maxY < borda, filho.elementType != .other || !filho.identifier.isEmpty { fim = max(fim, f.maxY) }
                varrer(filho)
            }
        }
        varrer(retrato)
        return fim
    }

    /// Rola até o fim: arrasta para cima até o fim do conteúdo ficar parado em três leituras seguidas. Com duas, um arrasto
    /// perdido na VM do iOS 26 parava a obra no meio da lista (26.5 do Mac, 4 em 21; o arrasto seguinte voltava a rolar).
    @MainActor private func rolarAteOFim(_ app: XCUIApplication) throws {
        var antes: CGFloat = -1, parados = 0
        for _ in 0..<40 {
            app.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 1)
            let agora = try fimDoConteudo(app)
            if abs(agora - antes) < 0.5 { parados += 1; if parados == 2 { return } } else { parados = 0 }
            antes = agora
        }
        XCTFail("a rolagem não parou no fim")
    }

    /// Abre a tela, rola até o fim e confere o ar entre o fim do conteúdo e a cápsula.
    @MainActor private func conferir(_ nome: String, ar: CGFloat, dados: String, abrir: String? = nil, aba: String? = nil,
                                     espera: String, argumentos: [String] = [], curtaNaLetraPadrao: Bool = false,
                                     soLetraPadrao: Bool = false) throws {
        let letras = [("letra padrão", [String]()), ("maior letra", maiorLetra)]
        for (letra, extra) in soLetraPadrao ? Array(letras.prefix(1)) : letras {
            let app = abrirApp(conta: "senha", dados: dados, abrir: abrir, argumentos: parado + argumentos + extra)
            if let aba { XCTAssertTrue(app.buttons["aba-obras"].waitForExistence(timeout: 30)); app.abrirAba(aba) }
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 30), "\(nome), \(letra): a tela não abriu")
            Thread.sleep(forTimeInterval: 1)
            try rolarAteOFim(app)
            let medido = topoDaCapsula(app) - (try fimDoConteudo(app))
            print(String(format: "folga | %@, %@ | ar %.1f (pedido %.0f)", nome, letra, medido, ar))
            if curtaNaLetraPadrao && extra.isEmpty {
                // A tela cabe inteira: o fim fica acima da cápsula com pelo menos o ar pedido (sobra o que não rolou).
                XCTAssertGreaterThanOrEqual(medido, ar - tolerancia, "\(nome), \(letra): o ar entre o fim da lista e a cápsula")
            } else {
                XCTAssertEqual(medido, ar, accuracy: tolerancia, "\(nome), \(letra): o ar entre o fim da lista e a cápsula")
            }
            app.terminate()
        }
    }

    @MainActor func testObrasTerminaAcimaDaCapsula() throws {
        // As 300 obras do teto, para a lista passar da tela também na letra padrão; a rolagem fixa leva perto do fim.
        try conferir("Obras", ar: 24, dados: "limite", espera: "aba-obras", argumentos: ["-custta.rolagem", "99999"])
    }

    @MainActor func testAjustesTerminaAcimaDaCapsula() throws {
        try conferir("Ajustes", ar: 24, dados: "exemplo", aba: "ajustes", espera: "versao", curtaNaLetraPadrao: true)
    }

    @MainActor func testObraTerminaAcimaDaCapsula() throws {
        try conferir("a obra", ar: 48, dados: "vitrine", abrir: "obra:v1", espera: "tituloDaObra")
    }

    @MainActor func testAfazeresTerminaAcimaDaCapsula() throws {
        // Os afazeres da vitrine cabem na tela na letra padrão. Só a letra padrão: na maior, rolar Afazeres até o fim trava
        // a thread principal do app no iOS 26 da CI, já na main (sondas 46061615607, 46061618851 e 46061622394: 6, 5 e 5 de
        // 9 iterações). A cena volta no PR do conserto de Afazeres.
        try conferir("Afazeres", ar: 48, dados: "vitrine", abrir: "afazeres:v1", espera: "pendentes", curtaNaLetraPadrao: true,
                     soLetraPadrao: true)
    }

    @MainActor func testOrcamentoTerminaAcimaDaCapsula() throws {
        // Na maior letra, os tópicos passam de 6.000 pt: a rolagem fixa leva perto do fim, e os arrastos assentam.
        try conferir("Orçamento", ar: 48, dados: "muitosTopicos", abrir: "orcamento:v1", espera: "editarOrcamento",
                     argumentos: ["-custta.rolagem", "99999"])
    }

    @MainActor func testValeAPenaTerminaAcimaDaCapsula() throws {
        // A obra da análise com o preço da venda estimada: o veredito, a faixa e a tabela passam da tela.
        try conferir("Vale a pena?", ar: 48, dados: "analise", abrir: "aba:valeAPena", espera: "tituloValeAPena")
    }

    /// A busca da obra com o teclado aberto: a cápsula não sobe com ele, e a lista não salta.
    @MainActor func testBuscaComTecladoDeixaCapsulaEListaParadas() throws {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: parado)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 30))
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa)
        Thread.sleep(forTimeInterval: 1)
        let capsulaAntes = topoDaCapsula(app)
        lupa.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "o teclado")
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(topoDaCapsula(app), capsulaAntes, accuracy: 1, "a cápsula fica parada com o teclado")
        // A lista rola, de propósito, até o campo ficar acima do teclado; depois disso, fica parada.
        let campo = app.elemento("campoDaBusca"), teclado = app.keyboards.firstMatch
        XCTAssertTrue(campo.exists, "o campo da busca aberto")
        XCTAssertLessThanOrEqual(campo.frame.maxY, teclado.frame.minY, "o campo fica à vista, acima do teclado")
        let campoAgora = campo.frame.minY
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(campo.frame.minY, campoAgora, accuracy: 1, "a lista fica parada com o teclado aberto")
    }
}
