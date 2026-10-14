import XCTest
import UIKit

/* Laudo de leitura sobre o vidro de verdade (spec, seção 8; conselho de 08/10). A auditoria de contraste do
   Xcode não lê fundo de vidro, então ela audita as cores com superfícies sólidas (AuditoriaUITests) e este
   laudo mede o que aparece na tela: cada cena em dois prints, um normal e um com o texto apagado, com o
   fundo parado no pior caso (aurora no pior ponto da deriva inteira, globo no ângulo de partida, logo
   pronto). Portão: 4,5:1 no pior ponto de cada palavra, em qualquer tamanho de letra. Cada cena deixa no
   resultado o print anotado (verde passa, vermelho não) e a tabela, para o Lupa e o Giovani verem sem
   abrir o simulador. As 15 cenas passam com o escurecimento sob o vidro e o globo mais fundo no escuro
   (decisão do Giovani em 09/10). Na CI (iOS 26) o laudo também é portão: o simulador de lá desenha o
   vidro diferente do Mac, mas igual de uma rodada para outra (as 47 cenas deram as mesmas notas em quatro
   rodadas do PR 3, todas acima de 4,5). */
final class LeituraNoVidroUITests: XCTestCase {
    /// Fundo parado no pior momento: Reduzir movimento (globo em 1,2 e logo pronto) e a aurora no pior ponto
    /// da deriva inteira, que também cobre o quadro em que ela para com Reduzir movimento.
    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"]
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let quatroCombos = [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")]
    private static let portao = 4.5
    /// A barra de status fica de fora: a hora muda entre os dois prints.
    private static let barraDeStatus: CGFloat = 70
    /// Rolagens da lista sob a cápsula de abas: no Mac, de 10 em 10 pt até 60 e o fim (260); na CI
    /// (`CUSTTA_VARREDURA=curta`), 0, 20, 40 e 260, para o job caber em 45 min.
    private static let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta"
        ? [0, 20, 40, 260] : Array(stride(from: 0, through: 60, by: 10)) + [260]

    private struct Cena {
        let nome: String
        let conta: String
        let argumentos: [String]
        /// Elemento que diz que a tela abriu.
        let espera: String
        /// "tudo" mede o conteúdo (da cápsula de abas para baixo fica de fora); "navegacao" mede só os rótulos
        /// da cápsula, com o conteúdo que passa por baixo dela intacto nos dois prints.
        let escopo: String
        /// Aba aberta pela cápsula antes do print (Ajustes não tem gancho de abertura).
        var aba: String? = nil
    }

    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat) {
        let app = abrirApp(conta: cena.conta, argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
        XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
        if let aba = cena.aba {
            app.abrirAba(aba)
            XCTAssertTrue(app.elemento("sair").waitForExistence(timeout: 10), "\(cena.nome): Ajustes não abriu")
        }
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
        // propósito: no "tudo", da borda de baixo (os 140 pt da BordaDeRolagem, como na AuditoriaUITests) ou da
        // cápsula, o que vier antes, até o pé da tela fica de fora.
        let altura = CGFloat(imagem.height) / escala
        let abaixo = capsula.isNull ? [] : [CGRect(x: 0, y: min(capsula.minY - 10, altura - 140), width: largura, height: altura)]
        // O indicador de início, como a barra de status, é do sistema e muda entre os prints (aparece ou não, e
        // muda de cor com o que tem por baixo): os 34 pt de baixo ficam de fora em toda cena.
        let indicador = [CGRect(x: 0, y: altura - 34, width: largura, height: 34)]
        let palavras = try LaudoDeContraste.medir(normal: Retrato(imagem), semTexto: Retrato(semTexto.image.cgImage!),
                                                  escala: escala, topo: Self.barraDeStatus,
                                                  somenteEm: cena.escopo == "navegacao" ? regiao : nil,
                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador)
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
            ]
            // Os rótulos da cápsula com o conteúdo passando atrás deles: a lista em várias rolagens, porque o pior
            // ponto muda com os dados e o combo (no fim da lista, 260 pt, já não passa nada atrás dos rótulos).
            cenas += Self.rolagens.map { rolagem in
                Cena(nome: "abas sobre a lista em \(rolagem) pt, \(tema), \(pele)", conta: "senha-nao-confirmada",
                     argumentos: combo + ["-custta.rolagem", "\(rolagem)"], espera: "avisoEmail", escopo: "navegacao")
            }
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

    /// Ajustes: o título grande (do sistema, com o halo da barra) e a versão, texto solto sobre a aurora, nos
    /// dois escuros, com "Aumentar contraste" e na maior letra. No Pro Max, a versão fica em 4,42:1 no escuro
    /// esmeralda (revisão final do PR 2).
    @MainActor func testLeituraEmAjustes() {
        let esmeralda = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
        let azul = ["-custta.tema", "escuro", "-custta.pele", "azul"] + piorMomento
        let cenas: [(String, [String])] = [("escuro, esmeralda", esmeralda), ("escuro, azul", azul),
                                           ("com Aumentar contraste", esmeralda + ["-custta.aumentarContraste", "YES"]),
                                           ("na maior letra", esmeralda + maiorLetra)]
        cobrar(cenas.map { nome, argumentos in
            Cena(nome: "ajustes, \(nome)", conta: "senha", argumentos: argumentos, espera: "aba-ajustes", escopo: "tudo",
                 aba: "ajustes")
        })
    }
}

extension LeituraNoVidroUITests {
    /// O "Cancelar" do "Sair da conta?" nos quatro combos, no tint do alerta (Texto). O texto do alerta
    /// é do sistema e o app não o apaga: o rótulo é medido contra a própria cápsula (`medirRotulo`). Exceção:
    /// o "Sair" não é medido. É destrutivo, e o vermelho do sistema não segue o tint (2,2 a 3,0:1 no iOS 27); fica
    /// o padrão da Apple (decisão de 11/10).
    @MainActor func testLeituraDoAlertaDeSair() {
        var falhas: [String] = []
        for (tema, pele) in quatroCombos {
            let nome = "alerta Sair da conta?, \(tema), \(pele)"
            let app = abrirApp(conta: "senha", argumentos: ["-custta.tema", tema, "-custta.pele", pele] + piorMomento)
            app.abrirAba("ajustes")
            XCTAssertTrue(app.elemento("sair").waitForExistence(timeout: 10), "\(nome): Ajustes não abriu")
            app.buttons["sair"].tap()
            let cancelar = app.alerts["Sair da conta?"].buttons["Cancelar"]
            XCTAssertTrue(cancelar.waitForExistence(timeout: 5), "\(nome): o alerta não abriu")
            Thread.sleep(forTimeInterval: 2)                           // o vidro do alerta assenta
            let foto = XCUIScreen.main.screenshot()
            let imagem = foto.image.cgImage!
            let escala = CGFloat(imagem.width) / app.frame.width
            let quadro = cancelar.frame
            app.terminate()
            guard let palavra = LaudoDeContraste.medirRotulo(Retrato(imagem), quadro: quadro, escala: escala) else {
                XCTFail("\(nome): o rótulo do Cancelar não foi achado")
                continue
            }
            anexar(nome, foto.image, [palavra], escala)
            Swift.print(String(format: "leitura | %@ | Cancelar %@ | nota %.2f (pior pixel %.2f)", nome, palavra.corHex,
                               palavra.nota, palavra.minimo))
            if palavra.nota < Self.portao { falhas.append(String(format: "%@: Cancelar em %.2f:1", nome, palavra.nota)) }
        }
        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 no alerta:\n" + falhas.joined(separator: "\n"))
    }

    /// O "Finalizar saída" nos quatro combos, nos três estados do mockup: o título e o botão do alerta (no tint Texto,
    /// como o do "Sair da conta?"), aberto e depois de falhar de novo, e o "Limpando…" da pílula, medidos contra o fundo
    /// em volta (`medirRotulo`). Os prints dos três estados ficam no resultado para conferir com o mockup. Exceção
    /// nomeada (decisão do Giovani, 12/10): a mensagem do alerta não é medida. Ela sai na cor secundária do sistema
    /// (2,7 a 3,7:1 no iOS 27), que o próprio iOS escurece com Aumentar contraste; fica o padrão da Apple, como no
    /// "Sair" destrutivo.
    @MainActor func testLeituraDoFinalizarSaida() { cobrarFinalizarSaida(maiorLetra: false) }

    /// Na maior letra o alerta rola, e o botão fica no fim, sobre o que estiver atrás do vidro do alerta (na entrada,
    /// o botão branco da Apple, que o escurecido sob o alerta apaga; conferência do Verniz, 11/10).
    @MainActor func testLeituraDoFinalizarSaidaNaMaiorLetra() { cobrarFinalizarSaida(maiorLetra: true) }

    @MainActor private func cobrarFinalizarSaida(maiorLetra letraGrande: Bool) {
        var falhas: [String] = []
        /// Mede um rótulo no print da tela, anexa o print anotado (e, com `limpo`, o sem anotação) e cobra o portão.
        func medir(_ nome: String, _ rotulo: String, _ quadro: CGRect, _ app: XCUIApplication, limpo: Bool) {
            let foto = XCUIScreen.main.screenshot()
            let imagem = foto.image.cgImage!
            let escala = CGFloat(imagem.width) / app.frame.width
            guard let palavra = LaudoDeContraste.medirRotulo(Retrato(imagem), quadro: quadro, escala: escala) else {
                XCTFail("\(nome): o rótulo \(rotulo) não foi achado")
                return
            }
            anexar(rotulo == FinalizarSaidaUITests.titulo ? "\(nome) (título)" : nome, foto.image, [palavra], escala)
            if limpo {
                let semAnotacao = XCTAttachment(screenshot: foto)      // para comparar com o mockup
                semAnotacao.name = "print — \(nome)\(rotulo == FinalizarSaidaUITests.titulo ? " (título)" : "")"
                semAnotacao.lifetime = .keepAlways
                add(semAnotacao)
            }
            Swift.print(String(format: "leitura | %@ | %@ %@ | nota %.2f (pior pixel %.2f)", nome, rotulo, palavra.corHex,
                               palavra.nota, palavra.minimo))
            if palavra.nota < Self.portao { falhas.append(String(format: "%@: %@ em %.2f:1", nome, rotulo, palavra.nota)) }
        }
        for (tema, pele) in quatroCombos {
            let app = abrirApp(conta: "nenhuma", limpeza: "abertura",
                               argumentos: ["-custta.tema", tema, "-custta.pele", pele] + piorMomento + (letraGrande ? maiorLetra : []))
            let alerta = app.alerts[FinalizarSaidaUITests.titulo], botao = alerta.buttons[FinalizarSaidaUITests.botao]
            for estado in ["aberto", "tentando", "falhou de novo"] {
                let nome = "finalizar saída\(letraGrande ? " na maior letra" : ""), \(estado), \(tema), \(pele)"
                if estado == "tentando" {
                    botao.tap()
                    // O alerta fecha, a ação roda e a pílula vem meio segundo depois: no simulador da CI, o teste só a acha
                    // uns 4 s após o toque (a nova tentativa falsa leva 8 s, para ela continuar à vista).
                    guard app.elemento("limpando").waitForExistence(timeout: 10) else {
                        XCTFail("\(nome): o \"Limpando…\" não apareceu")
                        continue
                    }
                    Thread.sleep(forTimeInterval: 0.8)                 // a pílula assenta
                    medir(nome, "Limpando…", app.elemento("limpando").frame, app, limpo: true)
                    continue
                }
                XCTAssertTrue(botao.waitForExistence(timeout: 15), "\(nome): o alerta não abriu")
                Thread.sleep(forTimeInterval: 2)                       // o vidro do alerta assenta
                // O título antes de rolar: na maior letra ele sai de vista quando o alerta rola até o botão. O medidor
                // entra 6 pt na moldura (a borda da cápsula); no texto solto, a moldura medida é a do próprio texto.
                medir(nome, FinalizarSaidaUITests.titulo, alerta.staticTexts[FinalizarSaidaUITests.titulo].frame.insetBy(dx: -6, dy: -6),
                      app, limpo: letraGrande)
                if letraGrande {
                    alerta.swipeUp()                                   // o alerta rola até o botão, no fim
                    Thread.sleep(forTimeInterval: 2)
                }
                medir(nome, FinalizarSaidaUITests.botao, botao.frame, app, limpo: true)
            }
            app.terminate()
        }
        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 no Finalizar saída:\n" + falhas.joined(separator: "\n"))
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

    func testRotuloSobreACapsulaDoAlerta() throws {
        let capsula: (UInt8, UInt8, UInt8) = (0x38, 0x59, 0x57), link: (UInt8, UInt8, UInt8) = (0x8F, 0xE8, 0xD5)
        let quadro = CGRect(x: 0, y: 0, width: 200 / 3, height: 120 / 3)      // o botão inteiro, em pontos
        let liso = retrato(200, 120, fundo: capsula, pintar: letras.map { ($0, link) })
        let palavra = try XCTUnwrap(LaudoDeContraste.medirRotulo(liso, quadro: quadro, escala: 3))
        XCTAssertEqual(palavra.corHex, "#8FE8D5")
        let esperado = LaudoDeContraste.contraste(LaudoDeContraste.luminancia(link.0, link.1, link.2),
                                                  LaudoDeContraste.luminancia(capsula.0, capsula.1, capsula.2))
        XCTAssertEqual(palavra.nota, esperado, accuracy: 0.05)
        // Um brilho do vidro (mais claro que a cápsula, mas não a ponto de virar letra) encostado nas letras
        // derruba a nota para 3,33; longe delas (mais de 3 pt), não.
        let claro: (UInt8, UInt8, UInt8) = (0x58, 0x79, 0x77)
        let perto = retrato(200, 120, fundo: capsula, pintar: letras.map { ($0, link) } + [(CGRect(x: 72, y: 40, width: 6, height: 24), claro)])
        XCTAssertEqual(try XCTUnwrap(LaudoDeContraste.medirRotulo(perto, quadro: quadro, escala: 3)).nota, 3.33, accuracy: 0.05)
        let longe = retrato(200, 120, fundo: capsula, pintar: letras.map { ($0, link) } + [(CGRect(x: 150, y: 80, width: 6, height: 6), claro)])
        XCTAssertEqual(try XCTUnwrap(LaudoDeContraste.medirRotulo(longe, quadro: quadro, escala: 3)).nota, esperado, accuracy: 0.05)
        XCTAssertNil(LaudoDeContraste.medirRotulo(liso, quadro: .null, escala: 3), "elemento que sumiu (quadro nulo): sem medida, sem queda")
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
