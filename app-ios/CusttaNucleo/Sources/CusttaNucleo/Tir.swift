import Foundation

/// `tirMensal` do calc.js, em % ao mês: bisseção de 100 passos entre −99% e +1000%.
/// nil sem venda, sem gastos, sem tempo passado ou com a raiz fora do intervalo.
/// Gasto depois do alvo conta como pago nele (diasEntre não fica negativo).
public func tirMensal(_ gastos: [Gasto], venda: Double, alvo: String) -> Double? {
    guard venda > 0, !gastos.isEmpty else { return nil }
    let fluxos = gastos.map { (valor: $0.valor, meses: Double(diasEntre($0.data, alvo)) / diasMes) }
    guard fluxos.contains(where: { $0.meses > 0 }) else { return nil }
    func saldo(_ r: Double) -> Double { venda - fluxos.reduce(0) { $0 + $1.valor * pow(1 + r, $1.meses) } }
    var baixo = -0.99, alto = 10.0
    if saldo(baixo) < 0 || saldo(alto) > 0 { return nil }
    for _ in 0..<100 {
        let meio = (baixo + alto) / 2
        if saldo(meio) > 0 { baixo = meio } else { alto = meio }
    }
    return (baixo + alto) / 2 * 100
}

/// `rendimentoAcima` do calc.js: quanto a TIR rende ao mês acima do banco, composto.
public func rendimentoAcima(_ tir: Double?, taxa: Double) -> Double? {
    guard let tir else { return nil }
    return ((1 + tir / 100) / (1 + taxa / 100) - 1) * 100
}

public struct ResumoVenda: Equatable, Sendable {
    public let lucro: Double?
    public let pctCusto: Double?
    public let pctVenda: Double?
}

/// `resumoVenda` do calc.js: lucro, % sobre o custo e % sobre a venda numa base de custo.
public func resumoVenda(_ venda: Double, custo: Double) -> ResumoVenda {
    if venda <= 0 || custo <= 0 { return ResumoVenda(lucro: nil, pctCusto: nil, pctVenda: nil) }
    return ResumoVenda(lucro: venda - custo, pctCusto: (venda / custo - 1) * 100, pctVenda: (venda - custo) / venda * 100)
}
