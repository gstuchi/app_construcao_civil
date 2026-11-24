import SwiftUI
import CusttaNucleo

/* As teclas do preço do "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `sim-teclado`): tomam o lugar da cápsula de
   abas enquanto a pessoa digita o "Se eu vender por". Uma faixa da Folha com os cantos de cima redondos, a barra ("Preço de
   venda" e "OK") e as teclas do teclado de valor da etapa 3 (a GradeDeTeclas encaixada: os centavos entram pela direita, com
   "00" e apagar), num campo só, sem ‹ ›. O que a digitação faz com o campo é do núcleo (`PrecoNasTeclas`, decisão do Giovani
   de 24/11): o valor fica à vista, a primeira tecla o substitui e o OK sem digitar deixa tudo como estava. A conta da tela
   acompanha cada tecla, como no site. Entram na área segura de baixo da tela da aba (`safeAreaInset`), como o "Salvar" das
   folhas: é por ela que a rolagem sabe onde as teclas começam. */
struct TeclasDoPreco: View {
    @Binding var campos: CamposDoSimulador
    let ok: () -> Void
    @State private var preco = PrecoNasTeclas()
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    var body: some View {
        VStack(spacing: 0) {
            // A letra da barra para no xxxLarge, como a das teclas encaixadas da etapa 3, com o Visualizador de Conteúdo Grande.
            HStack(spacing: 8) {
                Text("Preço de venda")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityShowsLargeContentViewer()
                    .accessibilityIdentifier("teclasDoPreco-titulo")
                Button(action: ok) {
                    Text("OK")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(paleta.cor(.destaqueTexto))
                        .padding(.horizontal, 6)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityShowsLargeContentViewer()
                .accessibilityIdentifier("teclasDoPreco-ok")
            }
            .padding(.horizontal, 8)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            GradeDeTeclas(centavos: Binding(get: { preco.centavos }, set: { campos.precoDigitado = preco.digitar($0) }),
                          tamanho: .encaixado)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        // Embaixo, a área segura do aparelho (34 pt; no mockup, 30): o fundo desce até a borda da tela.
        .padding(.bottom, 0)
        .background { fundo.ignoresSafeArea(edges: .bottom).accessibilityHidden(true) }
        .accessibilityElement(children: .contain)
        // O gesto de sair do VoiceOver (o Z) fecha as teclas, como o "OK". Só existe com elas abertas: não engole o de mais ninguém.
        .accessibilityAction(.escape, ok)
        .accessibilityIdentifier("teclasDoPreco")
    }

    /// A Folha, como a das folhas do app: a cor do token sobre o desfoque do que rola atrás; com "Reduzir transparência",
    /// opaca, sobre o Fundo. Sem a sombra de cima do mockup (preto a 35%): o app não tem token de sombra de painel, e cor
    /// solta não entra.
    @ViewBuilder private var fundo: some View {
        let forma = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
        if opcoes.reduzirTransparencia { forma.fill(paleta.cor(.folha)).background(paleta.cor(.fundo), in: forma) }
        else { forma.fill(paleta.cor(.folha)).background(.ultraThinMaterial, in: forma) }
    }
}
