import Testing
@testable import CusttaNucleo

/* A faixa "Onde a sua venda cai" do "Vale a pena?" é regra só do app (o site não tem a faixa): os números vêm da conta do
   mockup aprovado da etapa 4 (parte2.js, `telaSimula`) e das bordas dela. O empate ilustrativo é 901.820,11. */
struct FaixaDoSimuladorTests {
    private func conta(venda: Double, bruto: Double = 842_317.45, corrigido: Double = 901_820.11) -> ContaDoSimulador {
        ContaDoSimulador(venda: venda, meses: 6, alvo: "2027-04-12", bruto: bruto, corrigido: corrigido, novaDemais: false,
                         tir: 3.52, acima: 2.5, vale: venda > corrigido, multiplicador: 3.5)
    }

    private func perto(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

    @Test func vendaAcimaDoBancoCaiNaZonaDepoisDoEmpate() {
        let f = faixaSimulador(conta(venda: 1_450_000))
        #expect(f.linhas.map(\.marca) == [.custo, .empate, .venda])
        #expect(f.linhas.map(\.rotulo) == ["custo (bruto)", "empata com o banco", "sua venda"])
        #expect(f.linhas.map(\.valor) == ["R$\u{00A0}842.317,45", "R$\u{00A0}901.820,11", "R$\u{00A0}1.450.000,00"])
        // A escala vai de 3% abaixo do custo a 3% acima da venda: nenhuma marca encosta na borda.
        #expect(perto(f.linhas[0].fracao, 0.037355970201))
        #expect(perto(f.linhas[1].fracao, 0.125318831623))
        #expect(perto(f.linhas[2].fracao, 0.935693892141))
        #expect(f.acima)
        #expect(f.pilula == "acima do banco")
        #expect(f.falado == "Custo R$\u{00A0}842.317,45, empata com o banco em R$\u{00A0}901.820,11, sua venda R$\u{00A0}1.450.000,00")
    }

    @Test func vendaAbaixoDoBancoFicaAntesDoEmpate() {
        // Acima do custo e abaixo do empate: dá lucro e rende menos que o banco. A escala termina no empate.
        let f = faixaSimulador(conta(venda: 880_000))
        #expect(perto(f.linhas[0].fracao, 0.225970218971))
        #expect(perto(f.linhas[1].fracao, 0.758066881163))
        #expect(perto(f.linhas[2].fracao, 0.562942701846))
        #expect(!f.acima)
        #expect(f.pilula == "abaixo do banco")
    }

    @Test func vendaAbaixoDoCustoPuxaOComecoDaEscala() {
        // Prejuízo: a escala começa 3% abaixo da venda, e a venda fica à esquerda do custo.
        let f = faixaSimulador(conta(venda: 700_000))
        #expect(perto(f.linhas[2].fracao, 0.084042117438))
        #expect(perto(f.linhas[0].fracao, 0.653597348220))
        #expect(perto(f.linhas[1].fracao, 0.891727326296))
        #expect(!f.acima)
    }

    @Test func vendaIgualAoEmpateNaoEstaAcima() {
        // O veredito do site é venda > corrigido: no empate exato, "abaixo do banco", com as duas marcas no mesmo ponto.
        let f = faixaSimulador(conta(venda: 901_820.11))
        #expect(!f.acima)
        #expect(f.pilula == "abaixo do banco")
        #expect(f.linhas[1].fracao == f.linhas[2].fracao)
    }

    @Test func asMarcasFicamDentroDaFaixaENaOrdemDoCusto() {
        for venda in [1.0, 500.0, 842_317.45, 901_820.11, 2_000_000, 99_999_999.99] {
            for (bruto, corrigido) in [(0.01, 0.01), (842_317.45, 901_820.11), (99_999_999.99, 150_000_000.0)] {
                let f = faixaSimulador(conta(venda: venda, bruto: bruto, corrigido: corrigido))
                for l in f.linhas { #expect(l.fracao > 0 && l.fracao < 1, "\(l.marca) em \(l.fracao), venda \(venda), custo \(bruto)") }
                #expect(f.linhas[0].fracao <= f.linhas[1].fracao, "o custo nunca passa do empate")
                #expect(f.acima == (f.linhas[2].fracao > f.linhas[1].fracao))
            }
        }
    }
}
