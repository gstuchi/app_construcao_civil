import XCTest

/* Criar, editar e apagar obra (etapa 2, parte 3). Nova obra pelo + da lista: o cursor no nome e o teclado aberto; a área
   obrigatória com o erro do site, que some ao digitar; o valor estimado no teclado de valor; "Criar obra" entra direto na
   obra nova. Editar pelo lápis da barra; apagar no fim da folha, com o alerta do nome e dos lançamentos, volta à lista e a
   linha sai. O + avisa o teto de 300 obras antes de abrir. */
@MainActor
final class FolhaDaObraUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testCriarObraComOErroDaAreaEEntrarNela() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let mais = app.buttons["botaoMais"]
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 10))
        XCTAssertEqual(mais.label, "Nova obra")
        mais.tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "o cursor no nome e o teclado aberto")
        app.digitarComFoco("Casa Granja Viana 2", em: nome)
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in ["1", "6", "0", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaEstimado").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaEstimado").value as? String, "R$\u{a0}1.600.000,00")
        XCTAssertEqual(app.elemento("linhaOrcamento").value as? String, "Opcional")
        app.buttons["salvarObra"].tap()
        let erro = app.elemento("erroDaArea")
        XCTAssertTrue(erro.waitForExistence(timeout: 5))
        XCTAssertEqual(erro.label, "Informe área construída maior que zero.")
        app.digitarComFoco("280", em: app.textFields["areaDaObra"])
        XCTAssertTrue(erro.waitForNonExistence(timeout: 3), "o erro some ao digitar")
        app.buttons["salvarObra"].tap()
        let titulo = app.elemento("tituloDaObra")
        XCTAssertTrue(titulo.waitForExistence(timeout: 8), "\"Criar obra\" entra direto na obra nova")
        XCTAssertEqual(titulo.label, "Casa Granja Viana 2")
        XCTAssertTrue(app.elemento("obraSemGastos").exists)
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.600.000,00"))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["4 obras"].waitForExistence(timeout: 5), "a obra nova está na lista")
    }

    func testNomeVazioVoltaAoNomeSemMensagem() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra")
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 10))
        app.buttons["salvarObra"].tap()
        XCTAssertFalse(app.elemento("erroDoNome").exists, "sem mensagem, como o site")
        XCTAssertTrue(app.textFields["nomeDaObra"].exists, "a folha continua aberta")
    }

    func testDescartarObraPreenchidaPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra")
        app.digitarComFoco("Casa", em: app.textFields["nomeDaObra"])
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você já preencheu esta obra."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].exists)
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar obra"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3 obras"].exists, "nada foi gravado")
    }

    func testEditarObraPeloLapis() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        XCTAssertEqual(nome.value as? String, "Casa Alphaville")
        XCTAssertEqual(app.textFields["areaDaObra"].value as? String, "300")
        XCTAssertFalse(app.elemento("linhaOrcamento").exists, "sem orçamento na edição")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "editar não abre o teclado sozinho")
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.450.000,00")
        for _ in 0..<9 { app.buttons["tecla-del"].tap() }
        for t in ["1", "5", "0", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.buttons["salvarObra"].waitForExistence(timeout: 5))
        app.buttons["salvarObra"].tap()
        XCTAssertTrue(nome.waitForNonExistence(timeout: 5), "a folha desce e a tela fica na obra")
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.500.000,00"), app.elemento("indicadorVenda").label)
    }

    func testApagarObraVoltaParaAListaEALinhaSai() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
        app.buttons["editarObra"].tap()
        let apagar = app.buttons["apagarObra"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
        apagar.tap()
        let alerta = app.alerts["Apagar “Casa Alphaville”?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Os 46 lançamentos dela serão perdidos. Não dá para desfazer."].exists)
        alerta.buttons["Apagar obra"].tap()
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "volta para a lista")
        XCTAssertTrue(app.elemento("obra-v1").waitForNonExistence(timeout: 5), "a linha sai")
        XCTAssertTrue(app.staticTexts["2 obras"].waitForExistence(timeout: 3))
    }

    func testLimiteDe300ObrasAvisaAntesDeAbrir() {
        let app = abrirApp(conta: "senha", dados: "limite")
        XCTAssertTrue(app.elemento("obra-t1").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        let alerta = app.alerts["Limite de 300 obras"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Apague uma obra antiga para criar outra."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.textFields["nomeDaObra"].exists, "\"Nova obra\" não abre")
    }
}
