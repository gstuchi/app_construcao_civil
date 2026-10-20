import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O orçamento num iPhone de 375 pt (etapa 3, PR 1), na maior letra, com e sem Texto em negrito: nenhuma peça passa da
   largura. O laudo e as auditorias rodam no 18 Pro (402) e no Pro Max (440); 375 só aqui, num UIHostingController em escala
   1, com a largura de cada peça na tela (375 menos os 20 de cada lado; na folha, a linha já traz o recuo dela). */
@MainActor
struct OrcamentoEm375Tests {
    private let porTopico = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico"))

    private func largura<V: View>(_ view: V, _ disponivel: CGFloat, negrito: Bool) -> CGFloat {
        UIHostingController(rootView: view.dynamicTypeSize(.accessibility5)
            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: disponivel, height: CGFloat.infinity)).width
    }

    @Test(arguments: [false, true]) func telaDaObraEOrcamentoCabemEm375(negrito: Bool) throws {
        let casa = try #require(porTopico.obras.first { $0.id == "v1" })
        let resumo = try #require(orcamentoObra(casa))
        #expect(largura(LinhaDoOrcamento(resumo: resumo, comSeta: true), 335, negrito: negrito) <= 335, "a linha do orçamento")
        #expect(largura(CartaoDoOrcamento(resumo: resumo), 335, negrito: negrito) <= 335, "o cartão")
        let topicos = mapaDeTopicos(porTopico.config.topicosProprios)
        for linha in linhasPorTopico(resumo, topicos: topicos) + linhasForaDoOrcamento(resumo, topicos: topicos) {
            #expect(largura(LinhaDeTopicoNoOrcamento(linha: linha, identificador: linha.id), 335, negrito: negrito) <= 335, "\(linha.nome)")
        }
    }

    /// Na folha, o maior valor do teclado e o nome mais comprido dos tópicos fixos.
    @Test(arguments: [false, true]) func linhasDaFolhaCabemEm375(negrito: Bool) throws {
        let topico = try #require(topicosPadrao.max { $0.nome.count < $1.nome.count })
        let linha = LinhaDoTopicoNaFolha(topico: topico, centavos: tetoDoTeclado, ativa: true, proprio: false, primeira: true, ultima: true)
        #expect(largura(linha, 375, negrito: negrito) <= 375, "\(topico.nome)")
        let proprio = Topico(id: "c_x", nome: String(repeating: "Gesso e drywall ", count: 3), icone: "etiqueta")
        #expect(largura(LinhaDoTopicoNaFolha(topico: proprio, centavos: tetoDoTeclado, ativa: false, proprio: true, primeira: false,
                                              ultima: false), 375, negrito: negrito) <= 375, "o tópico próprio comprido")
        #expect(largura(TecladoEncaixado(centavos: .constant(tetoDoTeclado), nome: "\(topico.nome) · 21 de 71", anterior: {},
                                         proximo: {}, pronto: {}, salvarHabilitado: true, salvar: {}), 375, negrito: negrito) <= 375)
    }
}
