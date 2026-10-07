import Testing
@testable import CusttaNucleo

extension PontoEvolucao { var json: ValorJSON { .objeto(["mes": .texto(mes), "bruto": .numero(bruto), "corrigido": .numero(corrigido)]) } }
extension PontoMensal { var json: ValorJSON { .objeto(["mes": .texto(mes), "total": .numero(total)]) } }

struct SeriesTests {
    @Test func evolucao() {
        for c in Vetores.casos("calc.serieEvolucao") {
            let s = serieEvolucao(c.args[0].obra, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)
            confere(.lista(s.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func mensal() {
        for c in Vetores.casos("calc.serieMensal") {
            confere(.lista(serieMensal(c.args[0].gastos).map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func agregada() {
        for c in Vetores.casos("calc.serieEvolucaoAgregada") {
            let s = serieEvolucaoAgregada(c.args[0].obras, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)
            confere(.lista(s.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func ordemEstavelNoEmpate() {
        let pares = [(1, "a"), (0, "b"), (1, "c"), (0, "d")]
        #expect(ordenadoEstavel(pares) { $0.0 < $1.0 }.map(\.1) == ["b", "d", "a", "c"])
    }
}
