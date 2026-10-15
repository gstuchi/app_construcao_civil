import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* O que as telas que gravam usam (etapa 2): o `gravar` do modelo (troca o estado na hora e sobe o documento; recusa
   sem ver os dados; nada sobe quando a obra sumiu), o vaivém das folhas, o rascunho do gasto e para onde o VoiceOver vai
   depois de apagar. */
@MainActor
struct GravacaoDoAppTests {
    func montar(semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> (ModeloApp, TransporteFalsoApp, ContaFalsa) {
        let conta = ContaFalsa(inicial: "senha")
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: MarcaEmMemoria())
        return (ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: semRede)), transporte, conta)
    }

    @Test func gravarTrocaOEstadoNaHoraESobeODocumento() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        let obra = m.sincronizador.estado.obras[0]
        let antes = obra.gastos.count
        let novo = Gasto(campos: ["id": .texto("novo"), "valor": .numero(10), "topico": .texto("outros"), "descricao": .texto(""),
                                  "data": .texto("2026-10-13"), "pagamento": .texto("pix")])
        #expect(m.gravar { $0.lancandoGastos([novo], naObra: obra.id) } == .gravou)
        #expect(m.sincronizador.estado.obras[0].gastos.count == antes + 1, "a tela vê o gasto antes do servidor responder")
        #expect(transporte.gravacoes == 1)
    }

    @Test func buildDoTestFlightSoGravaEmContaDeTeste() {
        #expect(!ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: true), "a conta de sempre não grava no build de teste")
        #expect(ContaDeTeste.podeGravar(email: "Giovani+Custta-Teste@gmail.com", release: true))
        #expect(ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: false), "em Debug grava sempre")
        #expect(!ContaDeTeste.podeGravar(email: nil, release: true))
    }

    @Test func obraQueSumiuNaoGravaNada() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        #expect(m.gravar { $0.apagandoGasto("x", daObra: "nao-existe") } == .sumiu)
        #expect(transporte.gravacoes == 0)
    }

    /// A guarda do TestFlight ligada no `gravar`. Em Debug o `ehRelease` é falso: o teste o liga sem espera no meio (nada
    /// mais roda na thread principal entre ligar e desligar) para provar que o `gravar` pergunta pelo e-mail de quem entrou
    /// antes de mudar o estado.
    @Test func noBuildDoTestFlightOGravarSoPassaNaContaDeTeste() async throws {
        let novo = Gasto(campos: ["id": .texto("novo"), "valor": .numero(10), "topico": .texto("outros"), "descricao": .texto(""),
                                  "data": .texto("2026-10-13"), "pagamento": .texto("pix")])
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        let estado = m.sincronizador.estado
        ContaDeTeste.ehRelease = true
        let naContaDeSempre = m.gravar { $0.lancandoGastos([novo], naObra: $0.obras[0].id) }
        ContaDeTeste.ehRelease = false
        #expect(naContaDeSempre == .contaReal)
        #expect(m.sincronizador.estado == estado && transporte.gravacoes == 0, "nada muda nem sobe")

        let conta = ContaFalsa(inicial: "nenhuma")
        let outro = TransporteFalsoApp(dados: DadosDeExemplo.blob, semRede: false)
        let deTeste = ModeloApp(conta: conta, sincronizador: Sincronizador(transporte: outro, relogio: RelogioDoSistema(), online: true, marca: MarcaEmMemoria()),
                                rede: MonitorDeRede(forcarSemRede: false))
        try await conta.entrar(email: "giovani+custta-teste@gmail.com", senha: ContaFalsa.senhaCerta)
        await ate { deTeste.sincronizador.dadosCarregados && deTeste.usuario != nil }
        ContaDeTeste.ehRelease = true
        let naContaDeTeste = deTeste.gravar { $0.lancandoGastos([novo], naObra: $0.obras[0].id) }
        ContaDeTeste.ehRelease = false
        #expect(naContaDeTeste == .gravou && outro.gravacoes == 1)
    }

    @Test func antesDeVerOsDadosRecusaComOTextoDoSite() async {
        let (m, transporte, _) = montar(semRede: true, dados: nil)
        await ate { m.fase.ehPrincipal }
        let estado = m.sincronizador.estado
        #expect(m.gravar { $0.lancandoGastos([], naObra: $0.obras.first?.id ?? "") ?? $0 } == .naoCarregado)
        #expect(m.sincronizador.estado == estado && transporte.gravacoes == 0)
        #expect(m.mensagemDeNaoCarregado == "Conecte à internet para carregar suas obras antes de lançar.")
    }

    @Test func depoisDeSairNaoGrava() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        m.sincronizador.parar()
        #expect(m.gravar { $0 } == .semConta)
        #expect(transporte.gravacoes == 0)
    }

    @Test func folhasRodamODepoisSoQuandoAFolhaDesce() {
        let folhas = Folhas()
        folhas.aberta = .novoGasto(obraId: "o1")
        var rodou = false
        folhas.fechar { rodou = true }
        #expect(folhas.aberta == nil && !rodou, "o depois espera a folha terminar de descer")
        folhas.fechou()
        #expect(rodou)
        folhas.fechou()
        folhas.destacar(["a"], novo: true)
        let primeiro = folhas.destaque
        folhas.destacar(["a"], novo: true)
        #expect(folhas.destaque != primeiro, "o mesmo gasto acende de novo")
        folhas.apagar(.init(obraId: "o1", gastoId: "g", grupoId: nil))
        #expect(folhas.pedidoDeApagar?.gastoId == "g")
    }

    func obra(_ gastos: [[String: ValorJSON]]) -> Obra {
        Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "gastos": .lista(gastos.map(ValorJSON.objeto))])
    }

    @Test func rascunhoDoGastoNovoComecaComoOMockup() {
        let o = obra([["id": .texto("a"), "valor": .numero(1), "topico": .texto("pintura"), "descricao": .texto("Tinta"),
                       "data": .texto("2026-10-01"), "pagamento": .texto("pix")]])
        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-01-31")
        #expect(r.topico == "pintura", "o tópico do último gasto da obra")
        #expect(r.pagamento == "pix" && r.data == "2026-01-31")
        r.pagamento = "cartao"
        #expect(r.data == "2026-02-28", "o cartão começa um mês à frente, com o fim do mês ajustado")
        r.data = "2026-03-10"
        r.pagamento = "pix"
        #expect(r.data == "2026-01-31", "cada forma de pagamento guarda a sua data")
        #expect(!r.temOQuePerder, "no valor ainda, fechar não pergunta")
        r.passouDoValor = true
        #expect(r.temOQuePerder)
    }

    @Test func rascunhoDaEdicaoPerguntaSoSeMudou() {
        let g: [String: ValorJSON] = ["id": .texto("p1"), "valor": .numero(615), "topico": .texto("revest"), "descricao": .texto("Piso"),
                                      "data": .texto("2026-10-05"), "pagamento": .texto("cartao"), "grupoId": .texto("gr"),
                                      "parcela": .objeto(["n": .numero(4), "de": .numero(10)])]
        let o = obra([g])
        let r = RascunhoDoGasto(obra: o, editado: o.gastos[0], todas: [o], proprios: [], hoje: "2026-10-13")
        #expect(r.centavos == 61_500 && r.parcela == Parcela(n: 4, de: 10) && !r.cartaoNovo)
        #expect(!r.temOQuePerder)
        r.descricao = "Piso novo"
        #expect(r.temOQuePerder)
        r.descricao = "Piso"
        #expect(!r.temOQuePerder, "voltou ao que era")
        r.data = "2026-10-06"
        #expect(r.entrada.data == "2026-10-06", "na edição a data é uma só, qualquer que seja o pagamento")
    }

    @Test func pagamentoDesconhecidoFicaComoVeio() {
        let o = obra([["id": .texto("b"), "valor": .numero(5), "topico": .texto("outros"), "descricao": .texto("Taxa"),
                       "data": .texto("2026-10-01"), "pagamento": .texto("boleto")]])
        let r = RascunhoDoGasto(obra: o, editado: o.gastos[0], todas: [o], proprios: [], hoje: "2026-10-13")
        #expect(r.entrada.pagamento == "boleto", "o site regrava o que estava enquanto nenhuma forma é escolhida")
    }

    @Test func todosOsTopicosSemRepetirOsUsados() {
        let o = obra([["id": .texto("a"), "valor": .numero(1), "topico": .texto("pintura"), "descricao": .texto(""),
                       "data": .texto("2026-10-01"), "pagamento": .texto("pix")]])
        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-10-13")
        #expect(r.usados.map(\.id) == ["pintura"])
        #expect(r.topicosSemOsUsados.count == 20 && !r.topicosSemOsUsados.contains { $0.id == "pintura" })
    }

    @Test func descricaoParaEm500UnidadesSemPartirEmoji() {
        let o = obra([])
        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-10-13")
        r.descricao = String(repeating: "a", count: 499) + "🧱🧱"
        r.limitarDescricao()
        #expect(r.descricao.utf16.count == 499, "o tijolo (2 unidades) não cabe inteiro e sai")
        r.descricao = "  Cimento  "
        #expect(r.entrada.descricao == "Cimento", "a descrição sai aparada, como no site")
    }

    @Test func vizinhoDoVoiceOverDepoisDeApagar() {
        #expect(vizinhoDepoisDeApagar(["b"], ordem: ["a", "b", "c"]) == "c")
        #expect(vizinhoDepoisDeApagar(["c"], ordem: ["a", "b", "c"]) == "b")
        #expect(vizinhoDepoisDeApagar(["b", "c"], ordem: ["a", "b", "c", "d"]) == "d", "a compra toda sai junta")
        #expect(vizinhoDepoisDeApagar(["a"], ordem: ["a"]) == nil, "sem vizinho, vai para Lançamentos")
    }
}
