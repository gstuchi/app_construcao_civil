import CoreGraphics
import Foundation

/* O medidor do laudo de leitura (Tarefa 11). A auditoria do Xcode não lê fundo de vidro; o print lê. Cada
   cena sai em dois prints do mesmo quadro, com o fundo parado: um normal e um com o texto apagado
   (`-custta.textoApagado`, só Debug). As letras são os pixels que mudam de um para o outro; o fundo de cada
   letra é o pixel do segundo print no mesmo lugar e dois pixels em volta. O contraste (WCAG) sai pixel a
   pixel, com a cor de fato desenhada no miolo das letras; a nota de cada palavra é o percentil 1 (o pior
   ponto, sem o serrilhado) e o pior pixel vai junto no relatório. Fora das letras os dois prints têm de ser
   iguais: se não forem, a cena não é a mesma e o laudo dá erro em vez de medir. */

/// Um print em sRGB, 8 bits por canal (RGBA), da esquerda para a direita e de cima para baixo.
struct Retrato: Sendable {
    let largura: Int
    let altura: Int
    let rgba: [UInt8]

    init(largura: Int, altura: Int, rgba: [UInt8]) {
        precondition(rgba.count == largura * altura * 4)
        self.largura = largura
        self.altura = altura
        self.rgba = rgba
    }

    /// Converte para sRGB (o print do simulador pode vir em Display P3).
    init(_ imagem: CGImage) {
        let largura = imagem.width, altura = imagem.height
        var dados = [UInt8](repeating: 0, count: largura * altura * 4)
        dados.withUnsafeMutableBytes { bytes in
            let contexto = CGContext(data: bytes.baseAddress, width: largura, height: altura, bitsPerComponent: 8,
                                     bytesPerRow: largura * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            contexto.draw(imagem, in: CGRect(x: 0, y: 0, width: largura, height: altura))
        }
        self.init(largura: largura, altura: altura, rgba: dados)
    }
}

enum LaudoDeContraste {
    /// Uma palavra (ou linha) medida: caixa em pontos, cor desenhada, nota (percentil 1) e o pior pixel.
    struct Palavra: Sendable {
        let caixa: CGRect
        let cor: (r: UInt8, g: UInt8, b: UInt8)
        let nota: Double
        let minimo: Double

        var corHex: String { String(format: "#%02X%02X%02X", cor.r, cor.g, cor.b) }
    }

    struct CenaNaoDeterministica: Error, CustomStringConvertible {
        let pixels: Int
        var description: String { "\(pixels) pixels mudaram longe das letras: os dois prints não são a mesma cena" }
    }

    /// A partir de quanto um pixel conta como letra (maior diferença de canal, 0–255).
    static let limiarDaLetra = 40
    /// Diferença tolerada longe das letras (compressão, arredondamento do vidro).
    static let ruido = 10

    /// Luminância relativa do WCAG para cada valor de canal sRGB.
    private static let linear: [Double] = (0...255).map { v in
        let s = Double(v) / 255
        return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
    }

    static func luminancia(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> Double {
        0.2126 * linear[Int(r)] + 0.7152 * linear[Int(g)] + 0.0722 * linear[Int(b)]
    }

    static func contraste(_ a: Double, _ b: Double) -> Double { (max(a, b) + 0.05) / (min(a, b) + 0.05) }

    /// Mede as palavras da cena. `escala` em pixels por ponto; `topo`, em pontos, deixa a barra de status de
    /// fora (a hora muda entre os prints); `somenteEm` limita a medida a regiões e `ignorar` tira regiões
    /// (em pontos).
    static func medir(normal: Retrato, semTexto: Retrato, escala: CGFloat, topo: CGFloat = 0,
                      somenteEm: [CGRect]? = nil, ignorar: [CGRect] = []) throws -> [Palavra] {
        precondition(normal.largura == semTexto.largura && normal.altura == semTexto.altura)
        let w = normal.largura, h = normal.altura
        let a = normal.rgba, b = semTexto.rgba

        func retangulo(_ r: CGRect) -> (x0: Int, y0: Int, x1: Int, y1: Int) {
            (max(0, Int((r.minX * escala).rounded(.down))), max(0, Int((r.minY * escala).rounded(.down))),
             min(w, Int((r.maxX * escala).rounded(.up))), min(h, Int((r.maxY * escala).rounded(.up))))
        }
        var dentro = [Bool](repeating: somenteEm == nil, count: w * h)
        for r in somenteEm ?? [] {
            let q = retangulo(r)
            for y in q.y0..<max(q.y0, q.y1) { for x in q.x0..<max(q.x0, q.x1) { dentro[y * w + x] = true } }
        }
        for r in ignorar {
            let q = retangulo(r)
            for y in q.y0..<max(q.y0, q.y1) { for x in q.x0..<max(q.x0, q.x1) { dentro[y * w + x] = false } }
        }
        for i in 0..<min(w * h, Int((topo * escala).rounded(.up)) * w) { dentro[i] = false }

        // A maior diferença de canal entre os dois prints, pixel a pixel.
        var diferenca = [UInt8](repeating: 0, count: w * h)
        var letra = [Bool](repeating: false, count: w * h)
        for i in 0..<(w * h) where dentro[i] {
            let k = i * 4
            let d = max(abs(Int(a[k]) - Int(b[k])), abs(Int(a[k + 1]) - Int(b[k + 1])), abs(Int(a[k + 2]) - Int(b[k + 2])))
            diferenca[i] = UInt8(d)
            letra[i] = d > limiarDaLetra
        }

        // Longe das letras (mais de 5 pt, o alcance da sombra do texto), os prints têm de ser iguais.
        let perto = dilatar(letra, w, h, rx: Int(5 * escala), ry: Int(5 * escala))
        var mudou = 0
        for i in 0..<(w * h) where dentro[i] && !perto[i] && Int(diferenca[i]) > ruido { mudou += 1 }
        if mudou > max(40, w * h / 5000) { throw CenaNaoDeterministica(pixels: mudou) }

        // Palavras: letras juntas na horizontal (3 pt) e na vertical (1 pt).
        let juntas = dilatar(letra, w, h, rx: Int(3 * escala), ry: Int(escala))
        var rotulo = [Int32](repeating: -1, count: w * h)
        var grupos: [[Int]] = []
        for inicio in 0..<(w * h) where juntas[inicio] && rotulo[inicio] < 0 {
            let n = Int32(grupos.count)
            var pilha = [inicio], membros: [Int] = []
            rotulo[inicio] = n
            func visitar(_ v: Int) {
                if juntas[v] && rotulo[v] < 0 { rotulo[v] = n; pilha.append(v) }
            }
            while let i = pilha.popLast() {
                if letra[i] { membros.append(i) }
                let x = i % w
                if x > 0 { visitar(i - 1) }
                if x < w - 1 { visitar(i + 1) }
                if i >= w { visitar(i - w) }
                if i < w * (h - 1) { visitar(i + w) }
            }
            grupos.append(membros)
        }

        let vizinhos = [(0, 0), (-2, 0), (2, 0), (0, -2), (0, 2)]
        var palavras: [Palavra] = []
        for membros in grupos where membros.count >= 20 {
            // A cor do texto: a mediana dos pixels que mais mudaram (o miolo das letras).
            let fortes = membros.sorted { diferenca[$0] > diferenca[$1] }.prefix(max(1, membros.count / 4))
            func mediana(_ canal: Int) -> UInt8 { fortes.map { a[$0 * 4 + canal] }.sorted()[fortes.count / 2] }
            let cor = (r: mediana(0), g: mediana(1), b: mediana(2))
            let miolo = membros.filter { i in
                let k = i * 4
                return max(abs(Int(a[k]) - Int(cor.r)), abs(Int(a[k + 1]) - Int(cor.g)), abs(Int(a[k + 2]) - Int(cor.b))) <= 28
            }
            guard miolo.count >= 8 else { continue }
            // O fundo sob o miolo e a 2 px dele, no print sem texto.
            let lt = luminancia(cor.r, cor.g, cor.b)
            var notas: [Double] = []
            notas.reserveCapacity(miolo.count * 5)
            for i in miolo {
                let x = i % w, y = i / w
                for (dx, dy) in vizinhos {
                    let vx = x + dx, vy = y + dy
                    guard vx >= 0, vx < w, vy >= 0, vy < h else { continue }
                    let v = vy * w + vx
                    guard dentro[v] else { continue }
                    notas.append(contraste(lt, luminancia(b[v * 4], b[v * 4 + 1], b[v * 4 + 2])))
                }
            }
            notas.sort()
            var x0 = w, y0 = h, x1 = 0, y1 = 0
            for i in membros { let x = i % w, y = i / w; x0 = min(x0, x); y0 = min(y0, y); x1 = max(x1, x); y1 = max(y1, y) }
            let caixa = CGRect(x: CGFloat(x0) / escala, y: CGFloat(y0) / escala,
                               width: CGFloat(x1 - x0 + 1) / escala, height: CGFloat(y1 - y0 + 1) / escala)
            palavras.append(Palavra(caixa: caixa, cor: cor, nota: notas[notas.count / 100], minimo: notas[0]))
        }
        return palavras.sorted { ($0.caixa.minY, $0.caixa.minX) < ($1.caixa.minY, $1.caixa.minX) }
    }

    /// Dilatação retangular (separável, com contagem corrida): verdadeiro onde houver verdadeiro a até rx, ry.
    static func dilatar(_ m: [Bool], _ w: Int, _ h: Int, rx: Int, ry: Int) -> [Bool] {
        var horizontal = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            var conta = 0
            let base = y * w
            for x in 0..<min(w, rx) where m[base + x] { conta += 1 }
            for x in 0..<w {
                if x + rx < w, m[base + x + rx] { conta += 1 }
                if x - rx - 1 >= 0, m[base + x - rx - 1] { conta -= 1 }
                horizontal[base + x] = conta > 0
            }
        }
        var r = [Bool](repeating: false, count: w * h)
        for x in 0..<w {
            var conta = 0
            for y in 0..<min(h, ry) where horizontal[y * w + x] { conta += 1 }
            for y in 0..<h {
                if y + ry < h, horizontal[(y + ry) * w + x] { conta += 1 }
                if y - ry - 1 >= 0, horizontal[(y - ry - 1) * w + x] { conta -= 1 }
                r[y * w + x] = conta > 0
            }
        }
        return r
    }
}
