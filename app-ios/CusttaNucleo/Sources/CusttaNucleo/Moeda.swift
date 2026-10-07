import Foundation

/* Dinheiro como o site: máscara dos campos (fmtDigitado, fmtCompleto, numParaCampo, parseNum
   do calc.js) e exibição (money, moneyShort e moneyCurto). Não usa NumberFormatter: o ICU do
   aparelho pode mudar entre versões do iOS, e o espaço depois de "R$" tem de ser o U+00A0 do site. */

/// Agrupa dígitos de milhar com ponto ("1234567" → "1.234.567").
func agruparMilhar(_ digitos: String) -> String {
    var r = ""
    for (i, c) in digitos.enumerated() {
        if i > 0 && (digitos.count - i) % 3 == 0 { r.append(".") }
        r.append(c)
    }
    return r
}

/// `fmtDigitado` do calc.js: só dígitos e uma vírgula, milhar com ponto, até 2 centavos.
public func fmtDigitado(_ entrada: String?) -> String {
    let v = Array((entrada ?? "").unicodeScalars.filter { ehDigito($0) || $0 == "," })
    let virgula = v.firstIndex(of: ",")
    var inteiro = String(String.UnicodeScalarView(virgula.map { Array(v[..<$0]) } ?? v))
    while inteiro.count > 1, inteiro.first == "0" { inteiro.removeFirst() }
    let centavos: String? = virgula.map { i in String(String.UnicodeScalarView(v[(i + 1)...].filter { $0 != "," }.prefix(2))) }
    if inteiro.isEmpty && centavos == nil { return "" }
    let agrupado = agruparMilhar(inteiro.isEmpty ? "0" : inteiro)
    return centavos.map { agrupado + "," + $0 } ?? agrupado
}

/// `fmtCompleto` do calc.js: completa os centavos ("2.000" → "2.000,00").
public func fmtCompleto(_ entrada: String?) -> String {
    let v = fmtDigitado(entrada)
    if v.isEmpty { return "" }
    let partes = v.split(separator: ",", omittingEmptySubsequences: false)
    let centavos = partes.count > 1 ? String(partes[1]) : ""
    return String(partes[0]) + "," + String((centavos + "00").prefix(2))
}

/// `numParaCampo` do calc.js: número salvo → texto do campo.
public func numParaCampo(_ n: Double?) -> String {
    guard let n else { return "" }
    var s = numeroJS(n)
    if let p = s.firstIndex(of: ".") { s.replaceSubrange(p...p, with: ",") }
    return fmtCompleto(s)
}

/// `parseNum` do calc.js para texto: com vírgula, pontos são milhar; sem vírgula, só some o
/// ponto seguido de exatamente três dígitos e depois ponto ou fim ("1.5" continua 1,5).
public func lerNumero(_ texto: String?) -> Double {
    var u = Array(aparadoJS(texto ?? "").unicodeScalars.filter { ehDigito($0) || $0 == "," || $0 == "." || $0 == "-" })
    if u.contains(",") {
        u.removeAll { $0 == "." }
        if let i = u.firstIndex(of: ",") { u[i] = "." }
    } else {
        var saida: [Unicode.Scalar] = []
        for (i, c) in u.enumerated() {
            if c == "." && i + 3 < u.count && u[(i + 1)...(i + 3)].allSatisfy(ehDigito) && (i + 4 == u.count || u[i + 4] == ".") { continue }
            saida.append(c)
        }
        u = saida
    }
    guard let n = parseFloatJS(String(String.UnicodeScalarView(u))), n.isFinite else { return 0 }
    return n
}

/// `parseNum` do calc.js para número: finito passa, o resto vira 0.
public func lerNumero(_ numero: Double) -> Double { numero.isFinite ? numero : 0 }

/// `money` do site (Intl pt-BR, BRL): "R$ 1.234,56" com U+00A0 depois de "R$". Arredonda o meio
/// para longe do zero sobre os dígitos mais curtos, como o ICU; NaN e zero viram "R$ 0,00".
public func moeda(_ valor: Double?) -> String {
    let x = valor ?? 0
    let v = (x.isNaN || x == 0) ? 0 : x
    let sinal = v < 0 ? "-" : ""
    if v.isInfinite { return sinal + "R$\u{00A0}∞" }
    var inteiro = "0", centavos = "00"
    if v != 0 {
        let (d, n) = digitosMaisCurtos(abs(v))
        var parteInteira: String, fracao: String
        if n <= 0 { parteInteira = "0"; fracao = String(repeating: "0", count: -n) + d }
        else if n >= d.count { parteInteira = d + String(repeating: "0", count: n - d.count); fracao = "" }
        else { let i = d.index(d.startIndex, offsetBy: n); parteInteira = String(d[..<i]); fracao = String(d[i...]) }
        var duas = Array((fracao + "00").prefix(2))
        var digitosInteiros = Array(parteInteira)
        var sobe = fracao.count > 2 && fracao[fracao.index(fracao.startIndex, offsetBy: 2)] >= "5"
        var i = 1
        while sobe && i >= 0 {
            if duas[i] == "9" { duas[i] = "0"; i -= 1 } else { duas[i] = Character(String(duas[i].wholeNumberValue! + 1)); sobe = false }
        }
        var j = digitosInteiros.count - 1
        while sobe && j >= 0 {
            if digitosInteiros[j] == "9" { digitosInteiros[j] = "0"; j -= 1 } else { digitosInteiros[j] = Character(String(digitosInteiros[j].wholeNumberValue! + 1)); sobe = false }
        }
        if sobe { digitosInteiros.insert("1", at: 0) }
        inteiro = String(digitosInteiros)
        centavos = String(duas)
    }
    return sinal + "R$\u{00A0}" + agruparMilhar(inteiro) + "," + centavos
}

/// `moneyShort` do site: "R$ 1,23 mi" e "R$ 8,5 mil" (espaço comum), abaixo de mil cai em moeda(_:).
public func moedaCurta(_ n: Double) -> String {
    let a = abs(n)
    let s = n < 0 ? "-" : ""
    func comVirgula(_ t: String) -> String {
        guard let p = t.firstIndex(of: ".") else { return t }
        var r = t
        r.replaceSubrange(p...p, with: ",")
        return r
    }
    if a >= 1e6 { return s + "R$ " + comVirgula(toFixedJS(a / 1e6, a >= 1e7 ? 1 : 2)) + " mi" }
    if a >= 1000 { return s + "R$ " + comVirgula(toFixedJS(a / 1000, a >= 10000 ? 0 : 1)) + " mil" }
    return moeda(n)
}

/// `moneyCurto` do site: tira o ",0" de "R$ 8,0 mil" e o ",00" de "R$ 1,00 mi".
public func moedaCurtaSemZero(_ n: Double) -> String {
    let s = moedaCurta(n)
    for sufixo in [" mil", " mi"] where s.hasSuffix(sufixo) {
        let base = s.dropLast(sufixo.count)
        if let virgula = base.lastIndex(of: ",") {
            let depois = base[base.index(after: virgula)...]
            if !depois.isEmpty && depois.allSatisfy({ $0 == "0" }) { return String(base[..<virgula]) + sufixo }
        }
        return s
    }
    return s
}

/// `fmtMeses` do site: "começando" abaixo de 1 mês, "1 mês", "N meses".
public func fmtMeses(_ m: Double) -> String {
    if m < 1 { return "começando" }
    let r = arredondarJS(m)
    return numeroJS(r) + (r == 1 ? " mês" : " meses")
}
