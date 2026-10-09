import Foundation
import Observation
import Testing
@testable import Custta
import CusttaNucleo

/// Os três jeitos de abrir o app; só o primeiro (sem rede e sem nada no aparelho) não deixa gravar.
struct Abertura: Sendable, CustomTestStringConvertible {
    let nome: String
    let semRede: Bool
    let comDados: Bool
    let carrega: Bool
    var testDescription: String { nome }
}

let aberturas = [
    Abertura(nome: "sem rede e sem dados no aparelho", semRede: true, comDados: false, carrega: false),
    Abertura(nome: "com rede e conta ainda sem documento", semRede: false, comDados: false, carrega: true),
    Abertura(nome: "sem rede e com o blob no cache", semRede: true, comDados: true, carrega: true),
]

/* O modelo das telas com a conta e o transporte falsos: quem decide a tela, a mensagem de sessão
   expirada, o "Falta pouco" e a saída que espera a fila. */
@MainActor
struct ModeloAppTests {
    struct Montagem {
        let modelo: ModeloApp
        let conta: ContaFalsa
        let transporte: TransporteFalsoApp
    }

    func montar(conta inicial: String = "nenhuma", semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> Montagem {
        let conta = ContaFalsa(inicial: inicial)
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
        let modelo = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: semRede))
        return Montagem(modelo: modelo, conta: conta, transporte: transporte)
    }

    @Test func semContaVaiParaAEntrada() async {
        let m = montar().modelo
        await ate { m.fase == .entrada }
        #expect(m.fase == .entrada)
        #expect(m.mensagemEntrada == nil)
    }

    @Test func entrarComSenhaCertaAbreOAppComOsDados() async {
        let m = montar().modelo
        await ate { m.fase == .entrada }
        #expect(await m.entrar(email: " giovani@exemplo.com ", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(m.fase.ehPrincipal)
        #expect(m.sincronizador.estado.obras.count == 4)
        #expect(m.nome == "Giovani Stuchi")
    }

    @Test func mensagensDeEntrarSaoAsDoSite() async {
        let m = montar().modelo
        #expect(await m.entrar(email: "giovani", senha: "x") == "Digite seu e-mail.")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: "") == "Digite a senha.")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: "Errada123") == "E-mail ou senha incorretos.")
        #expect(await m.redefinirSenha(email: "x") == "Digite seu e-mail no campo acima primeiro.")
        #expect(await m.redefinirSenha(email: "giovani@exemplo.com") == "Enviamos um link de redefinição pro seu e-mail.")
    }

    @Test func contaSocialSemPerfilPassaPeloFaltaPouco() async {
        let m = montar(conta: "google-sem-perfil").modelo
        await ate { m.fase.ehFaltaPouco }
        #expect(m.fase.ehFaltaPouco)
        #expect(await m.completarPerfil(PerfilCadastro(nome: "Giovani", origem: "google")) == nil)
        #expect(m.fase.ehPrincipal)
    }

    @Test func perfilGravadoPorOutroAparelhoSegueParaOApp() async {
        let m = montar(conta: "google-perfil-concorrente").modelo
        await ate { m.fase.ehFaltaPouco }
        #expect(await m.completarPerfil(PerfilCadastro(nome: "Giovani", origem: "google")) == nil)
        #expect(m.fase.ehPrincipal)
    }

    @Test func perfilRecusadoSemOutroAparelhoFicaNoFaltaPouco() async {
        let sincronizador = Sincronizador(transporte: TransporteFalsoApp(dados: nil, semRede: false), relogio: RelogioDoSistema())
        let m = ModeloApp(conta: ContaSemPerfilQueRecusa(), sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: true))
        await ate { m.fase.ehFaltaPouco }
        #expect(await m.completarPerfil(PerfilCadastro(nome: "Giovani", origem: "google")) == "Não deu certo salvar. Tente de novo.")
        #expect(m.fase.ehFaltaPouco, "recusado e ainda pendente: não entra no app sem perfil, como no auth.js")
    }

    @Test func sessaoQueCaiExplicaNaEntradaELimpaOsDados() async throws {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        try await montagem.conta.sair()                 // a sessão cai sem a pessoa apertar "Sair"
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == "Sua sessão expirou por segurança. Entre de novo pra continuar.")
        #expect(m.sincronizador.estado == .vazio)
    }

    @Test func sairDePropositoNaoFalaEmSessaoExpirada() async {
        let m = montar(conta: "senha").modelo
        await ate { m.fase.ehPrincipal }
        #expect(await m.sair() == nil)
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == nil)
    }

    @Test func avisoDeSessaoExpiradaSoQuandoASessaoCai() async throws {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal }
        try await montagem.conta.sair()                 // a sessão cai
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == ModeloApp.sessaoExpirada)
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal }
        #expect(await m.sair() == nil)                  // agora de propósito
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == nil, "sair de propósito depois de uma queda não repete o aviso")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal }
        try await montagem.conta.sair()                 // e cai de novo
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == ModeloApp.sessaoExpirada, "a saída de propósito vale uma vez: a queda seguinte é explicada")
    }

    @Test func sairSemRedePedeParaConectarEFicaNoApp() async {
        let m = montar(conta: "senha", semRede: true).modelo
        await ate { m.fase.ehPrincipal }
        #expect(await m.sair() == "Conecte à internet e aguarde a sincronização antes de sair.")
        #expect(m.fase.ehPrincipal)
    }

    @Test func sairEsperaAEdicaoEmVooSubir() async {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        let edicao = Desfecho { try await m.sincronizador.salvar(.vazio) }
        await ate { montagem.transporte.gravacoes == 1 }
        #expect(await m.sair() == nil)
        await ate { edicao.terminou }
        #expect(edicao.terminou && edicao.erro == nil, "a edição em voo sobe antes de sair, como no cloud.js")
        await ate { m.fase == .entrada }
        #expect(m.fase == .entrada)
    }

    @Test(.timeLimit(.minutes(1)), arguments: aberturas)       // espera limitada (Desfecho); o limite de tempo é a última trava
    func abrirOAppNaoGravaNada(_ a: Abertura) async {
        let montagem = montar(conta: "senha", semRede: a.semRede, dados: a.comDados ? DadosDeExemplo.blob : nil)
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal }
        try? await Task.sleep(for: .milliseconds(400))
        #expect(montagem.transporte.gravacoes == 0, "carregar nunca regrava o documento")
        #expect(m.sincronizador.dadosCarregados == a.carrega)
        if !a.carrega {
            let d = Desfecho { try await m.sincronizador.salvar(.vazio) }
            await ate { d.terminou }
            #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"), "sem ver os dados, salvar recusa na hora")
            #expect(montagem.transporte.gravacoes == 0, "sem ver os dados, nem uma edição sobe")
        }
    }

    @Test func confirmarOEmailAvisaATelaQueLeOUsuario() async {
        let m = montar(conta: "senha-confirma-ao-conferir").modelo
        await ate { m.fase.ehPrincipal }
        #expect(m.usuario?.precisaConfirmarEmail == true)
        let mudou = Bandeira()
        withObservationTracking { _ = m.usuario } onChange: { Task { @MainActor in mudou.ligada = true } }
        #expect(await m.conferirVerificacao() == nil)
        await ate { mudou.ligada && m.usuario?.precisaConfirmarEmail == false }
        #expect(mudou.ligada, "a tela que mostra o aviso de e-mail é avisada")
        #expect(m.usuario?.precisaConfirmarEmail == false)
    }

    @Test func sairEEntrarDeNovoVoltaAosDados() async {
        let m = montar(conta: "senha").modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(await m.sair() == nil)
        await ate { m.fase == .entrada }
        #expect(m.sincronizador.estado == .vazio)
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(m.sincronizador.estado.obras.count == 4, "a escuta volta para a conta que entrou")
    }

    @Test func avisoDoSincronizadorApareceNaTela() async {
        let m = montar(conta: "senha").modelo
        await ate { m.sincronizador.dadosCarregados }
        let grande = Estado.de(.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1)]),
                                        "notas": .texto(String(repeating: "a", count: 900_000))]))
        _ = try? await m.sincronizador.salvar(grande)
        #expect(m.aviso == "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.")
    }

    /// Como o cloud.js: a rede que volta confere a sessão sem forçar; a gravação recusada com
    /// "unauthenticated" força a conferência.
    @Test func sessaoSoEForcadaQuandoAGravacaoERecusada() async {
        let conta = ContaFalsa(inicial: "senha")
        let sincronizador = Sincronizador(transporte: TransporteQueRecusa(codigo: "unauthenticated"), relogio: RelogioDoSistema())
        // sem o monitor do sistema: o teste diz quando a rede cai e volta
        let m = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: true))
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        m.rede.aoMudar?(false)
        m.rede.aoMudar?(true)
        await ate { !conta.verificacoesDeSessao.isEmpty }
        #expect(conta.verificacoesDeSessao == [false], "rede que volta confere a sessão sem forçar, como o cloud.js")
        let d = Desfecho { try await m.sincronizador.salvar(.vazio) }
        await ate { d.terminou && conta.verificacoesDeSessao.count == 2 }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "unauthenticated"))
        #expect(conta.verificacoesDeSessao == [false, true], "gravação recusada pela sessão força a conferência, como o cloud.js")
    }
}

/// Transporte que responde do servidor (conta ainda sem documento) e recusa toda gravação com o
/// código dado; o TransporteFalsoApp sempre confirma.
@MainActor
final class TransporteQueRecusa: TransporteDados {
    private final class Nada: Cancelavel { func cancelar() {} }
    private let codigo: String

    init(codigo: String) { self.codigo = codigo }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        Task { @MainActor in aoReceber(Instantaneo(dados: nil, doCache: false, gravacaoPendente: false)) }
        return Nada()
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        let codigo = self.codigo
        Task { @MainActor in concluir(codigo) }
    }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) { concluir(nil) }
}

/// Conta Google sem perfil cujo perfil as rules recusam (permission-denied) sem outro aparelho ter
/// gravado: o perfil continua pendente. A ContaFalsa grava o perfil antes de recusar.
@MainActor
final class ContaSemPerfilQueRecusa: ServicoConta {
    let usuario: Usuario? = Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true,
                                    provedores: ["google.com"], nomeExibicao: "Giovani Stuchi")

    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void) {
        let atual = usuario
        Task { @MainActor in aoMudar(atual) }
    }
    func entrar(email: String, senha: String) async throws {}
    func entrarComApple(_ credencial: CredencialApple) async throws {}
    func entrarComGoogle() async throws {}
    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {}
    func perfilPendente() async -> Bool { true }
    func completarPerfil(_ perfil: PerfilCadastro) async throws { throw ErroConta(codigo: "permission-denied") }
    func lerNome() async -> String? { nil }
    func redefinirSenha(email: String) async throws {}
    func reenviarVerificacao() async throws -> Bool { true }
    func conferirVerificacao() async -> Bool { false }
    func verificarSessao(forcar: Bool) async {}
    func sair() async throws {}
}
