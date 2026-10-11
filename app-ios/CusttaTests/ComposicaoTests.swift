import Foundation
import Testing
import FirebaseCore
@testable import Custta

/* A composição: com CUSTTA_SERVICOS=falsos (os testes de tela) nada encosta no Firebase. Sem a variável,
   o Debug monta o Firebase de produção (ou os emuladores, com CUSTTA_EMULADORES=1). */
@MainActor
struct ComposicaoTests {
    @Test func falsosSoComAVariavel() {
        let modelo = Composicao.montar(ambiente: ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": "senha"])
        #expect(modelo.conta is ContaFalsa)
        #expect(FirebaseApp.app() == nil, "nem os falsos nem o app que hospeda os testes ligam o Firebase")
        #expect(Composicao.projetoDosEmuladores == "demo-custta-phase2", "o mesmo projeto do firebase.test.json")
    }

    /// Nos emuladores, a chave é falsa: um pedido que escape deles (um useEmulator esquecido) é recusado pela
    /// produção em vez de criar conta lá. No formato das chaves do Google (39 caracteres, "A" na frente, só
    /// base64url), senão o FirebaseInstallations derruba o configure quando o FCM entrar.
    @Test func emuladoresComProjetoEChaveDeTeste() throws {
        let opcoes = Composicao.opcoesDosEmuladores()
        #expect(opcoes.projectID == Composicao.projetoDosEmuladores)
        let plist = try #require(Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"))
        let producao = try #require(FirebaseOptions(contentsOfFile: plist))
        #expect(opcoes.apiKey != producao.apiKey, "nunca a chave da produção nos emuladores")
        let chave = try #require(opcoes.apiKey)
        #expect(chave.count == 39 && chave.hasPrefix("A"))
        #expect(chave.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
    }
}
