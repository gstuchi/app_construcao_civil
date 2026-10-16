import XCTest

/* Os estados da etapa 2, parte 3, e o gasto numa obra vendida: a lista vazia que convida ao +; o + que avisa enquanto os
   dados não chegam; o gasto lançado de dentro de uma vendida, que vai para uma aberta escolhida na linha "Obra"; sem
   conexão, gravar continua; o "Não salvou" que não passa sozinho alerta uma vez e tocar na pílula tenta de novo. */
@MainActor
final class EstadosUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testListaVaziaConvidaParaOMais() {
        let app = abrirApp(conta: "senha", dados: "vazio")
        let vazio = app.elemento("obrasVazio")
        XCTAssertTrue(vazio.waitForExistence(timeout: 10))
        XCTAssertEqual(vazio.label, "Nenhuma obra ainda.")
        XCTAssertTrue(app.staticTexts["Toque no + para criar a primeira obra."].exists)
        XCTAssertEqual(app.buttons["botaoMais"].label, "Nova obra")
    }

    func testCarregandoOMaisAvisaEmVezDeAbrir() {
        let app = abrirApp(conta: "senha", leitura: "nunca")
        XCTAssertTrue(app.elemento("obrasCarregando").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["OK"].tap()
        XCTAssertFalse(app.textFields["nomeDaObra"].exists, "sem ver os dados, \"Nova obra\" não abre")
    }

    func testMaisNumaObraVendidaLancaNumaAberta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let mais = app.buttons["botaoMais"]
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        XCTAssertEqual(mais.label, "Lançar gasto")
        mais.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in ["1", "3", "8", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        let linha = app.elemento("linhaObra")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Casa Alphaville", "vem a primeira aberta da lista de obras")
        XCTAssertEqual(app.elemento("notaObraVendida").label, "Casa Tamboré 4 está vendida; o gasto vai para uma obra aberta.")
        linha.tap()
        let sobrado = app.buttons["obraAberta-v2"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["obraAberta-v3"].exists, "a vendida não entra na escolha")
        sobrado.tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Sobrado Granja Viana")
        app.buttons["salvarGasto"].tap()
        let titulo = app.elemento("tituloDaObra")
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(titulo.label, "Sobrado Granja Viana", "a folha desce na obra que recebeu o gasto")
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("6 lançamentos"), app.elemento("indicadorTotal").label)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v3").waitForExistence(timeout: 5), "o voltar leva à lista")
    }

    func testGastoDeObraVendidaContinuaEditavel() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let gasto = app.elemento("gasto-v3g3")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.rolarAte(gasto)
        gasto.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "abre \"Editar gasto\"")
        XCTAssertFalse(app.elemento("linhaObra").exists, "editar não troca a obra")
    }

    /// Trocar a obra na linha "Obra" troca os "Usados nesta obra" pelos dela (a Casa Alphaville tem três; o Sobrado, só
    /// "Outros"), e o tópico escolhido fica.
    func testTrocarAObraTrocaOsUsadosNestaObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let linha = lancarDeDentroDaVendida(app)
        let topico = app.elemento("linhaTopico")
        let usados = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'usado-'"))
        topico.tap()
        XCTAssertTrue(usados.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(usados.count, 3, "os três tópicos mais usados na Casa Alphaville")
        usados.element(boundBy: 2).tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        let nome = topico.value as? String
        linha.tap()
        app.buttons["obraAberta-v2"].tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Sobrado Granja Viana")
        XCTAssertEqual(topico.value as? String, nome, "o tópico escolhido fica")
        topico.tap()
        XCTAssertTrue(app.buttons["usado-outros"].waitForExistence(timeout: 5))
        XCTAssertEqual(usados.count, 1, "o Sobrado só usa \"Outros\"")
    }

    /// Toque duplo no "Salvar" da folha lançada de dentro da vendida: um gasto só, na obra escolhida.
    func testToqueDuploNoSalvarDaVendidaLancaUmGasto() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        _ = lancarDeDentroDaVendida(app)
        app.buttons["salvarGasto"].doubleTap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        sleep(1)
        XCTAssertEqual(app.elemento("tituloDaObra").label, "Casa Alphaville")
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("47 lançamentos"), app.elemento("indicadorTotal").label)
    }

    /// Sem nenhuma obra aberta, o + da vendida cria obra, como no site (o formGasto e o + chamam o formNovaObra).
    func testMaisNaVendidaSemObraAbertaCriaObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        apagarPeloLapis(app, "v1")
        app.elemento("obra-v2").tap()
        apagarPeloLapis(app, "v2")
        app.elemento("obra-v3").tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
        let mais = app.buttons["botaoMais"]
        XCTAssertEqual(mais.label, "Nova obra", "nenhuma obra aberta para receber o gasto")
        mais.tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 5), "abre \"Nova obra\"")
        XCTAssertFalse(app.elemento("visorDoValor").exists)
    }

    /// Na Casa Tamboré 4 (vendida): + → o valor no teclado → "Avançar"; devolve a linha "Obra" dos detalhes.
    private func lancarDeDentroDaVendida(_ app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in "100" { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        let linha = app.elemento("linhaObra")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        return linha
    }

    /// "Apagar obra" pelo lápis da obra aberta; volta à lista sem ela.
    private func apagarPeloLapis(_ app: XCUIApplication, _ id: String) {
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let apagar = app.buttons["apagarObra"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
        apagar.tap()
        let alerta = app.alerts.firstMatch
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Apagar obra"].tap()
        XCTAssertTrue(app.elemento("obra-\(id)").waitForNonExistence(timeout: 10), "a obra sai da lista")
    }

    func testSemConexaoGravarContinua() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 10))
        XCTAssertEqual(pilula.label, "Sem conexão")
        let pronta = app.buttons["acao-marcarPronta"]
        app.rolarAte(pronta)
        pronta.tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5), "a fase muda na hora, sem rede")
        XCTAssertEqual(pilula.label, "Sem conexão")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testNaoSalvouAlertaUmaVezETocarTentaDeNovo() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        app.rolarAte(pronta)
        pronta.tap()
        let alerta = app.alerts["Não salvou na nuvem"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Confira sua conexão e conta; toque no aviso para tentar novamente."].exists)
        alerta.buttons["Tentar de novo"].tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3))
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 5))
        XCTAssertFalse(alerta.waitForExistence(timeout: 3), "o mesmo erro não alerta de novo")
        XCTAssertEqual(pilula.label, "Não salvou")
        pilula.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3), "tocar na pílula tenta de novo")
        XCTAssertFalse(alerta.waitForExistence(timeout: 3))
        XCTAssertEqual(pilula.label, "Não salvou")
    }
}
