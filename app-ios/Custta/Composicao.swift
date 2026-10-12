import Foundation
import FirebaseCore
import FirebaseAuth
import CusttaNucleo

/* Monta o app com os serviços de verdade (Firebase de produção) ou, só em Debug, com os
   emuladores locais (CUSTTA_EMULADORES=1) ou com serviços falsos (CUSTTA_SERVICOS=falsos)
   para os testes de tela. O build Release (TestFlight) não tem os dois atalhos. */
@MainActor
enum Composicao {
    /// Projeto dos emuladores, o mesmo do firebase.test.json e dos testes do site.
    static let projetoDosEmuladores = "demo-custta-phase2"

    static func montar(ambiente: [String: String] = ProcessInfo.processInfo.environment) -> ModeloApp {
        #if DEBUG
        if ambiente["CUSTTA_SERVICOS"] == "falsos" { return montarFalso(ambiente) }
        #endif
        let emuladores = usaEmuladores(ambiente)
        let app = configurarFirebase(emuladores: emuladores)
        let banco = BancoFirebase(app: app, emulador: emuladores ? ("127.0.0.1", 8080) : nil)
        if emuladores { Auth.auth(app: app).useEmulator(withHost: "127.0.0.1", port: 9099) }
        #if DEBUG
        // Teste de tela que precisa começar na tela de entrar (a conta fica no keychain do simulador).
        if ambiente["CUSTTA_SAIR_AO_ABRIR"] == "1" { try? Auth.auth(app: app).signOut() }
        #endif
        let rede = MonitorDeRede()
        let conta = ContaFirebase(app: app, banco: banco, online: { rede.online })
        let sincronizador = Sincronizador(transporte: TransporteFirebase(banco: banco), relogio: RelogioDoSistema(), online: rede.online)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }

    /// CUSTTA_EMULADORES=1, só em Debug: o Release (TestFlight) nunca fala com os emuladores. É função, e não
    /// constante, para o Release não acusar o ramo dos emuladores como código que nunca roda.
    private static func usaEmuladores(_ ambiente: [String: String]) -> Bool {
        #if DEBUG
        ambiente["CUSTTA_EMULADORES"] == "1"
        #else
        false
        #endif
    }

    /// Firebase de produção pelo GoogleService-Info.plist; nos emuladores, o mesmo arquivo com o projeto de teste.
    static func configurarFirebase(emuladores: Bool) -> FirebaseApp {
        if let app = FirebaseApp.app() { return app }
        guard emuladores else {
            FirebaseApp.configure()
            return FirebaseApp.app()!
        }
        FirebaseApp.configure(options: opcoesDosEmuladores())
        return FirebaseApp.app()!
    }

    /// Chave falsa dos emuladores. O emulador do Auth aceita qualquer chave e a produção recusa esta: um pedido que
    /// escape dos emuladores (um useEmulator esquecido) falha em vez de criar conta na produção. Tem o formato das
    /// chaves do Google (39 caracteres, "A" na frente, só base64url), senão o FirebaseInstallations derruba o
    /// configure quando o FCM entrar.
    static let chaveDosEmuladores = "AIzaSyEmuladoresDoCusttaSemProducao0000"

    /// As opções do GoogleService-Info.plist com o projeto e a chave dos emuladores (o app e os testes contra eles).
    static func opcoesDosEmuladores() -> FirebaseOptions {
        let caminho = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let opcoes = FirebaseOptions(contentsOfFile: caminho)!
        opcoes.projectID = projetoDosEmuladores
        opcoes.apiKey = chaveDosEmuladores
        return opcoes
    }
}
