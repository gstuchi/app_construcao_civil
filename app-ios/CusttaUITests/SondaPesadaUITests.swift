import XCTest

/* Sonda temporária (ramo proto/, nunca na main): a obra pesada (`CUSTTA_DADOS=pesada`, 566 lançamentos) na maior letra,
   aberta e rolada 40 arrastos para baixo e 40 para cima por coordenada, sem consultar a tela no meio. No fim, lê o log da
   vigia do app (/tmp/custta-sonda) e imprime uma linha `sonda-pesada | …` com a abertura e as paradas. */
final class SondaPesadaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    @MainActor func testPesadaNaMaiorLetra() {
        let inicio = Date.now
        let nome = "pesada\(Int(inicio.timeIntervalSince1970))"
        let app = abrirApp(conta: "senha", dados: "pesada", abrir: "obra:v1", argumentos: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-custta.sonda", nome])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 90))
        let abriu = Date.now.timeIntervalSince(inicio)
        let baixo = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let alto = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        let antes = Date.now
        for _ in 1...40 { baixo.press(forDuration: 0.01, thenDragTo: alto, withVelocity: .fast, thenHoldForDuration: 0) }
        let desceu = Date.now.timeIntervalSince(antes)
        for _ in 1...40 { alto.press(forDuration: 0.01, thenDragTo: baixo, withVelocity: .fast, thenHoldForDuration: 0) }
        let rolou = Date.now.timeIntervalSince(antes)
        sleep(2)
        var paradas: [Int] = []
        let pasta = "/tmp/custta-sonda"
        for arquivo in (try? FileManager.default.contentsOfDirectory(atPath: pasta)) ?? [] where arquivo.hasPrefix("sonda-\(nome)-") {
            let texto = (try? String(contentsOfFile: pasta + "/" + arquivo, encoding: .utf8)) ?? ""
            for linha in texto.split(separator: "\n") {
                if let r = linha.range(of: "parada "), let ms = Int(linha[r.upperBound...].split(separator: " ")[0]) { paradas.append(ms) }
            }
        }
        let grandes = paradas.filter { $0 >= 1000 }
        print(String(format: "sonda-pesada | abriu %.1f s | desceu 40 em %.1f s | rolou 80 em %.1f s | paradas %d, ≥1 s: %d somando %.1f s, maior %.1f s | %@",
                     abriu, desceu, rolou, paradas.count, grandes.count, Double(grandes.reduce(0, +)) / 1000,
                     Double(paradas.max() ?? 0) / 1000, grandes.map { String($0) }.joined(separator: " ")))
        app.terminate()
    }
}
