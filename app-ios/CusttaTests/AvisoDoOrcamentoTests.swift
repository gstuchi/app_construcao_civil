import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O aviso dos tópicos ("N tópicos passaram do previsto") nunca passa da largura que recebe. Com o lado do triângulo fracionário
   (16/15 da letra; 0,8 dela na letra de acessibilidade), o texto ao lado recebia uma largura fora da grade de pixels e
   arredondava para cima: o aviso passava 1 pixel, e a linha do orçamento com ele (OrcamentoEm375Tests, com Texto em negrito).
   Medido num UIHostingController, como os outros testes de largura. */
@MainActor
struct AvisoDoOrcamentoTests {
    private func largura(_ texto: String, _ disponivel: CGFloat, _ tamanho: DynamicTypeSize, negrito: Bool) -> CGFloat {
        UIHostingController(rootView: AvisoDoOrcamento(texto: texto).dynamicTypeSize(tamanho)
            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: disponivel, height: CGFloat.infinity)).width
    }

    /// O aviso do orçamento por tópico da vitrine, das larguras de coluna da linha nos iPhones (a 375 pt na maior letra, 279) às
    /// do cartão da tela Orçamento, na letra padrão, nas três maiores fora da acessibilidade e nas cinco de acessibilidade.
    @Test(arguments: [false, true]) func naoPassaDaLargura(negrito: Bool) throws {
        let estado = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico"))
        let casa = try #require(estado.obras.first { $0.id == "v1" })
        let resumo = try #require(orcamentoObra(casa))
        let aviso = try #require(avisoDosTopicos(resumo))
        let tamanhos: [DynamicTypeSize] = [.large, .xLarge, .xxLarge, .xxxLarge, .accessibility1, .accessibility2, .accessibility3,
                                           .accessibility4, .accessibility5]
        for tamanho in tamanhos {
            for disponivel in stride(from: CGFloat(240), through: 340, by: 1) {
                let medida = largura(aviso, disponivel, tamanho, negrito: negrito)
                #expect(medida <= disponivel, "\(tamanho) a \(disponivel) pt: \(medida)")
            }
        }
    }
}
