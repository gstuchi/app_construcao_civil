import Testing
@testable import CusttaNucleo

extension RelatorioDaObra {
    var json: ValorJSON {
        .objeto(["fim": .texto(fim), "totalBruto": .numero(totalBruto), "totalCorrigido": .numero(totalCorrigido),
                 "grupos": .lista(grupos.map { g in
                     .objeto(["topico": .texto(g.topico), "bruto": .numero(g.bruto), "corrigido": .numero(g.corrigido),
                              "itens": .lista(g.itens.map { .objeto(["gasto": .objeto($0.gasto.campos), "corrigido": .numero($0.corrigido)]) })])
                 })])
    }
}

/* O relatório da obra (calc.js relatorioObra e companhia), conferido contra os vetores do site. */
struct RelatorioTests {
    @Test func gruposDoRelatorio() {
        for c in Vetores.casos("calc.relatorioObra") {
            let r = relatorioObra(c.args[0].obra, hoje: c.args[1].comoTexto!, taxa: c.args[2].numero)
            confere(r.json, c.saida, .dinheiro, c.caso)
            // O bruto de cada grupo e o total somam na ordem do documento, como o site: exato.
            let esperado = c.saida.comoObjeto ?? [:]
            confere(.lista(r.grupos.map { .numero($0.bruto) } + [.numero(r.totalBruto)]),
                    .lista((esperado["grupos"]?.comoLista ?? []).map { $0.comoObjeto?["bruto"] ?? .nulo } + [esperado["totalBruto"] ?? .nulo]),
                    .exata, c.caso + " (bruto exato)")
        }
    }
}
