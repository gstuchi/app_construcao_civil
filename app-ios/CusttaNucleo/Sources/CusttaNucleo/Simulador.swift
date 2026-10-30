import Foundation

/* O "Vale a pena?", como o calc.js o calcula e escreve (morava no app.js simulaCompute). Conferido pelos vetores do site
   (SimuladorTests). */

/// `MESES_SIMULADOR` do calc.js: os meses da venda vão de 0 a 120 na conta.
public let mesesSimulador = 120

public struct ContaDoSimulador: Equatable, Sendable {
    public let venda: Double
    /// Os meses da conta, entre 0 e 120.
    public let meses: Int
    /// Hoje mais os meses (`addMesesClampado`).
    public let alvo: String
    public let bruto: Double
    /// Corrigido até o alvo.
    public let corrigido: Double
    /// Menos de 1 mês de obra até o alvo: fica sem taxa.
    public let novaDemais: Bool
    /// A TIR, em % ao mês; nil sem taxa.
    public let tir: Double?
    public let acima: Double?
    /// A venda passa do corrigido.
    public let vale: Bool
    /// TIR ÷ taxa; 0 sem TIR.
    public let multiplicador: Double
}

/// `contaSimulador` do calc.js: vender a obra por `venda` daqui a `meses`, sem gasto novo até lá; nil sem preço.
public func contaSimulador(_ obra: Obra, venda: Double, meses: Int, hoje: String, taxa: Double) -> ContaDoSimulador? {
    if venda <= 0 { return nil }
    let m = min(mesesSimulador, max(0, meses))
    let alvo = addMesesClampado(hoje, m)
    let corrigido = totalCorrigido(obra, taxa: taxa, hoje: alvo)
    let novaDemais = mesesDeObra(obra, hoje: alvo) < 1
    let tir = novaDemais ? nil : tirMensal(obra.gastos, venda: venda, alvo: alvo)
    return ContaDoSimulador(venda: venda, meses: m, alvo: alvo, bruto: totalBruto(obra), corrigido: corrigido, novaDemais: novaDemais,
                            tir: tir, acima: rendimentoAcima(tir, taxa: taxa), vale: venda > corrigido,
                            multiplicador: tir.map { taxa > 0 ? $0 / taxa : 0 } ?? 0)
}

/// A cor de um número da tabela, pelo sinal.
public enum SinalDaSimulacao: String, Sendable {
    case positivo, negativo
}

public struct LinhaDaSimulacao: Equatable, Sendable {
    public let rotulo: String
    /// Pelo bruto.
    public let bruto: String
    /// Pelo corrigido.
    public let corrigido: String
    /// Só no lucro e nas duas porcentagens; nil sem valor.
    public let sinalBruto: SinalDaSimulacao?
    public let sinalCorrigido: SinalDaSimulacao?
    /// A linha do lucro.
    public let destaque: Bool
}

public struct TextosDoSimulador: Equatable, Sendable {
    /// "Vale a pena" ou "Rende menos que o banco".
    public let veredito: String
    /// "8,63% ao mês" ou "—".
    public let taxa: String
    /// "vendendo hoje", "banco paga 1%", "rende 8,6× o banco" e o aviso da obra com menos de 1 mês (o site junta com " · ").
    public let detalhes: [String]
    public let tabela: [LinhaDaSimulacao]
}

/// `textosSimulador` do calc.js: o cartão e a tabela da simulação. O R$/m² só com área.
public func textosSimulador(_ conta: ContaDoSimulador, taxa: Double, area: Double?) -> TextosDoSimulador {
    func virgula(_ v: Double, _ casas: Int) -> String { toFixedJS(v, casas).replacingOccurrences(of: ".", with: ",") }
    func din(_ v: Double?) -> String { v.map { moeda($0) } ?? "—" }
    func pct1(_ v: Double?) -> String { v.map { virgula($0, 1) + "%" } ?? "—" }
    func taxa2(_ v: Double?) -> String { v.map { virgula($0, 2) + "% a.m." } ?? "—" }
    func sinal(_ v: Double?) -> SinalDaSimulacao? { v.map { $0 >= 0 ? .positivo : .negativo } }
    func linha(_ rotulo: String, _ bruto: String, _ corrigido: String, sinais: (Double?, Double?)? = nil,
               destaque: Bool = false) -> LinhaDaSimulacao {
        LinhaDaSimulacao(rotulo: rotulo, bruto: bruto, corrigido: corrigido, sinalBruto: sinais.flatMap { sinal($0.0) },
                         sinalCorrigido: sinais.flatMap { sinal($0.1) }, destaque: destaque)
    }
    let rb = resumoVenda(conta.venda, custo: conta.bruto)
    let rc = resumoVenda(conta.venda, custo: conta.corrigido)
    var detalhes = [conta.meses == 0 ? "vendendo hoje" : "vendendo daqui a \(conta.meses) \(conta.meses == 1 ? "mês" : "meses")",
                    "banco paga \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))%"]
    if conta.tir != nil && conta.multiplicador >= 1 { detalhes.append("rende \(virgula(conta.multiplicador, 1))× o banco") }
    if conta.novaDemais { detalhes.append("obra com menos de 1 mês — % ao mês ainda não diz muito") }
    var tabela = [
        linha("Custo até a venda", moeda(conta.bruto), moeda(conta.corrigido)),
        linha("Venda", moeda(conta.venda), moeda(conta.venda)),
        linha("Lucro", din(rb.lucro), din(rc.lucro), sinais: (rb.lucro, rc.lucro), destaque: true),
        linha("% sobre o custo", pct1(rb.pctCusto), pct1(rc.pctCusto), sinais: (rb.pctCusto, rc.pctCusto)),
        linha("% sobre a venda", pct1(rb.pctVenda), pct1(rc.pctVenda), sinais: (rb.pctVenda, rc.pctVenda)),
        linha("Rendimento ao mês", taxa2(conta.tir), taxa2(conta.acima)),
    ]
    if let area, area > 0 {
        tabela.append(linha("Preço por m² (\(numeroJS(area).replacingOccurrences(of: ".", with: ",")) m²)", moeda(conta.venda / area),
                            moeda(conta.venda / area)))
    }
    return TextosDoSimulador(veredito: conta.vale ? "Vale a pena" : "Rende menos que o banco",
                             taxa: conta.tir.map { virgula($0, 2) + "% ao mês" } ?? "—", detalhes: detalhes, tabela: tabela)
}
