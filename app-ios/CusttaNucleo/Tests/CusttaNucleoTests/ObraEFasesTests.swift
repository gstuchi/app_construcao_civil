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

    @Test func editarAVendidaEApagarPeloId() throws {
        let antes = estado()
        let e = try #require(antes.editandoObra("o3", CamposDaObra(nome: "Vendida 2", dataInicio: "", valorEstimadoVenda: 850_000, areaM2: 90)))
        var esperada = antes.obras[2].arvore
        esperada["nome"] = .texto("Vendida 2"); esperada["valorEstimadoVenda"] = .numero(850_000); esperada["areaM2"] = .numero(90)
        #expect(e.obras[2].arvore == esperada, "a vendida editada guarda a fase, a venda inteira e o resto")
        #expect(Array(e.obras.prefix(2)) == Array(antes.obras.prefix(2)), "as outras obras não mudam")
        let semAPrimeira = try #require(antes.apagandoObra("o1"))
        let semAUltima = try #require(antes.apagandoObra("o3"))
        #expect(semAPrimeira.obras.map(\.id) == ["o2", "o3"] && semAUltima.obras.map(\.id) == ["o1", "o2"], "apaga a obra do id, não a da posição")
    }

    @Test func apagarObra() throws {
        let e = try #require(estado().apagandoObra("o2"))
        #expect(e.obras.map(\.id) == ["o1", "o3"])
        #expect(estado().apagandoObra("sumiu") == nil)
    }

    @Test func faseSoEntreConstrucaoEPronta() throws {
        let pronta = try #require(estado().mudandoFase("o1", para: .pronta))
        #expect(pronta.obras[0].fase == .pronta && pronta.obras[0].campos["campoDoSite"] == .numero(7))
        #expect(try #require(pronta.mudandoFase("o1", para: .construcao)).obras[0].fase == .construcao)
        #expect(estado().mudandoFase("o1", para: .vendida) == nil, "vender é pela folha da venda")
        #expect(estado().mudandoFase("o3", para: .pronta) == nil, "da vendida só se sai desfazendo a venda")
        #expect(estado().mudandoFase("sumiu", para: .pronta) == nil)
    }

    @Test func registrarVendaSoDaPronta() throws {
        let e = try #require(estado().registrandoVenda("o2", valor: 1_380_000, data: "2026-10-12"))
        #expect(e.obras[1].fase == .vendida)
        #expect(e.obras[1].campos["venda"] == .objeto(["valor": .numero(1_380_000), "data": .texto("2026-10-12")]), "venda {valor, data}, como o site")
        #expect(estado().registrandoVenda("o1", valor: 1, data: "2026-10-12") == nil, "a construção não se vende (a tela não oferece)")
        #expect(estado().registrandoVenda("o3", valor: 1, data: "2026-10-12") == nil, "outro aparelho já vendeu")
        #expect(estado().registrandoVenda("sumiu", valor: 1, data: "2026-10-12") == nil)
    }

    @Test func desfazerVendaApagaAChave() throws {
        let e = try #require(estado().desfazendoVenda("o3"))
        #expect(e.obras[2].fase == .pronta)
        #expect(e.obras[2].campos["venda"] == nil && gravada(e, 2)?["venda"] == nil, "o delete do site: a chave sai, não vira null")
        #expect(estado().desfazendoVenda("o2") == nil, "só a vendida")
        #expect(estado().desfazendoVenda("sumiu") == nil)
    }
}

struct TextosDaObraTests {
    @Test func acoesDaFaseComOsTextosDoSite() {
        #expect(acoesDaFase(.construcao) == [.marcarPronta])
        #expect(acoesDaFase(.pronta) == [.registrarVenda, .voltarConstrucao])
        #expect(acoesDaFase(.vendida) == [.desfazerVenda])
        #expect(AcaoDaFase.allCases.map(\.rotulo) == ["Marcar como pronta", "Registrar venda", "Voltar pra construção", "Desfazer venda"])
        #expect(AcaoDaFase.allCases.map(\.icone) == ["casa", "acordo", "voltar", "voltar"])
        #expect(AcaoDaFase.allCases.map(\.principal) == [true, true, false, false], "o próximo passo sólido; voltar em vidro")
    }

    @Test func perguntasDeApagarObraEDesfazerVenda() {
        let pergunta = textoDeApagarObra(nome: "Casa Alphaville", lancamentos: 46)
        #expect(pergunta.titulo == "Apagar “Casa Alphaville”?")
        #expect(pergunta.mensagem == "Os 46 lançamentos dela serão perdidos. Não dá para desfazer.")
        #expect(textoDeApagarObra(nome: "X", lancamentos: 1).mensagem == "1 lançamento dela será perdido. Não dá para desfazer.")
        #expect(textoDeApagarObra(nome: "X", lancamentos: 0).mensagem == "Não dá para desfazer.", "sem gasto, o site não fala em lançamentos")
        #expect(textoDeDesfazerVenda.titulo == "Desfazer a venda?")
        #expect(textoDeDesfazerVenda.mensagem == "A obra volta pra “Pronta”.")
        #expect(textoDeDesfazerVenda.botao == "Desfazer venda")
    }

    @Test func notasDasFolhasEListaVazia() {
        #expect(notaDaDataDaVenda(dataInicio: "2024-11-01") == "Entre o início da obra (01/11/24) e hoje. A correção pelo banco para nessa data.")
        #expect(notaDaObraVendida("Casa Alphaville") == "Casa Alphaville está vendida; o gasto vai para uma obra aberta.")
        #expect(listaDeObrasVazia.titulo == "Nenhuma obra ainda.")
        #expect(listaDeObrasVazia.texto == "Toque no + para criar a primeira obra.", "o \"pra\" do site vira \"para\" nas telas vazias")
    }

    @Test func alertaDeNaoSalvouComOTextoDoSite() {
        let comum = alertaDeNaoSalvou(codigo: "permission-denied")
        #expect(comum.titulo == "Não salvou na nuvem")
        #expect(comum.mensagem == "Confira sua conexão e conta; toque no aviso para tentar novamente.")
        let limite = alertaDeNaoSalvou(codigo: "limite")
        #expect(limite.titulo == "Não salvou: limite de dados atingido")
        for codigo in ["permission-denied", "unauthenticated", "limite"] {
            let a = alertaDeNaoSalvou(codigo: codigo)
            #expect("\(a.titulo). \(a.mensagem)" == AvisoSinc.naoSalvou(codigo: codigo, terminal: true).mensagem, "o texto do site, em título e mensagem")
        }
    }

    @Test func areaNoCampoSemOErroDoSite() {
        // O site mostra a área crua ("3.125") e o parseNum lê o ponto como milhar (3125); com a vírgula, volta igual.
        for area in [3.125, 280, 1234.5, 0.75, 12_345.678] { #expect(lerNumero(areaParaCampo(area)) == area, "\(area)") }
        #expect(areaParaCampo(3.125) == "3,125" && areaParaCampo(280) == "280" && areaParaCampo(nil) == "")
    }

    @Test func obrasAbertasNaOrdemDaLista() {
        let e = Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("a"), "nome": .texto("A"), "dataInicio": .texto("2025-01-01"), "fase": .texto("construcao")]),
            .objeto(["id": .texto("b"), "nome": .texto("B"), "dataInicio": .texto("2026-03-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-04-01")])]),
            .objeto(["id": .texto("c"), "nome": .texto("C"), "dataInicio": .texto("2026-02-01"), "fase": .texto("pronta")]),
        ])]))
        #expect(obrasAbertas(e.obras).map(\.id) == ["c", "a"], "sem as vendidas, a que começou mais recente primeiro")
    }
}
