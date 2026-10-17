import XCTest
import notify

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
        // O cursor já está na área, como no site (sem foco em nenhum campo, o typeText falha).
        app.typeText("280")
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

    /// Na maior letra, o erro da área leva o foco à área e o teclado decimal sobe com o botão em cima dele: a folha rola até
    /// a mensagem, que ficava atrás do botão (só o rótulo vermelho à vista).
    func testNaMaiorLetraOErroDaAreaFicaAVista() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra",
                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.digitarComFoco("Casa", em: app.textFields["nomeDaObra"])
        let criar = app.buttons["salvarObra"]
        criar.tap()
        let erro = app.elemento("erroDaArea")
        XCTAssertTrue(erro.waitForExistence(timeout: 5))
        // A folha rola depois que o teclado termina de subir: espera a rolagem.
        let prazo = Date().addingTimeInterval(5)
        while erro.frame.maxY > criar.frame.minY, Date() < prazo { RunLoop.current.run(until: Date().addingTimeInterval(0.3)) }
        XCTAssertLessThanOrEqual(erro.frame.maxY, criar.frame.minY, "a mensagem do erro acima do botão, à vista")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "o foco na área, com o teclado aberto")
    }

    /// Toque duplo no "Criar obra": cria uma obra só e entra nela. Sem a guarda, o segundo toque que chegasse enquanto a
    /// folha desce criaria outra, com outro id (o núcleo não tem como barrar). No simulador, sem a guarda, este teste ainda
    /// passa (o segundo toque não chegou a criar em 9 rodadas, ao contrário do Salvar do gasto): quem prende a guarda é a
    /// guarda Node "folhas que gravam".
    func testToqueDuploNoCriarObraCriaUmaSo() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra", argumentos: ["-custta.folha", "preenchida"])
        let criar = app.buttons["salvarObra"]
        XCTAssertTrue(criar.waitForExistence(timeout: 10))
        criar.doubleTap()
        let titulo = app.elemento("tituloDaObra")
        XCTAssertTrue(titulo.waitForExistence(timeout: 8))
        XCTAssertEqual(titulo.label, "Casa Granja Viana 2")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["4 obras"].waitForExistence(timeout: 5), "uma obra a mais, não duas")
    }

    /// Nos valores opcionais da obra, zero vale no teclado de valor: é como apagar o valor, e a linha volta a "Opcional".
    func testValorEstimadoZeradoVoltaAOpcional() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra", argumentos: ["-custta.folha", "preenchida"])
        let linha = app.elemento("linhaEstimado")
        XCTAssertTrue(linha.waitForExistence(timeout: 10))
        XCTAssertEqual(linha.value as? String, "R$\u{a0}1.600.000,00")
        linha.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for _ in 0..<9 { app.buttons["tecla-del"].tap() }
        let pronto = app.buttons["confirmarValor"]
        XCTAssertTrue(pronto.isEnabled, "no zero, \"Pronto\" apaga o valor")
        pronto.tap()
        XCTAssertTrue(app.elemento("linhaEstimado").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaEstimado").value as? String, "Opcional")
    }

    /// O teto pode encher com a folha aberta (outro aparelho criou obras): "Criar obra" avisa o limite em vez de criar a
    /// 301ª, e a folha continua aberta.
    func testComOTetoCheioCriarObraAvisaOLimite() {
        let app = abrirApp(conta: "senha", dados: "limite", folha: "novaObra", argumentos: ["-custta.folha", "preenchida"])
        let criar = app.buttons["salvarObra"]
        XCTAssertTrue(criar.waitForExistence(timeout: 10))
        criar.tap()
        let alerta = app.alerts["Limite de 300 obras"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.textFields["nomeDaObra"].exists, "a folha continua aberta e nada foi criado")
    }

    func testNomeVazioVoltaAoNomeSemMensagem() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra")
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 10))
        // O cursor sai do nome (a área preenchida), para o "volta ao nome" valer.
        let area = app.textFields["areaDaObra"]
        area.tap()
        area.typeText("280")
        app.buttons["salvarObra"].tap()
        XCTAssertFalse(app.elemento("erroDoNome").exists, "sem mensagem, como o site")
        XCTAssertTrue(app.textFields["nomeDaObra"].exists, "a folha continua aberta")
        // Sem foco em nenhum campo o typeText falha: o que se digita agora entra no nome.
        app.typeText("Casa")
        XCTAssertEqual(app.textFields["nomeDaObra"].value as? String, "Casa", "o cursor volta ao nome, como o site")
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

    /// A linha inteira do grupo é o "Apagar obra", como no mockup: o toque nas pontas, longe do texto, abre o alerta.
    func testApagarObraPelasPontasDaLinha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
        app.buttons["editarObra"].tap()
        let apagar = app.buttons["apagarObra"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
        app.tocarNasPontas(da: apagar, abrindo: app.alerts["Apagar “Casa Alphaville”?"])
    }

    /// Fechar "Editar obra" sem mudar nada não pergunta; com algo mudado, pergunta "Você mudou esta obra.", e "Descartar
    /// alterações" fecha sem gravar.
    func testFecharEditarObraSoPerguntaQuandoAlgoMudou() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(nome.waitForNonExistence(timeout: 5), "nada mudou: fecha sem perguntar")
        lapis.tap()
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        app.buttons["tecla-del"].tap()
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você mudou esta obra."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(nome.exists, "a edição continua aberta")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar alterações"].tap()
        XCTAssertTrue(nome.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.450.000,00"), "nada foi gravado")
    }

    /// Salvar a edição muda só o que a folha mostra: a fase, o início e os lançamentos da obra ficam como estavam.
    func testEditarObraMudaSoOsCamposDaFolha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2")
        let fase = app.elemento("faseDaObra")
        XCTAssertTrue(fase.waitForExistence(timeout: 10))
        let total = app.elemento("indicadorTotal")
        let antes = (fase.label, total.label)
        app.buttons["editarObra"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 5))
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in ["9", "0", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.buttons["salvarObra"].waitForExistence(timeout: 5))
        app.buttons["salvarObra"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}900.000,00"), app.elemento("indicadorVenda").label)
        XCTAssertEqual(fase.label, antes.0, "a fase e o início ficam")
        XCTAssertEqual(total.label, antes.1, "os lançamentos ficam")
    }

    /// A obra apagada em outro aparelho com "Editar obra" aberta e mudada: a folha fecha sem perguntar e sem gravar, e a
    /// tela volta a Obras.
    func testEditarObraFechaQuandoOutroAparelhoApagaAObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        app.buttons["tecla-del"].tap()
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(nome.waitForExistence(timeout: 5), "a edição mudada, antes de o outro aparelho apagar")
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(nome.waitForNonExistence(timeout: 10), "a obra sumiu: a folha fecha")
        XCTAssertFalse(app.alerts["Você mudou esta obra."].exists, "sem perguntar")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "a tela volta a Obras")
        XCTAssertFalse(app.elemento("obra-v1").exists)
        XCTAssertTrue(app.staticTexts["2 obras"].exists)
    }

    /// Apagar pelo lápis grava meio segundo depois de voltar à lista. Se o + abrir "Nova obra" nesse meio-tempo, o aviso
    /// desse apagar (aqui, o de dados não carregados) espera a folha descer: no iOS 27, o alerta da raiz derrubava a folha.
    func testAvisoDoApagarEsperaANovaObraDescer() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
                           argumentos: ["-custta.recusarGravacao", "nao-carregado"], extra: ["CUSTTA_APAGAR_OBRA": "aviso"])
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let apagar = app.buttons["apagarObra"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
        apagar.tap()
        let pergunta = app.alerts["Apagar “Casa Alphaville”?"]
        XCTAssertTrue(pergunta.waitForExistence(timeout: 5))
        pergunta.buttons["Apagar obra"].tap()
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "de volta à lista")
        app.buttons["botaoMais"].tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        notify_post("br.com.custta.falso.apagarObra")
        let aviso = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertFalse(aviso.waitForExistence(timeout: 3), "o aviso espera a folha descer")
        XCTAssertTrue(nome.exists, "\"Nova obra\" continua aberta")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(aviso.waitForExistence(timeout: 5), "com a folha fechada, o aviso aparece")
        aviso.buttons["OK"].tap()
        XCTAssertTrue(aviso.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("obra-v1").exists, "nada foi apagado")
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
