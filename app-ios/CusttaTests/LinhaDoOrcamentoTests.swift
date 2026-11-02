import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O bloco do orçamento na obra, na maior letra (conferência do Verniz contra o mockup da etapa 3, PR 1; o bloco da etapa 4,
   PR 1c): a seta ocupa só os 20 pt dela, 10 pt depois do texto. Medido num UIHostingController em escala 1, na largura do
   bloco na tela (o iPhone menos os 16 de cada lado). */
@MainActor
struct LinhaDoOrcamentoTests {
    private func altura(_ resumo: ResumoOrcamento, comSeta: Bool, _ largura: CGFloat) -> CGFloat {
        UIHostingController(rootView: LinhaDoOrcamento(resumo: resumo, comSeta: comSeta).dynamicTypeSize(.accessibility5)
            .environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// Com a seta, a coluna de texto é a do bloco sem seta 30 pt mais estreito: os 20 da seta e os 10 do vão (o .k-linha do
    /// mockup). Sem o quadro, o símbolo cresce com a letra e reserva cerca de 6 pt além do traço: no 18 Pro a coluna caía, e o
    /// "de" de "80% usado de" ficava sozinho numa linha (o orçamento por tópico da vitrine). Nas três larguras de iPhone: 375,
    /// 402 e 440.
    @Test(arguments: [CGFloat(343), 370, 408]) func setaOcupaOsVinteDoMockup(largura: CGFloat) throws {
        let dados = [DadosDeExemplo.vitrine(), DadosDeExemplo.vitrineDoOrcamento("porTopico"), DadosDeExemplo.vitrineDoOrcamento("perto"),
                     DadosDeExemplo.vitrineDoOrcamento("passou")]
        for (i, base) in dados.enumerated() {
            let casa = try #require(Estado.de(base).obras.first { $0.id == "v1" })
            let resumo = try #require(orcamentoObra(casa))
            let comSeta = altura(resumo, comSeta: true, largura)
            let semSeta = altura(resumo, comSeta: false, largura - 30)
            #expect(comSeta == semSeta, "vitrine \(i): com a seta, \(comSeta); sem ela e 30 pt mais estreito, \(semSeta)")
        }
    }
}
