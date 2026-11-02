import XCTest

/* Sonda das falhas do iOS 26 no #99 (02/11/2026, temporária, só em ramo proto/). Cada método é uma variante (o app travado
   encerra o teste, e o que vem depois se perderia); a variante chega ao app por `-custta.sonda`. Uma linha por passo no log:
   `sonda-a | …` e `sonda-b | …`. (a): a lupa na maior letra, como o BuscaUITests (até 30 arrastos; o original para em 20).
   (b): a cena "busca, achados, escuro" do laudo, como o LeituraNoVidroUITests (rolagem fixa 1118, "ceramica" e o buscar do
   teclado). */
@MainActor
final class Sonda26UITests: XCTestCase {
    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"]
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    private func linha(_ sonda: String, _ variante: String, _ inicio: Date, _ texto: String) {
        print("\(sonda) | \(variante) | t=\(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) | "
              + "\(String(format: "%.3f", Date.now.timeIntervalSince1970)) | \(texto)")
    }

    private func sondaA(_ variante: String) {
        let inicio = Date.now
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + ["-custta.sonda", variante])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        linha("sonda-a", variante, inicio, "abriu")
        let lupa = app.buttons["buscar"]
        let capsula = app.buttons["aba-obras"]
        let limite = (capsula.exists ? capsula.frame.minY : app.frame.maxY) - 16
        var arrastos = 0, chegou = false
        while arrastos < 30 {
            if lupa.exists && lupa.isHittable && lupa.frame.maxY < limite { chegou = true; break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)),
                       withVelocity: .slow, thenHoldForDuration: 0.3)
            arrastos += 1
            linha("sonda-a", variante, inicio, "arrasto \(arrastos), lupa \(lupa.exists ? "y=\(Int(lupa.frame.minY))" : "fora da árvore")")
        }
        linha("sonda-a", variante, inicio, "resultado: \(chegou ? "chegou" : "não chegou") em \(arrastos) arrastos"
              + " (o original para em 20: \(chegou && arrastos <= 20 ? "passaria" : "reprovaria"))")
        XCTAssertTrue(chegou && arrastos <= 20, "a lupa acima da cápsula em até 20 arrastos")
        app.terminate()
    }

    func testA1Controle() { sondaA("controle") }
    func testA2SemPosicao() { sondaA("semPosicao") }
    func testA3Conserto() { sondaA("blocosSoltos") }
    func testA4Controle() { sondaA("controle") }
    func testA5SemPosicao() { sondaA("semPosicao") }
    func testA6Conserto() { sondaA("blocosSoltos") }
    func testA7Controle() { sondaA("controle") }
    func testA8SemPosicao() { sondaA("semPosicao") }
    func testA9Conserto() { sondaA("blocosSoltos") }

    /// O log do app desta abertura (o mais novo da variante, criado depois de `desde`), lido do /tmp do Mac.
    private func logDoApp(_ variante: String, desde: Date) -> String? {
        let pasta = "/tmp/custta-sonda"
        guard let nomes = try? FileManager.default.contentsOfDirectory(atPath: pasta) else { return nil }
        let prefixo = "sonda-\(variante)-"
        let achados = nomes.filter { $0.hasPrefix(prefixo) && $0.hasSuffix(".log") }
            .compactMap { nome -> (Double, String)? in
                guard let ms = Double(nome.dropFirst(prefixo.count).dropLast(4)) else { return nil }
                return (ms / 1000, nome)
            }
            .filter { $0.0 >= desde.timeIntervalSince1970 - 1 }
            .sorted { $0.0 > $1.0 }
        guard let nome = achados.first?.1 else { return nil }
        return try? String(contentsOfFile: pasta + "/" + nome, encoding: .utf8)
    }

    /// Espera até `segundos` pela vigia do app dizer "presa há 4 s".
    private func travou(_ variante: String, desde: Date, segundos: Double) -> Bool {
        let ate = Date.now.addingTimeInterval(segundos)
        repeat {
            if logDoApp(variante, desde: desde)?.contains("presa há 4 s") == true { return true }
            usleep(500_000)
        } while Date.now < ate
        return false
    }

    private func sondaB(_ variante: String, rolagem: Bool = true) {
        let inicio = Date.now
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
                           argumentos: ["-custta.tema", "escuro"] + piorMomento + (rolagem ? ["-custta.rolagem", "1118"] : [])
                               + ["-custta.sonda", variante])
        XCTAssertTrue(app.elemento(rolagem ? "tituloPequenoDaBarra" : "tituloDaObra").waitForExistence(timeout: 30))
        linha("sonda-b", variante, inicio, "abriu")
        app.buttons["buscar"].tap()
        linha("sonda-b", variante, inicio, "tocou a lupa")
        if travou(variante, desde: inicio, segundos: 7) {
            linha("sonda-b", variante, inicio, "resultado: travou depois da lupa")
            app.terminate()
            return XCTFail("travou depois da lupa")
        }
        app.digitarComFoco("ceramica\n", em: app.textFields["campoDaBusca"])
        linha("sonda-b", variante, inicio, "digitou")
        if travou(variante, desde: inicio, segundos: 7) {
            linha("sonda-b", variante, inicio, "resultado: travou depois de digitar")
            app.terminate()
            return XCTFail("travou depois de digitar")
        }
        let fechou = app.keyboards.firstMatch.waitForNonExistence(timeout: 5)
        let soma = app.elemento("somaDosAchados").exists
        linha("sonda-b", variante, inicio, "resultado: \(fechou ? "passou" : "teclado não fechou"), soma \(soma)")
        XCTAssertTrue(fechou, "o buscar do teclado o fecha")
        app.terminate()
    }

    func testB1Controle() { sondaB("controle") }
    func testB2SemRefixar() { sondaB("semRefixar") }
    func testB3Olhos() { sondaB("olhos") }
    func testB4Controle() { sondaB("controle") }
    func testB5SemRefixar() { sondaB("semRefixar") }
    func testB6BlocosSoltos() { sondaB("blocosSoltos") }
    func testB7PilhaComum() { sondaB("pilhaComum") }
    func testB8SemRolagemFixa() { sondaB("controle", rolagem: false) }
    func testB9Controle() { sondaB("controle") }
    func testBASemPosicaoSemRolagem() { sondaB("semPosicao", rolagem: false) }
    func testBBBlocosSoltos() { sondaB("blocosSoltos") }
    func testBCPilhaComum() { sondaB("pilhaComum") }
    func testBDSemPosicaoSemRolagem() { sondaB("semPosicao", rolagem: false) }
    func testBESemRolagemFixa() { sondaB("controle", rolagem: false) }
}
