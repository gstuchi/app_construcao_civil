import XCTest

/* O orçamento (etapa 3, PR 1), com a vitrine e os orçamentos do mockup aprovado (VitrineDoOrcamento.swift): a linha nos
   indicadores, logo abaixo do Total gasto, nos três níveis do site, por total e por tópico, com o aviso dos tópicos e o que
   está fora; sem orçamento, nenhuma linha; a obra vendida com orçamento mostra a linha, como o site. */
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
        // O grupo começa 10 pt abaixo do Total gasto e o texto da linha, 13 abaixo do alto do grupo (o quadro de acessibilidade
        // da linha começa no texto).
        XCTAssertEqual(orcamento.minY - total.maxY, 10 + 13, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
        XCTAssertLessThanOrEqual(orcamento.maxY, corrigido.minY, "antes do Corrigido")
        XCTAssertEqual(orcamento.minX, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
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
