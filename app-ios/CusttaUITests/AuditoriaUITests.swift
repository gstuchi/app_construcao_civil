import XCTest
import UIKit

/* Requisitos verificáveis do spec, seção 8, com a cara do PWA: no maior tamanho de letra de
   acessibilidade nada corta, todo controle tem rótulo e alvo de 44 pt; o contraste das cores passa nos
   quatro combos e sobre a aurora parada (no quadro inicial e nos extremos da deriva). Não crescem com a
   letra, por decisão do mockup, a cápsula de abas, o botão do Google e o título pequeno da barra da obra
   (para perto de 22 pt): os três mostram o Visualizador de Conteúdo Grande, e a auditoria de tipo dinâmico
   os deixa de fora.

   Contraste: a auditoria do Xcode não lê fundo de vidro (no simulador do iOS 27 ela reprova até texto
   escuro sobre a pílula sólida do segmentado, e os mesmos textos com tinta de 6% ou de 50%). Aqui as cores
   são conferidas com "Reduzir transparência" (superfícies sólidas, sem o vidro na frente da aurora), também
   na maior letra; a leitura sobre o vidro de verdade é medida pixel a pixel pelo LeituraNoVidroUITests. */
final class AuditoriaUITests: XCTestCase {
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let tiposDeAuditoria: XCUIAccessibilityAuditType = [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion]
    /// Fundo parado: aurora no quadro inicial, globo no ângulo de partida, logo pronto.
    private let parado = ["-custta.reduzirMovimento", "YES"]
    private let solido = ["-custta.reduzirTransparencia", "YES"]
    private let quatroCombos = [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")]
    /// A borda de rolagem (`BordaDeRolagem`): o véu do fundo cobre 140 pt no alto, depois de rolar, e embaixo,
    /// nas telas com a cápsula de abas (88% e 80% com "Reduzir transparência").
    private let borda: CGFloat = 140

    /// Deixa fora o que não cresce de propósito (dinâmico: a cápsula de abas e o texto do botão do Google,
    /// pelo rótulo, porque a auditoria rola a tela sozinha) e o conteúdo que passa por baixo da barra de
    /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
    /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste.
    @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
        // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
        let folha = app.elemento("tituloDaFolha").exists
        let abas = folha ? [] : ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
        let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
        let barra = app.navigationBars.firstMatch
        let topoDoConteudo = barra.exists ? max(barra.frame.maxY, borda) : 0
        let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        try app.performAccessibilityAudit(for: tipos) { achado in
            guard let elemento = achado.element else {
                Swift.print("auditoria | \(achado.compactDescription) | sem elemento | reprova")
                return false
            }
            let fora: Bool
            switch achado.auditType {
            case .dynamicType:
                // O título pequeno da barra da obra para perto de 22 pt, como o do sistema (mockup da etapa 2), com o
                // Visualizador de Conteúdo Grande.
                // Na folha (mockup da etapa 2): o título para perto de 22 pt, as teclas e o "Apagar" do arrastar param no
                // AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber.
                fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                    || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
                    || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
                    || abas.contains { $0.contains(CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)) }
            case .contrast:
                if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
                else {
                    let sobABarra = elemento.frame.minY < topoDoConteudo && !daBarra.contains(elemento.frame)
                    fora = sobABarra || elemento.frame.maxY > fundoDaTela
                }
            default:
                fora = false
            }
            // Cada achado vai para o log: a CI não guarda o resultado dos testes, e sem esta linha uma reprovação
            // aparece só como "Contrast failed", sem dizer qual elemento nem onde.
            Swift.print("auditoria | \(achado.compactDescription) | \(elemento.elementType.rawValue) \"\(elemento.label)\" "
                        + "\(elemento.identifier) \(elemento.frame) | barra até \(topoDoConteudo), conteúdo até \(fundoDaTela) | "
                        + (fora ? "fora" : "reprova"))
            return fora
        }
    }

    /// Rola e espera a rolagem parar antes de auditar.
    @MainActor private func rolar(_ app: XCUIApplication) {
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.5)
    }

    @MainActor func testEntrarNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra + parado)
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testCriarContaNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra + parado)
        let segmento = app.buttons["irParaCriarConta"]
        for _ in 0..<6 where !(segmento.exists && segmento.isHittable) { app.swipeUp() }
        segmento.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testObrasNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testObraNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    /// A folha do gasto (etapa 2, PR 2) em cada passo, na maior letra; os detalhes também rolados, e o valor também com o
    /// número mais largo do visor (13 caracteres, a largura do teto R$ 99.999.999,99), que encolhe para caber.
    @MainActor func testFolhaDoGastoNoMaiorTamanho() throws {
        for (passo, espera) in [("valor", "visorDoValor"), ("detalhes", "linhaTopico"), ("cartao", "linhaTopico"),
                                ("topicos", "topico-terreno"), ("editar:g031", "avisoParcela")] {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado + ["-custta.folha", passo])
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
            try auditar(app, tiposDeAuditoria)
            if passo == "valor" {
                // Do R$ 1.380,00 do passo de teste: os dígitos têm largura fixa, então este número corta onde o teto cortaria.
                for _ in 0..<4 { app.buttons["tecla-9"].tap() }
                XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 13.800.099,99")
            } else {
                rolar(app)
            }
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    /// A folha do gasto (valor e cartão) e a linha aberta com o "Apagar", nos quatro combos, com superfícies sólidas.
    @MainActor func testContrasteDaFolhaNosQuatroCombos() throws {
        for (tema, pele) in quatroCombos {
            let combo = ["-custta.tema", tema, "-custta.pele", pele] + solido + parado
            for (passo, espera) in [("valor", "visorDoValor"), ("cartao", "resumoDoCartao")] {
                let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: combo + ["-custta.folha", passo])
                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
                try auditar(app, [.contrast])
                app.terminate()
            }
            let lista = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
                                 argumentos: combo + ["-custta.rolagem", "640", "-custta.linhaAberta", "g027"])
            XCTAssertTrue(lista.buttons["apagar-g027"].waitForExistence(timeout: 10))
            try auditar(lista, [.contrast])
            lista.terminate()
        }
    }

    @MainActor func testAjustesNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        try auditar(app, tiposDeAuditoria)
    }

    /// O falta pouco das contas Apple e Google, que nenhuma outra auditoria abre na maior letra.
    @MainActor func testFaltaPoucoNoMaiorTamanho() throws {
        for conta in ["apple-sem-perfil", "google-sem-perfil"] {
            let app = abrirApp(conta: conta, argumentos: maiorLetra + parado)
            XCTAssertTrue(app.elemento("textoFaltaPouco").waitForExistence(timeout: 10), conta)
            try auditar(app, tiposDeAuditoria)
            rolar(app)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    /// O exemplo de cada campo vazio cabe inteiro na caixa no maior tamanho, quebrando linha como no mockup
    /// ("nada corta"; D6 da conferência da Tarefa 10). A auditoria de texto cortado não vê o exemplo (o prompt)
    /// de um campo: o exemplo é medido aqui na letra do corpo e na largura do campo. A caixa não é elemento de
    /// acessibilidade (como contêiner, ela devolvia ao VoiceOver o exemplo desenhado): é medida no print.
    @MainActor func testExemploDosCamposCabeNoMaiorTamanho() throws {
        let corpo = UIFont.preferredFont(forTextStyle: .body,
                                         compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        func conferir(_ app: XCUIApplication, _ ids: [String]) throws {
            for id in ids {
                let campo = app.textFields[id].exists ? app.textFields[id] : app.secureTextFields[id]
                XCTAssertTrue(campo.waitForExistence(timeout: 5), "campo \(id)")
                let exemplo = try XCTUnwrap(campo.placeholderValue, "exemplo do campo \(id)")
                XCTAssertFalse(app.staticTexts[exemplo].exists, "\(id): o exemplo desenhado fica fora do VoiceOver (quem lê é o prompt do campo)")
                let altura = (exemplo as NSString).boundingRect(with: CGSize(width: campo.frame.width, height: .greatestFiniteMagnitude),
                                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                attributes: [.font: corpo], context: nil).height
                trazerAoMeio(app, campo, altura: altura)
                let caixa = alturaDaCaixa(app, campo)
                XCTAssertGreaterThanOrEqual(caixa, altura.rounded(.down),
                                            "\(id): \"\(exemplo)\" pede \(Int(altura)) pt e a caixa tem \(Int(caixa))")
            }
        }
        let app = abrirApp(argumentos: maiorLetra + parado)
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        try conferir(app, ["email", "senha"])
        let segmento = app.buttons["irParaCriarConta"]
        for _ in 0..<6 where !(segmento.exists && segmento.isHittable) { app.swipeUp() }
        segmento.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 10))
        try conferir(app, ["nome", "sobrenome", "emailCadastro", "senhaCadastro", "confirmacao"])
    }

    /// Rola a tela, arrastando por uma margem, até o campo e a altura que o exemplo pede ficarem fora do véu do
    /// alto (a borda de rolagem) e do indicador de início.
    @MainActor private func trazerAoMeio(_ app: XCUIApplication, _ campo: XCUIElement, altura: CGFloat) {
        let tela = app.frame.height
        let faixa = (borda + 20)...max(borda + 20, tela - 60 - altura)
        for _ in 0..<6 where !faixa.contains(campo.frame.minY) {
            let passo = max(-tela / 2, min(tela / 2, (faixa.lowerBound + faixa.upperBound) / 2 - campo.frame.minY))
            let inicio = app.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: passo > 0 ? 0.3 : 0.7))
            inicio.press(forDuration: 0.1, thenDragTo: inicio.withOffset(CGVector(dx: 0, dy: passo)),
                         withVelocity: .slow, thenHoldForDuration: 0.3)
        }
    }

    /// Altura da caixa do campo no print: a cor sólida do campo numa coluna da margem esquerda da caixa (antes do
    /// texto), do alto do campo para cima e para baixo até as bordas, mais a borda de 1 pt de cada lado.
    @MainActor private func alturaDaCaixa(_ app: XCUIApplication, _ campo: XCUIElement) -> CGFloat {
        let print = Retrato(app.screenshot().image.cgImage!)
        let escala = CGFloat(print.largura) / app.frame.width
        let x = Int((campo.frame.minX - 6) * escala), inicio = Int((campo.frame.minY + 1) * escala)
        func cor(_ y: Int) -> [Int] { (0..<3).map { Int(print.rgba[(y * print.largura + x) * 4 + $0]) } }
        let corDoCampo = cor(inicio)
        func ehCampo(_ y: Int) -> Bool { zip(cor(y), corDoCampo).allSatisfy { abs($0 - $1) <= 4 } }
        var cima = inicio, baixo = inicio
        while cima > 0, ehCampo(cima - 1) { cima -= 1 }
        while baixo + 1 < print.altura, ehCampo(baixo + 1) { baixo += 1 }
        return CGFloat(baixo - cima + 1) / escala + 2
    }

    /// Obras (com o aviso de e-mail, antes e depois de rolar) e entrar.
    @MainActor private func contraste(_ argumentos: [String]) throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: argumentos)
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        try auditar(app, [.contrast])
        rolar(app)
        try auditar(app, [.contrast])
        app.terminate()
        let entrar = abrirApp(argumentos: argumentos)
        XCTAssertTrue(entrar.textFields["email"].waitForExistence(timeout: 10))
        try auditar(entrar, [.contrast])
        entrar.terminate()
    }

    @MainActor func testContrasteNosQuatroCombos() throws {
        for (tema, pele) in quatroCombos {
            try contraste(["-custta.tema", tema, "-custta.pele", pele] + solido + parado)
        }
    }

    /// A tela da obra (etapa 2), no topo e com a lista rolada, nos quatro combos, com superfícies sólidas.
    @MainActor func testContrasteDaObraNosQuatroCombos() throws {
        for (tema, pele) in quatroCombos {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.tema", tema, "-custta.pele", pele] + solido + parado)
            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            rolar(app)
            try auditar(app, [.contrast])
            app.terminate()
        }
    }

    /// A deriva move os brilhos da aurora: o título e a dica da entrada são medidos também com a aurora
    /// congelada nos quadros de 13 s e 26 s (os extremos da deriva), no escuro, onde ela é mais clara.
    @MainActor func testContrasteDoTituloComAAuroraEmMovimento() throws {
        for pele in ["esmeralda", "azul"] {
            for quadro in ["13", "26"] {
                let app = abrirApp(argumentos: ["-custta.pele", pele, "-custta.quadroDaAurora", quadro] + solido + parado)
                XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
                try auditar(app, [.contrast])
                app.terminate()
            }
        }
    }

    /// Na maior letra o layout muda e o texto cai em outra parte da aurora: as cores de novo, com sólido.
    @MainActor func testContrasteNaMaiorLetra() throws {
        for (tema, pele) in [("escuro", "esmeralda"), ("claro", "azul")] {
            try contraste(["-custta.tema", tema, "-custta.pele", pele] + maiorLetra + solido + parado)
        }
    }
}
