import Testing
@testable import Custta

/* A composição: com CUSTTA_SERVICOS=falsos (os testes de tela) nada encosta no Firebase. Sem a variável,
   o Debug monta o Firebase de produção (ou os emuladores, com CUSTTA_EMULADORES=1). */
@MainActor
struct ComposicaoTests {
    @Test func falsosSoComAVariavel() {
        let modelo = Composicao.montar(ambiente: ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": "senha"])
        #expect(modelo.conta is ContaFalsa)
        #expect(Composicao.projetoDosEmuladores == "demo-custta-phase2", "o mesmo projeto do firebase.test.json")
    }
}
