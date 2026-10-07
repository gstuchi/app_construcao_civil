import Foundation

public struct ParcelaGerada: Equatable, Sendable {
    public let valor: Double
    public let data: String
}

/// `gerarParcelas` do calc.js: divide em centavos; o resto do arredondamento fica na última.
/// Vazio se o total não tem centavo positivo ou se há mais parcelas que centavos.
public func gerarParcelas(_ total: Double, _ n: Int, _ dataISO: String) -> [ParcelaGerada] {
    let centavos = arredondarJS(total * 100)
    guard centavos.isFinite, centavos > 0, n >= 1, Double(n) <= centavos else { return [] }
    let base = (centavos / Double(n)).rounded(.down)
    return (0..<n).map { i in
        ParcelaGerada(valor: (i == n - 1 ? centavos - base * Double(n - 1) : base) / 100,
                      data: addMesesClampado(dataISO, i))
    }
}

public struct Parcelamento: Equatable, Sendable {
    public let valorCompra: Double
    public let taxaMensal: Double
    public let nParcelas: Int
    public let totalCompra: Double
    public let jurosCompra: Double
    public let parcelas: [ParcelaGerada]
}

/// `parcelamentoCartao` do calc.js: prestação Price com primeiro vencimento em dataISO,
/// total arredondado ao centavo e parcelas iguais (a última absorve o resto).
public func parcelamentoCartao(_ valor: Double, _ n: Int, _ taxaMensal: Double, _ dataISO: String) -> Parcelamento? {
    guard valor.isFinite, valor > 0, (1...36).contains(n), taxaMensal.isFinite, taxaMensal >= 0, taxaMensal <= 100,
          dataISOValida(dataISO) else { return nil }
    let base = arredondarJS(valor * 100) / 100
    let i = taxaMensal / 100
    // expm1 e log1p, na fórmula do calc.js. A libm e o V8 podem diferir em 1 ulp aqui (decisão "Parcelamento Price").
    let prestacao = i == 0 ? base / Double(n) : base * i / (-expm1(-Double(n) * log1p(i)))
    let total = arredondarJS(prestacao * Double(n) * 100) / 100
    let centavos = arredondarJS(total * 100)
    guard centavos.isFinite, abs(centavos) <= 9_007_199_254_740_991 else { return nil }
    let parcelas = gerarParcelas(total, n, dataISO)
    if parcelas.isEmpty { return nil }
    return Parcelamento(valorCompra: base, taxaMensal: taxaMensal, nParcelas: n, totalCompra: total,
                        jurosCompra: arredondarJS((total - base) * 100) / 100, parcelas: parcelas)
}
