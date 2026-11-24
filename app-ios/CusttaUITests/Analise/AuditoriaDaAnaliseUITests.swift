import XCTest

/* As auditorias de acessibilidade das telas da análise (etapa 4, marco 2), no arquivo delas: o PR que só mexe na análise
   as roda nos jobs da etapa 4, sem as auditorias do resto do app (spec, "Portões por superfície"). A máquina é a do
   AuditoriaUITests (`AuditoriaDeTela`): o que fica de fora e por quê está lá. */
final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
    /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
    /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
    /// contraste" e com "Reduzir transparência". Antes de rolar, as teclas do preço abertas no lugar da cápsula.
    @MainActor func testValeAPenaNoMaiorTamanho() throws {
        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
            try auditar(app, tiposDeAuditoria)
            try auditarComAsTeclasDoPreco(app, tiposDeAuditoria)
            for _ in 0..<6 {
                rolar(app)
                try auditar(app, tiposDeAuditoria)
            }
            app.terminate()
        }
    }

    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, as teclas do preço, o veredito no sólido,
    /// a faixa e a tabela.
    @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
        for tema in temas {
            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                               argumentos: ["-custta.tema", tema] + solido + parado)
            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            try auditarComAsTeclasDoPreco(app, [.contrast])
            for _ in 0..<2 {
                rolar(app)
                try auditar(app, [.contrast])
            }
            app.terminate()
        }
    }

    /// Abre as teclas do preço, audita com elas à vista e fecha pelo "OK". Na maior letra, a linha do preço fica abaixo da
    /// dobra: a tela rola até ela antes do toque.
    @MainActor private func auditarComAsTeclasDoPreco(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
        let preco = app.elemento("simPreco"), ok = app.buttons["teclasDoPreco-ok"]
        app.rolarAte(preco)
        preco.tap()
        XCTAssertTrue(ok.waitForExistence(timeout: 5), "as teclas do preço")
        Thread.sleep(forTimeInterval: 1)                                   // a rolagem que põe a linha à vista assenta
        try auditar(app, tipos)
        ok.tap()
        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
    }
}
