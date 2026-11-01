import XCTest

/* A costura das telas da análise (etapa 4, PR 1c). A obra não tem porta para elas: os Gráficos e o Relatório só abrem pela
   abertura de Debug (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`), empurrados sobre a obra quando os dados chegam, como
   num toque na porta, numa tela provisória com o título na barra e o nome da obra. O voltar leva à obra e, dela, a Obras; o
   + da cápsula lança gasto na obra da tela (confirmação 6). As telas de verdade trocam a provisória no 2a e no 3a. */
@MainActor
final class AnaliseUITests: XCTestCase {
    /// Abre a tela da análise pelo gancho e confere o título, a obra e o + da cápsula.
    private func abrir(_ gancho: String, titulo: String, obra: String) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: gancho)
        XCTAssertTrue(app.navigationBars[titulo].waitForExistence(timeout: 10), "a tela \(titulo)")
        XCTAssertEqual(app.elemento("obraDaAnalise").label, obra)
        XCTAssertEqual(app.buttons["botaoMais"].label, "Lançar gasto", "o + lança gasto na obra da tela")
        return app
    }

    func testGraficosAbremSobreAObraEVoltamParaEla() {
        let app = abrir("graficos:v1", titulo: "Gráficos", obra: "Casa Alphaville")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o voltar leva à obra")
        XCTAssertFalse(app.navigationBars["Gráficos"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "e a obra, a Obras")
    }

    func testRelatorioAbreSobreAObraEVoltaParaEla() {
        let app = abrir("relatorio:v3", titulo: "Relatório", obra: "Casa Tamboré 4")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o voltar leva à obra")
        XCTAssertFalse(app.navigationBars["Relatório"].exists)
    }
}
