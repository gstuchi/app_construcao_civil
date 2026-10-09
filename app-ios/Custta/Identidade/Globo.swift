import SwiftUI

/* O globo em pontos do PWA (globe.js), em SwiftUI: continentes reais por polígonos, terra brilhante
   e oceano em grade tênue, só o hemisfério da frente, girando a 0,04 rad/s no relógio do fundo (30
   quadros por segundo). Centro em 80% da largura e 42% da altura; raio de 46% da altura ou 55% da
   largura, o menor. Halo atmosférico e aro de "planeta" em volta, desenhados uma vez; a cada quadro só
   os pontos, no retângulo do disco e a 1,75 pixel por ponto, a densidade do globe.js, ampliados. No
   claro fica a 40%, como marca-d'água, e no escuro também, dentro do app. Parado, fica no ângulo 1,2. */

enum PontosDoGlobo {
    /// Continentes (longitude, latitude), aproximados: os mesmos do globe.js.
    static let continentes: [[(Double, Double)]] = [
        [(-168, 66), (-140, 70), (-125, 71), (-110, 72), (-95, 72), (-80, 68), (-75, 62), (-58, 50), (-65, 45), (-74, 40), (-80, 32), (-81, 25), (-90, 19), (-97, 16), (-105, 20), (-111, 24), (-117, 33), (-124, 41), (-128, 50), (-140, 60), (-155, 58), (-165, 60), (-168, 66)],
        [(-52, 60), (-42, 60), (-22, 70), (-18, 76), (-30, 82), (-58, 80), (-68, 76), (-60, 66), (-52, 60)],
        [(-79, 9), (-70, 12), (-60, 9), (-52, 4), (-44, -3), (-35, -6), (-38, -13), (-48, -26), (-56, -35), (-65, -41), (-71, -52), (-75, -48), (-73, -37), (-71, -18), (-77, -6), (-80, 0), (-79, 9)],
        [(-9, 37), (-8, 43), (-2, 48), (0, 52), (7, 58), (12, 56), (18, 55), (25, 58), (30, 60), (40, 66), (55, 68), (60, 60), (50, 50), (40, 47), (30, 46), (25, 40), (15, 38), (5, 36), (-9, 37)],
        [(-17, 15), (-10, 25), (-6, 35), (10, 37), (20, 32), (32, 31), (35, 22), (43, 11), (51, 12), (45, 0), (40, -10), (35, -20), (32, -29), (25, -34), (18, -34), (14, -22), (12, -8), (8, 0), (-8, 5), (-13, 9), (-17, 15)],
        [(30, 46), (40, 47), (50, 50), (60, 60), (55, 68), (70, 73), (90, 76), (110, 77), (130, 72), (145, 70), (160, 68), (178, 66), (178, 62), (162, 58), (155, 52), (142, 46), (135, 43), (128, 39), (122, 34), (120, 26), (110, 18), (103, 8), (98, 12), (92, 20), (88, 22), (80, 12), (73, 18), (68, 24), (60, 26), (50, 28), (40, 36), (33, 40), (30, 46)],
        [(114, -22), (117, -16), (124, -13), (133, -11), (142, -13), (147, -19), (151, -25), (153, -30), (148, -38), (139, -37), (131, -33), (122, -33), (114, -27), (114, -22)],
        [(95, 5), (105, 3), (115, 0), (125, -3), (135, -5), (140, -8), (130, -9), (118, -9), (108, -7), (98, -2), (95, 5)],
        [(130, 32), (135, 34), (140, 36), (142, 42), (144, 44), (140, 40), (136, 35), (130, 32)],
    ]

    static func dentro(_ lon: Double, _ lat: Double, _ poligono: [(Double, Double)]) -> Bool {
        var dentro = false
        var j = poligono.count - 1
        for i in poligono.indices {
            let (xi, yi) = poligono[i], (xj, yj) = poligono[j]
            if (yi > lat) != (yj > lat) && lon < (xj - xi) * (lat - yi) / (yj - yi) + xi { dentro.toggle() }
            j = i
        }
        return dentro
    }

    static func ehTerra(_ lon: Double, _ lat: Double) -> Bool {
        lat < -72 || continentes.contains { dentro(lon, lat, $0) }
    }

    /// Pontos na esfera unitária, calculados uma vez (grade do celular: 2,2°).
    static let todos: (terra: [SIMD3<Double>], oceano: [SIMD3<Double>]) = {
        var terra: [SIMD3<Double>] = [], oceano: [SIMD3<Double>] = []
        let passo = 2.2, rad = Double.pi / 180
        var lat = -84.0
        while lat <= 84 {
            let cosL = cos(lat * rad)
            let passoLon = max(passo, passo / max(cosL, 0.08))
            var lon = -180.0
            while lon < 180 {
                let p = SIMD3(cosL * cos(lon * rad), sin(lat * rad), cosL * sin(lon * rad))
                if ehTerra(lon, lat) { terra.append(p) } else { oceano.append(p) }
                lon += passoLon
            }
            lat += passo
        }
        return (terra, oceano)
    }()
}

/// Onde o globo fica na tela: centro, raio e o retângulo que os pontos podem ocupar.
struct GeometriaDoGlobo: Equatable {
    let tamanho: CGSize
    var centro: CGPoint { CGPoint(x: tamanho.width * 0.80, y: tamanho.height * 0.42) }
    var raio: CGFloat { min(tamanho.height * 0.46, tamanho.width * 0.55) }

    /// O disco com a margem do maior ponto, cortado pela tela com a folga de 6 pt do globe.js.
    var disco: CGRect {
        let r = raio + 4
        return CGRect(x: centro.x - r, y: centro.y - r, width: 2 * r, height: 2 * r)
            .intersection(CGRect(x: -6, y: -6, width: tamanho.width + 12, height: tamanho.height + 12))
    }
}

struct Globo: View {
    let relogio: RelogioDoFundo
    /// Ângulo fixo (Debug, `-custta.anguloDoGlobo`, para o laudo de leitura); nil segue o relógio.
    var anguloFixo: Double? = nil
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    /// No escuro, dentro do app, o globo fica mais fundo, a 40%, junto com a aurora funda (decisão do Giovani em
    /// 09/10, com o laudo de leitura): atrás do vidro claro do iOS os pontos ficavam nítidos, e o texto dos
    /// cartões não fechava 4,5:1 sobre eles. A 40%, os pontos entre os cartões ficam com o brilho dos do
    /// mockup aprovado. Na entrada fica inteiro.
    nonisolated static func intensidade(tela: TelaDoVidro, escuro: Bool) -> Double { escuro && tela == .app ? 0.4 : 1 }

    var body: some View {
        let angulo = anguloFixo ?? 1.2 + 0.04 * relogio.segundos
        GeometryReader { geo in
            let g = GeometriaDoGlobo(tamanho: geo.size)
            ZStack(alignment: .topLeading) {
                HaloDoGlobo(geometria: g, halo: paleta.cor(.globoHalo), aro: paleta.cor(.globoAro)).equatable()
                PontosDoGloboVisiveis(geometria: g, angulo: angulo)
            }
            .modifier(MarcaDagua(ativa: esquema != .dark))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// No claro, o globo inteiro a 40% (halo e pontos juntos, como o canvas do site).
private struct MarcaDagua: ViewModifier {
    let ativa: Bool

    func body(content: Content) -> some View {
        if ativa { content.compositingGroup().opacity(0.4) } else { content }
    }
}

/// Halo atmosférico e aro: não mudam com o giro, então não são redesenhados a cada quadro.
private struct HaloDoGlobo: View, Equatable {
    let geometria: GeometriaDoGlobo
    let halo: Color
    let aro: Color

    var body: some View {
        Canvas { contexto, tamanho in
            let c = geometria.centro, r = geometria.raio
            contexto.fill(Path(CGRect(origin: .zero, size: tamanho)),
                          with: .radialGradient(Gradient(stops: [.init(color: halo.opacity(0.22), location: 0),
                                                                 .init(color: halo.opacity(0.07), location: 0.7),
                                                                 .init(color: halo.opacity(0), location: 1)]),
                                                center: c, startRadius: r * 0.4, endRadius: r * 1.35))
            contexto.stroke(Path(ellipseIn: CGRect(x: c.x - r * 1.01, y: c.y - r * 1.01, width: r * 2.02, height: r * 2.02)),
                            with: .color(aro.opacity(0.18)), lineWidth: 1.2)
        }
    }
}

/// Os pontos do hemisfério da frente, só no retângulo do disco, desenhados a 1,75 pixel por ponto (a
/// densidade do globe.js e do globo do mockup aprovado) e ampliados.
private struct PontosDoGloboVisiveis: View {
    let geometria: GeometriaDoGlobo
    let angulo: Double
    @Environment(\.paleta) private var paleta
    @Environment(\.displayScale) private var escalaDaTela

    /// Pixels por ponto do globe.js (`dpr = min(1.75, …)`).
    private static let densidade: CGFloat = 1.75
    /// Faixas de profundidade: um desenho por faixa e cor, em vez de um por ponto.
    private static let faixas = 10

    var body: some View {
        let disco = geometria.disco
        let k = min(1, Self.densidade / escalaDaTela)
        Canvas { contexto, _ in
            var c = contexto
            c.scaleBy(x: k, y: k)
            c.translateBy(x: -disco.minX, y: -disco.minY)
            let s = sin(angulo), cs = cos(angulo)
            desenharPontos(PontosDoGlobo.todos.oceano, c, s, cs, terra: false)
            desenharPontos(PontosDoGlobo.todos.terra, c, s, cs, terra: true)
        }
        .frame(width: disco.width * k, height: disco.height * k)
        .scaleEffect(1 / k, anchor: .topLeading)
        .offset(x: disco.minX, y: disco.minY)
    }

    private func desenharPontos(_ pontos: [SIMD3<Double>], _ contexto: GraphicsContext, _ s: Double, _ c: Double, terra: Bool) {
        let n = Self.faixas
        let centro = geometria.centro, r = Double(geometria.raio)
        let w = Double(geometria.tamanho.width), h = Double(geometria.tamanho.height)
        var caminhos = Array(repeating: Path(), count: n)
        var brilho = Array(repeating: Path(), count: n)
        for p in pontos {
            let x = p.x * c - p.z * s, z = p.x * s + p.z * c
            guard z >= 0.02 else { continue }                          // só o hemisfério da frente
            let sx = Double(centro.x) + x * r, sy = Double(centro.y) - p.y * r
            guard sx >= -6, sx <= w + 6, sy >= -6, sy <= h + 6 else { continue }
            let faixa = min(n - 1, Int(z * Double(n)))
            let profundidade = (Double(faixa) + 0.5) / Double(n)
            let lado = terra ? 1.5 + profundidade * 1.7 : 1.1 + profundidade * 1.0
            let quadrado = CGRect(x: sx - lado / 2, y: sy - lado / 2, width: lado, height: lado)
            if terra && z > 0.7 { brilho[faixa].addRect(quadrado) } else { caminhos[faixa].addRect(quadrado) }
        }
        let cor = paleta.cor(terra ? .globoTerra : .globoOceano), corBrilho = paleta.cor(.globoBrilho)
        for faixa in 0..<n {
            let profundidade = (Double(faixa) + 0.5) / Double(n)
            let alfa = terra ? 0.30 + profundidade * 0.62 : 0.10 + profundidade * 0.20
            if !caminhos[faixa].isEmpty { contexto.fill(caminhos[faixa], with: .color(cor.opacity(alfa))) }
            if !brilho[faixa].isEmpty { contexto.fill(brilho[faixa], with: .color(corBrilho.opacity(alfa))) }
        }
    }
}
