import Foundation
import Testing
import FirebaseCore
import FirebaseAuth
@testable import Custta

/* Contra os emuladores do Firebase (npm run test:app-ios:emuladores). Fora deles, os testes que
   usam isto pulam. Projeto e portas do firebase.test.json; um FirebaseApp com nome próprio, para
   nunca encostar no de produção. */
let comEmuladores = ProcessInfo.processInfo.environment["CUSTTA_EMULADORES"] == "1"

/// Suíte-mãe das suítes que dividem o `Emulador.banco`: tudo em série, porque `sair()` encerra a
/// instância que a outra suíte estaria usando. Fora dos emuladores, todas pulam.
@MainActor
@Suite(.serialized, .enabled(if: comEmuladores))
struct NoEmulador {}

@MainActor
enum Emulador {
    /// Projeto dos emuladores, o mesmo do firebase.test.json e dos testes do site.
    static let projeto = Composicao.projetoDosEmuladores
    static let app: FirebaseApp = {
        if let app = FirebaseApp.app(name: "emulador") { return app }
        let caminho = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let opcoes = FirebaseOptions(contentsOfFile: caminho)!
        opcoes.projectID = projeto
        FirebaseApp.configure(name: "emulador", options: opcoes)
        let app = FirebaseApp.app(name: "emulador")!
        Auth.auth(app: app).useEmulator(withHost: "127.0.0.1", port: 9099)
        return app
    }()
    static let banco = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080))

    static func novaConta() async throws -> User {
        let email = "teste-\(UUID().uuidString.prefix(8).lowercased())@example.com"
        return try await Auth.auth(app: app).createUser(withEmail: email, password: "Casa2026x").user
    }
}
