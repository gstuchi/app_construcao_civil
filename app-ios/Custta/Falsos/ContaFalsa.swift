#if DEBUG
import Foundation
import CusttaNucleo

/* Conta falsa para os testes (só Debug). A inicial vem de CUSTTA_CONTA:
   nenhuma | senha | senha-nao-confirmada | senha-confirma-ao-conferir (o "Já confirmei" acha o
   e-mail confirmado) | apple-sem-perfil | google-sem-perfil |
   google-perfil-concorrente (outro aparelho grava o perfil no meio do "Falta pouco"). */
@MainActor
final class ContaFalsa: ServicoConta {
    static let senhaCerta = "Casa2026x"
    private(set) var usuario: Usuario?
    private var ouvintes: [@MainActor (Usuario?) -> Void] = []
    private var temPerfil: Bool
    private let perfilConcorrente: Bool
    private let confirmaAoConferir: Bool
    /// O `forcar` de cada conferência de sessão pedida, em ordem (os testes conferem o que chega do Sincronizador).
    private(set) var verificacoesDeSessao: [Bool] = []
    /// Erro do envio de confirmação de e-mail, para os testes dos textos (nil: o envio vai).
    var erroAoEnviarConfirmacao: ErroConta?

    init(inicial: String) {
        perfilConcorrente = inicial == "google-perfil-concorrente"
        confirmaAoConferir = inicial == "senha-confirma-ao-conferir"
        temPerfil = !inicial.hasSuffix("sem-perfil") && !perfilConcorrente
        switch inicial {
        case "senha": usuario = Self.comSenha(email: "giovani@exemplo.com", verificado: true)
        case "senha-nao-confirmada", "senha-confirma-ao-conferir":
            usuario = Self.comSenha(email: "giovani@exemplo.com", verificado: false)
        case "apple-sem-perfil": usuario = Usuario(uid: "apple", email: "x@privaterelay.appleid.com", emailVerificado: true,
                                                   provedores: ["apple.com"], nomeExibicao: "Giovani Stuchi")
        case "google-sem-perfil", "google-perfil-concorrente":
            usuario = Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true, provedores: ["google.com"], nomeExibicao: "Giovani Stuchi")
        default: usuario = nil
        }
    }

    static func comSenha(email: String, verificado: Bool) -> Usuario {
        Usuario(uid: "teste", email: email, emailVerificado: verificado, provedores: ["password"], nomeExibicao: "")
    }

    private func trocar(_ u: Usuario?) {
        usuario = u
        ouvintes.forEach { $0(u) }
    }

    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void) {
        ouvintes.append(aoMudar)
        let atual = usuario
        Task { @MainActor in aoMudar(atual) }      // o Firebase também avisa a conta restaurada logo depois
    }

    func entrar(email: String, senha: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
        guard senha == Self.senhaCerta else { throw ErroConta(codigo: "auth/invalid-credential") }
        trocar(Self.comSenha(email: email, verificado: true))
    }

    func entrarComApple(_ credencial: CredencialApple) async throws {
        trocar(Usuario(uid: "apple", email: "x@privaterelay.appleid.com", emailVerificado: true, provedores: ["apple.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func entrarComGoogle() async throws {
        trocar(Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true, provedores: ["google.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {
        try await Task.sleep(for: .milliseconds(300))
        if email == "ja@existe.com" { throw ErroConta(codigo: "auth/email-already-in-use") }
        temPerfil = true
        trocar(Self.comSenha(email: email, verificado: false))
    }

    func perfilPendente() async -> Bool { usuario?.contaSocial == true && !temPerfil }

    func completarPerfil(_ perfil: PerfilCadastro) async throws {
        temPerfil = true
        if perfilConcorrente { throw ErroConta(codigo: "permission-denied") }    // as rules recusam o segundo perfil
    }

    func lerNome() async -> String? { usuario == nil ? nil : "Giovani Stuchi" }

    func redefinirSenha(email: String) async throws {
        if email == "ninguem@exemplo.com" { throw ErroConta(codigo: "auth/user-not-found") }
    }

    func reenviarVerificacao() async throws -> Bool {
        if let erroAoEnviarConfirmacao { throw erroAoEnviarConfirmacao }
        return true
    }

    func conferirVerificacao() async -> Bool {
        guard confirmaAoConferir, let u = usuario else { return false }
        if !u.emailVerificado { trocar(Self.comSenha(email: u.email, verificado: true)) }
        return true
    }

    func verificarSessao(forcar: Bool) async { verificacoesDeSessao.append(forcar) }

    func sair() async throws { trocar(nil) }
}
#endif
