import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As linhas e as frases da tela Orçamento (etapa 3, PR 1), montadas das regras do núcleo: o nome do tópico (o id, com o
   ícone etiqueta, quando o app não conhece o tópico, como no site), o gasto e o previsto do site, a frase do nível (a do
   "passou" em âmbar), o valor da linha, que não quebra, e as frases do cartão partidas em volta do dinheiro, iguais às do
   núcleo. */
struct TelaOrcamentoTests {
    private func obra(_ orcamento: ValorJSON, gastos: [(String, Double)]) -> Obra {
        Obra(arvore: ["id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "orcamento": orcamento,
                      "gastos": .lista(gastos.enumerated().map { i, g in
                          .objeto(["id": .texto("g\(i)"), "valor": .numero(g.1), "topico": .texto(g.0), "descricao": .texto(""),
                                   "data": .texto("2026-02-01"), "pagamento": .texto("pix")])
                      })])
    }

    private let porTopico: ValorJSON = .objeto(["modo": .texto("topicos"),
                                                "topicos": .objeto(["estrutura": .numero(85_000), "revest": .numero(80_000),
                                                                    "c_apagado": .numero(7_000), "pintura": .numero(10_000)])])

    @Test func porTopicoComAsFrasesDoSiteEOTopicoDesconhecidoPeloId() throws {
        let o = obra(porTopico, gastos: [("estrutura", 91_200), ("revest", 76_700), ("pintura", 1_000), ("projeto", 22_880.5)])
        let r = try #require(orcamentoObra(o))
        let linhas = linhasPorTopico(r, topicos: mapaDeTopicos([]))
        #expect(linhas.map(\.id) == ["estrutura", "revest", "pintura", "c_apagado"], "a ordem do site: quem gastou mais do previsto primeiro")
        #expect(linhas[0] == LinhaDeTopicoDoOrcamento(id: "estrutura", nome: "Estrutura", icone: "guindaste", gasto: "R$ 91 mil",
                                                       previsto: "85 mil", item: r.topicos[0], frase: "Passou R$ 6,2 mil do previsto",
                                                       fraseEmAlerta: true))
        #expect(linhas[1].frase == "Faltam R$ 3,3 mil — 96%" && !linhas[1].fraseEmAlerta)
        #expect(linhas[2].frase == nil, "dentro do previsto, sem frase")
        // O tópico que o app não conhece aparece pelo id, com o ícone etiqueta; sem gasto, "R$ 0,00" (abaixo de mil, a moeda
        // inteira, com o espaço fixo do site).
        #expect(linhas[3].nome == "c_apagado")
        #expect(linhas[3].icone == "etiqueta")
        #expect(linhas[3].gasto == "R$\u{a0}0,00")
        let fora = linhasForaDoOrcamento(r, topicos: mapaDeTopicos([]))
        #expect(fora == [LinhaDeTopicoDoOrcamento(id: "projeto", nome: "Documentação", icone: "documento", gasto: "R$ 23 mil",
                                                   previsto: nil, item: nil, frase: nil)])
    }

    @Test func gastoPorTopicoComAParteDaObra() {
        let o = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                     gastos: [("terreno", 319_847.85), ("revest", 76_700), ("c_meu", 2_000)])
        let proprio = TopicoProprio(campos: ["id": .texto("c_meu"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o, hoje: "2026-10-20", taxaMensal: 1), topicos: mapaDeTopicos([proprio]))
        #expect(linhas.map(\.nome) == ["Terreno", "Cerâmica", "Gesso"])
        #expect(linhas.map(\.gasto) == ["R$ 320 mil", "R$ 77 mil", "R$ 2 mil"])
        #expect(linhas.map(\.frase) == ["80% da obra", "19% da obra", "1% da obra"])
        #expect(linhas.allSatisfy { $0.previsto == nil && $0.item == nil && !$0.fraseEmAlerta })
    }

    /// As frases do cartão, partidas em volta do dinheiro (na letra grande ele vai para a própria linha), são as do núcleo.
    @Test func frasesDoCartaoIguaisAsDoNucleo() throws {
        let casos = [obra(porTopico, gastos: [("estrutura", 91_200), ("projeto", 22_880.5)]),
                     obra(.objeto(["modo": .texto("topicos"), "topicos": .objeto(["estrutura": .numero(85_000)])]), gastos: []),
                     obra(.objeto(["modo": .texto("total"), "total": .numero(1_200_000)]), gastos: [("terreno", 10)])]
        for o in casos {
            let r = try #require(orcamentoObra(o))
            let p = partesDoPrevisto(r)
            #expect([p.antes, p.valor, p.depois].filter { !$0.isEmpty }.joined(separator: " ") == previstoDoCartao(r))
            let f = partesDoFora(r)
            #expect(f.map { "\($0.antes) \($0.valor) \($0.depois)" } == fraseDoForaNoCartao(r))
        }
    }

    /// O valor da linha não quebra: o nome quebra antes (o `white-space: nowrap` do mockup). Na letra grande, na própria
    /// linha, quebra se precisar.
    @MainActor @Test func valorDaLinhaNaoQuebra() {
        func altura(_ largura: CGFloat, _ letra: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: ValorDoTopicoNoOrcamento(gasto: "R$ 320 mil", previsto: "320 mil").dynamicTypeSize(letra)
                .environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
        }
        #expect(altura(60, .large) == altura(1000, .large), "numa linha só, mesmo sem largura")
        #expect(altura(60, .accessibility5) > altura(1000, .accessibility5), "na letra grande, quebra")
    }

    /// A frase do "passou" no âmbar sobre o vidro (#6F4705 no claro, #FFD98A no escuro); as outras, fora do âmbar.
    @MainActor @Test func fraseDoPassouNoAmbarSobreOVidro() throws {
        func cor(_ alerta: Bool, _ esquema: ColorScheme) throws -> [UInt8] {
            let r = ImageRenderer(content: FraseDoTopicoNoOrcamento(texto: "Passou R$ 6,2 mil do previsto", alerta: alerta)
                .environment(\.paleta, Paleta(pele: .esmeralda)).environment(\.colorScheme, esquema))
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
        #expect(try cor(true, .light) == [0x6F, 0x47, 0x05])
        #expect(try cor(true, .dark) == [0xFF, 0xD9, 0x8A])
        #expect(try cor(false, .light) != [0x6F, 0x47, 0x05] && cor(false, .dark) != [0xFF, 0xD9, 0x8A], "a frase que não é do passou")
    }
}
