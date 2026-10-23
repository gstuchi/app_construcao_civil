import Foundation

/* Regras das telas da etapa 3 (dentro da obra) que o site não tem: o mockup aprovado em 18/10 as acrescenta ao que vem do
   app.js. Os números saem das regras com vetor (orcamentoObra, aPagar, resumoTopico); o que está aqui é
   texto e agrupamento, com teste próprio (DentroDaObraTests). */

/* ---------- orçamento: a linha nos indicadores e o cartão da tela Orçamento ---------- */

/// O pior aviso dos tópicos, embaixo da linha do orçamento (modo por tópico): "2 tópicos passaram do previsto" ou, sem
/// nenhum, "N perto do limite"; nil quando todos estão dentro.
public func avisoDosTopicos(_ r: ResumoOrcamento) -> String? {
    let passaram = r.topicos.filter { $0.nivel == .passou }.count
    let perto = r.topicos.filter { $0.nivel == .perto }.count
    if passaram > 0 { return "\(passaram) tópico\(passaram > 1 ? "s passaram" : " passou") do previsto" }
    if perto > 0 { return "\(perto) tópico\(perto > 1 ? "s" : "") perto do limite" }
    return nil
}

/// "R$ 30 mil fora do orçamento", na linha, quando há gasto em tópico sem previsto (modo por tópico).
public func foraNaLinha(_ r: ResumoOrcamento) -> String? {
    guard r.modo == "topicos", r.foraTotal > 0 else { return nil }
    return moedaCurtaSemZero(r.foraTotal) + " fora do orçamento"
}

/// "80% usado de R$ 1.019.847,85", embaixo da barra da linha.
public func usadoDoPrevisto(_ geral: ItemOrcamento) -> String {
    "\(numeroJS(geral.pct))% usado de \(moeda(geral.previsto))"
}

/// "Orçamento por tópico" ou "Orçamento total", no alto do cartão.
public func tituloDoCartao(_ r: ResumoOrcamento) -> String {
    r.modo == "topicos" ? "Orçamento por tópico" : "Orçamento total"
}

/// "de R$ 1.019.847,85 previstos em 14 tópicos" (no modo total, só o "de R$ …" do site): o cartão por tópico soma só os
/// tópicos previstos e não fecha com o Total gasto (achado 10).
public func previstoDoCartao(_ r: ResumoOrcamento) -> String {
    let de = "de \(moeda(r.geral.previsto))"
    guard r.modo == "topicos" else { return de }
    let n = r.topicos.count
    return de + " previstos em \(n) tópico\(n == 1 ? "" : "s")"
}

/// "Os R$ 29.780,50 fora do orçamento não entram nesta conta.", no fim do cartão por tópico com gasto fora.
public func fraseDoForaNoCartao(_ r: ResumoOrcamento) -> String? {
    guard r.modo == "topicos", r.foraTotal > 0 else { return nil }
    return "Os \(moeda(r.foraTotal)) fora do orçamento não entram nesta conta."
}

/// Um tópico do "Gasto por tópico" da tela Orçamento no modo total.
public struct GastoDoTopico: Equatable, Sendable, Identifiable {
    public let id: String
    public let bruto: Double
    /// O "% da obra" do resumo do tópico (o arredondamento do donut).
    public let pct: Double
}

/// O "Gasto por tópico" do modo total: cada tópico com gasto, com o bruto e o "% da obra" do resumo do tópico, para o número
/// ser o mesmo que o detalhe mostra ao abrir. A ordem é a da legenda do donut do site (renderObra do app.js,
/// `Object.entries(byTop).sort((a,b)=>b[1]-a[1])`): do maior bruto para o menor e, no empate, o tópico que aparece primeiro
/// nos gastos, porque o byTop nasce na ordem dos gastos e o sort do JavaScript é estável.
public func gastoPorTopico(_ obra: Obra, hoje: String, taxaMensal: Double) -> [GastoDoTopico] {
    var ids: [String] = []
    for g in obra.gastos where !ids.contains(g.topico) { ids.append(g.topico) }
    let linhas = ids.map { id in
        let r = resumoTopico(obra, topico: id, hoje: hoje, taxaMensal: taxaMensal)
        return GastoDoTopico(id: id, bruto: r.bruto, pct: r.pct)
    }
    return ordenadoEstavel(linhas) { $0.bruto > $1.bruto }
}

/// "38% da obra".
public func textoDaParteDaObra(_ pct: Double) -> String { "\(numeroJS(pct))% da obra" }

/// A dica do fim da tela Orçamento no modo total.
public let dicaDoModoTotal = "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\"."

/// "N de M tópicos com valor", na linha do total da folha por tópico.
public func topicosComValor(_ valores: [String: Double], de total: Int) -> String {
    "\(valores.values.filter { $0 > 0 }.count) de \(total) tópicos com valor"
}

/* ---------- A pagar · 30 dias ---------- */

/// A folha "A pagar · 30 dias" de uma obra: os vencimentos do indicador por mês e o que vem depois dos 30 dias.
public struct APagarDaObra: Equatable, Sendable {
    public let total: Double
    public let qtd: Int
    /// Por mês, do mais próximo ao mais distante; dentro do mês, a ordem do `aPagar` (por data).
    public let meses: [MesDeGastos]
    /// Os gastos a vencer depois de hoje + 30 dias: estão no "A vencer" da obra, não na folha.
    public let depoisQtd: Int
    public let depoisTotal: Double
    /// "Depois de 11/11/26, mais 10 gastos a vencer (R$ 52.250,00), no "A vencer" da obra."; nil sem nada depois.
    public let ponte: String?
}

public func aPagarDaObra(_ obra: Obra, hoje: String) -> APagarDaObra {
    let vencimentos = aPagar([obra], hoje: hoje)
    let limite = somarDias(hoje, 30)
    let depois = obra.gastos.filter { menorJS(limite, $0.data) }
    let total = depois.reduce(0) { $0 + $1.valor }
    let ponte = depois.isEmpty ? nil
        : "Depois de \(dataCurta(limite)), mais \(depois.count) gasto\(depois.count == 1 ? "" : "s") a vencer (\(moeda(total))), no \"A vencer\" da obra."
    return APagarDaObra(total: vencimentos.total, qtd: vencimentos.qtd, meses: porMes(vencimentos.itens.map(\.gasto)),
                        depoisQtd: depois.count, depoisTotal: total, ponte: ponte)
}

/* ---------- detalhe do tópico ---------- */

/// A linha do orçamento dentro do detalhe do tópico.
public enum OrcamentoDoTopico: Equatable, Sendable {
    /// A obra não tem orçamento por tópico (sem orçamento, ou só o total): nada no lugar da barra.
    case nenhum
    /// O tópico tem previsto: `rotuloNoOrcamento`, o valor, a barra e `fraseDoOrcamentoNoDetalhe`.
    case previsto(ItemOrcamento)
    /// Por tópico, mas sem valor para este: `semValorNoOrcamento` no lugar da barra.
    case semValor
}

public let semValorNoOrcamento = "Sem valor no orçamento: não entra na comparação."

/// Antes do previsto, em moeda cheia.
public let rotuloNoOrcamento = "No orçamento"

/// A frase embaixo da barra: a do site ("Passou R$ 6,2 mil do previsto", no alerta; "Faltam R$ 3,3 mil — 96%"; "Chegou ao
/// previsto — 100%") ou, no nível ok, que o site deixa sem frase, "{pct}% usado".
public func fraseDoOrcamentoNoDetalhe(_ item: ItemOrcamento) -> FraseDoOrcamento {
    fraseTopicoOrc(item) ?? FraseDoOrcamento(texto: rodapeOrc(item).usado + " usado", alerta: false)
}

/// A folha do detalhe do tópico.
public struct DetalheDoTopico: Equatable, Sendable {
    public let resumo: ResumoDoTopico
    /// "6 gastos · 12% da obra".
    public let linha: String
    /// "corrigido: R$ …".
    public let corrigido: String
    public let orcamento: OrcamentoDoTopico
    /// Os de data depois de hoje, o próximo primeiro (como o "A vencer" da obra).
    public let aVencer: [Gasto]
    /// Os outros, do mais novo para o mais antigo (data e id, como o site).
    public let pagos: [Gasto]
}

public func detalheDoTopico(_ obra: Obra, topico: String, hoje: String, taxaMensal: Double) -> DetalheDoTopico {
    let r = resumoTopico(obra, topico: topico, hoje: hoje, taxaMensal: taxaMensal)
    let ordenados = ordenadoEstavel(obra.gastos.filter { $0.topico == topico }) { menorJS($1.data + $1.id, $0.data + $0.id) }
    let orcamento: OrcamentoDoTopico
    if let o = orcamentoObra(obra), o.modo == "topicos" {
        orcamento = o.topicos.first { $0.id == topico }.map(OrcamentoDoTopico.previsto) ?? .semValor
    } else {
        orcamento = .nenhum
    }
    return DetalheDoTopico(resumo: r, linha: "\(r.qtd) gasto\(r.qtd == 1 ? "" : "s") · \(textoDaParteDaObra(r.pct))",
                           corrigido: "corrigido: " + moeda(r.corrigido), orcamento: orcamento,
                           aVencer: ordenados.filter { menorJS(hoje, $0.data) }.reversed(),
                           pagos: ordenados.filter { !menorJS(hoje, $0.data) })
}
