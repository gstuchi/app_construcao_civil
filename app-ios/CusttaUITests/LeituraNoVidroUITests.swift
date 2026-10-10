import XCTest
import UIKit

/* Laudo de leitura sobre o vidro de verdade (spec, seção 8; conselho de 08/10). A auditoria de contraste do
   Xcode não lê fundo de vidro, então ela audita as cores com superfícies sólidas (AuditoriaUITests) e este
   laudo mede o que aparece na tela: cada cena em dois prints, um normal e um com o texto apagado, com o
   fundo parado no pior caso (aurora no pior ponto da deriva inteira, globo no ângulo de partida, logo
   pronto). Portão: 4,5:1 no pior ponto de cada palavra, em qualquer tamanho de letra. Cada cena deixa no
   resultado o print anotado (verde passa, vermelho não) e a tabela, para o Lupa e o Giovani verem sem
   abrir o simulador. As 15 cenas passam com o escurecimento sob o vidro e o globo mais fundo no escuro
   (decisão do Giovani em 09/10). Na CI (`CUSTTA_LAUDO=relatorio`) o laudo só relata: o simulador do
   iOS 26 da CI pode desenhar o vidro diferente do Mac. */
final class LeituraNoVidroUITests: XCTestCase {
    /// Fundo parado no pior momento: Reduzir movimento (globo em 1,2 e logo pronto) e a aurora no pior ponto
    /// da deriva inteira, que também cobre o quadro em que ela para com Reduzir movimento.
    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES"]
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let quatroCombos = [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")]
    private static let portao = 4.5
    /// A barra de status fica de fora: a hora muda entre os dois prints.
    private static let barraDeStatus: CGFloat = 70
    /// Na CI, só o relatório (ver o comentário do topo).
    private static let soRelatorio = ProcessInfo.processInfo.environment["CUSTTA_LAUDO"] == "relatorio"

    private struct Cena {
        let nome: String
        let conta: String
        let argumentos: [String]
        /// Elemento que diz que a tela abriu.
        let espera: String
        /// "tudo" mede o conteúdo (da cápsula de abas para baixo fica de fora); "navegacao" mede só os rótulos
        /// da cápsula, com o conteúdo que passa por baixo dela intacto nos dois prints.
        let escopo: String
    }

    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat) {
        let app = abrirApp(conta: cena.conta, argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
        XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
        Thread.sleep(forTimeInterval: 2)                           // o vidro e a rolagem assentam
        let foto = XCUIScreen.main.screenshot()
        let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
        let largura = app.frame.width
        app.terminate()
        return (foto, abas, largura)
    }

    /// Mede as cenas e cobra o portão de cada uma.
    @MainActor private func cobrar(_ cenas: [Cena]) {
        for cena in cenas {
            let falhas: [String]
            do { falhas = try conferir(cena) } catch {
                XCTFail("\(cena.nome): \(error)")
                continue
            }
            guard !Self.soRelatorio else { continue }
            XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 sobre o vidro:\n" + falhas.joined(separator: "\n"))
        }
    }

    /// Mede uma cena, anexa o print anotado e a tabela e devolve as palavras abaixo do portão.
    @MainActor private func conferir(_ cena: Cena) throws -> [String] {
        let (normal, abas, largura) = fotografar(cena, textoApagado: false)
        let (semTexto, _, _) = fotografar(cena, textoApagado: true)
        let imagem = normal.image.cgImage!
        let escala = CGFloat(imagem.width) / largura
        let capsula = abas.reduce(CGRect.null) { $0.union($1) }
        let regiao = capsula.isNull ? [] : [capsula.insetBy(dx: -10, dy: -10)]
        // O que passa por baixo da cápsula e da barra de início é desfocado e coberto pelo véu da borda de
        // propósito: no "tudo", da cápsula até o pé da tela fica de fora.
        let abaixo = capsula.isNull ? [] : [CGRect(x: 0, y: capsula.minY - 10, width: largura, height: CGFloat(imagem.height) / escala)]
        let palavras = try LaudoDeContraste.medir(normal: Retrato(imagem), semTexto: Retrato(semTexto.image.cgImage!),
                                                  escala: escala, topo: Self.barraDeStatus,
                                                  somenteEm: cena.escopo == "navegacao" ? regiao : nil,
                                                  ignorar: cena.escopo == "tudo" ? abaixo : [])
        XCTAssertFalse(palavras.isEmpty, "\(cena.nome): nenhum texto medido")
        anexar(cena.nome, normal.image, palavras, escala)
        Swift.print(String(format: "leitura | %@ | %d palavras, %d abaixo | pior nota %.2f", cena.nome, palavras.count,
                           palavras.filter { $0.nota < Self.portao }.count, palavras.map(\.nota).min() ?? 0))
        return palavras.filter { $0.nota < Self.portao }.map { p in
            "\(cena.nome): texto \(p.corHex) em \(Int(p.caixa.minX)),\(Int(p.caixa.minY)) (\(Int(p.caixa.width))×\(Int(p.caixa.height)) pt) "
                + "fica em " + String(format: "%.2f:1 (pior pixel %.2f:1)", p.nota, p.minimo)
        }
    }

    @MainActor private func anexar(_ nome: String, _ imagem: UIImage, _ palavras: [LaudoDeContraste.Palavra], _ escala: CGFloat) {
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let tamanho = CGSize(width: imagem.size.width * imagem.scale, height: imagem.size.height * imagem.scale)
        let anotada = UIGraphicsImageRenderer(size: tamanho, format: formato).image { ctx in
            imagem.draw(in: CGRect(origin: .zero, size: tamanho))
            for p in palavras {
                let caixa = CGRect(x: p.caixa.minX * escala, y: p.caixa.minY * escala,
                                   width: p.caixa.width * escala, height: p.caixa.height * escala).insetBy(dx: -4, dy: -4)
                let cor: UIColor = p.nota < Self.portao ? .systemRed : .systemGreen
                cor.setStroke()
                ctx.cgContext.setLineWidth(4)
                ctx.cgContext.stroke(caixa)
                let rotulo = String(format: "%.1f", p.nota) as NSString
                rotulo.draw(at: CGPoint(x: caixa.maxX + 6, y: caixa.minY),
                            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 30), .foregroundColor: cor,
                                             .backgroundColor: UIColor.black.withAlphaComponent(0.6)])
            }
        }
        let foto = XCTAttachment(image: anotada)
        foto.name = "leitura — \(nome)"
        foto.lifetime = .keepAlways
        add(foto)
        let linhas = palavras.map { p in
            String(format: "%@  %4.0f,%4.0f  %4.0f×%3.0f pt  nota %5.2f  pior %5.2f", p.corHex,
                   p.caixa.minX, p.caixa.minY, p.caixa.width, p.caixa.height, p.nota, p.minimo)
        }
        let tabela = XCTAttachment(string: "Leitura — \(nome) (portão \(Self.portao):1)\n" + linhas.joined(separator: "\n"))
        tabela.name = "leitura — \(nome) (tabela)"
        tabela.lifetime = .keepAlways
        add(tabela)
    }

    /// Entrar (Fosco), Obras (Transparente, com o aviso de e-mail) e os rótulos da cápsula de abas sobre a
    /// lista rolada, nos quatro combos.
    @MainActor func testLeituraNosQuatroCombos() {
        var cenas: [Cena] = []
        for (tema, pele) in quatroCombos {
            let combo = ["-custta.tema", tema, "-custta.pele", pele] + piorMomento
            cenas += [
                Cena(nome: "entrar, \(tema), \(pele)", conta: "nenhuma", argumentos: combo, espera: "email", escopo: "tudo"),
                Cena(nome: "obras, \(tema), \(pele)", conta: "senha-nao-confirmada", argumentos: combo,
                     espera: "avisoEmail", escopo: "tudo"),
                Cena(nome: "abas sobre a lista, \(tema), \(pele)", conta: "senha-nao-confirmada",
                     argumentos: combo + ["-custta.rolagem", "260"], espera: "avisoEmail", escopo: "navegacao"),
            ]
        }
        cobrar(cenas)
    }

    /// Na maior letra o texto cai em outra parte da aurora; com "Aumentar contraste", o vidro é o Fosco com
    /// contorno. Os dois no escuro, onde a aurora é mais clara que o texto.
    @MainActor func testLeituraNaMaiorLetraEComAumentarContraste() {
        let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
        let contraste = escuro + ["-custta.aumentarContraste", "YES"]
        cobrar([
            Cena(nome: "obras na maior letra", conta: "senha-nao-confirmada", argumentos: escuro + maiorLetra,
                 espera: "avisoEmail", escopo: "tudo"),
            Cena(nome: "entrar com Aumentar contraste", conta: "nenhuma", argumentos: contraste, espera: "email", escopo: "tudo"),
            Cena(nome: "obras com Aumentar contraste", conta: "senha-nao-confirmada", argumentos: contraste,
                 espera: "avisoEmail", escopo: "tudo"),
        ])
    }
}

/* O medidor com imagens sintéticas: sem abrir o app. */
final class LaudoDeContrasteTests: XCTestCase {
    private func retrato(_ largura: Int, _ altura: Int, fundo: (UInt8, UInt8, UInt8),
                         pintar: [(CGRect, (UInt8, UInt8, UInt8))] = []) -> Retrato {
        var rgba = [UInt8](repeating: 255, count: largura * altura * 4)
        for i in 0..<(largura * altura) { rgba[i * 4] = fundo.0; rgba[i * 4 + 1] = fundo.1; rgba[i * 4 + 2] = fundo.2 }
        for (r, c) in pintar {
            for y in Int(r.minY)..<Int(r.maxY) { for x in Int(r.minX)..<Int(r.maxX) {
                let k = (y * largura + x) * 4
                rgba[k] = c.0; rgba[k + 1] = c.1; rgba[k + 2] = c.2
            } }
        }
        return Retrato(largura: largura, altura: altura, rgba: rgba)
    }

    private let fundo: (UInt8, UInt8, UInt8) = (0x12, 0x2A, 0x22)
    private let branco: (UInt8, UInt8, UInt8) = (0xFF, 0xFF, 0xFF)
    private let letras = [CGRect(x: 40, y: 40, width: 6, height: 24), CGRect(x: 52, y: 40, width: 6, height: 24),
                          CGRect(x: 64, y: 40, width: 6, height: 24)]

    func testTextoConhecidoSobreFundoLiso() throws {
        let normal = retrato(200, 120, fundo: fundo, pintar: letras.map { ($0, branco) })
        let semTexto = retrato(200, 120, fundo: fundo)
        let palavras = try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3)
        XCTAssertEqual(palavras.count, 1, "três letras juntas viram uma palavra")
        let esperado = LaudoDeContraste.contraste(LaudoDeContraste.luminancia(0xFF, 0xFF, 0xFF),
                                                  LaudoDeContraste.luminancia(fundo.0, fundo.1, fundo.2))
        XCTAssertEqual(palavras[0].nota, esperado, accuracy: 0.05)
        XCTAssertEqual(palavras[0].corHex, "#FFFFFF")
    }

    func testPontoClaroSobALetraDerrubaANota() throws {
        let claro: (UInt8, UInt8, UInt8) = (0xC8, 0xF0, 0xDC)
        let ponto = CGRect(x: 52, y: 48, width: 6, height: 8)
        let normal = retrato(200, 120, fundo: fundo, pintar: letras.map { ($0, branco) })
        let semTexto = retrato(200, 120, fundo: fundo, pintar: [(ponto, claro)])
        let palavra = try XCTUnwrap(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3).first)
        XCTAssertLessThan(palavra.nota, 1.5, "um ponto claro do globo atrás da letra reprova")
        XCTAssertLessThan(palavra.minimo, 1.5)
    }

    func testFundoQueMudaLongeDasLetrasDaErro() {
        let outro: (UInt8, UInt8, UInt8) = (0x26, 0x3E, 0x36)            // o vidro desenhado um pouco diferente
        let normal = retrato(200, 120, fundo: fundo, pintar: letras.map { ($0, branco) })
        let semTexto = retrato(200, 120, fundo: fundo, pintar: [(CGRect(x: 120, y: 60, width: 60, height: 40), outro)])
        XCTAssertThrowsError(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3)) { erro in
            XCTAssertTrue(erro is LaudoDeContraste.CenaNaoDeterministica)
        }
    }
}
