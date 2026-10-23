import XCTest

final class AjustesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirAjustes(rede: String? = nil) -> XCUIApplication {
        let app = abrirApp(conta: "senha", rede: rede)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testContaESair() {
        let app = abrirAjustes()
        XCTAssertTrue(app.staticTexts["nomeConta"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["nomeConta"].label, "Giovani Stuchi")
        XCTAssertEqual(app.staticTexts["emailConta"].value as? String, "giovani@exemplo.com")
        XCTAssertEqual(app.staticTexts["versao"].label, "Versão 2.0 (1)")
        XCTAssertEqual(app.buttons["sair"].frame.height, 52, accuracy: 0.5, "botão cheio do mockup")
        app.buttons["sair"].tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5), "confirmação pelo alerta do sistema")
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10), "voltou para a tela de entrar")
    }

    @MainActor func testSairSemInternetPedeParaConectar() {
        let app = abrirAjustes(rede: "offline")
        app.buttons["sair"].tap()
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.alerts["Conecte à internet e aguarde a sincronização antes de sair."].waitForExistence(timeout: 10))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["sair"].exists, "continua em Ajustes")
    }

    /// "Enviar confirmação de e-mail" chama o ModeloApp.enviarConfirmacao: texto dos Ajustes do site, não o do aviso.
    @MainActor func testEnviarConfirmacaoComOTextoDosAjustesDoSite() {
        let app = abrirApp(conta: "senha-nao-confirmada")
        app.abrirAba("ajustes")
        let enviar = app.buttons["Enviar confirmação de e-mail"]
        XCTAssertTrue(enviar.waitForExistence(timeout: 5))
        enviar.tap()
        XCTAssertTrue(app.staticTexts["E-mail enviado. Confira também a caixa de spam."].waitForExistence(timeout: 5))
    }

    @MainActor func testSairDoTopoPedeConfirmacaoECancelarFica() {
        let app = abrirApp(conta: "senha")
        let topo = app.buttons["sairTopo"]
        XCTAssertTrue(topo.waitForExistence(timeout: 10))
        topo.tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5), "continua em Obras")
    }

    @MainActor func testCapsulaDeAbasTrocaETemNomeEPosicao() {
        let app = abrirApp(conta: "senha")
        let obras = app.buttons["aba-obras"], ajustes = app.buttons["aba-ajustes"]
        XCTAssertTrue(obras.waitForExistence(timeout: 10))
        XCTAssertTrue(obras.isSelected)
        XCTAssertEqual(obras.label, "Obras")
        XCTAssertEqual(ajustes.value as? String, "2 de 2")
        ajustes.tap()
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        XCTAssertTrue(ajustes.isSelected)
        XCTAssertFalse(app.elemento("obra-o1").exists, "só a aba escolhida fica na tela (e no VoiceOver)")
        obras.tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5))
    }

    /// A cápsula fica 22 pt acima da borda, como a barra de abas do sistema (mockup aprovado), nas duas abas.
    /// Ela tem 4 pt de margem em volta das abas.
    @MainActor func testCapsulaFica22PontosAcimaDaBorda() {
        let app = abrirApp(conta: "senha")
        let obras = app.buttons["aba-obras"]
        XCTAssertTrue(obras.waitForExistence(timeout: 10))
        let base = app.windows.firstMatch.frame.maxY
        XCTAssertEqual(obras.frame.maxY + 4, base - 22, accuracy: 1)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["aba-ajustes"].frame.maxY + 4, base - 22, accuracy: 1)
    }
    /// Ajustes › Aparência (a escolha do vidro, adiantada da etapa 5 para o TestFlight): tocar Fosco grava a escolha deste
    /// aparelho e o app passa ao Fosco na hora, e o "N obras" de Obras deixa a pílula de vidro e vira texto solto
    /// (`VidroTokens.contagemEmPilula`); a escolha fica ao reabrir; o Transparente volta do mesmo jeito. Cada abertura
    /// com os falsos começa no Transparente; `CUSTTA_APARENCIA=manter` guarda a escolha da abertura anterior.
    @MainActor func testEscolhaDoVidroGravaValeNoAppEFicaAoReabrir() {
        var app = abrirAjustes()
        let transparente = app.buttons["vidro-transparente"], fosco = app.buttons["vidro-fosco"]
        XCTAssertTrue(transparente.waitForExistence(timeout: 5))
        XCTAssertEqual(transparente.label, "Transparente")
        XCTAssertEqual(fosco.label, "Fosco")
        XCTAssertEqual(transparente.value as? String, "1 de 2", "a posição que o VoiceOver diz")
        XCTAssertEqual(fosco.value as? String, "2 de 2")
        XCTAssertTrue(transparente.isSelected, "o padrão é o Transparente")
        XCTAssertFalse(fosco.isSelected)
        XCTAssertTrue(app.staticTexts["Transparente mostra mais a aurora atrás dos cartões. Fosco deixa os cartões mais firmes. Vale só neste aparelho."].exists)
        fosco.tap()
        XCTAssertTrue(fosco.isSelected)
        XCTAssertFalse(transparente.isSelected)
        app.abrirAba("obras")
        XCTAssertFalse(contagemEmPilula(app), "no Fosco, o \"4 obras\" é texto solto")

        app.terminate()
        app = abrirApp(conta: "senha", extra: ["CUSTTA_APARENCIA": "manter"])
        XCTAssertFalse(contagemEmPilula(app), "o Fosco ficou ao reabrir")
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["vidro-fosco"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["vidro-fosco"].isSelected)
        app.buttons["vidro-transparente"].tap()
        XCTAssertTrue(app.buttons["vidro-transparente"].isSelected)
        app.abrirAba("obras")
        XCTAssertTrue(contagemEmPilula(app), "de volta ao Transparente, a pílula")

        app.terminate()
        app = abrirApp(conta: "senha", extra: ["CUSTTA_APARENCIA": "manter"])
        XCTAssertTrue(contagemEmPilula(app), "o Transparente ficou ao reabrir")
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["vidro-transparente"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["vidro-transparente"].isSelected)
    }

    /// "Reduzir transparência" no iPhone: as duas doses do vidro ficam desligadas (a escolha não muda) e o aviso diz por quê,
    /// no lugar da nota.
    @MainActor func testReduzirTransparenciaDesligaAsDosesEDizPorQue() {
        let app = abrirApp(conta: "senha", argumentos: ["-custta.reduzirTransparencia", "YES"])
        app.abrirAba("ajustes")
        let transparente = app.buttons["vidro-transparente"], fosco = app.buttons["vidro-fosco"]
        XCTAssertTrue(fosco.waitForExistence(timeout: 5))
        XCTAssertFalse(transparente.isEnabled, "com Reduzir transparência, as doses ficam desligadas")
        XCTAssertFalse(fosco.isEnabled)
        XCTAssertTrue(app.staticTexts["O iPhone está com \u{201C}Reduzir transparência\u{201D} ligado. Enquanto isso, o Custta usa cartões sólidos."].exists)
        XCTAssertFalse(app.staticTexts["Transparente mostra mais a aurora atrás dos cartões. Fosco deixa os cartões mais firmes. Vale só neste aparelho."].exists,
                       "o aviso toma o lugar da nota")
        fosco.tap()
        XCTAssertTrue(transparente.isSelected, "desligada, a dose não troca a escolha")
    }

    /// "Aumentar contraste" no iPhone: as doses seguem ligadas, e o aviso diz que o Fosco com contorno vale.
    @MainActor func testAumentarContrasteDeixaAsDosesLigadasEAvisa() {
        let app = abrirApp(conta: "senha", argumentos: ["-custta.aumentarContraste", "YES"])
        app.abrirAba("ajustes")
        let transparente = app.buttons["vidro-transparente"], fosco = app.buttons["vidro-fosco"]
        XCTAssertTrue(fosco.waitForExistence(timeout: 5))
        XCTAssertTrue(transparente.isEnabled && fosco.isEnabled, "com Aumentar contraste, as doses seguem ligadas")
        XCTAssertTrue(app.staticTexts["Com \u{201C}Aumentar contraste\u{201D} ligado no iPhone, o Custta usa o vidro fosco com contorno."].exists)
    }

    /// Ajustes › Aparência, o tema: o segmentado "Escuro | Claro" troca o esquema do app na hora (o fundo da tela passa do
    /// verde quase preto ao claro) e a escolha fica ao reabrir; o Escuro volta do mesmo jeito.
    @MainActor func testEscolhaDoTemaTrocaNaHoraEFicaAoReabrir() {
        var app = abrirApp(conta: "senha", argumentos: ["-custta.reduzirMovimento", "YES"])
        app.abrirAba("ajustes")
        let escuro = app.buttons["tema-Escuro"], claro = app.buttons["tema-Claro"]
        XCTAssertTrue(escuro.waitForExistence(timeout: 5))
        XCTAssertTrue(escuro.isSelected, "o padrão é o Escuro")
        XCTAssertFalse(claro.isSelected)
        XCTAssertLessThan(brilhoDoFundo(app), 0.3, "escuro")
        claro.tap()
        XCTAssertTrue(claro.isSelected)
        XCTAssertGreaterThan(brilhoDoFundo(app), 0.6, "o Claro vale na hora")

        app.terminate()
        app = abrirApp(conta: "senha", argumentos: ["-custta.reduzirMovimento", "YES"], extra: ["CUSTTA_APARENCIA": "manter"])
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["tema-Claro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tema-Claro"].isSelected, "o Claro ficou ao reabrir")
        XCTAssertGreaterThan(brilhoDoFundo(app), 0.6)
        app.buttons["tema-Escuro"].tap()
        XCTAssertTrue(app.buttons["tema-Escuro"].isSelected)
        XCTAssertLessThan(brilhoDoFundo(app), 0.3, "de volta ao Escuro")

        app.terminate()
        app = abrirApp(conta: "senha", argumentos: ["-custta.reduzirMovimento", "YES"], extra: ["CUSTTA_APARENCIA": "manter"])
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["tema-Escuro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tema-Escuro"].isSelected, "o Escuro ficou ao reabrir")
        XCTAssertLessThan(brilhoDoFundo(app), 0.3)
    }

    /// Brilho médio (0 a 1) da margem esquerda da tela (os 10 pt antes dos painéis), da metade da tela até a cápsula de
    /// abas, onde só há o fundo: o Fundo do tema (#04100C no escuro, #EDF5F1 no claro) com a aurora por cima.
    @MainActor private func brilhoDoFundo(_ app: XCUIApplication) -> Double {
        Thread.sleep(forTimeInterval: 1)                               // a troca de esquema assenta
        let print = Retrato(app.screenshot().image.cgImage!)
        let escala = Double(print.largura) / Double(app.frame.width)
        let topo = Int(app.frame.height / 2 * escala)
        let base = Int((app.buttons["aba-obras"].frame.minY - 12) * escala)
        let largura = Int(10 * escala)
        var soma = 0.0
        for y in topo..<base {
            for x in 0..<largura {
                let i = (y * print.largura + x) * 4
                soma += (Double(print.rgba[i]) + Double(print.rgba[i + 1]) + Double(print.rgba[i + 2])) / (3 * 255)
            }
        }
        return soma / Double((base - topo) * largura)    // medido: 0,085 no escuro e 0,889 no claro
    }

    /// O "4 obras" na pílula de vidro (Transparente) tem 6 pt de recuo em cima e embaixo; solto (Fosco), só o texto.
    @MainActor private func contagemEmPilula(_ app: XCUIApplication) -> Bool {
        let contagem = app.staticTexts["4 obras"]
        XCTAssertTrue(contagem.waitForExistence(timeout: 10), "a contagem de Obras")
        return contagem.frame.height > 24      // 30 pt na pílula, 18 solto (letra padrão)
    }
}

