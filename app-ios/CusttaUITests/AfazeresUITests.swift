import XCTest
import notify

/* Os afazeres (etapa 3, PR 3; mockup da parte 2, seção 4): a linha na obra nos três estados, que abre a tela "Afazeres";
   adicionar vários seguidos (o novo no alto, o cursor no campo), o campo vazio que não faz nada e o que para em 500
   caracteres, com o + que grava os 500 mesmo depois de rajadas de teclas; marcar pelo círculo e desmarcar pelo texto, na
   ordem nova (o feito no alto dos Feitos, o desmarcado no alto dos pendentes), com o círculo que troca na hora e o segundo
   toque que desiste; "Feitos" fechado, que abre; apagar arrastando, sem pergunta; o texto longo inteiro na tela e cortado
   em duas linhas na obra; o vazio; a gravação recusada antes de ver os dados; a obra apagada em outro aparelho; o + da
   cápsula, que lança gasto na obra; e a mudança vinda de outro aparelho durante a digitação (achado 3). Na vitrine, a
   Casa Alphaville tem os 7 afazeres do mockup (3 pendentes e 4 feitos), o Sobrado Granja Viana, 2 feitos, e a Casa
   Tamboré 4, nenhum. */
@MainActor
final class AfazeresUITests: XCTestCase {
    private func abrirAfazeres(_ obra: String = "v1", argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "afazeres:\(obra)", argumentos: argumentos)
        XCTAssertTrue(app.textFields["novoAfazer"].waitForExistence(timeout: 10))
        return app
    }

    /// Os afazeres à vista, de cima para baixo, pelo texto.
    private func ordem(_ app: XCUIApplication) -> [String] {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'afazer-'")).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }.map(\.label)
    }

    private func pendentes(_ app: XCUIApplication) -> String { app.elemento("pendentes").label }

    /// A linha da obra nos três estados, cada uma abrindo a tela da obra dela.
    func testLinhaNosTresEstadosAbreAfazeres() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        for (obra, valor) in [("v1", "3 pendentes, Pagar a quinzena do pedreiro na sexta"), ("v2", "tudo feito, 2 feitos"),
                              ("v3", "Anote o que falta na obra.")] {
            let cartao = app.elemento("obra-\(obra)")
            XCTAssertTrue(cartao.waitForExistence(timeout: 10))
            cartao.tap()
            let linha = app.elemento("linhaDosAfazeres")
            XCTAssertTrue(linha.waitForExistence(timeout: 5))
            app.rolarAte(linha)
            XCTAssertEqual(linha.label, "Afazeres")
            XCTAssertEqual(linha.value as? String, valor, obra)
            linha.tap()
            XCTAssertTrue(app.textFields["novoAfazer"].waitForExistence(timeout: 5), "a linha empurra a tela Afazeres")
            XCTAssertTrue(app.navigationBars["Afazeres"].exists)
            app.navigationBars.buttons["BackButton"].tap()
            XCTAssertTrue(linha.waitForExistence(timeout: 5), "volta para a obra")
            app.navigationBars.buttons["BackButton"].tap()
        }
    }

    /// O "OK" do teclado e o + adicionam, aparado; o novo entra no alto dos pendentes, o campo limpa e o teclado fica.
    func testAdicionarVariosSeguidosNoAltoComOCursorNoCampo() {
        let app = abrirAfazeres()
        let campo = app.textFields["novoAfazer"]
        XCTAssertEqual(campo.label, "Novo afazer", "o rótulo do campo para o VoiceOver")
        XCTAssertEqual(pendentes(app), "Pendentes, 3")
        app.digitarComFoco("Comprar disjuntor de 40 A\n", em: campo)
        XCTAssertEqual(pendentes(app), "Pendentes, 4")
        XCTAssertEqual(ordem(app).first, "Comprar disjuntor de 40 A")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "o cursor continua no campo")
        campo.typeText("  Ligar pro eletricista  ")
        app.buttons["adicionarAfazer"].tap()
        XCTAssertEqual(pendentes(app), "Pendentes, 5")
        XCTAssertEqual(Array(ordem(app).prefix(3)), ["Ligar pro eletricista", "Comprar disjuntor de 40 A",
                                                    "Pagar a quinzena do pedreiro na sexta"], "aparado, no alto")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "o + também deixa o cursor no campo")
        campo.typeText("x")
        XCTAssertEqual(campo.value as? String, "x", "o campo limpou depois de adicionar")
    }

    /// Vazio (ou só espaços) não faz nada: o "OK" sai do campo mesmo assim (sem a quebra de linha que ele traz), e o campo
    /// continua com o cursor.
    func testCampoVazioNaoFazNada() {
        let app = abrirAfazeres()
        app.buttons["adicionarAfazer"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "o + sem texto põe o cursor no campo")
        app.textFields["novoAfazer"].typeText("   \n")
        XCTAssertEqual(pendentes(app), "Pendentes, 3")
        XCTAssertEqual(app.textFields["novoAfazer"].value as? String, "   ", "o OK sai do campo, mesmo sem adicionar")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
    }

    /// O campo para em 500 caracteres, como o maxlength do site: digitando tecla a tecla, a que passa não fica, e o + grava
    /// os 500. (Os 500 vão de uma vez, e as teclas a mais uma por vez, como a mão digita.)
    func testCampoParaEm500Caracteres() {
        let app = abrirAfazeres()
        let campo = app.textFields["novoAfazer"]
        let quinhentos = String(repeating: "a", count: 500)
        app.digitarComFoco(quinhentos, em: campo)
        for tecla in 1...5 {
            campo.typeText("a")
            XCTAssertEqual((campo.value as? String)?.count, 500, "tecla \(tecla) a mais")
        }
        app.buttons["adicionarAfazer"].tap()
        XCTAssertEqual(pendentes(app), "Pendentes, 4")
        XCTAssertEqual(ordem(app).first, quinhentos, "o afazer novo, com os 500")
    }

    /// Com o campo em 500, rajadas de teclas (o XCUITest digita a ~1 ms, mais rápido que a mão) e o +: o afazer novo é
    /// gravado com os 500, e os pendentes crescem um. No meio de uma rajada a tela pode passar de 500 (a tecla seguinte
    /// corrige), mas o estado e o gravado não, e o + nunca fica calado. As rajadas param na primeira em que a tela não mostra
    /// 500, para o + chegar logo depois dela.
    func testRajadasEm500EOMaisGravaOs500() {
        let app = abrirAfazeres()
        let campo = app.textFields["novoAfazer"]
        let quinhentos = String(repeating: "a", count: 500)
        app.digitarComFoco(quinhentos, em: campo)
        for _ in 1...40 {
            campo.typeText("aaa")
            guard (campo.value as? String)?.count == 500 else { break }
        }
        app.buttons["adicionarAfazer"].tap()
        XCTAssertEqual(pendentes(app), "Pendentes, 4", "o + gravou, sem ficar calado")
        XCTAssertEqual(ordem(app).first, quinhentos, "o afazer novo, com os 500")
        campo.typeText("x")
        XCTAssertEqual(campo.value as? String, "x", "o campo limpou depois do +")
    }

    /// Marcar pelo círculo leva o afazer ao alto dos Feitos (fechados, que abrem); desmarcar pelo texto, ao alto dos
    /// pendentes. O feito fica riscado e, para o VoiceOver, "feito".
    func testMarcarEDesmarcarNaOrdemNova() {
        let app = abrirAfazeres()
        let a1 = app.elemento("afazer-a1")
        XCTAssertEqual(a1.value as? String, "pendente")
        // O círculo, à esquerda do texto: alvo de 44 pt a partir de 12 da borda da linha.
        a1.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 34, dy: 28)).tap()
        XCTAssertTrue(app.elemento("pendentes").waitForExistence(timeout: 3))
        let feitos = app.elemento("feitos")
        let ate = Date.now.addingTimeInterval(5)
        while pendentes(app) != "Pendentes, 2" && Date.now < ate { usleep(200_000) }
        XCTAssertEqual(pendentes(app), "Pendentes, 2", "meio segundo depois, o afazer sai dos pendentes")
        XCTAssertEqual(feitos.label, "Feitos, 5")
        XCTAssertEqual(feitos.value as? String, "fechado", "os Feitos começam fechados")
        XCTAssertFalse(a1.exists, "com os Feitos fechados, o marcado some")
        feitos.tap()
        XCTAssertEqual(feitos.value as? String, "aberto")
        XCTAssertTrue(a1.waitForExistence(timeout: 3))
        XCTAssertEqual(a1.value as? String, "feito")
        let rotulos = ordem(app)
        XCTAssertEqual(Array(rotulos.suffix(5)).first, "Pagar a quinzena do pedreiro na sexta", "no alto dos Feitos")
        a1.tap()
        let ate2 = Date.now.addingTimeInterval(5)
        while pendentes(app) != "Pendentes, 3" && Date.now < ate2 { usleep(200_000) }
        XCTAssertEqual(pendentes(app), "Pendentes, 3")
        XCTAssertEqual(ordem(app).first, "Pagar a quinzena do pedreiro na sexta", "desmarcado, no alto dos pendentes")
        XCTAssertEqual(a1.value as? String, "pendente")
        XCTAssertEqual(feitos.label, "Feitos, 4")
    }

    /// O círculo troca na hora (e o VoiceOver já ouve "feito"), e o afazer só muda de lugar depois; um segundo toque nesse
    /// meio-tempo desiste. A espera passa de meio segundo para três (gancho do Debug), para o teste ver o meio do caminho.
    func testCirculoTrocaNaHoraESegundoToqueDesiste() {
        let app = abrirAfazeres(argumentos: ["-custta.esperaDoAfazer", "3000"])
        let a1 = app.elemento("afazer-a1"), a3 = app.elemento("afazer-a3")
        XCTAssertTrue(a1.waitForExistence(timeout: 5))
        a1.tap()
        XCTAssertEqual(a1.value as? String, "feito", "o círculo troca na hora")
        XCTAssertEqual(pendentes(app), "Pendentes, 3", "e o afazer ainda não saiu dos pendentes")
        a1.tap()
        XCTAssertEqual(a1.value as? String, "pendente", "o segundo toque desiste")
        sleep(4)
        XCTAssertEqual(pendentes(app), "Pendentes, 3", "nada mudou de lugar")
        XCTAssertEqual(ordem(app).first, "Pagar a quinzena do pedreiro na sexta")
        a3.tap()
        XCTAssertEqual(a3.value as? String, "feito")
        let ate = Date.now.addingTimeInterval(8)
        while pendentes(app) != "Pendentes, 2" && Date.now < ate { usleep(200_000) }
        XCTAssertEqual(pendentes(app), "Pendentes, 2", "passada a espera, o marcado vai para os Feitos")
        XCTAssertEqual(app.elemento("feitos").label, "Feitos, 5")
    }

    /// Na linha da obra, o primeiro pendente para em duas linhas (o texto inteiro está na tela Afazeres e no VoiceOver).
    func testLinhaCortaOPrimeiroPendenteEmDuasLinhas() {
        let app = abrirAfazeres()
        app.elemento("afazer-a1").tap()
        let ate = Date.now.addingTimeInterval(5)
        while pendentes(app) != "Pendentes, 2" && Date.now < ate { usleep(200_000) }
        app.navigationBars.buttons["BackButton"].tap()
        let linha = app.elemento("linhaDosAfazeres")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        app.rolarAte(linha)
        XCTAssertTrue((linha.value as? String ?? "").hasSuffix("com a altura do peitoril e o lado de abrir de cada folha."),
                      "o VoiceOver lê o pendente de 213 caracteres inteiro")
        XCTAssertLessThan(linha.frame.height, 110, "duas linhas do pendente, e não seis")
    }

    /// A obra apagada em outro aparelho com os afazeres abertos: volta para Obras, como a tela da obra.
    func testObraApagadaEmOutroAparelhoVoltaParaObras() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "afazeres:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        XCTAssertTrue(app.textFields["novoAfazer"].waitForExistence(timeout: 10))
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 10), "voltou para a lista de obras")
        XCTAssertFalse(app.textFields["novoAfazer"].exists)
        XCTAssertFalse(app.elemento("obra-v1").exists)
    }

    /// Arrastar mostra "Apagar", que apaga na hora, sem pergunta.
    func testApagarArrastandoSemPergunta() {
        let app = abrirAfazeres()
        let a3 = app.elemento("afazer-a3")
        XCTAssertTrue(a3.waitForExistence(timeout: 5))
        a3.swipeLeft()
        let apagar = app.buttons["apagar-a3"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 3), "arrastar para a esquerda mostra Apagar")
        apagar.tap()
        XCTAssertTrue(a3.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.alerts.count, 0, "sem pergunta")
        XCTAssertEqual(pendentes(app), "Pendentes, 2")
    }

    /// O pendente longo (213 caracteres) se lê inteiro, quebrando linha.
    func testTextoLongoSeLeInteiro() {
        let app = abrirAfazeres()
        let a2 = app.elemento("afazer-a2")
        XCTAssertTrue(a2.waitForExistence(timeout: 5))
        XCTAssertTrue(a2.label.hasSuffix("com a altura do peitoril e o lado de abrir de cada folha."), a2.label)
        XCTAssertGreaterThan(a2.frame.height, 6 * 20, "seis linhas, nenhuma cortada")
    }

    /// Sem nenhum afazer, o vazio do site; o primeiro adicionado o tira.
    func testVazioEOPrimeiroAfazer() {
        let app = abrirAfazeres("v3")
        let vazio = app.elemento("afazeresVazio")
        XCTAssertTrue(vazio.waitForExistence(timeout: 5))
        XCTAssertEqual(vazio.label, "Nenhum afazer.")
        XCTAssertTrue(app.staticTexts["Anote o que falta na obra."].exists)
        XCTAssertFalse(app.elemento("pendentes").exists)
        app.digitarComFoco("Pagar o eletricista\n", em: app.textFields["novoAfazer"])
        XCTAssertTrue(vazio.waitForNonExistence(timeout: 5))
        XCTAssertEqual(pendentes(app), "Pendentes, 1")
    }

    /// Antes de ver os dados, o alerta do site, e o texto continua no campo.
    func testNaoCarregadoAvisaEMantemOTexto() {
        let app = abrirAfazeres(argumentos: ["-custta.recusarGravacao", "nao-carregado"])
        let campo = app.textFields["novoAfazer"]
        app.digitarComFoco("Comprar areia\n", em: campo)
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["OK"].tap()
        XCTAssertEqual(campo.value as? String, "Comprar areia", "o texto continua no campo")
        XCTAssertEqual(pendentes(app), "Pendentes, 3", "nada foi gravado")
    }

    /// Achado 3: outro aparelho anota um afazer enquanto um é digitado aqui. A lista ganha o de lá, e o texto e o cursor
    /// ficam no campo (o texto em digitação e o foco moram na tela, e o redesenho que chega do Sincronizador não os recria).
    func testMudancaDeOutroAparelhoNaoApagaOAfazerEmDigitacao() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "afazeres:v1", extra: ["CUSTTA_MUDANCA_REMOTA": "afazer:v1"])
        let campo = app.textFields["novoAfazer"]
        app.digitarComFoco("Comprar cimen", em: campo)
        // O outro aparelho grava agora, com o afazer em digitação (um relógio desde a abertura correria contra o teste).
        notify_post("br.com.custta.falso.mudancaRemota")
        XCTAssertTrue(app.elemento("afazer-remoto1").waitForExistence(timeout: 10), "o afazer do outro aparelho chega")
        XCTAssertEqual(pendentes(app), "Pendentes, 4")
        XCTAssertEqual(campo.value as? String, "Comprar cimen", "o texto em digitação fica")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "e o teclado também")
        campo.typeText("to\n")                         // sem o foco, o XCUITest não digita ("no keyboard focus")
        XCTAssertEqual(pendentes(app), "Pendentes, 5")
        XCTAssertEqual(Array(ordem(app).prefix(2)), ["Comprar cimento", "Ver a entrega do gesso"])
    }

    /// Nos afazeres, o + da cápsula lança gasto na obra, como dentro dela.
    func testOMaisDaCapsulaLancaGastoNaObra() {
        let app = abrirAfazeres()
        let mais = app.buttons["botaoMais"]
        XCTAssertEqual(mais.label, "Lançar gasto")
        mais.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5), "a folha do gasto abre")
    }
}
