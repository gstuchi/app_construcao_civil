import Testing
@testable import CusttaNucleo

/* Os campos do "Vale a pena?" e o que a tela mostra: regra do site (app.js, simulaCompute) fora dos vetores, porque lá ela
   mora no campo do HTML (o `touched` do preço e o valor inicial dos meses). */
struct SimulacaoNaTelaTests {
    private let hoje = "2026-10-12"

    private func obra(_ id: String, estimada: Double? = nil, area: Double? = nil, fase: String = "construcao",
                      gastos: [(String, Double)] = [("2026-01-15", 100_000), ("2026-03-02", 50_000)]) -> Obra {
        var arvore: [String: ValorJSON] = [
            "id": .texto(id), "nome": .texto("Obra \(id)"), "fase": .texto(fase), "dataInicio": .texto("2026-01-10"),
            "gastos": .lista(gastos.enumerated().map { i, g in .objeto(["id": .texto("\(id)-g\(i)"), "valor": .numero(g.1), "data": .texto(g.0)]) }),
        ]
        if let estimada { arvore["valorEstimadoVenda"] = .numero(estimada) }
        if let area { arvore["areaM2"] = .numero(area) }
        return Obra(arvore: arvore)
    }

    private func tela(_ campos: CamposDoSimulador, _ obras: [Obra]) -> SimulacaoNaTela {
        simulacaoNaTela(campos, obras: obras, hoje: hoje, taxa: 1)
    }

    @Test func semObraElegivelNaoHaContaNemPreco() {
        let vendida = obra("v", estimada: 300_000, fase: "vendida"), vazia = obra("z", estimada: 300_000, gastos: [])
        for obras in [[], [vendida, vazia]] {
            let t = tela(CamposDoSimulador(), obras)
            #expect(t.elegiveis.isEmpty)
            #expect(t.obra == nil)
            #expect(t.preco == nil)
            #expect(t.conta == nil && t.textos == nil && t.faixa == nil)
        }
    }

    @Test func semDigitarOPrecoAcompanhaAVendaEstimadaDaObraEscolhida() {
        let a = obra("a", estimada: 300_000, area: 120), b = obra("b", estimada: 180_000)
        var campos = CamposDoSimulador()
        var t = tela(campos, [a, b])
        #expect(t.elegiveis.map(\.id) == ["a", "b"])
        #expect(t.obra?.id == "a", "sem escolha, vale a primeira elegível")
        #expect(t.preco == 300_000)
        #expect(t.conta?.venda == 300_000)
        // Trocar de obra sem ter digitado troca o preço (no site de antes do PR 0 a segunda herdava o da primeira).
        campos.obraId = "b"
        t = tela(campos, [a, b])
        #expect(t.obra?.id == "b")
        #expect(t.preco == 180_000)
        #expect(t.conta?.venda == 180_000)
    }

    @Test func semEstimadaOCampoFicaVazioEATelaPedeOPreco() {
        for semPreco in [obra("a"), obra("a", estimada: 0)] {
            let t = tela(CamposDoSimulador(), [semPreco])
            #expect(t.obra?.id == "a")
            #expect(t.preco == nil)
            #expect(t.conta == nil && t.textos == nil && t.faixa == nil)
        }
    }

    @Test func depoisDeDigitarValeODigitadoMesmoTrocandoDeObra() {
        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
        var campos = CamposDoSimulador()
        campos.precoDigitado = 250_000
        #expect(tela(campos, [a, b]).preco == 250_000)
        campos.obraId = "b"
        let t = tela(campos, [a, b])
        #expect(t.preco == 250_000)
        #expect(t.conta?.venda == 250_000)
    }

    @Test func campoApagadoNaoVoltaParaAEstimada() {
        var campos = CamposDoSimulador()
        campos.precoDigitado = 0
        let t = tela(campos, [obra("a", estimada: 300_000)])
        #expect(t.preco == nil)
        #expect(t.conta == nil)
    }

    @Test func aEscolhidaQueDeixaDeSerElegivelCaiNaPrimeira() {
        var campos = CamposDoSimulador()
        campos.obraId = "b"
        let a = obra("a", estimada: 300_000)
        #expect(tela(campos, [a, obra("b", estimada: 180_000)]).obra?.id == "b")
        #expect(tela(campos, [a, obra("b", estimada: 180_000, fase: "vendida")]).obra?.id == "a")
        #expect(tela(campos, [a]).obra?.id == "a", "a obra apagada em outro aparelho")
    }

    @Test func osMesesComecamEmZeroEAndamDeZeroACentoEVinte() {
        var campos = CamposDoSimulador()
        #expect(campos.meses == 0)
        campos.andarMeses(-1)
        #expect(campos.meses == 0)
        var t = tela(campos, [obra("a", estimada: 300_000)])
        #expect(!t.podeMenos && t.podeMais)
        #expect(t.conta?.meses == 0)
        campos.andarMeses(1)
        t = tela(campos, [obra("a", estimada: 300_000)])
        #expect(t.meses == 1 && t.podeMenos && t.podeMais)
        #expect(t.conta?.meses == 1)
        campos.andarMeses(500)
        t = tela(campos, [obra("a", estimada: 300_000)])
        #expect(t.meses == 120 && t.podeMenos && !t.podeMais)
        #expect(t.conta?.alvo == "2036-10-12")
    }

    @Test func osTextosEAFaixaSaoOsDaContaComAAreaDaObra() throws {
        let a = obra("a", estimada: 300_000, area: 120)
        let t = tela(CamposDoSimulador(), [a])
        let conta = try #require(t.conta)
        #expect(conta == contaSimulador(a, venda: 300_000, meses: 0, hoje: hoje, taxa: 1))
        #expect(t.textos == textosSimulador(conta, taxa: 1, area: 120))
        #expect(t.textos?.tabela.last?.rotulo == "Preço por m² (120 m²)")
        #expect(t.faixa == faixaSimulador(conta))
    }
}
