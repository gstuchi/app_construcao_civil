import XCTest
import notify

/* O gasto (etapa 2, PR 2), na obra da vitrine (46 lançamentos): lançar no Pix (com e sem rede) e no cartão parcelado,
   editar (a descrição e o valor no teclado), apagar arrastando e pela folha, a parcela (só esta ou a compra toda),
   descartar pelo × e puxando a folha, o voltar pela borda dentro da folha, o repetido, o `nao-carregado` e a folha que
   fecha quando outro aparelho apaga o gasto. */
@MainActor
final class GastoUITests: XCTestCase {
    private func abrirObra(_ argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: argumentos)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        return app
    }

    /// + → o valor no teclado → "Avançar".
    private func lancarValor(_ app: XCUIApplication, _ teclas: String) {
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in teclas { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5))
    }

    private func escrever(_ app: XCUIApplication, _ texto: String, apagando: Int = 0) {
        let campo = app.textFields["descricao"]
        for _ in 0..<5 where !app.keyboards.firstMatch.exists { campo.tap(); sleep(1) }
        if apagando > 0 { campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: apagando)) }
        campo.typeText(texto)
    }

    private func comRotulo(_ app: XCUIApplication, comecando texto: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", texto))
    }

    private func puxarFolha(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)),
                   withVelocity: .fast, thenHoldForDuration: 0)
    }

    func testLancarNoPixAcendeALinhaNova() {
        let app = abrirObra()
        lancarValor(app, "138000")
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}1.380,00")
        escrever(app, "Areia média, 6 m³")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
        XCTAssertTrue(comRotulo(app, comecando: "Areia média, 6 m³").firstMatch.waitForExistence(timeout: 5), "a linha nova aparece")
        XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
    }

    func testLancarSemRedeEntraNaLista() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        lancarValor(app, "100")
        escrever(app, "Areia sem rede")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertTrue(comRotulo(app, comecando: "Areia sem rede").firstMatch.waitForExistence(timeout: 5), "sem rede, o gasto entra na lista")
        XCTAssertEqual(app.elemento("indicadorSincronizacao").label, "Sem conexão", "e espera a rede na fila")
    }

    func testLancarNoCartaoEm10xVaiParaOAVencer() {
        let app = abrirObra()
        lancarValor(app, "498000")
        app.buttons["pagamento-Cartão"].tap()
        app.buttons["parcelas"].tap()
        app.buttons["10x"].tap()
        let resumo = app.elemento("resumoDoCartao")
        XCTAssertTrue(resumo.waitForExistence(timeout: 3))
        XCTAssertEqual(resumo.label, "10x de R$\u{a0}498,00 · Juros do cartão: R$\u{a0}0,00 · Total: R$\u{a0}4.980,00")
        escrever(app, "Revestimento da varanda")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.elemento("aVencer").value as? String, "aberto", "o primeiro vencimento é daqui a um mês: o A vencer abre")
        XCTAssertTrue(comRotulo(app, comecando: "Revestimento da varanda (1/10)").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("56"), "10 parcelas entraram")
    }

    func testEditarGastoTrocaADescricao() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.tap()
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Editar gasto"))
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}4.980,00")
        escrever(app, "Cimento CP-V, 120 sacos", apagando: 30)
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("gasto-g027").label.hasPrefix("Cimento CP-V, 120 sacos"), app.elemento("gasto-g027").label)
        XCTAssertTrue(app.elemento("lancamentos").label.contains("46"))
    }

    func testEditarOValorPeloTeclado() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.tap()
        XCTAssertTrue(app.elemento("linhaValor").waitForExistence(timeout: 5))
        app.elemento("linhaValor").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["confirmarValor"].label, "Pronto")
        for _ in 0..<6 { app.buttons["tecla-del"].tap() }
        for t in "12345" { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}123,45", "o valor novo volta aos detalhes")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.elemento("gasto-g027").value as? String, "R$\u{a0}123,45")
    }

    func testFolhaFechaQuandoOutroAparelhoApagaOGasto() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1/g027@0"])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5), "a edição abriu antes de o outro aparelho apagar")
        // O outro aparelho apaga agora, com a folha aberta. Um relógio desde a abertura do app corria contra o teste: na CI
        // (consultas ~4× mais lentas) a linha sumia antes do toque.
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 10), "o gasto sumiu: a folha fecha sem gravar")
        XCTAssertFalse(app.elemento("gasto-g027").exists)
    }

    func testEditarParcelaMostraOAvisoDoSite() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g031")
        app.rolarAte(linha)
        linha.tap()
        let aviso = app.elemento("avisoParcela")
        XCTAssertTrue(aviso.waitForExistence(timeout: 5))
        XCTAssertEqual(aviso.label, "Parcela 4/10 de uma compra no cartão — a edição vale só pra esta parcela.")
        XCTAssertFalse(app.buttons["pagamento-Pix"].exists, "numa parcela o pagamento não muda")
    }

    func testApagarArrastandoPerguntaComNomeEValor() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.swipeLeft()
        let apagar = app.buttons["apagar-g027"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 3), "arrastar para a esquerda mostra Apagar")
        apagar.tap()
        let alerta = app.alerts["Apagar este gasto?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["Cimento CP-II, 120 sacos · R$\u{a0}4.980,00. Não dá para desfazer."].exists)
        alerta.buttons["Apagar"].tap()
        XCTAssertTrue(app.elemento("gasto-g027").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("45"))
    }

    func testCancelarFechaALinhaENaoApaga() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.swipeLeft()
        app.buttons["apagar-g027"].tap()
        app.alerts["Apagar este gasto?"].buttons["Cancelar"].tap()
        XCTAssertTrue(app.buttons["apagar-g027"].waitForNonExistence(timeout: 3), "cancelar fecha a linha")
        XCTAssertTrue(app.elemento("gasto-g027").exists)
    }

    func testApagarACompraTodaDeUmaParcela() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g031")
        app.rolarAte(linha)
        linha.swipeLeft()
        app.buttons["apagar-g031"].tap()
        let alerta = app.alerts["Porcelanato 60×60 (4/10)"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.buttons["Apagar só esta parcela"].exists)
        alerta.buttons["Apagar a compra toda (10 parcelas)"].tap()
        XCTAssertTrue(app.elemento("gasto-g031").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("36"), "as 10 parcelas saíram juntas")
    }

    func testApagarSoEstaParcela() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g031")
        app.rolarAte(linha)
        linha.swipeLeft()
        app.buttons["apagar-g031"].tap()
        let alerta = app.alerts["Porcelanato 60×60 (4/10)"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["Apagar só esta parcela"].tap()
        XCTAssertTrue(app.elemento("gasto-g031").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("45"), "só a parcela saiu; as outras nove ficam")
    }

    func testApagarPelaFolhaDeEdicao() {
        let app = abrirObra()
        let linha = app.elemento("gasto-g027")
        app.rolarAte(linha)
        linha.tap()
        let botao = app.buttons["apagarGasto"]
        XCTAssertTrue(botao.waitForExistence(timeout: 5))
        botao.tap()
        app.alerts["Apagar este gasto?"].buttons["Apagar"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
        XCTAssertTrue(app.elemento("gasto-g027").waitForNonExistence(timeout: 5), "e a linha sai depois")
    }

    func testFecharDepoisDoValorPerguntaAntes() {
        let app = abrirObra()
        lancarValor(app, "1")
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você já preencheu este gasto."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").exists, "continua na folha")
        app.buttons["fecharFolha"].tap()
        app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("46"), "nada foi gravado")
    }

    func testPuxarAFolhaPreenchidaPerguntaESemValorFecha() {
        let app = abrirObra(["-custta.contarPontes", "YES"])
        lancarValor(app, "1")
        puxarFolha(app)
        XCTAssertTrue(app.alerts["Você já preencheu este gasto."].waitForExistence(timeout: 4), "puxar com valor pergunta")
        app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 0,00", "reabre limpa")
        puxarFolha(app)
        XCTAssertTrue(app.elemento("visorDoValor").waitForNonExistence(timeout: 5), "sem valor, puxar fecha sem perguntar")
        let pontes = app.elemento("pontesVivas")
        let zerou = NSPredicate(format: "label == 'pontes 0'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: zerou, object: pontes)], timeout: 5), .completed,
                       "nenhuma ponte presa depois de fechar: \(pontes.label)")
    }

    func testVoltarPelaBordaDentroDaFolha() {
        let app = abrirObra()
        lancarValor(app, "1")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5), "a borda volta ao valor, dentro da folha")
        XCTAssertTrue(app.elemento("tituloDaFolha").exists, "a folha continua aberta")
    }

    /// Sem descrição o aviso do repetido não segura o segundo toque: o toque duplo lança um gasto só.
    func testToqueDuploNoSalvarLancaUmGasto() {
        let app = abrirObra()
        lancarValor(app, "100")
        app.buttons["salvarGasto"].doubleTap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        sleep(1)
        XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
    }

    func testRepetidoPedeOSegundoToque() {
        let app = abrirObra()
        for vez in 0..<2 {
            lancarValor(app, "10000")
            escrever(app, "Areia fina")
            app.buttons["salvarGasto"].tap()
            if vez == 1 {
                XCTAssertTrue(app.elemento("avisoRepetido").waitForExistence(timeout: 3), "o segundo igual avisa")
                XCTAssertEqual(app.buttons["salvarGasto"].label, "Salvar mesmo assim")
                app.buttons["salvarGasto"].tap()
            }
            XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        }
        let linhas = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'gasto-' AND label BEGINSWITH 'Areia fina'"))
        XCTAssertEqual(Set(linhas.allElementsBoundByIndex.map(\.identifier)).count, 2, "os dois gastos iguais foram gravados")
    }

    func testNaoCarregadoAvisaEMantemAFolha() {
        let app = abrirObra(["-custta.recusarGravacao", "nao-carregado"])
        lancarValor(app, "138000")
        app.buttons["salvarGasto"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["O gasto continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}1.380,00", "o gasto continua na folha")
    }
}
