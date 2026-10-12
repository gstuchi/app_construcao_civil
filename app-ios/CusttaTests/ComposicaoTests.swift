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

    /// Nos emuladores, um FirebaseApp com nome próprio: a sessão dele fica numa vaga do keychain só dela, e o app
    /// padrão, só para a produção. Sem rede: configurar não fala com ninguém (nada de Auth nem Firestore aqui).
    @Test func emuladoresNumAppProprio() {
        let app = Composicao.configurarFirebase(emuladores: true)
        #expect(app.name == Composicao.nomeDoAppDosEmuladores)
        #expect(app.name != Emulador.nome, "nem o app dos testes de unidade contra os emuladores")
        #expect(app.options.projectID == Composicao.projetoDosEmuladores && app.options.apiKey == Composicao.chaveDosEmuladores)
        #expect(Composicao.configurarFirebase(emuladores: true) === app, "reabrir devolve o mesmo app (configurar de novo derruba)")
        #expect(FirebaseApp.app() == nil, "o app padrão fica só para a produção")
    }
}
