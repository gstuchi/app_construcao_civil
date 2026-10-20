import Testing
import SwiftUI
@testable import Custta

/* As teclas encaixadas nas medidas do mockup (`.kv`): a faixa tem a mesma altura em 402 e em 375 pt, também com Texto em
   negrito; na letra grande as teclas param em 64 pt, a barra fica com 56 e o "Salvar" sai. Medidas num UIHostingController,
   em escala 1 (sem simulador de 375 pt). */
@MainActor
struct TecladoEncaixadoTests {
    private struct Faixa: View {
        let nome: String?
        @State private var centavos = 0
        var body: some View {
            TecladoEncaixado(centavos: $centavos, nome: nome, anterior: {}, proximo: {}, pronto: {}, salvarHabilitado: true, salvar: {})
        }
    }

    private func altura(_ nome: String?, largura: CGFloat, _ tamanho: DynamicTypeSize, negrito: Bool = false) -> CGFloat {
        UIHostingController(rootView: Faixa(nome: nome).dynamicTypeSize(tamanho).environment(\.legibilityWeight, negrito ? .bold : .regular)
            .environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// Padrão: 6 + a barra de 44 + 6 + as teclas (4 de 50 e 3 vãos de 8) + 12 + o "Salvar" de 56 = 348. Sem as setas ("Só o
    /// total"), sem a barra: 298. Na letra grande: 6 + a barra de 56 + 6 + as teclas (4 de 64 e 3 vãos de 8) = 348, sem o
    /// "Salvar"; e a barra aparece também no "Só o total", com o "Pronto".
    @Test(arguments: [CGFloat(402), 375]) func alturasDoMockup(largura: CGFloat) {
        #expect(altura("Elétrica · 9 de 71", largura: largura, .large) == 348)
        #expect(altura(nil, largura: largura, .large) == 298)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .accessibility5) == 348)
        #expect(altura(nil, largura: largura, .accessibility5) == 348)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .large, negrito: true) == 348)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .accessibility5, negrito: true) == 348)
        #expect(altura("Esquadrias de alumínio com vidro temperado · 71 de 71", largura: largura, .large) == 348,
                "o nome comprido corta numa linha, sem crescer a barra")
    }

    /// A grade nos dois tamanhos: a do TecladoDeValor não muda (62 pt e 10 de vão; 72 na letra grande) e a encaixada tem 50 e
    /// 8 (64 na letra grande). As teclas param no AX2: na AX5, a mesma altura da AX2.
    @Test func gradeNosDoisTamanhos() {
        func altura(_ tamanho: TamanhoDasTeclas, _ letra: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: GradeDeTeclas(centavos: .constant(0), tamanho: tamanho).dynamicTypeSize(letra)
                .environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: 402, height: CGFloat.infinity)).height
        }
        #expect(altura(.padrao, .large) == CGFloat(4 * 62 + 3 * 10))
        #expect(altura(.padrao, .accessibility5) == CGFloat(4 * 72 + 3 * 10))
        #expect(altura(.encaixado, .large) == CGFloat(4 * 50 + 3 * 8))
        #expect(altura(.encaixado, .accessibility2) == CGFloat(4 * 64 + 3 * 8))
        #expect(altura(.encaixado, .accessibility5) == CGFloat(4 * 64 + 3 * 8))
    }
}
