import Foundation

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra: regra do app, sem vetor do site (spec da etapa 4, "Regras
   novas do app"). O site dá uma cor por tópico e repete depois da 8ª; o app tem 6 cores e o "Outros" em cinza, onde o
   tópico fixo "Outros" sempre fica (decisão do Giovani de 30/10). O pedaço pequeno ganha um piso de arco (anel) ou de
   largura (barra), tirado do maior; o % mostrado é o verdadeiro, com "<1%". */

/// Quantas cores o anel tem. O pedaço depois delas é cinza: o "Outros", ou o tópico que fica sozinho no cinza.
public let coresDoAnel = 6

/// O id do tópico fixo "Outros" (o último de `topicosPadrao`), que vai sempre para o pedaço cinza.
let idDoOutrosFixo = "outros"

/// O piso de arco do anel, em pontos, medido na circunferência do meio do aro.
public let pisoDoArco = 10.0
/// O piso de largura da barra empilhada e o vão entre os pedaços, em pontos (na letra padrão).
public let pisoDaBarra = 8.0
public let vaoDaBarra = 3.0

/// Um pedaço do anel e da barra empilhada.
public struct PedacoDoAnel: Equatable, Sendable {
    /// Os tópicos do pedaço, do maior para o menor: um só, ou os que o "Outros" junta.
    public let topicos: [GastoDoTopico]
    /// A soma do bruto dos tópicos, na ordem deles.
    public let bruto: Double
    /// A cor, de 0 a 5; nil no cinza.
    public let cor: Int?
    /// O pedaço cinza que junta dois tópicos ou mais: os comuns do 7º em diante e o fixo "Outros". Fica sempre por último,
    /// mesmo quando o fixo é o maior tópico.
    public let outros: Bool
}

/// Os pedaços, sobre a lista do `gastoPorTopico` (do maior para o menor): os 6 maiores tópicos comuns (todos menos o fixo
/// "Outros"), um por cor; e, por último, o pedaço cinza com o resto, na mesma ordem: o fixo e os comuns do 7º em diante. O
/// cinza fica no fim mesmo quando o fixo é o maior tópico (decisão do Giovani de 30/10: o "Outros" da pessoa nunca sai
/// colorido ao lado do "Outros · N tópicos"). Com um tópico só, o cinza é ele mesmo, com o nome dele (o fixo, ou o 7º
/// de uma obra com 7 comuns e sem o fixo); com dois ou mais, é o "Outros", com a soma e os tópicos que ele junta.
public func pedacosDoAnel(_ topicos: [GastoDoTopico]) -> [PedacoDoAnel] {
    let coloridos = Array(topicos.indices.filter { topicos[$0].id != idDoOutrosFixo }.prefix(coresDoAnel))
    var pedacos = coloridos.enumerated().map { cor, i in
        PedacoDoAnel(topicos: [topicos[i]], bruto: topicos[i].bruto, cor: cor, outros: false)
    }
    let cinza = topicos.indices.filter { !coloridos.contains($0) }.map { topicos[$0] }
    if !cinza.isEmpty {
        pedacos.append(PedacoDoAnel(topicos: cinza, bruto: cinza.reduce(0) { $0 + $1.bruto }, cor: nil, outros: cinza.count > 1))
    }
    return pedacos
}

/// Quem tem pedaço no anel e na barra: os tópicos de bruto maior que zero. O de bruto zero (um gasto de R$ 0) fica sem
/// pedaço, como o arco de comprimento 0 do site; numa obra sem bruto nenhum, todos têm.
func temPedaco(_ brutos: [Double]) -> [Bool] {
    brutos.contains { $0 > 0 } ? brutos.map { $0 > 0 } : brutos.map { _ in true }
}

/// As partes de cada bruto no comprimento (frações que somam 1), com o piso: a parte menor que o piso sobe para ele, e o
/// que ela ganhou sai da maior (no empate, a primeira); o bruto zero fica com 0, sem piso. Ficam iguais entre os que têm
/// pedaço sem bruto, sem comprimento ou quando a maior desceria abaixo do piso, que é quando o piso de todas não cabe (no
/// anel e na barra da obra, isso só acontece sem gasto).
func partesComPiso(_ brutos: [Double], comprimento: Double, piso: Double) -> [Double] {
    let soma = brutos.reduce(0, +), minima = piso / comprimento
    let com = temPedaco(brutos), quantos = Double(com.filter { $0 }.count)
    let iguais = com.map { $0 ? 1 / quantos : 0 }
    if brutos.isEmpty || !(soma > 0) || !(comprimento > 0) { return iguais }
    var partes = brutos.map { $0 / soma }
    var falta = 0.0
    for i in partes.indices where partes[i] > 0 && partes[i] < minima {
        falta += minima - partes[i]
        partes[i] = minima
    }
    let maior = partes.indices.max { partes[$0] < partes[$1] }!
    partes[maior] -= falta
    return partes[maior] < minima ? iguais : partes
}

/// Onde um pedaço começa e termina, em frações da volta do anel (de 0 a 1, a partir do topo, no sentido do relógio).
public struct ArcoDoPedaco: Equatable, Sendable {
    public let inicio: Double
    public let fim: Double
}

/// Os arcos do anel, um depois do outro a partir do topo, com o piso de arco; o último termina em 1.
public func arcosDoAnel(_ pedacos: [PedacoDoAnel], circunferencia: Double, piso: Double = pisoDoArco) -> [ArcoDoPedaco] {
    let partes = partesComPiso(pedacos.map(\.bruto), comprimento: circunferencia, piso: piso)
    var inicio = 0.0
    return partes.indices.map { i in
        let fim = i == partes.count - 1 ? 1 : inicio + partes[i]
        defer { inicio = fim }
        return ArcoDoPedaco(inicio: inicio, fim: fim)
    }
}

/// A fração da volta de um ponto, medido a partir do centro do anel (x para a direita, y para baixo, como na tela): 0 no
/// topo, 0,25 à direita, 0,5 embaixo.
public func fracaoNoAnel(x: Double, y: Double) -> Double {
    let f = atan2(x, -y) / (2 * Double.pi)
    return f < 0 ? f + 1 : f
}

/// O pedaço sob o dedo: o arco que contém o ângulo do ponto (o pedaço mais perto, ao longo do anel). O arco vazio (o tópico
/// de bruto zero) nunca fica sob o dedo. Se o dedo está na faixa de toque, quem decide é a tela.
public func pedacoNoAnel(x: Double, y: Double, arcos: [ArcoDoPedaco]) -> Int? {
    let f = fracaoNoAnel(x: x, y: y), cheios = arcos.indices.filter { arcos[$0].fim > arcos[$0].inicio }
    return cheios.first { f < arcos[$0].fim } ?? cheios.last
}

/// As larguras dos pedaços da barra empilhada: a largura sem os vãos, com o piso de largura (8 e 3 pt na letra padrão;
/// 12 e 4 pt na máxima, como o mockup). O pedaço de bruto zero fica sem largura e sem vão. Sem largura para os vãos (o 1º
/// quadro da tela), zero em todos.
public func largurasDaBarra(_ pedacos: [PedacoDoAnel], largura: Double, piso: Double = pisoDaBarra, vao: Double = vaoDaBarra) -> [Double] {
    let brutos = pedacos.map(\.bruto), comPedaco = temPedaco(brutos).filter { $0 }.count
    let util = max(0, largura - vao * Double(max(0, comPedaco - 1)))
    return partesComPiso(brutos, comprimento: util, piso: piso).map { $0 * util }
}

/// O % de um tópico (ou do "Outros") na lista, no meio do anel e na legenda: o `Math.round(bruto / total × 100)` do site, o
/// mesmo do detalhe do tópico, e "<1%" quando o % verdadeiro fica entre 0 e 1 (o site mostraria 0% ou 1%). Sem total, "0%".
public func porcentoDoTopico(_ bruto: Double, total: Double) -> String {
    let pct = total > 0 ? bruto / total * 100 : 0
    if pct > 0 && pct < 1 { return "<1%" }
    return numeroJS(arredondarJS(pct)) + "%"
}

/// O texto com o % como o VoiceOver o lê: o "<1%" vira "menos de 1%", como no rótulo do mockup, e a leitura não depende do
/// nível de pontuação. Serve ao % sozinho (a barra) e à frase com ele ("<1% da obra", na lista e no detalhe do tópico).
public func porcentoFalado(_ texto: String) -> String { texto.replacingOccurrences(of: "<1%", with: "menos de 1%") }

/// "1 tópico", "14 tópicos".
public func contagemDeTopicos(_ n: Int) -> String { "\(n) \(n == 1 ? "tópico" : "tópicos")" }

/// O nome do "Outros" no meio do anel: "Outros · 8 tópicos".
public func rotuloDoOutros(_ pedaco: PedacoDoAnel) -> String { "Outros · " + contagemDeTopicos(pedaco.topicos.count) }

/// A legenda da barra empilhada da obra.
public struct LegendaDaBarra: Equatable, Sendable {
    /// Os pedaços com linha na legenda.
    public let pedacos: [PedacoDoAnel]
    /// "e mais N tópicos", quando sobram tópicos; nil quando todos aparecem.
    public let mais: String?
}

/// A legenda da barra: os `quantos` primeiros pedaços (4; 3 na letra máxima) e "e mais N tópicos" com os que sobram.
public func legendaDaBarra(_ pedacos: [PedacoDoAnel], quantos: Int) -> LegendaDaBarra {
    let mostrados = Array(pedacos.prefix(quantos))
    let sobram = pedacos.reduce(0) { $0 + $1.topicos.count } - mostrados.reduce(0) { $0 + $1.topicos.count }
    return LegendaDaBarra(pedacos: mostrados, mais: sobram > 0 ? "e mais " + contagemDeTopicos(sobram) : nil)
}
