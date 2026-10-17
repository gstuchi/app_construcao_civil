import XCTest
import notify

/* Os estados da etapa 2, parte 3, e o gasto numa obra vendida: a lista vazia que convida ao +; o + que avisa enquanto os
   dados não chegam; o gasto lançado de dentro de uma vendida, que vai para uma aberta escolhida na linha "Obra"; sem
   conexão, gravar continua; o "Não salvou" que não passa sozinho alerta uma vez e tocar na pílula tenta de novo; com
   uma folha aberta, ele espera a folha descer. */
@MainActor
final class EstadosUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testListaVaziaConvidaParaOMais() {
        let app = abrirApp(conta: "senha", dados: "vazio")
        let vazio = app.elemento("obrasVazio")
        XCTAssertTrue(vazio.waitForExistence(timeout: 10))
        XCTAssertEqual(vazio.label, "Nenhuma obra ainda.")
        XCTAssertTrue(app.staticTexts["Toque no + para criar a primeira obra."].exists)
        XCTAssertEqual(app.buttons["botaoMais"].label, "Nova obra")
    }

    func testCarregandoOMaisAvisaEmVezDeAbrir() {
        let app = abrirApp(conta: "senha", leitura: "nunca")
        XCTAssertTrue(app.elemento("obrasCarregando").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["OK"].tap()
        XCTAssertFalse(app.textFields["nomeDaObra"].exists, "sem ver os dados, \"Nova obra\" não abre")
    }

    func testMaisNumaObraVendidaLancaNumaAberta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let mais = app.buttons["botaoMais"]
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        XCTAssertEqual(mais.label, "Lançar gasto")
        mais.tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in ["1", "3", "8", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        let linha = app.elemento("linhaObra")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Casa Alphaville", "vem a primeira aberta da lista de obras")
        XCTAssertEqual(app.elemento("notaObraVendida").label, "Casa Tamboré 4 está vendida; o gasto vai para uma obra aberta.")
        // O grupo do valor a 22 pt da nota: os 20 do espaço entre grupos e os 2 que faltam embaixo da nota (o .f-rod do
        // mockup é 36 pt em duas linhas de 18; o footnote ocupa 33,7).
        XCTAssertEqual(app.elemento("linhaValor").frame.minY - app.elemento("notaObraVendida").frame.maxY, 22, accuracy: 0.5)
        linha.tap()
        let sobrado = app.buttons["obraAberta-v2"]
        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["obraAberta-v3"].exists, "a vendida não entra na escolha")
        sobrado.tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Sobrado Granja Viana")
        app.buttons["salvarGasto"].tap()
        let titulo = app.elemento("tituloDaObra")
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(titulo.label, "Sobrado Granja Viana", "a folha desce na obra que recebeu o gasto")
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("6 lançamentos"), app.elemento("indicadorTotal").label)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v3").waitForExistence(timeout: 5), "o voltar leva à lista")
    }

    func testGastoDeObraVendidaContinuaEditavel() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let gasto = app.elemento("gasto-v3g3")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.rolarAte(gasto)
        gasto.tap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "abre \"Editar gasto\"")
        XCTAssertFalse(app.elemento("linhaObra").exists, "editar não troca a obra")
    }

    /// Trocar a obra na linha "Obra" troca os "Usados nesta obra" pelos dela (a Casa Alphaville tem três; o Sobrado, só
    /// "Outros"), e o tópico escolhido fica.
    func testTrocarAObraTrocaOsUsadosNestaObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let linha = lancarDeDentroDaVendida(app)
        let topico = app.elemento("linhaTopico")
        let usados = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'usado-'"))
        topico.tap()
        XCTAssertTrue(usados.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(usados.count, 3, "os três tópicos mais usados na Casa Alphaville")
        usados.element(boundBy: 2).tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        let nome = topico.value as? String
        linha.tap()
        app.buttons["obraAberta-v2"].tap()
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertEqual(linha.value as? String, "Sobrado Granja Viana")
        XCTAssertEqual(topico.value as? String, nome, "o tópico escolhido fica")
        topico.tap()
        XCTAssertTrue(app.buttons["usado-outros"].waitForExistence(timeout: 5))
        XCTAssertEqual(usados.count, 1, "o Sobrado só usa \"Outros\"")
    }

    /// Toque duplo no "Salvar" da folha lançada de dentro da vendida: um gasto só, na obra escolhida.
    func testToqueDuploNoSalvarDaVendidaLancaUmGasto() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        _ = lancarDeDentroDaVendida(app)
        app.buttons["salvarGasto"].doubleTap()
        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
        sleep(1)
        XCTAssertEqual(app.elemento("tituloDaObra").label, "Casa Alphaville")
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("47 lançamentos"), app.elemento("indicadorTotal").label)
    }

    /// Na maior letra o nome da obra quebra embaixo do rótulo e fica à esquerda, como no mockup (`.f-lin .d` alinhado à
    /// esquerda na AX5): a 1ª linha do nome ("Casa") começa onde começa o rótulo "Obra", e não à direita, em cima de
    /// "Alphaville".
    func testNaMaiorLetraONomeDaObraFicaAEsquerda() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3",
                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let linha = lancarDeDentroDaVendida(app)
        XCTAssertEqual(linha.value as? String, "Casa Alphaville")
        let faixas = tintaPorPixel(linha).faixas
        guard faixas.count >= 2 else { return XCTFail("o rótulo e o nome, por pixel: \(faixas)") }
        XCTAssertEqual(faixas[1].x, faixas[0].x, accuracy: 6, "a 1ª linha do nome começa onde começa o rótulo: \(faixas)")
    }

    /// Na maior letra, a seta da linha "Obra" fica na ponta direita, centrada na linha, e não segue o nome (o `.f-lin .chev`
    /// do mockup na AX5), e a nota fica a 22 pt da borda, como o `.f-rod` (34 na letra padrão).
    func testNaMaiorLetraASetaFicaNaPontaEANotaA22() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3",
                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let linha = lancarDeDentroDaVendida(app)
        continueAfterFailure = true     // as duas medidas são independentes
        let direita = tintaPorPixel(linha).direita
        XCTAssertGreaterThan(direita, linha.frame.width - 24, "a seta termina a 16 pt da ponta da linha: \(direita)")
        XCTAssertEqual(app.elemento("notaObraVendida").frame.minX, 22, accuracy: 0.5)
    }

    /// A tinta de uma linha sólida da folha, por pixel: o que se afasta do fundo (lido perto da beira esquerda), fora dos
    /// 8 pt de cada beira, em pontos. `faixas`: linhas de pixel seguidas com tinta, de cima para baixo, com o topo e o x da
    /// tinta mais à esquerda nos primeiros 20 pt da faixa (mais abaixo a seta, centrada no nome, pode encostar); traço fino
    /// (borda, separador) não conta como faixa. `direita`: o x da tinta mais à direita.
    private func tintaPorPixel(_ elemento: XCUIElement) -> (faixas: [(topo: CGFloat, x: CGFloat)], direita: CGFloat) {
        guard let cg = elemento.screenshot().image.cgImage else { return ([], 0) }
        let (l, a, e) = (cg.width, cg.height, CGFloat(cg.width) / elemento.frame.width)
        var px = [UInt8](repeating: 0, count: l * a * 4)
        let desenhou = px.withUnsafeMutableBytes { b -> Bool in
            guard let c = CGContext(data: b.baseAddress, width: l, height: a, bitsPerComponent: 8, bytesPerRow: l * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            c.draw(cg, in: CGRect(x: 0, y: 0, width: l, height: a))
            return true
        }
        guard desenhou else { return ([], 0) }
        let fundo = ((a / 2) * l + Int(4 * e)) * 4
        let colunas = Int(8 * e)..<(l - Int(8 * e))
        func tinta(_ x: Int, _ y: Int) -> Bool {
            (0..<3).contains { abs(Int(px[(y * l + x) * 4 + $0]) - Int(px[fundo + $0])) > 64 }
        }
        let primeira: [Int?] = (0..<a).map { y in colunas.first { tinta($0, y) } }
        let ultima = (0..<a).compactMap { y in colunas.reversed().first { tinta($0, y) } }.max() ?? 0
        var faixas: [(topo: CGFloat, x: CGFloat)] = []
        var y = 0
        while y < a {
            guard primeira[y] != nil else { y += 1; continue }
            var fim = y
            while fim + 1 < a, primeira[fim + 1] != nil { fim += 1 }
            if CGFloat(fim - y + 1) >= 6 * e {
                let x = (y...min(fim, y + Int(20 * e))).compactMap { primeira[$0] }.min() ?? 0
                faixas.append((CGFloat(y) / e, CGFloat(x) / e))
            }
            y = fim + 1
        }
        return (faixas, CGFloat(ultima) / e)
    }

    /// Sem nenhuma obra aberta, o + da vendida cria obra, como no site (o formGasto e o + chamam o formNovaObra).
    func testMaisNaVendidaSemObraAbertaCriaObra() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        apagarPeloLapis(app, "v1")
        app.elemento("obra-v2").tap()
        apagarPeloLapis(app, "v2")
        app.elemento("obra-v3").tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
        let mais = app.buttons["botaoMais"]
        XCTAssertEqual(mais.label, "Nova obra", "nenhuma obra aberta para receber o gasto")
        mais.tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 5), "abre \"Nova obra\"")
        XCTAssertFalse(app.elemento("visorDoValor").exists)
    }

    /// Na Casa Tamboré 4 (vendida): + → o valor no teclado → "Avançar"; devolve a linha "Obra" dos detalhes.
    private func lancarDeDentroDaVendida(_ app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in "100" { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        let linha = app.elemento("linhaObra")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        return linha
    }

    /// "Apagar obra" pelo lápis da obra aberta; volta à lista sem ela.
    private func apagarPeloLapis(_ app: XCUIApplication, _ id: String) {
        let lapis = app.buttons["editarObra"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        let apagar = app.buttons["apagarObra"]
        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
        apagar.tap()
        let alerta = app.alerts.firstMatch
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Apagar obra"].tap()
        XCTAssertTrue(app.elemento("obra-\(id)").waitForNonExistence(timeout: 10), "a obra sai da lista")
    }

    func testSemConexaoGravarContinua() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 10))
        XCTAssertEqual(pilula.label, "Sem conexão")
        let pronta = app.buttons["acao-marcarPronta"]
        app.rolarAte(pronta)
        pronta.tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5), "a fase muda na hora, sem rede")
        XCTAssertEqual(pilula.label, "Sem conexão")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testNaoSalvouAlertaUmaVezETocarTentaDeNovo() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        app.rolarAte(pronta)
        pronta.tap()
        let alerta = app.alerts["Não salvou na nuvem"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Confira sua conexão e conta; toque no aviso para tentar novamente."].exists)
        alerta.buttons["Tentar de novo"].tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3))
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 5))
        XCTAssertFalse(alerta.waitForExistence(timeout: 3), "o mesmo erro não alerta de novo")
        XCTAssertEqual(pilula.label, "Não salvou")
        pilula.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3), "tocar na pílula tenta de novo")
        XCTAssertFalse(alerta.waitForExistence(timeout: 3))
        XCTAssertEqual(pilula.label, "Não salvou")
    }

    /// A recusa que chega com uma folha aberta espera a folha descer: o alerta por cima derrubava a folha, e o que a pessoa
    /// tinha preenchido se perdia.
    func testNaoSalvouEsperaAFolhaDescer() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa",
                           extra: ["CUSTTA_GRAVACAO_ESPERA": "aviso"])
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        app.rolarAte(pronta)
        pronta.tap()
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in "4980" { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5))
        notify_post("br.com.custta.falso.responderGravacao")
        let alerta = app.alerts["Não salvou na nuvem"]
        XCTAssertFalse(alerta.waitForExistence(timeout: 3), "com a folha aberta, o alerta espera")
        XCTAssertTrue(app.elemento("linhaTopico").exists, "a folha continua, com o que foi preenchido")
        app.buttons["fecharFolha"].tap()
        app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5), "a folha desceu: agora o alerta")
    }
}
