#if DEBUG
import Foundation
import CusttaNucleo

/* Conta falsa para os testes (só Debug). A inicial vem de CUSTTA_CONTA:
   nenhuma | senha | senha-nao-confirmada | senha-confirma-ao-conferir (o "Já confirmei" acha o
   e-mail confirmado) | apple-sem-perfil | google-sem-perfil |
   google-perfil-concorrente (outro aparelho grava o perfil no meio do "Falta pouco").
   A falha da limpeza do cache vem de CUSTTA_LIMPEZA: falha (a limpeza do sair e a primeira nova
   tentativa falham; a segunda dá certo) | abertura (abre como se a limpeza retomada na abertura
   tivesse falhado; a primeira nova tentativa também falha e a segunda dá certo). */
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
    /// Saídas que chegaram à conta (os testes conferem que um pedido repetido no meio da saída não sai de novo).
    private(set) var saidas = 0
    /// Demora do `sair`, para os testes pegarem a saída em andamento.
    var demoraAoSair: Duration = .zero
    /// Quantas limpezas do cache ainda falham (a do sair e as novas tentativas).
    var falhasDaLimpeza = 0
    /// Demora de cada nova tentativa de limpar, para o teste de tela ver o "Limpando…".
    var demoraAoLimpar: Duration = .zero
    private var ouvintesDoBloqueio: [@MainActor (Bool) -> Void] = []
    private(set) var bloqueado = false {
        didSet { if bloqueado != oldValue { ouvintesDoBloqueio.forEach { $0(bloqueado) } } }
    }

    init(inicial: String, limpeza: String? = nil) {
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
        switch limpeza {
        case "falha": falhasDaLimpeza = 2
        case "abertura": bloqueado = true; falhasDaLimpeza = 1
        default: break
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
        if bloqueado { throw ErroConta(codigo: "cache") }
        try await Task.sleep(for: .milliseconds(300))
        guard senha == Self.senhaCerta else { throw ErroConta(codigo: "auth/invalid-credential") }
        trocar(Self.comSenha(email: email, verificado: true))
    }

    func entrarComApple(_ credencial: CredencialApple) async throws {
        if bloqueado { throw ErroConta(codigo: "cache") }
        trocar(Usuario(uid: "apple", email: "x@privaterelay.appleid.com", emailVerificado: true, provedores: ["apple.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func entrarComGoogle() async throws {
        if bloqueado { throw ErroConta(codigo: "cache") }
        trocar(Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true, provedores: ["google.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {
        if bloqueado { throw ErroConta(codigo: "cache") }
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

    func sair() async throws {
        saidas += 1
        if demoraAoSair > .zero { try await Task.sleep(for: demoraAoSair) }
        trocar(nil)
        if falhasDaLimpeza > 0 {
            falhasDaLimpeza -= 1
            bloqueado = true
            throw ErroConta(codigo: "cache")
        }
    }

    func observarBloqueio(_ aoMudar: @escaping @MainActor (Bool) -> Void) {
        ouvintesDoBloqueio.append(aoMudar)
        let atual = bloqueado
        Task { @MainActor in aoMudar(atual) }
    }

    func tentarLimparDeNovo() async throws {
        if demoraAoLimpar > .zero { try await Task.sleep(for: demoraAoLimpar) }
        if falhasDaLimpeza > 0 {
            falhasDaLimpeza -= 1
            throw ErroConta(codigo: "cache")
        }
        bloqueado = false
    }
}
#endif
