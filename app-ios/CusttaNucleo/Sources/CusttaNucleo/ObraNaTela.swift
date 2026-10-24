import Foundation

/* Regras da tela da obra: os textos do renderObra e do gastoRow do app.js, com o desenho aprovado na etapa 2 (lista
   por mês com o total, "A vencer" agrupado no alto, valor sem vermelho, "Pix" e "Cartão" por extenso e a linha sem
   descrição sem repetir o tópico). Os números vêm das funções do calc.js que já têm vetor (totalBruto, totalCorrigido,
   aPagar, lucroVenda, precoPorM2, mesesDeObra); o agrupamento é do app e tem teste próprio. */

let nomesDosMeses = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro",
                     "novembro", "dezembro"]

/// "dd/mm/aa", o `fmtData` do app.js.
public func dataCurta(_ iso: String) -> String {
    guard let c = componentesISO(iso) else { return iso }
    let ano = String(c.ano)
    return doisDigitos(c.dia) + "/" + doisDigitos(c.mes) + "/" + String(ano.suffix(2))
}

/// "10 de outubro de 2026", para o VoiceOver.
public func dataPorExtenso(_ iso: String) -> String {
    guard let c = componentesISO(iso) else { return iso }
    return "\(c.dia) de \(nomesDosMeses[c.mes - 1]) de \(c.ano)"
}

/// "Outubro de 2026", do mês AAAA-MM.
public func tituloDoMes(_ mes: String) -> String {
    guard let c = componentesISO(mes + "-01") else { return mes }
    let nome = nomesDosMeses[c.mes - 1]
    return nome.prefix(1).uppercased() + nome.dropFirst() + " de \(c.ano)"
}

/// "começou em 12/08/25 · 14 meses", a linha de baixo do cabeçalho da obra.
public func textoDoInicio(_ obra: Obra, hoje: String) -> String {
    "começou em \(dataCurta(obra.dataInicio)) · \(fmtMeses(mesesDeObra(obra, hoje: hoje)))"
}

/// Os gastos de um mês, com o total dele.
public struct MesDeGastos: Equatable, Sendable, Identifiable {
    /// AAAA-MM.
    public let id: String
    public let titulo: String
    public let total: Double
    public let gastos: [Gasto]
}

/// O "A vencer": os gastos com data depois de hoje (parcelas futuras e gastos agendados), fechado no alto da lista.
public struct GrupoAVencer: Equatable, Sendable {
    public let total: Double
    /// Por mês, do mais próximo para o mais distante; dentro do mês, por data.
    public let meses: [MesDeGastos]

    public var quantidade: Int { meses.reduce(0) { $0 + $1.gastos.count } }
    /// A data do próximo vencimento.
    public var proximo: String { meses.first?.gastos.first?.data ?? "" }
    /// "13 gastos · o próximo é em 15/10/26".
    public var resumo: String {
        "\(quantidade) \(quantidade == 1 ? "gasto" : "gastos") · o próximo é em \(dataCurta(proximo))"
    }
}

/// A lista de gastos da obra: o "A vencer" (se houver) e os meses, do mais recente para o mais antigo.
public struct ListaDaObra: Equatable, Sendable {
    public let aVencer: GrupoAVencer?
    public let meses: [MesDeGastos]
}

func porMes(_ gastos: [Gasto]) -> [MesDeGastos] {
    var ordem: [String] = []
    var grupos: [String: [Gasto]] = [:]
    for g in gastos {
        let mes = String(g.data.prefix(7))
        if grupos[mes] == nil { ordem.append(mes) }
        grupos[mes, default: []].append(g)
    }
    return ordem.map { mes in
        let lista = grupos[mes] ?? []
        return MesDeGastos(id: mes, titulo: tituloDoMes(mes), total: lista.reduce(0) { $0 + $1.valor }, gastos: lista)
    }
}

/// A lista da tela da obra. Fora do "A vencer", a ordem é a do site (data e id, do mais recente para o mais antigo);
/// no "A vencer", a contrária, para o próximo vencimento vir primeiro.
public func listaDaObra(_ obra: Obra, hoje: String) -> ListaDaObra {
    let ordenados = ordenadoEstavel(obra.gastos) { menorJS($1.data + $1.id, $0.data + $0.id) }
    let futuros = ordenados.filter { menorJS(hoje, $0.data) }
    let passados = ordenados.filter { !menorJS(hoje, $0.data) }
    let aVencer = futuros.isEmpty ? nil
        : GrupoAVencer(total: futuros.reduce(0) { $0 + $1.valor }, meses: porMes(futuros.reversed()))
    return ListaDaObra(aVencer: aVencer, meses: porMes(passados))
}

/// O que a linha de um gasto mostra e o que o VoiceOver lê.
public struct LinhaDeGasto: Equatable, Sendable {
    /// A descrição, ou o nome do tópico quando ela está vazia, com " (n/de)" na parcela.
    public let titulo: String
    /// O nome do tópico na linha de baixo; nil quando o título já é o tópico (sem descrição) e na lista de um tópico só
    /// (`comTopico: false`).
    public let topico: String?
    /// "Pix", "Cartão" ou nil (outra forma de pagamento que o site gravou).
    public let pagamento: String?
    /// "10/10/26".
    public let data: String
    /// "−R$ 4.980,00": o menos (U+2212) e o valor do site, sem vermelho.
    public let valor: String
    /// "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" (sem o valor, que vai no value).
    public let rotulo: String
    /// "R$ 4.980,00", sem o "menos".
    public let valorFalado: String
    public let icone: String
}

/// A linha do gasto. O tópico que o app não conhece (apagado em Ajustes) aparece pelo id, com o ícone etiqueta, como
/// no site. Com `comTopico: false` (o detalhe do tópico, que só lista gastos dele e já o diz no título da folha), o tópico
/// sai da linha de baixo e do VoiceOver, como o `semTopico` do mockup; sem descrição, o título continua o nome do tópico.
public func linhaDeGasto(_ g: Gasto, topicos: [String: Topico], comTopico: Bool = true) -> LinhaDeGasto {
    let topico = topicos[g.topico] ?? Topico(id: g.topico, nome: g.topico.isEmpty ? "Outros" : g.topico, icone: "etiqueta")
    let descricao = g.descricao                      // o `g.descricao || t.nm` do site: só a descrição vazia cai no tópico
    let parcela = g.parcela.map { " (\($0.n)/\($0.de))" } ?? ""
    let titulo = (descricao.isEmpty ? topico.nome : descricao) + parcela
    let pagamento: String? = g.pagamento == "pix" ? "Pix" : g.pagamento == "cartao" ? "Cartão" : nil
    let tituloFalado = (descricao.isEmpty ? topico.nome : descricao) + (g.parcela.map { ", parcela \($0.n) de \($0.de)" } ?? "")
    let embaixo = comTopico && !descricao.isEmpty ? topico.nome : nil
    let detalhes = [embaixo, pagamento, dataPorExtenso(g.data)].compactMap { $0 }
    return LinhaDeGasto(titulo: titulo, topico: embaixo, pagamento: pagamento,
                        data: dataCurta(g.data), valor: "\u{2212}" + moeda(g.valor),
                        rotulo: tituloFalado + ". " + detalhes.joined(separator: ", "), valorFalado: moeda(g.valor),
                        icone: topico.icone)
}

/// O indicador de venda, nas três situações do site.
public enum VendaNaTela: Equatable, Sendable {
    /// "Venda", "Vendida em dd/mm/aa", o valor e "lucro … · … vs banco" (verde com lucro bruto ≥ 0).
    case vendida(valor: String, etiqueta: String, nota: String, lucroPositivo: Bool)
    /// "Venda estimada", "estimativa", o valor e o R$/m² com a área (ou a margem sobre o corrigido).
    case estimada(valor: String, nota: String)
    /// "Venda estimada", "—" e "Toque no lápis para informar o valor" (no site, "cadastre no editar obra").
    case semEstimativa
}

/// Os quatro indicadores da obra (opção A do mockup: o total gasto em destaque e os outros três num cartão).
public struct IndicadoresDaObra: Equatable, Sendable {
    public let totalGasto: String
    /// "46 lançamentos", "1 lançamento" ou "sem gastos".
    public let etiquetaDoTotal: String
    public let corrigido: String
    /// "Correção até hoje: +R$ …", ou "até a venda".
    public let notaDoCorrigido: String
    public let aPagar: String
    /// "3 vencimentos", "1 vencimento" ou "nada em 30 dias".
    public let etiquetaDoAPagar: String
    public let venda: VendaNaTela
}

public func indicadoresDaObra(_ obra: Obra, taxa: Double, hoje: String) -> IndicadoresDaObra {
    let bruto = totalBruto(obra)
    let corr = totalCorrigido(obra, taxa: taxa, hoje: hoje)
    let vencimentos = aPagar([obra], hoje: hoje)
    let n = obra.gastos.count
    let venda: VendaNaTela
    if obra.fase == .vendida, let v = obra.venda, let lucro = lucroVenda(obra, taxa: taxa) {
        venda = .vendida(valor: moeda(v.valor), etiqueta: "Vendida em \(dataCurta(v.data))",
                         nota: "lucro \(moedaCurta(lucro.bruto)) · \(lucro.vsBanco >= 0 ? "+" : "")\(moedaCurta(lucro.vsBanco)) vs banco",
                         lucroPositivo: lucro.bruto >= 0)
    } else if let estimado = obra.valorEstimadoVenda, estimado != 0 {
        let nota = precoPorM2(estimado, obra.areaM2).map { "\(moedaCurta($0))/m² · \(numeroJS(obra.areaM2 ?? 0).replacingOccurrences(of: ".", with: ",")) m²" }
            ?? "margem \(moedaCurta(estimado - corr))"
        venda = .estimada(valor: moeda(estimado), nota: nota)
    } else {
        venda = .semEstimativa
    }
    return IndicadoresDaObra(
        totalGasto: moeda(bruto), etiquetaDoTotal: n == 0 ? "sem gastos" : "\(n) lançamento\(n > 1 ? "s" : "")",
        corrigido: moeda(corr), notaDoCorrigido: "Correção até \(obra.venda != nil ? "a venda" : "hoje"): +\(moeda(corr - bruto))",
        aPagar: moeda(vencimentos.total),
        etiquetaDoAPagar: vencimentos.qtd == 0 ? "nada em 30 dias" : "\(vencimentos.qtd) vencimento\(vencimentos.qtd > 1 ? "s" : "")",
        venda: venda)
}

/// O alerta de apagar um gasto (mockup aprovado, "Apagar" em tudo): "Apagar este gasto?" com o nome e o valor.
public func textoDeApagarGasto(_ linha: LinhaDeGasto) -> (titulo: String, mensagem: String) {
    ("Apagar este gasto?", "\(linha.titulo) · \(linha.valorFalado). Não dá para desfazer.")
}

/// O alerta de apagar uma parcela: só esta ou a compra toda, com o N das que restam (o site conta as irmãs que existem).
public func textoDeApagarParcela(_ linha: LinhaDeGasto, parcela: Parcela, restantes: Int)
    -> (titulo: String, mensagem: String, soEsta: String, compraToda: String) {
    (linha.titulo, "Esta parcela faz parte de uma compra em \(parcela.de)x no cartão.", "Apagar só esta parcela",
     "Apagar a compra toda (\(restantes) parcela\(restantes == 1 ? "" : "s"))")
}
