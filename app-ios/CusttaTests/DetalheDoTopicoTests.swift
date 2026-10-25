import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* As peças do detalhe do tópico (etapa 3, PR 2), sobre a lista das folhas de origem: "A vencer · N" e "Pagos · N", cada
   seção só com gasto, com o cabeçalho fora do grupo; o primeiro gasto da seção leva os cantos de cima do grupo e o último,
   os de baixo (o fundo do grupo é desenhado por peça, as peças são filhas diretas da LazyVStack). E o corrigido do resumo,
   partido em duas partes para a letra grande. */
@MainActor
struct DetalheDoTopicoTests {
    func gasto(_ id: String, _ data: String, topico: String = "revest") -> ValorJSON {
        .objeto(["id": .texto(id), "valor": .numero(100), "topico": .texto(topico), "descricao": .texto(""), "data": .texto(data),
                 "pagamento": .texto("pix")])
    }

    func obra(_ gastos: [ValorJSON]) -> Obra {
        Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "gastos": .lista(gastos)])
    }

    func pecas(_ o: Obra) -> [PecaDaOrigem] {
        pecasDoDetalhe(detalheDoTopico(o, topico: "revest", hoje: "2026-10-12", taxaMensal: 1))
    }

    @Test func pecasDoDetalheComSecoesEOLugarNoGrupo() {
        // Hoje 12/10/26: dois a vencer, três pagos (um deles hoje) e um gasto de outro tópico, que fica fora.
        let p = pecas(obra([gasto("p1", "2026-09-01"), gasto("v2", "2026-11-20"), gasto("hoje", "2026-10-12"),
                            gasto("v1", "2026-10-20"), gasto("outro", "2026-10-01", topico: "pintura"), gasto("p2", "2026-10-05")]))
        #expect(p.map(\.id) == ["secao-A vencer", "v1", "v2", "secao-Pagos", "hoje", "p2", "p1"],
                "a vencer, o próximo primeiro; pagos, o mais novo primeiro")
        #expect(p[0].tipo == .secao(titulo: "A vencer", quantidade: 2))
        #expect(p[3].tipo == .secao(titulo: "Pagos", quantidade: 3))
        #expect(p.map(\.cima) == [false, true, false, false, true, false, false],
                "o cabeçalho fica fora do grupo: os cantos de cima vão no primeiro gasto da seção")
        #expect(p.map(\.primeiro) == [false, true, false, false, true, false, false], "o primeiro gasto vem sem a linha fina em cima")
        #expect(p.map(\.ultimo) == [false, false, true, false, false, false, true], "o último gasto leva os cantos de baixo")
    }

    @Test func semAVencerSoPagos() {
        let p = pecas(obra([gasto("p1", "2026-09-01"), gasto("p2", "2026-10-05")]))
        #expect(p.map(\.id) == ["secao-Pagos", "p2", "p1"], "a seção sem gasto não aparece")
        #expect(p.first?.tipo == .secao(titulo: "Pagos", quantidade: 2))
        #expect(p.map(\.cima) == [false, true, false])
        #expect(p.map(\.ultimo) == [false, false, true])
        // Um gasto só, a vencer: o primeiro e o último da seção, com os quatro cantos; sem "Pagos".
        let um = pecas(obra([gasto("v", "2026-12-01")]))
        #expect(um.map(\.id) == ["secao-A vencer", "v"])
        #expect(um.last.map { $0.cima && $0.primeiro && $0.ultimo } == true)
        #expect(pecas(obra([gasto("outro", "2026-10-01", topico: "pintura")])).isEmpty, "sem gasto do tópico, nenhuma peça")
    }

    @Test func oCorrigidoDoResumoEODoNucleo() {
        // Partido para o dinheiro ir para a própria linha na letra grande; junto, o texto do núcleo (o do site).
        let d = detalheDoTopico(obra([gasto("p1", "2026-09-01"), gasto("v1", "2026-10-20")]), topico: "revest", hoje: "2026-10-12",
                                taxaMensal: 1)
        let partes = partesDoCorrigido(d)
        #expect(partes.antes + " " + partes.valor == d.corrigido)
        #expect(partes.valor == moeda(d.resumo.corrigido))
    }
}
