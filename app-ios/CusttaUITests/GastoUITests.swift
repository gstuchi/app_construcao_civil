import XCTest

/* O gasto (etapa 2, PR 2), na obra da vitrine (46 lançamentos): lançar no Pix (com e sem rede), descartar pelo × e
   puxando a folha, o voltar pela borda dentro da folha, o repetido e o `nao-carregado`. */
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
