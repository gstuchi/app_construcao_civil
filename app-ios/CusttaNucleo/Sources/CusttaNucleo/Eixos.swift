import Foundation

/* Os eixos dos gráficos de mês (evolução e gasto por mês): regra do app, sem vetor do site. O site divide o eixo em frações
   do máximo (R$ 233 mil, 465 mil…); o app usa números redondos (R$ 250 mil, 500 mil…), como o mockup (`parte1.js:114-121`).
   Os rótulos dos meses e o mês sob o dedo também são conta pura; o resto (medir, ancorar na borda) é da tela. */

/// Os números redondos de cada potência de 10.
let passosRedondos: [Double] = [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]

/// A escala do eixo de valor.
public struct EscalaDoEixo: Equatable, Sendable {
    /// A distância entre as linhas da grade.
    public let passo: Double
    /// Quantas linhas a grade tem acima do zero: 4 na letra padrão, 2 na máxima.
    public let divisoes: Int
    public var topo: Double { passo * Double(divisoes) }
    /// As linhas da grade, de baixo para cima, sem o zero.
    public var linhas: [Double] { (0..<divisoes).map { passo * Double($0 + 1) } }
    /// Os rótulos das linhas: o `moedaCurta` (o `moneyShort` do site), como o mockup.
    public var rotulos: [String] { linhas.map(moedaCurta) }
}

/// A escala redonda: o menor passo redondo (1; 1,2; 1,5; 2; 2,5; 3; 4; 5; 6; 8 ou 10 vezes uma potência de 10) que, vezes as
/// divisões, passa do maior valor com 3% de folga. Sem valor, conta como R$ 1, para o gráfico nunca dividir por zero.
public func escalaRedonda(_ maior: Double, divisoes: Int) -> EscalaDoEixo {
    let alvo = max(maior, 1) * 1.03 / Double(divisoes)
    let potencia = pow(10, log10(alvo).rounded(.down))
    let passo = passosRedondos.lazy.map { $0 * potencia }.first { $0 >= alvo } ?? 10 * potencia
    return EscalaDoEixo(passo: passo, divisoes: divisoes)
}

/// Um rótulo fixo do eixo X: o índice do mês na série e o texto.
public struct RotuloDoEixoX: Equatable, Sendable {
    public let indice: Int
    public let texto: String
}

/// "out", ou "out/26" com o ano, de um mês AAAA-MM.
func mesAbreviado(_ mes: String, comAno: Bool) -> String {
    let (ano, m) = anoMes(mes)
    return String(nomesDosMeses[m - 1].prefix(3)) + (comAno ? "/" + String(String(ano).suffix(2)) : "")
}

/// Os rótulos fixos do eixo X: `quantos` meses espalhados por igual, sempre o primeiro e o último (4 na letra padrão, 3 na
/// máxima), no índice `Math.round(i × (n − 1) ÷ (quantos − 1))`; o ano vai no primeiro e quando muda do rótulo anterior.
public func rotulosDoEixoX(_ meses: [String], quantos: Int) -> [RotuloDoEixoX] {
    let k = min(quantos, meses.count)
    var anoAnterior = ""
    return (0..<max(0, k)).map { i in
        let indice = Int(arredondarJS(Double(i) * Double(meses.count - 1) / Double(max(1, k - 1))))
        let ano = String(meses[indice].prefix(4))
        defer { anoAnterior = ano }
        return RotuloDoEixoX(indice: indice, texto: mesAbreviado(meses[indice], comAno: ano != anoAnterior))
    }
}

/// O rótulo do mês escolhido: o do rótulo fixo, se ele for um; senão o mês abreviado, com o ano só em janeiro.
public func rotuloDoMes(_ meses: [String], indice: Int, fixos: [RotuloDoEixoX]) -> String {
    if let fixo = fixos.first(where: { $0.indice == indice }) { return fixo.texto }
    return mesAbreviado(meses[indice], comAno: anoMes(meses[indice]).1 == 1)
}

/// O mês sob o dedo no gasto por mês: a coluna que contém x (as colunas dividem a largura por igual a partir de `inicio`),
/// presa ao primeiro e ao último mês.
public func mesNaColuna(x: Double, inicio: Double, largura: Double, meses: Int) -> Int {
    guard meses > 0, largura > 0 else { return 0 }
    let i = ((x - inicio) / (largura / Double(meses))).rounded(.down)
    return Int(max(0, min(Double(meses - 1), i)))
}

/// O mês sob o dedo na evolução: o ponto mais perto de x (os pontos vão de `inicio` a `inicio + largura`; no meio, o de
/// depois, como o `Math.round`), preso às pontas.
public func mesNoPonto(x: Double, inicio: Double, largura: Double, meses: Int) -> Int {
    guard meses > 1, largura > 0 else { return 0 }
    let i = arredondarJS((x - inicio) / largura * Double(meses - 1))
    return Int(max(0, min(Double(meses - 1), i)))
}
