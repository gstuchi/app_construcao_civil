import Foundation
import CusttaNucleo

/// A conta como o app a vê (o `currentUser` do cloud.js).
struct Usuario: Equatable, Sendable {
    let uid: String
    let email: String
    let emailVerificado: Bool
    /// "password", "google.com", "apple.com".
    let provedores: [String]
    let nomeExibicao: String

    /// Sem provedor (conta antiga) vale o fluxo com senha, como no site.
    var temSenha: Bool { provedores.isEmpty || provedores.contains("password") }
    var contaSocial: Bool { provedores.contains("google.com") || provedores.contains("apple.com") }
    var contaApple: Bool { provedores.contains("apple.com") }
    /// O aviso "Confirme seu e-mail" só vale para conta com senha.
    var precisaConfirmarEmail: Bool { temSenha && !emailVerificado }
}

/// O que o botão "Continuar com a Apple" devolve, já sem tipos da AuthenticationServices.
struct CredencialApple: Sendable {
    let idToken: String
    let nonce: String
    let nomeCompleto: PersonNameComponents?
}

/// Erro de conta com o código no formato do site ("auth/wrong-password", "offline", "pendente").
struct ErroConta: Error, Equatable {
    let codigo: String
}

/// Conta e perfil (Firebase Auth e `perfis/{uid}`). A implementação real é ContaFirebase; os testes usam ContaFalsa.
@MainActor
protocol ServicoConta: AnyObject {
    var usuario: Usuario? { get }
    /// Avisa a cada troca de usuário, inclusive a primeira leitura (conta restaurada ou nenhuma);
    /// quem se inscreve depois dela recebe o estado atual.
    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void)
    func entrar(email: String, senha: String) async throws
    func entrarComApple(_ credencial: CredencialApple) async throws
    func entrarComGoogle() async throws
    /// Cria a conta, grava `perfis/{uid}` e manda o e-mail de confirmação (falha no envio não desfaz a conta).
    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws
    /// Conta Google ou Apple sem `perfis/{uid}`. Falha de rede responde false: travar quem está sem rede é pior.
    func perfilPendente() async -> Bool
    func completarPerfil(_ perfil: PerfilCadastro) async throws
    /// "Nome Sobrenome" de `perfis/{uid}`, ou nil.
    func lerNome() async -> String?
    func redefinirSenha(email: String) async throws
    /// false quando o e-mail já estava confirmado.
    func reenviarVerificacao() async throws -> Bool
    /// Relê a conta no servidor; nunca lança.
    func conferirVerificacao() async -> Bool
    /// Renova o token; sai da conta só se a sessão foi invalidada (nunca por falta de rede).
    func verificarSessao(forcar: Bool) async
    /// Sai da conta e limpa o cache local do banco. Quem chama já esperou a fila e parou a escuta.
    func sair() async throws
}
