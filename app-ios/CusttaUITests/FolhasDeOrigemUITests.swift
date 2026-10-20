import XCTest
import notify

/* As folhas de origem da etapa 3 (PR 2), na obra da vitrine (46 lançamentos, 3 vencimentos em 30 dias, contados de hoje):
   a seta do indicador abre a folha "A pagar · 30 dias" com o resumo, os vencimentos por mês e a frase do que vem depois;
   a obra sem vencimentos abre a folha vazia, que fecha só pelo × e pelo puxar; a obra apagada em outro aparelho fecha a
   folha. */
@MainActor
final class FolhasDeOrigemUITests: XCTestCase {
    /// A obra aberta (v1, a Casa Alphaville do mockup, por padrão).
    private func abrirObra(_ obra: String = "v1", argumentos: [String] = [], gravacao: String? = nil,
                           extra: [String: String] = [:]) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:\(obra)", gravacao: gravacao, argumentos: argumentos, extra: extra)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        return app
    }

    /// A seta do indicador "A pagar · 30 dias": rola até ele e toca; a folha abre com o resumo.
    private func abrirAPagar(_ app: XCUIApplication) {
        let indicador = app.elemento("indicadorAPagar")
        XCTAssertTrue(indicador.waitForExistence(timeout: 5))
        app.rolarAte(indicador)
        indicador.tap()
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForExistence(timeout: 5), "a seta abre a folha do A pagar")
    }

    /// O elemento da folha (o que recebe o toque), e não o da obra por trás dela.
    private func naFolha(_ app: XCUIApplication, _ id: String) -> XCUIElement? {
        app.descendants(matching: .any).matching(identifier: id).allElementsBoundByIndex.first { $0.exists && $0.isHittable }
    }

    private func puxarFolha(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)),
                   withVelocity: .fast, thenHoldForDuration: 0)
    }

    /// AAAA-MM de hoje + `dias`, no fuso do aparelho (o do app).
    private func mes(daquiA dias: Int) -> String {
        let dia = Calendar(identifier: .gregorian).date(byAdding: .day, value: dias, to: .now) ?? .now
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: dia)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    func testASetaDoIndicadorAbreAFolhaDoAPagar() {
        let app = abrirObra()
        let indicador = app.elemento("indicadorAPagar")
        XCTAssertTrue(indicador.waitForExistence(timeout: 5))
        XCTAssertTrue(indicador.label.hasPrefix("A pagar · 30 dias"), indicador.label)
        XCTAssertTrue(indicador.label.contains("Parcelas e gastos futuros"), indicador.label)
        XCTAssertTrue(indicador.elementType == .button, "a linha inteira é o botão: \(indicador.elementType.rawValue)")
        abrirAPagar(app)
        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("A pagar · 30 dias"), app.elemento("tituloDaFolha").label)
        let resumo = app.elemento("resumoDoAPagar")
        XCTAssertTrue(resumo.label.contains("R$\u{a0}13.250,00"), resumo.label)
        XCTAssertTrue(resumo.label.contains("3 vencimentos · a partir de amanhã"), resumo.label)
        // Os três vencimentos do indicador, o próximo primeiro (a ordem do aPagar), com a linha da etapa 2.
        let ids = ["g039", "g032", "g045"]
        let linhas = ids.compactMap { naFolha(app, "gasto-\($0)") }
        XCTAssertEqual(linhas.count, 3, "os três vencimentos na folha")
        if linhas.count == 3 {
            XCTAssertLessThan(linhas[0].frame.minY, linhas[1].frame.minY)
            XCTAssertLessThan(linhas[1].frame.minY, linhas[2].frame.minY)
            XCTAssertTrue(linhas[2].label.hasPrefix("Tinta acrílica, parcela 2 de 3. Pintura, Cartão, "), linhas[2].label)
            XCTAssertEqual(linhas[2].value as? String, "R$\u{a0}2.300,00")
        }
        // Agrupados por mês: o cabeçalho do mês do 2º vencimento, com o total dele (o do 3º, se for o mesmo mês).
        let mesDoSegundo = mes(daquiA: 24)
        let total = mes(daquiA: 25) == mesDoSegundo ? "R$\u{a0}8.450,00" : "R$\u{a0}6.150,00"
        let cabecalho = naFolha(app, "mes-\(mesDoSegundo)")
        XCTAssertNotNil(cabecalho, "o cabeçalho do mês")
        XCTAssertTrue(cabecalho?.label.contains(total) == true, cabecalho?.label ?? "")
        if let cabecalho, linhas.count == 3 { XCTAssertLessThan(cabecalho.frame.maxY, linhas[1].frame.minY + 1) }
        // A frase do fim: o que vem depois dos 30 dias está no "A vencer" da obra.
        let ponte = app.elemento("ponteDoAPagar")
        XCTAssertTrue(ponte.exists)
        XCTAssertTrue(ponte.label.hasPrefix("Depois de "), ponte.label)
        XCTAssertTrue(ponte.label.hasSuffix("mais 10 gastos a vencer (R$\u{a0}52.250,00), no \"A vencer\" da obra."), ponte.label)
        let fechar = app.buttons.matching(NSPredicate(format: "label == 'Fechar'")).allElementsBoundByIndex
        XCTAssertEqual(fechar.map(\.identifier), ["fecharFolha"], "só o × se chama Fechar: o botão \"Fechar\" do site sai")
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(app.elemento("resumoDoAPagar").waitForNonExistence(timeout: 5), "o × fecha")
    }

    func testObraSemVencimentosAbreAFolhaVazia() {
        let app = abrirObra("v2")
        abrirAPagar(app)
        let resumo = app.elemento("resumoDoAPagar")
        XCTAssertTrue(resumo.label.contains("R$\u{a0}0,00"), resumo.label)
        XCTAssertTrue(resumo.label.contains("0 vencimentos · a partir de amanhã"), resumo.label)
        let vazio = app.elemento("aPagarVazio")
        XCTAssertTrue(vazio.exists)
        XCTAssertEqual(vazio.label, "Nenhum gasto previsto para esse período.")
        XCTAssertFalse(app.elemento("ponteDoAPagar").exists, "nada depois dos 30 dias: sem a frase")
        sleep(1)
        XCTAssertTrue(resumo.exists, "vazia, a folha fica aberta")
        puxarFolha(app)
        XCTAssertTrue(resumo.waitForNonExistence(timeout: 5), "puxar fecha, sem perguntar")
    }

    func testAFolhaFechaQuandoOutroAparelhoApagaAObra() {
        let app = abrirObra(extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        abrirAPagar(app)
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.buttons["fecharFolha"].waitForNonExistence(timeout: 10), "a obra sumiu: a folha fecha")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "e a obra volta para a lista")
    }
}
