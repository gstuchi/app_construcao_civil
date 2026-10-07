import Testing
@testable import CusttaNucleo

extension ResumoVenda {
    var json: ValorJSON { .objeto(["lucro": opcional(lucro), "pctCusto": opcional(pctCusto), "pctVenda": opcional(pctVenda)]) }
}

struct TirTests {
    @Test func tirMensalPorBissecao() {
        for c in Vetores.casos("calc.tirMensal") {
            confere(opcional(tirMensal(c.args[0].gastos, venda: c.args[1].numero, alvo: c.args[2].comoTexto!)), c.saida, .continua, c.caso)
        }
    }

    @Test func rendimentoAcimaDoBanco() {
        for c in Vetores.casos("calc.rendimentoAcima") {
            confere(opcional(rendimentoAcima(c.args[0].numeroOuNil, taxa: c.args[1].numero)), c.saida, .continua, c.caso)
        }
    }

    @Test func resumoDaVenda() {
        for c in Vetores.casos("calc.resumoVenda") {
            confere(resumoVenda(c.args[0].numero, custo: c.args[1].numero).json, c.saida, .continua, c.caso)
        }
    }

    @Test func semMesPassadoNaoTemTirMesmoComVendaIgualAoCusto() {
        let alvo = "2026-10-06"
        let doDia = Gasto(campos: ["id": .texto("a"), "valor": .numero(1000), "data": .texto(alvo)])
        #expect(tirMensal([doDia], venda: 1000, alvo: alvo) == nil)
        let depois = Gasto(campos: ["id": .texto("b"), "valor": .numero(1000), "data": .texto("2026-10-20")])
        #expect(tirMensal([depois], venda: 1000, alvo: alvo) == nil)
    }

    @Test func resumoDaVendaNegativaOuSemCustoDaNil() {
        for (venda, custo) in [(-1.0, 1000.0), (1000.0, -1.0), (-5.0, -5.0), (0.0, 0.0)] {
            #expect(resumoVenda(venda, custo: custo) == ResumoVenda(lucro: nil, pctCusto: nil, pctVenda: nil))
        }
    }
}
