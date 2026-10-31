import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* A barra empilhada de tópicos e a hachura da identidade nova (etapa 4, PR 1b): as cores dos pedaços (os 6 maiores nas do
   anel e o "Outros" em cinza), as larguras do núcleo desenhadas com o vão e o piso, na letra padrão e na de acessibilidade,
   o nome de cada pedaço e a hachura a 45°, por pixel. */
@MainActor
struct BarraEmpilhadaTests {
    /// Os pedaços de uma obra com um gasto por tópico ("t0", "t1"…), nos valores dados.
    private func pedacos(_ brutos: [Double]) -> [PedacoDoAnel] {
        let gastos: [ValorJSON] = brutos.enumerated().map { i, valor in
            .objeto(["id": .texto("g\(i)"), "valor": .numero(valor), "topico": .texto("t\(i)"), "descricao": .texto(""),
                     "data": .texto("2026-02-01"), "pagamento": .texto("pix")])
        }
        let estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista(gastos)])])]))
        return pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
    }

    @Test func coresDoAnelEOutrosCinza() {
        let oito = pedacos([800, 700, 600, 500, 400, 300, 200, 100])
        #expect(oito.map(corDoPedaco) == [.grafico1, .grafico2, .grafico3, .grafico4, .grafico5, .grafico6, .graficoOutros])
        let sete = pedacos([700, 600, 500, 400, 300, 200, 100])
        #expect(sete.map(corDoPedaco).last == .graficoOutros && !sete.last!.outros, "o 7º tópico de uma obra com 7, em cinza")
        let nomes = ["t0": Topico(id: "t0", nome: "Terreno", icone: "casa")]
        #expect(nomeDoPedaco(oito[0], topicos: nomes) == "Terreno" && nomeDoPedaco(oito[1], topicos: nomes) == "t1")
        #expect(nomeDoPedaco(oito[6], topicos: nomes) == "Outros · 2 tópicos")
    }

    /// Os pixels RGBA (pré-multiplicados) do desenho, no escuro, em escala 1.
    private func pixels(_ conteudo: some View) throws -> (w: Int, h: Int, em: (Int, Int) -> [Int]) {
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
        let copia = rgba
        return (w, h, { x, y in (0..<4).map { Int(copia[(y * w + x) * 4 + $0]) } })
    }

    /// Na linha do meio, cada pedaço na cor dele e nas larguras do núcleo, com o vão transparente entre eles: o pequeno sobe
    /// ao piso (8 pt; 12 na letra de acessibilidade, com o vão de 4 e 26 pt de altura).
    @Test(arguments: [DynamicTypeSize.large, .accessibility5])
    func pedacosNasLargurasDoNucleoComOVao(_ letra: DynamicTypeSize) throws {
        let tres = pedacos([600, 300, 1])
        let grande = letra.isAccessibilitySize
        let (vao, piso, altura) = grande ? (4.0, 12.0, 26) : (3.0, 8.0, 16)
        let larguras = largurasDaBarra(tres, largura: 300, piso: piso, vao: vao)
        #expect(larguras[2] == piso)
        let p = try pixels(BarraEmpilhada(pedacos: tres).frame(width: 300).dynamicTypeSize(letra))
        #expect(p.w == 300 && p.h == altura)
        let cores = [[0x19, 0x9E, 0x70], [0x39, 0x87, 0xE5], [0xD5, 0x51, 0x81]]
        var x = 0.0
        for (i, largura) in larguras.enumerated() {
            let meio = Int(x + largura / 2)
            #expect(p.em(meio, p.h / 2) == cores[i] + [0xFF], "pedaço \(i) em \(meio): \(p.em(meio, p.h / 2))")
            if i < larguras.count - 1 {
                let fresta = Int(x + largura + vao / 2)
                #expect(p.em(fresta, p.h / 2)[3] == 0, "o vão depois do pedaço \(i), em \(fresta)")
            }
            x += largura + vao
        }
    }

    /// A hachura de 2 pt a cada 6 cobre um terço do retângulo, em listras "/": o pixel de uma linha se repete 1 pt à direita
    /// na linha de cima.
    @Test func hachuraA45GrausNoPassoDoMockup() throws {
        let p = try pixels(Hachura().fill(ambar).frame(width: 120, height: 40))
        var cheios = 0, iguais = 0, comparados = 0
        for y in 1..<p.h {
            for x in 0..<(p.w - 1) {
                let cheio = p.em(x, y)[3] > 127
                if cheio { cheios += 1 }
                comparados += 1
                if cheio == (p.em(x + 1, y - 1)[3] > 127) { iguais += 1 }
            }
        }
        let fracao = Double(cheios) / Double(comparados)
        #expect(abs(fracao - 1.0 / 3) < 0.04, "\(fracao)")
        #expect(Double(iguais) / Double(comparados) > 0.97, "\(iguais) de \(comparados)")
    }

    /// O % da legenda fica numa linha em todo tamanho de letra: a coluna dele é a do "100%" na fonte da letra. Com uma coluna
    /// estreita, o % quebra em várias linhas, que a auditoria não acusa (não corta) e a varredura não vê (não alarga). Um
    /// tópico só, de nome curto: embaixo da barra, a legenda é uma linha.
    @Test func porcentoDaLegendaNumaLinha() {
        for letra in DynamicTypeSize.allCases {
            let altura = UIHostingController(rootView: BarraDeTopicos(pedacos: pedacos([100]), topicos: [:]).dynamicTypeSize(letra))
                .sizeThatFits(in: CGSize(width: 343, height: 10_000)).height
            let fonte = fonteDoTexto(.subheadline, letra)
            let linha = max(fonte.lineHeight, UIFont.monospacedSystemFont(ofSize: fonte.pointSize, weight: .semibold).lineHeight)
            let barra: CGFloat = letra.isAccessibilitySize ? 26 : 16
            #expect(abs(altura - (2 + 8 + barra + 8 + 8 + 4) - linha) < 1, "\(letra): \(altura) com a linha de \(linha)")
        }
    }

    private var ambar: Color { Paleta().cor(.alerta) }

    /// A barra e a legenda não passam da largura do bloco em nenhum tamanho de letra, nas larguras dos iPhones: o % é um
    /// irmão de largura fracionária do nome, e o nome que recebe uma largura fora da grade de pixels arredonda para cima (o
    /// bloco passava 1/3 de pt na letra máxima).
    @Test func barraDeTopicosNaoPassaDaLargura() {
        let estado = Estado.de(DadosDeExemplo.vitrine())
        let pedacos = pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        for letra in DynamicTypeSize.allCases {
            for largura in [CGFloat(343), 370, 408] {
                let bloco = BlocoDeVidro { BarraDeTopicos(pedacos: pedacos, topicos: topicos) }.dynamicTypeSize(letra)
                let medida = UIHostingController(rootView: bloco).sizeThatFits(in: CGSize(width: largura, height: 10_000)).width
                #expect(medida == largura, "\(letra) em \(largura): \(medida)")
            }
        }
    }

    /// A barra vai sobre a placa forte (84% no escuro), para as cores ficarem a 3:1 com a aurora atrás: no recuo de 8 pt à
    /// esquerda da barra, a placa forte, e não a comum (58%).
    @Test func barraDeTopicosSobreAPlacaForte() throws {
        let p = try pixels(BarraDeTopicos(pedacos: pedacos([300, 200, 100]), topicos: [:]).frame(width: 300))
        #expect(p.em(4, 18)[3] == 0xD6, "\(p.em(4, 18))")
    }
}
