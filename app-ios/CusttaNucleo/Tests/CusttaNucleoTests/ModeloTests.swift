import Testing
@testable import CusttaNucleo

/// Argumentos dos vetores → tipos do núcleo (os testes das tarefas seguintes usam).
extension ValorJSON {
    var obra: Obra { Obra(arvore: comoObjeto ?? [:]) }
    var obras: [Obra] { (comoLista ?? []).map(\.obra) }
    var gastos: [Gasto] { (comoLista ?? []).compactMap { $0.comoObjeto.map(Gasto.init(campos:)) } }
}

struct ModeloTests {
    @Test func estadoLeEEscreveSemPerderNada() {
        for c in Vetores.casos("dados.normaliza") {
            let normalizado = normaliza(c.args[0])
            #expect(canonico(Estado(normalizado: normalizado).arvore) == canonico(normalizado), "\(c.caso)")
        }
    }

    @Test func gravarCampoConhecidoMantemODesconhecido() {
        var estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Obra"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .texto("fica"),
            "venda": .objeto(["valor": .numero(10), "data": .texto("2026-02-01"), "obs": .texto("fica")]),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1), "data": .texto("2026-01-02"),
                                       "grupoId": .texto("gr"), "parcela": .objeto(["n": .numero(1), "de": .numero(2), "x": .booleano(true)]),
                                       "anexo": .texto("fica")])])])])]))
        estado.obras[0].nome = "Obra nova"
        estado.obras[0].venda = Venda(valor: 20, data: "2026-03-01")
        estado.obras[0].gastos[0].valor = 2
        estado.obras[0].gastos[0].parcela = Parcela(n: 2, de: 2)
        estado.config.taxaMensal = 1.5
        let obra = estado.arvore.comoObjeto!["obras"]!.comoLista![0].comoObjeto!
        #expect(obra["campoDoSite"] == .texto("fica"))
        #expect(obra["nome"] == .texto("Obra nova"))
        #expect(obra["venda"] == .objeto(["valor": .numero(20), "data": .texto("2026-03-01"), "obs": .texto("fica")]))
        let gasto = obra["gastos"]!.comoLista![0].comoObjeto!
        #expect(gasto["anexo"] == .texto("fica"))
        #expect(gasto["parcela"] == .objeto(["n": .numero(2), "de": .numero(2), "x": .booleano(true)]))
        #expect(estado.arvore.comoObjeto!["config"]!.comoObjeto!["taxaMensal"] == .numero(1.5))
    }

    @Test func vendaNulaGravaNull() {
        var obra = Estado.de(.objeto(["obras": .lista([.objeto(["id": .texto("o"), "dataInicio": .texto("2026-01-01")])])])).obras[0]
        obra.venda = nil
        #expect(obra.arvore["venda"] == .nulo)
        #expect(obra.fase == .construcao)
    }

    @Test func estadoVazioEOBlobVazioDoSite() {
        #expect(canonico(Estado.vazio.arvore) == #"{"config":{"taxaMensal":1,"topicosCustom":[]},"obras":[]}"#)
    }

    @Test func topicosPadraoIguaisAoSite() {
        let esperado = Vetores.casos("calc.TOPICOS")[0].saida.comoLista!.map { t -> Topico in
            let o = t.comoObjeto!
            return Topico(id: o["id"]!.comoTexto!, nome: o["nm"]!.comoTexto!, icone: o["ic"]!.comoTexto!)
        }
        #expect(topicosPadrao == esperado)
    }

    @Test func mapaDeTopicosPoeOProprioPorCima() {
        let mapa = mapaDeTopicos([TopicoProprio(campos: ["id": .texto("c_x"), "nm": .texto("Automação"), "ic": .texto("etiqueta")]),
                                  TopicoProprio(campos: ["id": .texto("pintura"), "nm": .texto("Pintura fina"), "ic": .texto("rolo")])])
        #expect(mapa["c_x"]?.nome == "Automação")
        #expect(mapa["pintura"]?.nome == "Pintura fina")
        #expect(mapa["terreno"]?.nome == "Terreno")
    }

    @Test func grupoIdVazioContaComoSemGrupo() {
        #expect(Gasto(campos: ["grupoId": .texto("")]).grupoId == nil)
        #expect(Gasto(campos: ["grupoId": .texto("gr1")]).grupoId == "gr1")
        #expect(Gasto(campos: [:]).grupoId == nil)
    }
}
