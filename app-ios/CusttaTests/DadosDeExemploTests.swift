import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje), também com os orçamentos
   da etapa 3. */
struct DadosDeExemploTests {
    static let dias = ["2026-01-31", "2026-03-01", "2026-10-08", "2026-12-31", "2027-02-28", "2028-02-29"]

    @Test(arguments: dias)
    func vitrineComOsNumerosDoMockup(_ dia: String) throws {
        let fuso = TimeZone.current
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = fuso
        let partes = dia.split(separator: "-").map { Int($0)! }
        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
        let estado = Estado.de(DadosDeExemplo.vitrine(hoje: hoje))
        let iso = dataLocalISO(hoje, fuso: fuso)
        let obras = obrasOrdenadas(estado.obras)
        #expect(obras.map(\.nome) == ["Casa Alphaville", "Sobrado Granja Viana", "Casa Tamboré 4"])
        #expect(obras.map(\.fase.rotulo) == ["Em construção", "Pronta · à venda", "Vendida"])
        #expect(obras.map { fmtMeses(mesesDeObra($0, hoje: iso)) } == ["14 meses", "23 meses", "18 meses"])
        #expect(obras.map { moedaCurta(totalBruto($0)) } == ["R$ 842 mil", "R$ 1,38 mi", "R$ 976 mil"])
        #expect(obras.map { moedaCurta(totalCorrigido($0, taxa: 1, hoje: iso)) } == ["R$ 927 mil", "R$ 1,65 mi", "R$ 1,12 mi"])
        #expect(orcamentoObra(obras[0]).map(textoOrcamentoNaLista) == "70% do orçamento")
        // a tela da obra do mockup da etapa 2 (parte1.html)
        let casa = obras[0]
        let indicadores = indicadoresDaObra(casa, taxa: 1, hoje: iso)
        #expect(indicadores.totalGasto == "R$\u{a0}842.317,45" && indicadores.etiquetaDoTotal == "46 lançamentos")
        #expect(indicadores.corrigido == "R$\u{a0}926.847,69")
        #expect(indicadores.aPagar == "R$\u{a0}13.250,00" && indicadores.etiquetaDoAPagar == "3 vencimentos")
        #expect(indicadores.venda == .estimada(valor: "R$\u{a0}1.450.000,00", nota: "R$ 4,8 mil/m² · 300 m²"))
        let lista = listaDaObra(casa, hoje: iso)
        #expect(lista.aVencer?.quantidade == 13 && lista.aVencer?.total == 65_500)
        #expect(orcamentoObra(obras[1]) == nil && orcamentoObra(obras[2]) == nil)
    }

    /// Os orçamentos da etapa 3 sobre a vitrine mostram os números do mockup aprovado (parte1.html) em qualquer dia.
    @Test(arguments: dias)
    func orcamentosDoMockupDaEtapa3(_ dia: String) throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        let partes = dia.split(separator: "-").map { Int($0)! }
        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
        func casa(_ variante: String) -> Obra { Estado.de(DadosDeExemplo.vitrineDoOrcamento(variante, hoje: hoje)).obras[0] }
        let r = try #require(orcamentoObra(casa("porTopico")))
        #expect(moeda(r.geral.gasto) == "R$\u{a0}812.536,95" && moeda(r.geral.previsto) == "R$\u{a0}1.019.847,85" && r.geral.pct == 80)
        #expect(r.topicos.map { $0.id ?? "" } == ["estrutura", "fundacao", "terreno", "revest", "telhado", "ferragem", "eletrica",
                                                   "esquadrias", "matbasicos", "hidraulica", "alvenaria", "maoobra", "acabamento", "paisagismo"])
        #expect(avisoDosTopicos(r) == "2 tópicos passaram do previsto" && foraNaLinha(r) == "R$ 30 mil fora do orçamento")
        #expect(r.fora.map(\.id) == ["projeto", "pintura"] && moeda(r.foraTotal) == "R$\u{a0}29.780,50")
        let porTopico = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico", hoje: hoje))
        #expect(topicosDoFormulario(porTopico.config.topicosProprios).count == 22, "os 21 fixos e o Gesso e drywall")
        let vendida = try #require(orcamentoObra(porTopico.obras[2]), "a vendida com orçamento total")
        #expect(vendida.geral.pct == 98 && vendida.geral.nivel == .perto && moeda(vendida.geral.sobra) == "R$\u{a0}24.000,00")
        for (variante, pct, nivel) in [("perto", 92.0, NivelOrcamento.perto), ("passou", 105, .passou)] {
            let o = try #require(orcamentoObra(casa(variante)))
            #expect(o.geral.pct == pct && o.geral.nivel == nivel, "\(variante)")
        }
        #expect(orcamentoObra(casa("semOrcamento")) == nil && pecasOrcamento(casa("semOrcamento")).definir)
        let muitos = Estado.de(DadosDeExemplo.vitrineDoOrcamento("muitosTopicos", hoje: hoje))
        #expect(topicosDoFormulario(muitos.config.topicosProprios).count == 71, "os 21 fixos e os 50 próprios do limite das rules")
    }
}
