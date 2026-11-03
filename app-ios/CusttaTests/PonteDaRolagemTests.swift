import Testing
import CoreGraphics
@testable import Custta

/* A conta da ponte do rolar até o gasto salvo (PonteDaRolagem.swift): o meio do quadro do gasto vai ao meio da parte à vista,
   entre o recuo de cima (a barra) e o de baixo, preso ao começo e ao fim do conteúdo. Os números são os do iPhone 17 Pro:
   janela de 874 pt e recuos de 116 e 34, o que deixa 724 pt à vista. */
struct PonteDaRolagemTests {
    @Test func gastoVaiAoMeioDaParteAVista() {
        // O meio do gasto (4.778 + 165 = 4.943) fica 116 + 362 pt abaixo do topo da janela.
        #expect(deslocamentoAteOMeio(de: CGRect(x: 16, y: 4778, width: 370, height: 330), recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == 4465)
    }

    @Test func gastoPertoDoTopoParaNoComeco() {
        #expect(deslocamentoAteOMeio(de: CGRect(x: 16, y: 40, width: 370, height: 60), recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == -116)
    }

    @Test func gastoPertoDoFimParaNoFim() {
        // O fim do conteúdo: 3.000 + 34 − 874 = 2.160.
        #expect(deslocamentoAteOMeio(de: CGRect(x: 16, y: 2900, width: 370, height: 60), recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 3000) == 2160)
    }

    @Test func conteudoMaisCurtoQueAJanelaFicaNoComeco() {
        #expect(deslocamentoAteOMeio(de: CGRect(x: 16, y: 300, width: 370, height: 60), recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 500) == -116)
    }
}
