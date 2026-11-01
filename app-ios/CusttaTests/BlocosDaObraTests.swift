import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O alto da obra em blocos (etapa 4, PR 1c): o que o sólido mostra em cada fase (o lucro na vendida com lucro, decisão 4:
   A; o Total gasto no resto, e na vendida com prejuízo, B), o sinal dos valores, e os blocos montados sem passar da largura
   em nenhum tamanho de letra, com o maior valor no sólido (o irmão fracionário alargava a coluna inteira; memória
   `irmao-fracionario-passa-um-pixel`). */
@MainActor
struct BlocosDaObraTests {
    /// Uma obra com um gasto de 100 mil em 01/01/26 e, se vendida, a venda em 01/07/26.
    private func obra(fase: String = "construcao", venda: Double? = nil, gasto: Double = 100_000) -> Obra {
        var campos: [String: ValorJSON] = [
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto(fase), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista([.objeto(["id": .texto("g1"), "valor": .numero(gasto), "topico": .texto("terreno"),
                                       "descricao": .texto("Terreno"), "data": .texto("2026-01-01"), "pagamento": .texto("pix")])]),
        ]
        if let venda { campos["venda"] = .objeto(["valor": .numero(venda), "data": .texto("2026-07-01")]) }
        return Estado.de(.objeto(["obras": .lista([.objeto(campos)])])).obras[0]
    }

    @Test func solidoDoTotalForaDaVendidaComLucro() {
        #expect(solidoDaObra(obra(), taxa: 1) == .total)
        #expect(solidoDaObra(obra(fase: "pronta"), taxa: 1) == .total)
        // Com prejuízo (B), o sólido volta a ser o Total gasto.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 80_000), taxa: 0) == .total)
    }

    @Test func solidoDoLucroNaVendida() {
        // Sem correção, o acima do banco é o próprio lucro.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 150_000), taxa: 0)
            == .lucro(valor: "+R$\u{a0}50.000,00", etiqueta: "Vendida em 01/07/26", nota: "+R$\u{a0}50.000,00 acima do banco"))
        // Lucro zero conta como lucro, como o `>= 0` do mockup.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 100_000), taxa: 0)
            == .lucro(valor: "+R$\u{a0}0,00", etiqueta: "Vendida em 01/07/26", nota: "+R$\u{a0}0,00 acima do banco"))
        // Com lucro e o acima do banco negativo (10% ao mês por 6 meses passa dos 50 mil), o sólido continua o lucro, e o
        // acima do banco vem com o menos.
        guard case let .lucro(valor, _, nota) = solidoDaObra(obra(fase: "vendida", venda: 150_000), taxa: 10) else {
            Issue.record("o sólido devia ser o lucro"); return
        }
        #expect(valor == "+R$\u{a0}50.000,00")
        #expect(nota.hasPrefix("\u{2212}R$\u{a0}") && nota.hasSuffix(" acima do banco"), "\(nota)")
    }

    /// Sem gastos, o Total gasto convida a lançar o primeiro pelo +, menos na vendida: o + de lá não lança nela (abre a folha
    /// com a linha "Obra", para escolher outra).
    @Test func notaDoTotalSemGastos() {
        var semGastos = obra()
        semGastos.gastos = []
        #expect(notaDoTotal(semGastos) == "Toque no + para lançar o primeiro gasto.")
        #expect(notaDoTotal(obra()) == "bruto, sem correção")
        var vendida = obra(fase: "vendida", venda: 150_000)
        vendida.gastos = []
        #expect(notaDoTotal(vendida) == "bruto, sem correção", "a vendida sem gastos não convida a lançar nela")
    }

    @Test func valorComSinal() {
        #expect(comSinal(1234.5) == "+R$\u{a0}1.234,50")
        #expect(comSinal(-1234.5) == "\u{2212}R$\u{a0}1.234,50")
        #expect(comSinal(0) == "+R$\u{a0}0,00")
    }

    /// Os blocos montados não passam da largura da coluna em nenhum tamanho de letra, com e sem o Negrito, nas larguras dos
    /// iPhones (375, 402 e 440 pt menos as bordas de 16), em escala 3: na obra da vitrine, na vendida com lucro, na vendida com
    /// prejuízo (a v3 da vitrine com prejuízo: o Total gasto no sólido e o lucro no âmbar) e com o maior valor no sólido. Com
    /// o Negrito, o rótulo do sólido ao lado da etiqueta passava 1/3 de pt nos 408 (o `CabecalhoDoBloco` do PR 1b).
    @Test func blocosNaoPassamDaLargura() {
        let vitrine = Estado.de(DadosDeExemplo.vitrine()).obras[0]
        var vendida = vitrine
        vendida.fase = .vendida
        vendida.venda = Venda(valor: 1_380_000, data: "2026-07-01")
        let prejuizo = Estado.de(DadosDeExemplo.vitrineComPrejuizo()).obras[2]
        let obras = [vitrine, vendida, prejuizo, obra(gasto: 1_000_000_000)]
        for negrito in [false, true] {
            for (i, obra) in obras.enumerated() {
                for letra in DynamicTypeSize.allCases {
                    for largura in [CGFloat(343), 370, 408] {
                        let blocos = BlocosDaObra(obra: obra, taxa: 1, hoje: "2026-10-12") {}.dynamicTypeSize(letra)
                            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3)
                        let medida = UIHostingController(rootView: blocos).sizeThatFits(in: CGSize(width: largura, height: 20_000)).width
                        #expect(medida == largura, "obra \(i), \(letra), negrito \(negrito), em \(largura): \(medida)")
                    }
                }
            }
        }
    }
}
