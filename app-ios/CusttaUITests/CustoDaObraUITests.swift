import XCTest

/* Custo da obra pesada (prova de 02/11, temporária, só em ramo proto/): a Casa Alphaville com +520 gastos
   (`CUSTTA_DADOS=pesada`), no 26.5. Mede, do lado do teste, o tempo de abrir a obra e o de cada letra da busca, e lê do log
   do app (/tmp/custta-sonda) as paradas da thread principal acima de 250 ms. Uma linha `custo | …` por medida. */
@MainActor
final class CustoDaObraUITests: XCTestCase {
    private var variante: String { ProcessInfo.processInfo.environment["CUSTTA_SONDA"] ?? "controle" }

    private func paradas(desde: Date) -> [String] {
        let pasta = "/tmp/custta-sonda"
        guard let nomes = try? FileManager.default.contentsOfDirectory(atPath: pasta) else { return [] }
        var linhas: [String] = []
        let prefixo = "sonda-\(variante)-"
        for nome in nomes where nome.hasPrefix(prefixo) && nome.hasSuffix(".log") {
            guard let ms = Double(nome.dropFirst(prefixo.count).dropLast(4)), ms / 1000 >= desde.timeIntervalSince1970 - 1,
                  let texto = try? String(contentsOfFile: pasta + "/" + nome, encoding: .utf8) else { continue }
            linhas += texto.split(separator: "\n").map(String.init).filter { $0.contains("parada") || $0.contains("presa") || $0.contains("altura mes") }
        }
        return linhas
    }

    private func medir(_ volta: Int, letra: [String] = []) {
        let inicio = Date.now
        let app = abrirApp(conta: "senha", dados: "pesada", abrir: "obra:v1", argumentos: ["-custta.sonda", variante] + letra)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 60))
        let abrir = Date.now.timeIntervalSince(inicio)
        let lupa = app.buttons["buscar"]
        app.rolarAte(lupa, tentativas: 30)
        lupa.tap()
        let campo = app.textFields["campoDaBusca"]
        XCTAssertTrue(campo.waitForExistence(timeout: 10))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        var tempos: [String] = []
        var digitado = ""
        for letraDigitada in ["c", "i", "m", "e", "n", "t", "o"] {
            let antes = Date.now
            campo.typeText(letraDigitada)
            digitado += letraDigitada
            let ate = Date.now.addingTimeInterval(20)
            while campo.value as? String != digitado && Date.now < ate { usleep(50_000) }
            tempos.append(String(format: "%.2f", Date.now.timeIntervalSince(antes)))
        }
        let pilula = app.elemento("lancamentos").label
        print("custo | volta \(volta)\(letra.isEmpty ? "" : " AX5") | abrir \(String(format: "%.1f", abrir)) s | letras \(tempos.joined(separator: " ")) s | \(pilula)")
        for linha in paradas(desde: inicio) { print("custo | volta \(volta) | app: \(linha)") }
        app.terminate()
    }

    func testCusto1() { medir(1) }
    func testCusto2() { medir(2) }
    func testCusto3() { medir(3) }
}
