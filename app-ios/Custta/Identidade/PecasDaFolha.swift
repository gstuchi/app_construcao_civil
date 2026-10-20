import SwiftUI
import CusttaNucleo

/* As peças de dentro da folha do sistema (mockup da etapa 2, parte 2, "Medidas"): grupos sólidos na Linha da folha, a
   16 pt das bordas, raio 24 e 20 pt entre eles; linhas de 52 pt (a do valor, 60) com rótulo à esquerda e valor à direita;
   a linha fina recuada 16 pt; cabeçalho e rodapé em 13 pt secundário. Dentro da folha nada é vidro: a folha já é. Na
   letra grande, o rótulo vai em cima do valor. */

/// A seta de dentro do valor, na letra grande: só avisa a linha, que a desenha na ponta direita.
private struct SetaNaPonta: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

extension EnvironmentValues {
    /// Dentro do valor de uma `LinhaDaFolhaComRotulo` na letra grande: a `SetaDaLinha` não segue o valor.
    @Entry var setaNaPonta = false
}

/// Um grupo de linhas: o fundo sólido e o recorte no raio do grupo.
struct GrupoDaFolha<Conteudo: View>: View {
    @ViewBuilder let conteudo: () -> Conteudo
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: conteudo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(paleta.cor(.linhaDaFolha), in: .rect(cornerRadius: 24, style: .continuous))
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
    }
}

/// A linha fina entre duas linhas de um grupo, recuada do começo (16 pt; 60 na lista de tópicos).
struct SeparadorDaFolha: View {
    var recuo: CGFloat = 16
    @Environment(\.paleta) private var paleta
    @Environment(\.displayScale) private var escala

    var body: some View {
        Rectangle()
            .fill(paleta.cor(.separadorDaFolha))
            .frame(height: 1 / escala)
            .padding(.leading, recuo)
            .accessibilityHidden(true)
    }
}

/// Uma linha com rótulo e valor ("Valor", "Tópico", "Data", "Parcelas"): lado a lado; na letra grande, um em cima do
/// outro, o rótulo secundário e menor que o valor e a seta na ponta direita, centrada na altura (o `.f-lin` do mockup na
/// AX5). `altura` é a mínima (52; a do valor, 60, com o rótulo no secundário, o `.f-valor .r`).
struct LinhaDaFolhaComRotulo<Valor: View>: View {
    let rotulo: String
    var altura: CGFloat = 52
    @ViewBuilder let valor: () -> Valor
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let layout = grande
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            // Na letra grande, o subheadline (49 pt na AX5) e não o footnote do mockup (44): o footnote da AX1 tem os 23 pt
            // do body da última letra comum, e a auditoria de tipo dinâmico marca o rótulo que não cresce na passagem.
            Text(rotulo)
                .font(grande ? .subheadline : nil)
                .foregroundStyle(paleta.cor(grande || altura > 52 ? .secundarioTransparente : .texto))
                .fixedSize(horizontal: false, vertical: true)
            if !grande { Spacer(minLength: 0) }
            valor()
                .environment(\.setaNaPonta, grande)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: altura, alignment: .leading)
        .overlayPreferenceValue(SetaNaPonta.self, alignment: .trailing) { tem in
            if tem { SetaDaLinha().padding(.trailing, 16) }
        }
        .contentShape(.rect)
    }
}

/// Um campo de texto com o rótulo em cima, dentro de um grupo ("Nome da obra", "Área construída em m²"), como a
/// descrição do gasto: rótulo em 13 medium secundário (no erro, na cor do erro), na linha de 18 pt do mockup, e o campo
/// embaixo.
struct CampoComRotuloEmCima<Campo: View>: View {
    let rotulo: String
    var erro = false
    @ViewBuilder let campo: () -> Campo
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rotulo)
                .font(.footnote.weight(.medium))
                .foregroundStyle(paleta.cor(erro ? .erroNoVidro : .secundarioTransparente))
                .accessibilityHidden(true)
                .padding(.vertical, 1)          // linha de 18 pt, a do rótulo no mockup (o footnote ocupa 16)
            campo()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
    }
}

/// Uma linha de dinheiro que abre o teclado de valor ("Valor estimado de venda", "Orçamento total", "Valor da venda"):
/// "R$" e o valor, ou "Opcional" vazia, e a seta.
struct LinhaDeDinheiro: View {
    let rotulo: String
    let centavos: Int
    var opcional = true
    var altura: CGFloat = 52
    var identificador: String
    let abrir: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        Button(action: abrir) {
            LinhaDaFolhaComRotulo(rotulo: rotulo, altura: altura) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if centavos == 0 && opcional {
                        Text("Opcional").foregroundStyle(paleta.cor(.secundarioTransparente))
                    } else {
                        ValorEmDinheiro(texto: fmtCentavos(centavos), fonte: altura > 52 ? .title2.weight(.bold) : .body.weight(.semibold),
                                        prefixo: .callout.weight(.semibold))
                    }
                    SetaDaLinha()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rotulo)
        .accessibilityValue(centavos == 0 && opcional ? "Opcional" : moeda(centavosParaReais(centavos)))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identificador)
    }
}

/// A seta ">" das linhas que abrem outro passo; para de crescer no AX3 (18 × 30 no mockup na AX5). Na letra grande,
/// dentro do valor de uma `LinhaDaFolhaComRotulo`, não segue o valor: guarda o lugar dela no fim do valor (o valor para
/// 40 pt antes da borda, como no mockup) e avisa a linha, que a desenha na ponta direita (o `.f-lin .chev` na AX5).
struct SetaDaLinha: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.setaNaPonta) private var naPonta

    var body: some View {
        if naPonta {
            Color.clear.frame(width: 18, height: 0).preference(key: SetaNaPonta.self, value: true)
        } else {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .foregroundStyle(paleta.cor(.textoTerciario))
                .accessibilityHidden(true)
                .foraDoLaudo()
        }
    }
}

/// Texto solto na folha, fora dos grupos (resumo do cartão, ajuda, avisos): 13 pt secundário, a 34 pt da borda (16 do
/// grupo + 18; na letra grande, 22), como o rodapé de um grupo de Ajustes do sistema.
struct NotaDaFolha: View {
    let texto: String
    var cor: Token = .secundarioTransparente
    var identificador: String?

    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        Text(texto)
            .font(.footnote)
            .foregroundStyle(paleta.cor(cor))
            .fixedSize(horizontal: false, vertical: true)
            // O .f-rod do mockup é 36 pt em duas linhas de 18; o footnote ocupa 33,7, e o que falta fica embaixo: os glifos
            // já caem onde o mockup os põe (1 pt abaixo, a meia entrelinha do SwiftUI), e o que vem depois desce para o lugar.
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, tamanho.isAccessibilitySize ? 22 : 34)
            .accessibilityIdentifier(identificador ?? "")
    }
}

/// O título da folha na barra: 17 semibold e, embaixo, o nome da obra em 13 secundário (mockup). Uma linha cada; na
/// letra grande para perto de 22 pt e mostra o Visualizador de Conteúdo Grande, como o título pequeno da obra, e o nome
/// da obra sai da barra (mockup), ficando só para o VoiceOver. `letraGrande` vem de fora: dentro da barra, o tamanho de
/// letra chega limitado e nunca é de acessibilidade.
struct TituloDaFolha: View {
    let titulo: String
    var subtitulo: String?
    var letraGrande = false
    @Environment(\.paleta) private var paleta

    var body: some View {
        // Os identificadores vão também em cada texto: na barra, o VoiceOver junta os dois, mas a auditoria de tipo
        // dinâmico do Xcode olha cada um (e a exceção de "para perto de 22 pt" é por identificador).
        VStack(spacing: 0) {
            Text(titulo)
                .font(.headline)
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityIdentifier("tituloDaFolha")
            if let subtitulo, !letraGrande {
                Text(subtitulo)
                    .font(.footnote)
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .accessibilityIdentifier("tituloDaFolha-obra")
            }
        }
        .lineLimit(1)
        .frame(maxWidth: 250)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .combine)
        .accessibilityValue(letraGrande ? subtitulo ?? "" : "")
        .accessibilityAddTraits(.isHeader)
        .accessibilityShowsLargeContentViewer()
        .accessibilityIdentifier("tituloDaFolha")
    }
}

/// O segmentado de duas opções da folha (Pix | Cartão; "Só o total" | "Por tópico"): o trilho em cápsula e a opção escolhida
/// sólida. Opções de 36 pt, no mínimo 86 de largura, ícone (se houver) e palavra; com `larguraToda`, as opções dividem a
/// largura; na letra grande, uma em cima da outra. VoiceOver lê cada opção como botão, com "1 de 2" e "selecionado", como a
/// cápsula de abas.
struct SegmentadoDaFolha<Opcao: Hashable>: View {
    let opcoes: [(valor: Opcao, rotulo: String, icone: String?)]
    @Binding var escolhida: Opcao
    var identificador: String
    var larguraToda = false
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.opcoes) private var opcoesDoAparelho

    var body: some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(Array(opcoes.enumerated()), id: \.offset) { i, opcao in
                let ativa = opcao.valor == escolhida
                Button {
                    guard !ativa else { return }
                    if opcoesDoAparelho.reduzirMovimento { escolhida = opcao.valor }
                    else { withAnimation(.spring(duration: 0.3, bounce: 0)) { escolhida = opcao.valor } }
                } label: {
                    HStack(spacing: 6) {
                        if let icone = opcao.icone { Image(decorative: icone).resizable().frame(width: 15, height: 15) }
                        Text(opcao.rotulo).font(.subheadline.weight(ativa ? .semibold : .medium))
                    }
                    .fixedSize()
                    .foregroundStyle(paleta.cor(.texto))
                    .padding(.horizontal, 12)
                    .frame(minWidth: 86, minHeight: 36)
                    .frame(maxWidth: tamanho.isAccessibilitySize || larguraToda ? .infinity : nil)
                    .background {
                        if ativa {
                            // A sombra do mockup (0 1px 3px): no claro, é ela que separa o branco do trilho.
                            Capsule().fill(paleta.cor(.segmentadoEscolhido))
                                .shadow(color: paleta.cor(.sombraDoSegmentado), radius: 1.5, y: 1)
                        }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(opcao.rotulo)
                .accessibilityValue("\(i + 1) de \(opcoes.count)")
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier("\(identificador)-\(opcao.rotulo)")
            }
        }
        .padding(3)
        .background(paleta.cor(.segmentadoFundo), in: .capsule)
    }
}
