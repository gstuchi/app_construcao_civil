import Foundation

/* Datas AAAA-MM-DD como no calc.js. O site faz conta em hora local; aqui a conta é de
   calendário (dia absoluto), que dá o mesmo resultado em qualquer fuso e sem horário de verão.
   Só dataLocalISO depende de fuso, e recebe o fuso explícito. Entradas são datas válidas: o
   estado normalizado não deixa passar outra coisa (dataISOValida existe para checar). */

func componentesISO(_ iso: String) -> (ano: Int, mes: Int, dia: Int)? {
    let u = Array(iso.utf8)
    guard u.count == 10, u[4] == 0x2D, u[7] == 0x2D else { return nil }
    for i in [0, 1, 2, 3, 5, 6, 8, 9] where !(0x30...0x39).contains(u[i]) { return nil }
    func numero(_ r: Range<Int>) -> Int { r.reduce(0) { $0 * 10 + Int(u[$1] - 0x30) } }
    return (numero(0..<4), numero(5..<7), numero(8..<10))
}

func bissexto(_ ano: Int) -> Bool { ano % 4 == 0 && (ano % 100 != 0 || ano % 400 == 0) }

func diasNoMes(ano: Int, mes: Int) -> Int {
    switch mes {
    case 2: return bissexto(ano) ? 29 : 28
    case 4, 6, 9, 11: return 30
    default: return 31
    }
}

/// Dias desde 1970-01-01 no calendário gregoriano proléptico (algoritmo days_from_civil).
func diaAbsoluto(ano: Int, mes: Int, dia: Int) -> Int {
    let y = mes <= 2 ? ano - 1 : ano
    let era = (y >= 0 ? y : y - 399) / 400
    let anoDaEra = y - era * 400
    let diaDoAno = (153 * ((mes + 9) % 12) + 2) / 5 + dia - 1
    let diaDaEra = anoDaEra * 365 + anoDaEra / 4 - anoDaEra / 100 + diaDoAno
    return era * 146097 + diaDaEra - 719468
}

/// O inverso de diaAbsoluto (algoritmo civil_from_days).
func dataDeDiaAbsoluto(_ dias: Int) -> (ano: Int, mes: Int, dia: Int) {
    let z = dias + 719468
    let era = (z >= 0 ? z : z - 146096) / 146097
    let diaDaEra = z - era * 146097
    let anoDaEra = (diaDaEra - diaDaEra / 1460 + diaDaEra / 36524 - diaDaEra / 146096) / 365
    let diaDoAno = diaDaEra - (365 * anoDaEra + anoDaEra / 4 - anoDaEra / 100)
    let mp = (5 * diaDoAno + 2) / 153
    let dia = diaDoAno - (153 * mp + 2) / 5 + 1
    let mes = mp < 10 ? mp + 3 : mp - 9
    return (anoDaEra + era * 400 + (mes <= 2 ? 1 : 0), mes, dia)
}

func doisDigitos(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

/// AAAA-MM-DD, com o ano em quatro dígitos.
func isoDe(ano: Int, mes: Int, dia: Int) -> String {
    let a = String(ano)
    return String(repeating: "0", count: max(0, 4 - a.count)) + a + "-" + doisDigitos(mes) + "-" + doisDigitos(dia)
}

func somarDias(_ iso: String, _ dias: Int) -> String {
    guard let c = componentesISO(iso) else { return iso }
    let d = dataDeDiaAbsoluto(diaAbsoluto(ano: c.ano, mes: c.mes, dia: c.dia) + dias)
    return isoDe(ano: d.ano, mes: d.mes, dia: d.dia)
}

/// `dataLocalISO` do calc.js: o dia do instante no fuso dado (não o dia em UTC).
public func dataLocalISO(_ instante: Date, fuso: TimeZone) -> String {
    var calendario = Calendar(identifier: .gregorian)
    calendario.timeZone = fuso
    let c = calendario.dateComponents([.year, .month, .day], from: instante)
    return isoDe(ano: c.year!, mes: c.month!, dia: c.day!)
}

/// `dataISOValida` do calc.js. Anos 0000 a 0099 não valem: o Date.UTC do JavaScript lê esses anos como 1900 + ano.
public func dataISOValida(_ iso: String?) -> Bool {
    guard let iso, let c = componentesISO(iso) else { return false }
    return c.ano >= 100 && (1...12).contains(c.mes) && (1...diasNoMes(ano: c.ano, mes: c.mes)).contains(c.dia)
}

/// `dataIgualOuDepois` do calc.js.
public func dataIgualOuDepois(_ data: String?, _ minimo: String?) -> Bool {
    guard let data, let minimo, dataISOValida(data), dataISOValida(minimo) else { return false }
    return !menorJS(data, minimo)
}

/// `diasEntre` do calc.js: dias de calendário, nunca negativo.
public func diasEntre(_ de: String, _ ate: String) -> Int {
    guard let a = componentesISO(de), let b = componentesISO(ate) else { return 0 }
    return max(0, diaAbsoluto(ano: b.ano, mes: b.mes, dia: b.dia) - diaAbsoluto(ano: a.ano, mes: a.mes, dia: a.dia))
}

/// `addMesesClampado` do calc.js (meses ≥ 0): dia que não existe vira o último do mês (31/01 + 1 = 28 ou 29/02).
/// Como no JavaScript, o ano sai sem completar com zeros.
public func addMesesClampado(_ dataISO: String, _ meses: Int) -> String {
    guard let c = componentesISO(dataISO) else { return dataISO }
    let total = (c.mes - 1) + meses
    let ano = c.ano + Int((Double(total) / 12).rounded(.down))
    let mes = total % 12
    let dia = min(c.dia, diasNoMes(ano: ano, mes: mes + 1))
    return "\(ano)-" + doisDigitos(mes + 1) + "-" + doisDigitos(dia)
}
