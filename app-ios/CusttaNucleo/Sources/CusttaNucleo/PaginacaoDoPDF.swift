import Foundation

/* A tabela do PDF (da página 2 em diante) como conta pura (spec da etapa 4, "### 2. PDF", "Paginação no núcleo"): as colunas,
   com a de valor pela largura do maior valor, e onde cada página quebra. O desenho (UIKit, no PR do PDF) mede o texto de cada
   gasto na largura da coluna, pelo mesmo motor com que desenha, passa as alturas das linhas para cá e desenha cada página na
   altura prevista. As medidas são as do mockup e do protótipo (A4, `parte2.js:163-164`); o PR do PDF as acerta no desenho. */

/// As medidas da página e da tabela do PDF, em pontos.
public struct MedidasDoPDF: Equatable, Sendable {
    public var largura = 595.0
    public var altura = 842.0
    /// O rodapé "página N de M" mora na margem de baixo.
    public var margemDeCima = 34.0
    public var margemDeBaixo = 50.0
    public var margemDosLados = 44.0
    /// O logo e o título do relatório, em toda página.
    public var cabecalho = 47.0
    /// O "Gastos por tópico" da 1ª página da tabela.
    public var subtitulo = 30.0
    /// Os títulos das colunas, repetidos em toda página.
    public var cabecalhoDaTabela = 18.0
    public var linhaDoTopico = 20.0
    /// A linha do gasto: o texto e o respiro, nunca menos que a linha mínima.
    public var linhaMinimaDoGasto = 15.0
    public var respiroDoGasto = 3.0
    /// O fim: o total, cada linha da venda (ou da margem) e o aviso da obra sem venda estimada.
    public var linhaDoTotal = 22.0
    public var linhaDaVenda = 18.0
    public var avisoSemVenda = 23.0
    public var colunaDaData = 63.5
    /// A folga de cada lado da célula, e o recuo do texto do gasto, depois do ponto do tópico.
    public var folga = 6.0
    public var recuoDoGasto = 19.0

    public init() {}

    /// O espaço da tabela na página `i` da tabela (a 0 tem o subtítulo).
    public func espaco(_ i: Int) -> Double {
        altura - margemDeCima - margemDeBaixo - cabecalho - (i == 0 ? subtitulo : 0) - cabecalhoDaTabela
    }

    /// O fim: o total e a venda, o lucro e o acima do banco; ou a venda estimada e a margem; ou o aviso sem venda.
    public func alturaDoFim(_ fim: FimDoRelatorio?) -> Double {
        switch fim {
        case .venda: linhaDoTotal + 3 * linhaDaVenda
        case .estimada: linhaDoTotal + 2 * linhaDaVenda
        case nil: linhaDoTotal + avisoSemVenda
        }
    }
}

/// O número das colunas de valor, sem o "R$" (o título da coluna diz "(R$)"): "319.847,85".
public func valorNoPDF(_ v: Double) -> String { duasCasasPtBR(v) }

/// A correção, com o sinal: "+46.338,31".
public func correcaoNoPDF(_ v: Double) -> String { (v < 0 ? "" : "+") + duasCasasPtBR(v) }

/// O texto mais longo das colunas de valor (bruto, corrigido e correção de cada gasto, de cada tópico e do total). Os números
/// da tabela são em SF Mono, de avanço igual: o mais longo é o mais largo, e o desenho mede só ele.
public func maiorValorDoPDF(_ r: RelatorioDaObra) -> String {
    var maior = ""
    func ve(_ bruto: Double, _ corrigido: Double) {
        for t in [valorNoPDF(bruto), valorNoPDF(corrigido), correcaoNoPDF(corrigido - bruto)] where t.count > maior.count { maior = t }
    }
    for g in r.grupos {
        ve(g.bruto, g.corrigido)
        for item in g.itens { ve(item.gasto.valor, item.corrigido) }
    }
    ve(r.totalBruto, r.totalCorrigido)
    return maior
}

/// As colunas da tabela.
public struct ColunasDoPDF: Equatable, Sendable {
    /// A do gasto (o ponto do tópico e a descrição): o que sobra.
    public let gasto: Double
    public let data: Double
    /// Cada uma das três de valor.
    public let valor: Double
    /// A largura em que a descrição é medida e desenhada: a coluna do gasto sem o recuo e a folga.
    public let texto: Double
}

/// As colunas: as três de valor com a largura do maior valor (`maiorValorDoPDF`, medido) ou do maior título, se ele for mais
/// largo, e a folga dos dois lados; a data fixa; o gasto com o resto da largura entre as margens.
public func colunasDoPDF(larguraDoMaiorValor: Double, larguraDoMaiorTitulo: Double = 0, medidas m: MedidasDoPDF = MedidasDoPDF()) -> ColunasDoPDF {
    let valor = max(larguraDoMaiorValor, larguraDoMaiorTitulo) + 2 * m.folga
    let gasto = m.largura - 2 * m.margemDosLados - m.colunaDaData - 3 * valor
    return ColunasDoPDF(gasto: gasto, data: m.colunaDaData, valor: valor, texto: gasto - m.recuoDoGasto - m.folga)
}

/// Um gasto da tabela, medido: a altura de cada linha do texto da descrição, na largura `ColunasDoPDF.texto`.
public struct GastoMedidoDoPDF: Equatable, Sendable {
    public var linhas: [Double]
    public init(linhas: [Double]) { self.linhas = linhas }
}

/// O que vai numa linha da tabela.
public enum ItemDoPDF: Equatable, Sendable {
    /// O tópico `topico` (o índice no relatório), com os totais; na continuação, com "(continuação)" e sem eles.
    case topico(Int, continuacao: Bool)
    /// As linhas `linhas` do texto do gasto `gasto` do tópico. O pedaço que começa na linha 0 leva a data e os valores.
    case gasto(topico: Int, gasto: Int, linhas: Range<Int>)
    /// O fim inteiro.
    case fim
}

/// Uma página da tabela e o espaço que ela usa.
public struct PaginaDoPDF: Equatable, Sendable {
    public internal(set) var itens: [ItemDoPDF] = []
    public internal(set) var usado = 0.0
}

/// As páginas da tabela, que vêm depois da página 1 (o resumo).
public struct PaginacaoDoPDF: Equatable, Sendable {
    public let paginas: [PaginaDoPDF]
    /// Quantas páginas o PDF tem, com a página 1.
    public var total: Int { paginas.count + 1 }
}

/// "página 2 de 5", no rodapé de toda página (a 1 é o resumo).
public func rodapeDoPDF(pagina: Int, de total: Int) -> String { "página \(pagina) de \(total)" }

/// A linha de um pedaço do texto de um gasto: as linhas e o respiro, arredondadas para cima, nunca menos que a mínima.
func alturaDoGasto(_ linhas: ArraySlice<Double>, _ m: MedidasDoPDF) -> Double {
    max(m.linhaMinimaDoGasto, linhas.reduce(0, +).rounded(.up) + m.respiroDoGasto)
}

/// Pagina a tabela: `topicos` traz, na ordem do relatório, cada gasto medido. Regras:
/// - o tópico vai para a página seguinte se não cabe com o 1º gasto (ou com a 1ª linha dele, se ele for partido);
/// - o gasto que não cabe vai inteiro para a página seguinte, que repete o tópico com "(continuação)", sem os totais;
/// - o gasto maior que uma página é partido entre as linhas do texto, a partir do que sobra na página;
/// - na página ainda vazia (a 1ª da tabela), o 1º gasto que não cabe inteiro também é partido ali;
/// - o fim fica inteiro numa página.
public func paginarTabelaDoPDF(_ topicos: [[GastoMedidoDoPDF]], fim: FimDoRelatorio?, medidas m: MedidasDoPDF = MedidasDoPDF()) -> PaginacaoDoPDF {
    var paginas = [PaginaDoPDF()]
    func cabe(_ h: Double) -> Bool { paginas[paginas.count - 1].usado + h <= m.espaco(paginas.count - 1) }
    func por(_ item: ItemDoPDF, _ h: Double) {
        paginas[paginas.count - 1].itens.append(item)
        paginas[paginas.count - 1].usado += h
    }
    func continua(_ t: Int) {
        paginas.append(PaginaDoPDF())
        por(.topico(t, continuacao: true), m.linhaDoTopico)
    }
    // O espaço de uma página nova, depois do tópico: o gasto mais alto que ele é partido.
    let paginaNova = m.espaco(1) - m.linhaDoTopico
    for (t, gastos) in topicos.enumerated() {
        // Na página ainda vazia (a 1ª da tabela, menor por causa do subtítulo), o 1º gasto que não cabe inteiro é partido ali:
        // abrir outra página a deixaria em branco.
        let vazia = paginas[paginas.count - 1].itens.isEmpty
        let limite = vazia ? m.espaco(paginas.count - 1) - m.linhaDoTopico : paginaNova
        let primeiro = gastos.first.map { g -> Double in
            let inteiro = alturaDoGasto(g.linhas[...], m)
            return inteiro <= limite ? inteiro : alturaDoGasto(g.linhas.prefix(1), m)
        } ?? 0
        if !cabe(m.linhaDoTopico + primeiro) { paginas.append(PaginaDoPDF()) }
        por(.topico(t, continuacao: false), m.linhaDoTopico)
        for (g, gasto) in gastos.enumerated() {
            let inteiro = alturaDoGasto(gasto.linhas[...], m), n = gasto.linhas.count
            // O 1º gasto já foi decidido com o tópico: inteiro, ou partido a partir daqui.
            if g > 0 && !cabe(inteiro) && inteiro <= paginaNova { continua(t) }
            if cabe(inteiro) {
                por(.gasto(topico: t, gasto: g, linhas: 0..<n), inteiro)
                continue
            }
            var a = 0
            while a < n {
                var b = a
                while b < n, cabe(alturaDoGasto(gasto.linhas[a...b], m)) { b += 1 }
                if b == a {
                    continua(t)
                    while b < n, cabe(alturaDoGasto(gasto.linhas[a...b], m)) { b += 1 }
                    b = max(b, a + 1)
                }
                por(.gasto(topico: t, gasto: g, linhas: a..<b), alturaDoGasto(gasto.linhas[a..<b], m))
                a = b
            }
        }
    }
    let alturaDoFim = m.alturaDoFim(fim)
    if !cabe(alturaDoFim) { paginas.append(PaginaDoPDF()) }
    por(.fim, alturaDoFim)
    return PaginacaoDoPDF(paginas: paginas)
}
