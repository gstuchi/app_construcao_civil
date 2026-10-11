import SwiftUI

/* "Finalizar saída" (mockup aprovado finalizar-saida.html; o diálogo do ui-confirm.js:149 do site): a limpeza
   do cache local falhou, no sair ou na abertura, e entrar fica bloqueado até ela dar certo. Alerta do sistema
   com um botão só, sem Cancelar (o do site não fecha). O sistema fecha o alerta ao tocar: enquanto limpa, só
   depois de meio segundo aparece a pílula "Limpando…" no lugar dele, para não piscar. Falhou de novo, o alerta
   volta com o erro; deu certo, o escurecido sai sem aviso.

   O escurecido do app fica de pé durante toda a limpeza pendente (conferência do Verniz, 11/10): sob o alerta ele
   se soma ao do sistema e, no escuro, apaga o que brilha atrás do vidro do alerta (o botão branco da Apple, na
   letra maior); no claro, sob o alerta ele é transparente, porque o texto do botão é escuro. Sem o alerta, sozinho,
   fica no total dos dois. Assim a tela não clareia quando o alerta fecha nem aceita toque até a limpeza terminar. */
struct FinalizarSaida: ViewModifier {
    static let titulo = "Finalizar saída"
    static let texto = "Suas obras continuam salvas na sua conta. Falta limpar os dados do Custta que ficaram neste iPhone antes de entrar de novo."
    static let erro = "Ainda não foi possível limpar. Suas obras continuam salvas na sua conta. Tente de novo ou feche o Custta e abra outra vez."

    private enum Nivel: Equatable { case nenhum, sobOAlerta, total }

    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @State private var nivel = Nivel.nenhum
    @State private var alertaFechando = false
    @State private var vigia = VigiaDoAlerta()
    @State private var pilula = false

    func body(content: Content) -> some View {
        let tentando = modelo.limpeza == .tentando
        content
            .overlay {
                if nivel != .nenhum {
                    ZStack {
                        paleta.cor(nivel == .total ? .escurecido : .escurecidoSobOAlerta)
                            .ignoresSafeArea()
                            .contentShape(.rect)
                        if pilula && tentando { Limpando() }
                    }
                    .transition(.opacity)
                }
            }
            .onChange(of: alvo, initial: true) { antes, depois in
                withAnimation(Self.curva(de: antes, para: depois)) { nivel = depois }
            }
            // O SwiftUI só roda a ação do botão no fim do fechamento do alerta: o escurecido sobe para o total quando
            // o fechamento começa, junto com o sumiço do escurecido do sistema.
            .onChange(of: pendente, initial: true) { _, aberto in
                alertaFechando = false
                if aberto {
                    vigia.vigiar { alertaFechando = true }
                } else { vigia.parar() }
            }
            .task(id: tentando) {
                pilula = false
                guard tentando else { return }
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled { pilula = true }
            }
            // O alerta num fundo vazio, para o tint valer só nele: o botão na cor do texto, como o do "Sair da conta?"
            // (o LinkNoVidro do mockup fica em 4,45:1 na cápsula do alerta no Pro Max, no escuro azul).
            .background {
                Color.clear
                    .alert(Self.titulo, isPresented: Binding(get: { pendente }, set: { _ in })) {
                        Button("Tentar limpar novamente") { modelo.tentarLimparDeNovo() }
                    } message: {
                        Text(modelo.limpeza == .pendente(erro: true) ? Self.erro : Self.texto)
                    }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: modelo.limpeza != nil)
    }

    private var pendente: Bool {
        if case .pendente = modelo.limpeza { return true }
        return false
    }

    private var alvo: Nivel {
        switch modelo.limpeza {
        case nil: .nenhum
        case .pendente: alertaFechando ? .total : .sobOAlerta
        case .tentando: .total
        }
    }

    /// Acompanha o escurecido do sistema, que entra em uns 0,19 s quando o alerta abre e sai em 0,13 s quando ele fecha
    /// (vídeo no iOS 27). Esmaecer não é movimento: com `opcoes.reduzirMovimento` o esmaecimento fica, como o do sistema.
    private static func curva(de antes: Nivel, para depois: Nivel) -> Animation {
        switch (antes, depois) {
        case (_, .sobOAlerta): .easeOut(duration: 0.19)
        case (.sobOAlerta, .total): .easeOut(duration: 0.13)
        default: .easeOut(duration: 0.2)
        }
    }
}

/// A pílula do "tentando", onde estava o alerta: vidro sobre a superfície sólida, porque no centro da tela de entrar
/// ela cai sobre o botão branco da Apple, e o vidro sozinho clareava ali (o "Limpando…" ficava em 1,5:1).
private struct Limpando: View {
    @Environment(\.paleta) private var paleta
    private let anuncio = "Limpando"

    var body: some View {
        HStack(spacing: 10) {
            ProgressView().tint(paleta.cor(.texto))
            Text("Limpando…")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 48)
        .glassEffect(.regular, in: .capsule)
        .background(paleta.cor(.superficie), in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(anuncio)
        // Modal: o VoiceOver fica nela, como no escurecido. Esconder a tela de baixo pela raiz não serve: o
        // accessibilityHidden(false) de fora revelava a aurora, o globo e o véu, que se escondem por dentro.
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("limpando")
        .onChange(of: anuncio, initial: true) { _, texto in AccessibilityNotification.Announcement(texto).post() }
    }
}

extension View {
    /// O alerta "Finalizar saída" e o "Limpando…", por cima de qualquer tela.
    func finalizaSaida() -> some View { modifier(FinalizarSaida()) }
}
