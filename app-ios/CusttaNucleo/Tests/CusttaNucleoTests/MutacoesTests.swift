import Testing
@testable import CusttaNucleo

/* O que as telas que gravam fazem no estado: lançar no fim, editar no lugar, apagar um gasto e a compra toda, sem tocar
   no que o app não conhece; obra ou gasto que sumiram devolvem nil (nada é gravado). */
struct MutacoesTests {
    func estado() -> Estado {
        Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .numero(7), "gastos": .lista([
                .objeto(["id": .texto("a"), "valor": .numero(10), "topico": .texto("pintura"), "descricao": .texto("Tinta"), "data": .texto("2026-02-01"),
                         "pagamento": .texto("pix"), "notaSoDoSite": .texto("fica")]),
                .objeto(["id": .texto("p1"), "valor": .numero(5), "topico": .texto("eletrica"), "descricao": .texto("Fios"), "data": .texto("2026-03-01"),
                         "pagamento": .texto("cartao"), "grupoId": .texto("g"), "parcela": .objeto(["n": .numero(1), "de": .numero(2)])]),
                .objeto(["id": .texto("p2"), "valor": .numero(5), "topico": .texto("eletrica"), "descricao": .texto("Fios"), "data": .texto("2026-04-01"),
                         "pagamento": .texto("cartao"), "grupoId": .texto("g"), "parcela": .objeto(["n": .numero(2), "de": .numero(2)])]),
            ])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado"), "dataInicio": .texto("2026-01-01"), "gastos": .lista([])]),
        ])]))
    }

    @Test func lancarNoFimDaObra() throws {
        let novo = Gasto(campos: ["id": .texto("n"), "valor": .numero(1), "topico": .texto("outros"), "descricao": .texto(""),
                                  "data": .texto("2026-05-01"), "pagamento": .texto("pix")])
        let e = try #require(estado().lancandoGastos([novo], naObra: "o1"))
        #expect(e.obras[0].gastos.map(\.id) == ["a", "p1", "p2", "n"])
        #expect(e.obras[0].campos["campoDoSite"] == .numero(7), "o que o app não conhece fica")
        #expect(estado().lancandoGastos([novo], naObra: "sumiu") == nil)
    }

    @Test func editarNoLugarAPartirDoGastoAtual() throws {
        let entrada = EntradaDoGasto(valor: 99, topico: "pintura", descricao: "Tinta fosca", data: "2026-02-01", pagamento: "pix")
        let conferido = try conferirGasto(entrada, editado: estado().obras[0].gastos[0], hoje: "2026-10-13").get()
        let e = try #require(estado().editandoGasto("a", entrada, conferido, naObra: "o1"))
        #expect(e.obras[0].gastos.map(\.id) == ["a", "p1", "p2"])
        #expect(e.obras[0].gastos[0].valor == 99 && e.obras[0].gastos[0].descricao == "Tinta fosca")
        #expect(e.obras[0].gastos[0].campos["notaSoDoSite"] == .texto("fica"))
        // Outro aparelho mudou o gasto com a folha aberta: a edição parte do que está no estado agora.
        var mudado = estado()
        mudado.obras[0].gastos[0].campos["notaSoDoSite"] = .texto("mudou em outro aparelho")
        let depois = try #require(mudado.editandoGasto("a", entrada, conferido, naObra: "o1"))
        #expect(depois.obras[0].gastos[0].campos["notaSoDoSite"] == .texto("mudou em outro aparelho"))
        #expect(estado().editandoGasto("x", entrada, conferido, naObra: "o1") == nil, "o gasto sumiu")
    }

    @Test func apagarUmEAcompraToda() throws {
        let um = try #require(estado().apagandoGasto("p1", daObra: "o1"))
        #expect(um.obras[0].gastos.map(\.id) == ["a", "p2"], "só esta parcela")
        let toda = try #require(estado().apagandoCompra("g", daObra: "o1"))
        #expect(toda.obras[0].gastos.map(\.id) == ["a"], "as parcelas que restam saem juntas")
        #expect(estado().apagandoGasto("x", daObra: "o1") == nil && estado().apagandoCompra("x", daObra: "o1") == nil)
        #expect(parcelasDaCompra(estado().obras[0].gastos[1], naObra: estado().obras[0]) == 2)
        #expect(parcelasDaCompra(um.obras[0].gastos[1], naObra: um.obras[0]) == 1, "conta as que restam, não o parcela.de")
        #expect(parcelasDaCompra(estado().obras[0].gastos[0], naObra: estado().obras[0]) == 1)
    }

    @Test func topicosDaFolha() {
        let topicos = topicosDoFormulario([])
        #expect(topicos.count == 21 && topicos.first?.id == "terreno")
        let comProprio = topicosDoFormulario([TopicoProprio(campos: ["id": .texto("c_x"), "nm": .texto("Automação"), "ic": .texto("etiqueta")])])
        #expect(comProprio.last?.nome == "Automação")
        let obra = estado().obras[0]
        #expect(topicoInicial(obra, topicos: topicos) == "eletrica", "o do último gasto lançado")
        #expect(topicoInicial(estado().obras[1], topicos: topicos) == "terreno", "obra sem gasto começa no primeiro, como o site")
        #expect(usadosNestaObra(obra, topicos: topicos).map(\.id) == ["eletrica", "pintura"])
        var empate = obra
        empate.gastos.append(Gasto(campos: ["id": .texto("z"), "valor": .numero(1), "topico": .texto("pintura"), "data": .texto("2026-06-01")]))
        #expect(usadosNestaObra(empate, topicos: topicos).map(\.id) == ["pintura", "eletrica"], "no empate, o do gasto mais recente")
    }
}
