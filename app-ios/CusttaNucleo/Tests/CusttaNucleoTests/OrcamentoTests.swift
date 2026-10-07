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

struct OrcamentoTests {
    @Test func previstoVersusReal() {
        for c in Vetores.casos("calc.orcamentoObra") {
            confere(orcamentoObra(c.args[0].obra)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }
}
