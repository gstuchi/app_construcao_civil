import XCTest
import UIKit

/* Laudo de leitura sobre o vidro de verdade (spec, seção 8; conselho de 08/10). A auditoria de contraste do
   Xcode não lê fundo de vidro, então ela audita as cores com superfícies sólidas (AuditoriaUITests) e este
   laudo mede o que aparece na tela: cada cena em dois prints, um normal e um com o texto apagado, com o
   fundo parado no pior caso (aurora no pior ponto da deriva inteira, globo no ângulo de partida, logo
   pronto). Portão: 4,5:1 no pior ponto de cada palavra, em qualquer tamanho de letra; fica de fora só o que
   a tabela de exceções diz (excecoes): o exemplo da descrição do gasto, informativo no mockup
   (exemploDaDescricao), e, numa cena, o triângulo do aviso do orçamento. Cada cena deixa no
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
    private let temas = ["escuro", "claro"]
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
        /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine).
        var dados = "exemplo"
        var abrir: String? = nil
        /// Folha aberta pelo gancho quando os dados chegam (`novaObra`, `venda:v2`; etapa 2, parte 3).
        var folha: String? = nil
        /// Tela rolada: o texto que passa por baixo da barra é borrado pela borda de rolagem e muda quando é apagado, a
        /// mais de 5 pt das letras; os 140 pt de cima (a borda) ficam de fora, como os de baixo.
        var rolada = false
        /// Toques depois de a tela abrir e antes do print, os mesmos nos dois (a busca, o mês, os Feitos, a linha arrastada;
        /// etapa 3, PR 3): o estado a que se chega pelo toque, sem gancho de teste.
        var toques: (@MainActor (XCUIApplication) -> Void)? = nil
    }

    /// A tabela de exceções do laudo: a cena e a figura que sai dos dois prints dela (`foraDoLaudo(_:)` no app, com
    /// `-custta.foraDoLaudo`; no print anotado da cena ela não aparece). Fora da tabela, só o exemplo da descrição do gasto,
    /// em toda cena em que aparece (`exemploDaDescricao`).
    /// - "obra com orçamento por tópico, na maior letra": o triângulo do aviso dos tópicos. É uma Image ao lado do texto, e o
    ///   texto apagado não a tira: ela fica nos dois prints, mas no Pro Max o print sem texto a desenha 0,26 px mais baixo
    ///   (os valores que encolhem em cima dela medem uma fração de ponto diferente sem o texto) e as bordas, reamostradas,
    ///   mudam até 204: viram "letra" com o próprio triângulo de fundo (1,33:1). Nenhuma folga inteira casa (a melhor é
    ///   0 px). Só o ícone sai: a frase do aviso, na mesma cor (alertaNoVidro), segue medida nesta cena, nas outras e no
    ///   18 Pro (decisão do Prumo, 21/10).
    private static let excecoes = ["obra com orçamento por tópico, na maior letra": "iconeDoAviso"]

    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect]) {
        let excecao = Self.excecoes[cena.nome].map { ["-custta.foraDoLaudo", $0] } ?? []
        let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir, folha: cena.folha,
                           argumentos: cena.argumentos + excecao + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
        XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
        if let aba = cena.aba {
            app.abrirAba(aba)
            XCTAssertTrue(app.elemento("sair").waitForExistence(timeout: 10), "\(cena.nome): Ajustes não abriu")
        }
        cena.toques?(app)
        Thread.sleep(forTimeInterval: 2)                           // o vidro e a rolagem assentam
        let foto = XCUIScreen.main.screenshot()
        let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
        let largura = app.frame.width
        let informativo = exemploDaDescricao(app, cena)
        app.terminate()
        return (foto, abas, largura, informativo)
    }

    /// O exemplo da descrição do gasto ("Ex: 50 sacos de cimento") é o único texto fora do portão: o mockup aprovado o
    /// marca como informativo (parte2.html:1981), no terciário sobre a linha sólida da folha (3,40:1 no escuro esmeralda,
    /// 3,84 no escuro azul), o mesmo tom do prompt do campo no build 3.1. O laudo não via aquele prompt (quem o desenha é
    /// o UIKit, e o texto apagado não o tira); o exemplo virou Text para quebrar linha na letra grande e passou a ser
    /// medido. Sai a caixa do campo vazio e, embaixo dela, as linhas do exemplo, medidas como na AuditoriaUITests (letra
    /// do corpo na largura do campo). Com texto digitado o exemplo some e nada sai; o texto do campo, como o prompt, o
    /// UIKit desenha e o laudo não vê (mutação no terciário passa): o Texto sobre a LinhaDaFolha fica no PARES_SOLIDOS.
    @MainActor private func exemploDaDescricao(_ app: XCUIApplication, _ cena: Cena) -> [CGRect] {
        let campo = app.textFields["descricao"]
        guard campo.exists, let exemplo = campo.placeholderValue else { return [] }
        let valor = campo.value as? String ?? ""
        guard valor.isEmpty || valor == exemplo else { return [] }
        let categoria = cena.argumentos.firstIndex(of: "-UIPreferredContentSizeCategoryName")
            .map { UIContentSizeCategory(rawValue: cena.argumentos[$0 + 1]) } ?? .large
        let corpo = UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: categoria))
        let altura = (exemplo as NSString).boundingRect(with: CGSize(width: campo.frame.width, height: .greatestFiniteMagnitude),
                                                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                        attributes: [.font: corpo], context: nil).height
        var caixa = campo.frame
        caixa.size.height = max(caixa.height, altura.rounded(.up))
        return [caixa.insetBy(dx: -2, dy: -2)]
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
        let (normal, abas, largura, informativo) = fotografar(cena, textoApagado: false)
        let (semTexto, _, _, _) = fotografar(cena, textoApagado: true)
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
        let borda = cena.rolada ? [CGRect(x: 0, y: 0, width: largura, height: 140)] : []
        let palavras = try LaudoDeContraste.medir(normal: Retrato(imagem), semTexto: Retrato(semTexto.image.cgImage!),
                                                  escala: escala, topo: Self.barraDeStatus,
                                                  somenteEm: cena.escopo == "navegacao" ? regiao : nil,
                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador + borda + informativo)
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
    /// lista rolada, no escuro e no claro.
    @MainActor func testLeituraNosDoisTemas() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                Cena(nome: "entrar, \(tema)", conta: "nenhuma", argumentos: combo, espera: "email", escopo: "tudo"),
                Cena(nome: "obras, \(tema)", conta: "senha-nao-confirmada", argumentos: combo,
                     espera: "avisoEmail", escopo: "tudo"),
            ]
            // Os rótulos da cápsula com o conteúdo passando atrás deles: a lista em várias rolagens, porque o pior
            // ponto muda com os dados e o combo (no fim da lista, 260 pt, já não passa nada atrás dos rótulos).
            cenas += Self.rolagens.map { rolagem in
                Cena(nome: "abas sobre a lista em \(rolagem) pt, \(tema)", conta: "senha-nao-confirmada",
                     argumentos: combo + ["-custta.rolagem", "\(rolagem)"], espera: "avisoEmail", escopo: "navegacao")
            }
        }
        cobrar(cenas)
    }

    /// Na maior letra o texto cai em outra parte da aurora; com "Aumentar contraste", o vidro é o Fosco com
    /// contorno. Os dois no escuro, onde a aurora é mais clara que o texto.
    @MainActor func testLeituraNaMaiorLetraEComAumentarContraste() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        let contraste = escuro + ["-custta.aumentarContraste", "YES"]
        cobrar([
            Cena(nome: "obras na maior letra", conta: "senha-nao-confirmada", argumentos: escuro + maiorLetra,
                 espera: "avisoEmail", escopo: "tudo"),
            Cena(nome: "entrar com Aumentar contraste", conta: "nenhuma", argumentos: contraste, espera: "email", escopo: "tudo"),
            Cena(nome: "obras com Aumentar contraste", conta: "senha-nao-confirmada", argumentos: contraste,
                 espera: "avisoEmail", escopo: "tudo"),
        ])
    }

    /// Ajustes: o título grande (do sistema, com o halo da barra), o painel da Aparência (o rótulo, os nomes das opções e
    /// a nota sobre o vidro, e o aviso com "Aumentar contraste"), a Conta e a versão, texto solto sobre a aurora; nos dois
    /// temas e nas duas doses, com "Aumentar contraste" e na maior letra (no alto e rolada até a Conta e a versão, que a
    /// Aparência empurra para baixo). No Pro Max, a versão fica em 4,42:1 no escuro esmeralda sem o halo (revisão final
    /// do PR 2).
    @MainActor func testLeituraEmAjustes() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        var cenas: [(String, [String], Bool)] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [("\(tema), Transparente", combo, false), ("\(tema), Fosco", combo + ["-custta.vidro", "fosco"], false)]
        }
        cenas += [("com Aumentar contraste", escuro + ["-custta.aumentarContraste", "YES"], false),
                  ("na maior letra", escuro + maiorLetra, false),
                  ("na maior letra, rolada", escuro + maiorLetra + ["-custta.rolagem", "2000"], true)]
        cobrar(cenas.map { nome, argumentos, rolada in
            Cena(nome: "ajustes, \(nome)", conta: "senha", argumentos: argumentos, espera: "aba-ajustes", escopo: "tudo",
                 aba: "ajustes", rolada: rolada)
        })
    }
}

extension LeituraNoVidroUITests {
    /// O "Cancelar" do "Sair da conta?" no escuro e no claro, no tint do alerta (Texto). O texto do alerta
    /// é do sistema e o app não o apaga: o rótulo é medido contra a própria cápsula (`medirRotulo`). Exceção:
    /// o "Sair" não é medido. É destrutivo, e o vermelho do sistema não segue o tint (2,2 a 3,0:1 no iOS 27); fica
    /// o padrão da Apple (decisão de 11/10).
    @MainActor func testLeituraDoAlertaDeSair() {
        var falhas: [String] = []
        for tema in temas {
            let nome = "alerta Sair da conta?, \(tema)"
            let app = abrirApp(conta: "senha", argumentos: ["-custta.tema", tema] + piorMomento)
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

    /// O "Finalizar saída" no escuro e no claro, nos três estados do mockup: o título e o botão do alerta (no tint Texto,
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
        for tema in temas {
            let app = abrirApp(conta: "nenhuma", limpeza: "abertura",
                               argumentos: ["-custta.tema", tema] + piorMomento + (letraGrande ? maiorLetra : []))
            let alerta = app.alerts[FinalizarSaidaUITests.titulo], botao = alerta.buttons[FinalizarSaidaUITests.botao]
            for estado in ["aberto", "tentando", "falhou de novo"] {
                let nome = "finalizar saída\(letraGrande ? " na maior letra" : ""), \(estado), \(tema)"
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

    /// A tela da obra (etapa 2): o topo (título, fase, indicadores) e a lista rolada (o "A vencer" e os cartões dos meses),
    /// no escuro e no claro; mais a maior letra e o Aumentar contraste, no escuro esmeralda. A vendida fica no
    /// testLeituraDaObraVendida (lucro e prejuízo). A lista em 905 pt: a 640 até a etapa 2; a linha do orçamento da vitrine
    /// (118 pt, PR 1 da etapa 3) e a linha dos afazeres com o cabeçalho da busca (117 pt, PR 3) empurraram tudo o que vem
    /// depois deles. A borda de cima fica no vão entre a pílula "Lançamentos" e o "A vencer" (no 18 Pro, 23 pt abaixo da pílula
    /// e 18 acima do "A vencer"): a 875, os mesmos 758 de antes mais 117, ela cortava a pílula.
    @MainActor func testLeituraDaObra() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                Cena(nome: "obra, topo, \(tema)", conta: "senha", argumentos: combo, espera: "tituloDaObra", escopo: "tudo",
                     dados: "vitrine", abrir: "obra:v1"),
                Cena(nome: "obra, lista, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "905"],
                     espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
            ]
        }
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        cenas += [
            Cena(nome: "obra na maior letra", conta: "senha", argumentos: escuro + maiorLetra, espera: "tituloDaObra", escopo: "tudo",
                 dados: "vitrine", abrir: "obra:v1"),
            Cena(nome: "obra com Aumentar contraste", conta: "senha", argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "905"],
                 espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
        ]
        cobrar(cenas)
    }

    /// A lista da obra rolando, no escuro (onde a dose de vidro decide), sem e com Aumentar contraste: o pior
    /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, seis rolagens; na
    /// CI, duas.
    @MainActor func testLeituraDaObraRolando() {
        // As da etapa 2 (200 a 1500) desceram 118 pt com a linha do orçamento da vitrine (PR 1 da etapa 3). No PR 3, cada uma
        // tem a borda de cima no meio de um vão entre duas linhas (de 12 a 23 pt de folga no 18 Pro, em 25/10), sem palavra
        // cortada pela borda: a 318 fica; a 561 é a 518 mais 43 (a 518 já cortava uma palavra); da terceira em diante, as de
        // antes mais 117 (a linha dos afazeres e o cabeçalho da busca, que o PR 3 pôs depois das ações) cortavam palavra (a
        // 1318, a linha de baixo de um gasto em 3,91), e cada uma foi para o vão mais perto. A 318 e a 561 mostram a linha dos
        // afazeres e a busca embaixo. Da 1101 para baixo, as linhas são as dos cartões dos meses, que mudam com o dia (a
        // vitrine conta os gastos a partir de hoje): em 26/10, a "Quinzena do pedreiro" de 55 dias atrás passou de agosto para
        // setembro, e a 1715 ficou com 8 pt de folga embaixo; com o hoje deslocado para 3/11 (o cartão do mês novo nasce com um
        // gasto só), a 561 e a 1101 seguem num vão, e a 1423 e a 1715 cortam uma palavra pela borda (que passa, de 6,26 a 7,26).
        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [561, 1101] : [318, 561, 905, 1101, 1423, 1715]
        var cenas: [Cena] = []
        for contraste in [false, true] {
            for y in rolagens {
                let argumentos = ["-custta.tema", "escuro", "-custta.rolagem", "\(y)"] + piorMomento
                    + (contraste ? ["-custta.aumentarContraste", "YES"] : [])
                // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
                cenas.append(Cena(nome: "obra rolando \(y), escuro\(contraste ? ", Aumentar contraste" : "")", conta: "senha",
                                  argumentos: argumentos, espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine",
                                  abrir: "obra:v1", rolada: true))
            }
        }
        cobrar(cenas)
    }

    /// A folha do gasto (PR 2 da etapa 2): o teclado de valor, os detalhes no Pix e no cartão (o resumo e a ajuda ficam
    /// direto na Folha), a lista de tópicos, a edição de uma parcela e o "Salvar mesmo assim" âmbar, no escuro e no claro;
    /// na maior letra e com Aumentar contraste; e a linha arrastada com o "Apagar" na lista da obra.
    @MainActor func testLeituraDaFolhaDoGasto() {
        func folha(_ nome: String, _ passo: String, _ argumentos: [String], espera: String) -> Cena {
            Cena(nome: nome, conta: "senha", argumentos: argumentos + ["-custta.folha", passo], espera: espera, escopo: "tudo",
                 dados: "vitrine", abrir: "obra:v1")
        }
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                folha("folha, valor, \(tema)", "valor", combo, espera: "visorDoValor"),
                folha("folha, detalhes, \(tema)", "detalhes", combo, espera: "linhaTopico"),
                folha("folha, cartão, \(tema)", "cartao", combo, espera: "resumoDoCartao"),
                folha("folha, tópicos, \(tema)", "topicos", combo, espera: "topico-terreno"),
                folha("folha, parcela, \(tema)", "editar:g031", combo, espera: "avisoParcela"),
                folha("folha, repetido, \(tema)", "repetido", combo, espera: "avisoRepetido"),
                // A 835 põe a borda no vão entre os afazeres e a pílula; a 758 de antes, com a lista 117 pt mais abaixo
                // desde o PR 3, cortava o cabeçalho dos afazeres.
                Cena(nome: "obra, linha aberta, \(tema)", conta: "senha",
                     argumentos: combo + ["-custta.rolagem", "835", "-custta.linhaAberta", "g027"], espera: "apagar-g027",
                     escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
            ]
        }
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        let contraste = escuro + ["-custta.aumentarContraste", "YES"]
        cenas += [
            folha("folha, valor, na maior letra", "valor", escuro + maiorLetra, espera: "visorDoValor"),
            folha("folha, cartão, na maior letra", "cartao", escuro + maiorLetra, espera: "linhaTopico"),
            folha("folha, cartão, com Aumentar contraste", "cartao", contraste, espera: "resumoDoCartao"),
            folha("folha, repetido, com Aumentar contraste", "repetido", contraste, espera: "avisoRepetido"),
        ]
        cobrar(cenas)
    }
}

extension LeituraNoVidroUITests {
    /// A parte 3 da etapa 2: as ações da fase (a sólida da marca e a de vidro), a lista vazia, as folhas da obra e da venda
    /// e a do gasto lançado de dentro de uma vendida, no escuro e no claro; mais a maior letra no escuro esmeralda.
    @MainActor func testLeituraDaParte3() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                Cena(nome: "obra pronta, ações da fase, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "250"],
                     espera: "acao-voltarConstrucao", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
                Cena(nome: "lista vazia, \(tema)", conta: "senha", argumentos: combo, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
                Cena(nome: "folha da obra nova, \(tema)", conta: "senha", argumentos: combo + ["-custta.folha", "preenchida"],
                     espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
                Cena(nome: "folha da venda, data, \(tema)", conta: "senha", argumentos: combo + ["-custta.folha", "detalhes"],
                     espera: "confirmarVenda", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2"),
            ]
        }
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        cenas += [
            Cena(nome: "folha do gasto numa vendida", conta: "senha", argumentos: escuro + ["-custta.folha", "detalhes"],
                 espera: "linhaObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v3", folha: "gastoDeVendida:v3"),
            Cena(nome: "folha de editar obra", conta: "senha", argumentos: escuro, espera: "apagarObra", escopo: "tudo",
                 dados: "vitrine", abrir: "obra:v1", folha: "editarObra:v1"),
        ]
        cobrar(cenas)
    }

    /// A obra vendida: o lucro (PositivoNoVidro) e o prejuízo (NegativoNoVidro) sobre o vidro e o "Desfazer venda" de vidro,
    /// no escuro e no claro. Com o Positivo e o Negativo do site, o lucro ficava em 3,66:1 no escuro esmeralda e 2,76:1 no
    /// claro azul.
    @MainActor func testLeituraDaObraVendida() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento + ["-custta.rolagem", "400"]
            cenas += [
                Cena(nome: "obra vendida com lucro, \(tema)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
                     escopo: "tudo", dados: "vitrine", abrir: "obra:v3", rolada: true),
                Cena(nome: "obra vendida com prejuízo, \(tema)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
                     escopo: "tudo", dados: "prejuizo", abrir: "obra:v3", rolada: true),
            ]
        }
        cobrar(cenas)
    }

    @MainActor func testLeituraDaParte3NaMaiorLetra() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento + maiorLetra
        cobrar([
            // Espera o lápis da barra: rolada a 1100 pt em 300 ms, o título sai da pilha preguiçosa antes da espera achar.
            Cena(nome: "obra pronta, ações da fase, na maior letra", conta: "senha", argumentos: escuro + ["-custta.rolagem", "1100"],
                 espera: "editarObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
            Cena(nome: "lista vazia na maior letra", conta: "senha", argumentos: escuro, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
            Cena(nome: "folha da obra nova na maior letra", conta: "senha", argumentos: escuro + ["-custta.folha", "preenchida"],
                 espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
            Cena(nome: "folha da venda na maior letra", conta: "senha", argumentos: escuro + ["-custta.folha", "detalhes"],
                 espera: "confirmarVenda", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2"),
        ])
    }

    /// O "Não salvou" (uma vez, quando o erro não passa sozinho), no escuro e no claro: "OK" e "Tentar de novo" no tint do alerta
    /// (Texto), medidos contra a própria cápsula, como o "Cancelar" do "Sair da conta?".
    @MainActor func testLeituraDoAlertaDeNaoSalvou() {
        var falhas: [String] = []
        for tema in temas {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa",
                               argumentos: ["-custta.tema", tema] + piorMomento)
            let pronta = app.buttons["acao-marcarPronta"]
            XCTAssertTrue(pronta.waitForExistence(timeout: 10))
            app.rolarAte(pronta)
            pronta.tap()
            let alerta = app.alerts["Não salvou na nuvem"]
            XCTAssertTrue(alerta.waitForExistence(timeout: 8), "\(tema): o alerta não abriu")
            Thread.sleep(forTimeInterval: 2)
            let foto = XCUIScreen.main.screenshot()
            let imagem = foto.image.cgImage!
            let escala = CGFloat(imagem.width) / app.frame.width
            let botoes = ["OK", "Tentar de novo"].map { ($0, alerta.buttons[$0].frame) }
            app.terminate()
            for (rotulo, quadro) in botoes {
                let nome = "alerta Não salvou, \(rotulo), \(tema)"
                guard let palavra = LaudoDeContraste.medirRotulo(Retrato(imagem), quadro: quadro, escala: escala) else {
                    XCTFail("\(nome): o rótulo não foi achado"); continue
                }
                anexar(nome, foto.image, [palavra], escala)
                Swift.print(String(format: "leitura | %@ | %@ | nota %.2f (pior pixel %.2f)", nome, palavra.corHex, palavra.nota, palavra.minimo))
                if palavra.nota < Self.portao { falhas.append(String(format: "%@ em %.2f:1", nome, palavra.nota)) }
            }
        }
        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 no alerta:\n" + falhas.joined(separator: "\n"))
    }
}

extension LeituraNoVidroUITests {
    /// O orçamento (etapa 3, PR 1), no escuro e no claro: a linha do orçamento por tópico na obra (o aviso dos tópicos no
    /// âmbar sobre o vidro), a tela Orçamento no alto e rolada (as frases do "Por tópico" e o que está fora) e no modo total
    /// (o gasto por tópico e a dica), e a folha com as teclas encaixadas, por tópico e no "Definir orçamento". Roda no job
    /// laudo-etapa3.
    @MainActor func testLeituraDoOrcamento() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                Cena(nome: "obra com orçamento por tópico, \(tema)", conta: "senha", argumentos: combo,
                     espera: "indicadorOrcamento", escopo: "tudo", dados: "porTopico", abrir: "obra:v1"),
                Cena(nome: "tela Orçamento, topo, \(tema)", conta: "senha", argumentos: combo,
                     espera: "cartaoDoOrcamento", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
                // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
                Cena(nome: "tela Orçamento, rolada, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "700"],
                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
                // 8 pt antes do fim: no fim, a borda de cima cortava o "5% da obra" do Telhado (o laudo mede a parte de baixo
                // de uma palavra que entra no véu); aqui ela fica entre o nome do Telhado e o percentual, e a dica ainda aparece.
                Cena(nome: "tela Orçamento, só o total, fim, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "606"],
                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "orcamento:v1", rolada: true),
                Cena(nome: "folha do orçamento, por tópico, digitando, \(tema)", conta: "senha",
                     argumentos: combo + ["-custta.folha", "teclas:eletrica"], espera: "barraDasTeclas-nome", escopo: "tudo",
                     dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1"),
                Cena(nome: "folha do orçamento, definir, \(tema)", conta: "senha", argumentos: combo, espera: "tecla-1",
                     escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", folha: "orcamento:v1"),
            ]
        }
        cobrar(cenas)
    }

    /// O orçamento na maior letra (o dinheiro das frases na própria linha, o chip que quebra, as teclas no tamanho do AX2) e
    /// com Aumentar contraste, no escuro esmeralda.
    @MainActor func testLeituraDoOrcamentoNaMaiorLetra() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        let grande = escuro + maiorLetra, contraste = escuro + ["-custta.aumentarContraste", "YES"]
        cobrar([
            // O triângulo do aviso sai dos dois prints desta cena (a tabela de exceções, `excecoes`); a frase dele fica.
            Cena(nome: "obra com orçamento por tópico, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "700"],
                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "obra:v1", rolada: true),
            Cena(nome: "tela Orçamento, topo, na maior letra", conta: "senha", argumentos: grande, espera: "cartaoDoOrcamento",
                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
            // A 1637 pt, nos dois iPhones, a borda de cima fica no vão entre a Estrutura e a Fundação, sem texto nem barra logo
            // abaixo dela, sob o véu: no 18 Pro (a largura da CI), o nome da Fundação começa 11 pt abaixo; no Pro Max, só o fio
            // entre as linhas (3 pt) e o nome, a 28. A 1500, no Pro Max, a barra da Estrutura ficava 6 pt abaixo da borda, com o
            // texto borrado pelo véu logo acima, e o alto dela mudava entre os dois prints (1837 px longe das letras:
            // CenaNaoDeterministica). De 1615 a 1660, nos dois, nenhum pixel muda longe das letras.
            Cena(nome: "tela Orçamento, rolada, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "1637"],
                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
            // Na maior letra, a linha ativa no meio da faixa leva o alto da lista (o segmentado) para baixo da barra da folha,
            // que borra o que passa por ela: as cenas da folha com as teclas são roladas.
            Cena(nome: "folha do orçamento, por tópico, digitando, na maior letra", conta: "senha",
                 argumentos: grande + ["-custta.folha", "teclas:eletrica"], espera: "barraDasTeclas-pronto", escopo: "tudo",
                 dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1", rolada: true),
            Cena(nome: "folha do orçamento, definir, na maior letra", conta: "senha", argumentos: grande, espera: "tecla-1",
                 escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", folha: "orcamento:v1", rolada: true),
            Cena(nome: "tela Orçamento com Aumentar contraste", conta: "senha", argumentos: contraste, espera: "cartaoDoOrcamento",
                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
        ])
    }
}

extension LeituraNoVidroUITests {
    /// As folhas de origem (etapa 3, PR 2), no escuro e no claro. O A pagar: com os vencimentos (na letra padrão a folha cabe
    /// inteira, com a frase do fim), no fim de uma lista longa, vazio e com a edição de um vencimento empurrada (o "A pagar"
    /// embaixo do título, o voltar ao lado). O detalhe do tópico: a Cerâmica no topo e rolada até os pagos, a Estrutura, que
    /// passou do orçamento (a frase no Alerta sobre a linha da folha), a Documentação, fora do orçamento, a Cerâmica no modo
    /// total e a edição com "Cerâmica". As roladas e as edições abrem pelos ganchos da lista das folhas (`-custta.rolagem` e
    /// `-custta.origem editar:<gasto>`). Roda no job laudo-etapa3.
    @MainActor func testLeituraDasFolhasDeOrigem() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                Cena(nome: "A pagar, \(tema)", conta: "senha", argumentos: combo, espera: "resumoDoAPagar", escopo: "tudo",
                     dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
                // As 20 diárias do topicoLongo alongam a lista. A 1092 pt, 5 antes do fim no 18 Pro, a borda de cima fica no vão
                // entre duas diárias; a frase do fim cai na faixa de baixo, que o laudo deixa de fora (a da cápsula de abas, que
                // segue atrás da folha): a cena mede as linhas que passam pelo meio.
                Cena(nome: "A pagar, fim, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "1092"],
                     espera: "ponteDoAPagar", escopo: "tudo", dados: "topicoLongo", abrir: "obra:v1", folha: "aPagar:v1", rolada: true),
                Cena(nome: "A pagar vazio, \(tema)", conta: "senha", argumentos: combo, espera: "aPagarVazio", escopo: "tudo",
                     dados: "vitrine", abrir: "obra:v2", folha: "aPagar:v2"),
                Cena(nome: "A pagar, editar gasto, \(tema)", conta: "senha", argumentos: combo + ["-custta.origem", "editar:g039"],
                     espera: "salvarGasto", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
                Cena(nome: "detalhe, Cerâmica, topo, \(tema)", conta: "senha", argumentos: combo, espera: "orcamentoDoTopico",
                     escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest"),
                // A 500 pt (a Cerâmica rola até 575), a borda de cima fica no fio entre duas linhas e os pagos passam pelo meio.
                // A espera não prova a rolagem: a pilha preguiçosa já monta as 16 peças da Cerâmica no topo.
                Cena(nome: "detalhe, Cerâmica, rolada, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "500"],
                     espera: "gasto-g021", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest",
                     rolada: true),
                Cena(nome: "detalhe, Estrutura, passou, \(tema)", conta: "senha", argumentos: combo, espera: "orcamentoDoTopico",
                     escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:estrutura"),
                Cena(nome: "detalhe, Documentação, fora, \(tema)", conta: "senha", argumentos: combo, espera: "orcamentoDoTopico",
                     escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:projeto"),
                Cena(nome: "detalhe, só o total, \(tema)", conta: "senha", argumentos: combo, espera: "secao-A vencer",
                     escopo: "tudo", dados: "vitrine", abrir: "orcamento:v1", folha: "topico:v1:revest"),
                Cena(nome: "detalhe, editar gasto, \(tema)", conta: "senha", argumentos: combo + ["-custta.origem", "editar:g021"],
                     espera: "salvarGasto", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest"),
            ]
        }
        cobrar(cenas)
    }

    /// As folhas de origem na maior letra e com Aumentar contraste, no escuro (o molde é o testLeituraDoOrcamentoNaMaiorLetra):
    /// o A pagar no topo e rolado e a edição de um vencimento empurrada; o detalhe da Cerâmica no topo e rolado, a Estrutura (a
    /// frase do "passou" no Alerta, a mais fraca do laudo da letra padrão) e a edição com "Cerâmica"; com Aumentar contraste, o
    /// A pagar e a Cerâmica. As roladas e as edições abrem pelos ganchos da lista das folhas, como no testLeituraDasFolhasDeOrigem.
    /// Roda no job laudo-etapa3-b.
    @MainActor func testLeituraDasFolhasDeOrigemNaMaiorLetra() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        let grande = escuro + maiorLetra, contraste = escuro + ["-custta.aumentarContraste", "YES"]
        cobrar([
            Cena(nome: "A pagar, na maior letra", conta: "senha", argumentos: grande, espera: "resumoDoAPagar", escopo: "tudo",
                 dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
            // A 248 pt, nos dois iPhones, a borda de cima fica no vão entre o resumo e o cabeçalho do primeiro mês: no 18 Pro (a
            // largura da CI), 12 pt abaixo do "3 vencimentos…" e 60 acima do mês; no Pro Max, 59 e 13. Esse vão não depende do dia
            // (o mês do primeiro vencimento vem sempre logo depois do resumo); os de baixo, sim (os vencimentos da vitrine mudam de
            // mês com o dia). A cena mede o cabeçalho do mês e a primeira linha quase inteira.
            Cena(nome: "A pagar, rolado, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "248"],
                 espera: "resumoDoAPagar", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1", rolada: true),
            Cena(nome: "A pagar, editar gasto, na maior letra", conta: "senha", argumentos: grande + ["-custta.origem", "editar:g039"],
                 espera: "salvarGasto", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
            Cena(nome: "detalhe, Cerâmica, topo, na maior letra", conta: "senha", argumentos: grande, espera: "orcamentoDoTopico",
                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest"),
            // A 628 pt, nos dois iPhones, a borda fica no vão entre a frase do orçamento e o "A vencer · 6": no 18 Pro, 23 pt abaixo
            // da frase e 13 acima do cabeçalho; no Pro Max, 12 e 24. Mais para baixo, as linhas dos dois iPhones se desencontram
            // (no 18 Pro, o último a vencer quebra uma linha a mais) e nenhuma rolagem acha um vão comum nos pagos: eles ficam com
            // a cena rolada da letra padrão.
            Cena(nome: "detalhe, Cerâmica, rolada, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "628"],
                 espera: "orcamentoDoTopico", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest",
                 rolada: true),
            Cena(nome: "detalhe, Estrutura, passou, na maior letra", conta: "senha", argumentos: grande, espera: "orcamentoDoTopico",
                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:estrutura"),
            Cena(nome: "detalhe, editar gasto, na maior letra", conta: "senha", argumentos: grande + ["-custta.origem", "editar:g021"],
                 espera: "salvarGasto", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest"),
            Cena(nome: "A pagar com Aumentar contraste", conta: "senha", argumentos: contraste, espera: "resumoDoAPagar",
                 escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
            Cena(nome: "detalhe, Cerâmica, com Aumentar contraste", conta: "senha", argumentos: contraste, espera: "orcamentoDoTopico",
                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest"),
        ])
    }
}

extension LeituraNoVidroUITests {
    /// A busca e os afazeres (etapa 3, PR 3), no escuro e no claro, na Casa Alphaville da vitrine; tudo pelo toque
    /// (`Cena.toques`), sem gancho novo. A busca: os lançamentos com o campo vazio e o chip do mês de hoje, em repouso (o
    /// "buscar" do teclado o fecha); o mês de hoje com a soma; "ceramica", com os achados e a soma deles; "azulejo", nada
    /// achado, com o "Limpar a busca"; e o mês sem gasto, com o "Ver todos os meses" (o mês mais novo tem só a última parcela
    /// do porcelanato, daqui a 175 dias, em qualquer dia: apagada só ela, o mês fica vazio). A lista fica parada pela rolagem
    /// fixa da obra, que a segura mesmo depois da lupa (sem ela, a lupa põe a pílula "Lançamentos" sob a borda). A 835 pt, a
    /// borda de cima fica no vão entre a linha dos afazeres e a pílula (no 18 Pro, 26 pt abaixo de uma e 32 acima da outra),
    /// acima de tudo o que muda com o dia. As listas curtas não chegam aos 835 e param no fim: no mês sem gasto, a borda fica
    /// no vão entre os dois últimos indicadores (7 pt abaixo do "Parcelas e gastos futuros" e 24 acima do "Venda estimada");
    /// no nada achado, o fim a punha sobre o valor da venda estimada, e a 596 pt (7 antes do fim) ela fica no vão entre o
    /// "Venda estimada" e o valor, a 7 pt de cada um, com o "Limpar a busca" 26 pt acima da faixa de baixo. Nenhuma dessas
    /// linhas muda com o dia. Os afazeres: a tela com os 3 pendentes (o de 213 caracteres inteiro) e os "Feitos" fechados, os
    /// "Feitos" abertos, o vazio (a Casa Tamboré) e a linha arrastada com o "Apagar". Ficam de fora: o menu do mês, que é do
    /// sistema (nem a cor nem o vidro dele são do app); e o texto digitado e o prompt dos campos, que o UIKit desenha e o
    /// texto apagado não tira (ponto cego do laudo: saem iguais nos dois prints). Roda no job laudo-etapa3-b.
    @MainActor func testLeituraDaBuscaEDosAfazeres() {
        let hoje = Self.mesPorExtenso(daqui: 0), maisNovo = Self.mesPorExtenso(daqui: 175)
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            func busca(_ nome: String, rolagem: Int = 835, _ toques: @escaping @MainActor (XCUIApplication) -> Void) -> Cena {
                Cena(nome: "busca, \(nome), \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "\(rolagem)"],
                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, toques: toques)
            }
            cenas += [
                busca("em repouso") { app in
                    Self.buscar(app, "")
                    Self.escolherMes(app, hoje)
                },
                busca("mês") { app in Self.escolherMes(app, hoje) },
                busca("achados") { app in Self.buscar(app, "ceramica") },
                busca("nada achado", rolagem: 596) { app in Self.buscar(app, "azulejo") },
                busca("mês sem gasto") { app in
                    Self.escolherMes(app, maisNovo)
                    let linha = app.elemento("gasto-g037")
                    XCTAssertTrue(linha.waitForExistence(timeout: 5), "a última parcela no A vencer, aberto pelo filtro")
                    linha.swipeLeft()
                    app.buttons["apagar-g037"].tap()
                    app.alerts.firstMatch.buttons["Apagar só esta parcela"].tap()
                    XCTAssertTrue(app.elemento("buscaMesSemGasto").waitForExistence(timeout: 5), "o mês ficou sem gasto")
                },
                Cena(nome: "afazeres, \(tema)", conta: "senha", argumentos: combo, espera: "pendentes", escopo: "tudo",
                     dados: "vitrine", abrir: "afazeres:v1"),
                Cena(nome: "afazeres, feitos abertos, \(tema)", conta: "senha", argumentos: combo, espera: "pendentes", escopo: "tudo",
                     dados: "vitrine", abrir: "afazeres:v1", toques: { app in
                         app.elemento("feitos").tap()
                         XCTAssertTrue(app.elemento("afazer-a4").waitForExistence(timeout: 5), "os Feitos abertos")
                     }),
                Cena(nome: "afazeres vazio, \(tema)", conta: "senha", argumentos: combo, espera: "afazeresVazio", escopo: "tudo",
                     dados: "vitrine", abrir: "afazeres:v3"),
                Cena(nome: "afazeres, linha aberta, \(tema)", conta: "senha", argumentos: combo, espera: "pendentes", escopo: "tudo",
                     dados: "vitrine", abrir: "afazeres:v1", toques: { app in
                         app.elemento("afazer-a3").swipeLeft()
                         XCTAssertTrue(app.buttons["apagar-a3"].waitForExistence(timeout: 3), "arrastar mostra Apagar")
                     }),
            ]
        }
        cobrar(cenas)
    }

    /// O mês por extenso, como o menu e o chip o mostram ("Outubro de 2026"), daqui a tantos dias: a vitrine conta os gastos a
    /// partir de hoje, e o mês de hoje sempre tem gasto (o g039, daqui a 3 dias, ou o g027, de 2 dias atrás).
    private static func mesPorExtenso(daqui dias: Int) -> String {
        let data = Calendar(identifier: .gregorian).date(byAdding: .day, value: dias, to: .now) ?? .now
        let formato = DateFormatter()
        formato.locale = Locale(identifier: "pt_BR")
        formato.dateFormat = "LLLL 'de' yyyy"
        let texto = formato.string(from: data)
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }

    /// O mês pelo menu do sistema, tocado pelo título (o item traz a contagem no subtítulo), como no BuscaUITests.
    @MainActor private static func escolherMes(_ app: XCUIApplication, _ titulo: String) {
        app.buttons["filtrarPorMes"].tap()
        let item = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", titulo, titulo + ",")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "o menu mostra \(titulo)")
        item.tap()
        XCTAssertTrue(app.elemento("chipDoMes").waitForExistence(timeout: 5), "o chip de \(titulo)")
    }

    /// A lupa abre o campo com o teclado; o texto entra e o "buscar" do teclado o fecha, com a busca aberta (em repouso).
    @MainActor private static func buscar(_ app: XCUIApplication, _ texto: String) {
        app.buttons["buscar"].tap()
        app.digitarComFoco(texto + "\n", em: app.textFields["campoDaBusca"])
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "o buscar do teclado o fecha")
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

    /// O que muda até 1 pt entre os prints longe das letras (o valor que encolhe na maior letra empurra o que vem embaixo
    /// 1 px, e na tela Orçamento há mais de um valor em cima) é a mesma cena: o separador não muda a cena e a borda forte
    /// não vira palavra. Na escala 3, a folga é de 3 px; com 4 px, a cena mudou.
    func testBordaQueMudaAteUmPontoNaoMudaACena() throws {
        let separador: (UInt8, UInt8, UInt8) = (0x26, 0x40, 0x38), borda: (UInt8, UInt8, UInt8) = (0x80, 0x90, 0x88)
        func retratos(_ desce: CGFloat, _ cor: (UInt8, UInt8, UInt8)) -> (Retrato, Retrato) {
            (retrato(200, 120, fundo: fundo, pintar: letras.map { ($0, branco) } + [(CGRect(x: 100, y: 100, width: 90, height: 1), cor)]),
             retrato(200, 120, fundo: fundo, pintar: [(CGRect(x: 100, y: 100 + desce, width: 90, height: 1), cor)]))
        }
        for desce in 1...3 {
            for cor in [separador, borda] {
                let (normal, semTexto) = retratos(CGFloat(desce), cor)
                XCTAssertEqual(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3).count, 1,
                               "\(desce) px: só as três letras")
            }
        }
        let (normal, semTexto) = retratos(4, separador)
        XCTAssertThrowsError(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3)) { erro in
            XCTAssertTrue(erro is LaudoDeContraste.CenaNaoDeterministica)
        }
    }

}
