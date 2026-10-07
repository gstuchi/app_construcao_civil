import Foundation

/* JSON igual ao JSON.stringify do site, byte a byte, e a forma canônica do canon() do calc.js.
   Os tamanhos de blob batem exatamente com o do site porque a ordem das chaves não muda a
   contagem de bytes; o resto (número, escape de texto) segue o JavaScript. */

/// Limite de bytes do blob em JSON (UTF-8), o mesmo LIMITE_BLOB do calc.js.
public let limiteBlob = 900_000

/// A partir daqui o app avisa que os dados estão perto do limite: o AVISO_BLOB do calc.js.
public let avisoBlob = 700_000

/// Chave que o JavaScript trata como índice de array: vem antes das outras, em ordem numérica.
func indiceDeArray(_ chave: String) -> UInt32? {
    guard !chave.isEmpty, chave.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else { return nil }
    if chave.utf8.count > 1 && chave.utf8.first == 0x30 { return nil }
    guard chave.utf8.count <= 10, let v = UInt64(chave), v < 4_294_967_295 else { return nil }
    return UInt32(v)
}

/// Comparação de texto do `<` e do `sort()` do JavaScript: unidade UTF-16 por unidade.
public func menorJS(_ a: String, _ b: String) -> Bool { a.utf16.lexicographicallyPrecedes(b.utf16) }

/// Ordem das chaves no canon(): índices de array em ordem numérica, depois o resto pela ordem do JavaScript.
func ordemCanonica(_ chaves: [String]) -> [String] {
    var indices: [(UInt32, String)] = []
    var outras: [String] = []
    for c in chaves { if let i = indiceDeArray(c) { indices.append((i, c)) } else { outras.append(c) } }
    indices.sort { $0.0 < $1.0 }
    outras.sort(by: menorJS)
    return indices.map(\.1) + outras
}

func escreverTextoJSON(_ s: String, em r: inout String) {
    r += "\""
    for u in s.unicodeScalars {
        switch u.value {
        case 0x22: r += "\\\""
        case 0x5C: r += "\\\\"
        case 0x08: r += "\\b"
        case 0x0C: r += "\\f"
        case 0x0A: r += "\\n"
        case 0x0D: r += "\\r"
        case 0x09: r += "\\t"
        case 0x00..<0x20:
            let hex = String(u.value, radix: 16)
            r += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
        default: r.unicodeScalars.append(u)
        }
    }
    r += "\""
}

func escrever(_ v: ValorJSON, em r: inout String) {
    switch v {
    case .nulo: r += "null"
    case .booleano(let b): r += b ? "true" : "false"
    case .numero(let n): r += n.isFinite ? numeroJS(n) : "null"
    case .texto(let s): escreverTextoJSON(s, em: &r)
    case .lista(let l):
        r += "["
        for (i, x) in l.enumerated() { if i > 0 { r += "," }; escrever(x, em: &r) }
        r += "]"
    case .objeto(let o):
        r += "{"
        for (i, k) in ordemCanonica(Array(o.keys)).enumerated() {
            if i > 0 { r += "," }
            escreverTextoJSON(k, em: &r)
            r += ":"
            escrever(o[k]!, em: &r)
        }
        r += "}"
    }
}

/// `canon()` do calc.js: JSON com as chaves em ordem canônica.
public func canonico(_ v: ValorJSON) -> String {
    var r = ""
    escrever(v, em: &r)
    return r
}

/// Mesmo conteúdo para o site (canon igual): o eco do snapshot usa isto, como o app.js. Compara bytes,
/// como o `===` do JavaScript: o `==` do Swift igualaria texto equivalente em outra normalização (NFC × NFD).
public func mesmoConteudo(_ a: ValorJSON, _ b: ValorJSON) -> Bool { canonico(a).utf8.elementsEqual(canonico(b).utf8) }

/// `tamanhoBlob` do calc.js: bytes UTF-8 do JSON.
public func tamanhoBlob(_ v: ValorJSON) -> Int { canonico(v).utf8.count }

/// `blobCabe` do calc.js.
public func blobCabe(_ v: ValorJSON) -> Bool { tamanhoBlob(v) <= limiteBlob }
