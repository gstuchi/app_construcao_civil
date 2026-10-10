import SwiftUI

/// Escolhe a tela pela fase da conta, desenha o fundo (aurora e globo, no mesmo relógio) e aplica a
/// aparência deste aparelho, a dose de vidro da tela e as opções do iPhone.
struct RaizView: View {
    @Environment(ModeloApp.self) private var modelo
    @AppStorage(Aparencia.chaveTema) private var tema = "escuro"
    @AppStorage(Aparencia.chavePele) private var pele = "esmeralda"
    @AppStorage(Aparencia.chaveVidro) private var escolhaDeVidro = "transparente"
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @Environment(\.accessibilityReduceTransparency) private var reduzirTransparencia
    @Environment(\.colorSchemeContrast) private var contraste
    @Environment(\.scenePhase) private var fase
    @State private var poucaEnergia = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var calor = OpcoesDoAparelho.quente(ProcessInfo.processInfo.thermalState)
    @State private var teclado = false
    @State private var pausas = PausasDoFundo()
    @State private var relogio = RelogioDoFundo()
    #if DEBUG
    // Os testes de tela não mudam os ajustes do sistema: ligam cada opção por argumento.
    @AppStorage("custta.reduzirMovimento") private var forcarReduzirMovimento = false
    @AppStorage("custta.reduzirTransparencia") private var forcarReduzirTransparencia = false
    @AppStorage("custta.aumentarContraste") private var forcarAumentarContraste = false
    /// Quadro da deriva (s) em que a aurora fica parada nos testes de contraste; negativo = não força.
    @AppStorage("custta.quadroDaAurora") private var quadroDaAurora = -1.0
    /// Laudo de leitura (Tarefa 11): ângulo fixo do globo (negativo = não força), aurora no pior caso da
    /// deriva e o texto apagado ("tudo" ou "navegacao").
    @AppStorage("custta.anguloDoGlobo") private var anguloDoGlobo = -1.0
    @AppStorage("custta.auroraPiorCaso") private var auroraPiorCaso = false
    @AppStorage("custta.textoApagado") private var textoApagado = ""
    #endif

    var body: some View {
        let paleta = Paleta(pele: Aparencia.pele(pele))
        let escuro = Aparencia.esquema(tema) == .dark
        let opcoes = opcoesDoAparelho
        let tela: TelaDoVidro = if case .principal = modelo.fase { .app } else { .entrada }
        let fundoAnda = opcoes.fundoAnda(ativo: fase == .active, rolando: pausas.rolando, teclado: teclado,
                                         coberto: pausas.cobertas > 0)
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: tela, pele: paleta.pele, escuro: escuro), relogio: relogio,
                        deslocamento: quadroFixo, piorCaso: laudo.auroraPiorCaso)
                .animation(opcoes.reduzirMovimento ? nil : Aurora.transicao(paraOApp: tela == .app), value: tela)
            Globo(relogio: relogio, anguloFixo: laudo.anguloDoGlobo)
                .opacity(Globo.intensidade(tela: tela, escuro: escuro))
                .animation(opcoes.reduzirMovimento ? nil : Aurora.transicao(paraOApp: tela == .app), value: tela)
            conteudo
                .transition(.opacity)
                .animation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.25), value: tela)
        }
        #if DEBUG
        .modifier(ApagaTexto(ativo: textoApagado == "tudo"))
        .environment(\.apagaTextoDaNavegacao, textoApagado == "navegacao")
        #endif
        // O aviso fica por cima de todas as telas; vem antes do .environment para receber a mesma paleta.
        .overlay(alignment: .top) { AvisoView() }
        .environment(\.paleta, paleta)
        .environment(\.opcoes, opcoes)
        .environment(\.vidro, VidroTokens.para(tela: tela, escolha: Aparencia.vidro(escolhaDeVidro), opcoes: opcoes))
        .environment(\.pausasDoFundo, pausas)
        .tint(paleta.cor(.marca))
        .preferredColorScheme(Aparencia.esquema(tema))
        .onChange(of: fundoAnda, initial: true) { _, anda in relogio.rodando = anda }
        .acompanhaEnergia(poucaEnergia: $poucaEnergia, calor: $calor)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in teclado = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in teclado = false }
    }

    private var opcoesDoAparelho: OpcoesDoAparelho {
        var o = OpcoesDoAparelho(reduzirMovimento: reduzirMovimento, reduzirTransparencia: reduzirTransparencia,
                                 aumentarContraste: contraste == .increased, poucaEnergia: poucaEnergia, calor: calor)
        #if DEBUG
        o.reduzirMovimento = o.reduzirMovimento || forcarReduzirMovimento
        o.reduzirTransparencia = o.reduzirTransparencia || forcarReduzirTransparencia
        o.aumentarContraste = o.aumentarContraste || forcarAumentarContraste
        #endif
        return o
    }

    private var quadroFixo: TimeInterval {
        #if DEBUG
        return max(0, quadroDaAurora)
        #else
        return 0
        #endif
    }

    /// Os ganchos do laudo de leitura; no Release, nada.
    private var laudo: (anguloDoGlobo: Double?, auroraPiorCaso: Bool) {
        #if DEBUG
        return (anguloDoGlobo >= 0 ? anguloDoGlobo : nil, auroraPiorCaso)
        #else
        return (nil, false)
        #endif
    }

    @ViewBuilder private var conteudo: some View {
        switch modelo.fase {
        case .carregando:
            ProgressView()
                .accessibilityLabel("Carregando")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .entrada:
            EntradaView(faltaPouco: nil)
        case .faltaPouco(let usuario):
            EntradaView(faltaPouco: usuario)
        case .principal:
            PrincipalView()
        }
    }
}

/// O toast do site: texto curto no topo, em vidro, que some sozinho.
struct AvisoView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let aviso = modelo.aviso {
            Text(aviso)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(paleta.cor(.texto))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .superficie(.navegacao, em: .capsule)
                .padding(.horizontal, 16)
                .allowsHitTesting(false)                 // fica sobre a barra: não pode engolir o toque nela
                .accessibilityIdentifier("aviso")
                .accessibilityAddTraits(.updatesFrequently)
                .onChange(of: aviso, initial: true) { _, novo in AccessibilityNotification.Announcement(novo).post() }
        }
    }
}
