import Testing
@testable import Custta

/* A costura das telas da análise (etapa 4, PR 1c): a abertura de Debug lê do gancho a tela e a obra, só dos Gráficos e do
   Relatório, e a rota no caminho de Obras leva a obra da tela ao + da cápsula. */
struct CosturaDaAnaliseTests {
    @Test func ganchoDeAberturaComATelaEAObra() {
        #expect(TelaDaAnalise(gancho: "graficos:v1") == .graficos("v1"))
        #expect(TelaDaAnalise(gancho: "relatorio:o2") == .relatorio("o2"))
        for outro in ["obra:v1", "orcamento:v1", "afazeres:v1", "valeAPena:v1", "graficos:", "graficos", ":v1", ""] {
            #expect(TelaDaAnalise(gancho: outro) == nil, "\(outro)")
        }
    }

    @Test func rotaComAObraEOTituloDaTela() {
        #expect(RotaDeObras.analise(.graficos("v1")).obraId == "v1")
        #expect(RotaDeObras.analise(.relatorio("v3")).obraId == "v3")
        #expect(TelaDaAnalise.graficos("v1").titulo == "Gráficos" && TelaDaAnalise.relatorio("v1").titulo == "Relatório")
    }
}
