import SwiftUI

/* Cápsula de abas própria (decisão do mockup aprovado): a barra de vidro do PWA com a lente que
   desliza para a aba escolhida. O que a barra do sistema dava de graça vem à mão: VoiceOver lê o nome,
   "1 de 2" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
   letra. Na etapa 1, duas abas e nenhum +. */

enum Aba: String, CaseIterable, Identifiable, Sendable {
    case obras
    case ajustes

    var id: String { rawValue }
    var titulo: String { self == .obras ? "Obras" : "Ajustes" }
    var icone: String { self == .obras ? "Icones/predio" : "Icones/engrenagem" }
}

struct CapsulaDeAbas: View {
    @Binding var escolhida: Aba
    var abas: [Aba] = Aba.allCases
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Namespace private var lente

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(abas.enumerated()), id: \.element) { indice, aba in
                let ativa = aba == escolhida
                Button {
                    guard !ativa else { return }
                    if opcoes.reduzirMovimento { escolhida = aba }
                    else { withAnimation(.spring(duration: 0.35, bounce: 0.15)) { escolhida = aba } }
                } label: {
                    VStack(spacing: 2) {
                        Image(decorative: aba.icone).resizable().frame(width: 26, height: 24)
                        Text(aba.titulo).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(paleta.cor(ativa ? .linkNoVidro : .texto))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if ativa { Capsule().fill(paleta.cor(.lenteAba)).matchedGeometryEffect(id: "lente", in: lente) }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(aba.titulo)
                .accessibilityValue("\(indice + 1) de \(abas.count)")
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier("aba-\(aba.rawValue)")
                .accessibilityShowsLargeContentViewer { Label(aba.titulo, image: aba.icone) }
            }
        }
        .padding(4)
        .frame(height: 62)
        .superficie(.navegacao, em: .capsule)
        .dynamicTypeSize(.large)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)               // da borda da tela (mockup aprovado), como a barra de abas do sistema
    }
}
