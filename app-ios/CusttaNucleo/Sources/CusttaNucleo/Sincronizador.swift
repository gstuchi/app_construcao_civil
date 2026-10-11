import Foundation
import Observation

/* A sincronização do documento `dados/{uid}`, porte da fila de escrita do cloud.js e do eco do
   app.js. Não conhece o Firebase: fala com um TransporteDados (o do app é fino, sobre o SDK) e
   mede o tempo com um Relogio, os dois falsos nos testes.

   Regras que vêm do site:
   - grava o documento inteiro; cada versão vai na hora para o transporte (a fila persistente do
     SDK guarda a ordem, inclusive sem rede); a última gravação vale;
   - a confirmação só conta para a versão mais recente;
   - erro terminal para e espera ação; transitório tenta de novo com proximoBackoff;
   - acima de 900.000 bytes não grava; entre 700.000 e 900.000 avisa uma vez;
   - snapshot que chega com gravação local pendente não troca o estado; os outros passam pela
     normalização e só trocam o estado se o conteúdo mudou.

   Como o site, nunca grava antes de ver os dados: até chegar um snapshot do servidor, ou do
   cache com o documento, `salvar` recusa com "nao-carregado". Uma regra a mais que o site: volta
   a recusar se chegar um documento que não deu para ler inteiro ("formato-desconhecido"). Sem
   isso, uma edição regravaria o documento inteiro por cima do que o app não viu. */

public enum OrigemErro: String, Sendable {
    case escrita, leitura
}

public enum EstadoSinc: Equatable, Sendable {
    case ocioso, salvando, repetindo, offline
    case erro(codigo: String, origem: OrigemErro)

    var ehErro: Bool { if case .erro = self { return true }; return false }
}

/// O que o snapshot do documento traz.
public struct Instantaneo: Sendable {
    /// nil: o documento não existe.
    public let dados: ValorJSON?
    public let doCache: Bool
    public let gravacaoPendente: Bool
    public init(dados: ValorJSON?, doCache: Bool, gravacaoPendente: Bool) {
        self.dados = dados; self.doCache = doCache; self.gravacaoPendente = gravacaoPendente
    }
}

@MainActor public protocol Cancelavel: AnyObject {
    func cancelar()
}

/// O banco visto pelo Sincronizador. Todo retorno chega na fila principal.
@MainActor public protocol TransporteDados: AnyObject {
    /// Escuta `dados/{uid}` com as mudanças de metadados (cache, gravação pendente). `aoFalhar` recebe o
    /// código do erro: do Firestore ("permission-denied"), que encerra a escuta, ou "formato-desconhecido"
    /// (documento com tipo que o JSON não tem), que não encerra: o próximo snapshot bom volta a valer.
    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel
    /// Grava o documento inteiro com `_atualizado` do servidor. `concluir(nil)` quando o servidor confirma;
    /// `concluir(codigo)` no erro. Sem rede, só conclui quando a rede volta.
    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void)
    /// Conclui quando tudo o que o SDK guardou subiu (inclusive gravações de antes desta sessão).
    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void)
}

@MainActor public protocol Relogio: AnyObject {
    var agoraMs: Int64 { get }
    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel
}

public struct ErroSinc: Error, Equatable, Sendable {
    public let codigo: String
    public init(codigo: String) { self.codigo = codigo }
}

/// Aviso para a tela, com o texto do site.
public enum AvisoSinc: Equatable, Sendable {
    case pertoDoLimite
    case naoSalvou(codigo: String, terminal: Bool)
    case naoLeu(codigo: String)

    public var mensagem: String {
        switch self {
        case .pertoDoLimite: return "Seus dados estão próximos do limite de armazenamento."
        case .naoSalvou("limite", _): return "Não salvou: limite de dados atingido. Reduza os dados e tente novamente."
        case .naoSalvou(_, true): return "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente."
        case .naoSalvou(_, false): return "Sem salvar na nuvem agora — vamos tentar de novo sozinhos."
        case .naoLeu(let codigo): return "Não consegui ler seus dados da nuvem agora (\(codigo))."
        }
    }

    /// Erro terminal e aviso de tamanho aparecem sempre; os outros, no máximo um a cada 30 s.
    var raro: Bool {
        switch self {
        case .pertoDoLimite, .naoSalvou(_, true): return false
        case .naoSalvou(_, false), .naoLeu: return true
        }
    }
}

/// O indicador de sincronização da tela; nil quando está tudo em dia (fica invisível).
public struct IndicadorSinc: Equatable, Sendable {
    public let rotulo: String
    public let girando: Bool
    public let erro: Bool
    public let dica: String
}

public func indicador(_ e: EstadoSinc) -> IndicadorSinc? {
    switch e {
    case .ocioso: return nil
    case .salvando, .repetindo: return IndicadorSinc(rotulo: "Salvando…", girando: true, erro: false, dica: "Salvando…")
    case .offline: return IndicadorSinc(rotulo: "Sem conexão", girando: false, erro: false, dica: "Sem conexão")
    case .erro(_, let origem):
        return IndicadorSinc(rotulo: origem == .leitura ? "Não sincronizou" : "Não salvou", girando: false, erro: true,
                             dica: "Não foi possível sincronizar. Toque para tentar de novo.")
    }
}

@MainActor @Observable
public final class Sincronizador {
    public private(set) var estadoSinc: EstadoSinc
    public private(set) var estado: Estado = .vazio
    /// Já chegou um snapshot em que dá para confiar: do servidor, ou do cache com o documento.
    /// Cache sem documento (app recém-instalado, sem rede) não conta: o servidor pode ter obras.
    /// Volta a falso se chegar um documento que o app não conseguiu ler inteiro.
    public private(set) var dadosCarregados = false

    @ObservationIgnored public var aoAvisar: ((AvisoSinc) -> Void)?
    /// Pede para conferir a sessão, como o `verificarSessao` do cloud.js: o erro "unauthenticated" ao
    /// gravar força (true); a rede que voltou não força (false), e quem confere pula a conferência não
    /// forçada se a última foi há menos de 60 s.
    @ObservationIgnored public var aoPedirVerificacaoDeSessao: ((_ forcar: Bool) -> Void)?

    @ObservationIgnored private let transporte: TransporteDados
    @ObservationIgnored private let relogio: Relogio
    @ObservationIgnored private var uid: String?
    @ObservationIgnored private var online: Bool
    @ObservationIgnored private var pendente: ValorJSON?
    @ObservationIgnored private var sujo = false
    @ObservationIgnored private var tentativa = 0
    @ObservationIgnored private var emVoo = false
    @ObservationIgnored private var versaoEscrita = 0
    @ObservationIgnored private var esperas: [(String?) -> Void] = []
    @ObservationIgnored private var repeticao: (any Cancelavel)?
    @ObservationIgnored private var avisouTamanho = false
    @ObservationIgnored private var escuta: (any Cancelavel)?
    @ObservationIgnored private var revisaoLeitura = 0
    @ObservationIgnored private var erroLeitura: String?
    @ObservationIgnored private var pendenciaCache = false
    @ObservationIgnored private var ultimoAvisoRaro: Int64?

    public init(transporte: TransporteDados, relogio: Relogio, online: Bool = true) {
        self.transporte = transporte
        self.relogio = relogio
        self.online = online
        self.estadoSinc = online ? .ocioso : .offline
    }

    public var temPendencia: Bool { pendente != nil || emVoo || pendenciaCache }

    /* ---------- conta ---------- */

    /// Começa a escutar a conta. Troca de conta zera tudo antes.
    public func iniciar(uid novo: String) {
        parar()
        uid = novo
        abrirEscuta(novo)
    }

    /// Sai da conta: para a escuta, descarta a fila desta sessão (a do SDK fica com ele) e rejeita
    /// quem esperava confirmação com "cancelled".
    public func parar() {
        escuta?.cancelar(); escuta = nil
        revisaoLeitura += 1
        versaoEscrita += 1
        repeticao?.cancelar(); repeticao = nil
        pendente = nil; sujo = false; emVoo = false; tentativa = 0; pendenciaCache = false; erroLeitura = nil
        terminarEsperas("cancelled")
        uid = nil
        estado = .vazio
        dadosCarregados = false
        publicar(online ? .ocioso : .offline)
    }

    /* ---------- escrita ---------- */

    /// Troca o estado na hora e grava o documento inteiro. Volta quando o servidor confirma esta
    /// versão (ou uma mais nova); lança ErroSinc no erro terminal, se a conta saiu ("cancelled") ou
    /// se ainda não deu para ver os dados desta conta ("nao-carregado").
    public func salvar(_ novo: Estado) async throws {
        guard uid != nil else {
            avisar(.naoSalvou(codigo: "cancelled", terminal: true))
            throw ErroSinc(codigo: "cancelled")
        }
        guard dadosCarregados else { throw ErroSinc(codigo: "nao-carregado") }
        estado = novo
        let blob = novo.arvore
        let tamanho = tamanhoBlob(blob)
        if tamanho >= avisoBlob && tamanho <= limiteBlob && !avisouTamanho { avisouTamanho = true; avisar(.pertoDoLimite) }
        if tamanho < avisoBlob { avisouTamanho = false }
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            esperas.append { codigo in
                if let codigo { c.resume(throwing: ErroSinc(codigo: codigo)) } else { c.resume() }
            }
            pendente = blob
            sujo = true
            if estadoSinc.ehErro { tentativa = 0 }
            repeticao?.cancelar(); repeticao = nil
            publicar(online ? .salvando : .offline)
            enviar()
        }
    }

    /// Toque no indicador de erro: reabre a leitura que falhou e reenvia o que está pendente.
    public func tentarDeNovo() {
        if erroLeitura != nil, let uid { abrirEscuta(uid) }
        guard pendente != nil || emVoo else { return }
        tentativa = 0
        repeticao?.cancelar(); repeticao = nil
        enviar()
    }

    /// Espera subir o que esta sessão gravou e o que o SDK guardou de antes; false se não subiu
    /// em `timeoutMs` ou se deu erro. Sair da conta só segue com true.
    public func aguardarFila(timeoutMs: Int = 5000) async -> Bool {
        await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            let espera = EsperaUnica(c)
            espera.tempo = relogio.agendar(depois: timeoutMs) { espera.terminar(false) }
            if pendente != nil || emVoo {
                espera.faltam += 1
                esperas.append { codigo in codigo == nil ? espera.cumpriu() : espera.terminar(false) }
                tentarDeNovo()
            }
            espera.faltam += 1
            transporte.aguardarGravacoesPendentes { codigo in codigo == nil ? espera.cumpriu() : espera.terminar(false) }
        }
    }

    /// Rede voltou (tenta já o que estava pendente) ou caiu (indicador "Sem conexão").
    public func redeMudou(online agora: Bool) {
        online = agora
        if agora {
            aoPedirVerificacaoDeSessao?(false)
            if estadoSinc.ehErro { return }
            if pendente != nil { tentativa = 0; agendarRepeticao(0) }
            else { publicar(emVoo || pendenciaCache ? .salvando : .ocioso) }
        } else if !estadoSinc.ehErro {
            publicar(.offline)
        }
    }

    private func enviar() {
        guard let blob = pendente, let uid else { return }
        pendente = nil
        emVoo = true
        versaoEscrita += 1
        let versao = versaoEscrita
        publicar(!online ? .offline : tentativa > 0 ? .repetindo : .salvando)
        guard blobCabe(blob) else { falhou(versao: versao, blob: blob, codigo: "limite"); return }
        transporte.gravar(uid: uid, blob: blob) { [weak self] codigo in
            guard let self else { return }
            if let codigo { self.falhou(versao: versao, blob: blob, codigo: codigo) } else { self.confirmou(versao: versao) }
        }
    }

    private func confirmou(versao: Int) {
        guard versao == versaoEscrita else { return }
        emVoo = false
        tentativa = 0
        if pendente != nil { enviar(); return }
        sujo = false
        publicar(.ocioso)
        terminarEsperas(nil)
    }

    private func falhou(versao: Int, blob: ValorJSON, codigo: String) {
        guard versao == versaoEscrita else { return }
        emVoo = false
        if pendente == nil { pendente = blob }
        let terminal = codigo == "limite" || erroEhTerminal(codigo: codigo)
        if codigo == "unauthenticated" { aoPedirVerificacaoDeSessao?(true) }
        avisar(.naoSalvou(codigo: codigo, terminal: terminal))
        if terminal {
            tentativa = 0
            publicar(.erro(codigo: codigo, origem: .escrita))
            terminarEsperas(codigo)
            return
        }
        let ms = proximoBackoff(Double(tentativa))
        tentativa += 1
        publicar(online ? .repetindo : .offline)
        agendarRepeticao(ms)
    }

    private func agendarRepeticao(_ ms: Int) {
        repeticao?.cancelar()
        repeticao = relogio.agendar(depois: ms) { [weak self] in
            self?.repeticao = nil
            self?.enviar()
        }
    }

    private func terminarEsperas(_ codigo: String?) {
        let todas = esperas
        esperas = []
        todas.forEach { $0(codigo) }
    }

    /* ---------- leitura ---------- */

    private func abrirEscuta(_ uid: String) {
        escuta?.cancelar()
        revisaoLeitura += 1
        let revisao = revisaoLeitura
        escuta = transporte.escutar(uid: uid, aoReceber: { [weak self] instantaneo in
            guard let self, revisao == self.revisaoLeitura, self.uid == uid else { return }
            self.recebeu(instantaneo)
        }, aoFalhar: { [weak self] codigo in
            guard let self, revisao == self.revisaoLeitura, self.uid == uid else { return }
            self.erroLeitura = codigo
            if codigo == "formato-desconhecido" { self.dadosCarregados = false }   // quem não leu o documento inteiro não grava
            self.publicar(.erro(codigo: codigo, origem: .leitura))
            self.avisar(.naoLeu(codigo: codigo))
        })
    }

    private func recebeu(_ i: Instantaneo) {
        if !i.doCache {
            let recuperou = erroLeitura != nil
            erroLeitura = nil
            if recuperou && !sujo { publicar(online ? .ocioso : .offline) }
        }
        pendenciaCache = i.gravacaoPendente
        if !sujo && !estadoSinc.ehErro { publicar(!online ? .offline : pendenciaCache ? .salvando : .ocioso) }
        guard !sujo else { return }          // edição desta sessão ainda não confirmada vence o eco
        let novo = normaliza(i.dados)
        if !mesmoConteudo(novo, estado.arvore) { estado = Estado(normalizado: novo) }
        if !i.doCache || i.dados != nil { dadosCarregados = true }
    }

    /* ---------- estado e avisos ---------- */

    private func publicar(_ novo: EstadoSinc) {
        if !novo.ehErro, let erroLeitura { estadoSinc = .erro(codigo: erroLeitura, origem: .leitura); return }
        estadoSinc = novo
    }

    private func avisar(_ aviso: AvisoSinc) {
        if aviso.raro {
            let agora = relogio.agoraMs
            if let ultimo = ultimoAvisoRaro, agora - ultimo < 30_000 { return }
            ultimoAvisoRaro = agora
        }
        aoAvisar?(aviso)
    }
}

/// Junta várias esperas num resultado só: true quando todas cumprem, false no primeiro erro ou no tempo.
@MainActor private final class EsperaUnica {
    private let continuacao: CheckedContinuation<Bool, Never>
    private var terminou = false
    var faltam = 0
    var tempo: (any Cancelavel)?

    init(_ c: CheckedContinuation<Bool, Never>) { continuacao = c }

    func cumpriu() {
        faltam -= 1
        if faltam == 0 { terminar(true) }
    }

    func terminar(_ ok: Bool) {
        guard !terminou else { return }
        terminou = true
        tempo?.cancelar()
        continuacao.resume(returning: ok)
    }
}
