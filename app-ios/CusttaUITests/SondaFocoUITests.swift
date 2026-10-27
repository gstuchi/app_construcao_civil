import XCTest
import notify

/// Sonda do foco da busca no iOS 26 (27/10, temporária): o fluxo do achado 3 com os avisos do app (SondaFoco) impressos
/// com o tempo, numa linha `sonda-foco | variante | t=… | …`. Uma variante por teste.
@MainActor
final class SondaFocoUITests: XCTestCase {
    private func sonda(_ variante: String) {
        let inicio = Date.now
        let nomes = ["foco.sim", "foco.nao", "campo.apareceu", "campo.sumiu", "edicao.comeca", "edicao.acaba", "teclado.mostra",
                     "teclado.esconde", "texto", "parada"]
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

    func testSondaFocoNenhum1() { sonda("nenhum") }
    func testSondaFocoNenhum2() { sonda("nenhum") }
    func testSondaFocoVstack() { sonda("vstack") }
    func testSondaFocoLento() { sonda("lento") }
    func testSondaFocoLentoVstack() { sonda("lentoVstack") }
}
