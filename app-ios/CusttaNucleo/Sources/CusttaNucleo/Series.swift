import Foundation

public struct PontoEvolucao: Equatable, Sendable {
    public let mes: String
    public let bruto: Double
    public let corrigido: Double
}

public struct PontoMensal: Equatable, Sendable {
    public let mes: String
    public let total: Double
}

/// Ordenação que mantém a ordem original no empate, como o sort do JavaScript.
func ordenadoEstavel<T>(_ itens: [T], _ antes: (T, T) -> Bool) -> [T] {
    itens.enumerated().sorted { a, b in
        if antes(a.element, b.element) { return true }
        if antes(b.element, a.element) { return false }
        return a.offset < b.offset
    }.map(\.element)
}

/// Chave de mês do calc.js: o ano como número, sem completar com zeros.
private func chaveMes(_ ano: Int, _ mes: Int) -> String { "\(ano)-" + doisDigitos(mes) }

private func anoMes(_ chave: String) -> (Int, Int) {
    (Int(chave.prefix(4)) ?? 0, Int(chave.dropFirst(5).prefix(2)) ?? 0)
}

/// `serieEvolucao` do calc.js: um ponto por mês do 1º gasto até o fim da correção, cortando no
/// último dia de cada mês; os últimos 24.
public func serieEvolucao(_ obra: Obra, taxa: Double, hoje: String) -> [PontoEvolucao] {
    if obra.gastos.isEmpty { return [] }
    let fim = fimCorrecao(obra, hoje: hoje)
    let gs = ordenadoEstavel(obra.gastos) { menorJS($0.data, $1.data) }
    let ini = String(gs[0].data.prefix(7))
    let fimMes = String(fim.prefix(7))
    let ultimo = menorJS(ini, fimMes) ? fimMes : ini
    var meses: [String] = []
    var (y, m) = anoMes(ini)
    for _ in 0..<600 {
        let chave = chaveMes(y, m)
        meses.append(chave)
        if chave == ultimo { break }
        m += 1
        if m > 12 { m = 1; y += 1 }
    }
    let pontos = meses.map { mes -> PontoEvolucao in
        let (ano, numeroMes) = anoMes(mes)
        var corte = mes + "-" + doisDigitos(diasNoMes(ano: ano, mes: numeroMes))
        if menorJS(fim, corte) { corte = fim }
        let ate = gs.filter { !menorJS(corte, $0.data) }
        return PontoEvolucao(mes: mes,
                             bruto: ate.reduce(0) { $0 + $1.valor },
                             corrigido: ate.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: corte, taxa: taxa) })
    }
    return Array(pontos.suffix(24))
}

/// `serieMensal` do calc.js: bruto por mês, meses vazios em zero, os últimos 24.
public func serieMensal(_ gastos: [Gasto]) -> [PontoMensal] {
    if gastos.isEmpty { return [] }
    var por: [String: Double] = [:]
    for g in gastos {
        let k = String(g.data.prefix(7))
        por[k] = (por[k] ?? 0) + g.valor
    }
    let chaves = por.keys.sorted(by: menorJS)
    let fim = chaves[chaves.count - 1]
    var saida: [PontoMensal] = []
    var (y, m) = anoMes(chaves[0])
    for _ in 0..<600 {
        let chave = chaveMes(y, m)
        saida.append(PontoMensal(mes: chave, total: por[chave] ?? 0))
        if chave == fim { break }
        m += 1
        if m > 12 { m = 1; y += 1 }
    }
    return Array(saida.suffix(24))
}

/// `serieEvolucaoAgregada` do calc.js: soma das obras por mês; vendida fica congelada.
public func serieEvolucaoAgregada(_ obras: [Obra], taxa: Double, hoje: String) -> [PontoEvolucao] {
    let series = obras.map { serieEvolucao($0, taxa: taxa, hoje: hoje) }.filter { !$0.isEmpty }
    if series.isEmpty { return [] }
    let meses = Set(series.flatMap { $0.map(\.mes) }).sorted(by: menorJS)
    let pontos = meses.map { mes -> PontoEvolucao in
        var bruto = 0.0, corr = 0.0
        for s in series {
            var p: PontoEvolucao?
            for q in s { if !menorJS(mes, q.mes) { p = q } else { break } }
            if let p { bruto += p.bruto; corr += p.corrigido }
        }
        return PontoEvolucao(mes: mes, bruto: bruto, corrigido: corr)
    }
    return Array(pontos.suffix(24))
}
