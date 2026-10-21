import Foundation

/* Correção pelo banco e lucro, como no calc.js. A ordem das operações é a mesma do JavaScript; com
   pow, o resultado em ponto flutuante sai igual ao do V8 (conferido). Não vale para expm1 e log1p
   (Parcelas.swift), que podem diferir em 1 ulp. */

/// DIAS_MES do calc.js: meses de 30,44 dias.
public let diasMes = 30.44

/// `corrigido` do calc.js: juros compostos diários de `de` até `ate` (gasto depois de `ate` fica pelo valor).
public func corrigido(_ valor: Double, de: String, ate: String, taxa: Double) -> Double {
    valor * pow(1 + taxa / 100, Double(diasEntre(de, ate)) / diasMes)
}

/// `fimCorrecao` do calc.js: a data da venda, ou hoje.
public func fimCorrecao(_ obra: Obra, hoje: String) -> String {
    if let data = obra.venda?.data, !data.isEmpty { return data }
    return hoje
}

/// `totalBruto` do calc.js (inclui parcelas a vencer).
public func totalBruto(_ obra: Obra) -> Double {
    obra.gastos.reduce(0) { $0 + $1.valor }
}

/// `totalCorrigido` do calc.js.
public func totalCorrigido(_ obra: Obra, taxa: Double, hoje: String) -> Double {
    let fim = fimCorrecao(obra, hoje: hoje)
    return obra.gastos.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxa) }
}

public struct ResumoDoTopico: Equatable, Sendable {
    public let qtd: Int
    /// Com as parcelas a vencer.
    public let bruto: Double
    /// Até a venda ou hoje.
    public let corrigido: Double
    /// Inteiro (o arredondamento da legenda do donut), guardado como Double; 0 na obra sem gasto.
    public let pct: Double
}

/// `resumoTopico` do calc.js: o resumo da folha do tópico.
public func resumoTopico(_ obra: Obra, topico: String, hoje: String, taxaMensal: Double) -> ResumoDoTopico {
    let gs = obra.gastos.filter { $0.topico == topico }
    let fim = fimCorrecao(obra, hoje: hoje)
    let bruto = gs.reduce(0) { $0 + $1.valor }
    let total = totalBruto(obra)
    return ResumoDoTopico(qtd: gs.count, bruto: bruto, corrigido: gs.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxaMensal) },
                          pct: total > 0 ? arredondarJS(bruto / total * 100) : 0)
}

public struct LucroVenda: Equatable, Sendable {
    public let bruto: Double
    public let vsBanco: Double
}

/// `lucroVenda` do calc.js: o corrigido vai até a data da venda.
public func lucroVenda(_ obra: Obra, taxa: Double) -> LucroVenda? {
    guard let venda = obra.venda else { return nil }
    return LucroVenda(bruto: venda.valor - totalBruto(obra),
                      vsBanco: venda.valor - totalCorrigido(obra, taxa: taxa, hoje: venda.data))
}

/// `mesesDeObra` do calc.js.
public func mesesDeObra(_ obra: Obra, hoje: String) -> Double {
    Double(diasEntre(obra.dataInicio, fimCorrecao(obra, hoje: hoje))) / diasMes
}

/// `precoPorM2` do calc.js.
public func precoPorM2(_ valor: Double?, _ area: Double?) -> Double? {
    guard let valor, let area, valor > 0, area > 0 else { return nil }
    return valor / area
}
