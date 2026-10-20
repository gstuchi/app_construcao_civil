import Foundation

/* Orçamento previsto × real, como o orcamentoObra do calc.js. Base sempre bruta (inclui parcelas
   a vencer). O pct arredondado é o que a tela mostra e decide o nível, então cor e número não discordam. */

public enum NivelOrcamento: String, Sendable {
    case ok, perto, passou
}

/// LIMIAR_PERTO do calc.js: a partir de 90% do previsto o nível é "perto".
public let limiarPerto = 90.0

public struct ItemOrcamento: Equatable, Sendable {
    /// Tópico, no modo por tópico; nil no resumo e no modo total.
    public let id: String?
    public let previsto: Double
    public let gasto: Double
    /// Inteiro (Math.round do JavaScript), guardado como Double.
    public let pct: Double
    public let sobra: Double
    public let nivel: NivelOrcamento
}

public struct ForaOrcamento: Equatable, Sendable {
    public let id: String
    public let gasto: Double
}

public struct ResumoOrcamento: Equatable, Sendable {
    /// "total" ou "topicos".
    public let modo: String
    public let geral: ItemOrcamento
    public let topicos: [ItemOrcamento]
    public let fora: [ForaOrcamento]
    public let foraTotal: Double
}

func itemOrcamento(_ id: String?, gasto: Double, previsto: Double) -> ItemOrcamento {
    let pct = arredondarJS(gasto / previsto * 100)
    let nivel: NivelOrcamento = gasto - previsto > 0.005 ? .passou : pct >= limiarPerto ? .perto : .ok
    return ItemOrcamento(id: id, previsto: previsto, gasto: gasto, pct: pct, sobra: previsto - gasto, nivel: nivel)
}

private func positivoFinito(_ v: ValorJSON?) -> Double? {
    guard let n = v?.comoNumero, n.isFinite, n > 0 else { return nil }
    return n
}

/// `orcamentoObra` do calc.js; nil sem orçamento válido.
public func orcamentoObra(_ obra: Obra) -> ResumoOrcamento? {
    guard let orc = obra.orcamento?.comoObjeto else { return nil }
    if orc["modo"] == .texto("topicos") {
        let previstos = orc["topicos"]?.comoObjeto ?? [:]
        let ids = previstos.keys.filter { positivoFinito(previstos[$0]) != nil }
        if ids.isEmpty { return nil }
        var porTopico: [String: Double] = [:]
        for g in obra.gastos { porTopico[g.topico] = (porTopico[g.topico] ?? 0) + g.valor }
        let topicos = ids.map { itemOrcamento($0, gasto: porTopico[$0] ?? 0, previsto: positivoFinito(previstos[$0])!) }
            .sorted { a, b in
                let d = b.gasto / b.previsto - a.gasto / a.previsto
                if d != 0 && !d.isNaN { return d < 0 }
                return menorJS(a.id!, b.id!)
            }
        let fora = porTopico.keys.filter { !ids.contains($0) && porTopico[$0]! > 0 }
            .map { ForaOrcamento(id: $0, gasto: porTopico[$0]!) }
            .sorted { a, b in a.gasto != b.gasto ? a.gasto > b.gasto : menorJS(a.id, b.id) }
        let previsto = topicos.reduce(0) { $0 + $1.previsto }
        let gasto = topicos.reduce(0) { $0 + $1.gasto }
        return ResumoOrcamento(modo: "topicos", geral: itemOrcamento(nil, gasto: gasto, previsto: previsto),
                               topicos: topicos, fora: fora, foraTotal: fora.reduce(0) { $0 + $1.gasto })
    }
    guard let total = positivoFinito(orc["total"]) else { return nil }
    return ResumoOrcamento(modo: "total", geral: itemOrcamento(nil, gasto: totalBruto(obra), previsto: total),
                           topicos: [], fora: [], foraTotal: 0)
}

/* Os textos do cartão e da lista por tópico, como o calc.js os escreve (moravam no app.js orcamentoHtml). */

public extension NivelOrcamento {
    /// `ORC_PILULA` do calc.js: a pílula do cartão.
    var pilula: String {
        switch self {
        case .ok: return "dentro do previsto"
        case .perto: return "perto do limite"
        case .passou: return "passou do previsto"
        }
    }
}

/// `larguraBarraOrc` do calc.js: a barra em %, de 0 a 100 (no "passou", ela para no previsto).
public func larguraBarraOrc(_ pct: Double) -> Double { max(0, min(100, pct)) }

public struct FraseDoOrcamento: Equatable, Sendable {
    public let texto: String
    /// No "passou": a frase vai na cor do alerta.
    public let alerta: Bool
}

/// `fraseTopicoOrc` do calc.js: quanto passou, quanto falta ou que chegou (meio centavo de sobra já é "chegou"); nada
/// no "dentro do previsto".
public func fraseTopicoOrc(_ t: ItemOrcamento) -> FraseDoOrcamento? {
    switch t.nivel {
    case .passou: return FraseDoOrcamento(texto: "Passou \(moedaCurtaSemZero(-t.sobra)) do previsto", alerta: true)
    case .perto:
        let pct = numeroJS(t.pct)
        let texto = t.sobra > 0.005 ? "Faltam \(moedaCurtaSemZero(t.sobra)) — \(pct)%" : "Chegou ao previsto — \(pct)%"
        return FraseDoOrcamento(texto: texto, alerta: false)
    case .ok: return nil
    }
}

public struct RodapeDoOrcamento: Equatable, Sendable {
    /// "{pct}%", antes do "usado".
    public let usado: String
    /// "sobra" ou "passou".
    public let rotulo: String
    /// O valor sem sinal.
    public let valor: String
}

/// `rodapeOrc` do calc.js: "{pct}% usado" e "sobra" ou "passou" com o valor sem sinal.
public func rodapeOrc(_ r: ItemOrcamento) -> RodapeDoOrcamento {
    RodapeDoOrcamento(usado: "\(numeroJS(r.pct))%", rotulo: r.nivel == .passou ? "passou" : "sobra", valor: moeda(abs(r.sobra)))
}

public struct LinhaDoTopicoOrc: Equatable, Sendable {
    public let gasto: String
    /// Sem o "R$".
    public let previsto: String
}

/// `linhaTopicoOrc` do calc.js: "{gasto} / {previsto}", o previsto sem o "R$" (com o espaço comum ou o duro do `money`).
public func linhaTopicoOrc(_ t: ItemOrcamento) -> LinhaDoTopicoOrc {
    var previsto = moedaCurtaSemZero(t.previsto)
    for prefixo in ["R$ ", "R$\u{00A0}"] where previsto.hasPrefix(prefixo) {
        previsto.removeFirst(prefixo.count)
        break
    }
    return LinhaDoTopicoOrc(gasto: moedaCurtaSemZero(t.gasto), previsto: previsto)
}
