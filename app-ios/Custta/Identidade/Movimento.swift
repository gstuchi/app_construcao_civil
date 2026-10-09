import SwiftUI
import Combine
import Observation
import QuartzCore

/* O que move o fundo (aurora, globo, logo) e quando ele para. Aurora e globo andam num relógio só, a 30
   quadros por segundo pedidos ao ProMotion, e param com Reduzir movimento, no Modo de Pouca Energia e com
   o aparelho quente (OpcoesDoAparelho.animaFundo), com o app fora de ativo, durante a rolagem (volta
   400 ms depois de parar, como o globe.js), com o teclado aberto e com um alerta por cima (o sobVidro do
   globe.js). O tempo só corre enquanto o fundo anda: pausar e voltar não faz nada pular. O logo, que se
   escreve uma vez em 3 s, tem relógio próprio, na taxa da tela. */

/// Tempo que só corre enquanto a animação roda.
struct TempoPausavel: Equatable, Sendable {
    private(set) var acumulado: TimeInterval = 0
    /// Quando o trecho atual começou; nil com a animação parada.
    private(set) var inicio: Date?

    mutating func rodar(em agora: Date) {
        if inicio == nil { inicio = agora }
    }

    mutating func parar(em agora: Date) {
        guard let inicio else { return }
        acumulado += max(0, agora.timeIntervalSince(inicio))
        self.inicio = nil
    }

    func segundos(em agora: Date) -> TimeInterval {
        acumulado + (inicio.map { max(0, agora.timeIntervalSince($0)) } ?? 0)
    }
}

/// cubic-bezier(x1, y1, x2, y2) do CSS: o progresso da animação no instante x (0…1).
struct CurvaBezier: Equatable, Sendable {
    let x1, y1, x2, y2: Double

    static let suave = CurvaBezier(x1: 0.42, y1: 0, x2: 0.58, y2: 1)        // ease-in-out

    init(x1: Double, y1: Double, x2: Double, y2: Double) {
        self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
    }

    private func ponto(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - t
        return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
    }

    func y(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var baixo = 0.0, alto = 1.0, t = x
        for _ in 0..<40 {                      // bisseção: x(t) só cresce com t
            let atual = ponto(t, x1, x2)
            if abs(atual - x) < 1e-7 { break }
            if atual < x { baixo = t } else { alto = t }
            t = (baixo + alto) / 2
        }
        return ponto(t, y1, y2)
    }
}

/// Relógio da aurora e do globo: um só, para os dois mudarem no mesmo quadro (cada quadro do fundo refaz o
/// vidro da tela inteira). Soma o tempo quadro a quadro com o passo limitado a 1/15 s: depois do segundo
/// plano, de uma travada ou do depurador, o fundo segue de onde estava. Quem desenha lê `segundos` no
/// próprio body, para só ele ser refeito a cada quadro.
@MainActor @Observable
final class RelogioDoFundo {
    /// O maior passo de um quadro para o outro.
    static let passoMaximo: TimeInterval = 1.0 / 15
    private(set) var segundos: TimeInterval = 0
    /// Anda ou para; parado, o relógio não acorda o app.
    var rodando = false {
        didSet {
            guard rodando != oldValue else { return }
            anterior = nil
            if rodando, link == nil { link = Self.criarLink(alvo) }
            link?.isPaused = !rodando
        }
    }
    @ObservationIgnored private var anterior: CFTimeInterval?
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private let alvo = AlvoDoRelogio()

    init() { alvo.relogio = self }

    /// Um quadro: soma o tempo desde o anterior, no máximo `passoMaximo`.
    func avancar(para agora: CFTimeInterval) {
        defer { anterior = agora }
        guard let anterior else { return }
        segundos += min(max(0, agora - anterior), Self.passoMaximo)
    }

    private static func criarLink(_ alvo: AlvoDoRelogio) -> CADisplayLink {
        let link = CADisplayLink(target: alvo, selector: #selector(AlvoDoRelogio.quadro(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        return link
    }
}

/// Alvo do CADisplayLink, que segura o alvo com referência forte: sem o relógio, o link se desliga.
@MainActor
private final class AlvoDoRelogio: NSObject {
    weak var relogio: RelogioDoFundo?

    @objc func quadro(_ link: CADisplayLink) {
        guard let relogio else { link.invalidate(); return }
        relogio.avancar(para: link.timestamp)
    }
}

extension OpcoesDoAparelho {
    /// Aurora e globo andam só com o app ativo e nada segurando o fundo.
    func fundoAnda(ativo: Bool, rolando: Bool, teclado: Bool, coberto: Bool) -> Bool {
        animaFundo && ativo && !rolando && !teclado && !coberto
    }
}

/// O que segura o fundo além das opções do iPhone: a rolagem (pausa já e volta 400 ms depois de parar)
/// e um alerta do sistema por cima.
@MainActor @Observable
final class PausasDoFundo {
    private(set) var rolando = false
    private(set) var cobertas = 0
    @ObservationIgnored private var retomada: Task<Void, Never>?

    func mudou(_ fase: ScrollPhase) {
        retomada?.cancel()
        if fase != .idle {
            rolando = true
            return
        }
        retomada = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.rolando = false
        }
    }

    /// Um alerta aparece (true) ou some (false) por cima do fundo.
    func cobrir(_ coberto: Bool) {
        cobertas = max(0, cobertas + (coberto ? 1 : -1))
    }
}

extension EnvironmentValues {
    @Entry var pausasDoFundo: PausasDoFundo?
}

extension View {
    /// A tela avisa o fundo quando rola (ScrollView ou List).
    func pausaOFundoAoRolar() -> some View { modifier(AvisaRolagem()) }

    /// Segura o fundo enquanto `ativo` (um alerta do sistema por cima).
    func pausaOFundo(enquanto ativo: Bool) -> some View { modifier(SeguraOFundo(ativo: ativo)) }

    /// Pouca Energia e calor do aparelho. Os avisos do sistema chegam numa fila qualquer: passam para a
    /// principal antes de mexer na tela.
    func acompanhaEnergia(poucaEnergia: Binding<Bool>, calor: Binding<Bool>) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange).receive(on: DispatchQueue.main)) { _ in
            poucaEnergia.wrappedValue = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification).receive(on: DispatchQueue.main)) { _ in
            calor.wrappedValue = OpcoesDoAparelho.quente(ProcessInfo.processInfo.thermalState)
        }
    }
}

private struct AvisaRolagem: ViewModifier {
    @Environment(\.pausasDoFundo) private var pausas

    func body(content: Content) -> some View {
        content.onScrollPhaseChange { _, fase in pausas?.mudou(fase) }
    }
}

private struct SeguraOFundo: ViewModifier {
    let ativo: Bool
    @Environment(\.pausasDoFundo) private var pausas

    func body(content: Content) -> some View {
        content
            .onChange(of: ativo) { _, novo in pausas?.cobrir(novo) }
            .onDisappear { if ativo { pausas?.cobrir(false) } }
    }
}

/// Relógio do logo, que se escreve uma vez em 3 s: na taxa da tela, como a animação do CSS, e parado
/// sem pular. Quem usa passa `rodando` já sem `opcoes.reduzirMovimento`, a Pouca Energia, o calor e a rolagem.
struct RelogioDoLogo<Conteudo: View>: View {
    let rodando: Bool
    @ViewBuilder let conteudo: (TimeInterval) -> Conteudo
    @State private var tempo = TempoPausavel()

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !rodando)) { contexto in
            conteudo(tempo.segundos(em: contexto.date))
        }
        .onAppear { if rodando { tempo.rodar(em: .now) } }
        .onDisappear { tempo.parar(em: .now) }
        .onChange(of: rodando) { _, roda in
            if roda { tempo.rodar(em: .now) } else { tempo.parar(em: .now) }
        }
    }
}
