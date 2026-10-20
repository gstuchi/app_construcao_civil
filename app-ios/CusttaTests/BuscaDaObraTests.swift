import Testing
@testable import Custta
import CusttaNucleo

/* A busca da lista de lançamentos (etapa 3): a tela decide que está filtrando (o "A vencer" que abre sozinho, a soma, o
   vazio da busca) pela mesma conta do contador do site, e o × da busca e o botão do vazio limpam o que devem. */
@MainActor
struct BuscaDaObraTests {
    @Test func filtrandoPelaMesmaContaDoContadorDoSite() {
        let casos: [(texto: String, mes: String)] = [("", ""), ("   ", ""), ("cer", ""), (" cer ", ""), ("Á", ""), ("\u{301}", ""),
                                                     ("", "2026-03"), ("  ", "2026-03"), ("cer", "2026-03")]
        for c in casos {
            let busca = BuscaDaObra()
            busca.texto = c.texto
            busca.mes = c.mes
            let noSite = contadorLancamentos(total: 3, achados: 1, filtro: busca.filtro) == "1/3"
            #expect(busca.filtrando == noSite, "texto \(c.texto.debugDescription), mês \(c.mes.debugDescription)")
        }
    }

    @Test func fecharLimpaOTextoEFicaComOMes() {
        let busca = BuscaDaObra()
        busca.aberta = true
        busca.texto = "cimento"
        busca.mes = "2026-03"
        busca.fechar()
        #expect(!busca.aberta && busca.texto.isEmpty && busca.mes == "2026-03")
    }

    @Test func limparTiraABuscaEOMesEDeixaOCampoAberto() {
        let busca = BuscaDaObra()
        busca.aberta = true
        busca.texto = "sapatas"
        busca.mes = "2025-06"
        busca.limpar()
        #expect(busca.aberta && busca.texto.isEmpty && busca.mes.isEmpty && !busca.filtrando)
    }

    /// A lista filtrada agrupa só os achados: cada mês com a soma dos seus e o "A vencer" com os seus.
    @Test func obraComOsAchadosSomaSoOsAchados() {
        func gasto(_ id: String, _ data: String, _ valor: Double) -> ValorJSON {
            .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto("outros"), "descricao": .texto(id), "data": .texto(data),
                     "pagamento": .texto("pix")])
        }
        let obra = Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                                 "gastos": .lista([gasto("a", "2026-09-01", 1_000), gasto("b", "2026-09-02", 2_000), gasto("c", "2026-12-01", 3_000)])])
        let lista = listaDaObra(obra.comOsGastos([obra.gastos[1], obra.gastos[2]]), hoje: "2026-10-12")
        #expect(lista.meses.map(\.total) == [2_000])
        #expect(lista.aVencer?.total == 3_000)
        #expect(obra.gastos.count == 3, "a obra de verdade não muda")
    }
}
