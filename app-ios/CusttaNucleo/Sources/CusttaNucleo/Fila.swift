import Foundation

/* Regras puras da fila de escrita, como no calc.js. */

private let codigosTerminais: Set<String> = ["permission-denied", "unauthenticated", "invalid-argument",
    "not-found", "failed-precondition", "unimplemented", "out-of-range"]

/// `erroEhTerminal` do calc.js: erro que não melhora tentando de novo. Aceita "firestore/PERMISSION_DENIED";
/// erro sem código é falha de transporte e conta como transitório.
public func erroEhTerminal(codigo: String?) -> Bool {
    guard let codigo else { return false }
    let normal = codigo.lowercased().replacingOccurrences(of: "_", with: "-")
        .split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? ""
    return codigosTerminais.contains(normal)
}

/// `proximoBackoff` do calc.js, em milissegundos: 1 s, 2 s, 4 s, 8 s, 16 s e trava em 30 s.
public func proximoBackoff(_ tentativa: Double) -> Int {
    let n = max(0, (tentativa.isNaN ? 0 : tentativa).rounded(.down))
    return Int(min(30_000, 1000 * pow(2, n)))
}
