import Foundation
import Observation
import CusttaNucleo

/* O estado das telas: qual tela aparece (entrada, falta pouco, app), a conta, a sincronização e
   os avisos. Porte do que auth.js e o boot do app.js fazem com a conta. */
@MainActor @Observable
final class ModeloApp {
    enum Fase: Equatable {
        case carregando
        case entrada
        case faltaPouco(Usuario)
        case principal(Usuario)
    }

    /// Textos que a tela de entrar mostra com ícone próprio (cadeado e ✓), os mesmos do site.
    static let sessaoExpirada = "Sua sessão expirou por segurança. Entre de novo pra continuar."
    static let linkEnviado = "Enviamos um link de redefinição pro seu e-mail."
    static let linkReenviado = "Link reenviado. Confira também a caixa de spam."
    static let confirmacaoEnviada = "E-mail enviado. Confira também a caixa de spam."
    static let emailJaConfirmado = "E-mail já confirmado."

    private(set) var fase: Fase = .carregando
    /// Texto da tela de entrada: sessão expirada.
    var mensagemEntrada: String?
    /// Aviso curto no topo (o toast do site).
    private(set) var aviso: String?
    /// "Nome Sobrenome" de `perfis/{uid}`, para Ajustes.
    private(set) var nome: String?
    let sincronizador: Sincronizador
    let rede: MonitorDeRede

    @ObservationIgnored let conta: ServicoConta
    @ObservationIgnored private var uidAtivo: String?
    @ObservationIgnored private var jaEntrou = false
    @ObservationIgnored private var saindoDeProposito = false
    @ObservationIgnored private var checagem = 0
    @ObservationIgnored private var tarefaDoAviso: Task<Void, Never>?

    init(conta: ServicoConta, sincronizador: Sincronizador, rede: MonitorDeRede) {
        self.conta = conta
        self.sincronizador = sincronizador
        self.rede = rede
        sincronizador.aoAvisar = { [weak self] aviso in self?.avisar(aviso.mensagem) }
        sincronizador.aoPedirVerificacaoDeSessao = { [weak self] forcar in
            Task { await self?.conta.verificarSessao(forcar: forcar) }
        }
        rede.aoMudar = { [weak sincronizador] online in sincronizador?.redeMudou(online: online) }
        conta.observar { [weak self] usuario in
            Task { await self?.usuarioMudou(usuario) }
        }
    }

    /// A conta da tela atual. Vem da `fase`, que é observável: a tela que lê `usuario` é avisada quando
    /// ele muda (o e-mail confirmado tira o aviso sem precisar reabrir o app).
    var usuario: Usuario? {
        switch fase {
        case .faltaPouco(let u), .principal(let u): return u
        case .carregando, .entrada: return nil
        }
    }

    /* ---------- conta ---------- */

    func usuarioMudou(_ u: Usuario?) async {
        checagem += 1
        let minha = checagem
        guard let u else {
            let expirou = jaEntrou && !saindoDeProposito
            jaEntrou = false
            saindoDeProposito = false
            uidAtivo = nil
            sincronizador.parar()
            nome = nil
            if expirou { mensagemEntrada = Self.sessaoExpirada }
            fase = .entrada
            return
        }
        jaEntrou = true
        mensagemEntrada = nil
        if uidAtivo != u.uid {
            uidAtivo = u.uid
            sincronizador.iniciar(uid: u.uid)
        }
        if u.contaSocial, await conta.perfilPendente() {
            if minha == checagem { fase = .faltaPouco(u) }
            return
        }
        guard minha == checagem else { return }
        fase = .principal(u)
        nome = await conta.lerNome()
    }

    /// Mensagem de erro para a tela de entrar, ou nil se entrou.
    func entrar(email: String, senha: String) async -> String? {
        if let erro = validarEntrada(email: email, senha: senha) { return erro }
        do { try await conta.entrar(email: aparadoJS(email), senha: senha); return nil }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "login") }
    }

    func entrarComApple(_ credencial: CredencialApple) async -> String? {
        do { try await conta.entrarComApple(credencial); return nil }
        catch { return mensagemOuNil(mensagemErroSocial(codigo: (error as? ErroConta)?.codigo, provedor: "apple.com")) }
    }

    func entrarComGoogle() async -> String? {
        do { try await conta.entrarComGoogle(); return nil }
        catch { return mensagemOuNil(mensagemErroSocial(codigo: (error as? ErroConta)?.codigo, provedor: "google.com")) }
    }

    private func mensagemOuNil(_ s: String) -> String? { s.isEmpty ? nil : s }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async -> String? {
        do { try await conta.criarConta(email: aparadoJS(email), senha: senha, perfil: perfil); return nil }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "cadastro") }
    }

    /// "Esqueci minha senha", com o e-mail digitado no próprio cartão de entrar, como no site:
    /// o texto de sucesso ou de erro.
    func redefinirSenha(email: String) async -> String {
        let e = aparadoJS(email)
        guard emailParece(e) else { return "Digite seu e-mail no campo acima primeiro." }
        do { try await conta.redefinirSenha(email: e); return Self.linkEnviado }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "redefinir") }
    }

    /// "Falta pouco": grava o perfil e segue para o app. Outro aparelho pode ter gravado antes
    /// (as rules recusam o segundo): se o perfil já existe, não há nada pendente.
    func completarPerfil(_ perfil: PerfilCadastro) async -> String? {
        do {
            try await conta.completarPerfil(perfil)
        } catch let erro as ErroConta {
            if erro.codigo == "permission-denied", !(await conta.perfilPendente()) { await seguirParaOApp(); return nil }
            return erro.codigo == "offline" ? "Conecte à internet para continuar." : "Não deu certo salvar. Tente de novo."
        } catch { return "Não deu certo salvar. Tente de novo." }
        await seguirParaOApp()
        return nil
    }

    private func seguirParaOApp() async {
        guard let u = conta.usuario else { return }
        fase = .principal(u)
        nome = await conta.lerNome()
    }

    /// "Sair da conta" e "Usar outra conta", na ordem do cloud.js: espera a fila subir (sem rede, pede
    /// para conectar), confere que a conta é a mesma, para a escuta e só então sai.
    /// Mensagem de erro, ou nil se saiu.
    func sair() async -> String? {
        let semRede = "Conecte à internet e aguarde a sincronização antes de sair."
        guard rede.online, let uid = conta.usuario?.uid else { return semRede }
        guard await sincronizador.aguardarFila(timeoutMs: 5000) else { return semRede }
        guard conta.usuario?.uid == uid else { return "Não foi possível sair com segurança. Tente novamente." }
        saindoDeProposito = true
        sincronizador.parar()
        do { try await conta.sair(); return nil }
        catch {
            saindoDeProposito = false
            sincronizador.iniciar(uid: uid)          // não saiu: volta a escutar a conta
            return "Não foi possível sair com segurança. Tente novamente."
        }
    }

    /// Texto do aviso de e-mail depois de "Reenviar link".
    func reenviarVerificacao() async -> String {
        do {
            return try await conta.reenviarVerificacao() ? Self.linkReenviado : Self.emailJaConfirmado
        } catch let erro as ErroConta {
            switch erro.codigo {
            case "offline": return "Conecte à internet para reenviar."
            case "auth/too-many-requests": return "Muitos envios seguidos. Aguarde alguns minutos."
            default: return "Não foi possível reenviar agora. Tente novamente."
            }
        } catch { return "Não foi possível reenviar agora. Tente novamente." }
    }

    /// Texto de Ajustes depois de "Enviar confirmação de e-mail": os dos Ajustes do site (#ajVerificar), que não
    /// são os do aviso de e-mail.
    func enviarConfirmacao() async -> String {
        do {
            return try await conta.reenviarVerificacao() ? Self.confirmacaoEnviada : Self.emailJaConfirmado
        } catch let erro as ErroConta where erro.codigo == "offline" {
            return "Conecte à internet para enviar."
        } catch { return "Não foi possível enviar agora. Aguarde e tente novamente." }
    }

    /// Texto do aviso de e-mail depois de "Já confirmei"; nil quando confirmou (o aviso some).
    func conferirVerificacao() async -> String? {
        if await conta.conferirVerificacao() { return nil }
        return rede.online ? "Ainda não recebemos a confirmação. Toque no link do e-mail e tente de novo."
                           : "Conecte à internet para conferir."
    }

    /// O app voltou para a frente: confere a sessão e, se faltar, a confirmação do e-mail.
    func voltouParaFrente() async {
        await conta.verificarSessao(forcar: false)
        if conta.usuario?.precisaConfirmarEmail == true { _ = await conta.conferirVerificacao() }
    }

    /* ---------- sincronização e avisos ---------- */

    func tentarDeNovo() {
        avisar("Tentando de novo…")
        sincronizador.tentarDeNovo()
    }

    func avisar(_ texto: String) {
        aviso = texto
        tarefaDoAviso?.cancel()
        tarefaDoAviso = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.aviso = nil
        }
    }
}
