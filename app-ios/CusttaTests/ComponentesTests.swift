import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* Medidas das peças das telas que o mockup aprovado fixa e o print não tira sozinho: a caixa do campo não é
   elemento de acessibilidade, então a altura sai do layout, num UIHostingController. O ImageRenderer não serve:
   ele não instala o @FocusState do campo, e o SwiftUI acusa "Accessing FocusState's value outside of the body
   of a View" (aviso de execução que dispara o simctl diagnose da rodada). A escala 1 mede em pontos inteiros,
   a grade do mockup: na tela de 3x a linha do rótulo arredonda para 17,67 pt. */
@MainActor
struct ComponentesTests {
    private struct Campo: View {
        let senha: Bool
        @FocusState private var foco: String?
        @State private var texto = ""

        var body: some View {
            CampoDeEntrada(rotulo: "Senha", exemplo: "Sua senha", texto: $texto, identificador: "campo", senha: senha,
                           foco: $foco, chave: "campo")
                .frame(width: 320)
        }
    }

    private func altura(senha: Bool) -> CGFloat {
        UIHostingController(rootView: Campo(senha: senha).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: 320, height: CGFloat.infinity)).height
    }

    /// Rótulo de 18 pt e 6 de espaço em cima da caixa: 48 pt no campo de texto e 52 no de senha, em que o olho
    /// tem alvo de 44 pt (no mockup, 11 pt de margem e o olho de 44 pt com 8 pt para dentro de cada lado).
    @Test func campoDeSenhaCom52PontosComoOMockup() {
        #expect(altura(senha: false) == CGFloat(18 + 6 + 48))
        #expect(altura(senha: true) == CGFloat(18 + 6 + 52))
    }

    private func alturaDaPilula(largura: CGFloat) -> CGFloat {
        UIHostingController(rootView: Limpando().dynamicTypeSize(.accessibility5).environment(\.displayScale, 3))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// A pílula "Limpando…" na maior letra num iPhone de 375 pt (SE, 12 e 13 mini) fica numa linha só, da altura que
    /// tem numa largura folgada, em vez de as reticências caírem sozinhas na linha de baixo (escala 3, a do 13 mini).
    @Test func pilulaDoLimpandoNumaLinhaNaMaiorLetraEm375Pontos() {
        #expect(alturaDaPilula(largura: 375) == alturaDaPilula(largura: 1000))
    }
}

/* A etiqueta "novo" entra no título da linha como imagem, colada à última palavra (mockup). O ImageRenderer não herda
   nada da tela: a imagem tem de sair na escala da tela, na Marca do esquema de cor e da pele, e crescer com a letra. */
@MainActor
struct EtiquetaNovoTests {
    private func imagem(_ esquema: ColorScheme, pele: Pele = .esmeralda, tamanho: DynamicTypeSize = .large) throws -> UIImage {
        try #require(EtiquetaNovo.imagem(paleta: Paleta(pele: pele), esquema: esquema, tamanho: tamanho, escala: 3))
    }

    /// RGBA do fundo da cápsula, 4 pt depois do começo dela (a imagem tem 4 pt de folga antes), na meia altura.
    private func fundo(_ imagem: UIImage) -> [UInt8] {
        guard let cg = imagem.cgImage else { return [] }
        let x = Int(8 * imagem.scale), y = cg.height / 2
        var rgba = [UInt8](repeating: 0, count: 4)
        let contexto = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        contexto?.draw(cg, in: CGRect(x: -x, y: y - cg.height + 1, width: cg.width, height: cg.height))
        return rgba
    }

    @Test func naEscalaDaTelaENaMarcaDoEsquemaEDaPele() throws {
        #expect(try imagem(.dark).scale == 3)
        #expect(fundo(try imagem(.dark)) == [0x14, 0xB3, 0x9A, 0xFF], "Esmeralda/Marca do escuro")
        #expect(fundo(try imagem(.light)) == [0x0B, 0x7A, 0x68, 0xFF], "Esmeralda/Marca do claro")
        #expect(fundo(try imagem(.dark, pele: .azul)) == [0x5B, 0x8C, 0xFF, 0xFF], "Azul/Marca do escuro")
    }

    @Test func cresceComALetra() throws {
        #expect(try imagem(.dark, tamanho: .accessibility5).size.width > imagem(.dark).size.width * 1.5)
    }
}

/* As ações da fase na maior letra (quadro "Ações da fase" do mockup da parte 3, AX5): o ícone para nos 34 pt do mockup,
   o recuo interno cai de 20 para 10 nos tamanhos de acessibilidade (o mockup em 375 deixa o texto a cerca de 10 pt da
   borda) e o rótulo fica centrado em cada linha. Sem o teto, o ícone ia a cerca de 62 pt; com o recuo de 20, "construção",
   que pede 268 pt, partia em três linhas com hífen em 375. A pílula tem 362 pt no 18 Pro (402 menos 20 de cada lado) e
   335 num iPhone de 375 pt. */
@MainActor
struct AcoesDaFaseTests {
    private func altura(_ fase: Fase, largura: CGFloat) -> CGFloat {
        UIHostingController(rootView: AcoesDaFaseView(fase: fase, agir: { _ in }).dynamicTypeSize(.accessibility5)
            .environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// Na pronta, "Voltar pra construção" fica em duas linhas, como "Registrar venda": as duas pílulas somam o dobro da de
    /// "Desfazer venda", que tem duas linhas, mais os 10 entre elas. Em 375 sobram 273 pt para "construção" (335 menos 10
    /// de cada lado, o ícone e 8 até o texto).
    @Test(arguments: [CGFloat(362), 335]) func voltarPraConstrucaoEmDuasLinhas(largura: CGFloat) {
        #expect(altura(.pronta, largura: largura) == 2 * altura(.vendida, largura: largura) + 10)
    }

    /// No 18 Pro, "Marcar como pronta" também vira um bloco de duas linhas (com o recuo de 20 eram três). Em 375 fica em
    /// três, uma palavra por linha.
    @Test func marcarComoProntaEmDuasLinhasNo18Pro() {
        #expect(altura(.construcao, largura: 362) == altura(.vendida, largura: 362))
    }

    /// O desenho das ações da fase em escala 1 e o teste de texto: pixel opaco longe da cor do fundo da pílula, lida a
    /// 5 pt da borda esquerda, na meia altura.
    private func desenho(_ conteudo: some View) throws -> (largura: Int, altura: Int, texto: (Int, Int) -> Bool) {
        let render = ImageRenderer(content: conteudo)
        render.scale = 1
        let imagem = try #require(render.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let pixels = rgba
        func pixel(_ x: Int, _ y: Int) -> [Int] { (0..<4).map { Int(pixels[(y * w + x) * 4 + $0]) } }
        let fundo = pixel(5, h / 2)
        return (w, h, { x, y in
            let p = pixel(x, y)
            return p[3] > 250 && zip(p.prefix(3), fundo.prefix(3)).map { abs($0 - $1) }.reduce(0, +) > 150
        })
    }

    /// Começo e fim (em pt, na escala 1) de cada linha do rótulo de "Marcar como pronta", sem o ícone de 34 pt à
    /// esquerda da primeira linha.
    private func linhas(largura: CGFloat) throws -> [ClosedRange<Int>] {
        let (w, h, texto) = try desenho(AcoesDaFaseView(fase: .construcao, agir: { _ in }).frame(width: largura)
            .dynamicTypeSize(.accessibility5))
        let depoisDoIcone = ((0..<w).first { x in (0..<h).contains { texto(x, $0) } } ?? 0) + 34 + 2
        var linhas: [ClosedRange<Int>] = []
        var atual: ClosedRange<Int>?
        for y in 0..<h {
            let xs = (depoisDoIcone..<w).filter { texto($0, y) }
            if let a = xs.first, let b = xs.last {
                atual = min(atual?.lowerBound ?? a, a)...max(atual?.upperBound ?? b, b)
            } else if let linha = atual {
                linhas.append(linha)
                atual = nil
            }
        }
        return linhas
    }

    /// Cada linha de "Marcar como pronta" fica centrada, como no mockup (text-align:center), em vez de todas começarem
    /// rente ao ícone.
    @Test(arguments: [CGFloat(362), 335]) func rotuloCentradoEmCadaLinha(largura: CGFloat) throws {
        let linhas = try linhas(largura: largura)
        let centros = linhas.map { Double($0.lowerBound + $0.upperBound) / 2 }
        #expect(linhas.count >= 2, "\(linhas)")
        #expect((centros.max() ?? 0) - (centros.min() ?? 0) <= 3, "\(linhas)")
    }

    /// Na largura ideal (uma linha), o rótulo termina a 20 pt da borda da pílula na letra padrão, como sempre foi, e a 10
    /// nos tamanhos de acessibilidade. A folga vai do último pixel da letra à borda e soma o respiro da própria letra
    /// (2 a 3 pt na AX5).
    @Test(arguments: zip([DynamicTypeSize.large, .xxxLarge, .accessibility1, .accessibility5], [20, 20, 10, 10]))
    func recuoInternoSoMenorNaLetraDeAcessibilidade(tamanho: DynamicTypeSize, recuo: Int) throws {
        let (w, h, texto) = try desenho(AcoesDaFaseView(fase: .construcao, agir: { _ in }).dynamicTypeSize(tamanho))
        let fim = try #require((0..<w).last { x in (0..<h).contains { texto(x, $0) } })
        #expect((recuo...recuo + 5).contains(w - 1 - fim), "rótulo termina em \(fim) de \(w)")
    }
}
