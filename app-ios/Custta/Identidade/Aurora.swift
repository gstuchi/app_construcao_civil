import SwiftUI

/* A aurora do PWA (#aurora do styles.css) em SwiftUI: quatro brilhos elípticos e um degradê de base
   nas cores do skin, numa camada maior que a área visível (−15% em cima e embaixo, −30% dos lados)
   que deriva devagar (26 s de ida e 26 de volta). Cobre 78% da altura da tela, passa por trás da
   barra de status e some para baixo. A camada só é redesenhada quando a cor ou a intensidade mudam;
   a deriva só a move (no relógio do fundo), então o quadro custa uma transformação. */

enum Aurora {
    /// Intensidade do mockup aprovado: a de hoje na entrada, a funda dentro do app (no escuro); no claro,
    /// a do site nas duas.
    static func intensidade(tela: TelaDoVidro, pele: Pele, escuro: Bool) -> Double {
        switch (escuro, tela, pele) {
        case (false, _, .esmeralda): return 0.55
        case (false, _, .azul): return 0.52
        case (true, .entrada, .esmeralda): return 0.92
        case (true, .entrada, .azul): return 1
        case (true, .app, .esmeralda): return 0.48
        case (true, .app, .azul): return 0.52
        }
    }

    /// Ao entrar a aurora assenta em 0,9 s; ao sair, clareia em 0,6 s (curva suave de saída).
    static func transicao(paraOApp: Bool) -> Animation {
        .timingCurve(0.2, 0.8, 0.2, 1, duration: paraOApp ? 0.9 : 0.6)
    }
}

/// Um quadro da deriva (keyframes aurora-deriva do site): deslocamento em fração da camada, giro e escala.
struct Deriva: Equatable, Sendable {
    var x: Double
    var y: Double
    var giro: Double
    var escala: Double

    static let quadros = [
        Deriva(x: -0.04, y: -0.02, giro: 0, escala: 1),
        Deriva(x: 0.05, y: 0.03, giro: 8, escala: 1.08),
        Deriva(x: -0.02, y: 0.04, giro: -6, escala: 1.02),
    ]

    /// 26 s de ida e 26 de volta; cada trecho entre quadros com ease-in-out, como o CSS.
    static func em(segundos t: TimeInterval) -> Deriva {
        let ciclo = t.truncatingRemainder(dividingBy: 52)
        let p = ciclo <= 26 ? ciclo / 26 : (52 - ciclo) / 26
        let (a, b, local) = p < 0.5 ? (quadros[0], quadros[1], p / 0.5) : (quadros[1], quadros[2], (p - 0.5) / 0.5)
        let e = CurvaBezier.suave.y(local)
        return Deriva(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e,
                      giro: a.giro + (b.giro - a.giro) * e, escala: a.escala + (b.escala - a.escala) * e)
    }
}

/// O fundo de todas as telas: a cor de fundo e a aurora por cima.
struct FundoAurora: View {
    /// Intensidade da aurora (animável: a transição entre a entrada e o app passa por aqui).
    let intensidade: Double
    let relogio: RelogioDoFundo
    /// Segundos de deriva somados ao relógio (os testes de contraste congelam a aurora num quadro dado).
    var deslocamento: TimeInterval = 0
    /// Só em Debug, para o laudo de leitura: a aurora no pior caso da deriva inteira (ver EnvelopeDaAurora).
    var piorCaso = false
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        let d = Deriva.em(segundos: relogio.segundos + deslocamento)
        let fundo = paleta.cor(.fundo)
        GeometryReader { geo in
            let largura = geo.size.width, altura = geo.size.height * 0.78
            ZStack(alignment: .top) {
                if piorCaso {
                    EnvelopeDaAurora(camada: camada, fundo: fundo, escuro: esquema == .dark, largura: largura, altura: altura)
                } else {
                    Self.movida(camada, d, largura, altura)
                }
                // A aurora some para baixo: o fundo por cima, transparente até 40% e opaco no fim. É o mesmo
                // pixel da máscara do site sem o passe fora da tela a cada quadro da deriva.
                LinearGradient(stops: [.init(color: fundo.opacity(0), location: 0.4), .init(color: fundo, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .frame(width: largura, height: altura)
            .clipped()
        }
        .background(fundo)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var camada: CamadaAurora {
        CamadaAurora(cores: [paleta.cor(.aurora1), paleta.cor(.aurora2), paleta.cor(.aurora3), paleta.cor(.aurora4)],
                     intensidade: intensidade)
    }

    /// A camada num quadro da deriva. Desenhada a um terço do tamanho e ampliada: degradê liso não perde
    /// nada e a camada ocupa um nono da memória.
    static func movida(_ camada: CamadaAurora, _ d: Deriva, _ largura: CGFloat, _ altura: CGFloat) -> some View {
        camada
            .equatable()
            .frame(width: largura * 1.6 / 3, height: altura * 1.3 / 3)
            .scaleEffect(3)
            .frame(width: largura * 1.6, height: altura * 1.3)
            .scaleEffect(d.escala)
            .rotationEffect(.degrees(d.giro))
            .offset(x: d.x * largura * 1.6, y: d.y * altura * 1.3)
            .frame(width: largura, height: altura)
    }
}

/// Só para o laudo de leitura (Debug, `-custta.auroraPiorCaso`): os 27 quadros da deriva (de 0 a 26 s)
/// sobre o fundo, combinados pelo mais claro no escuro (o texto é claro) e pelo mais escuro no claro. Um
/// print mede o pior ponto da aurora no ciclo inteiro. Cada quadro é composto com o fundo antes de entrar
/// na conta: sem isso, o mais claro agia sobre a aurora semitransparente de cada quadro e o envelope ficava
/// até 3 vezes mais claro que o mais claro dos quadros (achado de 09/10).
struct EnvelopeDaAurora: View {
    let camada: CamadaAurora
    let fundo: Color
    let escuro: Bool
    let largura: CGFloat
    let altura: CGFloat
    /// Os segundos da deriva que entram na conta (os testes usam menos quadros).
    var segundos = Array(0...26)

    var body: some View {
        ZStack {
            ForEach(segundos, id: \.self) { s in
                FundoAurora.movida(camada, Deriva.em(segundos: Double(s)), largura, altura)
                    .background(fundo)
                    .compositingGroup()
                    .blendMode(s == segundos[0] ? .normal : (escuro ? .lighten : .darken))
            }
        }
        .compositingGroup()
    }
}

/// A camada desenhada: base em degradê de 100° e os quatro brilhos, de baixo para cima.
struct CamadaAurora: View, Animatable, Equatable {
    let cores: [Color]
    var intensidade: Double

    nonisolated var animatableData: Double {
        get { intensidade }
        set { intensidade = newValue }
    }

    /// Brilhos do CSS: tamanho e centro em fração da camada, cor (índice) e onde o brilho some.
    private static let brilhos: [(rx: Double, ry: Double, cx: Double, cy: Double, cor: Int, fim: Double)] = [
        (0.24, 0.24, 0.44, 0.12, 3, 0.70),
        (0.48, 0.44, 0.52, 0.52, 2, 0.74),
        (0.50, 0.52, 0.84, 0.16, 1, 0.70),
        (0.55, 0.55, 0.16, 0.26, 0, 0.70),
    ]

    var body: some View {
        Canvas { contexto, tamanho in
            let w = tamanho.width, h = tamanho.height, a = intensidade
            // linear-gradient(100deg, A3, A1 35%, A2 65%, A3): a linha passa pelo centro.
            let angulo = 100.0 * .pi / 180
            let direcao = CGVector(dx: sin(angulo), dy: -cos(angulo))
            let meia = (abs(w * sin(angulo)) + abs(h * cos(angulo))) / 2
            let base = Gradient(stops: [
                .init(color: cores[2].opacity(a), location: 0), .init(color: cores[0].opacity(a), location: 0.35),
                .init(color: cores[1].opacity(a), location: 0.65), .init(color: cores[2].opacity(a), location: 1),
            ])
            contexto.fill(Path(CGRect(origin: .zero, size: tamanho)),
                          with: .linearGradient(base, startPoint: CGPoint(x: w / 2 - direcao.dx * meia, y: h / 2 - direcao.dy * meia),
                                                endPoint: CGPoint(x: w / 2 + direcao.dx * meia, y: h / 2 + direcao.dy * meia)))
            for b in Self.brilhos {
                let cor = cores[b.cor]
                contexto.drawLayer { camada in
                    camada.translateBy(x: b.cx * w, y: b.cy * h)
                    camada.scaleBy(x: b.rx * w, y: b.ry * h)
                    camada.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                                with: .radialGradient(Gradient(stops: [.init(color: cor.opacity(a), location: 0),
                                                                       .init(color: cor.opacity(0), location: b.fim)]),
                                                      center: .zero, startRadius: 0, endRadius: 1))
                }
            }
        }
    }
}

/// Halo do texto solto sobre a aurora, só no escuro: o tom do fundo no centro, com borda gradual. Na entrada,
/// atrás do título, do logo e da dica; nos tamanhos de acessibilidade cresce junto com o título e o miolo fica
/// mais largo. No título grande da barra (Obras e Ajustes) e na versão em Ajustes, mais leve.
struct HaloDoTitulo: View {
    /// Opacidade no centro: o menor passo que passa de 4,5:1 no Pro Max (decisão do Giovani em 10/10). Na entrada,
    /// 50% (com 45%, a dica "Role para entrar" ficava em 4,06:1 no pior momento da aurora); na barra, 5% (sem
    /// halo, o título "Obras", branco do sistema, ficava em 4,41:1, e a versão em Ajustes, em 4,42:1).
    nonisolated static let naEntrada = 0.50
    nonisolated static let naBarra = 0.05
    let grande: Bool
    var opacidade = HaloDoTitulo.naEntrada
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        let a = esquema == .dark ? opacidade : 0
        let fundo = paleta.cor(.fundo)
        let paradas: [(Double, Double)] = grande
            ? [(0, 1), (0.66, 1), (0.76, 0.8), (0.87, 0.45), (0.95, 0.15), (1, 0)]
            : [(0, 1), (0.46, 1), (0.60, 0.82), (0.74, 0.5), (0.88, 0.18), (1, 0)]
        EllipticalGradient(stops: paradas.map { .init(color: fundo.opacity(a * $0.1), location: $0.0) },
                           center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            .padding(grande ? EdgeInsets(top: -96, leading: -70, bottom: -80, trailing: -70)
                            : EdgeInsets(top: -64, leading: -78, bottom: -58, trailing: -78))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// O halo atrás do título grande da barra, no conteúdo que rola: o título fica logo acima do conteúdo, então o
    /// halo sobe e sai junto quando o título recolhe.
    func haloDoTituloDaBarra() -> some View { modifier(HaloDoTituloDaBarra()) }
}

private struct HaloDoTituloDaBarra: ViewModifier {
    /// A linha do título grande (41 pt na letra padrão), que cresce com a letra como o título do sistema.
    @ScaledMetric(relativeTo: .largeTitle) private var linha: CGFloat = 41
    @ScaledMetric(relativeTo: .largeTitle) private var largura: CGFloat = 100

    func body(content: Content) -> some View {
        content.background(alignment: .topLeading) {
            HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naBarra)
                .frame(width: largura, height: linha)
                .offset(x: 18, y: -(linha + 9))
        }
    }
}
