import Foundation

/* Ponte com os tipos do Foundation que o SDK do Firestore usa (NSNumber, NSString, NSArray,
   NSDictionary, NSNull). Fica no núcleo porque não depende do Firebase e decide a regra de
   número: o Firestore devolve inteiro ou decimal conforme o JavaScript gravou; aqui os dois
   viram Double, e na volta o inteiro seguro vira Int64, como o SDK JavaScript grava. */

public extension ValorJSON {
    /// nil se o valor, ou qualquer coisa dentro dele, for de um tipo que o JSON não tem (data do
    /// Firestore, referência, bytes): virar null perderia o dado na próxima gravação, que reescreve o
    /// documento inteiro. Quem chama decide o que fazer (a etapa 1B recusa ler e não grava).
    init?(foundation valor: Any) {
        switch valor {
        case is NSNull:
            self = .nulo
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .booleano(n.boolValue) }
            else { self = .numero(n.doubleValue) }
        case let s as String:
            self = .texto(s)
        case let l as [Any]:
            var r: [ValorJSON] = []
            r.reserveCapacity(l.count)
            for x in l {
                guard let v = ValorJSON(foundation: x) else { return nil }
                r.append(v)
            }
            self = .lista(r)
        case let o as [String: Any]:
            var r: [String: ValorJSON] = [:]
            for (k, v) in o {
                guard let x = ValorJSON(foundation: v) else { return nil }
                r[k] = x
            }
            self = .objeto(r)
        default:
            return nil
        }
    }

    /// Para gravar no Firestore: inteiro seguro (|n| ≤ 2^53 − 1, sem −0) vira Int64, como o SDK
    /// JavaScript faz; o resto vai como Double.
    var paraFoundation: Any {
        switch self {
        case .nulo: return NSNull()
        case .booleano(let b): return b
        case .numero(let n):
            if n.rounded(.towardZero) == n, abs(n) <= 9_007_199_254_740_991, !(n == 0 && n.sign == .minus) { return Int64(n) }
            return n
        case .texto(let s): return s
        case .lista(let l): return l.map(\.paraFoundation)
        case .objeto(let o): return o.mapValues(\.paraFoundation)
        }
    }
}
