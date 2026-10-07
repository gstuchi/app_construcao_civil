import Foundation

/// Valor do documento `dados/{uid}` como o JavaScript o vê. O modelo lê e escreve por cima
/// desta árvore, então campo que o app não conhece volta intacto para o banco.
/// Número é sempre `Double`, como no JavaScript: inteiro e decimal vindos do Firestore viram o mesmo caso.
public enum ValorJSON: Equatable, Hashable, Sendable {
    case nulo
    case booleano(Bool)
    case numero(Double)
    case texto(String)
    case lista([ValorJSON])
    case objeto([String: ValorJSON])
}

public extension ValorJSON {
    var comoTexto: String? { if case .texto(let s) = self { return s }; return nil }
    var comoNumero: Double? { if case .numero(let n) = self { return n }; return nil }
    var comoBooleano: Bool? { if case .booleano(let b) = self { return b }; return nil }
    var comoLista: [ValorJSON]? { if case .lista(let l) = self { return l }; return nil }
    var comoObjeto: [String: ValorJSON]? { if case .objeto(let o) = self { return o }; return nil }
}

extension ValorJSON: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .nulo }
        else if let b = try? c.decode(Bool.self) { self = .booleano(b) }
        else if let n = try? c.decode(Double.self) { self = .numero(n) }
        else if let s = try? c.decode(String.self) { self = .texto(s) }
        else if let l = try? c.decode([ValorJSON].self) { self = .lista(l) }
        else { self = .objeto(try c.decode([String: ValorJSON].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .nulo: try c.encodeNil()
        case .booleano(let b): try c.encode(b)
        case .numero(let n): try c.encode(n)
        case .texto(let s): try c.encode(s)
        case .lista(let l): try c.encode(l)
        case .objeto(let o): try c.encode(o)
        }
    }
}
