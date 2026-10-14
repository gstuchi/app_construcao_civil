import Foundation

/* O teclado de valor do site (teclado.js), na parte pura: centavos como inteiro, dígitos entrando pela direita como
   numa maquininha. Cada regra tem caso nos vetores (grupos teclado.*). */

/// `TETO` do teclado.js: R$ 99.999.999,99. Acima disso a tecla é ignorada, para nunca mudar o número em silêncio.
public let tetoDoTeclado = 9_999_999_999

/// Uma tecla do teclado de valor.
public enum TeclaDeValor: Equatable, Sendable {
    case digito(Int)
    case duploZero
    case apagar

    /// O nome da tecla no teclado.js ('0'…'9', '00', 'del').
    public var nome: String {
        switch self {
        case .digito(let d): return String(d)
        case .duploZero: return "00"
        case .apagar: return "del"
        }
    }

    /// '0'…'9', '00' e 'del'; o resto não é tecla (o teclado.js ignora).
    public init?(nome: String) {
        switch nome {
        case "00": self = .duploZero
        case "del": self = .apagar
        default:
            guard nome.count == 1, let d = Int(nome), (0...9).contains(d) else { return nil }
            self = .digito(d)
        }
    }
}

/// `aplicarTecla` do teclado.js: dígito pela direita, "00" multiplica por 100, apagar tira o último dígito.
public func aplicarTecla(_ centavos: Int, _ tecla: TeclaDeValor) -> Int {
    let c = max(0, centavos)
    switch tecla {
    case .apagar: return c / 10
    case .duploZero:
        let (n, estourou) = c.multipliedReportingOverflow(by: 100)
        return estourou || n > tetoDoTeclado ? c : n
    case .digito(let d):
        let (n, estourou) = c.multipliedReportingOverflow(by: 10)
        return estourou || n + d > tetoDoTeclado ? c : n + d
    }
}

/// `fmtCentavos` do teclado.js: "1.234,56" (milhar com ponto, sempre duas casas), sem o "R$".
public func fmtCentavos(_ centavos: Int) -> String {
    let c = max(0, centavos)
    let resto = c % 100
    return agruparMilhar(String(c / 100)) + "," + (resto < 10 ? "0\(resto)" : "\(resto)")
}

/// `centavosParaReais` do teclado.js.
public func centavosParaReais(_ centavos: Int) -> Double { Double(centavos) / 100 }

/// `reaisParaCentavos` do teclado.js: arredonda pelo toFixed(4) antes (8,7 × 100 dá 869,999… em ponto flutuante) e para no
/// teto; zero ou negativo vira 0.
public func reaisParaCentavos(_ reais: Double) -> Int {
    guard reais.isFinite, reais > 0 else { return 0 }
    // De 1e21 para cima o toFixed do site devolve notação científica ("1e+21") ou "Infinity", que o parseFloat lê
    // inteiros: dá o teto. O parseFloatJS daqui só lê dígitos e ponto, e em "1e+21" leria 1.
    if reais * 100 >= 1e21 { return tetoDoTeclado }
    let arredondado = arredondarJS(parseFloatJS(toFixedJS(reais * 100, 4)) ?? 0)
    return Int(min(Double(tetoDoTeclado), arredondado))
}
