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
    /// aparelho e o app passa ao Fosco na hora; a escolha fica ao reabrir; o Transparente volta do mesmo jeito. A prova é
    /// relativa, pelo print do painel da Conta, logo abaixo (o mesmo conteúdo e o mesmo lugar nas duas doses; só o vidro
    /// muda): o do Fosco difere do do Transparente por uma margem clara, e cada volta à mesma dose dá o mesmo painel. Nada de
    /// valor absoluto do vidro, que muda do iOS 26 para o 27, nem do quadro de acessibilidade da contagem de Obras, que no
    /// iOS 26 não inclui o recuo da pílula (run 40040611692); e nada de cartão de Obras, que a contagem sem pílula do Fosco
    /// desloca (só o deslocamento já dava 2,3 de diferença, com o vidro do Fosco desenhado como o do Transparente). Cada
    /// abertura com os falsos começa no Transparente; `CUSTTA_APARENCIA=manter` guarda a escolha.
    @MainActor func testEscolhaDoVidroGravaValeNoAppEFicaAoReabrir() {
        let parado = ["-custta.reduzirMovimento", "YES"]
        var app = abrirApp(conta: "senha", argumentos: parado)
        app.abrirAba("ajustes")
        let transparente = app.buttons["vidro-transparente"], fosco = app.buttons["vidro-fosco"]
        XCTAssertTrue(transparente.waitForExistence(timeout: 5))
        XCTAssertEqual(transparente.label, "Transparente")
        XCTAssertEqual(fosco.label, "Fosco")
        XCTAssertEqual(transparente.value as? String, "1 de 2", "a posição que o VoiceOver diz")
        XCTAssertEqual(fosco.value as? String, "2 de 2")
        XCTAssertTrue(transparente.isSelected, "o padrão é o Transparente")
        XCTAssertFalse(fosco.isSelected)
        XCTAssertTrue(app.staticTexts["Transparente mostra mais a aurora atrás dos cartões. Fosco deixa os cartões mais firmes. Vale só neste aparelho."].exists)
        let noTransparente = painelDaConta(app)
        fosco.tap()
        XCTAssertTrue(fosco.isSelected)
        XCTAssertFalse(transparente.isSelected)
        let noFosco = painelDaConta(app)
        let entreAsDoses = diferenca(noTransparente, noFosco)
        XCTAssertGreaterThan(entreAsDoses, 1, "no Fosco, o vidro do painel muda na hora")

        app.terminate()
        app = abrirApp(conta: "senha", argumentos: parado, extra: ["CUSTTA_APARENCIA": "manter"])
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["vidro-fosco"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["vidro-fosco"].isSelected)
        XCTAssertLessThan(diferenca(painelDaConta(app), noFosco), entreAsDoses / 3, "o Fosco ficou ao reabrir")
        app.buttons["vidro-transparente"].tap()
        XCTAssertTrue(app.buttons["vidro-transparente"].isSelected)
        XCTAssertLessThan(diferenca(painelDaConta(app), noTransparente), entreAsDoses / 3, "de volta ao Transparente")

        app.terminate()
        app = abrirApp(conta: "senha", argumentos: parado, extra: ["CUSTTA_APARENCIA": "manter"])
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["vidro-transparente"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["vidro-transparente"].isSelected)
        XCTAssertLessThan(diferenca(painelDaConta(app), noTransparente), entreAsDoses / 3, "o Transparente ficou ao reabrir")
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

    /// O painel da Conta no print, do nome ao fim do "Sair da conta", nas margens de dentro do painel (16 + 4 pt de cada lado).
    @MainActor private func painelDaConta(_ app: XCUIApplication) -> (largura: Int, altura: Int, rgb: [UInt8]) {
        let nome = app.staticTexts["nomeConta"], sair = app.buttons["sair"]
        XCTAssertTrue(sair.waitForExistence(timeout: 10), "o painel da Conta")
        Thread.sleep(forTimeInterval: 1.5)                             // o vidro e a mola do anel assentam
        let print = Retrato(app.screenshot().image.cgImage!)
        let escala = CGFloat(print.largura) / app.frame.width
        let quadro = CGRect(x: 20, y: nome.frame.minY, width: app.frame.width - 40, height: sair.frame.maxY - nome.frame.minY)
        let x0 = Int((quadro.minX * escala).rounded()), y0 = Int((quadro.minY * escala).rounded())
        let largura = Int(quadro.width * escala), altura = Int(quadro.height * escala)
        var rgb: [UInt8] = []
        rgb.reserveCapacity(largura * altura * 3)
        for y in y0..<(y0 + altura) {
            for x in x0..<(x0 + largura) {
                let i = (y * print.largura + x) * 4
                rgb += [print.rgba[i], print.rgba[i + 1], print.rgba[i + 2]]
            }
        }
        return (largura, altura, rgb)
    }

    /// Diferença média por canal (0 a 255) entre dois recortes, na parte que os dois têm.
    private func diferenca(_ a: (largura: Int, altura: Int, rgb: [UInt8]), _ b: (largura: Int, altura: Int, rgb: [UInt8])) -> Double {
        let largura = min(a.largura, b.largura), altura = min(a.altura, b.altura)
        var soma = 0
        for y in 0..<altura {
            for x in 0..<largura {
                for c in 0..<3 { soma += abs(Int(a.rgb[(y * a.largura + x) * 3 + c]) - Int(b.rgb[(y * b.largura + x) * 3 + c])) }
            }
        }
        let media = Double(soma) / Double(largura * altura * 3)
        Swift.print(String(format: "vidro | diferença do painel %.2f", media))
        return media
    }
}

