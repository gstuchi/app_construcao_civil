import XCTest

/* As auditorias de acessibilidade das telas da análise (etapa 4, marco 2), no arquivo delas: o PR que só mexe na análise
   as roda nos jobs da etapa 4, sem as auditorias do resto do app (spec, "Portões por superfície"). A máquina é a do
   AuditoriaUITests (`AuditoriaDeTela`): o que fica de fora e por quê está lá. */
final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
    /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
    /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
    /// contraste" e com "Reduzir transparência".
    @MainActor func testValeAPenaNoMaiorTamanho() throws {
        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
            try auditar(app, tiposDeAuditoria)
            for _ in 0..<6 {
                rolar(app)
                try auditar(app, tiposDeAuditoria)
            }
            app.terminate()
        }
    }

    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, o veredito no sólido, a faixa e a tabela.
    @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
        for tema in temas {
            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                               argumentos: ["-custta.tema", tema] + solido + parado)
            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            for _ in 0..<2 {
                rolar(app)
                try auditar(app, [.contrast])
            }
            app.terminate()
        }
    }
}
