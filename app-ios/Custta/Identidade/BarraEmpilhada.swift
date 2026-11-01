import SwiftUI
import CusttaNucleo

/* A barra empilhada de tópicos e a hachura da identidade nova (etapa 4; a barra foi pedida pelo Giovani em 29/10, no lugar
   do mini-anel da obra: parte1.css:206-216 e "Mudanças de 29/10" do LEIA-ME). Desenhadas em Shape, sem Swift Charts. Os
   pedaços e as larguras vêm do núcleo (Pedacos.swift): os 6 maiores nas cores do anel e o "Outros" em cinza (onde o tópico
   fixo "Outros" sempre fica), com o vão e o piso de largura. A barra não tem toque: a porta para os Gráficos chega com eles
   (PR 2b). */

/// A cor de um pedaço: as seis do anel, do maior para o menor, e o cinza do "Outros" (ou do tópico sozinho no cinza: o fixo
/// "Outros", ou o 7º de uma obra com 7 sem ele).
func corDoPedaco(_ pedaco: PedacoDoAnel) -> Token {
    guard let cor = pedaco.cor else { return .graficoOutros }
    return [Token.grafico1, .grafico2, .grafico3, .grafico4, .grafico5, .grafico6][cor]
}

/// O nome de um pedaço na legenda e no VoiceOver: o do tópico (o que o app não conhece aparece pelo id, como na linha do
/// gasto) ou "Outros · N tópicos".
func nomeDoPedaco(_ pedaco: PedacoDoAnel, topicos: [String: Topico]) -> String {
    if pedaco.outros { return rotuloDoOutros(pedaco) }
    let id = pedaco.topicos.first?.id ?? ""
    return topicos[id]?.nome ?? (id.isEmpty ? "Outros" : id)
}

/// A fonte do estilo de texto no tamanho de letra dado (a altura de uma linha e o tamanho dela crescem com a letra).
func fonteDoTexto(_ estilo: UIFont.TextStyle, _ letra: DynamicTypeSize) -> UIFont {
    UIFont.preferredFont(forTextStyle: estilo, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(letra)))
}

/// A barra: um pedaço por tópico, de cantos redondos, com a largura do núcleo (proporcional, com o piso de 8 pt tirado do
/// maior) e o vão de 3 pt; 16 pt de altura. Na letra de acessibilidade, 26 pt, vão de 4 e piso de 12 (parte1.css:209-210).
struct BarraEmpilhada: View {
    let pedacos: [PedacoDoAnel]
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let grande = letra.isAccessibilitySize
        let (altura, vao, piso): (CGFloat, Double, Double) = grande ? (26, 4, 12) : (16, vaoDaBarra, pisoDaBarra)
        GeometryReader { geo in
            let larguras = largurasDaBarra(pedacos, largura: geo.size.width, piso: piso, vao: vao)
            HStack(spacing: vao) {
                ForEach(Array(pedacos.enumerated()), id: \.offset) { i, pedaco in
                    Capsule().fill(paleta.cor(corDoPedaco(pedaco))).frame(width: larguras[i])
                }
            }
        }
        .frame(height: altura)
    }
}

/// O conteúdo do bloco "Gastos por tópico" da obra: a barra sobre a placa forte (8 pt de recuo e cantos de 12, para as cores
/// ficarem a 3:1 com a aurora atrás) e a legenda numa coluna, com os 4 maiores (3 na letra de acessibilidade): o ponto da
/// cor, o nome inteiro (quebra em vez de cortar) e o % (o "<1%" do núcleo), e "e mais N tópicos" quando sobram. O VoiceOver
/// lê a barra inteira num elemento ("Gastos por tópico": cada pedaço com o %).
struct BarraDeTopicos: View {
    let pedacos: [PedacoDoAnel]
    let topicos: [String: Topico]
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let total = pedacos.reduce(0) { $0 + $1.bruto }
        let legenda = legendaDaBarra(pedacos, quantos: letra.isAccessibilitySize ? 3 : 4)
        // O ponto no meio da primeira linha do nome, que cresce com a letra. O % numa coluna de largura inteira, a do "100%":
        // assim o nome recebe uma largura na grade de pixels (com o % de largura fracionária ao lado, o nome arredondava para
        // cima, e o bloco passava 1/3 de pt da largura).
        let fonte = fonteDoTexto(.subheadline, letra)
        let mono = UIFont.monospacedSystemFont(ofSize: fonte.pointSize, weight: .semibold)
        let colunaDoPorcento = ("100%" as NSString).size(withAttributes: [.font: mono]).width.rounded(.up)
        VStack(alignment: .leading, spacing: 4) {
            BarraEmpilhada(pedacos: pedacos)
                .padding(8)
                .placa(forte: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Gastos por tópico")
                .accessibilityValue(pedacos.map { pedaco in
                    // O "<1%" falado como "menos de 1%" (o porcentoFalado do núcleo), como no rótulo do mockup.
                    "\(nomeDoPedaco(pedaco, topicos: topicos)), \(porcentoFalado(porcentoDoTopico(pedaco.bruto, total: total)))"
                }.joined(separator: "; "))
                .accessibilityAddTraits(.isImage)
                .accessibilityIdentifier("barraDeTopicos")
                .padding(.top, 2)
                .padding(.bottom, 8)
            ForEach(Array(legenda.pedacos.enumerated()), id: \.offset) { _, pedaco in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(paleta.cor(corDoPedaco(pedaco))).frame(width: 12, height: 12)
                        .padding(.top, (fonte.lineHeight - 12) / 2)
                    Text(nomeDoPedaco(pedaco, topicos: topicos))
                        .foregroundStyle(paleta.cor(.texto))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(porcentoDoTopico(pedaco.bruto, total: total))
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(paleta.cor(vidro.secundario))
                        .frame(width: colunaDoPorcento, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
            if let mais = legenda.mais {
                Text(mais).foregroundStyle(paleta.cor(vidro.secundario)).padding(.leading, 22)
            }
        }
        .font(.subheadline)
    }
}

/// A hachura a 45° ("/") da identidade nova, com o traço e o passo medidos de través, como o `repeating-linear-gradient(-45deg)`
/// do mockup: 2 pt a cada 6 no excesso do orçamento e na zona "acima do banco"; 1,5 a cada 4 nas parcelas a vencer do gasto
/// por mês (parte1.css:187 e :300). Uma forma presa ao retângulo: quem usa a preenche na cor e a recorta pela marca.
struct Hachura: Shape {
    var traco: CGFloat = 2
    var passo: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        // A 45°, a medida de través vale √2 vezes na horizontal.
        let largura = traco * CGFloat(2).squareRoot(), avanco = passo * CGFloat(2).squareRoot(), h = rect.height
        var listras = Path()
        var x = rect.minX - h
        while x < rect.maxX {
            listras.move(to: CGPoint(x: x, y: rect.maxY))
            listras.addLine(to: CGPoint(x: x + largura, y: rect.maxY))
            listras.addLine(to: CGPoint(x: x + largura + h, y: rect.minY))
            listras.addLine(to: CGPoint(x: x + h, y: rect.minY))
            listras.closeSubpath()
            x += avanco
        }
        return listras.intersection(Path(rect))
    }
}
