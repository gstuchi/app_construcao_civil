import Testing
import CoreGraphics
import Foundation
@testable import Custta

/* A conta da ponte (PonteDaRolagem.swift): o meio do quadro do gasto vai ao meio da parte à vista, e o topo da pílula, ao
   topo dela, entre o recuo de cima (a barra) e o de baixo, preso ao começo e ao fim do conteúdo. Os números são os do iPhone
   17 Pro: janela de 874 pt e recuos de 116 e 34, o que deixa 724 pt à vista. */
struct PonteDaRolagemTests {
    @Test func gastoVaiAoMeioDaParteAVista() {
        // O meio do gasto (4.778 + 165 = 4.943) fica 116 + 362 pt abaixo do topo da janela.
        #expect(deslocamento(levando: CGRect(x: 16, y: 4778, width: 370, height: 330), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == 4465)
    }

    @Test func gastoPertoDoTopoParaNoComeco() {
        #expect(deslocamento(levando: CGRect(x: 16, y: 40, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == -116)
    }

    @Test func gastoPertoDoFimParaNoFim() {
        // O fim do conteúdo: 3.000 + 34 − 874 = 2.160.
        #expect(deslocamento(levando: CGRect(x: 16, y: 2900, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 3000) == 2160)
    }

    @Test func conteudoMaisCurtoQueAJanelaFicaNoComeco() {
        #expect(deslocamento(levando: CGRect(x: 16, y: 300, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 500) == -116)
    }

    /// O teclado da busca (ObraView.campoForaDaJanela): o campo fecha o teclado só a meia tela além da borda, onde a
    /// LazyVStack de antes o desmontava; na janela de 874 pt, 437 acima do topo ou abaixo do fim.
    @Test func campoForaDaJanelaSoAMeiaTelaDaBorda() {
        let janela = CGRect(x: 0, y: 0, width: 402, height: 874)
        func campo(_ y: CGFloat) -> CGRect { CGRect(x: 56, y: y, width: 272, height: 22) }
        #expect(!ObraView.campoForaDaJanela(campo(189), janela: janela))
        #expect(!ObraView.campoForaDaJanela(campo(-459), janela: janela))   // o fim do campo em −437: na borda
        #expect(ObraView.campoForaDaJanela(campo(-460), janela: janela))
        #expect(!ObraView.campoForaDaJanela(campo(1311), janela: janela))   // o topo em 874 + 437
        #expect(ObraView.campoForaDaJanela(campo(1312), janela: janela))
    }

    /// O alto no vão de 12 pt entre duas linhas, como na v1 a 400 na letra padrão (a linha de cima termina em 393,33 e a
    /// de baixo começa em 405,33): a linha do alto é a de baixo, e a fração negativa devolve o alto ao vão. A letra que muda
    /// escala as linhas, e o alto segue no vão acima da linha, sem pular para o topo dela.
    @Test func altoNoVaoFicaNoVaoQuandoALetraMuda() {
        let cima = IndexPath(indexes: [1, 1]), baixo = IndexPath(indexes: [1, 2])
        let alto = linhaDoAlto(400, em: [(cima, CGRect(x: 16, y: 289, width: 370, height: 104.33)),
                                         (baixo, CGRect(x: 16, y: 405.33, width: 370, height: 104.33))])
        #expect(alto?.indice == baixo)
        let fracao = alto?.fracao ?? 0
        let volta = CGFloat(405.33) + fracao * CGFloat(104.33)
        #expect(abs(volta - 400) < 0.01)
        // Na maior letra, a linha de baixo começa em 520 e tem 200 pt, e a de cima termina em 508: o alto fica no vão.
        let naMaiorLetra = CGFloat(520) + fracao * CGFloat(200)
        #expect(naMaiorLetra > 508 && naMaiorLetra < 520)
    }

    @Test func pilulaVaiAoTopoDaParteAVista() {
        // O topo da pílula (1.250) fica logo abaixo da barra: 1.250 − 116.
        #expect(deslocamento(levando: CGRect(x: 16, y: 1250, width: 370, height: 44), a: 0, recuoDeCima: 116,
                             recuoDeBaixo: 34, altura: 874, conteudo: 20000) == 1134)
    }
}
