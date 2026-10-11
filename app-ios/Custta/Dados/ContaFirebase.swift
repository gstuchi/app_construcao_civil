import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import CusttaNucleo

/* Conta no Firebase Auth e perfil em `perfis/{uid}`, porte do cloud.js. Os campos e limites do
   perfil são os das firestore.rules (a validação mora no núcleo, cadastro.js portado). Leitura e
   gravação do perfil esperam o banco ficar pronto (limpeza de cache em andamento). */
@MainActor
final class ContaFirebase: ServicoConta {
    private let app: FirebaseApp
    private let banco: BancoFirebase
    private let online: @MainActor () -> Bool
    private var auth: Auth { Auth.auth(app: app) }
    private var alca: AuthStateDidChangeListenerHandle?
    private var ouvintes: [@MainActor (Usuario?) -> Void] = []
    private var ultimaVerificacao: Date?
    private var verificando = false
    /// O Firebase já disse quem está na conta (ou que ninguém está).
    private var estadoConhecido = false
    private(set) var usuario: Usuario?

    init(app: FirebaseApp, banco: BancoFirebase, online: @escaping @MainActor () -> Bool) {
        self.app = app
        self.banco = banco
        self.online = online
        auth.languageCode = "pt-BR"
        alca = auth.addStateDidChangeListener { [weak self] _, user in
            MainActor.assumeIsolated { self?.publicar(user) }
        }
    }

    /// Quem se inscreve depois da primeira leitura do Firebase recebe o estado atual logo em seguida.
    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void) {
        ouvintes.append(aoMudar)
        guard estadoConhecido else { return }
        let atual = usuario
        Task { @MainActor in aoMudar(atual) }
    }

    private func publicar(_ user: User?) {
        if user?.uid != usuario?.uid { ultimaVerificacao = nil }    // a espera de 60 s é por conta (cloud.js)
        estadoConhecido = true
        usuario = user.map(Self.usuario(de:))
        ouvintes.forEach { $0(usuario) }
    }

    static func usuario(de u: User) -> Usuario {
        Usuario(uid: u.uid, email: u.email ?? "", emailVerificado: u.isEmailVerified,
                provedores: u.providerData.map(\.providerID), nomeExibicao: u.displayName ?? "")
    }

    /// Código do site para qualquer erro dos SDKs (Auth, Firestore, Apple, Google, rede).
    nonisolated static func erro(_ e: Error) -> ErroConta {
        if let conta = e as? ErroConta { return conta }
        let n = e as NSError
        if n.domain == dominioFirestore { return ErroConta(codigo: codigoDeErroFirestore(dominio: n.domain, codigo: n.code)) }
        return ErroConta(codigo: codigoDeErroDeConta(dominio: n.domain, codigo: n.code))
    }

    private func exigirRede() throws -> User {
        guard online() else { throw ErroConta(codigo: "offline") }
        guard let u = auth.currentUser else { throw ErroConta(codigo: "cancelled") }
        return u
    }

    /* O User do SDK não é Sendable: os métodos assíncronos dele (reload, sendEmailVerification) o
       mandariam para fora da fila principal. A versão com completion fica aqui e só o resultado viaja. */
    private func esperar(_ chamada: (@escaping @Sendable (Error?) -> Void) -> Void) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            chamada { erro in
                if let erro { c.resume(throwing: erro) } else { c.resume() }
            }
        }
    }

    private static func agoraISO() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    /// `{email, criado, tz, ...perfil}`, como o cloud.js grava.
    private func gravarPerfil(_ u: User, emailDigitado: String?, _ perfil: PerfilCadastro) async throws {
        var dados = perfil.campos.mapValues(\.paraFoundation)
        dados["email"] = u.email ?? emailDigitado ?? ""
        dados["criado"] = Self.agoraISO()
        dados["tz"] = TimeZone.current.identifier
        await banco.aguardarPronto()
        try await banco.firestore().collection("perfis").document(u.uid).setData(dados)
    }

    func entrar(email: String, senha: String) async throws {
        do { _ = try await auth.signIn(withEmail: email, password: senha) } catch { throw Self.erro(error) }
    }

    func entrarComApple(_ credencial: CredencialApple) async throws {
        do {
            let c = OAuthProvider.appleCredential(withIDToken: credencial.idToken, rawNonce: credencial.nonce,
                                                  fullName: credencial.nomeCompleto)
            let r = try await auth.signIn(with: c)
            /* A Apple só manda o nome no primeiro login: guardado no displayName, chega ao
               "Falta pouco" sem a tela pedir de novo. Melhor esforço, como no site. */
            let nome = [credencial.nomeCompleto?.givenName, credencial.nomeCompleto?.familyName]
                .compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if (r.user.displayName ?? "").isEmpty && !nome.isEmpty {
                let pedido = r.user.createProfileChangeRequest()
                pedido.displayName = nome
                try? await pedido.commitChanges()
                publicar(auth.currentUser)
            }
        } catch { throw Self.erro(error) }
    }

    func entrarComGoogle() async throws {
        guard let tela = controladorNoTopo() else { throw ErroConta(codigo: "auth/erro-sem-tela") }
        do {
            let r = try await GIDSignIn.sharedInstance.signIn(withPresenting: tela)
            guard let idToken = r.user.idToken?.tokenString else { throw ErroConta(codigo: "auth/invalid-credential") }
            let c = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: r.user.accessToken.tokenString)
            _ = try await auth.signIn(with: c)
        } catch { throw Self.erro(error) }
    }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {
        do {
            let r = try await auth.createUser(withEmail: email, password: senha)
            try await gravarPerfil(r.user, emailDigitado: email, perfil)
            let novo = r.user
            try? await esperar { novo.sendEmailVerification(completion: $0) }
        } catch { throw Self.erro(error) }
    }

    func perfilPendente() async -> Bool {
        guard let u = auth.currentUser, usuario?.contaSocial == true else { return false }
        await banco.aguardarPronto()
        let ref = banco.firestore().collection("perfis").document(u.uid)
        if let doc = try? await ref.getDocument(source: .cache), doc.exists { return false }
        do { return !(try await ref.getDocument(source: .server)).exists } catch { return false }
    }

    func completarPerfil(_ perfil: PerfilCadastro) async throws {
        let u = try exigirRede()
        do { try await gravarPerfil(u, emailDigitado: nil, perfil) } catch { throw Self.erro(error) }
    }

    func lerNome() async -> String? {
        guard let u = auth.currentUser else { return nil }
        await banco.aguardarPronto()
        guard let dados = try? await banco.firestore().collection("perfis").document(u.uid).getDocument().data() else { return nil }
        let nome = [dados["nome"] as? String, dados["sobrenome"] as? String].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        return nome.isEmpty ? nil : nome
    }

    func redefinirSenha(email: String) async throws {
        do { try await auth.sendPasswordReset(withEmail: email) } catch { throw Self.erro(error) }
    }

    func reenviarVerificacao() async throws -> Bool {
        let u = try exigirRede()
        do {
            try await esperar { u.reload(completion: $0) }
            guard auth.currentUser?.uid == u.uid else { throw ErroConta(codigo: "cancelled") }   // trocou de conta no meio
            if u.isEmailVerified { publicar(auth.currentUser); return false }
            try await esperar { u.sendEmailVerification(completion: $0) }
            return true
        } catch { throw Self.erro(error) }
    }

    func conferirVerificacao() async -> Bool {
        guard let u = try? exigirRede() else { return false }
        do {
            try await esperar { u.reload(completion: $0) }
            guard auth.currentUser?.uid == u.uid, usuario != nil else { return false }            // trocou de conta no meio
            if u.isEmailVerified && usuario?.emailVerificado == false { publicar(auth.currentUser) }
            return u.isEmailVerified
        } catch { return false }
    }

    func verificarSessao(forcar: Bool) async {
        guard let u = auth.currentUser, online(), !verificando else { return }
        if !forcar, let ultima = ultimaVerificacao, Date().timeIntervalSince(ultima) < 60 { return }
        ultimaVerificacao = Date()
        verificando = true
        defer { verificando = false }
        do { _ = try await u.getIDTokenResult(forcingRefresh: true) }
        catch {
            if sessaoInvalida(Self.erro(error).codigo) && auth.currentUser?.uid == u.uid { try? auth.signOut() }
        }
    }

    /// Na ordem do cloud.js: marca a limpeza, sai, esquece o Google e apaga o cache. Se a limpeza
    /// falhar (ou o app fechar no meio), a marca fica e a próxima abertura termina antes de ler.
    func sair() async throws {
        banco.marcarLimpeza()
        do { try auth.signOut() } catch { banco.desmarcarLimpeza(); throw Self.erro(error) }
        GIDSignIn.sharedInstance.signOut()
        try? await banco.limparCache()
    }
}
