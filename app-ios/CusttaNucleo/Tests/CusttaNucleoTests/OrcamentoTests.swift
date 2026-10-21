import Testing
@testable import CusttaNucleo

extension ItemOrcamento {
    var campos: [String: ValorJSON] {
        ["previsto": .numero(previsto), "gasto": .numero(gasto), "pct": .numero(pct), "sobra": .numero(sobra), "nivel": .texto(nivel.rawValue)]
    }
}
extension ResumoOrcamento {
    /// Mesma forma do retorno do orcamentoObra do site.
    var json: ValorJSON {
        var r = geral.campos
        r["modo"] = .texto(modo)
        r["topicos"] = .lista(topicos.map { t in var c = t.campos; c["id"] = .texto(t.id ?? ""); return .objeto(c) })
        r["fora"] = .lista(fora.map { .objeto(["id": .texto($0.id), "gasto": .numero($0.gasto)]) })
        r["foraTotal"] = .numero(foraTotal)
        return .objeto(r)
    }
}
extension ValorJSON {
    /// Um item do orcamentoObra do site ({previsto, gasto, pct, sobra, nivel}, com id no modo por tópico).
    var itemOrcamento: ItemOrcamento {
        let o = comoObjeto ?? [:]
        return ItemOrcamento(id: o["id"]?.comoTexto, previsto: o["previsto"]!.numero, gasto: o["gasto"]!.numero, pct: o["pct"]!.numero,
                             sobra: o["sobra"]!.numero, nivel: NivelOrcamento(rawValue: o["nivel"]!.comoTexto!)!)
    }
}

struct OrcamentoTests {
    @Test func previstoVersusReal() {
        for c in Vetores.casos("calc.orcamentoObra") {
            confere(orcamentoObra(c.args[0].obra)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }

    @Test func pilulaPorNivel() {
        let pilulas = [NivelOrcamento.ok, .perto, .passou].map { ($0.rawValue, ValorJSON.texto($0.pilula)) }
        confere(.objeto(Dictionary(uniqueKeysWithValues: pilulas)), Vetores.casos("calc.ORC_PILULA")[0].saida, .exata, "pílulas")
    }

    @Test func barraDe0a100() {
        for c in Vetores.casos("calc.larguraBarraOrc") {
            confere(.numero(larguraBarraOrc(c.args[0].numero)), c.saida, .exata, c.caso)
        }
    }

    @Test func fraseDoTopico() {
        for c in Vetores.casos("calc.fraseTopicoOrc") {
            let f = fraseTopicoOrc(c.args[0].itemOrcamento)
            confere(f.map { .objeto(["texto": .texto($0.texto), "alerta": .booleano($0.alerta)]) } ?? .nulo, c.saida, .exata, c.caso)
        }
    }

    @Test func rodapeDoCartao() {
        for c in Vetores.casos("calc.rodapeOrc") {
            let r = rodapeOrc(c.args[0].itemOrcamento)
            confere(.objeto(["usado": .texto(r.usado), "rotulo": .texto(r.rotulo), "valor": .texto(r.valor)]), c.saida, .exata, c.caso)
        }
    }

    @Test func linhaDoTopico() {
        for c in Vetores.casos("calc.linhaTopicoOrc") {
            let l = linhaTopicoOrc(c.args[0].itemOrcamento)
            confere(.objeto(["gasto": .texto(l.gasto), "previsto": .texto(l.previsto)]), c.saida, .exata, c.caso)
        }
    }

    @Test func totalAoVivoDaFolha() {
        for c in Vetores.casos("calc.somaTopicosOrc") {
            confere(.numero(somaTopicosOrc((c.args[0].comoLista ?? []).map(\.numero))), c.saida, .exata, c.caso)
        }
    }

    @Test func totalPreenchidoAoTrocarDeModo() {
        for c in Vetores.casos("calc.totalPreenchidoOrc") {
            confere(.texto(totalPreenchidoOrc(c.args[0].comoTexto!, (c.args[1].comoLista ?? []).map(\.numero))), c.saida, .exata, c.caso)
        }
    }

    @Test func pecasQueAObraMostra() {
        for c in Vetores.casos("calc.pecasOrcamento") {
            let p = pecasOrcamento(c.args[0].obra)
            confere(.objeto(["cartao": .booleano(p.cartao), "porTopico": .booleano(p.porTopico), "definir": .booleano(p.definir),
                             "tocaveis": .lista(p.tocaveis.map(ValorJSON.texto))]), c.saida, .exata, c.caso)
        }
    }
}
