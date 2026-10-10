import SwiftUI

/* Lê o atributo `d` de um caminho SVG (comandos absolutos M, L, H, V, C, Q, A e Z, com repetição
   implícita) num Path do SwiftUI. Serve ao logo escrito, que usa os mesmos caminhos do index.html
   (tests/app-ios.test.cjs confere que são iguais). O arco vira curvas de Bézier de até 90°, pela
   conversão da especificação do SVG (apêndice F.6). */
enum CaminhoSVG {
    struct ErroDeLeitura: Error, Equatable {
        let perto: String
    }

    static func ler(_ d: String) throws -> Path {
        var itens = Leitor(d)
        var path = Path()
        var atual = CGPoint.zero
        var inicio = CGPoint.zero
        var comando: Character = " "
        while let proximo = itens.proximoComando(anterior: comando) {
            comando = proximo
            switch comando {
            case "M":
                atual = try itens.ponto(); inicio = atual
                path.move(to: atual)
                comando = "L"                                  // pares seguidos depois de M são linhas
            case "L":
                atual = try itens.ponto(); path.addLine(to: atual)
            case "H":
                atual.x = try itens.numero(); path.addLine(to: atual)
            case "V":
                atual.y = try itens.numero(); path.addLine(to: atual)
            case "C":
                let c1 = try itens.ponto(), c2 = try itens.ponto(); atual = try itens.ponto()
                path.addCurve(to: atual, control1: c1, control2: c2)
            case "Q":
                let c = try itens.ponto(); atual = try itens.ponto()
                path.addQuadCurve(to: atual, control: c)
            case "A":
                let rx = try itens.numero(), ry = try itens.numero(), giro = try itens.numero()
                let grande = try itens.numero() != 0, horario = try itens.numero() != 0
                let fim = try itens.ponto()
                arco(&path, de: atual, ate: fim, rx: rx, ry: ry, giro: giro, grande: grande, horario: horario)
                atual = fim
            case "Z":
                path.closeSubpath(); atual = inicio
                comando = " "                                  // Z não se repete: número logo depois é erro
            default:
                throw ErroDeLeitura(perto: String(comando))
            }
        }
        return path
    }

    /// Arco elíptico do SVG em curvas de Bézier.
    static func arco(_ path: inout Path, de p1: CGPoint, ate p2: CGPoint, rx rxDado: Double, ry ryDado: Double,
                     giro: Double, grande: Bool, horario: Bool) {
        var rx = abs(rxDado), ry = abs(ryDado)
        guard rx > 0, ry > 0, p1 != p2 else { path.addLine(to: p2); return }
        let phi = giro * .pi / 180, cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy, y1 = -sinPhi * dx + cosPhi * dy
        let lambda = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lambda > 1 { rx *= lambda.squareRoot(); ry *= lambda.squareRoot() }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coef = (grande != horario ? 1.0 : -1.0) * max(0, num / den).squareRoot()
        let cxL = coef * rx * y1 / ry, cyL = -coef * ry * x1 / rx
        let cx = cosPhi * cxL - sinPhi * cyL + (p1.x + p2.x) / 2
        let cy = sinPhi * cxL + cosPhi * cyL + (p1.y + p2.y) / 2
        func angulo(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        }
        let ux = (x1 - cxL) / rx, uy = (y1 - cyL) / ry, vx = (-x1 - cxL) / rx, vy = (-y1 - cyL) / ry
        let theta1 = angulo(1, 0, ux, uy)
        var delta = angulo(ux, uy, vx, vy)
        if !horario && delta > 0 { delta -= 2 * .pi }
        if horario && delta < 0 { delta += 2 * .pi }
        let partes = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let passo = delta / Double(partes)
        let k = 4.0 / 3.0 * tan(passo / 4)
        func noPlano(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: cx + rx * cosPhi * x - ry * sinPhi * y, y: cy + rx * sinPhi * x + ry * cosPhi * y)
        }
        var theta = theta1
        for _ in 0..<partes {
            let a = cos(theta), b = sin(theta), c = cos(theta + passo), d = sin(theta + passo)
            path.addCurve(to: noPlano(c, d), control1: noPlano(a - k * b, b + k * a), control2: noPlano(c + k * d, d - k * c))
            theta += passo
        }
    }

    /// Os números e comandos do atributo `d`, em ordem.
    private struct Leitor {
        private let caracteres: [Character]
        private var i = 0

        init(_ d: String) { caracteres = Array(d) }

        private mutating func pularSeparadores() {
            while i < caracteres.count, caracteres[i] == " " || caracteres[i] == "," || caracteres[i].isNewline { i += 1 }
        }

        /// O próximo comando; se vier número, repete o anterior.
        mutating func proximoComando(anterior: Character) -> Character? {
            pularSeparadores()
            guard i < caracteres.count else { return nil }
            if caracteres[i].isLetter { defer { i += 1 }; return caracteres[i] }
            return anterior
        }

        mutating func numero() throws -> Double {
            pularSeparadores()
            let comeco = i
            if i < caracteres.count, caracteres[i] == "-" || caracteres[i] == "+" { i += 1 }
            var viuPonto = false
            while i < caracteres.count, caracteres[i].isNumber || (caracteres[i] == "." && !viuPonto) {
                if caracteres[i] == "." { viuPonto = true }
                i += 1
            }
            guard let n = Double(String(caracteres[comeco..<i])) else {
                throw ErroDeLeitura(perto: String(caracteres[comeco..<min(caracteres.count, comeco + 12)]))
            }
            return n
        }

        mutating func ponto() throws -> CGPoint {
            let x = try numero()
            return CGPoint(x: x, y: try numero())
        }
    }
}
