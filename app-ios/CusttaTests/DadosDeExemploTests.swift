import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje), também com os orçamentos
   da etapa 3 e as obras dos estados da análise da etapa 4. */
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

    /// A obra pesada (`CUSTTA_DADOS=pesada`, a da medida da obra em List no iPhone) carrega em qualquer dia: a Casa
    /// Alphaville com 520 gastos a mais, 566 no total, um mês passado com 30 ou mais, e as outras obras como na vitrine.
    @Test(arguments: dias)
    func obraPesadaComUmGastoPorDia(_ dia: String) throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        let partes = dia.split(separator: "-").map { Int($0)! }
        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
        let pesada = Estado.de(DadosDeExemplo.vitrinePesada(hoje: hoje)), vitrine = Estado.de(DadosDeExemplo.vitrine(hoje: hoje))
        let casa = try #require(pesada.obras.first { $0.id == "v1" })
        #expect(casa.gastos.count == 566)
        let maior = listaDaObra(casa, hoje: dataLocalISO(hoje, fuso: .current)).meses.map(\.gastos.count).max() ?? 0
        #expect(maior >= 30, "um mês cheio: a célula gigante da List na maior letra")
        #expect(pesada.obras.filter { $0.id != "v1" } == vitrine.obras.filter { $0.id != "v1" })
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
        // O topicoLongo, da lista longa do detalhe do tópico: 120 diárias da equipe na Mão de obra (100 pagas, de ontem para trás,
        // e 20 a vencer, de amanhã em diante), de R$ 350,00 no Pix; o resto da obra é o do porTopico.
        func iso(_ dias: Int) -> String {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = .current
            return dataLocalISO(c.date(byAdding: .day, value: dias, to: hoje)!, fuso: .current)
        }
        let sem = Set(casa("porTopico").gastos.map(\.id))
        let longa = casa("topicoLongo")
        let diarias = longa.gastos.filter { !sem.contains($0.id) }
        #expect(longa.gastos.count == sem.count + 120 && diarias.count == 120, "as 120 diárias, e mais nada")
        #expect(diarias.allSatisfy { $0.topico == "maoobra" && $0.valor == 350 && $0.pagamento == "pix" })
        #expect(diarias.filter { $0.data < iso(0) }.count == 100 && diarias.filter { $0.data > iso(0) }.count == 20, "100 pagas e 20 a vencer, nenhuma hoje")
        let data = Dictionary(uniqueKeysWithValues: diarias.map { ($0.id, $0.data) })
        #expect(data["d001"] == iso(-1) && data["d100"] == iso(-100) && data["d101"] == iso(1) && data["d120"] == iso(20), "de ontem para trás e de amanhã em diante")
    }

    /// As obras dos estados da análise (etapa 4, `CUSTTA_DADOS=analise`) sobre a vitrine, em qualquer dia: o que cada uma
    /// promete às telas dos marcos 2 e 3. No dia 1º, os gastos deste mês caem todos nele, e a obra de 1 mês continua com 1 mês.
    @Test(arguments: dias)
    func obrasDosEstadosDaAnalise(_ dia: String) throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        let partes = dia.split(separator: "-").map { Int($0)! }
        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
        let iso = dataLocalISO(hoje, fuso: .current)
        func dias(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .day, value: n, to: hoje)!, fuso: .current) }
        // O mês pelo dia 1º (que todo mês tem) e o dia preso ao fim dele: a conta de mês do Calendar a partir do dia 29 a 31
        // erra o bissexto no iOS 26 quando o mês fica negativo (swift-foundation #1708).
        func meses(_ n: Int) -> String {
            let c = calendario.dateComponents([.year, .month, .day], from: hoje)
            let primeiro = calendario.date(from: DateComponents(year: c.year, month: c.month, day: 1, hour: 12))!
            let alvo = calendario.date(byAdding: .month, value: n, to: primeiro)!
            let dia = min(c.day!, calendario.range(of: .day, in: .month, for: alvo)!.count)
            return dataLocalISO(calendario.date(byAdding: .day, value: dia - 1, to: alvo)!, fuso: .current)
        }
        let estado = Estado.de(DadosDeExemplo.vitrineDaAnalise(hoje: hoje))
        #expect(estado.obras.map(\.id) == ["v1", "v2", "v3", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"])
        #expect(Array(estado.obras.prefix(3)) == Estado.de(DadosDeExemplo.vitrine(hoje: hoje)).obras, "a vitrine de sempre na frente")
        let obra = Dictionary(uniqueKeysWithValues: estado.obras.map { ($0.id, $0) })
        let ids = estado.obras.flatMap { $0.gastos.map(\.id) }
        #expect(Set(ids).count == ids.count, "cada gasto com id próprio")
        // A Casa Alphaville (v1): 14 tópicos (o anel junta 8 no "Outros") e 13 parcelas a vencer.
        let casa = try #require(obra["v1"])
        #expect(gastoPorTopico(casa).count == 14 && pedacosDoAnel(gastoPorTopico(casa)).last?.topicos.count == 8)
        #expect(listaDaObra(casa, hoje: iso).aVencer?.quantidade == 13)
        // a1: a Casa Alphaville vendida há 114 dias por R$ 1.380.000,00, com os gastos dela; os depois da venda ficam fora da
        // evolução.
        let vendida = try #require(obra["a1"])
        #expect(vendida.nome == "Casa Alphaville" && vendida.fase == .vendida && vendida.venda == Venda(valor: 1_380_000, data: dias(-114)))
        #expect(vendida.gastos.map(\.valor) == casa.gastos.map(\.valor) && vendida.gastos.map(\.data) == casa.gastos.map(\.data))
        #expect(fraseForaDaEvolucao(vendida, hoje: iso)?.hasSuffix("com data depois da venda.") == true)
        // a2: sem gastos.
        let cotia = try #require(obra["a2"])
        #expect(cotia.nome == "Casa Cotia" && cotia.gastos.isEmpty && cotia.fase == .construcao)
        // a3: 1 gasto, neste mês.
        let terreno = try #require(obra["a3"])
        #expect(terreno.nome == "Terreno Granja" && terreno.gastos.map(\.valor) == [120_000])
        #expect(serieMensal(terreno.gastos).count == 1 && serieEvolucao(terreno, taxa: 1, hoje: iso).count == 1)
        #expect(terreno.gastos.allSatisfy { $0.data.prefix(7) == iso.prefix(7) && $0.data <= iso }, "neste mês, até hoje")
        // a4: 5 gastos neste mês, até hoje: 1 mês nos gráficos e menos de 1 mês de obra no "Vale a pena?".
        let vilaNova = try #require(obra["a4"])
        #expect(vilaNova.nome == "Sobrado Vila Nova" && vilaNova.gastos.count == 5 && gastoPorTopico(vilaNova).count == 4)
        #expect(vilaNova.gastos.allSatisfy { $0.data.prefix(7) == iso.prefix(7) && $0.data <= iso }, "neste mês, até hoje")
        #expect(serieMensal(vilaNova.gastos).count == 1 && serieEvolucao(vilaNova, taxa: 1, hoje: iso).count == 1)
        #expect(mesesDeObra(vilaNova, hoje: iso) < 1 && vilaNova.valorEstimadoVenda == 1_100_000 && vilaNova.areaM2 == 220)
        #expect([cotia, terreno, vilaNova].allSatisfy { $0.dataInicio == String(iso.prefix(8)) + "01" }, "no dia 1º deste mês")
        // a5: 7 gastos, todos em Estrutura.
        let galpao = try #require(obra["a5"])
        #expect(galpao.nome == "Galpão Jundiaí" && galpao.gastos.count == 7 && gastoPorTopico(galpao).map(\.id) == ["estrutura"])
        // a6: Outros e Extras abaixo de 1%.
        let granja = try #require(obra["a6"])
        let topicos = gastoPorTopico(granja)
        #expect(granja.nome == "Casa Granja Viana" && topicos.map(\.id) == ["terreno", "fundacao", "projeto", "outros", "extras"])
        #expect(topicos.map { porcentoDoTopico($0.bruto, total: totalBruto(granja)) } == ["78%", "17%", "5%", "<1%", "<1%"])
        // a7: 30 meses de gastos (do 30º mês atrás ao mês passado), com 3 parados: os dois gráficos de mês passam de 24 e
        // mostram os últimos 24, com os 3 parados entre eles.
        let morumbi = try #require(obra["a7"])
        #expect(morumbi.nome == "Casa Morumbi" && morumbi.dataInicio == meses(-30) && morumbi.gastos.count == 27)
        #expect(morumbi.gastos.first?.data == meses(-30) && morumbi.gastos.last?.data == meses(-1))
        #expect(gastoPorMesFoiCortado(morumbi.gastos) && evolucaoFoiCortada(morumbi, hoje: iso))
        let porMes = serieMensal(morumbi.gastos)
        #expect(porMes.count == 24 && porMes.first?.mes == String(meses(-24).prefix(7)))
        #expect(porMes.filter { $0.total == 0 }.map(\.mes) == [-20, -19, -18].map { String(meses($0).prefix(7)) }, "3 meses parados, seguidos")
        #expect(!gastoPorMesFoiCortado(casa.gastos) && !evolucaoFoiCortada(casa, hoje: iso), "a Casa Alphaville cabe em 24")
        // a8: a Casa Alphaville sem a venda estimada, com os mesmos gastos.
        let semVenda = try #require(obra["a8"])
        #expect(semVenda.nome == "Casa Alphaville" && semVenda.fase == .construcao && semVenda.venda == nil)
        #expect(semVenda.valorEstimadoVenda == nil && casa.valorEstimadoVenda == 1_450_000)
        #expect(semVenda.gastos.map(\.valor) == casa.gastos.map(\.valor) && semVenda.gastos.map(\.data) == casa.gastos.map(\.data))
    }

    /// A conta de mês para trás dos falsos no fim do mês: o dia que o mês não tem fica no último dele, sem transbordar para 1º de
    /// março. No iOS 26, a do Calendar levava 29/02/2028 − 24 meses a 01/03/2026 (swift-foundation #1708): dois gastos da Casa
    /// Morumbi da análise em março e fevereiro de 2026 parado (job app da CI do #99). As datas aqui são escritas, não contadas.
    @Test func mesesParaTrasNoFimDoMes() throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        func dia(_ a: Int, _ m: Int, _ d: Int) throws -> Date {
            try #require(calendario.date(from: DateComponents(year: a, month: m, day: d, hour: 12)))
        }
        let bissexto = try dia(2028, 2, 29), fimDeJaneiro = try dia(2028, 1, 31)
        let analise = Estado.de(DadosDeExemplo.vitrineDaAnalise(hoje: bissexto))
        let morumbi = try #require(analise.obras.first { $0.id == "a7" })
        let datas = Set(morumbi.gastos.map(\.data))
        #expect(morumbi.dataInicio == "2025-08-29")
        #expect(datas.isSuperset(of: ["2025-08-29", "2026-01-29", "2026-02-28", "2027-01-29", "2027-02-28", "2028-01-29"]))
        #expect(!datas.contains("2026-03-01") && !datas.contains("2027-03-01"), "nada em 1º de março")
        // A vitrine pelo mesmo caminho: no 31/01/2028, a 1ª etapa do Sobrado Granja Viana, de 23 meses atrás, fica em 28/02/2026.
        let vitrine = Estado.de(DadosDeExemplo.vitrine(hoje: fimDeJaneiro))
        let sobrado = try #require(vitrine.obras.first { $0.id == "v2" })
        #expect(sobrado.dataInicio == "2026-02-28" && sobrado.gastos.contains { $0.data == "2026-02-28" })
    }
}
