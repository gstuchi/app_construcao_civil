import XCTest
import notify

/// Sonda do foco da busca no iOS 26 (27/10, temporária): o fluxo do achado 3 com os avisos do app (SondaFoco) impressos
/// com o tempo, numa linha `sonda-foco | variante | t=… | …`. Uma variante por teste.
@MainActor
final class SondaFocoUITests: XCTestCase {
    private func sonda(_ variante: String) {
        let inicio = Date.now
        let nomes = ["foco.sim", "foco.nao", "campo.apareceu", "campo.sumiu", "edicao.comeca", "edicao.acaba", "teclado.mostra",
                     "teclado.esconde", "texto", "parada", "congelou"]
        var tokens: [Int32] = []
        for nome in nomes {
            var token: Int32 = 0
            notify_register_dispatch("br.com.custta.sonda.\(nome)", &token, DispatchQueue.global()) { @Sendable t in
                var estado: UInt64 = 0
                notify_get_state(t, &estado)
                print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | app: \(nome) \(estado)")
            }
            tokens.append(token)
        }
        defer { tokens.forEach { notify_cancel($0) } }
        func linha(_ texto: String) {
            print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | teste: \(texto)")
        }
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.sondaFoco", variante],
                           extra: ["CUSTTA_APAGAR_REMOTO": "v1/g027@0"])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let campo = app.textFields["campoDaBusca"]
        func estado(_ passo: String) {
            let focados = app.textFields.matching(NSPredicate(format: "hasKeyboardFocus == 1")).count
            linha("\(passo) · pílula \(app.elemento("lancamentos").label) · texto \(campo.value as? String ?? "?") · teclado "
                  + "\(app.keyboards.firstMatch.exists) · campos com foco \(focados)")
        }
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa)
        lupa.tap()
        linha("lupa · teclado \(app.keyboards.firstMatch.waitForExistence(timeout: 5))")
        app.digitarComFoco("cimen", em: campo)
        estado("digitou")
        sleep(5)
        estado("5 s depois")
        notify_post("br.com.custta.falso.apagarRemoto")
        let ate = Date.now.addingTimeInterval(20)
        while app.elemento("lancamentos").label != "Lançamentos, 1 de 45" && Date.now < ate { usleep(200_000) }
        estado("remoto")
        sleep(3)
        estado("3 s depois do remoto")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "o teclado fica")
    }

    /// Estresse: com a busca aberta o tempo todo, digita "cimen", apaga e baixa o teclado pelo "buscar"; o toque no campo o
    /// traz de volta. Seis voltas. O campo não sai da tela: um `campo.sumiu` aqui é a pilha refazendo o campo à vista.
    private func estresse(_ variante: String) {
        let inicio = Date.now
        let nomes = ["foco.sim", "foco.nao", "campo.apareceu", "campo.sumiu", "edicao.comeca", "edicao.acaba", "teclado.mostra",
                     "teclado.esconde", "parada", "congelou"]
        var tokens: [Int32] = []
        for nome in nomes {
            var token: Int32 = 0
            notify_register_dispatch("br.com.custta.sonda.\(nome)", &token, DispatchQueue.global()) { @Sendable t in
                var estado: UInt64 = 0
                notify_get_state(t, &estado)
                print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | app: \(nome) \(estado)")
            }
            tokens.append(token)
        }
        defer { tokens.forEach { notify_cancel($0) } }
        func linha(_ texto: String) {
            print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | teste: \(texto)")
        }
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.sondaFoco", variante])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        func esperarPilula(_ texto: String) -> String {
            let ate = Date.now.addingTimeInterval(15)
            while app.elemento("lancamentos").label != texto && Date.now < ate { usleep(200_000) }
            return app.elemento("lancamentos").label
        }
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa)
        lupa.tap()
        linha("lupa · teclado \(app.keyboards.firstMatch.waitForExistence(timeout: 5))")
        let campo = app.textFields["campoDaBusca"]
        for volta in 1...6 {
            app.digitarComFoco("cimen", em: campo)
            let achou = esperarPilula("Lançamentos, 2 de 46")
            campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5))
            let tudo = esperarPilula("Lançamentos, 46")
            campo.typeText("\n")
            linha("volta \(volta) · \(achou) · \(tudo) · teclado \(app.keyboards.firstMatch.exists)")
        }
    }

    /// Estresse da abertura: do topo da obra, abre a busca pela lupa (o campo entra, a lista rola até a pílula e o teclado
    /// sobe) e fecha pelo ×, doze vezes. Cada volta tem um `campo.apareceu` e um `campo.sumiu` (o ×); a mais, é a pilha
    /// refazendo o campo à vista (visto uma vez no run 40508695109, 0,4 s depois de o teclado subir).
    private func aberturas(_ variante: String) {
        let inicio = Date.now
        let nomes = ["foco.sim", "foco.nao", "campo.apareceu", "campo.sumiu", "edicao.acaba", "teclado.mostra", "teclado.esconde"]
        var tokens: [Int32] = []
        for nome in nomes {
            var token: Int32 = 0
            notify_register_dispatch("br.com.custta.sonda.\(nome)", &token, DispatchQueue.global()) { @Sendable t in
                print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | app: \(nome)")
            }
            tokens.append(token)
        }
        defer { tokens.forEach { notify_cancel($0) } }
        func linha(_ texto: String) {
            print("sonda-foco | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | teste: \(texto)")
        }
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.sondaFoco", variante])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        for volta in 1...12 {
            app.swipeDown(); app.swipeDown()
            let lupa = app.buttons["buscar"]
            app.rolarAte(lupa)
            lupa.tap()
            let teclado = app.keyboards.firstMatch.waitForExistence(timeout: 5)
            sleep(1)
            linha("volta \(volta) · abriu · teclado \(teclado)")
            app.buttons["fecharBusca"].tap()
            _ = app.keyboards.firstMatch.waitForNonExistence(timeout: 5)
            linha("volta \(volta) · fechou")
        }
    }

    func testSondaFocoAberturas1() { aberturas("aberturas") }
    func testSondaFocoAberturas2() { aberturas("aberturas") }
}
