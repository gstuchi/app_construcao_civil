import Foundation

/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio): os grupos, o fim, a linha da correção e a
   soma da seleção. Conferido pelos vetores do site (RelatorioTests). */

/// Um gasto do relatório, com o corrigido até o fim da correção.
public struct ItemDoRelatorio: Equatable, Sendable {
    public let gasto: Gasto
    public let corrigido: Double
}

/// Um tópico do relatório: os gastos por data, o bruto e o corrigido.
public struct GrupoDoRelatorio: Equatable, Sendable {
    public let topico: String
    public let itens: [ItemDoRelatorio]
    public let bruto: Double
    public let corrigido: Double
}

public struct RelatorioDaObra: Equatable, Sendable {
    /// Até onde a correção vai: a data da venda, ou hoje.
    public let fim: String
    public let grupos: [GrupoDoRelatorio]
    public let totalBruto: Double
    public let totalCorrigido: Double
}

/// `relatorioObra` do calc.js. Um grupo por tópico, do maior bruto para o menor (no empate, o tópico que aparece primeiro nos
/// gastos); no grupo, os gastos por data (na mesma data, a ordem do documento), cada um com o corrigido até o fim; o bruto e
/// o corrigido do grupo somam os gastos na ordem do documento, não na das datas. E os totais da obra.
public func relatorioObra(_ obra: Obra, hoje: String, taxa: Double) -> RelatorioDaObra {
    let fim = fimCorrecao(obra, hoje: hoje)
    var topicos: [String] = []
    var porTopico: [String: [Gasto]] = [:]
    for g in obra.gastos {
        if porTopico[g.topico] == nil { topicos.append(g.topico) }
        porTopico[g.topico, default: []].append(g)
    }
    let grupos = topicos.map { topico in
        let gs = porTopico[topico] ?? []
        let itens = ordenadoEstavel(gs) { menorJS($0.data, $1.data) }
            .map { ItemDoRelatorio(gasto: $0, corrigido: corrigido($0.valor, de: $0.data, ate: fim, taxa: taxa)) }
        return GrupoDoRelatorio(topico: topico, itens: itens, bruto: gs.reduce(0) { $0 + $1.valor },
                                corrigido: gs.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxa) })
    }
    return RelatorioDaObra(fim: fim, grupos: ordenadoEstavel(grupos) { $0.bruto > $1.bruto },
                           totalBruto: totalBruto(obra), totalCorrigido: totalCorrigido(obra, taxa: taxa, hoje: hoje))
}

/// O fim do relatório.
public enum FimDoRelatorio: Equatable, Sendable {
    /// Na obra vendida: a venda, o lucro bruto (venda − gasto) e o acima do banco (venda − corrigido até a venda).
    case venda(valor: Double, data: String, lucroBruto: Double, acimaDoBanco: Double)
    /// Com venda estimada: a estimada e a margem (a estimada menos o corrigido até hoje).
    case estimada(valor: Double, margem: Double)
}

/// `fimRelatorio` do calc.js: nil sem venda e sem venda estimada (a estimada zero não conta, como no site).
public func fimRelatorio(_ obra: Obra, hoje: String, taxa: Double) -> FimDoRelatorio? {
    if let venda = obra.venda, let lucro = lucroVenda(obra, taxa: taxa) {
        return .venda(valor: venda.valor, data: venda.data, lucroBruto: lucro.bruto, acimaDoBanco: lucro.vsBanco)
    }
    if let estimada = obra.valorEstimadoVenda, estimada != 0 {
        return .estimada(valor: estimada, margem: estimada - totalCorrigido(obra, taxa: taxa, hoje: hoje))
    }
    return nil
}

/// `linhaCorrecao` do calc.js: "Correção de 1,5% ao mês, da data de cada gasto até a venda (20/05/26)." ou "… até hoje (…).".
public func linhaCorrecao(_ obra: Obra, hoje: String, taxa: Double) -> String {
    let ate = obra.venda.map { "a venda (\(dataCurta($0.data)))" } ?? "hoje (\(dataCurta(hoje)))"
    return "Correção de \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))% ao mês, da data de cada gasto até \(ate)."
}

/// A soma da seleção do relatório (e a dos achados da busca).
public struct SomaDaSelecao: Equatable, Sendable {
    /// "1 item" ou "N itens".
    public let quantos: String
    public let bruto: Double
    public let corrigido: Double
    /// A parte do total bruto da obra, com 2 casas ("4,20%"), ou "0%" com o total zero.
    public let parte: String
}

/// `somaSelecao` do calc.js: os itens na ordem do relatório (a soma em ponto flutuante segue essa ordem).
public func somaSelecao(_ itens: [ItemDoRelatorio], totalBruto: Double) -> SomaDaSelecao {
    let bruto = itens.reduce(0) { $0 + $1.gasto.valor }
    return SomaDaSelecao(quantos: "\(itens.count) \(itens.count == 1 ? "item" : "itens")", bruto: bruto,
                         corrigido: itens.reduce(0) { $0 + $1.corrigido },
                         parte: totalBruto > 0 ? duasCasasPtBR(bruto / totalBruto * 100) + "%" : "0%")
}

/// `x.toLocaleString('pt-BR', {minimumFractionDigits: 2, maximumFractionDigits: 2})`: os dígitos e o arredondamento do
/// `moeda` (o mesmo formatador do ICU), sem o "R$ ".
func duasCasasPtBR(_ x: Double) -> String { moeda(x).replacingOccurrences(of: "R$\u{00A0}", with: "") }
