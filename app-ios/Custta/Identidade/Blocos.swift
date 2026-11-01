import SwiftUI

/* As peças de bloco da identidade nova (etapa 4; mockup aprovado em ~/Documents/custta-mockups/nativo/etapa4/, parte1.css e
   "Medidas e especificação" do parte1.html): a grade de bordas 16/34, o bloco de vidro de um assunto, o bloco sólido
   protagonista (verde, ou âmbar no veredito), o rótulo, a nota e a etiqueta de dentro deles, e a placa, um tom chapado sem
   desfoque que não é vidro. Nenhuma tela as usa ainda: a obra (PR 1c) e as telas da análise. Nunca vidro dentro de vidro:
   dentro do bloco de vidro, só o sólido e a placa. */

/// A grade de bordas (ajuste 3 do mockup): toda forma (bloco, cápsula, botão, cápsula de abas, voltar) e o título solto
/// começam a 16 pt da borda da tela; todo texto, chip, ponto ou ícone dentro de uma forma, a 34 (os 16 e o recuo de 18 do
/// bloco). À direita, o mesmo. A letra máxima não muda as bordas; o texto centralizado é a exceção.
enum Grade {
    static let externa: CGFloat = 16
    static let recuo: CGFloat = 18
    static let interna: CGFloat = externa + recuo
    /// O espaço entre dois blocos.
    static let entreBlocos: CGFloat = 12

    /// O raio dos cantos do bloco e o recuo de cima e de baixo: 26 e 16 pt; 32 e 22 na letra de acessibilidade.
    static func raioDoBloco(_ tamanho: DynamicTypeSize) -> CGFloat { tamanho.isAccessibilitySize ? 32 : 26 }
    static func recuoVertical(_ tamanho: DynamicTypeSize) -> CGFloat { tamanho.isAccessibilitySize ? 22 : 16 }
}

extension EnvironmentValues {
    /// A tinta do bloco sólido em volta (nil fora dele): o rótulo, a nota, a etiqueta e o número de dentro seguem ela.
    @Entry var tintaDoBloco: Token? = nil
}

/// Um assunto por bloco, no vidro do conteúdo, com os cantos e o recuo da grade. Ocupa a largura toda; a borda de 16 pt é
/// da coluna da tela.
struct BlocoDeVidro<Conteudo: View>: View {
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { conteudo }
            .padding(.vertical, Grade.recuoVertical(tamanho))
            .padding(.horizontal, Grade.recuo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(tamanho)))
    }
}

/// O bloco sólido protagonista, um por tela, que não é vidro: o verde (o Total gasto da obra, o total do Relatório, o "Vale
/// a pena") ou o âmbar (o "Rende menos que o banco"), com o texto escuro, a sombra de 36 pt na cor do bloco (20% no escuro,
/// 22% no claro) e o filete de luz no topo. Os textos de dentro vêm na tinta do bloco, o secundário também (o mockup troca o
/// --sec pela tinta). No claro, a sombra do âmbar é o Alerta, mais escuro que o bloco, como o mockup.
struct BlocoSolido<Conteudo: View>: View {
    var cor: CorDoSolido = .verde
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let escuro = esquema == .dark
        let (fundo, tinta, sombra): (Token, Token, Token) = switch cor {
        case .verde: (.destaqueSolido, .tintaSobreDestaque, .destaque)
        case .ambar: (.solidoAmbar, .tintaSobreAmbar, escuro ? .solidoAmbar : .alerta)
        }
        let forma = RoundedRectangle(cornerRadius: Grade.raioDoBloco(tamanho))
        VStack(alignment: .leading, spacing: 0) { conteudo }
            .padding(.vertical, Grade.recuoVertical(tamanho))
            .padding(.horizontal, Grade.recuo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(paleta.cor(tinta))
            .environment(\.tintaDoBloco, tinta)
            .background {
                forma.fill(paleta.cor(fundo))
                    .shadow(color: paleta.cor(sombra).opacity(escuro ? 0.20 : 0.22), radius: 18, y: 14)
                    // O filete: a forma menos ela mesma 1 pt abaixo (o inset 0 1px 0 do mockup), afinando nas quinas.
                    .overlay { forma.subtracting(forma.offset(y: 1)).fill(paleta.cor(.luzDoSolido)) }
            }
    }
}

/// O alto do bloco: o rótulo e, à direita, a etiqueta; na letra de acessibilidade, a etiqueta embaixo do rótulo (o
/// .cab-bloco do mockup). 8 pt acima do número.
struct CabecalhoDoBloco<Etiqueta: View>: View {
    let rotulo: String
    @ViewBuilder var etiqueta: Etiqueta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            // O rótulo ocupa o que sobra pelo frame, e não um Spacer ao lado: com o Negrito, o Spacer arredondava para cima,
            // e o cabeçalho passava 1/3 pt da largura.
            RotuloDoBloco(texto: rotulo).frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
            etiqueta
        }
        .padding(.bottom, 8)
    }
}

extension CabecalhoDoBloco where Etiqueta == EmptyView {
    init(rotulo: String) { self.init(rotulo: rotulo) { EmptyView() } }
}

enum CorDoSolido: Sendable { case verde, ambar }

/// O rótulo do bloco ("Total gasto", "Corrigido pelo banco"): subheadline semibold no secundário do vidro; no sólido,
/// negrito na tinta dele.
struct RotuloDoBloco: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.tintaDoBloco) private var tinta

    var body: some View {
        Text(texto)
            .font(.subheadline.weight(tinta == nil ? .semibold : .bold))
            .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
    }
}

/// A nota embaixo do número ("bruto, sem correção", "Correção até hoje: +R$ …"): subheadline no secundário do vidro, ou na
/// tinta do sólido.
struct NotaDoBloco: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.tintaDoBloco) private var tinta

    var body: some View {
        Text(texto)
            .font(.subheadline)
            .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
            .padding(.top, 2)
    }
}

/// A etiqueta dentro do sólido ("46 lançamentos", "Vendida em 20/06/26"): a tinta do bloco sobre ela mesma a 14%, nas
/// medidas da `EtiquetaDoIndicador` (footnote semibold, recuo de 10 × 3 e o raio de uma linha, que não come a quina do
/// texto quando ela quebra na letra grande).
struct EtiquetaDoSolido: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.tintaDoBloco) private var tinta
    @ScaledMetric(relativeTo: .footnote) private var linha: CGFloat = 16

    var body: some View {
        let cor = paleta.cor(tinta ?? .tintaSobreDestaque)
        Text(texto)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(cor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(cor.opacity(0.14), in: .rect(cornerRadius: (linha + 6) / 2))
    }
}

extension View {
    /// A placa atrás das marcas de gráfico: um tom chapado do fundo, sem desfoque (não é vidro), para as cores ficarem a 3:1
    /// com a aurora atrás. A forte (84% no escuro, 92% no claro) vai atrás da barra empilhada da obra; a outra (58% e 66%),
    /// atrás do anel e dos gráficos de mês.
    func placa(forte: Bool = false, raio: CGFloat = 12) -> some View { modifier(Placa(forte: forte, raio: raio)) }
}

private struct Placa: ViewModifier {
    let forte: Bool
    let raio: CGFloat
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        content.background(paleta.cor(forte ? .placaForte : .placa), in: .rect(cornerRadius: raio))
    }
}
