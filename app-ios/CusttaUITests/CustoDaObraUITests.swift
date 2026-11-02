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

    // MARK: protótipo da obra em List (02/11, tarde)

    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    /// As linhas do log do app desta abertura que interessam à rolagem: as peças (aparece, some, altura) e as paradas.
    private func pecasDoLog(desde: Date) -> [String] {
        let pasta = "/tmp/custta-sonda"
        guard let nomes = try? FileManager.default.contentsOfDirectory(atPath: pasta) else { return [] }
        let prefixo = "sonda-\(variante)-"
        var linhas: [String] = []
        for nome in nomes where nome.hasPrefix(prefixo) && nome.hasSuffix(".log") {
            guard let ms = Double(nome.dropFirst(prefixo.count).dropLast(4)), ms / 1000 >= desde.timeIntervalSince1970 - 1,
                  let texto = try? String(contentsOfFile: pasta + "/" + nome, encoding: .utf8) else { continue }
            linhas += texto.split(separator: "\n").map(String.init)
        }
        return linhas
    }

    /// A obra pesada de cima a baixo e de volta, em arrastos rápidos (com impulso): o tempo de cada 10, as peças vivas
    /// (as que apareceram e não sumiram), a maior altura de cartão de mês e as paradas da thread. A memória do app vem do
    /// lado do Mac (memoria.sh), pelas horas das linhas `custo |`.
    private func rolarAPesada(_ letra: [String]) {
        let inicio = Date.now
        let app = abrirApp(conta: "senha", dados: "pesada", abrir: "obra:v1", argumentos: ["-custta.sonda", variante] + letra)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 60))
        print("custo | rolagem\(letra.isEmpty ? "" : " AX5") | abriu em \(String(format: "%.1f", Date.now.timeIntervalSince(inicio))) s | \(String(format: "%.3f", Date.now.timeIntervalSince1970))")
        for sentido in ["desce", "sobe"] {
            var marca = Date.now
            for i in 1...40 {
                if sentido == "desce" { app.swipeUp(velocity: .fast) } else { app.swipeDown(velocity: .fast) }
                if i % 10 == 0 {
                    print("custo | rolagem | \(sentido) \(i): \(String(format: "%.1f", Date.now.timeIntervalSince(marca))) s | \(String(format: "%.3f", Date.now.timeIntervalSince1970))")
                    marca = Date.now
                }
            }
        }
        let log = pecasDoLog(desde: inicio)
        var vivas = Set<String>(), maior = (0, ""), aparicoes = 0, sumicos = 0
        for linha in log {
            if let r = linha.range(of: "aparece ") { vivas.insert(String(linha[r.upperBound...])); aparicoes += 1 }
            if let r = linha.range(of: "some ") { vivas.remove(String(linha[r.upperBound...])); sumicos += 1 }
            if let r = linha.range(of: "altura mes ") {
                let resto = String(linha[r.upperBound...])
                if let h = Int(resto.split(separator: " ").last ?? ""), h > maior.0 { maior = (h, resto) }
            }
        }
        print("custo | rolagem | peças: \(aparicoes) aparições, \(sumicos) sumiços, \(vivas.count) vivas no fim; maior cartão: \(maior.1)")
        for linha in log where linha.contains("parada") || linha.contains("presa") { print("custo | rolagem | app: \(linha)") }
        app.terminate()
    }

    func testCustoAX5() { medir(4, letra: maiorLetra) }
    func testCustoRolagem() { rolarAPesada([]) }
    func testCustoRolagemAX5() { rolarAPesada(maiorLetra) }
}
