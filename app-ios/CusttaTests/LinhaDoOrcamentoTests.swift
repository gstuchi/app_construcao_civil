import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* A linha do orçamento na obra, na maior letra (conferência do Verniz contra o mockup da etapa 3, PR 1): o chevron ocupa só os
   18 pt dele, e a coluna de texto fica com os 306 pt do mockup no 18 Pro, com "80% usado de" numa linha. Medida num
   UIHostingController em escala 1, na largura da linha na tela (o iPhone menos os 20 de cada lado). */
@MainActor
struct LinhaDoOrcamentoTests {
    private func altura(_ resumo: ResumoOrcamento, comSeta: Bool, _ largura: CGFloat) -> CGFloat {
        UIHostingController(rootView: LinhaDoOrcamento(resumo: resumo, comSeta: comSeta).dynamicTypeSize(.accessibility5)
            .environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// Com a seta, a coluna de texto é a da linha sem seta 22 pt mais estreita: os 18 do chevron e os 4 do vão. Sem o quadro,
    /// o símbolo cresce com a letra e reserva cerca de 6 pt além do traço: no 18 Pro a coluna caía para 284, e o "de" de
    /// "80% usado de" ficava sozinho numa linha (o orçamento por tópico da vitrine). Nas três larguras de iPhone: 375, 402 e 440.
    @Test(arguments: [CGFloat(335), 362, 400]) func chevronOcupaOsDezoitoDoMockup(largura: CGFloat) throws {
        let dados = [DadosDeExemplo.vitrine(), DadosDeExemplo.vitrineDoOrcamento("porTopico"), DadosDeExemplo.vitrineDoOrcamento("perto"),
                     DadosDeExemplo.vitrineDoOrcamento("passou")]
        for (i, base) in dados.enumerated() {
            let casa = try #require(Estado.de(base).obras.first { $0.id == "v1" })
            let resumo = try #require(orcamentoObra(casa))
            let comSeta = altura(resumo, comSeta: true, largura)
            let semSeta = altura(resumo, comSeta: false, largura - 22)
            #expect(comSeta == semSeta, "vitrine \(i): com a seta, \(comSeta); sem ela e 22 pt mais estreita, \(semSeta)")
        }
    }
}
