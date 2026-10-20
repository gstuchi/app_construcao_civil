import XCTest
import notify

/* A folha "Orçamento da obra" (etapa 3, PR 1): definir por total e por tópico (com ‹ › e "Pronto"), trocar de modo com o
   total vazio, salvar vazio, tirar e o caminho de volta para a obra, o teto do teclado, a folha na maior letra e a rolagem até
   a linha ativa nas 71 linhas. Com a vitrine e os orçamentos do mockup (VitrineDoOrcamento.swift). */
private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

extension OrcamentoUITests {
    /// A Casa Alphaville sem orçamento: "Definir orçamento" nas ações da fase abre a folha. Na maior letra, as ações ficam longe
    /// do alto e a lista preguiçosa só monta o botão perto da vista: rola antes de procurar.
    private func definir(_ app: XCUIApplication) {
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let definir = app.buttons["definirOrcamento"]
        app.rolarAte(definir)
        XCTAssertTrue(definir.exists)
        definir.tap()
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
    }

    private func digitar(_ app: XCUIApplication, _ teclas: String) {
        for t in teclas { app.buttons["tecla-\(t)"].tap() }
    }

    /// A tela Orçamento da obra e o lápis dela.
    private func editarPeloLapis(_ app: XCUIApplication) {
        let lapis = app.buttons["editarOrcamento"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
    }

    /// Sem orçamento, "Definir orçamento" aparece na obra em construção e na pronta; na vendida, não (achado 5, como o site).
    func testDefinirOrcamentoForaDaVendida() {
        // A ação da fase de cada obra, montada junto com o "Definir" (o mesmo grupo): à vista ela, o "Definir" também estaria.
        for (obra, acao, aparece) in [("v1", "acao-marcarPronta", true), ("v2", "acao-registrarVenda", true), ("v3", "acao-desfazerVenda", false)] {
            let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:\(obra)")
            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
            app.rolarAte(app.buttons[acao])
            XCTAssertTrue(app.buttons[acao].exists, obra)
            XCTAssertEqual(app.buttons["definirOrcamento"].exists, aparece, obra)
            app.terminate()
        }
    }

    /// "Definir": "Só o total", com as teclas já abertas, sem a barra, o "Salvar" apagado até ter valor e sem "Tirar
    /// orçamento"; salvar mostra a linha na obra, e o "Definir" sai das ações.
    func testDefinirPorTotal() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        XCTAssertTrue(app.buttons["modoDoOrcamento-Só o total"].isSelected)
        XCTAssertTrue(app.buttons["tecla-1"].exists, "as teclas já abertas")
        XCTAssertFalse(app.buttons["barraDasTeclas-pronto"].exists, "no \"Só o total\", sem a barra")
        XCTAssertFalse(app.buttons["tirarOrcamento"].exists, "sem orçamento, nada a tirar")
        let salvar = app.buttons["salvarOrcamento"]
        XCTAssertFalse(salvar.isEnabled, "o \"Salvar\" apagado até ter valor")
        digitar(app, "120000000")
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.200.000,00")
        XCTAssertTrue(salvar.isEnabled)
        salvar.tap()
        XCTAssertTrue(salvar.waitForNonExistence(timeout: 5), "a folha desce")
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertTrue(linha.label.contains("70% usado de R$\u{a0}1.200.000,00"), linha.label)
        XCTAssertFalse(app.buttons["definirOrcamento"].exists, "com orçamento, o \"Definir\" sai")
    }

    /// Por tópico: tocar numa linha abre as teclas nela; ‹ › andam pelas linhas sem fechar as teclas; "Pronto" fecha; o
    /// total ao vivo e o que vai para a obra.
    func testDefinirPorTopicoComAsSetas() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        app.buttons["modoDoOrcamento-Por tópico"].tap()
        XCTAssertFalse(app.buttons["tecla-1"].exists, "trocar de modo fecha as teclas")
        XCTAssertFalse(app.buttons["salvarOrcamento"].isEnabled, "sem orçamento e nada com valor")
        app.elemento("linhaOrc-terreno").tap()
        let nome = app.staticTexts["barraDasTeclas-nome"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        XCTAssertEqual(nome.label, "Terreno · 1 de 21")
        digitar(app, "32000000")
        app.buttons["barraDasTeclas-proximo"].tap()
        XCTAssertEqual(nome.label, "Documentação · 2 de 21")
        digitar(app, "1000000")
        app.buttons["barraDasTeclas-anterior"].tap()
        XCTAssertEqual(nome.label, "Terreno · 1 de 21")
        app.buttons["barraDasTeclas-anterior"].tap()
        XCTAssertEqual(nome.label, "Terreno · 1 de 21", "na primeira linha, ‹ não faz nada")
        XCTAssertEqual(app.elemento("linhaOrc-projeto").value as? String, "R$\u{a0}10.000,00")
        let total = app.elemento("totalDoOrcamento").label
        XCTAssertTrue(total.contains("R$\u{a0}330.000,00") && total.contains("2 de 21 tópicos com valor"), total)
        app.buttons["barraDasTeclas-pronto"].tap()
        XCTAssertFalse(app.buttons["tecla-1"].exists, "\"Pronto\" fecha as teclas")
        app.buttons["salvarOrcamento"].tap()
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertTrue(linha.label.contains("passou do previsto") && linha.label.contains("1 tópico passou do previsto"), linha.label)
    }

    /// Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos (a frase em âmbar diz isso); trocar não
    /// grava: fechar pergunta, e descartar deixa o orçamento por tópico como estava.
    func testTrocarParaSoOTotalPreencheComASomaENaoGrava() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        editarPeloLapis(app)
        XCTAssertTrue(app.buttons["modoDoOrcamento-Por tópico"].isSelected, "abre no modo salvo")
        app.buttons["modoDoOrcamento-Só o total"].tap()
        XCTAssertTrue(app.staticTexts["Preenchido com a soma dos tópicos."].waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.019.847,85")
        XCTAssertTrue(app.staticTexts["Comparado com o Total gasto (bruto), com as parcelas a vencer."].exists)
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você mudou este orçamento."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar alterações"].tap()
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").label.contains("Orçamento por tópico"), "nada foi gravado")
    }

    /// "Tirar orçamento" pergunta com o texto do site; tirar leva a tela Orçamento de volta para a obra, sem a linha e com o
    /// "Definir" de volta.
    func testTirarOrcamentoPerguntaEVoltaParaAObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        editarPeloLapis(app)
        let tirar = app.buttons["tirarOrcamento"]
        app.rolarAte(tirar)
        tirar.tap()
        let alerta = app.alerts["Tirar o orçamento desta obra?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Os gastos continuam como estão."].exists)
        alerta.buttons["Cancelar"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        tirar.tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Tirar orçamento"].tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a tela Orçamento voltou para a obra")
        XCTAssertFalse(app.elemento("tituloDoOrcamento").exists)
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists, "a linha sumiu da obra")
        XCTAssertTrue(app.buttons["definirOrcamento"].waitForExistence(timeout: 5))
    }

    /// Salvar com tudo vazio faz a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar).
    func testSalvarVazioPerguntaComoTirar() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "orcamento:v1")
        editarPeloLapis(app)
        app.elemento("linhaOrcamentoTotal").tap()
        for _ in 0..<9 { app.buttons["tecla-del"].tap() }
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}0,00")
        let salvar = app.buttons["salvarOrcamento"]
        XCTAssertTrue(salvar.isEnabled, "com orçamento antes, salvar vazio vale")
        salvar.tap()
        let alerta = app.alerts["Tirar o orçamento desta obra?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Tirar orçamento"].tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists)
    }

    /// O teto do teclado do app (R$ 99.999.999,99): a tecla que passaria dele é ignorada (o site não tem teto, achado 12).
    func testTetoDoTeclado() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        digitar(app, "99999999990")
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}99.999.999,99")
        app.buttons["tecla-00"].tap()
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}99.999.999,99")
    }

    /// Na maior letra: com as teclas abertas, o "Salvar" sai, a barra fica sem o nome e "Pronto" fecha (o "Salvar" volta); no
    /// "Só o total", a barra aparece com o "Pronto" (sem ela, não sobraria nem "Salvar" nem "Pronto").
    func testNaMaiorLetraOSalvarSaiComAsTeclas() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", argumentos: maiorLetra)
        editarPeloLapis(app)
        let linha = app.elemento("linhaOrc-terreno")
        app.rolarAte(linha)
        linha.tap()
        let pronto = app.buttons["barraDasTeclas-pronto"]
        XCTAssertTrue(pronto.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["salvarOrcamento"].exists, "com as teclas abertas, o \"Salvar\" sai")
        XCTAssertFalse(app.staticTexts["barraDasTeclas-nome"].exists, "na maior letra, sem o nome na barra")
        XCTAssertEqual(app.buttons["tecla-1"].frame.height, 64, accuracy: 0.5, "as teclas param em 64 pt")
        pronto.tap()
        XCTAssertTrue(app.buttons["salvarOrcamento"].waitForExistence(timeout: 5), "\"Pronto\" fecha e o \"Salvar\" volta")
        app.terminate()
        let sem = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1", argumentos: maiorLetra)
        definir(sem)
        XCTAssertTrue(sem.buttons["barraDasTeclas-pronto"].waitForExistence(timeout: 5), "no \"Só o total\", o \"Pronto\"")
        XCTAssertFalse(sem.buttons["barraDasTeclas-proximo"].exists, "sem as setas")
        sem.buttons["barraDasTeclas-pronto"].tap()
        XCTAssertTrue(sem.buttons["salvarOrcamento"].waitForExistence(timeout: 5))
    }

    /// Antes de ver os dados, o "Salvar" avisa com o texto do site dentro da folha, que continua aberta com o que foi digitado.
    func testSalvarAntesDeVerOsDadosAvisaENaoFecha() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1", argumentos: ["-custta.recusarGravacao", "nao-carregado"])
        definir(app)
        digitar(app, "100000")
        app.buttons["salvarOrcamento"].tap()
        let alerta = app.alerts.firstMatch
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["O orçamento continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.000,00", "a folha continua, com o valor")
    }

    /// A obra apagada em outro aparelho com a folha aberta: não há onde gravar; a folha desce e, sem a obra, volta a lista de
    /// Obras.
    func testFolhaFechaQuandoOutroAparelhoApagaAObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 10))
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForNonExistence(timeout: 10), "a folha desceu")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "de volta à lista de Obras")
    }

    /// Teclado físico: com as teclas abertas, os dígitos entram na linha ativa. O apagar fica com a guarda Node da folha: o
    /// `typeKey` do XCTest não entrega nenhum apagar (⌫, ⌦ nem U+0008) a uma view que não é campo de texto, e o `typeText`
    /// exige um campo com o foco; o ⌫ de um teclado de verdade (o HID do teclado do Mac no simulador) chega como `.delete` e
    /// apaga (registro do PR 1, tarefa 6, 21/10).
    func testTecladoFisicoDigitaNaLinhaAtiva() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        for tecla in ["1", "2", "5"] { app.typeKey(tecla, modifierFlags: []) }
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1,25")
    }

    /// Com as teclas fechadas, tocar numa linha de baixo abre as teclas e leva a linha para o meio da faixa à vista: ao abrir,
    /// a lista encolhe, e a rolagem espera a altura nova.
    func testTocarUmaLinhaDeBaixoAbreAsTeclasComElaNoMeio() throws { try tocarUmaLinhaDeBaixo(reduzirMovimento: true) }

    /// O mesmo sem Reduzir movimento, o caminho de quem não liga a opção: com a rolagem animada, a linha também termina no meio
    /// da faixa.
    func testTocarUmaLinhaDeBaixoComAnimacaoAbreAsTeclasComElaNoMeio() throws { try tocarUmaLinhaDeBaixo(reduzirMovimento: false) }

    private func tocarUmaLinhaDeBaixo(reduzirMovimento: Bool) throws {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: ["-custta.folha", "topicos"] + (reduzirMovimento ? ["-custta.reduzirMovimento", "YES"] : []))
        XCTAssertTrue(app.elemento("linhaOrc-terreno").waitForExistence(timeout: 10))
        let lista = app.elemento("listaDoOrcamento")
        // A última linha inteira à vista antes de as teclas abrirem: depois, ela ficaria embaixo delas.
        let ids = ["terreno", "projeto", "matbasicos", "fundacao", "ferragem", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica"]
        let alvo = try XCTUnwrap(ids.last { app.elemento("linhaOrc-\($0)").exists && app.elemento("linhaOrc-\($0)").frame.maxY < lista.frame.maxY - 1 })
        let linha = app.elemento("linhaOrc-\(alvo)")
        linha.tap()
        let teclas = app.elemento("tecladoEncaixado")
        XCTAssertTrue(teclas.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        XCTAssertGreaterThanOrEqual(linha.frame.minY, lista.frame.minY - 0.5, alvo)
        XCTAssertLessThanOrEqual(linha.frame.maxY, teclas.frame.minY + 0.5, "\(alvo): inteira acima das teclas")
        XCTAssertEqual(linha.frame.midY, (lista.frame.minY + teclas.frame.minY) / 2, accuracy: 2, "\(alvo): no meio da faixa")
    }

    /// A linha ativa fica inteira à vista entre o alto da lista e as teclas a cada ›, nas 71 linhas (os 21 fixos e os 50
    /// próprios, o limite das rules), também ao abrir; longe das pontas da lista, no meio da faixa (decisão 2).
    private func varrer(letraGrande: Bool) {
        let app = abrirApp(conta: "senha", dados: "muitosTopicos", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: ["-custta.folha", "teclas:terreno", "-custta.reduzirMovimento", "YES"] + (letraGrande ? maiorLetra : []))
        let proximo = app.buttons["barraDasTeclas-proximo"]
        XCTAssertTrue(proximo.waitForExistence(timeout: 10))
        let teclas = app.elemento("tecladoEncaixado"), lista = app.elemento("listaDoOrcamento")
        // Na maior letra o alto da folha rola com a lista, que passa por baixo da barra da folha: a faixa à vista começa onde a
        // barra acaba. A barra da folha, e não a da tela Orçamento atrás dela (a primeira da árvore).
        let barra = app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch
        var fora: [String] = []
        var indice = 0
        func conferir(_ id: String) {
            defer { indice += 1 }
            let linha = app.elemento("linhaOrc-\(id)")
            guard linha.exists else { fora.append("\(id) sem linha"); return }
            let f = linha.frame, faixa = (max(lista.frame.minY, barra.frame.maxY), teclas.frame.minY)
            if f.minY < faixa.0 - 0.5 || f.maxY > faixa.1 + 0.5 {
                fora.append("\(id) [\(Int(f.minY))–\(Int(f.maxY))] na faixa [\(Int(faixa.0))–\(Int(faixa.1))]")
            } else if (5..<66).contains(indice), abs(f.midY - (faixa.0 + faixa.1) / 2) > 2 {
                // Longe das pontas (onde a lista não rola mais), a linha fica no meio da faixa.
                fora.append("\(id) com o meio em \(Int(f.midY)), longe do meio da faixa (\(Int((faixa.0 + faixa.1) / 2)))")
            }
        }
        conferir("terreno")
        let ids = ["projeto", "matbasicos", "fundacao", "ferragem", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica",
                   "esquadrias", "revest", "pintura", "acabamento", "piscina", "paisagismo", "maoobra", "aluguelmaq", "matextra",
                   "extras", "outros", "c_gesso"] + (2...50).map { "c_proprio\($0)" }
        for id in ids {
            proximo.tap()
            conferir(id)
        }
        XCTAssertTrue(fora.isEmpty, "linha ativa fora da faixa:\n" + fora.joined(separator: "\n"))
    }

    func testVarreduraDoProximoNas71Linhas() { varrer(letraGrande: false) }
    func testVarreduraDoProximoNas71LinhasNaMaiorLetra() { varrer(letraGrande: true) }
}
