import XCTest
import notify

/// Sonda da cena "A pagar, fim" do laudo no iOS 26 (27/10, temporária): abre a cena como o laudo e mede quanto a
/// `ponteDoAPagar` leva para existir (até 40 s), com os avisos do app numa linha `sonda-fim | …`.
@MainActor
final class SondaFimUITests: XCTestCase {
    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"]

    private func sonda(_ variante: String, rolagem: Bool = true) {
        let inicio = Date.now
        func agora() -> String { String(format: "%.1f", Date.now.timeIntervalSince(inicio)) }
        var tokens: [Int32] = []
        for nome in ["parada", "congelou", "fixa", "refixa"] {
            var token: Int32 = 0
            notify_register_dispatch("br.com.custta.sondaFim.\(nome)", &token, DispatchQueue.global()) { @Sendable t in
                var estado: UInt64 = 0
                notify_get_state(t, &estado)
                print("sonda-fim | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | app: \(nome) \(estado)")
            }
            tokens.append(token)
        }
        defer { tokens.forEach { notify_cancel($0) } }
        let app = abrirApp(conta: "senha", dados: "topicoLongo", abrir: "obra:v1", folha: "aPagar:v1",
                           argumentos: ["-custta.tema", "escuro"] + piorMomento + (rolagem ? ["-custta.rolagem", "1092"] : [])
                               + ["-custta.sondaFim", variante])
        let alvo = app.elemento(rolagem ? "ponteDoAPagar" : "resumoDoAPagar")
        print("sonda-fim | \(variante) | t=\(agora()) | teste: abriu")
        let ate = Date.now.addingTimeInterval(40)
        var consultas = 0
        while !alvo.exists && Date.now < ate { consultas += 1; usleep(250_000) }
        print("sonda-fim | \(variante) | t=\(agora()) | teste: alvo \(alvo.exists) depois de \(consultas) consultas")
        app.terminate()
    }

    func testSondaFimControle1() { sonda("controle") }
    func testSondaFimControle2() { sonda("controle") }
    func testSondaFimControle3() { sonda("controle") }
    func testSondaFimSemObraFixa1() { sonda("semObraFixa") }
    func testSondaFimSemObraFixa2() { sonda("semObraFixa") }
    func testSondaFimSemObraFixa3() { sonda("semObraFixa") }
    func testSondaFimSemRolagem1() { sonda("semRolagem", rolagem: false) }
    func testSondaFimSemRolagem2() { sonda("semRolagem", rolagem: false) }
}
