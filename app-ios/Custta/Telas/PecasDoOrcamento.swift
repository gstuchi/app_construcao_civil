import SwiftUI
import CusttaNucleo

/* As peças do orçamento na tela da obra (mockup aprovado da etapa 3, parte 1, opção A): a linha do orçamento, primeira do
   grupo dos indicadores, logo abaixo do Total gasto; a barra dos três níveis do site; o aviso dos tópicos. Perto e passou em
   âmbar, nunca vermelho; no "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado: a diferença está
   na forma, não só na cor. Medidas do mockup: recuo 18 (16 à direita), o chip como os dos indicadores, "sobra" e "passou"
   em subheadline semibold no secundário, o valor em title2 bold, a barra de 8 com 9 acima e 7 abaixo. Os textos e as contas
   são os do site (orcamentoObra, rodapeOrc) e os das regras novas do app (avisoDosTopicos, foraNaLinha). */

/// Onde a barra do orçamento enche e onde ficam as listras do excesso, em pontos (larguraBarraOrc do site; no "passou", a
/// parte cheia é o previsto dentro do gasto e o excesso vem depois da fresta).
struct GeometriaDaBarra: Equatable {
    /// A parte cheia, a partir da esquerda.
    let cheia: CGFloat
    /// O excesso listrado, do fim da fresta ao fim da barra; nil fora do "passou".
    let listras: ClosedRange<CGFloat>?

    /// A fresta entre o previsto e o excesso.
    static let fresta: CGFloat = 2

    init(_ item: ItemOrcamento, largura: CGFloat) {
        if item.nivel == .passou, item.gasto > 0 {
            let previsto = largura * CGFloat(item.previsto) / CGFloat(item.gasto)
            cheia = previsto
            listras = min(previsto + Self.fresta, largura)...largura
        } else {
            cheia = largura * CGFloat(larguraBarraOrc(item.pct)) / 100
            listras = nil
        }
    }
}

/// A barra do orçamento: o trilho no texto a 14%; dentro do previsto, o degradê da marca; perto e passou, o âmbar; no
/// "passou", o excesso listrado a 45° (3 de âmbar e 3 de âmbar a 38%). 8 pt (6 nas linhas dos tópicos, `fina`), 12 na
/// letra grande. Figura, fora do VoiceOver: a linha diz o nível em texto.
struct BarraDoOrcamento: View {
    let item: ItemOrcamento
    var fina = false
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let altura: CGFloat = tamanho.isAccessibilitySize ? 12 : fina ? 6 : 8
        GeometryReader { geo in
            let g = GeometriaDaBarra(item, largura: geo.size.width)
            ZStack(alignment: .leading) {
                Capsule().fill(paleta.cor(.texto).opacity(0.14))
                if g.cheia > 0 {
                    Capsule()
                        .fill(item.nivel == .ok ? AnyShapeStyle(LinearGradient(colors: [paleta.cor(.marca), paleta.cor(.destaque)],
                                                                                 startPoint: .leading, endPoint: .trailing))
                                                : AnyShapeStyle(paleta.cor(.alerta)))
                        .frame(width: g.cheia)
                }
                if let l = g.listras, l.upperBound > l.lowerBound {
                    ListrasDoExcesso(cor: paleta.cor(.alerta))
                        .frame(width: l.upperBound - l.lowerBound)
                        .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: altura / 2, topTrailingRadius: altura / 2))
                        .offset(x: l.lowerBound)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: altura)
        .accessibilityHidden(true)
    }
}

/// O excesso do "passou": listras "/" de 3 pt a cada 6 pt (medidos de través), em âmbar sobre o âmbar a 38%.
private struct ListrasDoExcesso: View {
    let cor: Color

    var body: some View {
        Canvas { contexto, tamanho in
            contexto.fill(Path(CGRect(origin: .zero, size: tamanho)), with: .color(cor.opacity(0.38)))
            // A 45°, os 3 e os 6 pt de través valem 3√2 e 6√2 na horizontal.
            let largura = 3 * CGFloat(2).squareRoot(), passo = 6 * CGFloat(2).squareRoot(), h = tamanho.height
            var listras = Path()
            var x = -h
            while x < tamanho.width {
                listras.move(to: CGPoint(x: x, y: h))
                listras.addLine(to: CGPoint(x: x + largura, y: h))
                listras.addLine(to: CGPoint(x: x + largura + h, y: 0))
                listras.addLine(to: CGPoint(x: x + h, y: 0))
                listras.closeSubpath()
                x += passo
            }
            contexto.fill(listras, with: .color(cor))
        }
    }
}

/// "{pct}% usado de" e o previsto: o `usadoDoPrevisto` do núcleo partido, para o dinheiro ir para a própria linha na letra
/// grande.
func partesDoUsado(_ geral: ItemOrcamento) -> (antes: String, valor: String) {
    ("\(rodapeOrc(geral).usado) usado de", moeda(geral.previsto))
}

/// Uma frase com dinheiro dentro ("80% usado de R$ 1.019.847,85"): numa linha só no tamanho padrão; na letra grande, o
/// dinheiro vai para a própria linha e encolhe para caber (mockup, `.din`), em vez de partir no meio.
struct FraseComDinheiro: View {
    let antes: String
    let valor: String
    var depois = ""
    var fonte: Font = .subheadline
    let cor: Token
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        if tamanho.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) {
                if !antes.isEmpty { Text(antes).font(fonte).foregroundStyle(paleta.cor(cor)) }
                ValorEmDinheiro(texto: valor, fonte: fonte, cor: cor)
                if !depois.isEmpty { Text(depois).font(fonte).foregroundStyle(paleta.cor(cor)) }
            }
        } else {
            Text([antes, valor, depois].filter { !$0.isEmpty }.joined(separator: " "))
                .font(fonte)
                .foregroundStyle(paleta.cor(cor))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// O aviso dos tópicos ("2 tópicos passaram do previsto"): o triângulo do site e o texto em semibold, no âmbar sobre o
/// vidro. O triângulo cresce com a letra (16 pt no tamanho padrão; 0,8 da letra nos tamanhos de acessibilidade, mockup).
struct AvisoDoOrcamento: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    @ScaledMetric(relativeTo: .subheadline) private var letra: CGFloat = 15

    var body: some View {
        let lado = tamanho.isAccessibilitySize ? letra * 0.8 : letra * 16 / 15
        HStack(alignment: .top, spacing: 6) {
            Image(decorative: "Icones/alerta")
                .resizable()
                .frame(width: lado, height: lado)
                .padding(.top, tamanho.isAccessibilitySize ? letra * 0.15 : 2)
                .foraDoLaudo("iconeDoAviso")
            Text(texto)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(paleta.cor(.alertaNoVidro))
    }
}

/// A linha do orçamento nos indicadores: "Orçamento" e o nível do site, quanto sobra (ou passou), a barra, "{pct}% usado de
/// {previsto}" e, por tópico, o pior aviso dos tópicos e o que está fora; com a seta, ela abre a tela Orçamento (a linha
/// inteira é o botão). Um elemento só para o VoiceOver, como as outras linhas dos indicadores.
struct LinhaDoOrcamento: View {
    let resumo: ResumoOrcamento
    var comSeta = false
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let geral = resumo.geral
        let rodape = rodapeOrc(geral)
        HStack(spacing: 4) {
            conteudo(geral, rodape)
            if comSeta {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .accessibilityHidden(true)
                    .foraDoLaudo()
            }
        }
        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorOrcamento")
    }

    private func conteudo(_ geral: ItemOrcamento, _ rodape: RodapeDoOrcamento) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { rotulo; Spacer(minLength: 8); etiqueta(geral.nivel) }
                VStack(alignment: .leading, spacing: 6) { rotulo; etiqueta(geral.nivel) }
            }
            // "sobra R$ …" numa linha; na letra grande, um em cima do outro (mockup).
            let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                                                     : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 7))
            layout {
                Text(rodape.rotulo).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(vidro.secundario))
                ValorEmDinheiro(texto: rodape.valor, fonte: .title2.weight(.bold))
            }
            .padding(.top, 2)
            BarraDoOrcamento(item: geral)
                .padding(.top, 9)
                .padding(.bottom, 7)
            let usado = partesDoUsado(geral)
            FraseComDinheiro(antes: usado.antes, valor: usado.valor, cor: vidro.secundario)
            if let aviso = avisoDosTopicos(resumo) { AvisoDoOrcamento(texto: aviso).padding(.top, 4) }
            if let fora = foraNaLinha(resumo) {
                Text(fora).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario)).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rotulo: some View {
        Text("Orçamento").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func etiqueta(_ nivel: NivelOrcamento) -> some View {
        EtiquetaDoIndicador(texto: nivel.pilula, cor: corDoNivel(nivel))
    }
}

/// O chip do nível do orçamento: verde dentro do previsto; âmbar perto e passou, nunca vermelho.
func corDoNivel(_ nivel: NivelOrcamento) -> EtiquetaDoIndicador.Cor { nivel == .ok ? .positivo : .alerta }
