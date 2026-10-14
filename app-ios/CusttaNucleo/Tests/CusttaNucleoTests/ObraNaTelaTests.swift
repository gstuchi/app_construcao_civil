import Testing
@testable import CusttaNucleo

/* A tela da obra: lista por mês, "A vencer" no alto, a linha do gasto e os indicadores, com os números dos vetores. */
struct ObraNaTelaTests {
    static let hoje = "2026-10-12"

    func gasto(_ id: String, _ data: String, _ valor: Double, descricao: String = "", topico: String = "matbasicos",
               pagamento: String = "pix", parcela: (Int, Int)? = nil) -> ValorJSON {
        var g: [String: ValorJSON] = ["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(descricao),
                                      "data": .texto(data), "pagamento": .texto(pagamento)]
        if let parcela {
            g["grupoId"] = .texto("gr")
            g["parcela"] = .objeto(["n": .numero(Double(parcela.0)), "de": .numero(Double(parcela.1))])
        }
        return .objeto(g)
    }

    func obra(_ gastos: [ValorJSON], extra: [String: ValorJSON] = [:]) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-08-12"),
                                      "fase": .texto("construcao"), "gastos": .lista(gastos)]
        o.merge(extra) { _, novo in novo }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    @Test func datasDaTela() {
        #expect(dataCurta("2026-10-05") == "05/10/26")
        #expect(dataPorExtenso("2026-10-05") == "5 de outubro de 2026")
        #expect(tituloDoMes("2026-03") == "Março de 2026")
        #expect(textoDoInicio(obra([]), hoje: Self.hoje) == "começou em 12/08/25 · 14 meses")
    }

    @Test func mesesDoMaisRecenteEAVencerNoAlto() {
        let o = obra([
            gasto("a", "2026-09-30", 100), gasto("b", "2026-10-10", 4980), gasto("c", "2026-10-12", 10),
            gasto("d", "2026-11-05", 6150, parcela: (5, 10)), gasto("e", "2026-10-15", 4800, parcela: (2, 6)),
            gasto("f", "2026-10-10", 1), gasto("g", "2026-11-05", 2300, parcela: (2, 3)),
        ])
        let lista = listaDaObra(o, hoje: Self.hoje)
        #expect(lista.meses.map(\.id) == ["2026-10", "2026-09"], "hoje fica fora do A vencer")
        #expect(lista.meses[0].gastos.map(\.id) == ["c", "f", "b"], "data e id do mais recente para o mais antigo, como o site")
        #expect(lista.meses[0].total == 4991)
        #expect(lista.meses[0].titulo == "Outubro de 2026")
        let aVencer = try! #require(lista.aVencer)
        #expect(aVencer.meses.map(\.id) == ["2026-10", "2026-11"], "o próximo vencimento primeiro")
        #expect(aVencer.meses[1].gastos.map(\.id) == ["d", "g"])
        #expect(aVencer.total == 13250)
        #expect(aVencer.resumo == "3 gastos · o próximo é em 15/10/26")
        #expect(listaDaObra(obra([gasto("a", "2026-09-30", 100)]), hoje: Self.hoje).aVencer == nil)
    }

    @Test func linhaDoGasto() {
        let topicos = mapaDeTopicos([])
        let pix = linhaDeGasto(Gasto(campos: gasto("a", "2026-10-10", 4980, descricao: "Cimento CP-II, 120 sacos").comoObjeto!), topicos: topicos)
        #expect(pix.titulo == "Cimento CP-II, 120 sacos")
        #expect(pix.topico == "Materiais básicos")
        #expect(pix.pagamento == "Pix")
        #expect(pix.data == "10/10/26")
        #expect(pix.valor == "\u{2212}R$\u{a0}4.980,00")
        #expect(pix.rotulo == "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026")
        #expect(pix.valorFalado == "R$\u{a0}4.980,00")
        let semDescricao = linhaDeGasto(Gasto(campos: gasto("b", "2026-10-06", 2300, topico: "pintura", pagamento: "cartao", parcela: (1, 3)).comoObjeto!),
                                        topicos: topicos)
        #expect(semDescricao.titulo == "Pintura (1/3)", "sem descrição, o título é o tópico")
        #expect(semDescricao.topico == nil, "e a linha de baixo não repete o tópico")
        #expect(semDescricao.pagamento == "Cartão")
        #expect(semDescricao.rotulo == "Pintura, parcela 1 de 3. Cartão, 6 de outubro de 2026")
        let estranho = linhaDeGasto(Gasto(campos: gasto("c", "2026-10-06", 1, topico: "c_sumiu", pagamento: "boleto").comoObjeto!), topicos: topicos)
        #expect(estranho.titulo == "c_sumiu" && estranho.icone == "etiqueta" && estranho.pagamento == nil)
    }

    @Test func indicadoresComOsTextosDoSite() {
        let comGastos = obra([gasto("a", "2026-09-30", 100), gasto("b", "2026-10-20", 50), gasto("c", "2026-12-20", 70)],
                             extra: ["valorEstimadoVenda": .numero(1_450_000), "areaM2": .numero(300)])
        let i = indicadoresDaObra(comGastos, taxa: 1, hoje: Self.hoje)
        #expect(i.totalGasto == "R$\u{a0}220,00")
        #expect(i.etiquetaDoTotal == "3 lançamentos")
        #expect(i.notaDoCorrigido.hasPrefix("Correção até hoje: +R$"))
        #expect(i.aPagar == "R$\u{a0}50,00" && i.etiquetaDoAPagar == "1 vencimento")
        #expect(i.venda == .estimada(valor: "R$\u{a0}1.450.000,00", nota: "R$ 4,8 mil/m² · 300 m²"))
        let vazia = indicadoresDaObra(obra([]), taxa: 1, hoje: Self.hoje)
        #expect(vazia.etiquetaDoTotal == "sem gastos" && vazia.etiquetaDoAPagar == "nada em 30 dias")
        #expect(vazia.venda == .semEstimativa)
        let semArea = indicadoresDaObra(obra([gasto("a", "2026-09-30", 100)], extra: ["valorEstimadoVenda": .numero(1000)]), taxa: 0, hoje: Self.hoje)
        #expect(semArea.venda == .estimada(valor: "R$\u{a0}1.000,00", nota: "margem R$\u{a0}900,00"))
        let vendida = obra([gasto("a", "2025-09-30", 200_000)],
                           extra: ["fase": .texto("vendida"), "venda": .objeto(["valor": .numero(150_000), "data": .texto("2026-06-30")])])
        let v = indicadoresDaObra(vendida, taxa: 1, hoje: Self.hoje)
        #expect(v.notaDoCorrigido.hasPrefix("Correção até a venda: +R$"))
        guard case .vendida(let valor, let etiqueta, let nota, let positivo) = v.venda else { Issue.record("vendida"); return }
        #expect(valor == "R$\u{a0}150.000,00" && etiqueta == "Vendida em 30/06/26" && !positivo)
        #expect(nota.hasPrefix("lucro -R$ 50 mil · -R$"), "\(nota)")
    }
}
