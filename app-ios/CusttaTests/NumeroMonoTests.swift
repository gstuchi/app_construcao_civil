import Testing
import SwiftUI
import UIKit
@testable import Custta
import CusttaNucleo

/* O número mono da identidade nova (etapa 4, PR 1b; spec, "O número que encolhe"): os tamanhos do mockup na letra padrão e
   na máxima, crescendo a cada passo; o R$ e os centavos a 58% e 62% do número, nunca abaixo de 11 pt; o valor do núcleo
   partido; o maior valor, que cabe no sólido na letra máxima em 375 pt; e o R$ e os centavos na linha do número. */
@MainActor
struct NumeroMonoTests {
    @Test func medidasNaLetraPadraoENaMaxima() {
        let principal = TamanhoDoNumero.principal.medidas(corpo: 17)
        #expect(principal == MedidasDoNumero(numero: 40, moeda: 0.58 * 40, centavos: 0.62 * 40, fatorMinimo: 11 / (0.58 * 40)))
        let maxima = TamanhoDoNumero.principal.medidas(corpo: 53)
        #expect(maxima.numero == CGFloat(56) && maxima.fatorMinimo == 11 / (0.58 * CGFloat(56)))
        // Na linha, 58% do número fica abaixo de 11: o R$ e os centavos em 11, e o número não encolhe.
        #expect(TamanhoDoNumero.linha.medidas(corpo: 17) == MedidasDoNumero(numero: 17, moeda: 11, centavos: 11, fatorMinimo: 1))
        #expect(TamanhoDoNumero.allCases.map { $0.medidas(corpo: 17).numero } == [CGFloat(40), 30, 22, 17, 17])
        #expect(TamanhoDoNumero.allCases.map { $0.medidas(corpo: 53).numero } == [CGFloat(56), 48, 40, 34, 30])
    }

    /// Da menor letra à máxima, o número cresce a cada passo, como o texto do sistema, e chega ao tamanho do mockup na máxima;
    /// o R$ encolhido até o fator mínimo fica em 11 pt.
    @Test func cresceACadaPassoDaLetra() {
        let passos = DynamicTypeSize.allCases
        #expect(passos.count == 12 && corpoDoTexto(.large) == 17 && corpoDoTexto(.accessibility5) == 53)
        for tamanho in TamanhoDoNumero.allCases {
            let medidas = passos.map { tamanho.medidas(corpo: corpoDoTexto($0)) }
            #expect(zip(medidas, medidas.dropFirst()).allSatisfy { $0.numero < $1.numero }, "\(tamanho): \(medidas.map(\.numero))")
            #expect(abs(medidas[3].numero - tamanho.padrao) < 0.01 && abs(medidas[11].numero - tamanho.maximo) < 0.01, "\(tamanho): \(medidas.map(\.numero))")
            #expect(medidas.allSatisfy { $0.moeda * $0.fatorMinimo >= 11 - 1e-9 }, "\(tamanho): o R$ encolhido")
        }
    }

    @Test func partesDoValorDoNucleo() {
        #expect(partesDoValor(moeda(842_317.45)) == PartesDoValor(sinal: "", inteiro: "842.317", centavos: "45"))
        #expect(partesDoValor("−" + moeda(4_980)) == PartesDoValor(sinal: "−", inteiro: "4.980", centavos: "00"))
        #expect(partesDoValor(moeda(-5)) == PartesDoValor(sinal: "-", inteiro: "5", centavos: "00"))
        #expect(partesDoValor(moeda(.infinity)) == PartesDoValor(sinal: "", inteiro: "∞", centavos: nil))
        #expect(partesDoValor("—") == nil)
    }

    /// O maior valor (R$ 1.000.000.000,00) cabe nos 307 pt do sólido na letra máxima num iPhone de 375 pt (os 16 de borda e
    /// os 18 de recuo dos dois lados), sem chegar ao piso: encolhido, o R$ fica acima de 11 pt e o texto, numa linha.
    @Test func maiorValorCabeNoSolidoNaLetraMaximaEm375() {
        let valor = ValorEmDinheiro("R$\u{a0}1.000.000.000,00", mono: .principal).dynamicTypeSize(.accessibility5)
        let natural = UIHostingController(rootView: valor.fixedSize()).sizeThatFits(in: CGSize(width: 10_000, height: 10_000))
        let medidas = TamanhoDoNumero.principal.medidas(corpo: 53)
        let fator = 307 / natural.width
        #expect(fator < 1 && fator > medidas.fatorMinimo,
                "fator \(fator): o número em \(medidas.numero * fator) pt e o R$ em \(medidas.moeda * fator) pt")
        let em307 = UIHostingController(rootView: valor).sizeThatFits(in: CGSize(width: 307, height: 10_000))
        #expect(em307.width <= 307 && em307.height < natural.height, "\(em307) contra \(natural)")
    }

    /// Os pés e o alto de cada letra desenhada, da esquerda para a direita (colunas com tinta seguidas).
    private func letras(_ texto: String) throws -> [(topo: Int, base: Int)] {
        let r = ImageRenderer(content: ValorEmDinheiro(texto, mono: .principal)
            .environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
        r.scale = 2
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let colunas = (0..<w).map { x in (0..<h).filter { rgba[($0 * w + x) * 4 + 3] > 128 } }
        var saida: [(topo: Int, base: Int)] = []
        var atual: (topo: Int, base: Int)?
        for coluna in colunas {
            if let topo = coluna.first, let base = coluna.last {
                atual = atual.map { (min($0.topo, topo), max($0.base, base)) } ?? (topo, base)
            } else if let a = atual {
                saida.append(a)
                atual = nil
            }
        }
        if let atual { saida.append(atual) }
        return saida
    }

    /// O R$ e os centavos na linha do número, nunca sobrescritos: o pé do "R", o dos "8" grandes e o dos "8" dos centavos na
    /// mesma linha de base, e o alto do "R" e dos centavos bem abaixo do alto dos dígitos (58% e 62% do tamanho).
    @Test func moedaECentavosNaLinhaDoNumero() throws {
        let l = try letras("R$\u{a0}88,88")
        try #require(l.count == 7, "R, $, 8, 8, a vírgula, 8 e 8: \(l)")
        let (rs, oito, centavo) = (l[0], l[2], l[5])
        let altura = oito.base - oito.topo
        #expect(abs(rs.base - oito.base) <= 1 && abs(centavo.base - oito.base) <= 1, "\(l)")
        #expect(rs.base - rs.topo < altura * 3 / 4 && centavo.base - centavo.topo < altura * 3 / 4, "\(l)")
    }

    /// Na tela, o número cresce a cada passo da letra e chega ao tamanho do mockup na máxima: a largura natural do mesmo
    /// valor sobe a cada passo, e na máxima é 56/40 da padrão. (As medidas acima não provam que a vista as usa.)
    @Test func numeroNaTelaCresceACadaPasso() {
        let larguras = DynamicTypeSize.allCases.map { letra in
            UIHostingController(rootView: ValorEmDinheiro("R$\u{a0}88,88", mono: .principal).dynamicTypeSize(letra).fixedSize())
                .sizeThatFits(in: CGSize(width: 10_000, height: 10_000)).width
        }
        #expect(zip(larguras, larguras.dropFirst()).allSatisfy { $0 < $1 }, "\(larguras)")
        #expect(abs(larguras[11] / larguras[3] - 56.0 / 40) < 0.03, "\(larguras)")
    }
}
