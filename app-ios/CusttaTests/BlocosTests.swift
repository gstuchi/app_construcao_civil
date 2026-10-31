import Testing
import SwiftUI
@testable import Custta

/* As peças de bloco da identidade nova (etapa 4, PR 1b) que o print não prova sozinho: as cores do sólido verde e do âmbar
   nos dois temas, com o filete de luz no topo; a tinta do bloco no rótulo, na nota e na etiqueta de dentro dele; as duas
   placas; e o recuo e o raio do bloco, que crescem na letra de acessibilidade. */
@MainActor
struct BlocosTests {
    /// Os pixels RGBA (pré-multiplicados) do desenho no esquema dado.
    private func pixels(_ conteudo: some View, _ esquema: ColorScheme, escala: CGFloat = 1) throws -> (w: Int, h: Int, em: (Int, Int) -> [Int]) {
        let r = ImageRenderer(content: conteudo.environment(\.paleta, Paleta()).environment(\.colorScheme, esquema))
        r.scale = escala
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let copia = rgba
        return (w, h, { x, y in (0..<4).map { Int(copia[(y * w + x) * 4 + $0]) } })
    }

    private func perto(_ a: [Int], _ b: [Int], folga: Int = 2) -> Bool { zip(a, b).allSatisfy { abs($0 - $1) <= folga } }

    /// O fundo do sólido (#3AD17E nos dois temas; o âmbar, #FFD98A e #F2C15A) e o filete de luz de 1 pt no topo, o branco a
    /// 35% sobre ele; logo abaixo do filete, o fundo de novo.
    @Test(arguments: [ColorScheme.dark, .light])
    func solidoVerdeEAmbarComOFileteNoTopo(_ esquema: ColorScheme) throws {
        let ambar = esquema == .dark ? [0xFF, 0xD9, 0x8A] : [0xF2, 0xC1, 0x5A]
        for (cor, fundo) in [(CorDoSolido.verde, [0x3A, 0xD1, 0x7E]), (.ambar, ambar)] {
            let p = try pixels(BlocoSolido(cor: cor) { Color.clear }.frame(width: 100, height: 60), esquema)
            let filete = fundo.map { Int((Double($0) + Double(255 - $0) * 0.35).rounded()) }
            #expect(perto(p.em(50, 30), fundo + [0xFF]), "\(cor), o fundo: \(p.em(50, 30))")
            #expect(perto(p.em(50, 0), filete + [0xFF]), "\(cor), o filete: \(p.em(50, 0))")
            #expect(perto(p.em(50, 1), fundo + [0xFF]), "\(cor), 1 pt abaixo do filete: \(p.em(50, 1))")
        }
    }

    /// A cor mais comum entre os pixels opacos (o miolo das letras).
    private func corDoTexto(_ conteudo: some View, _ esquema: ColorScheme = .dark) throws -> [Int] {
        let p = try pixels(conteudo, esquema, escala: 3)
        var contagem: [[Int]: Int] = [:]
        for y in 0..<p.h { for x in 0..<p.w { let c = p.em(x, y); if c[3] == 255 { contagem[Array(c[0..<3]), default: 0] += 1 } } }
        return contagem.max { $0.value < $1.value }?.key ?? []
    }

    /// Dentro do sólido, o rótulo, a nota e a etiqueta vêm na tinta dele (#04100C no verde, #2B1B00 no âmbar); fora, o rótulo e
    /// a nota vêm no secundário do vidro.
    @Test func tintaDoBlocoNoRotuloNaNotaENaEtiqueta() throws {
        for (tinta, cor) in [(Token.tintaSobreDestaque, [0x04, 0x10, 0x0C]), (.tintaSobreAmbar, [0x2B, 0x1B, 0x00])] {
            #expect(try corDoTexto(RotuloDoBloco(texto: "Total gasto").environment(\.tintaDoBloco, tinta)) == cor)
            #expect(try corDoTexto(NotaDoBloco(texto: "bruto, sem correção").environment(\.tintaDoBloco, tinta)) == cor)
            #expect(try corDoTexto(EtiquetaDoSolido(texto: "46 lançamentos").environment(\.tintaDoBloco, tinta)) == cor)
        }
        #expect(try corDoTexto(RotuloDoBloco(texto: "Corrigido pelo banco")) == [0xD6, 0xE8, 0xE0], "o SecundarioTransparente")
        #expect(try corDoTexto(NotaDoBloco(texto: "Correção até hoje")) == [0xD6, 0xE8, 0xE0])
    }

    /// A placa, um tom chapado do fundo: 58% no escuro e 66% no claro; a forte, 84% e 92%.
    @Test func placaEPlacaForte() throws {
        for (esquema, placa, forte) in [(ColorScheme.dark, 0x94, 0xD6), (.light, 0xA8, 0xEB)] {
            #expect(try pixels(Color.clear.frame(width: 40, height: 40).placa(), esquema).em(20, 20)[3] == placa)
            #expect(try pixels(Color.clear.frame(width: 40, height: 40).placa(forte: true), esquema).em(20, 20)[3] == forte)
        }
    }

    /// O recuo de cima e de baixo do bloco (16 pt; 22 na letra de acessibilidade) e o raio (26; 32), no vidro e no sólido.
    @Test func recuoERaioCrescemNaLetraDeAcessibilidade() {
        func altura<V: View>(_ bloco: V, _ t: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: bloco.dynamicTypeSize(t)).sizeThatFits(in: CGSize(width: 300, height: CGFloat.infinity)).height
        }
        for (t, recuo) in [(DynamicTypeSize.large, CGFloat(16)), (.accessibility1, 22), (.accessibility5, 22)] {
            let (vidro, solido) = (altura(BlocoDeVidro { Color.clear.frame(height: 10) }, t), altura(BlocoSolido { Color.clear.frame(height: 10) }, t))
            #expect(vidro == 10 + 2 * recuo, "\(t): \(vidro)")
            #expect(solido == 10 + 2 * recuo, "\(t): \(solido)")
        }
        #expect(Grade.raioDoBloco(.large) == 26 && Grade.raioDoBloco(.xxxLarge) == 26 && Grade.raioDoBloco(.accessibility1) == 32)
        #expect(Grade.externa == 16 && Grade.interna == 34 && Grade.entreBlocos == 12)
    }

    /// O canto do sólido segue o raio da grade: a 8 pt das duas bordas, dentro da quina de 26 e fora da de 32.
    @Test func raioDoSolidoCresceNaLetraDeAcessibilidade() throws {
        for (letra, dentro) in [(DynamicTypeSize.large, true), (.accessibility1, false)] {
            let p = try pixels(BlocoSolido { Color.clear }.frame(width: 100, height: 100).dynamicTypeSize(letra), .dark)
            #expect((p.em(8, 8)[3] == 255) == dentro, "\(letra): \(p.em(8, 8))")
        }
    }

    /// O cabeçalho do sólido com a etiqueta, com e sem o Negrito, em todo tamanho de letra e na largura de dentro do sólido
    /// nos três iPhones (o bloco de 343, 370 e 408 pt, menos o recuo de 18 de cada lado), na escala 3 deles: nunca passa da
    /// largura que recebe. Com o Negrito, o rótulo ao lado de um `Spacer` arredondava para cima, e o cabeçalho passava 1/3
    /// pt (372,333 nos 372 do Pro Max), e o bloco com ele.
    @Test func cabecalhoDoSolidoNaoPassaDaLargura() {
        let pares = [("Total gasto", "46 lançamentos"), ("Total gasto", "1 lançamento"), ("Total gasto", "sem gastos"),
                     ("Rende menos que o banco", "banco paga 1%")]
        for negrito in [false, true] {
            for tamanho in DynamicTypeSize.allCases {
                for bloco in [CGFloat(343), 370, 408] {
                    let disponivel = bloco - 2 * Grade.recuo
                    for (rotulo, etiqueta) in pares {
                        let cabecalho = CabecalhoDoBloco(rotulo: rotulo) { EtiquetaDoSolido(texto: etiqueta) }
                            .environment(\.tintaDoBloco, .tintaSobreDestaque).dynamicTypeSize(tamanho)
                            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3)
                        let medida = UIHostingController(rootView: cabecalho)
                            .sizeThatFits(in: CGSize(width: disponivel, height: CGFloat.infinity)).width
                        #expect(medida <= disponivel, "\(rotulo), \(etiqueta), \(tamanho), negrito \(negrito), a \(disponivel) pt: \(medida)")
                    }
                }
            }
        }
    }
}
