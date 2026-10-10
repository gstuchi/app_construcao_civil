import Testing
import SwiftUI
@testable import Custta

/* Medidas das peças das telas que o mockup aprovado fixa e o print não tira sozinho: a caixa do campo não é
   elemento de acessibilidade, então a altura sai do layout, pelo ImageRenderer (o tamanho é o do layout; o
   pixel do vidro é que varia entre rodadas). */
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

    private func altura(senha: Bool) throws -> CGFloat {
        try #require(ImageRenderer(content: Campo(senha: senha)).uiImage).size.height
    }

    /// Rótulo de 18 pt e 6 de espaço em cima da caixa: 48 pt no campo de texto e 52 no de senha, em que o olho
    /// tem alvo de 44 pt (no mockup, 11 pt de margem e o olho de 44 pt com 8 pt para dentro de cada lado).
    @Test func campoDeSenhaCom52PontosComoOMockup() throws {
        #expect(try altura(senha: false) == 18 + 6 + 48)
        #expect(try altura(senha: true) == 18 + 6 + 52)
    }
}
