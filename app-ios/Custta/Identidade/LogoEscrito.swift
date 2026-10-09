import SwiftUI

/* Título escrito à mão (o .logo-escrito do index.html): cada letra aparece sob um traço de caneta,
   na ordem e nos tempos do styles.css; o ponto carimba (com vibração leve, como no app de hoje) e, no
   escuro, um brilho varre o "tt." com o degradê do realce. Com Reduzir movimento ou Pouca Energia
   aparece pronto. Os caminhos são os do index.html, que tests/logo-escrito.test.cjs protege;
   tests/app-ios.test.cjs confere que os dois continuam iguais. */
enum LogoCaminhos {
    struct Letra: Sendable {
        let glifo: String
        /// Traços de caneta que revelam a letra.
        let penas: [String]
        /// O "tt" da marca (cor da marca no claro; no escuro, coberto pelo realce).
        let tt: Bool
    }

    static let letras: [Letra] = [
        // c
        Letra(glifo: "M279 10Q217 10 172 -12Q126 -33 96 -70Q65 -106 50 -152Q35 -198 35 -247Q35 -296 50 -342Q65 -388 96 -424Q126 -460 172 -482Q217 -503 279 -503Q355 -503 411 -467Q467 -431 495 -356L375 -308Q364 -342 342 -363Q319 -384 279 -384Q241 -384 218 -364Q194 -344 183 -312Q172 -281 172 -247Q172 -213 183 -181Q194 -149 218 -129Q241 -109 279 -109Q319 -109 342 -130Q364 -151 375 -185L495 -137Q467 -63 411 -26Q355 10 279 10Z",
              penas: ["M478 -385 L405 -355 A165 195 0 1 0 405 -135 L478 -105"],
              tt: false),
        // u
        Letra(glifo: "M728 10Q665 10 624 -14Q584 -39 565 -84Q546 -128 546 -187V-493H683V-217Q683 -188 690 -164Q696 -139 714 -124Q733 -109 770 -109Q815 -109 836 -136Q856 -162 862 -208Q868 -255 868 -314V-493H1006V0H868V-107L884 -94Q861 -36 820 -13Q778 10 728 10Z",
              penas: ["M600 -493 V-200 C600 15 922 15 922 -230 V-493 V10"],
              tt: false),
        // s
        Letra(glifo: "M1265 10Q1209 10 1167 -6Q1125 -22 1097 -46Q1069 -69 1051 -89L1145 -171Q1162 -146 1192 -123Q1221 -100 1266 -100Q1299 -100 1318 -113Q1336 -126 1336 -143Q1336 -159 1324 -168Q1312 -178 1292 -185Q1272 -192 1247 -199Q1219 -206 1189 -216Q1159 -227 1133 -244Q1107 -261 1091 -288Q1075 -314 1075 -354Q1075 -421 1128 -462Q1180 -503 1265 -503Q1325 -503 1374 -480Q1423 -457 1452 -413L1367 -346Q1349 -372 1321 -386Q1293 -401 1262 -401Q1236 -401 1220 -392Q1203 -382 1203 -367Q1203 -356 1211 -348Q1219 -341 1237 -335Q1255 -329 1286 -321Q1315 -314 1347 -304Q1379 -294 1408 -276Q1436 -259 1454 -230Q1471 -202 1471 -159Q1471 -109 1446 -70Q1420 -32 1374 -11Q1327 10 1265 10Z",
              penas: ["M1412 -392 C1362 -457 1282 -460 1232 -460 C1152 -460 1104 -412 1104 -352 C1104 -284 1172 -268 1252 -244 C1342 -217 1398 -192 1398 -138 C1398 -58 1322 -38 1242 -38 C1162 -38 1108 -73 1070 -118"],
              tt: false),
        // t
        Letra(glifo: "M1729 10Q1688 10 1652 -6Q1616 -21 1594 -56Q1572 -91 1572 -151V-602L1711 -676V-190Q1711 -146 1722 -124Q1734 -102 1767 -102Q1777 -102 1790 -104Q1802 -106 1816 -110V-5Q1795 3 1774 6Q1752 10 1729 10ZM1486 -386V-493H1816V-386Z",
              penas: ["M1641 -690 V-160 C1641 -40 1700 -45 1790 -55", "M1486 -440 H1816"],
              tt: true),
        // t
        Letra(glifo: "M2073 10Q2032 10 1996 -6Q1960 -21 1938 -56Q1916 -91 1916 -151V-602L2055 -676V-190Q2055 -146 2066 -124Q2078 -102 2111 -102Q2121 -102 2134 -104Q2146 -106 2160 -110V-5Q2139 3 2118 6Q2096 10 2073 10ZM1830 -386V-493H2160V-386Z",
              penas: ["M1985 -690 V-160 C1985 -40 2044 -45 2134 -55", "M1830 -440 H2160"],
              tt: true),
        // a
        Letra(glifo: "M2534 0 2524 -66V-312Q2524 -352 2498 -370Q2471 -388 2429 -388Q2390 -388 2348 -373Q2305 -358 2275 -334L2211 -429Q2267 -470 2322 -486Q2377 -503 2441 -503Q2544 -503 2602 -452Q2660 -401 2660 -312V0ZM2391 10Q2337 10 2294 -10Q2251 -30 2226 -68Q2201 -105 2201 -154Q2201 -197 2219 -228Q2237 -259 2267 -276Q2291 -290 2321 -296Q2351 -302 2384 -302H2535V-201H2404Q2390 -201 2378 -198Q2366 -196 2356 -189Q2348 -183 2344 -174Q2339 -165 2339 -154Q2339 -129 2358 -114Q2378 -100 2411 -100Q2442 -100 2468 -113Q2493 -126 2508 -149Q2524 -172 2524 -201L2556 -126Q2540 -74 2514 -44Q2487 -15 2456 -2Q2424 10 2391 10Z",
              penas: ["M2235 -365 C2300 -440 2380 -450 2440 -450 C2560 -450 2600 -380 2600 -300 V0", "M2600 -265 H2385 C2285 -265 2255 -200 2255 -150 C2255 -75 2305 -45 2372 -45 C2470 -45 2560 -90 2590 -180"],
              tt: false)
    ]
    static let ponto = "M2730 0V-137H2874V0Z"

    /// Início e duração (s) de cada traço, na ordem das penas (le-p0 a le-p8 do styles.css).
    static let tracos: [(inicio: Double, duracao: Double)] = [
        (0, 0.3), (0.26, 0.34), (0.56, 0.3), (0.84, 0.22), (1.02, 0.12), (1.12, 0.22), (1.3, 0.12), (1.4, 0.24), (1.6, 0.24),
    ]
    static let curvaDoTraco = CurvaBezier(x1: 0.45, y1: 0.05, x2: 0.35, y2: 1)
    static let carimbo = (inicio: 1.86, duracao: 0.34)
    static let curvaDoCarimbo = CurvaBezier(x1: 0.3, y1: 1.6, x2: 0.5, y2: 1)
    /// A vibração do carimbo, 120 ms depois de ele começar (auth.js).
    static let vibracao = 1.98
    /// Daqui em diante as letras aparecem inteiras (le-fim).
    static let inteiras = 2.25
    static let varredura = (inicio: 2.35, duracao: 0.65)
    static let curvaDaVarredura = CurvaBezier(x1: 0.65, y1: 0, x2: 0.35, y2: 1)
    /// No escuro, o "tt" escuro some debaixo do realce (le-tt).
    static let some = 3.0
    static let total = 3.05

    /// A caixa do desenho (viewBox "0 -700 2900 720") e a largura do traço da caneta.
    static let caixa = CGRect(x: 0, y: -700, width: 2900, height: 720)
    static let larguraDaPena = 180.0

    /// Os caminhos já lidos (uma vez).
    static let caminhos: (letras: [(glifo: Path, penas: [Path], tt: Bool)], ponto: Path) = {
        let lidas = letras.map { l in
            ((try? CaminhoSVG.ler(l.glifo)) ?? Path(), l.penas.map { (try? CaminhoSVG.ler($0)) ?? Path() }, l.tt)
        }
        return (lidas, (try? CaminhoSVG.ler(ponto)) ?? Path())
    }()
}

struct LogoEscrito: View {
    /// false: aparece pronto (Reduzir movimento, Pouca Energia).
    let animado: Bool
    /// Altura do logo: não cresce com a letra grande (decisão do mockup).
    var altura: CGFloat = 33
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    @Environment(\.pausasDoFundo) private var pausas
    @State private var terminou = false
    @State private var carimbou = false

    var body: some View {
        let largura = altura * LogoCaminhos.caixa.width / LogoCaminhos.caixa.height
        RelogioDoLogo(rodando: animado && !terminou && !(pausas?.rolando ?? false)) { segundos in
            let t = animado ? segundos : LogoCaminhos.total
            Canvas { contexto, tamanho in desenhar(contexto, tamanho, t: t) }
                .onChange(of: t >= LogoCaminhos.vibracao) { _, passou in if passou { carimbou = true } }
                .onChange(of: t >= LogoCaminhos.total) { _, acabou in if acabou { terminou = true } }
        }
        .frame(width: largura, height: altura)
        .sensoryFeedback(.impact(weight: .light), trigger: carimbou) { _, novo in novo }
        .accessibilityHidden(true)
    }

    private static func progresso(_ t: Double, _ inicio: Double, _ duracao: Double, _ curva: CurvaBezier) -> Double {
        curva.y(min(1, max(0, (t - inicio) / duracao)))
    }

    private func desenhar(_ contexto: GraphicsContext, _ tamanho: CGSize, t: Double) {
        var c = contexto
        let escala = tamanho.height / LogoCaminhos.caixa.height
        c.scaleBy(x: escala, y: escala)
        c.translateBy(x: -LogoCaminhos.caixa.minX, y: -LogoCaminhos.caixa.minY)
        let escuro = esquema == .dark
        let texto = paleta.cor(.texto), marca = paleta.cor(.marca), fundo = paleta.cor(.fundo)
        var indicePena = 0
        for letra in LogoCaminhos.caminhos.letras {
            let penas = letra.penas.indices.map { indicePena + $0 }
            indicePena += letra.penas.count
            if letra.tt && escuro && t >= LogoCaminhos.some { continue }
            let cor = letra.tt ? (escuro ? fundo : marca) : texto
            if t >= LogoCaminhos.inteiras {
                c.fill(letra.glifo, with: .color(cor))
                continue
            }
            var camada = c
            camada.clipToLayer { mascara in
                for (i, pena) in zip(penas, letra.penas) {
                    let (inicio, duracao) = LogoCaminhos.tracos[i]
                    let fim = 1 - 1.1 * (1 - Self.progresso(t, inicio, duracao, LogoCaminhos.curvaDoTraco))
                    guard fim > 0 else { continue }
                    mascara.stroke(pena.trimmedPath(from: 0, to: min(1, fim)), with: .color(.black),
                                   style: StrokeStyle(lineWidth: LogoCaminhos.larguraDaPena, lineCap: .round, lineJoin: .round))
                }
            }
            camada.fill(letra.glifo, with: .color(cor))
        }
        // O ponto carimba a partir da base.
        let ponto = LogoCaminhos.caminhos.ponto, caixa = ponto.boundingRect
        let s = Self.progresso(t, LogoCaminhos.carimbo.inicio, LogoCaminhos.carimbo.duracao, LogoCaminhos.curvaDoCarimbo)
        if s > 0 {
            var p = c
            p.translateBy(x: caixa.midX, y: caixa.maxY)
            p.scaleBy(x: s, y: s)
            p.translateBy(x: -caixa.midX, y: -caixa.maxY)
            p.fill(ponto, with: .color(escuro ? fundo : marca))
        }
        // No escuro, o realce varre o "tt." da esquerda para a direita.
        guard escuro else { return }
        let v = Self.progresso(t, LogoCaminhos.varredura.inicio, LogoCaminhos.varredura.duracao, LogoCaminhos.curvaDaVarredura)
        guard v > 0 else { return }
        var realce = c
        realce.clip(to: Path(CGRect(x: 1440, y: -800, width: 1500 * v, height: 900)))
        let degrade = Gradient(colors: [paleta.cor(.realceLogo), paleta.cor(.destaque)])
        for letra in LogoCaminhos.caminhos.letras where letra.tt {
            realce.fill(letra.glifo, with: .linearGradient(degrade, startPoint: CGPoint(x: 0, y: -690), endPoint: CGPoint(x: 0, y: 10)))
        }
        realce.fill(ponto, with: .linearGradient(degrade, startPoint: CGPoint(x: 0, y: caixa.minY), endPoint: CGPoint(x: 0, y: caixa.maxY)))
    }
}
