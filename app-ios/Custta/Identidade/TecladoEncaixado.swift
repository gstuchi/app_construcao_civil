import SwiftUI
import CusttaNucleo

/* As teclas encaixadas embaixo da folha do orçamento (mockup aprovado da etapa 3, parte 1, `.kv`; conselho de 19/10, decisão
   2): uma faixa sólida da Folha, com a linha fina em cima, com a barra (‹ › para a linha anterior e a seguinte, o nome da linha
   e "Pronto"), as teclas do teclado de valor (50 pt, 8 de vão, a mesma GradeDeTeclas do TecladoDeValor) e o "Salvar" de 56
   embaixo. Na letra de acessibilidade, as teclas param em 64 pt, o nome sai da barra e o "Salvar" sai enquanto as teclas estão
   abertas ("Pronto" fecha e ele volta). Sem as setas ("Só o total"), a barra só aparece na letra de acessibilidade, com o
   "Pronto": sem ela não sobraria nem o "Salvar" nem o "Pronto" (furo do mockup, levado ao Giovani). */
struct TecladoEncaixado: View {
    @Binding var centavos: Int
    /// "Elétrica · 9 de 71", com as setas ("Por tópico"); nil sem elas ("Só o total").
    let nome: String?
    let anterior: () -> Void
    let proximo: () -> Void
    let pronto: () -> Void
    let salvarHabilitado: Bool
    let salvar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        VStack(spacing: 0) {
            if nome != nil || grande {
                // A letra da barra para no xxxLarge (lida aqui fora: dentro do limite, nunca é de acessibilidade).
                BarraDasTeclas(nome: grande ? nil : nome, setas: nome != nil, grande: grande, anterior: anterior, proximo: proximo,
                               pronto: pronto)
                    .padding(.bottom, 6)
            }
            GradeDeTeclas(centavos: $centavos, tamanho: .encaixado)
            if !grande {
                Button("Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha())
                    .disabled(!salvarHabilitado)
                    .accessibilityIdentifier("salvarOrcamento")
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background {
            paleta.cor(.folha).ignoresSafeArea(edges: .bottom).accessibilityHidden(true)
        }
        .overlay(alignment: .top) { SeparadorDaFolha(recuo: 0) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tecladoEncaixado")
    }
}

/// A barra das teclas encaixadas: ‹ › de 44 × 38 no fundo das teclas (o toque de 44 × 44), o nome da linha ativa, numa linha
/// só, e "Pronto" na cor do link. A letra para no xxxLarge, como o título da folha, com o Visualizador de Conteúdo Grande nas
/// quatro peças; na letra de acessibilidade, a barra tem 56 pt e não mostra o nome (mockup). As setas são desenho, de 16 pt
/// (não letra): a letra fixa delas aparecia na auditoria de tipo dinâmico como texto sem elemento.
struct BarraDasTeclas: View {
    let nome: String?
    let setas: Bool
    let grande: Bool
    let anterior: () -> Void
    let proximo: () -> Void
    let pronto: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(spacing: 8) {
            if setas {
                seta("chevron.left", "Tópico anterior", "barraDasTeclas-anterior", anterior)
                seta("chevron.right", "Próximo tópico", "barraDasTeclas-proximo", proximo)
            }
            if let nome {
                Text(nome)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .accessibilityShowsLargeContentViewer()
                    .accessibilityIdentifier("barraDasTeclas-nome")
            } else {
                Spacer(minLength: 0)
            }
            Button(action: pronto) {
                Text("Pronto")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(paleta.cor(.linkNoVidro))
                    .padding(.horizontal, 6)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("barraDasTeclas-pronto")
        }
        .frame(minHeight: grande ? 56 : 44)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func seta(_ simbolo: String, _ rotulo: String, _ identificador: String, _ acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 16, height: 16)
                .foregroundStyle(paleta.cor(.texto))
                .frame(width: 44, height: 38)
                .background(paleta.cor(.tecla), in: .capsule)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotulo)
        .accessibilityShowsLargeContentViewer { Label(rotulo, systemImage: simbolo) }
        .accessibilityIdentifier(identificador)
    }
}
