import XCTest

/* Fases e venda (etapa 2, parte 3), com as obras da vitrine: a Casa Alphaville em construção (v1), o Sobrado Granja Viana
   pronto (v2) e a Casa Tamboré 4 vendida (v3). Mudar entre construção e pronta não pergunta; a venda vai em dois passos
   (teclado de valor, depois a data) e grava a fase vendida; desfazer pergunta com o texto do site e volta para pronta. */
@MainActor
final class FasesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testMarcarComoProntaEVoltarPraConstrucaoSemPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        XCTAssertFalse(app.buttons["acao-registrarVenda"].exists, "a construção não se vende")
        app.rolarAte(pronta)
        pronta.tap()
        let voltar = app.buttons["acao-voltarConstrucao"]
        XCTAssertTrue(voltar.waitForExistence(timeout: 5), "pronta: voltar e registrar venda")
        XCTAssertTrue(app.buttons["acao-registrarVenda"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists, "mudar a fase não pergunta (o mudarFase do site)")
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        app.rolarAte(voltar)
        voltar.tap()
        XCTAssertTrue(app.buttons["acao-marcarPronta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
    }

    func testRegistrarVendaEmDoisPassos() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2")
        let vender = app.buttons["acao-registrarVenda"]
        XCTAssertTrue(vender.waitForExistence(timeout: 10))
        app.rolarAte(vender)
        vender.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["confirmarValor"].isEnabled, "\"Avançar\" só com valor")
        for t in ["1", "3", "8", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.380.000,00")
        app.buttons["confirmarValor"].tap()
        let confirmar = app.buttons["confirmarVenda"]
        XCTAssertTrue(confirmar.waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaValorDaVenda").value as? String, "R$\u{a0}1.380.000,00")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Entre o início da obra (")).firstMatch.exists)
        confirmar.tap()
        XCTAssertTrue(confirmar.waitForNonExistence(timeout: 5), "a folha desce")
        XCTAssertTrue(app.buttons["acao-desfazerVenda"].waitForExistence(timeout: 5), "vendida: só desfazer")
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"))
        let venda = app.elemento("indicadorVenda").label
        XCTAssertTrue(venda.contains("R$\u{a0}1.380.000,00") && venda.contains("Vendida em "), venda)
    }

    func testValorDaVendaVoltaAoTecladoPelaLinha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2", argumentos: ["-custta.folha", "detalhes"])
        let linha = app.elemento("linhaValorDaVenda")
        XCTAssertTrue(linha.waitForExistence(timeout: 10))
        linha.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5), "a linha do valor volta ao teclado")
        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.380.000,00")
    }

    func testDesfazerVendaPerguntaComOTextoDoSite() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let desfazer = app.buttons["acao-desfazerVenda"]
        XCTAssertTrue(desfazer.waitForExistence(timeout: 10))
        app.rolarAte(desfazer)
        desfazer.tap()
        let alerta = app.alerts["Desfazer a venda?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["A obra volta pra “Pronta”."].exists)
        alerta.buttons["Cancelar"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"), "cancelar não muda nada")
        app.rolarAte(desfazer)
        desfazer.tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Desfazer venda"].tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("Venda estimada"), "a venda saiu; volta a estimativa")
    }

    func testDescartarVendaDepoisDoValorPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2", argumentos: ["-custta.folha", "detalhes"])
        XCTAssertTrue(app.buttons["confirmarVenda"].waitForExistence(timeout: 10))
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você já preencheu esta venda."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar venda"].tap()
        XCTAssertTrue(app.buttons["confirmarVenda"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"), "nada foi gravado")
    }

    /// Toque duplo no "Confirmar venda": a folha que desce pelo binding ainda aceita o segundo toque (no Salvar do gasto,
    /// ele gravava de novo). A obra fica vendida uma vez, e nada abre nem avisa depois.
    func testToqueDuploNoConfirmarVendaVendeUmaVez() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2", argumentos: ["-custta.folha", "detalhes"])
        let confirmar = app.buttons["confirmarVenda"]
        XCTAssertTrue(confirmar.waitForExistence(timeout: 10))
        confirmar.doubleTap()
        XCTAssertTrue(confirmar.waitForNonExistence(timeout: 5), "a folha desce")
        XCTAssertTrue(app.buttons["acao-desfazerVenda"].waitForExistence(timeout: 5))
        sleep(1)
        XCTAssertFalse(app.alerts.firstMatch.exists, "nenhum aviso")
        XCTAssertFalse(app.elemento("tituloDaFolha").exists, "nenhuma folha abriu por baixo")
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
    }

    /// A data fora do intervalo (na obra que começa no futuro, o calendário só tem hoje): "Confirmar venda" mostra a
    /// mensagem do site e a folha fica, sem gravar. O calendário não deixa escolher essa data: o teste a põe na folha.
    func testDataForaDoIntervaloMostraAMensagemDoSite() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2",
                           argumentos: ["-custta.folha", "detalhes", "-custta.dataDaVenda", "2000-01-01"])
        let confirmar = app.buttons["confirmarVenda"]
        XCTAssertTrue(confirmar.waitForExistence(timeout: 10))
        confirmar.tap()
        let erro = app.elemento("erroDaVenda")
        XCTAssertTrue(erro.waitForExistence(timeout: 5))
        XCTAssertEqual(erro.label, "Data da venda precisa ficar entre o início da obra e hoje")
        XCTAssertTrue(confirmar.exists, "a folha continua aberta")
        app.buttons["fecharFolha"].tap()
        app.alerts["Você já preencheu esta venda."].buttons["Descartar venda"].tap()
        XCTAssertTrue(confirmar.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"), "nada foi gravado")
    }

    /// Gravação recusada antes de ver os dados: "Confirmar venda" avisa com o texto do site e a venda continua na folha,
    /// como no gasto. A recusa da conta de teste (só no TestFlight) usa o mesmo caminho; a guarda Node a confere.
    func testNaoCarregadoAvisaEMantemAVenda() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2",
                           argumentos: ["-custta.folha", "detalhes", "-custta.recusarGravacao", "nao-carregado"])
        let confirmar = app.buttons["confirmarVenda"]
        XCTAssertTrue(confirmar.waitForExistence(timeout: 10))
        confirmar.tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["A venda continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertTrue(confirmar.waitForExistence(timeout: 3), "a venda continua na folha")
        XCTAssertEqual(app.elemento("linhaValorDaVenda").value as? String, "R$\u{a0}1.380.000,00")
    }

    /// "Avançar" marca a venda como preenchida: na data, fechar pergunta antes de descartar. Os testes acima abrem a folha
    /// já na data pelo gancho de Debug, que marca isso sozinho; este passa pelo teclado, como quem vende.
    func testFecharDepoisDeAvancarPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2")
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 10))
        app.buttons["tecla-5"].tap()
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.buttons["confirmarVenda"].waitForExistence(timeout: 5))
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(app.alerts["Você já preencheu esta venda."].waitForExistence(timeout: 5), "depois do valor, fechar pergunta")
    }
}
