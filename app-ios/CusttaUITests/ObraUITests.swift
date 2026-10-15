import XCTest

/* A tela da obra (etapa 2, PR 1), com os dados da vitrine (a obra do mockup aprovado: 46 lançamentos, 13 a vencer):
   entrar pela lista e voltar pelo círculo e pela borda; o caminho que sobrevive à troca de aba; os indicadores com os
   números do mockup; o "A vencer" fechado que abre e fecha; e a obra sem gastos. */
@MainActor
final class ObraUITests: XCTestCase {
    func testEntrarPelaListaEVoltarPeloCirculo() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let obra = app.elemento("obra-v1")
        XCTAssertTrue(obra.waitForExistence(timeout: 10))
        obra.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a obra abriu")
        XCTAssertTrue(app.buttons["aba-obras"].exists, "a cápsula de abas fica fixa durante o push")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "voltou para Obras")
    }

    func testVoltarPelaBorda() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.voltarPelaBorda()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "a borda esquerda volta para Obras")
    }

    func testAObraAbertaSobreviveATrocaDeAba() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        app.abrirAba("obras")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "volta para a obra que estava aberta")
    }

    func testIndicadoresComOsNumerosDoMockup() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let total = app.elemento("indicadorTotal")
        XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
        XCTAssertTrue(app.elemento("indicadorCorrigido").label.contains("R$\u{a0}926.847,69"))
        let aPagar = app.elemento("indicadorAPagar").label
        XCTAssertTrue(aPagar.contains("R$\u{a0}13.250,00") && aPagar.contains("3 vencimentos"), aPagar)
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.450.000,00"))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        let fase = app.elemento("faseDaObra").label, lancamentos = app.elemento("lancamentos").label
        XCTAssertTrue(fase.contains("14 meses"), fase)
        XCTAssertTrue(lancamentos.contains("46"), lancamentos)
        let tituloPequeno = app.elemento("tituloPequenoDaBarra")
        XCTAssertFalse(tituloPequeno.exists, "no alto, o nome fica só no título grande")
        app.swipeUp()
        XCTAssertTrue(tituloPequeno.waitForExistence(timeout: 5), "rolada a tela, o nome passa para a barra")
    }

    func testAVencerFechadoAbreEFecha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let aVencer = app.elemento("aVencer")
        XCTAssertTrue(aVencer.waitForExistence(timeout: 10))
        app.rolarAte(aVencer)
        XCTAssertEqual(aVencer.value as? String, "fechado")
        XCTAssertFalse(app.elemento("gasto-g037").exists, "as parcelas futuras não aparecem com o grupo fechado")
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForExistence(timeout: 5), "aberto, mostra o próximo vencimento")
        XCTAssertEqual(aVencer.value as? String, "aberto")
        // Aberto, as linhas ficam juntas como no cartão do mês: entre dois gastos do mesmo mês, só a linha fina.
        let porcelanato = app.elemento("gasto-g032"), tinta = app.elemento("gasto-g045")
        XCTAssertLessThan(abs(tinta.frame.minY - porcelanato.frame.maxY), 1, "o vão entre os gastos é o do cartão do mês")
        app.rolarAte(aVencer)
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForNonExistence(timeout: 5), "fechado de novo, as parcelas somem")
        XCTAssertEqual(aVencer.value as? String, "fechado")
    }

    func testLinhaDoGastoComORotuloDoMockup() {
        // Sem rede, com a pílula "Sem conexão" na barra: rolada a tela, o nome da obra não entra ao lado dela.
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let cimento = app.elemento("gasto-g027")
        app.rolarAte(cimento)
        XCTAssertTrue(cimento.waitForExistence(timeout: 5))
        XCTAssertTrue(cimento.label.hasPrefix("Cimento CP-II, 120 sacos. Materiais básicos, Pix, "), cimento.label)
        XCTAssertEqual(cimento.value as? String, "R$\u{a0}4.980,00")
        app.swipeUp()
        XCTAssertTrue(app.elemento("indicadorSincronizacao").exists)
        XCTAssertFalse(app.elemento("tituloPequenoDaBarra").waitForExistence(timeout: 2),
                       "com a pílula de sincronização, o nome não entra na barra")
        // No fim da rolagem, o último gasto fica à vista, acima da cápsula de abas (mockup: o conteúdo termina 132 pt acima
        // da borda de baixo).
        let ultimo = app.elemento("gasto-g001")
        var fim = -1.0                                   // a pilha cria o último gasto antes de ele entrar na tela
        for _ in 0..<16 {
            app.swipeUp()
            guard ultimo.exists else { continue }
            if ultimo.frame.maxY == fim { break }
            fim = ultimo.frame.maxY
        }
        XCTAssertLessThanOrEqual(ultimo.frame.maxY, app.buttons["aba-obras"].frame.minY, "o último gasto acima da cápsula")
    }

    func testObraSemGastos() {
        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("sem gastos"))
    }
}
