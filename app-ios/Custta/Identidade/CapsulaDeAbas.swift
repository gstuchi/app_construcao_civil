import SwiftUI

/* Cápsula de abas própria (decisão do mockup aprovado): a barra de vidro do PWA com a pílula que
   desliza para a aba escolhida. A pílula é sólida, na tinta da marca com o rótulo em SobreTinta, como o
   segmentado da entrada (decisão do Giovani em 10/10): o rótulo da aba escolhida fica no contraste dos
   dois tokens com qualquer coisa passando por baixo; na lente de vidro, a lista rolada derrubava o "Obras"
   para 3,8:1 no escuro. O que a barra do sistema dava de graça vem à mão: VoiceOver lê o nome,
   "1 de 2" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
   letra. O + volta na etapa 2, ao lado da cápsula e na Tinta (mockup): lança gasto na obra; some onde não há o que
   criar (Ajustes), como o do site, e a cápsula ocupa a largura toda. */

/// O + ao lado da cápsula: o rótulo para o VoiceOver ("Lançar gasto") e o que ele faz.
struct AcaoDoMais {
    let rotulo: String
    let acao: () -> Void
}

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
    var mais: AcaoDoMais?
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Namespace private var pilula

    var body: some View {
        HStack(spacing: 10) {
            abasNaCapsula
            if let mais {
                Button(action: mais.acao) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(paleta.cor(.sobreTinta))
                        .frame(width: 62, height: 62)
                        .background(paleta.cor(.tinta), in: .circle)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mais.rotulo)
                .accessibilityIdentifier("botaoMais")
                .accessibilityShowsLargeContentViewer { Label(mais.rotulo, systemImage: "plus") }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .dynamicTypeSize(.large)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)               // da borda da tela (mockup aprovado), como a barra de abas do sistema
        .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.35, bounce: 0), value: mais != nil)
    }

    private var abasNaCapsula: some View {
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
                    .foregroundStyle(paleta.cor(ativa ? .sobreTinta : .texto))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if ativa { Capsule().fill(paleta.cor(.tinta)).matchedGeometryEffect(id: "pilula", in: pilula) }
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
    }
}
