import Testing
@testable import CusttaNucleo

extension LucroVenda { var json: ValorJSON { .objeto(["bruto": .numero(bruto), "vsBanco": .numero(vsBanco)]) } }

struct CorrecaoTests {
    @Test func diasPorMes() {
        #expect(diasMes == Vetores.casos("calc.DIAS_MES")[0].saida.comoNumero)
    }

    @Test func corrigidoPeloBanco() {
        for c in Vetores.casos("calc.corrigido") {
            let v = corrigido(c.args[0].numero, de: c.args[1].comoTexto!, ate: c.args[2].comoTexto!, taxa: c.args[3].numero)
            confere(.numero(v), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func totais() {
        for c in Vetores.casos("calc.totalBruto") { confere(.numero(totalBruto(c.args[0].obra)), c.saida, .dinheiro, c.caso) }
        for c in Vetores.casos("calc.totalCorrigido") {
            confere(.numero(totalCorrigido(c.args[0].obra, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func lucroNaVenda() {
        for c in Vetores.casos("calc.lucroVenda") {
            confere(lucroVenda(c.args[0].obra, taxa: c.args[1].numero)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }

    @Test func mesesDeObraAteHojeOuAVenda() {
        for c in Vetores.casos("calc.mesesDeObra") {
            confere(.numero(mesesDeObra(c.args[0].obra, hoje: c.args[1].comoTexto!)), c.saida, .continua, c.caso)
        }
    }

    @Test func precoPorMetroQuadrado() {
        for c in Vetores.casos("calc.precoPorM2") {
            confere(opcional(precoPorM2(c.args[0].numeroOuNil, c.args[1].numeroOuNil)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func vendaSemDataCorrigeAteHoje() {
        var obra = Obra(arvore: ["id": .texto("o"), "dataInicio": .texto("2026-01-01")])
        obra.venda = Venda(valor: 500, data: "")
        #expect(fimCorrecao(obra, hoje: "2026-10-06") == "2026-10-06")
        obra.venda = Venda(valor: 500, data: "2026-02-01")
        #expect(fimCorrecao(obra, hoje: "2026-10-06") == "2026-02-01")
    }

    @Test func precoPorM2ComAreaOuValorNegativosDaNil() {
        #expect(precoPorM2(100, -5) == nil)
        #expect(precoPorM2(-100, 5) == nil)
        #expect(precoPorM2(nil, 5) == nil)
    }
}
