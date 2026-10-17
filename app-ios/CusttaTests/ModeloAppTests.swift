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
    /// O servidor já respondeu a esta conta numa abertura anterior (a marca do Sincronizador).
    var servidorJaRespondeu = false
    let carrega: Bool
    var testDescription: String { nome }
}

let aberturas = [
    Abertura(nome: "sem rede e sem dados no aparelho", semRede: true, comDados: false, carrega: false),
    Abertura(nome: "com rede e conta ainda sem documento", semRede: false, comDados: false, carrega: true),
    Abertura(nome: "sem rede e com o blob no cache", semRede: true, comDados: true, carrega: true),
    Abertura(nome: "sem rede, conta vazia que o servidor já respondeu", semRede: true, comDados: false, servidorJaRespondeu: true, carrega: true),
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

    func montar(conta inicial: String = "nenhuma", semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob,
                servidorJaRespondeu: Bool = false) -> Montagem {
        let conta = ContaFalsa(inicial: inicial)
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
        let marca = MarcaEmMemoria()
        marca.marcarTodas = servidorJaRespondeu
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: marca)
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

    @Test func segundoPedidoDeSairNoMeioDaSaidaERecusado() async {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal }
        montagem.conta.demoraAoSair = .milliseconds(300)
        let primeiro = Desfecho { if await m.sair() != nil { throw ErroConta(codigo: "nao-saiu") } }
        await ate { m.saindo }
        #expect(m.saindo, "\"Usar outra conta\" fica desabilitado enquanto sai")
        #expect(await m.sair() == nil, "o pedido repetido (toque duplo) é recusado sem mensagem, como no auth.js")
        await ate { primeiro.terminou }
        #expect(primeiro.terminou && primeiro.erro == nil, "a primeira saída termina")
        #expect(montagem.conta.saidas == 1, "uma saída só: duas limpezas juntas, a primeira soltaria a fila no meio da outra")
        #expect(!m.saindo)
        await ate { m.fase == .entrada }
        #expect(m.fase == .entrada)
    }

    @Test func limpezaQueFalhaAoSairAbreOFinalizarSaida() async {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        montagem.conta.falhasDaLimpeza = 1
        #expect(await m.sair() == nil, "saiu da conta: a falha da limpeza não é erro de sair")
        await ate { m.fase == .entrada && m.limpeza != nil }
        #expect(m.fase == .entrada && m.mensagemEntrada == nil, "saiu de propósito: nada de sessão expirada")
        #expect(m.limpeza == .pendente(erro: false))
        #expect(m.sincronizador.estado == .vazio, "a escuta não volta para a conta que saiu")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == "Não deu certo. Tente de novo.",
                "bloqueado, entrar recusa (a mensagem do site para o código cache)")
        #expect(await m.entrarComGoogle() == "Limpe os dados locais antes de entrar.", "a do auth.js para o login social")
        m.tentarLimparDeNovo()
        #expect(m.limpeza == .tentando, "o alerta fecha na hora")
        await ate { m.limpeza == nil }
        #expect(m.limpeza == nil, "deu certo: sem aviso")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
    }

    @Test func novaTentativaQueFalhaVoltaComOErro() async {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal }
        montagem.conta.falhasDaLimpeza = 2
        #expect(await m.sair() == nil)
        await ate { m.limpeza != nil }
        m.tentarLimparDeNovo()
        await ate { m.limpeza == .pendente(erro: true) }
        #expect(m.limpeza == .pendente(erro: true), "falhou de novo: o alerta volta com o erro")
        m.tentarLimparDeNovo()
        await ate { m.limpeza == nil }
        #expect(m.limpeza == nil)
    }

    @Test func limpezaQueFalhouNaAberturaAbreOFinalizarSaida() async {
        let conta = ContaFalsa(inicial: "nenhuma", limpeza: "abertura")
        let transporte = TransporteFalsoApp(dados: nil, semRede: false)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: true)
        let m = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: false))
        await ate { m.limpeza != nil }
        #expect(m.limpeza == .pendente(erro: false), "a limpeza retomada na abertura falhou: abre pedindo para finalizar")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) != nil, "e entrar recusa")
        m.tentarLimparDeNovo()
        await ate { m.limpeza == .pendente(erro: true) }
        m.tentarLimparDeNovo()
        await ate { m.limpeza == nil }
        #expect(m.limpeza == nil)
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
    }

    @Test(.timeLimit(.minutes(1)), arguments: aberturas)       // espera limitada (Desfecho); o limite de tempo é a última trava
    func abrirOAppNaoGravaNada(_ a: Abertura) async {
        let montagem = montar(conta: "senha", semRede: a.semRede, dados: a.comDados ? DadosDeExemplo.blob : nil,
                              servidorJaRespondeu: a.servidorJaRespondeu)
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

    @Test func mensagemDeNaoCarregadoComoOSite() async {
        #expect(montar().modelo.mensagemDeNaoCarregado == "Carregando suas obras, tente em instantes.")
        #expect(montar(semRede: true).modelo.mensagemDeNaoCarregado == "Conecte à internet para carregar suas obras antes de lançar.")
    }

    /// Documento num formato que o app não lê: gravar fica recusado, e "carregando" seria para sempre.
    @Test func mensagemDeNaoCarregadoComDocumentoQueOAppNaoLe() async {
        let s = Sincronizador(transporte: TransporteFalsoApp(dados: nil, semRede: false, falhaDeLeitura: "formato-desconhecido"),
                              relogio: RelogioDoSistema())
        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: s, rede: MonitorDeRede(forcarSemRede: false))
        await ate { if case .erro = m.sincronizador.estadoSinc { return true }; return false }
        #expect(m.mensagemDeNaoCarregado == textoErroDeLeitura("formato-desconhecido"))
    }

    /// Outro erro de leitura antes de carregar: a escuta encerrada só reabre pelo "Tentar de novo", então o alerta diz o
    /// mesmo que a lista de obras, com e sem rede (conectar sozinho não carrega).
    @Test(arguments: [false, true])
    func mensagemDeNaoCarregadoComLeituraQueFalhou(semRede: Bool) async {
        let s = Sincronizador(transporte: TransporteFalsoApp(dados: nil, semRede: semRede, falhaDeLeitura: "permission-denied"),
                              relogio: RelogioDoSistema(), online: !semRede)
        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: s, rede: MonitorDeRede(forcarSemRede: semRede))
        await ate { if case .erro = m.sincronizador.estadoSinc { return true }; return false }
        #expect(!m.sincronizador.dadosCarregados)
        #expect(m.mensagemDeNaoCarregado == textoErroDeLeitura("permission-denied"))
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

    /// Ajustes › "Enviar confirmação de e-mail" com os textos dos Ajustes do site, e não os do aviso de e-mail.
    @Test func enviarConfirmacaoComOsTextosDosAjustesDoSite() async {
        let m = montar(conta: "senha-nao-confirmada")
        #expect(await m.modelo.enviarConfirmacao() == "E-mail enviado. Confira também a caixa de spam.")
        m.conta.erroAoEnviarConfirmacao = ErroConta(codigo: "offline")
        #expect(await m.modelo.enviarConfirmacao() == "Conecte à internet para enviar.")
        m.conta.erroAoEnviarConfirmacao = ErroConta(codigo: "auth/too-many-requests")
        #expect(await m.modelo.enviarConfirmacao() == "Não foi possível enviar agora. Aguarde e tente novamente.")
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

    /// O erro que não passa sozinho (aqui, o limite de dados) vira o alerta com o texto do site, e não o aviso do topo.
    @Test func erroQueNaoPassaSozinhoViraOAlerta() async {
        let m = montar(conta: "senha").modelo
        await ate { m.sincronizador.dadosCarregados }
        let grande = Estado.de(.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1)]),
                                        "notas": .texto(String(repeating: "a", count: 900_000))]))
        _ = try? await m.sincronizador.salvar(grande)
        #expect(m.alertaDeGravacao == AlertaDeGravacao(titulo: "Não salvou: limite de dados atingido", mensagem: "Reduza os dados e tente novamente."))
        #expect(m.aviso == nil)
    }

    /// Um alerta por erro (etapa 2, parte 3): tentar de novo e falhar de novo fica só na pílula; depois de uma gravação
    /// confirmada, o erro seguinte é outro e alerta de novo.
    @Test func naoSalvouAlertaUmaVezPorErro() async {
        let transporte = TransporteNaMao()
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema())
        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: false))
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
        transporte.responder("permission-denied")
        #expect(m.alertaDeGravacao?.titulo == "Não salvou na nuvem")
        #expect(m.alertaDeGravacao?.mensagem == "Confira sua conexão e conta; toque no aviso para tentar novamente.")
        m.fecharAlertaDeGravacao()
        m.tentarDeNovo()
        transporte.responder("permission-denied")
        #expect(m.alertaDeGravacao == nil, "o mesmo erro: só a pílula")
        #expect(m.aviso == "Tentando de novo…")
        m.tentarDeNovo()
        transporte.responder(nil)
        #expect(m.sincronizador.estadoSinc == .ocioso)
        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
        transporte.responder("permission-denied")
        #expect(m.alertaDeGravacao != nil, "depois de salvar, o erro seguinte é outro")
    }

    /// O erro que passa sozinho (a rede caiu no meio da gravação) não vira o alerta: fica o aviso do topo, como no site, e a
    /// fila tenta de novo sozinha.
    @Test func erroQuePassaSozinhoFicaNoAvisoDoTopo() async {
        let transporte = TransporteNaMao()
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema())
        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: false))
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
        transporte.responder("unavailable")
        #expect(m.alertaDeGravacao == nil, "erro de rede não é o \"Não salvou\" que pede ação")
        #expect(m.aviso == "Sem salvar na nuvem agora — vamos tentar de novo sozinhos.")
    }

    /// A sessão que cai com o "Não salvou" aberto leva o alerta junto, e quem entra de novo começa do zero: o primeiro erro
    /// da sessão nova alerta, mesmo sem gravação confirmada no meio.
    @Test func sessaoQueCaiEsqueceONaoSalvou() async throws {
        let transporte = TransporteNaMao()
        let conta = ContaFalsa(inicial: "senha")
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema())
        let m = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: false))
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
        transporte.responder("permission-denied")
        #expect(m.alertaDeGravacao != nil)
        try await conta.sair()                          // a sessão cai com o alerta aberto
        await ate { m.fase == .entrada }
        #expect(m.alertaDeGravacao == nil, "o alerta da sessão que caiu não fica para a próxima")
        try await conta.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta)
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
        transporte.responder("permission-denied")
        #expect(m.alertaDeGravacao != nil, "o primeiro erro da sessão nova alerta")
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

/// Transporte em que o teste responde cada gravação na hora que quiser (`responder`), com o documento já visto.
@MainActor
final class TransporteNaMao: TransporteDados {
    private final class Nada: Cancelavel { func cancelar() {} }
    private var esperando: [(String?) -> Void] = []

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        Task { @MainActor in aoReceber(Instantaneo(dados: nil, doCache: false, gravacaoPendente: false)) }
        return Nada()
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) { esperando.append(concluir) }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) { concluir(nil) }

    /// Responde a gravação mais antiga que ainda espera.
    func responder(_ codigo: String?) {
        guard !esperando.isEmpty else { return }
        esperando.removeFirst()(codigo)
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
    func observarBloqueio(_ aoMudar: @escaping @MainActor (Bool) -> Void) {}
    func tentarLimparDeNovo() async throws {}
}
