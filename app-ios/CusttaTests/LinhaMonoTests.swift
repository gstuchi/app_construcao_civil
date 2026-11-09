import Testing
import SwiftUI
import UIKit
@testable import Custta
import CusttaNucleo

/* A linha do gasto na forma mono da identidade nova (etapa 4, PR 1b): sem o ícone quadrado da etapa 3, com o valor ao lado
   do título enquanto cabe e embaixo dele quando não cabe, e 52 pt de altura mínima. Medida no layout, num
   UIHostingController em escala 1, e nos pixels, no escuro. */
@MainActor
struct LinhaMonoTests {
    private func gasto(_ valor: Double) -> Gasto {
        Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(valor), "topico": .texto("x"),
                                       "descricao": .texto("Cal"), "data": .texto("2026-10-10"), "pagamento": .texto("pix")])]),
        ])])])).obras[0].gastos[0]
    }

    private func linha(_ g: Gasto, mono: Bool) -> some View {
        LinhaDeGastoView(gasto: g, linha: linhaDeGasto(g, topicos: mapaDeTopicos([]))).environment(\.linhaMono, mono)
    }

    /// Os pixels RGBA (pré-multiplicados) da linha na largura dada, no escuro, em escala 1.
    private func pixels(_ conteudo: some View) throws -> (w: Int, h: Int, rgba: [UInt8]) {
        let r = ImageRenderer(content: conteudo.environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
        r.scale = 1
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return (w, h, rgba)
    }

    /// Há tinta nos 30 pt antes do recuo da direita? Com o título e a linha de baixo curtos ("Cal"; "x · Pix · 10/10/26"),
    /// só o valor ao lado do título chega lá; embaixo do título, ele começa no recuo da esquerda e não passa de 190 pt.
    private func valorAoLado(_ g: Gasto, largura: Int) throws -> Bool {
        let p = try pixels(linha(g, mono: true).frame(width: CGFloat(largura)))
        return (0..<p.h).contains { y in ((largura - 48)..<(largura - 18)).contains { x in p.rgba[(y * p.w + x) * 4 + 3] > 128 } }
    }

    /// A altura da tinta nos 8 pt antes do recuo da direita: os centavos (",00") do valor inteiro têm ~8 pt; as reticências do
    /// valor cortado, ~3.
    private func tintaNaPontaDireita(_ g: Gasto, largura: Int) throws -> Int {
        let p = try pixels(linha(g, mono: true).frame(width: CGFloat(largura)))
        let linhas = (0..<p.h).filter { y in ((largura - 26)..<(largura - 18)).contains { x in p.rgba[(y * p.w + x) * 4 + 3] > 128 } }
        return (linhas.last ?? 0) - (linhas.first ?? 0) + 1
    }

    /// O valor ao lado do título fica inteiro: o de R$ 1 bilhão, numa linha de 370 pt (o cartão num iPhone de 402), cabe ao
    /// lado e termina nos centavos, sem reticências (a pilha dava ao valor só a metade da linha).
    @Test func valorAoLadoNaoCorta() throws {
        #expect(try valorAoLado(gasto(1_000_000_000), largura: 370))
        #expect(try tintaNaPontaDireita(gasto(1_000_000_000), largura: 370) >= 6)
        #expect(try tintaNaPontaDireita(gasto(4_980), largura: 370) >= 6)
    }

    /// O valor fica ao lado do título enquanto sobram 120 pt para o título: numa linha de 280 pt (244 sem o recuo), o comum
    /// fica ao lado e o de R$ 1 bilhão desce para baixo dele; em 343 pt (o cartão num iPhone de 375; 307 sem o recuo), o de
    /// R$ 1.234.567,89 fica ao lado e o de R$ 1 bilhão, com mais de 175 pt, ainda desce. A linha tem 52 pt no mínimo.
    @Test func valorAoLadoDoTituloOuEmbaixoDele() throws {
        let largura = { (valor: Double) in
            UIHostingController(rootView: ValorEmDinheiro("−" + moeda(valor), mono: .linha).fixedSize())
                .sizeThatFits(in: CGSize(width: 1000, height: 1000)).width
        }
        #expect(largura(4_980) <= 244 - 12 - 120 && largura(1_234_567.89) <= 307 - 12 - 120 && largura(1_000_000_000) > 307 - 12 - 120,
                "\(largura(4_980)), \(largura(1_234_567.89)) e \(largura(1_000_000_000))")
        #expect(try valorAoLado(gasto(4_980), largura: 280))
        #expect(try !valorAoLado(gasto(1_000_000_000), largura: 280))
        #expect(try valorAoLado(gasto(1_234_567.89), largura: 343))
        #expect(try !valorAoLado(gasto(1_000_000_000), largura: 343))
        let altura = UIHostingController(rootView: linha(gasto(4_980), mono: true).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: 1000, height: 10_000)).height
        #expect(altura >= 52, "\(altura)")
    }

    /// A linha não passa da largura do cartão em nenhum tamanho de letra, nas larguras dos iPhones, com os lançamentos da
    /// vitrine e o de R$ 1 bilhão: o ícone do tópico, que cresce com a letra, fica ao lado do texto de baixo.
    @Test func linhaNaoPassaDaLargura() {
        let estado = Estado.de(DadosDeExemplo.vitrine())
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        let gastos = Array(estado.obras[0].gastos.prefix(6)) + [gasto(1_000_000_000)]
        for letra in DynamicTypeSize.allCases {
            for largura in [CGFloat(343), 370, 408] {
                for g in gastos {
                    let vista = LinhaDeGastoView(gasto: g, linha: linhaDeGasto(g, topicos: topicos)).environment(\.linhaMono, true)
                        .dynamicTypeSize(letra)
                    let medida = UIHostingController(rootView: vista).sizeThatFits(in: CGSize(width: largura, height: 10_000)).width
                    #expect(medida == largura, "\(g.id) \(letra) em \(largura): \(medida)")
                }
            }
        }
    }

    /// O ícone quadrado da etapa 3 (o fundo FantasmaFundo, #0A3F30 no escuro) sai da linha mono; a da etapa 3 continua com ele.
    @Test func semOIconeQuadrado() throws {
        func fundosDoIcone(mono: Bool) throws -> Int {
            let r = ImageRenderer(content: linha(gasto(4_980), mono: mono).frame(width: 343)
                .environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
            r.scale = 1
            let imagem = try #require(r.cgImage)
            let (w, h) = (imagem.width, imagem.height)
            var rgba = [UInt8](repeating: 0, count: w * h * 4)
            rgba.withUnsafeMutableBytes { bytes in
                CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                    .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
            }
            return stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0] == 0x0A && rgba[$0 + 1] == 0x3F && rgba[$0 + 2] == 0x30 }.count
        }
        #expect(try fundosDoIcone(mono: false) > 500)
        #expect(try fundosDoIcone(mono: true) == 0)
    }

    /// O ícone do tópico cresce com a letra: na máxima, a linha de baixo mede o ícone de 42 pt, o vão de 6 e o texto.
    @Test func iconeDoTopicoCresceComALetra() {
        let g = gasto(4_980), l = linhaDeGasto(g, topicos: mapaDeTopicos([]))
        func ideal(_ v: some View) -> CGFloat {
            UIHostingController(rootView: v.dynamicTypeSize(.accessibility5).fixedSize())
                .sizeThatFits(in: CGSize(width: 10_000, height: 10_000)).width
        }
        let texto = ideal(Text([l.topico, l.pagamento, l.data].compactMap { $0 }.joined(separator: " · ")).font(.subheadline))
        let linhaInteira = ideal(linha(g, mono: true))
        #expect(abs(linhaInteira - 2 * 18 - 42 - 6 - texto) < 1, "\(linhaInteira) e \(texto)")
    }
}
