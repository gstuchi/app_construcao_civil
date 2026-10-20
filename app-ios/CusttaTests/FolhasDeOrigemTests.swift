import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A lógica das folhas de origem da etapa 3 (o A pagar): as peças da lista, filhas diretas da LazyVStack, com o lugar de
   cada uma no grupo do mês (o fundo do grupo é desenhado por peça). */
@MainActor
struct FolhasDeOrigemTests {
    func gasto(_ id: String, _ data: String, _ valor: Double = 100) -> ValorJSON {
        .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto("outros"), "descricao": .texto(""), "data": .texto(data),
                 "pagamento": .texto("pix")])
    }

    func obra(_ gastos: [ValorJSON]) -> Obra {
        Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "gastos": .lista(gastos)])
    }

    @Test func pecasDoAPagarPorMesComOLugarNoGrupo() {
        // Hoje 12/10/26: três vencimentos em outubro e novembro, um hoje (fica fora) e um depois dos 30 dias (fica fora).
        let o = obra([gasto("c", "2026-11-06"), gasto("hoje", "2026-10-12"), gasto("a", "2026-10-15"), gasto("b", "2026-11-05"),
                      gasto("depois", "2026-11-12")])
        let pecas = pecasDaOrigem(aPagarDaObra(o, hoje: "2026-10-12").meses)
        #expect(pecas.map(\.id) == ["mes-2026-10", "a", "mes-2026-11", "b", "c"])
        #expect(pecas.map(\.primeiro) == [false, true, false, true, false], "o primeiro gasto do grupo vem sem a linha fina em cima")
        #expect(pecas.map(\.ultimo) == [false, true, false, false, true], "o último gasto do grupo leva os cantos de baixo")
    }

    @Test func pecasSemVencimentoNenhuma() {
        #expect(pecasDaOrigem(aPagarDaObra(obra([gasto("p", "2026-10-01")]), hoje: "2026-10-12").meses).isEmpty)
    }
}
