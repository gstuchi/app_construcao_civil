import Foundation

/* Primitivas do JavaScript que as regras do site usam e que o Swift faz diferente.
   Cada uma é conferida contra o próprio JavaScript pelos grupos `js.*` dos vetores. */

/// Dígitos decimais mais curtos que voltam ao mesmo Double e o expoente `n` do ECMAScript
/// (x = 0.d1d2…dk × 10^n, d1 ≠ 0). Vêm de `description`, que já é a representação mais
/// curta e, no empate, a mais próxima: a mesma escolha do JavaScript.
func digitosMaisCurtos(_ x: Double) -> (digitos: String, n: Int) {
    let s = x.description                     // "1500.0", "0.1", "1e-07", "1.25e+20"
    var mantissa = Substring(s)
    var expoente = 0
    if let e = s.firstIndex(where: { $0 == "e" || $0 == "E" }) {
        mantissa = s[..<e]
        expoente = Int(s[s.index(after: e)...])!
    }
    var inteiro = mantissa
    var fracao: Substring = ""
    if let p = mantissa.firstIndex(of: ".") {
        inteiro = mantissa[..<p]
        fracao = mantissa[mantissa.index(after: p)...]
    }
    var digitos = String(inteiro) + String(fracao)
    var n = inteiro.count + expoente
    while digitos.count > 1, digitos.first == "0" { digitos.removeFirst(); n -= 1 }
    while digitos.count > 1, digitos.last == "0" { digitos.removeLast() }
    return (digitos, n)
}

/// `String(numero)` do JavaScript (Number::toString do ECMAScript).
public func numeroJS(_ x: Double) -> String {
    if x.isNaN { return "NaN" }
    if x == 0 { return "0" }
    if x.isInfinite { return x < 0 ? "-Infinity" : "Infinity" }
    if x < 0 { return "-" + numeroJS(-x) }
    let (d, n) = digitosMaisCurtos(x)
    let k = d.count
    if k <= n && n <= 21 { return d + String(repeating: "0", count: n - k) }
    if 0 < n && n <= 21 {
        let i = d.index(d.startIndex, offsetBy: n)
        return String(d[..<i]) + "." + String(d[i...])
    }
    if -6 < n && n <= 0 { return "0." + String(repeating: "0", count: -n) + d }
    let e = n - 1
    let resto = d.dropFirst()
    return String(d.prefix(1)) + (resto.isEmpty ? "" : "." + resto) + "e" + (e < 0 ? "-" : "+") + String(abs(e))
}

/// `Math.round` do JavaScript: o meio vai para +infinito (o `rounded()` do Swift leva para longe do zero).
public func arredondarJS(_ x: Double) -> Double {
    let piso = x.rounded(.down)
    return x - piso >= 0.5 ? piso + 1 : piso
}

/// `numero.toFixed(casas)` do JavaScript para casas de 0 a 2, as que o site usa: arredonda pelo valor
/// binário exato e, no empate exato, fica com o maior (8.25 → "8.3", 1.005 → "1.00"). Com mais casas,
/// valor grande estouraria os 128 bits da conta.
public func toFixedJS(_ x: Double, _ casas: Int) -> String {
    precondition((0...2).contains(casas), "toFixedJS: casas de 0 a 2")
    if x.isNaN { return "NaN" }
    if abs(x) >= 1e21 { return numeroJS(x) }
    let negativo = x < 0
    let v = abs(x)
    var potencia: UInt128 = 1
    for _ in 0..<casas { potencia *= 10 }
    var n: UInt128 = 0
    if v != 0 && v.isNormal {
        let m = UInt128((UInt64(1) << 52) | v.significandBitPattern)   // v = m × 2^e, exato
        let e = Int(v.exponent) - 52
        let produto = m * potencia
        if e >= 0 {
            n = produto << UInt128(e)
        } else if -e < 120 {
            let k = UInt128(-e)
            let q = produto >> k
            let resto = produto - (q << k)
            n = resto << 1 >= (UInt128(1) << k) ? q + 1 : q
        }
    }
    var texto = String(n)
    if casas > 0 {
        if texto.count <= casas { texto = String(repeating: "0", count: casas + 1 - texto.count) + texto }
        texto.insert(".", at: texto.index(texto.endIndex, offsetBy: -casas))
    }
    return (negativo ? "-" : "") + texto
}

/// Espaço para o JavaScript (`trim`, `\s`): WhiteSpace e LineTerminator do ECMAScript.
func ehEspacoJS(_ u: Unicode.Scalar) -> Bool {
    switch u.value {
    case 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0xA0, 0x1680, 0x2000...0x200A,
         0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF: return true
    default: return false
    }
}

/// Dígito para o `\d` do JavaScript: só 0 a 9 do ASCII.
func ehDigito(_ u: Unicode.Scalar) -> Bool { (0x30...0x39).contains(u.value) }

/// `texto.trim()` do JavaScript.
public func aparadoJS(_ s: String) -> String {
    let u = Array(s.unicodeScalars)
    guard let ini = u.firstIndex(where: { !ehEspacoJS($0) }) else { return "" }
    let fim = u.lastIndex(where: { !ehEspacoJS($0) })!
    var r = String.UnicodeScalarView()
    r.append(contentsOf: u[ini...fim])
    return String(r)
}

/// `Number(texto)` do JavaScript: vazio (depois do trim) vale 0; aceita hexadecimal, octal e
/// binário sem sinal, decimal com expoente e "Infinity"; o resto vale NaN.
public func numeroDeTextoJS(_ texto: String) -> Double {
    let t = Array(aparadoJS(texto).unicodeScalars)
    if t.isEmpty { return 0 }
    if t.count > 2, t[0] == "0" {
        let bitsPorDigito: Int? = switch t[1] { case "x", "X": 4; case "o", "O": 3; case "b", "B": 1; default: nil }
        if let bitsPorDigito {
            // O Number() arredonda o valor exato uma vez só; somar dígito a dígito arredondaria a cada passo
            // acima de 2^53 (0x200000000000018 sairia 1 ULP abaixo). Os dígitos viram bits, os bits viram
            // hexadecimal, e o Double lê "0x…p0" de uma vez, estourando para +infinito como o JavaScript.
            var bits = ""
            for u in t[2...] {
                guard let d = Int(String(u), radix: 1 << bitsPorDigito) else { return .nan }
                let b = String(d, radix: 2)
                bits += String(repeating: "0", count: bitsPorDigito - b.count) + b
            }
            // Zero à esquerda não conta; acima de 1024 bits o valor já passa de 2^1024 (e o Double(String)
            // devolve nil acima de 16.384 caracteres, em vez de infinito).
            guard let primeiro = bits.firstIndex(of: "1") else { return 0 }
            bits = String(bits[primeiro...])
            if bits.count > 1024 { return .infinity }
            bits = String(repeating: "0", count: (4 - bits.count % 4) % 4) + bits
            var hex = ""
            var i = bits.startIndex
            while i < bits.endIndex {
                let fim = bits.index(i, offsetBy: 4)
                hex += String(Int(bits[i..<fim], radix: 2)!, radix: 16)
                i = fim
            }
            return Double("0x" + hex + "p0") ?? .nan
        }
    }
    var i = 0
    var negativo = false
    if t[i] == "+" || t[i] == "-" { negativo = t[i] == "-"; i += 1 }
    if Array(t[i...]) == Array("Infinity".unicodeScalars) { return negativo ? -.infinity : .infinity }
    var inteiros = "", fracao = ""
    while i < t.count, ehDigito(t[i]) { inteiros.unicodeScalars.append(t[i]); i += 1 }
    if i < t.count, t[i] == "." {
        i += 1
        while i < t.count, ehDigito(t[i]) { fracao.unicodeScalars.append(t[i]); i += 1 }
    }
    if inteiros.isEmpty && fracao.isEmpty { return .nan }
    var expoente = ""
    if i < t.count, t[i] == "e" || t[i] == "E" {
        i += 1
        if i < t.count, t[i] == "+" || t[i] == "-" { expoente.unicodeScalars.append(t[i]); i += 1 }
        var digitos = 0
        while i < t.count, ehDigito(t[i]) { expoente.unicodeScalars.append(t[i]); i += 1; digitos += 1 }
        if digitos == 0 { return .nan }
    }
    if i != t.count { return .nan }
    let literal = (negativo ? "-" : "") + (inteiros.isEmpty ? "0" : inteiros) + "." + (fracao.isEmpty ? "0" : fracao)
        + (expoente.isEmpty ? "" : "e" + expoente)
    return Double(literal) ?? .nan
}

/// `parseFloat` do JavaScript sobre o que sobra no parseNum (dígitos, ponto e sinal): lê o maior
/// prefixo decimal; sem dígito nenhum devolve nil (o NaN do JavaScript).
func parseFloatJS(_ s: String) -> Double? {
    let t = Array(s.unicodeScalars)
    var i = 0
    var sinal = ""
    if i < t.count, t[i] == "-" || t[i] == "+" { sinal.unicodeScalars.append(t[i]); i += 1 }
    var inteiros = "", fracao = ""
    while i < t.count, ehDigito(t[i]) { inteiros.unicodeScalars.append(t[i]); i += 1 }
    if i < t.count, t[i] == "." {
        i += 1
        while i < t.count, ehDigito(t[i]) { fracao.unicodeScalars.append(t[i]); i += 1 }
    }
    if inteiros.isEmpty && fracao.isEmpty { return nil }
    return Double(sinal + (inteiros.isEmpty ? "0" : inteiros) + (fracao.isEmpty ? "" : "." + fracao))
}

/// Valor "verdadeiro" do JavaScript (`if (v)`). `nil` faz papel de `undefined`.
public func verdadeiroJS(_ v: ValorJSON?) -> Bool {
    switch v {
    case nil, .nulo?: return false
    case .booleano(let b)?: return b
    case .numero(let n)?: return n != 0 && !n.isNaN
    case .texto(let s)?: return !s.isEmpty
    case .lista?, .objeto?: return true
    }
}

/// `Number(v)` do JavaScript para os tipos que chegam do documento. Lista passa pelo texto, como o
/// ToPrimitive do JavaScript: `Number([])` é 0, `Number([7])` é 7, `Number([1, 2])` é NaN.
public func paraNumeroJS(_ v: ValorJSON?) -> Double {
    switch v {
    case nil: return .nan
    case .nulo?: return 0
    case .booleano(let b)?: return b ? 1 : 0
    case .numero(let n)?: return n
    case .texto(let s)?: return numeroDeTextoJS(s)
    case .lista(let l)?: return numeroDeTextoJS(textoDeListaJS(l))
    case .objeto?: return .nan
    }
}

/// `String(lista)` do JavaScript (`join(",")`): null vira "", objeto vira "[object Object]".
func textoDeListaJS(_ l: [ValorJSON]) -> String {
    l.map { v -> String in
        switch v {
        case .nulo: return ""
        case .booleano(let b): return b ? "true" : "false"
        case .numero(let n): return numeroJS(n)
        case .texto(let s): return s
        case .lista(let sub): return textoDeListaJS(sub)
        case .objeto: return "[object Object]"
        }
    }.joined(separator: ",")
}
