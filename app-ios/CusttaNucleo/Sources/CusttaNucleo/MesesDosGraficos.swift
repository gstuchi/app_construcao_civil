import Foundation

/* O mês dos gráficos de mês e o que vai em volta deles: regra do app, sem vetor do site (spec da etapa 4, "Regras novas do
   app" e confirmação 2). O site escolhe o último mês com gasto, que pode ser um mês a vencer, e não tem as frases nem a
   média. Tudo depende de hoje, que entra por parâmetro: a virada do mês troca o mês de referência. */

/// O mês de referência dos Gráficos (AAAA-MM): o da venda, na obra vendida; senão, este mês. É o mês do fim da correção.
public func mesDeReferencia(_ obra: Obra, hoje: String) -> String { String(fimCorrecao(obra, hoje: hoje).prefix(7)) }

/// O mês escolhido por padrão no gasto por mês: o de referência; fora da série, o último com gasto (o que o mockup faz).
/// nil sem série.
public func mesPadraoDoGastoPorMes(_ serie: [PontoMensal], referencia: String) -> Int? {
    if serie.isEmpty { return nil }
    return serie.firstIndex { $0.mes == referencia } ?? serie.lastIndex { $0.total > 0 } ?? 0
}

/// O mês a vencer do gasto por mês (tracejado e hachurado): depois do mês de referência. O mês de referência conta
/// inteiro, como pago, mesmo com parcela que ainda vence nele.
public func mesAVencer(_ mes: String, referencia: String) -> Bool { menorJS(referencia, mes) }

private func vendida(_ obra: Obra) -> Bool { !(obra.venda?.data ?? "").isEmpty }

/// O bruto dos gastos de data depois do fim da correção (hoje, ou a venda), na ordem do documento: o que a evolução, que
/// para no fim da correção, deixa de fora.
public func foraDaEvolucao(_ obra: Obra, hoje: String) -> Double {
    let fim = fimCorrecao(obra, hoje: hoje)
    return obra.gastos.filter { menorJS(fim, $0.data) }.reduce(0) { $0 + $1.valor }
}

/// A frase embaixo da evolução: "Fora do gráfico: R$ … a vencer (depois de hoje)." ou, na vendida, "Fora do gráfico: R$ …
/// com data depois da venda."; nil sem nada fora.
public func fraseForaDaEvolucao(_ obra: Obra, hoje: String) -> String? {
    let fora = foraDaEvolucao(obra, hoje: hoje)
    if fora <= 0.005 { return nil }
    return "Fora do gráfico: \(moeda(fora)) " + (vendida(obra) ? "com data depois da venda." : "a vencer (depois de hoje).")
}

/// A frase embaixo do anel, que soma as parcelas a vencer: "Inclui R$ … a vencer."; nil sem nada a vencer e na vendida.
public func fraseAVencerDoAnel(_ obra: Obra, hoje: String) -> String? {
    if vendida(obra) { return nil }
    let fora = foraDaEvolucao(obra, hoje: hoje)
    return fora > 0.005 ? "Inclui \(moeda(fora)) a vencer." : nil
}

/// O aviso embaixo do gráfico cuja série passou de 24 meses e mostra só os últimos 24.
public let avisoDos24Meses = "Mostrando os últimos 24 meses."

/// Quantos meses vão de `de` a `ate` (AAAA-MM), os dois incluídos.
func mesesEntre(_ de: String, _ ate: String) -> Int {
    let (a1, m1) = anoMes(de), (a2, m2) = anoMes(ate)
    return (a2 - a1) * 12 + m2 - m1 + 1
}

/// O gasto por mês (`serieMensal`, do mês do 1º gasto ao do último) passou de 24 meses e foi cortado.
public func gastoPorMesFoiCortado(_ gastos: [Gasto]) -> Bool {
    let meses = gastos.map { String($0.data.prefix(7)) }.sorted(by: menorJS)
    guard let primeiro = meses.first, let ultimo = meses.last else { return false }
    return mesesEntre(primeiro, ultimo) > 24
}

/// A evolução (`serieEvolucao`, do mês do 1º gasto ao do fim da correção) passou de 24 meses e foi cortada. Na obra parada
/// há tempo, ela é cortada e o gasto por mês, não.
public func evolucaoFoiCortada(_ obra: Obra, hoje: String) -> Bool {
    guard let primeiro = obra.gastos.map({ String($0.data.prefix(7)) }).min(by: menorJS) else { return false }
    let fim = mesDeReferencia(obra, hoje: hoje)
    return mesesEntre(primeiro, menorJS(primeiro, fim) ? fim : primeiro) > 24
}

/// Um dos números embaixo do gasto por mês.
public struct NumeroDoResumo: Equatable, Sendable {
    public let rotulo: String
    public let valor: String
}

/// A média, o maior e os meses embaixo do gasto por mês.
public struct ResumoDosMeses: Equatable, Sendable {
    /// A soma dos meses ÷ os meses; 0 sem meses.
    public let media: Double
    /// O mês de maior bruto; no empate, o primeiro. nil sem meses.
    public let maior: PontoMensal?
    public let meses: Int

    /// "Média por mês", "Maior · mai" e "Meses", com os valores no `moedaCurta`, como o mockup.
    public var numeros: [NumeroDoResumo] {
        [NumeroDoResumo(rotulo: "Média por mês", valor: moedaCurta(media)),
         NumeroDoResumo(rotulo: maior.map { "Maior · " + mesAbreviado($0.mes, comAno: false) } ?? "Maior",
                        valor: maior.map { moedaCurta($0.total) } ?? "—"),
         NumeroDoResumo(rotulo: "Meses", valor: "\(meses)")]
    }
}

/// A conta da confirmação 2 do spec: do mês do 1º gasto ao mês de referência, com os meses zerados e sem os meses a vencer;
/// o mês de referência conta inteiro. Com o 1º gasto depois do mês de referência, nenhum mês.
public func resumoDosMeses(_ obra: Obra, hoje: String) -> ResumoDosMeses {
    let referencia = mesDeReferencia(obra, hoje: hoje)
    var porMes: [String: Double] = [:]
    for g in obra.gastos { porMes[String(g.data.prefix(7)), default: 0] += g.valor }
    guard let primeiro = porMes.keys.min(by: menorJS), !menorJS(referencia, primeiro) else {
        return ResumoDosMeses(media: 0, maior: nil, meses: 0)
    }
    var (ano, mes) = anoMes(primeiro)
    let pontos = (0..<mesesEntre(primeiro, referencia)).map { _ in
        defer { mes += 1; if mes > 12 { mes = 1; ano += 1 } }
        return PontoMensal(mes: chaveMes(ano, mes), total: porMes[chaveMes(ano, mes)] ?? 0)
    }
    let maior = pontos.dropFirst().reduce(pontos[0]) { $1.total > $0.total ? $1 : $0 }
    return ResumoDosMeses(media: pontos.reduce(0) { $0 + $1.total } / Double(pontos.count), maior: maior, meses: pontos.count)
}
