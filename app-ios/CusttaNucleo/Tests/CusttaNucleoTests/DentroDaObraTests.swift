import Testing
@testable import CusttaNucleo

/* As regras da etapa 3 que o site não tem (mockup aprovado em 18/10): o aviso dos tópicos e o que está fora, o cartão da
   tela Orçamento e o gasto por tópico no modo total. Valores de mil para cima, para separar moeda de moedaCurta. */
struct DentroDaObraTests {
    static let hoje = "2026-10-12"

    func gasto(_ id: String, _ data: String, _ valor: Double, topico: String = "matbasicos") -> ValorJSON {
        .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(""), "data": .texto(data),
                 "pagamento": .texto("pix")])
    }

    func obra(_ gastos: [ValorJSON], orcamento: ValorJSON? = nil, extra: [String: ValorJSON] = [:]) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-08-12"),
                                      "fase": .texto("construcao"), "gastos": .lista(gastos)]
        if let orcamento { o["orcamento"] = orcamento }
        o.merge(extra) { _, novo in novo }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    func porTopico(_ previstos: [String: Double]) -> ValorJSON {
        .objeto(["modo": .texto("topicos"), "topicos": .objeto(previstos.mapValues(ValorJSON.numero))])
    }

    func resumo(_ previstos: [String: Double], _ gastos: [(String, Double)]) throws -> ResumoOrcamento {
        try #require(orcamentoObra(obra(gastos.enumerated().map { gasto("g\($0.offset)", "2026-10-01", $0.element.1, topico: $0.element.0) },
                                        orcamento: porTopico(previstos))))
    }

    @Test func avisoDosTopicosNaLinhaDoOrcamento() throws {
        let dois = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000],
                              [("estrutura", 120_000), ("fundacao", 52_000), ("pintura", 18_500), ("eletrica", 1_000), ("projeto", 29_780.5)])
        #expect(avisoDosTopicos(dois) == "2 tópicos passaram do previsto", "o pior aviso: o perto da pintura não aparece")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000], [("pintura", 25_000), ("eletrica", 9_500)]))
                == "1 tópico passou do previsto")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000, "estrutura": 5_000],
                                           [("pintura", 18_500), ("eletrica", 9_500), ("estrutura", 4_600)])) == "3 tópicos perto do limite")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000], [("pintura", 18_500), ("eletrica", 1_000)]))
                == "1 tópico perto do limite")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        let total = try #require(orcamentoObra(obra([gasto("a", "2026-10-01", 900_000)],
                                                    orcamento: .objeto(["modo": .texto("total"), "total": .numero(400_000)]))))
        #expect(avisoDosTopicos(total) == nil && foraNaLinha(total) == nil && fraseDoForaNoCartao(total) == nil)
    }

    @Test func oQueEstaForaNaLinhaENoCartao() throws {
        let r = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000],
                           [("estrutura", 120_000), ("fundacao", 52_000), ("pintura", 18_500), ("eletrica", 1_000), ("projeto", 29_780.5)])
        #expect(foraNaLinha(r) == "R$ 30 mil fora do orçamento")
        #expect(try foraNaLinha(resumo(["pintura": 20_000], [("pintura", 1_000), ("projeto", 8_000)])) == "R$ 8 mil fora do orçamento",
                "o moneyCurto do site, sem o \",0\"")
        #expect(try foraNaLinha(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        #expect(fraseDoForaNoCartao(r) == "Os R$\u{00A0}29.780,50 fora do orçamento não entram nesta conta.")
        #expect(try fraseDoForaNoCartao(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        #expect(usadoDoPrevisto(r.geral) == "106% usado de R$\u{00A0}180.000,00")
    }

    @Test func oQueEstaForaSomaOsTopicosSemPrevisto() throws {
        // Dois tópicos sem previsto: a linha e o cartão mostram a soma (foraTotal), não o maior nem o último.
        let r = try resumo(["pintura": 20_000], [("pintura", 1_000), ("projeto", 8_000), ("terreno", 4_000)])
        #expect(foraNaLinha(r) == "R$ 12 mil fora do orçamento")
        #expect(fraseDoForaNoCartao(r) == "Os R$\u{00A0}12.000,00 fora do orçamento não entram nesta conta.")
    }

    @Test func cartaoDaTelaOrcamento() throws {
        let r = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000], [("estrutura", 1_000)])
        #expect(tituloDoCartao(r) == "Orçamento por tópico")
        #expect(previstoDoCartao(r) == "de R$\u{00A0}180.000,00 previstos em 4 tópicos")
        #expect(try previstoDoCartao(resumo(["pintura": 5_000], [("pintura", 1_000), ("projeto", 2_000)]))
                == "de R$\u{00A0}5.000,00 previstos em 1 tópico", "o tópico fora não conta")
        let total = try #require(orcamentoObra(obra([gasto("a", "2026-10-01", 1_000)],
                                                    orcamento: .objeto(["modo": .texto("total"), "total": .numero(400_000)]))))
        #expect(tituloDoCartao(total) == "Orçamento total" && previstoDoCartao(total) == "de R$\u{00A0}400.000,00")
    }

    @Test func gastoPorTopicoNoModoTotal() {
        let o = obra([gasto("e1", "2026-09-01", 3_000, topico: "estrutura"), gasto("x1", "2026-09-02", 1_500, topico: "c_apagado"),
                      gasto("f1", "2026-09-03", 3_000, topico: "fundacao"), gasto("l1", "2026-09-04", 2_000, topico: "eletrica"),
                      gasto("l2", "2026-12-04", 2_500, topico: "eletrica")])
        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
        #expect(linhas.map(\.id) == ["eletrica", "estrutura", "fundacao", "c_apagado"], "do maior para o menor; no empate, a ordem dos gastos")
        #expect(linhas.map(\.bruto) == [4_500, 3_000, 3_000, 1_500], "o bruto, com o gasto futuro")
        #expect(linhas.map(\.pct) == [38, 25, 25, 13], "o Math.round do site: 37,5 vai a 38")
        #expect(textoDaParteDaObra(linhas[0].pct) == "38% da obra")
        #expect(gastoPorTopico(obra([]), hoje: Self.hoje, taxaMensal: 1).isEmpty)
        #expect(dicaDoModoTotal == "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
    }

    @Test func gastoPorTopicoNoEmpateSegueAOrdemDosGastos() {
        // A legenda do donut do site: o byTop nasce na ordem dos gastos e o sort do JavaScript é estável, então no empate do
        // bruto vem o tópico que aparece primeiro na lista (fundação, pintura, estrutura): não o de id menor nem o de id maior,
        // nem o do último gasto, nem o da data. A elétrica tem o mesmo "% da obra" arredondado, mas bruto menor: vai depois.
        let o = obra([gasto("l1", "2026-09-28", 1_990, topico: "eletrica"), gasto("f1", "2026-09-03", 2_000, topico: "fundacao"),
                      gasto("p1", "2026-09-20", 1_000, topico: "pintura"), gasto("e1", "2026-09-01", 2_000, topico: "estrutura"),
                      gasto("p2", "2026-09-25", 1_000, topico: "pintura"), gasto("a1", "2026-09-02", 2_500, topico: "acabamento")])
        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
        #expect(linhas.map(\.id) == ["acabamento", "fundacao", "pintura", "estrutura", "eletrica"])
        #expect(linhas.map(\.bruto) == [2_500, 2_000, 2_000, 2_000, 1_990])
        #expect(linhas.map(\.pct) == [24, 19, 19, 19, 19], "o empate é do bruto, não do % arredondado")
    }

    @Test func topicosComValorNaFolha() {
        #expect(topicosComValor(["terreno": 10, "projeto": 0, "pintura": 5, "eletrica": -3], de: 23) == "2 de 23 tópicos com valor")
        #expect(topicosComValor([:], de: 21) == "0 de 21 tópicos com valor")
    }
}
