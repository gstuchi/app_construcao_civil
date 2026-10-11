import SwiftUI

/* "Finalizar saída" (mockup aprovado finalizar-saida.html; o diálogo do ui-confirm.js:149 do site): a limpeza
   do cache local falhou, no sair ou na abertura, e entrar fica bloqueado até ela dar certo. Alerta do sistema
   com um botão só, sem Cancelar (o do site não fecha). O sistema fecha o alerta ao tocar: enquanto limpa, a
   tela fica sob o mesmo escurecido do alerta, sem aceitar toque, e só depois de meio segundo aparece a pílula
   "Limpando…" no lugar dele, para não piscar. Falhou de novo, o alerta volta com o erro; deu certo, o
   escurecido sai sem aviso. */
struct FinalizarSaida: ViewModifier {
    static let titulo = "Finalizar saída"
    static let texto = "Suas obras continuam salvas na sua conta. Falta limpar os dados do Custta que ficaram neste iPhone antes de entrar de novo."
    static let erro = "Ainda não foi possível limpar. Suas obras continuam salvas na sua conta. Tente de novo ou feche o Custta e abra outra vez."

    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @State private var pilula = false

    func body(content: Content) -> some View {
        let tentando = modelo.limpeza == .tentando
        content
            .accessibilityHidden(tentando)          // sob o escurecido, para o VoiceOver também: só a pílula fala
            .overlay {
                if tentando {
                    ZStack {
                        paleta.cor(.escurecido)
                            .ignoresSafeArea()
                            .contentShape(.rect)
                        if pilula { Limpando() }
                    }
                    .transition(opcoes.reduzirMovimento ? .identity : .opacity.animation(.easeOut(duration: 0.2)))
                }
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
        .accessibilityIdentifier("limpando")
        .onChange(of: anuncio, initial: true) { _, texto in AccessibilityNotification.Announcement(texto).post() }
    }
}

extension View {
    /// O alerta "Finalizar saída" e o "Limpando…", por cima de qualquer tela.
    func finalizaSaida() -> some View { modifier(FinalizarSaida()) }
}
