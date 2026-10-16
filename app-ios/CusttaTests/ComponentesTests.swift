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

    private func alturaDaPilula(largura: CGFloat) -> CGFloat {
        UIHostingController(rootView: Limpando().dynamicTypeSize(.accessibility5).environment(\.displayScale, 3))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// A pílula "Limpando…" na maior letra num iPhone de 375 pt (SE, 12 e 13 mini) fica numa linha só, da altura que
    /// tem numa largura folgada, em vez de as reticências caírem sozinhas na linha de baixo (escala 3, a do 13 mini).
    @Test func pilulaDoLimpandoNumaLinhaNaMaiorLetraEm375Pontos() {
        #expect(alturaDaPilula(largura: 375) == alturaDaPilula(largura: 1000))
    }
}

/* A etiqueta "novo" entra no título da linha como imagem, colada à última palavra (mockup). O ImageRenderer não herda
   nada da tela: a imagem tem de sair na escala da tela, na Marca do esquema de cor e da pele, e crescer com a letra. */
@MainActor
struct EtiquetaNovoTests {
    private func imagem(_ esquema: ColorScheme, pele: Pele = .esmeralda, tamanho: DynamicTypeSize = .large) throws -> UIImage {
        try #require(EtiquetaNovo.imagem(paleta: Paleta(pele: pele), esquema: esquema, tamanho: tamanho, escala: 3))
    }

    /// RGBA do fundo da cápsula, 4 pt depois do começo dela (a imagem tem 4 pt de folga antes), na meia altura.
    private func fundo(_ imagem: UIImage) -> [UInt8] {
        guard let cg = imagem.cgImage else { return [] }
        let x = Int(8 * imagem.scale), y = cg.height / 2
        var rgba = [UInt8](repeating: 0, count: 4)
        let contexto = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        contexto?.draw(cg, in: CGRect(x: -x, y: y - cg.height + 1, width: cg.width, height: cg.height))
        return rgba
    }

    @Test func naEscalaDaTelaENaMarcaDoEsquemaEDaPele() throws {
        #expect(try imagem(.dark).scale == 3)
        #expect(fundo(try imagem(.dark)) == [0x14, 0xB3, 0x9A, 0xFF], "Esmeralda/Marca do escuro")
        #expect(fundo(try imagem(.light)) == [0x0B, 0x7A, 0x68, 0xFF], "Esmeralda/Marca do claro")
        #expect(fundo(try imagem(.dark, pele: .azul)) == [0x5B, 0x8C, 0xFF, 0xFF], "Azul/Marca do escuro")
    }

    @Test func cresceComALetra() throws {
        #expect(try imagem(.dark, tamanho: .accessibility5).size.width > imagem(.dark).size.width * 1.5)
    }
}
