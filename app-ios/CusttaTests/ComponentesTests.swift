import Testing
import SwiftUI
@testable import Custta

/* Medidas das peças das telas que o mockup aprovado fixa e o print não tira sozinho: a caixa do campo não é
   elemento de acessibilidade, então a altura sai do layout, num UIHostingController. O ImageRenderer não serve:
   ele não instala o @FocusState do campo, e o SwiftUI acusa "Accessing FocusState's value outside of the body
   of a View" (aviso de execução que dispara o simctl diagnose da rodada). A escala 1 mede em pontos inteiros,
   a grade do mockup: na tela de 3x a linha do rótulo arredonda para 17,67 pt. */
@MainActor
struct ComponentesTests {
    private struct Campo: View {
        let senha: Bool
        @FocusState private var foco: String?
        @State private var texto = ""

        var body: some View {
            CampoDeEntrada(rotulo: "Senha", exemplo: "Sua senha", texto: $texto, identificador: "campo", senha: senha,
                           foco: $foco, chave: "campo")
                .frame(width: 320)
        }
    }

    private func altura(senha: Bool) -> CGFloat {
        UIHostingController(rootView: Campo(senha: senha).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
    }

    /// Rótulo de 18 pt e 6 de espaço em cima da caixa: 48 pt no campo de texto e 52 no de senha, em que o olho
    /// tem alvo de 44 pt (no mockup, 11 pt de margem e o olho de 44 pt com 8 pt para dentro de cada lado).
    @Test func campoDeSenhaCom52PontosComoOMockup() {
        #expect(altura(senha: false) == CGFloat(18 + 6 + 48))
        #expect(altura(senha: true) == CGFloat(18 + 6 + 52))
    }
}
