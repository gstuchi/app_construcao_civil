import Testing
@testable import CusttaNucleo

extension APagar {
    var json: ValorJSON {
        .objeto(["total": .numero(total), "qtd": .numero(Double(qtd)),
                 "itens": .lista(itens.map { .objeto(["obraId": .texto($0.obraId), "gasto": .objeto($0.gasto.campos)]) })])
    }
}
extension GastoRecente {
    var json: ValorJSON { .objeto(["obraId": .texto(obraId), "obraNome": .texto(obraNome), "gasto": .objeto(gasto.campos)]) }
}

struct ListasTests {
    @Test func aPagarEmTrintaDias() {
        for c in Vetores.casos("calc.aPagar") {
            let r = c.args.count > 2
                ? aPagar(c.args[0].obras, hoje: c.args[1].comoTexto!, dias: Int(c.args[2].numero))
                : aPagar(c.args[0].obras, hoje: c.args[1].comoTexto!)
            confere(r.json, c.saida, .dinheiro, c.caso)
        }
    }

    @Test func recentes() {
        for c in Vetores.casos("calc.gastosRecentes") {
            let r = c.args.count > 1 ? gastosRecentes(c.args[0].obras, n: Int(c.args[1].numero)) : gastosRecentes(c.args[0].obras)
            confere(.lista(r.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func textoSemAcento() {
        for c in Vetores.casos("calc.semAcento") {
            #expect(semAcento(c.arg(0)?.textoOuNil) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func filtroDosLancamentos() {
        for c in Vetores.casos("calc.filtraGastos") {
            let topicos = (c.args[1].comoObjeto ?? [:]).mapValues { t in
                Topico(id: t.comoObjeto!["id"]!.comoTexto!, nome: t.comoObjeto!["nm"]!.comoTexto!, icone: t.comoObjeto!["ic"]!.comoTexto!)
            }
            let f = c.args[2].comoObjeto.map { FiltroGastos(texto: $0["texto"]?.comoTexto, mes: $0["mes"]?.comoTexto) }
            let r = filtraGastos(c.args[0].gastos, topicos: topicos, filtro: f)
            confere(.lista(r.map { .objeto($0.campos) }), c.saida, .exata, c.caso)
        }
    }
}
