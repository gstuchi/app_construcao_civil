#if DEBUG
import Foundation
import CusttaNucleo

/* As obras dos estados do mockup aprovado da etapa 4 (gera-dados-p1.cjs e gera-dados-p2.cjs, de 28 e 29/10/2026) sobre a
   vitrine, para as telas da análise dos marcos 2 e 3 (Gráficos, Relatório, "Vale a pena?" e PDF), com as datas contadas de
   hoje, como na vitrine. CUSTTA_DADOS=analise (MontarFalso): a vitrine de sempre (a Casa Alphaville, v1, com 14 tópicos, 13
   parcelas a vencer e a venda estimada; o Sobrado Granja Viana, v2, pronto e sem venda estimada; a Casa Tamboré 4, v3,
   vendida, com 1 tópico) e mais:
   a1  a Casa Alphaville vendida por R$ 1.380.000,00 há 114 dias, com os 46 gastos dela (os depois da venda ficam fora da
       evolução)
   a2  Casa Cotia, sem gastos
   a3  Terreno Granja, 1 gasto de R$ 120.000,00
   a4  Sobrado Vila Nova, 5 gastos neste mês, até hoje (1 mês; no "Vale a pena?", menos de 1 mês de obra)
   a5  Galpão Jundiaí, 7 gastos, todos em Estrutura (1 tópico)
   a6  Casa Granja Viana, com Outros (0,25%) e Extras (0,05%) abaixo de 1% (o piso e o "<1%")
   a7  Casa Morumbi, 30 meses de gastos, com 3 meses parados no meio (os últimos 24 meses)
   a8  a Casa Alphaville sem a venda estimada (o Relatório e o PDF sem venda)
   A Cotia, o Terreno Granja e o Sobrado Vila Nova começam no dia 1º deste mês, e os gastos deles caem neste mês: o dia do
   mockup, sem passar de hoje (no dia 1º, todos caem nele). */
extension DadosDeExemplo {
    static func vitrineDaAnalise(hoje: Date = .now) -> ValorJSON {
        let base = vitrine(hoje: hoje)
        guard case .objeto(var raiz) = base, case .lista(let obras) = raiz["obras"], let primeira = obras.first,
              case .objeto(let casa) = primeira, case .lista(let gastosDaCasa) = casa["gastos"] else { return base }
        let calendario = Calendar(identifier: .gregorian)
        func dias(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .day, value: n, to: hoje) ?? hoje, fuso: .current) }
        func meses(_ n: Int) -> String { DadosDeExemplo.meses(n, de: hoje) }
        let hojeISO = dataLocalISO(hoje, fuso: .current)
        /// O dia `n` deste mês, sem passar de hoje.
        func desteMes(_ n: Int) -> String { String(hojeISO.prefix(8)) + String(format: "%02d", min(n, Int(hojeISO.suffix(2)) ?? 1)) }
        func gasto(_ id: String, _ valor: Double, _ topico: String, _ descricao: String, _ data: String) -> ValorJSON {
            .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(descricao),
                     "data": .texto(data), "pagamento": .texto("pix")])
        }
        func obra(_ id: String, _ nome: String, inicio: String, gastos: [ValorJSON], extra: [String: ValorJSON] = [:]) -> ValorJSON {
            var campos: [String: ValorJSON] = ["id": .texto(id), "nome": .texto(nome), "fase": .texto("construcao"),
                                               "dataInicio": .texto(inicio), "gastos": .lista(gastos)]
            campos.merge(extra) { _, novo in novo }
            return .objeto(campos)
        }
        /// A Casa Alphaville da vitrine com outro id, e os gastos com ids próprios.
        func copiaDaCasa(_ id: String, _ mudar: [String: ValorJSON]) -> ValorJSON {
            var campos = casa
            campos["id"] = .texto(id)
            campos["gastos"] = .lista(gastosDaCasa.map { g in
                guard case .objeto(var copia) = g, let deles = copia["id"]?.comoTexto else { return g }
                copia["id"] = .texto(id + deles)
                return .objeto(copia)
            })
            campos.merge(mudar) { _, novo in novo }
            return .objeto(campos)
        }
        let morumbi: [(Int, Double, String, String)] = [
            (30, 250_000, "terreno", "Compra do terreno"), (29, 18_500, "projeto", "Projeto e aprovação"),
            (28, 42_000, "fundacao", "Estacas e blocos"), (27, 38_600, "fundacao", "Vigas baldrame"),
            (26, 51_200, "estrutura", "Pilares do térreo"), (25, 47_800, "estrutura", "Laje do térreo"),
            (24, 29_300, "alvenaria", "Blocos de concreto"), (23, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (22, 52_300, "estrutura", "Laje do pavimento superior"), (21, 21_100, "alvenaria", "Alvenaria do pavimento superior"),
            (17, 16_400, "maoobra", "Pedreiro e ajudantes"), (16, 33_900, "telhado", "Madeiramento do telhado"),
            (15, 18_200, "telhado", "Telhas de cerâmica"), (14, 12_800, "eletrica", "Eletrodutos e caixas"),
            (13, 10_900, "hidraulica", "Tubulação de água e esgoto"), (12, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (11, 24_600, "revest", "Reboco interno"), (10, 19_800, "revest", "Contrapiso"),
            (9, 27_400, "esquadrias", "Janelas de alumínio"), (8, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (7, 31_200, "revest", "Porcelanato"), (6, 14_900, "eletrica", "Fios e quadro de luz"),
            (5, 12_300, "hidraulica", "Louças e metais"), (4, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (3, 22_800, "pintura", "Pintura interna"), (2, 9_800, "pintura", "Pintura externa"),
            (1, 16_400, "maoobra", "Pedreiro e ajudantes"),
        ]
        raiz["obras"] = .lista(obras + [
            copiaDaCasa("a1", ["fase": .texto("vendida"), "venda": .objeto(["valor": .numero(1_380_000), "data": .texto(dias(-114))])]),
            obra("a2", "Casa Cotia", inicio: desteMes(1), gastos: []),
            obra("a3", "Terreno Granja", inicio: desteMes(1), gastos: [gasto("u1", 120_000, "terreno", "Entrada do terreno", desteMes(5))]),
            obra("a4", "Sobrado Vila Nova", inicio: desteMes(1), gastos: [
                gasto("m1", 180_000, "terreno", "Entrada do terreno", desteMes(2)),
                gasto("m2", 18_500, "projeto", "Projeto arquitetônico", desteMes(3)),
                gasto("m3", 9_800, "maoobra", "Limpeza do terreno", desteMes(6)),
                gasto("m4", 14_320, "matbasicos", "Cimento, areia e brita", desteMes(8)),
                gasto("m5", 4_380.5, "projeto", "Taxas e alvará da prefeitura", desteMes(9)),
            ], extra: ["valorEstimadoVenda": .numero(1_100_000), "areaM2": .numero(220)]),
            obra("a5", "Galpão Jundiaí", inicio: dias(-224), gastos: [
                gasto("t1", 52_300, "estrutura", "Pilares e vigas", dias(-210)),
                gasto("t2", 38_900, "estrutura", "Concreto da laje", dias(-186)),
                gasto("t3", 12_400.9, "estrutura", "Ferragem da laje", dias(-153)),
                gasto("t4", 26_900, "estrutura", "Formas e escoramento", dias(-116)),
                gasto("t5", 31_700.5, "estrutura", "Estrutura metálica da cobertura", dias(-83)),
                gasto("t6", 24_300, "estrutura", "Vigas de borda", dias(-48)),
                gasto("t7", 19_600, "estrutura", "Concreto do piso", dias(-6)),
            ]),
            obra("a6", "Casa Granja Viana", inicio: dias(-194), gastos: [
                gasto("p1", 300_000, "terreno", "Terreno", dias(-185)),
                gasto("p2", 64_200, "fundacao", "Sapatas e baldrames", dias(-126)),
                gasto("p3", 18_500, "projeto", "Projeto arquitetônico", dias(-160)),
                gasto("p4", 950, "outros", "Caçamba de entulho", dias(-28)),
                gasto("p5", 180, "extras", "Cópia de chaves", dias(-9)),
            ], extra: ["valorEstimadoVenda": .numero(900_000), "areaM2": .numero(180)]),
            obra("a7", "Casa Morumbi", inicio: meses(-30), gastos: morumbi.enumerated().map { i, g in
                gasto(String(format: "k%02d", i + 1), g.1, g.2, g.3, meses(-g.0))
            }),
            copiaDaCasa("a8", ["valorEstimadoVenda": .nulo]),
        ])
        return .objeto(raiz)
    }
}
#endif
