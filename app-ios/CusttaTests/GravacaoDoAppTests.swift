import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* O que as telas que gravam usam (etapa 2): o `gravar` do modelo (troca o estado na hora e sobe o documento; recusa
   sem ver os dados; nada sobe quando a obra sumiu). */
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
}
