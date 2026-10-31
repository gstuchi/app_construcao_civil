import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As peças do orçamento na tela da obra (etapa 3, PR 1) que o print não prova sozinho: a barra dos três níveis (no "passou",
   a parte cheia para no previsto e o excesso começa depois da fresta), a frase com o dinheiro na mesma conta do núcleo e
   o aviso dos tópicos no âmbar sobre o vidro, medido por pixel no esquema da tela. */
@MainActor
struct OrcamentoTests {
    private func item(_ gasto: Double, de previsto: Double) -> ItemOrcamento {
        let estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "orcamento": .objeto(["modo": .texto("total"), "total": .numero(previsto)]),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(gasto), "topico": .texto("outros"), "descricao": .texto(""),
                                       "data": .texto("2026-02-01"), "pagamento": .texto("pix")])]),
        ])])]))
        return orcamentoObra(estado.obras[0])!.geral
    }

    @Test func barraDentroEPertoEnchemAtePctLimitadoA100() {
        let dentro = GeometriaDaBarra(item(700, de: 1000), largura: 300), perto = GeometriaDaBarra(item(920, de: 1000), largura: 300)
        #expect(dentro.cheia == 210 && dentro.listras == nil)
        #expect(perto.cheia == 276 && perto.listras == nil)
        let chegou = GeometriaDaBarra(item(1000.004, de: 1000), largura: 300)
        #expect(chegou.cheia == 300 && chegou.listras == nil, "meio centavo acima ainda é chegou: a barra cheia, sem listras")
        #expect(GeometriaDaBarra(item(333.4, de: 1000), largura: 300).cheia == 99, "pelo pct arredondado do site (33%), não pela conta exata")
    }

    /// No "passou", a parte cheia é o previsto dentro do gasto (800 de 1.000: 80% da barra), e o excesso listrado vai da
    /// fresta de 2 pt ao fim; pelo pct (100%), a barra encheria inteira e o excesso não apareceria.
    @Test func barraDoPassouParaNoPrevistoComFrestaEListras() {
        let g = GeometriaDaBarra(item(1000, de: 800), largura: 300)
        #expect(g.cheia == 240)
        #expect(g.listras == 242...300)
    }

    /// A frase "{pct}% usado de {previsto}" da linha, partida para o dinheiro ir para a própria linha na letra grande, é a
    /// mesma do núcleo.
    @Test func fraseDoUsadoEADoNucleo() {
        for i in [item(700, de: 1000), item(842_317.45, de: 800_000), item(812_536.95, de: 1_019_847.85)] {
            let p = partesDoUsado(i)
            #expect("\(p.antes) \(p.valor)" == usadoDoPrevisto(i))
        }
    }

    @Test func chipVerdeDentroEAmbarPertoEPassou() {
        #expect(corDoNivel(.ok) == .positivo)
        #expect(corDoNivel(.perto) == .alerta && corDoNivel(.passou) == .alerta)
    }

    /// Os pixels da barra (100 × 8 pt, escala 1, no escuro esmeralda): dentro do previsto, o degradê começa na Marca; perto e
    /// passou, o âmbar; no "passou", o fim é listrado (âmbar e âmbar a 38% alternados) e a fresta mostra o trilho.
    @Test func barraNasCoresDoNivel() throws {
        func pixels(_ i: ItemOrcamento) throws -> (Int) -> [Int] {
            let r = ImageRenderer(content: BarraDoOrcamento(item: i).frame(width: 100)
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
            let meio = h / 2, copia = rgba
            return { x in (0..<4).map { Int(copia[(meio * w + x) * 4 + $0]) } }
        }
        let perto = { (a: [Int], b: [Int]) in zip(a, b).allSatisfy { abs($0 - $1) <= 3 } }
        let dentro = try pixels(item(700, de: 1000))
        #expect(perto(dentro(4), [0x14, 0xB3, 0x9A, 0xFF]), "o degradê começa na Marca: \(dentro(4))")
        #expect(dentro(90)[3] < 0x40, "depois dos 70%, só o trilho (o texto a 14%): \(dentro(90))")
        #expect(perto(try pixels(item(920, de: 1000))(50), [0xE0, 0xA8, 0x3A, 0xFF]), "perto: o âmbar")
        let passou = try pixels(item(1000, de: 800))
        #expect(perto(passou(50), [0xE0, 0xA8, 0x3A, 0xFF]), "passou: o âmbar até o previsto")
        #expect(passou(81)[3] < 0x40, "a fresta de 2 pt mostra o trilho: \(passou(81))")
        let listras = (83..<99).map { passou($0)[3] }
        #expect(listras.contains { $0 == 0xFF } && listras.contains { $0 < 0xC0 }, "o excesso listrado alterna: \(listras)")
    }

    /// Na letra grande, o dinheiro da frase vai para a própria linha: em 1000 pt, onde a frase caberia numa linha, ela ocupa
    /// duas; no tamanho padrão, uma.
    @Test func dinheiroDaFraseNaPropriaLinhaNaLetraGrande() {
        func altura(_ t: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: FraseComDinheiro(antes: "80% usado de", valor: "R$\u{a0}1.019.847,85", cor: .texto)
                .dynamicTypeSize(t).environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: 1000, height: CGFloat.infinity)).height
        }
        let linha = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)).lineHeight
        #expect(altura(.accessibility5) > 1.8 * linha, "duas linhas: \(altura(.accessibility5)) com a linha de \(linha)")
        #expect(altura(.large) < 30, "uma linha: \(altura(.large))")
    }

    /// A cor mais comum entre os pixels opacos do desenho (o texto, sem a borda suavizada).
    private func corDoTexto(_ esquema: ColorScheme) throws -> [UInt8] {
        let r = ImageRenderer(content: AvisoDoOrcamento(texto: "2 tópicos passaram do previsto")
            .environment(\.paleta, Paleta()).environment(\.colorScheme, esquema))
        r.scale = 3
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let opacos = stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0 + 3] == 255 }.map { Array(rgba[$0..<$0 + 3]) }
        return Dictionary(grouping: opacos, by: { $0 }).max { $0.value.count < $1.value.count }?.key ?? []
    }

    /// O aviso dos tópicos no âmbar sobre o vidro: #5E3A03 no claro (o Alerta do site, #8A5A06, não fechava 4,5:1 sobre a
    /// aurora clara) e #FFD98A no escuro.
    @Test func avisoDosTopicosNoAmbarSobreOVidro() throws {
        #expect(try corDoTexto(.light) == [0x5E, 0x3A, 0x03])
        #expect(try corDoTexto(.dark) == [0xFF, 0xD9, 0x8A])
    }
}
