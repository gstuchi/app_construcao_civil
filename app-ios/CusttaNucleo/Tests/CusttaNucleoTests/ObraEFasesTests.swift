import Testing
@testable import CusttaNucleo

/* O que as folhas da obra e da venda e as ações da fase fazem no estado (app.js formNovaObra, formEditarObra, formVenda,
   mudarFase e o desfazer da venda): a obra nova no fim e na forma que o site grava; editar só os campos do formulário;
   apagar; a fase só entre construção e pronta; vender só a pronta; desfazer apaga a chave `venda`. Obra que sumiu, ou
   que outro aparelho mudou de fase com a tela aberta, devolve nil: nada é gravado. */
struct MutacoesDaObraTests {
    func estado() -> Estado {
        Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "fase": .texto("construcao"),
                     "areaM2": .numero(120), "valorEstimadoVenda": .numero(900_000), "campoDoSite": .numero(7),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(500_000)]),
                     "gastos": .lista([.objeto(["id": .texto("a"), "valor": .numero(10), "topico": .texto("pintura"),
                                                "descricao": .texto("Tinta"), "data": .texto("2026-02-01"), "pagamento": .texto("pix")])])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado"), "dataInicio": .texto("2025-06-01"), "fase": .texto("pronta"),
                     "gastos": .lista([])]),
            .objeto(["id": .texto("o3"), "nome": .texto("Vendida"), "dataInicio": .texto("2024-01-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(800_000), "data": .texto("2025-02-10"), "notaDoSite": .texto("fica")]),
                     "gastos": .lista([])]),
        ])]))
    }

    /// A obra `i` do documento que vai para o banco.
    func gravada(_ e: Estado, _ i: Int) -> [String: ValorJSON]? {
        guard case .objeto(let raiz) = e.arvore, case .lista(let obras) = raiz["obras"], i < obras.count else { return nil }
        return obras[i].comoObjeto
    }

    @Test func obraNovaNoFimComoOSiteGrava() throws {
        let nova = obraNova(CamposDaObra(nome: "Casa Granja Viana 2", dataInicio: "2026-10-01", valorEstimadoVenda: 1_600_000, areaM2: 280),
                            id: "n1", hoje: "2026-10-13")
        let e = try #require(estado().criandoObra(nova))
        #expect(e.obras.map(\.id) == ["o1", "o2", "o3", "n1"], "o push do site: no fim do documento")
        let documento = try #require(gravada(e, 3))
        #expect(documento == nova, "no documento como o site grava")
        #expect(documento["afazeres"] == nil && documento["venda"] == nil, "sem venda e sem afazeres (a leitura acrescenta)")
        let antiga = try #require(gravada(e, 0))
        #expect(antiga["afazeres"] == .lista([]) && antiga["venda"] == .nulo && antiga["campoDoSite"] == .numero(7),
                "as que já estavam continuam como a leitura normalizada deixou")
    }

    @Test func obraNovaNaoPassaDoTetoDasRules() {
        var cheio = Estado.vazio
        cheio.obras = (0..<limiteDeObras).map { Obra(arvore: ["id": .texto("x\($0)"), "nome": .texto("O"), "dataInicio": .texto("2026-01-01")]) }
        let nova = obraNova(CamposDaObra(nome: "A mais", dataInicio: "", areaM2: 1), id: "a", hoje: "2026-10-13")
        #expect(cheio.criandoObra(nova) == nil, "a 301ª faria toda gravação seguinte ser recusada pelas rules")
        cheio.obras.removeLast()
        #expect(cheio.criandoObra(nova)?.obras.count == limiteDeObras, "a 300ª ainda entra")
    }

    @Test func editarSoOsCamposDoFormulario() throws {
        let e = try #require(estado().editandoObra("o1", CamposDaObra(nome: "Casa Nova", dataInicio: "", valorEstimadoVenda: 0, areaM2: 3.125)))
        let o = e.obras[0]
        #expect(o.nome == "Casa Nova" && o.dataInicio == "2026-01-01", "início vazio fica o antigo")
        #expect(o.campos["valorEstimadoVenda"] == .nulo, "estimado zero vira null")
        #expect(o.areaM2 == 3.125)
        #expect(o.campos["campoDoSite"] == .numero(7) && o.orcamento != nil && o.gastos.count == 1 && o.fase == .construcao, "o resto fica")
        let semArea = try #require(estado().editandoObra("o1", CamposDaObra(nome: "Casa", dataInicio: "2025-12-01", valorEstimadoVenda: 1, areaM2: 0)))
        #expect(semArea.obras[0].campos["areaM2"] == .nulo && semArea.obras[0].dataInicio == "2025-12-01", "área opcional na edição")
        #expect(estado().editandoObra("sumiu", CamposDaObra(nome: "X", dataInicio: "")) == nil)
    }

    @Test func apagarObra() throws {
        let e = try #require(estado().apagandoObra("o2"))
        #expect(e.obras.map(\.id) == ["o1", "o3"])
        #expect(estado().apagandoObra("sumiu") == nil)
    }
}
