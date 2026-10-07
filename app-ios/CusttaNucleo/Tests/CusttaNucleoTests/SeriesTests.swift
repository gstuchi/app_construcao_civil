import Testing
@testable import CusttaNucleo

extension PontoEvolucao { var json: ValorJSON { .objeto(["mes": .texto(mes), "bruto": .numero(bruto), "corrigido": .numero(corrigido)]) } }
extension PontoMensal { var json: ValorJSON { .objeto(["mes": .texto(mes), "total": .numero(total)]) } }

private func obraComGastos(_ gastos: [(String, Double)], venda: (valor: Double, data: String)? = nil) -> Obra {
    var arvore: [String: ValorJSON] = [
        "id": .texto("o"),
        "gastos": .lista(gastos.enumerated().map { i, g in
            .objeto(["id": .texto("g\(i)"), "valor": .numero(g.1), "data": .texto(g.0)])
        }),
    ]
    if let venda { arvore["venda"] = .objeto(["valor": .numero(venda.valor), "data": .texto(venda.data)]) }
    return Obra(arvore: arvore)
}

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

    @Test func evolucaoNaoDependeDaOrdemEmQueOsGastosForamLancados() {
        let foraDeOrdem = serieEvolucao(obraComGastos([("2026-08-15", 100), ("2026-06-10", 50), ("2026-07-01", 30)]), taxa: 1, hoje: "2026-10-06")
        #expect(foraDeOrdem.map(\.mes) == ["2026-06", "2026-07", "2026-08", "2026-09", "2026-10"])
        #expect(foraDeOrdem.map(\.bruto) == [50, 80, 180, 180, 180])
        let emOrdem = serieEvolucao(obraComGastos([("2026-06-10", 50), ("2026-07-01", 30), ("2026-08-15", 100)]), taxa: 1, hoje: "2026-10-06")
        #expect(foraDeOrdem == emOrdem)
    }

    @Test func vendaAntesDoMesDoPrimeiroGastoDaUmPontoSo() {
        let obra = obraComGastos([("2026-06-15", 100), ("2026-07-01", 30)], venda: (500, "2026-03-10"))
        #expect(serieEvolucao(obra, taxa: 1, hoje: "2026-10-06") == [PontoEvolucao(mes: "2026-06", bruto: 0, corrigido: 0)])
    }

    @Test func evolucaoParaNaGuardaDe600Meses() {
        let s = serieEvolucao(obraComGastos([("1950-01-15", 100)]), taxa: 1, hoje: "2026-10-06")
        #expect(s.count == 24 && s.first?.mes == "1998-01" && s.last?.mes == "1999-12")
    }
}
