import XCTest
import notify

/* O orçamento (etapa 3, PR 1), com a vitrine e os orçamentos do mockup aprovado (VitrineDoOrcamento.swift): a linha nos
   indicadores, logo abaixo do Total gasto, nos três níveis do site, por total e por tópico, com o aviso dos tópicos e o que
   está fora; sem orçamento, nenhuma linha; a obra vendida com orçamento mostra a linha, como o site. A linha abre a tela
   Orçamento: o cartão, o "Por tópico" com as frases do site e o que está fora; no modo total, o gasto por tópico e a dica. */
@MainActor
final class OrcamentoUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// A linha da Casa Alphaville com o orçamento dado: o rótulo de acessibilidade junta os textos dela.
    private func linha(_ dados: String, obra: String = "v1") -> (XCUIApplication, String) {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "obra:\(obra)")
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 10), "\(dados): a linha do orçamento")
        return (app, linha.label)
    }

    func testLinhaPorTotalNosTresNiveis() {
        let casos = [
            ("vitrine", ["Orçamento", "dentro do previsto", "sobra", "R$\u{a0}357.682,55", "70% usado de R$\u{a0}1.200.000,00"]),
            ("perto", ["perto do limite", "sobra", "R$\u{a0}77.682,55", "92% usado de R$\u{a0}920.000,00"]),
            ("passou", ["passou do previsto", "passou, R$\u{a0}42.317,45", "105% usado de R$\u{a0}800.000,00"]),
        ]
        for (dados, textos) in casos {
            let (app, rotulo) = linha(dados)
            for texto in textos { XCTAssertTrue(rotulo.contains(texto), "\(dados): \"\(texto)\" em \"\(rotulo)\"") }
            XCTAssertFalse(rotulo.contains("tópico"), "\(dados): por total, sem o aviso dos tópicos: \(rotulo)")
            app.terminate()
        }
    }

    func testLinhaPorTopicoComOAvisoEOQueEstaFora() {
        let (_, rotulo) = linha("porTopico")
        for texto in ["dentro do previsto", "R$\u{a0}207.310,90", "80% usado de R$\u{a0}1.019.847,85", "2 tópicos passaram do previsto",
                      "R$ 30 mil fora do orçamento"] {
            XCTAssertTrue(rotulo.contains(texto), "\"\(texto)\" em \"\(rotulo)\"")
        }
    }

    /// A primeira linha do grupo dos indicadores: logo abaixo do Total gasto, que não sai do lugar, e antes do Corrigido.
    func testALinhaVemLogoAbaixoDoTotalGasto() {
        let (app, _) = linha("porTopico")
        let total = app.elemento("indicadorTotal").frame, orcamento = app.elemento("indicadorOrcamento").frame
        let corrigido = app.elemento("indicadorCorrigido").frame
        // O grupo começa 10 pt abaixo do Total gasto, e a linha inteira é o botão que abre a tela Orçamento: o quadro dela começa
        // no alto e na borda do grupo, 18 pt antes do texto do Corrigido (o quadro de uma linha sem toque começa no texto).
        XCTAssertEqual(orcamento.minY - total.maxY, 10, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
        XCTAssertLessThanOrEqual(orcamento.maxY, corrigido.minY, "antes do Corrigido")
        XCTAssertEqual(orcamento.minX + 18, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
    }

    func testSemOrcamentoNenhumaLinha() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("indicadorCorrigido").waitForExistence(timeout: 10))
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists)
    }

    /// Como no site: a obra vendida com orçamento continua mostrando como ele fechou.
    func testVendidaComOrcamentoMostraALinha() {
        let (_, rotulo) = linha("porTopico", obra: "v3")
        XCTAssertTrue(rotulo.contains("perto do limite") && rotulo.contains("98% usado de R$\u{a0}1.000.000,00"), rotulo)
    }
}


extension OrcamentoUITests {
    /// A linha abre a tela Orçamento (push do sistema, no caminho de Obras), que volta pelo círculo e pela borda.
    func testLinhaAbreATelaOrcamentoQueVoltaPeloCirculoEPelaBorda() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "obra:v1")
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 10))
        linha.tap()
        let titulo = app.elemento("tituloDoOrcamento")
        XCTAssertTrue(titulo.waitForExistence(timeout: 5), "a tela Orçamento abriu")
        XCTAssertEqual(titulo.label, "Orçamento")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o círculo volta para a obra")
        linha.tap()
        XCTAssertTrue(titulo.waitForExistence(timeout: 5))
        app.voltarPelaBorda(saindo: titulo)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a borda volta para a obra")
    }

    /// O cartão do site com o que o mockup acrescenta: os tópicos previstos e a frase do que está fora (achado 10).
    func testCartaoPorTopico() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        let cartao = app.elemento("cartaoDoOrcamento")
        XCTAssertTrue(cartao.waitForExistence(timeout: 10))
        for texto in ["Orçamento por tópico", "dentro do previsto", "R$\u{a0}812.536,95", "de R$\u{a0}1.019.847,85 previstos em 14 tópicos",
                      "80% usado", "sobra", "R$\u{a0}207.310,90", "Os R$\u{a0}29.780,50 fora do orçamento não entram nesta conta."] {
            XCTAssertTrue(cartao.label.contains(texto), "\"\(texto)\" em \"\(cartao.label)\"")
        }
        XCTAssertTrue(app.elemento("porTopico").label.contains("14"), app.elemento("porTopico").label)
    }

    /// "Por tópico" com as frases do site, na ordem do site (quem gastou mais do previsto primeiro), e uma linha por tópico
    /// fora do orçamento. Neste PR as linhas não abrem nada: nenhuma é botão.
    func testPorTopicoComAsFrasesDoSiteEOsTopicosFora() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
        let casos = [
            ("estrutura", ["Estrutura", "R$ 91 mil", "/ 85 mil", "Passou R$ 6,2 mil do previsto"]),
            ("fundacao", ["Fundação", "R$ 64 mil", "/ 60 mil", "Passou R$ 4,2 mil do previsto"]),
            ("terreno", ["Terreno", "R$ 320 mil", "/ 320 mil", "Chegou ao previsto — 100%"]),
            ("revest", ["Cerâmica", "R$ 77 mil", "/ 80 mil", "Faltam R$ 3,3 mil — 96%"]),
        ]
        var anterior: CGFloat = 0
        for (id, textos) in casos {
            let linha = app.elemento("topicoOrc-\(id)")
            app.rolarAte(linha)
            for texto in textos { XCTAssertTrue(linha.label.contains(texto), "\(id): \"\(texto)\" em \"\(linha.label)\"") }
            XCTAssertGreaterThan(linha.frame.minY, anterior, "\(id) na ordem do site")
            anterior = linha.frame.minY
            XCTAssertFalse(app.buttons["topicoOrc-\(id)"].exists, "\(id): neste PR a linha não abre o detalhe")
        }
        let acabamento = app.elemento("topicoOrc-acabamento")
        app.rolarAte(acabamento)
        XCTAssertTrue(acabamento.label.contains("R$\u{a0}0,00") && acabamento.label.contains("/ 60 mil"), acabamento.label)
        XCTAssertFalse(acabamento.label.contains("Faltam"), "dentro do previsto, sem frase")
        let fora = app.elemento("foraDoOrcamento")
        app.rolarAte(app.elemento("foraOrc-pintura"))
        XCTAssertTrue(fora.label.contains("Fora do orçamento") && fora.label.contains("R$\u{a0}29.780,50"), fora.label)
        XCTAssertTrue(app.staticTexts["Tópico sem valor não entra na comparação."].exists)
        for (id, nome, gasto) in [("projeto", "Documentação", "R$ 23 mil"), ("pintura", "Pintura", "R$ 6,9 mil")] {
            let linha = app.elemento("foraOrc-\(id)")
            XCTAssertTrue(linha.label.contains(nome) && linha.label.contains(gasto), linha.label)
            XCTAssertFalse(app.buttons["foraOrc-\(id)"].exists, "\(id): neste PR a linha não abre o detalhe")
        }
        XCTAssertLessThan(app.elemento("foraOrc-projeto").frame.minY, app.elemento("foraOrc-pintura").frame.minY, "do maior gasto ao menor")
    }

    /// No modo total não há "Por tópico": o "Gasto por tópico" (bruto e % da obra) e, no fim, a dica do lápis.
    func testModoTotalComOGastoPorTopicoEADica() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "orcamento:v1")
        let cartao = app.elemento("cartaoDoOrcamento")
        XCTAssertTrue(cartao.waitForExistence(timeout: 10))
        XCTAssertTrue(cartao.label.contains("Orçamento total") && cartao.label.contains("de R$\u{a0}1.200.000,00"), cartao.label)
        XCTAssertFalse(cartao.label.contains("previstos em"), "no modo total, só o \"de R$ …\" do site")
        XCTAssertFalse(app.elemento("porTopico").exists)
        XCTAssertTrue(app.elemento("gastoPorTopico").label.contains("14"), app.elemento("gastoPorTopico").label)
        let terreno = app.elemento("gastoTopico-terreno"), estrutura = app.elemento("gastoTopico-estrutura")
        XCTAssertTrue(terreno.label.contains("Terreno") && terreno.label.contains("R$ 320 mil") && terreno.label.contains("38% da obra"),
                      terreno.label)
        XCTAssertLessThan(terreno.frame.minY, estrutura.frame.minY, "do maior bruto para o menor")
        XCTAssertFalse(app.buttons["gastoTopico-terreno"].exists, "neste PR a linha não abre o detalhe")
        let dica = app.elemento("dicaDoModoTotal")
        app.rolarAte(dica)
        XCTAssertEqual(dica.label, "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
    }

    /// A obra apagada em outro aparelho com a tela Orçamento aberta: a tela Orçamento e a obra saem, e volta a lista de Obras.
    func testTelaOrcamentoVoltaParaObrasQuandoOutroAparelhoApagaAObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.elemento("tituloDoOrcamento").waitForNonExistence(timeout: 10), "a tela Orçamento saiu")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "de volta à lista de Obras")
        XCTAssertFalse(app.elemento("tituloDaObra").exists, "sem a obra apagada no caminho")
        XCTAssertFalse(app.elemento("obra-v1").exists)
    }

    /// Dentro da tela Orçamento, o + lança gasto na obra dela.
    func testMaisNaTelaOrcamentoLancaGastoNaObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
        let mais = app.buttons["botaoMais"]
        XCTAssertEqual(mais.label, "Lançar gasto")
        mais.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Valor do gasto"), "a folha do gasto novo, da obra do orçamento")
    }
}
