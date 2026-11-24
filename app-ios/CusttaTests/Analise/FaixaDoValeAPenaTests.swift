import Testing
import SwiftUI
import CusttaNucleo
@testable import Custta

/* O desenho da faixa "Onde a sua venda cai": cada marca no x que o núcleo deu, como fração da largura. A conta sai de uma
   obra com um gasto só de R$ 1.000.000,00, pela regra do núcleo (`contaSimulador` e `faixaSimulador`). */
@MainActor
struct FaixaDoValeAPenaTests {
    private func faixa(venda: Double, gastoEm data: String = "2026-10-12") throws -> FaixaDoSimulador {
        let obra = Obra(arvore: ["id": .texto("o"), "nome": .texto("Obra"), "dataInicio": .texto(data),
                                 "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1_000_000), "data": .texto(data)])])])
        return faixaSimulador(try #require(contaSimulador(obra, venda: venda, meses: 0, hoje: "2026-10-12", taxa: 1)))
    }

    @Test func cadaMarcaNoXDaFracaoDela() throws {
        // Gasto de hoje: o empate é o próprio custo. A escala vai de 970 mil a 2,06 milhões.
        let x = DesenhoDaFaixa.posicoes(try faixa(venda: 2_000_000), largura: 300)
        #expect(abs((x[.custo] ?? -1) - 8.2568807339) < 1e-6)
        #expect(abs((x[.empate] ?? -1) - 8.2568807339) < 1e-6)
        #expect(abs((x[.venda] ?? -1) - 283.4862385321) < 1e-6)
    }

    @Test func aVendaAbaixoDoBancoFicaAEsquerdaDoEmpate() throws {
        // Gasto de um ano atrás: corrigido a 1% ao mês, o empate passa de R$ 1,12 milhão, e a venda de R$ 1,05 milhão fica
        // entre o custo e ele, fora da zona hachurada, que vai do empate ao fim.
        let f = try faixa(venda: 1_050_000, gastoEm: "2025-10-12")
        let x = DesenhoDaFaixa.posicoes(f, largura: 300)
        #expect(!f.acima)
        #expect((x[.custo] ?? 0) < (x[.venda] ?? 0))
        #expect((x[.venda] ?? 0) < (x[.empate] ?? 0))
    }
}
