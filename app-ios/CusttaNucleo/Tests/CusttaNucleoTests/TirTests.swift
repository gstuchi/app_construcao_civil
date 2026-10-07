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
}
