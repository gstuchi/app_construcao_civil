import Testing
@testable import CusttaNucleo

struct NormalizacaoTests {
    @Test func normalizaComoODadosJs() {
        for c in Vetores.casos("dados.normaliza") {
            #expect(mesmoConteudo(normaliza(c.args[0]), c.saida), "\(c.caso): \(canonico(normaliza(c.args[0]))) ≠ \(canonico(c.saida))")
        }
    }

    @Test func limitesDeTexto() {
        let l = Vetores.casos("dados.LIMITES")[0].saida.comoObjeto!
        #expect(Double(Limites.nome) == l["nome"]?.comoNumero)
        #expect(Double(Limites.descricao) == l["descricao"]?.comoNumero)
        #expect(Double(Limites.topico) == l["topico"]?.comoNumero)
        #expect(Double(Limites.afazer) == l["afazer"]?.comoNumero)
    }
}
