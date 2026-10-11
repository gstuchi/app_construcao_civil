import Foundation
import Testing
import FirebaseCore
import FirebaseFirestore
@testable import Custta

/* A limpeza do cache interrompida (o app fechou no meio de um "sair") termina na abertura seguinte,
   antes de qualquer leitura. Sem rede e sem emulador: apagar o cache é local (roda na CI). */

@MainActor
struct BancoFirebaseTests {
    @Test func limpezaInterrompidaTerminaAntesDaPrimeiraLeitura() async throws {
        let nome = "limpeza-\(UUID().uuidString.prefix(8).lowercased())"
        let caminho = try #require(Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"))
        let opcoes = try #require(FirebaseOptions(contentsOfFile: caminho))
        opcoes.projectID = Emulador.projeto
        FirebaseApp.configure(name: nome, options: opcoes)
        let preferencias = try #require(UserDefaults(suiteName: nome))
        preferencias.set(true, forKey: BancoFirebase.chaveLimpeza)
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)

        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        #expect(!usou.ligada, "ninguém lê antes de a limpeza terminar")
        await banco.aguardarPronto()
        #expect(usou.ligada)
        #expect(!banco.limpezaPendente, "a abertura terminou a limpeza e tirou a marca")
    }
}
