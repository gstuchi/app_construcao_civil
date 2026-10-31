import Testing
@testable import CusttaNucleo

/* O mês dos gráficos de mês (regra do app, sem vetor do site): o mês de referência, o escolhido por padrão, os meses a
   vencer, as frases do que ficou fora, a média, o maior e os meses, e o aviso dos 24 meses. Tudo depende de hoje, que entra
   por parâmetro; os casos cobrem a virada do mês e do ano. */
struct MesesDosGraficosTests {
    func obra(_ gastos: [(data: String, valor: Double)], venda: String? = nil) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-05"),
                                      "fase": .texto(venda == nil ? "construcao" : "vendida"),
                                      "gastos": .lista(gastos.enumerated().map { i, g in
                                          .objeto(["id": .texto("g\(i)"), "valor": .numero(g.valor), "topico": .texto("terreno"),
                                                   "descricao": .texto(""), "data": .texto(g.data), "pagamento": .texto("pix")])
                                      })]
        if let venda { o["venda"] = .objeto(["valor": .numero(2_000_000), "data": .texto(venda)]) }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    /// Uma obra com gastos de março de 2026 até uma parcela de novembro; hoje é 12/10/2026.
    var casa: Obra {
        obra([("2026-03-10", 100_000), ("2026-05-02", 400_000), ("2026-05-20", 200_000), ("2026-07-01", 600_000),
              ("2026-10-25", 300_000), ("2026-11-05", 900_000)])
    }

    @Test func mesDeReferenciaEsteMesOuODaVenda() {
        #expect(mesDeReferencia(casa, hoje: "2026-10-12") == "2026-10")
        #expect(mesDeReferencia(obra([("2026-03-10", 1)], venda: "2026-06-20"), hoje: "2026-10-12") == "2026-06")
    }

    @Test func mesEscolhidoPorPadrao() {
        let serie = serieMensal(casa.gastos)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2026-10") == 7)     // este mês, não novembro (o site cairia nele)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2026-06") == 3)     // o da venda
        // Fora da série, o último com gasto (o mês de valor zero no fim não conta).
        let parada = serieMensal(obra([("2025-01-10", 100), ("2025-03-02", 0)]).gastos)
        #expect(mesPadraoDoGastoPorMes(parada, referencia: "2026-10") == 0)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2025-01") == 8)
        // Sem mês com gasto (tudo zerado), o primeiro, como o Math.max(0, …) do mockup.
        #expect(mesPadraoDoGastoPorMes(serieMensal(obra([("2025-01-10", 0), ("2025-03-02", 0)]).gastos), referencia: "2026-10") == 0)
        #expect(mesPadraoDoGastoPorMes([], referencia: "2026-10") == nil)
    }

    @Test func mesesAVencerDepoisDaReferencia() {
        #expect(mesAVencer("2026-11", referencia: "2026-10"))
        #expect(!mesAVencer("2026-10", referencia: "2026-10"))                // o mês corrente conta inteiro, como pago
        #expect(!mesAVencer("2026-09", referencia: "2026-10"))
        #expect(mesAVencer("2027-01", referencia: "2026-12"))
    }

    @Test func frasesDoQueFicouFora() {
        // A parcela de 25/10 está a vencer (depois de hoje), embora outubro conte inteiro no gasto por mês.
        #expect(foraDaEvolucao(casa, hoje: "2026-10-12") == 1_200_000)
        #expect(fraseForaDaEvolucao(casa, hoje: "2026-10-12") == "Fora do gráfico: R$\u{00A0}1.200.000,00 a vencer (depois de hoje).")
        #expect(fraseAVencerDoAnel(casa, hoje: "2026-10-12") == "Inclui R$\u{00A0}1.200.000,00 a vencer.")
        // No dia do gasto, ele já está no gráfico.
        #expect(fraseForaDaEvolucao(casa, hoje: "2026-11-05") == nil)
        #expect(fraseAVencerDoAnel(casa, hoje: "2026-11-05") == nil)
        // Só acima de meio centavo, como o mockup: 1 centavo a vencer aparece; 0,4 centavo (poeira de conta) não.
        let centavo = obra([("2026-11-05", 0.01)]), poeira = obra([("2026-11-05", 0.004)])
        #expect(fraseForaDaEvolucao(centavo, hoje: "2026-10-12") == "Fora do gráfico: R$\u{00A0}0,01 a vencer (depois de hoje).")
        #expect(fraseAVencerDoAnel(centavo, hoje: "2026-10-12") == "Inclui R$\u{00A0}0,01 a vencer.")
        #expect(fraseForaDaEvolucao(poeira, hoje: "2026-10-12") == nil)
        #expect(fraseAVencerDoAnel(poeira, hoje: "2026-10-12") == nil)
        // Na vendida, o que tem data depois da venda (no mesmo mês também); o anel não fala de "a vencer".
        let vendida = obra([("2026-03-10", 50_000), ("2026-06-20", 1_000), ("2026-06-25", 8_000), ("2026-07-01", 2_000)], venda: "2026-06-20")
        #expect(fraseForaDaEvolucao(vendida, hoje: "2026-10-12") == "Fora do gráfico: R$\u{00A0}10.000,00 com data depois da venda.")
        #expect(fraseAVencerDoAnel(vendida, hoje: "2026-10-12") == nil)
        #expect(fraseForaDaEvolucao(obra([("2026-03-10", 50_000)], venda: "2026-06-20"), hoje: "2026-10-12") == nil)
    }

    @Test func viradaDoMesEDoAno() {
        let virada = obra([("2026-09-15", 4_000), ("2026-11-01", 1_000)])
        // No último dia de outubro, novembro está a vencer e fica fora da média.
        #expect(mesDeReferencia(virada, hoje: "2026-10-31") == "2026-10")
        #expect(fraseForaDaEvolucao(virada, hoje: "2026-10-31") == "Fora do gráfico: R$\u{00A0}1.000,00 a vencer (depois de hoje).")
        #expect(resumoDosMeses(virada, hoje: "2026-10-31").meses == 2)
        // No 1º de novembro, novembro é este mês: entra na média e sai das frases.
        #expect(mesDeReferencia(virada, hoje: "2026-11-01") == "2026-11")
        #expect(!mesAVencer("2026-11", referencia: mesDeReferencia(virada, hoje: "2026-11-01")))
        #expect(fraseForaDaEvolucao(virada, hoje: "2026-11-01") == nil)
        #expect(resumoDosMeses(virada, hoje: "2026-11-01") == ResumoDosMeses(media: 5_000.0 / 3, maior: PontoMensal(mes: "2026-09", total: 4_000), meses: 3))
        // Na virada do ano.
        let ano = obra([("2026-12-20", 3_000), ("2027-01-01", 6_000)])
        #expect(resumoDosMeses(ano, hoje: "2026-12-31").meses == 1)
        #expect(resumoDosMeses(ano, hoje: "2027-01-01") == ResumoDosMeses(media: 4_500, maior: PontoMensal(mes: "2027-01", total: 6_000), meses: 2))
    }

    @Test func mediaMaiorEMeses() {
        // De março a outubro (8 meses, com abril, junho, agosto e setembro zerados); outubro conta inteiro, novembro não.
        let r = resumoDosMeses(casa, hoje: "2026-10-12")
        #expect(r == ResumoDosMeses(media: 200_000, maior: PontoMensal(mes: "2026-05", total: 600_000), meses: 8))  // maio empata com julho: o primeiro
        #expect(r.numeros == [NumeroDoResumo(rotulo: "Média por mês", valor: "R$ 200 mil"), NumeroDoResumo(rotulo: "Maior · mai", valor: "R$ 600 mil"),
                              NumeroDoResumo(rotulo: "Meses", valor: "8")])
        // Na vendida, até o mês da venda.
        #expect(resumoDosMeses(obra(casa.gastos.map { ($0.data, $0.valor) }, venda: "2026-06-20"), hoje: "2026-10-12")
                == ResumoDosMeses(media: 175_000, maior: PontoMensal(mes: "2026-05", total: 600_000), meses: 4))
        // Só gastos a vencer: nenhum mês.
        let futuro = resumoDosMeses(obra([("2026-11-05", 900_000)]), hoje: "2026-10-12")
        #expect(futuro == ResumoDosMeses(media: 0, maior: nil, meses: 0))
        #expect(futuro.numeros.map(\.valor) == ["R$\u{00A0}0,00", "—", "0"])
        #expect(futuro.numeros[1].rotulo == "Maior")
    }

    @Test func avisoSoComASerieCortada() {
        func mensal(_ de: String, _ ate: String) -> Obra { obra([(de + "-01", 10), (ate + "-01", 10)]) }
        #expect(!gastoPorMesFoiCortado(mensal("2024-11", "2026-10").gastos))           // 24 meses: cabem
        #expect(gastoPorMesFoiCortado(mensal("2024-10", "2026-10").gastos))            // 25: cortado
        #expect(!gastoPorMesFoiCortado([]))
        // A evolução vai até hoje: uma obra parada há tempo tem a evolução cortada e o gasto por mês inteiro.
        let parada = mensal("2023-01", "2024-06")
        #expect(evolucaoFoiCortada(parada, hoje: "2026-10-12"))
        #expect(!gastoPorMesFoiCortado(parada.gastos))
        #expect(!evolucaoFoiCortada(parada, hoje: "2024-12-31"))                       // 2023-01 a 2024-12: 24 meses
        #expect(evolucaoFoiCortada(parada, hoje: "2025-01-01"))                        // 2023-01 a 2025-01: 25, cortada
        #expect(!evolucaoFoiCortada(obra([]), hoje: "2026-10-12"))
        // Na vendida ela para na venda: a mesma obra vendida em 12/2024 cabe em 24 meses mesmo em 2026; vendida em 01/2025, não.
        let gastosDaParada: [(data: String, valor: Double)] = parada.gastos.map { ($0.data, $0.valor) }
        #expect(!evolucaoFoiCortada(obra(gastosDaParada, venda: "2024-12-31"), hoje: "2026-10-12"))
        #expect(evolucaoFoiCortada(obra(gastosDaParada, venda: "2025-01-31"), hoje: "2026-10-12"))
        // Os gastos ficam na ordem em que foram lançados, não na das datas (o gasto antigo lançado depois): o corte vai do
        // mês mais antigo ao mais novo, não do 1º ao último do documento.
        let foraDeOrdem = obra([("2026-10-01", 10), ("2024-10-01", 10), ("2025-06-01", 10)])
        #expect(gastoPorMesFoiCortado(foraDeOrdem.gastos))                            // 2024-10 a 2026-10: 25 meses
        #expect(evolucaoFoiCortada(foraDeOrdem, hoje: "2026-10-12"))
        #expect(avisoDos24Meses == "Mostrando os últimos 24 meses.")
    }
}
