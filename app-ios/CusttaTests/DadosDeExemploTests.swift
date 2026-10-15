import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje). */
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
}
