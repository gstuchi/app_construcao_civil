import Testing
import SwiftUI
import UIKit
@testable import Custta

/* O título e a cápsula de metadados da identidade nova (etapa 4, PR 1b; ajustes 1 e 2 do mockup): o título em SF Mono 600 de
   30 pt (44 na letra máxima), que quebra o nome comprido, o pequeno da barra de 16 pt (20), numa linha só, e a cápsula que
   abraça o conteúdo com o recuo do mockup. Medidos no layout, num UIHostingController em escala 1. */
@MainActor
struct TitulosTests {
    private func medida<V: View>(_ vista: V, _ letra: DynamicTypeSize = .large, largura: CGFloat = 10_000) -> CGSize {
        UIHostingController(rootView: vista.dynamicTypeSize(letra).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: 10_000))
    }

    /// Uma linha do SF Mono semibold no tamanho dado.
    private func linha(_ tamanho: CGFloat) -> CGFloat { UIFont.monospacedSystemFont(ofSize: tamanho, weight: .semibold).lineHeight }

    /// O título e o pequeno da barra são do SF Mono (a mesma largura para "i" e "M") e têm a altura de uma linha dele no
    /// tamanho do mockup, na letra padrão e na máxima.
    @Test func tituloEPequenoDaBarraNoMonoNosTamanhosDoMockup() {
        let estreito = medida(TituloMono(texto: "iiiiiiii").fixedSize()), largo = medida(TituloMono(texto: "MMMMMMMM").fixedSize())
        #expect(abs(estreito.width - largo.width) < 0.5, "\(estreito.width) contra \(largo.width)")
        for (letra, grande, pequeno) in [(DynamicTypeSize.large, CGFloat(30), CGFloat(16)), (.accessibility5, 44, 20)] {
            #expect(abs(medida(TituloMono(texto: "Casa"), letra).height - linha(grande)) < 1, "\(letra)")
            #expect(abs(medida(TituloPequenoMono(texto: "Casa", letra: letra), letra).height - linha(pequeno)) < 1, "\(letra)")
        }
    }

    /// O nome comprido quebra o título (o mockup: "nome comprido quebra em duas linhas"); o pequeno da barra fica numa linha.
    @Test func nomeCompridoQuebraOTituloENaoOPequenoDaBarra() {
        let nome = "Residencial Jardim das Palmeiras, bloco B"
        #expect(medida(TituloMono(texto: nome), largura: 370).height > 1.8 * linha(30))
        #expect(abs(medida(TituloPequenoMono(texto: nome, letra: .large), largura: 236).height - linha(16)) < 1)
    }

    /// A cápsula abraça o conteúdo, com o recuo de 18 dos lados e 10 + 12 em cima e embaixo (16 + 18 na letra de
    /// acessibilidade).
    @Test func capsulaAbracaOConteudoComORecuo() {
        let conteudo = Color.clear.frame(width: 100, height: 20)
        #expect(medida(CapsulaDeMetadados { conteudo }) == CGSize(width: 136, height: 42))
        #expect(medida(CapsulaDeMetadados { conteudo }, .accessibility1) == CGSize(width: 136, height: 54))
    }
}
