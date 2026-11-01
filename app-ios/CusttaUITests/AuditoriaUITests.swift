import XCTest
import UIKit

/* Requisitos verificáveis do spec, seção 8, com a cara do PWA: no maior tamanho de letra de
   acessibilidade nada corta, todo controle tem rótulo e alvo de 44 pt; o contraste das cores passa nos
   dois temas e sobre a aurora parada (no quadro inicial e nos extremos da deriva). Não crescem com a
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
    private let temas = ["escuro", "claro"]
    /// A borda de rolagem (`BordaDeRolagem`): o véu do fundo cobre 140 pt no alto, depois de rolar, e embaixo,
    /// nas telas com a cápsula de abas (88% e 80% com "Reduzir transparência").
    private let borda: CGFloat = 140

    /// Deixa fora o que não cresce de propósito (dinâmico: a cápsula de abas e o texto do botão do Google,
    /// pelo rótulo, porque a auditoria rola a tela sozinha) e o conteúdo que passa por baixo da barra de
    /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
    /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste. Com `corteSemElemento`, deixa passar
    /// também o "Text clipped" sem elemento, e só ele: o ponto cego do ViewThatFits na maior letra (T34), nas cenas com um à vista.
    @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
                                    corteSemElemento: Bool = false) throws {
        // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
        let folha = app.elemento("tituloDaFolha").exists
        let abas = folha ? [] : ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
        let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
        // Com a folha aberta, a barra é a da folha, e não a da tela por trás dela (a primeira da árvore); e a folha não tem a
        // borda de rolagem das telas: o conteúdo dela começa onde a barra acaba.
        let barra = folha ? app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch : app.navigationBars.firstMatch
        let topoDoConteudo = barra.exists ? (folha ? barra.frame.maxY : max(barra.frame.maxY, borda)) : 0
        let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        // Com as teclas encaixadas abertas (folha do orçamento), a lista termina onde a faixa delas começa: o que a lista tem
        // embaixo da faixa está escondido (montado pela lista preguiçosa, mas fora da vista). As teclas e a barra entram.
        let teclas = app.elemento("tecladoEncaixado")
        let topoDasTeclas = teclas.exists ? teclas.frame.minY : .infinity
        let dasTeclas = teclas.exists ? teclas.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        // E começa embaixo do cabeçalho fixo da folha (o segmentado e o total): o que a lista tem em cima dele foi rolado para
        // fora da vista. No 18 Pro essas linhas ficam sob a barra; no Pro Max, com a faixa mais alta, entre a barra e o total.
        let lista = app.elemento("listaDoOrcamento")
        let topoDaLista = lista.exists ? lista.frame.minY : -.infinity
        let daLista = lista.exists ? lista.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        // O total ao vivo da folha do orçamento ("Total", a soma e "N de M tópicos com valor") muda de lugar na fronteira da
        // letra de acessibilidade: nela, rola dentro da lista; abaixo dela, fica fixo em cima da lista. No iOS 26, a auditoria
        // acha "partially unsupported" e "Text clipped" nos três, com o print da CI mostrando os três grandes e inteiros. Lá,
        // a letra vai e volta em cada auditoria: a padrão enquanto este auditar lê os quadros, a AX5 dentro dela. O quadro do
        // total lido aqui não é onde ela acha os textos (run 39710458060, depois do swipe): a exceção é pelo identificador
        // de cada texto, como as outras. Só ali, só na letra de acessibilidade e só no iOS 26; a prova de que crescem e não
        // cortam é o OrcamentoUITests.testNaMaiorLetraOTotalCresceSemCortar.
        let totalMudaDeLugar = app.launchArguments.contains { $0.hasPrefix("UICTContentSizeCategoryAccessibility") }
            && !ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0))
        try app.performAccessibilityAudit(for: tipos) { achado in
            guard let elemento = achado.element else {
                // O arranjo que o ViewThatFits descartou dá "Text clipped" sem elemento, com a tela mostrando o outro inteiro.
                // Qualquer outro achado sem elemento reprova, também nessas cenas.
                let pontoCego = corteSemElemento && achado.auditType == .textClipped
                Swift.print("auditoria | \(achado.compactDescription) | sem elemento | "
                            + (pontoCego ? "ponto cego do ViewThatFits" : "reprova"))
                return pontoCego
            }
            let fora: Bool
            let noTotal = totalMudaDeLugar && elemento.identifier.hasPrefix("totalDoOrcamento-")
            switch achado.auditType {
            case .dynamicType where noTotal && achado.compactDescription.contains("partially"), .textClipped where noTotal:
                fora = true
            case .dynamicType:
                // Os títulos das barras param perto de 22 pt, como os do sistema (mockup da etapa 2), com o Visualizador de
                // Conteúdo Grande: o pequeno da obra e o das folhas (na maior letra o nome da obra sai da barra da folha e
                // fica no valor do título, para o VoiceOver). Pelo identificador, e não pela barra inteira: o que passa por
                // baixo dela continua na auditoria de tipo dinâmico. Na folha do gasto, as teclas e o "Apagar" do arrastar
                // param no AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber. Na
                // folha do orçamento (etapa 3), a barra das teclas encaixadas para no xxxLarge, como o título da folha.
                let centro = CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)
                fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                    || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
                    || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
                    || elemento.identifier.hasPrefix("barraDasTeclas-")
                    || abas.contains { $0.contains(centro) }
            case .contrast:
                if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
                // O travessão da venda sem estimativa: um traço de 3 pt que a auditoria não consegue medir (como o "·"
                // solto da linha de gasto); está no secundário do vidro, a cor da nota logo abaixo, que passa na mesma
                // superfície, e o laudo de leitura mede o pixel dele.
                else if elemento.label == "—" { fora = true }
                else {
                    let sobABarra = elemento.frame.minY < topoDoConteudo && !daBarra.contains(elemento.frame)
                    let sobAsTeclas = elemento.frame.maxY > topoDasTeclas + 0.5 && !dasTeclas.contains(elemento.frame)
                    let acimaDaLista = elemento.frame.minY < topoDaLista - 0.5 && daLista.contains(elemento.frame)
                    fora = sobABarra || sobAsTeclas || acimaDaLista || elemento.frame.maxY > fundoDaTela
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

    /// A vitrine das peças da identidade nova (etapa 4, PR 1b; só no Debug, com CUSTTA_ABRIR=pecas) na maior letra, em
    /// rolagens fixas (como a obra: logo depois de um arrasto, a auditoria acha corte que parado não há): o título e a cápsula
    /// de metadados, os blocos, o número mono, a barra de tópicos e a linha mono crescem com a letra e nada corta, e os alvos
    /// têm 44 pt, antes de a obra (PR 1c) usá-los. O título pequeno da barra é o da obra (`tituloPequenoDaBarra`), que para
    /// perto de 20 pt. Sem a descrição suficiente: na vitrine, o número fica solto, sem o rótulo do bloco, e a auditoria acha
    /// "Label not human-readable" num elemento só de algarismos, com ou sem o mono; na obra, o rótulo e o número do bloco são
    /// um elemento, como os indicadores da etapa 3.
    @MainActor func testVitrineDasPecasNoMaiorTamanho() throws {
        for rolagem in [0, 900, 1800, 2700, 3600] {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas",
                               argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.elemento("vitrine-solido").waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, [.dynamicType, .textClipped, .hitRegion])
            app.terminate()
        }
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

    /// A folha do gasto (valor e cartão) e a linha aberta com o "Apagar", no escuro e no claro, com superfícies sólidas.
    /// A linha aberta em 758 pt (640 até a etapa 2, antes da linha do orçamento da vitrine, de 118 pt).
    @MainActor func testContrasteDaFolhaNosDoisTemas() throws {
        for tema in temas {
            let combo = ["-custta.tema", tema] + solido + parado
            for (passo, espera) in [("valor", "visorDoValor"), ("cartao", "resumoDoCartao")] {
                let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: combo + ["-custta.folha", passo])
                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
                try auditar(app, [.contrast])
                app.terminate()
            }
            let lista = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
                                 argumentos: combo + ["-custta.rolagem", "758", "-custta.linhaAberta", "g027"])
            XCTAssertTrue(lista.buttons["apagar-g027"].waitForExistence(timeout: 10))
            try auditar(lista, [.contrast])
            lista.terminate()
        }
    }

    /// Ajustes na maior letra: a Aparência no alto (as opções do vidro uma embaixo da outra, com o círculo em cima do
    /// nome) e, rolada, a Conta; também com "Aumentar contraste" e com "Reduzir transparência", que trocam a nota pelo aviso.
    @MainActor func testAjustesNoMaiorTamanho() throws {
        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
            let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado + opcao)
            app.abrirAba("ajustes")
            XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
            try auditar(app, tiposDeAuditoria)
            rolar(app)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    /// Ajustes com superfícies sólidas, no escuro e no claro. Com "Reduzir transparência" as duas doses viram a mesma
    /// superfície sólida, e as opções do vidro ficam esmaecidas e desligadas, com o aviso que diz por quê.
    @MainActor func testContrasteDeAjustesNosDoisTemas() throws {
        for tema in temas {
            let app = abrirApp(conta: "senha", argumentos: ["-custta.tema", tema] + solido + parado)
            app.abrirAba("ajustes")
            XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
            try auditar(app, [.contrast])
            rolar(app)
            try auditar(app, [.contrast])
            app.terminate()
        }
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

    @MainActor func testContrasteNosDoisTemas() throws {
        for tema in temas {
            try contraste(["-custta.tema", tema] + solido + parado)
        }
    }

    /// A tela da obra (etapa 2), no topo e com a lista rolada, no escuro e no claro, com superfícies sólidas.
    @MainActor func testContrasteDaObraNosDoisTemas() throws {
        for tema in temas {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.tema", tema] + solido + parado)
            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            rolar(app)
            try auditar(app, [.contrast])
            app.terminate()
        }
    }

    /// As telas da etapa 2, parte 3, na maior letra: a obra pronta (com as duas ações da fase, a sólida e a de vidro)
    /// e a vendida (a venda com o lucro e o "Desfazer venda") em rolagens fixas, a lista vazia, as folhas da obra (nova
    /// e editar), a da venda e a do gasto lançado de dentro de uma vendida. Na obra, rolagem fixa e não o arrasto:
    /// logo depois do arrasto, a auditoria marcava "Text clipped" nos indicadores da v2, que parados não cortam (triagem em
    /// 0, 400 e 800 pt, na v1 e na v2). A vendida fica sem os 800 pt: ali estão os indicadores, os mesmos da v2 a 800, e no
    /// iOS 26 eles davam sete achados sem elemento enquanto a auditoria trocava o tamanho da letra (CI, 17/10; no Mac passam).
    @MainActor func testParte3NoMaiorTamanho() throws {
        var app: XCUIApplication
        for (obra, rolagem) in [("v2", 0), ("v2", 800), ("v2", 1600), ("v3", 0), ("v3", 1600)] {
            app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:\(obra)",
                           argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
        app = abrirApp(conta: "senha", dados: "vazio", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        app.terminate()
        for (folha, espera, abrir) in [("novaObra", "nomeDaObra", nil), ("editarObra:v1", "apagarObra", "obra:v1"),
                                       ("venda:v2", "confirmarVenda", "obra:v2"),
                                       ("gastoDeVendida:v3", "linhaObra", "obra:v3")] {
            app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
                           argumentos: maiorLetra + parado + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), folha)
            try auditar(app, tiposDeAuditoria)
            app.swipeUp()
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    /// As mesmas telas no escuro e no claro, com superfícies sólidas.
    @MainActor func testContrasteDaParte3NosDoisTemas() throws {
        for tema in temas {
            let combo = ["-custta.tema", tema] + solido + parado
            var app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", argumentos: combo + ["-custta.rolagem", "250"])
            XCTAssertTrue(app.buttons["acao-voltarConstrucao"].waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1)
            try auditar(app, [.contrast])
            app.terminate()
            app = abrirApp(conta: "senha", dados: "vazio", argumentos: combo)
            XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            app.terminate()
            for (folha, espera, abrir) in [("novaObra", "nomeDaObra", nil), ("venda:v2", "confirmarVenda", "obra:v2")] {
                app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
                               argumentos: combo + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), folha)
                Thread.sleep(forTimeInterval: 1)
                try auditar(app, [.contrast])
                app.terminate()
            }
        }
    }

    /// A deriva move os brilhos da aurora: o título e a dica da entrada são medidos também com a aurora
    /// congelada nos quadros de 13 s e 26 s (os extremos da deriva), no escuro, onde ela é mais clara.
    @MainActor func testContrasteDoTituloComAAuroraEmMovimento() throws {
        for quadro in ["13", "26"] {
            let app = abrirApp(argumentos: ["-custta.quadroDaAurora", quadro] + solido + parado)
            XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            app.terminate()
        }
    }

    /// Na maior letra o layout muda e o texto cai em outra parte da aurora: as cores de novo, com sólido.
    @MainActor func testContrasteNaMaiorLetra() throws {
        for tema in temas {
            try contraste(["-custta.tema", tema] + maiorLetra + solido + parado)
        }
    }
}

extension AuditoriaUITests {
    /// O orçamento (etapa 3, PR 1) na maior letra: a linha na obra, a tela Orçamento no alto e rolada (o cartão e os primeiros
    /// tópicos; os tópicos a 3000 pt; no modo total, o gasto por tópico a 2200 pt) e a folha, com as teclas fechadas e abertas,
    /// por tópico e no "Definir". A tela Orçamento sem o meio (1500 pt): ali, enquanto a auditoria trocava o tamanho da letra,
    /// saíam achados sem elemento (como a vendida a 800 pt da etapa 2). E sem o fim do modo total (a 3000 pt e mais): a
    /// auditoria diminui a letra, a lista longa encolhe para cima da rolagem e a tela fica vazia, com o gancho da rolagem fixa ou
    /// sem ele, e os achados saem sem elemento (ponto cego, 21/10); o que só o fim tem, a dica, tem guarda Node. Roda no job
    /// laudo-etapa3.
    @MainActor func testOrcamentoNoMaiorTamanho() throws {
        var app: XCUIApplication
        for (dados, abrir, rolagem, espera) in [("porTopico", "obra:v1", 700, "editarObra"), ("porTopico", "orcamento:v1", 0, "editarOrcamento"),
                                                ("porTopico", "orcamento:v1", 3000, "editarOrcamento"),
                                                ("vitrine", "orcamento:v1", 2200, "editarOrcamento")] {
            app = abrirApp(conta: "senha", dados: dados, abrir: abrir, argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.buttons[espera].waitForExistence(timeout: 10), "\(abrir) em \(rolagem)")
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
        for (dados, abrir, passo, espera) in [("porTopico", "orcamento:v1", "topicos", "linhaOrc-terreno"),
                                              ("porTopico", "orcamento:v1", "teclas:eletrica", "barraDasTeclas-pronto"),
                                              ("semOrcamento", "obra:v1", "", "tecla-1")] {
            app = abrirApp(conta: "senha", dados: dados, abrir: abrir, folha: "orcamento:v1",
                           argumentos: maiorLetra + parado + (passo.isEmpty ? [] : ["-custta.folha", passo]))
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
            Thread.sleep(forTimeInterval: 1)
            try auditar(app, tiposDeAuditoria)
            if passo == "topicos" {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 1.5)
                try auditar(app, tiposDeAuditoria)
            }
            app.terminate()
        }
    }

    /// As mesmas telas no escuro e no claro, com superfícies sólidas.
    @MainActor func testContrasteDoOrcamentoNosDoisTemas() throws {
        for tema in temas {
            let combo = ["-custta.tema", tema] + solido + parado
            var app = abrirApp(conta: "senha", dados: "porTopico", abrir: "obra:v1", argumentos: combo)
            XCTAssertTrue(app.elemento("indicadorOrcamento").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            app.terminate()
            app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", argumentos: combo)
            XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
            try auditar(app, [.contrast])
            rolar(app)
            try auditar(app, [.contrast])
            app.terminate()
            app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: combo + ["-custta.folha", "teclas:eletrica"])
            XCTAssertTrue(app.elemento("barraDasTeclas-nome").waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1)
            try auditar(app, [.contrast])
            app.terminate()
        }
    }

    /// As folhas de origem (etapa 3, PR 2) na maior letra: o A pagar e o detalhe da Cerâmica no topo e depois de um arrasto
    /// (como a folha do orçamento), e a edição empurrada em cada uma (a g039 no A pagar, a g021 no detalhe), com o voltar e o
    /// nome da folha embaixo do título, todas com os quatro tipos. Onde há um ViewThatFits à vista (o cabeçalho do mês, em toda
    /// a lista do A pagar, e o "No orçamento", no topo do detalhe), passa só o "Text clipped" sem elemento (ponto cego, T34): o
    /// arranjo em linha que não coube dá esse achado (dois por cabeçalho no iOS 27, conforme a rolagem), e a tela mostra a
    /// coluna inteira. Com a coluna no lugar do ViewThatFits, nenhum achado; nem identificador nem .contain dão elemento a ele,
    /// então não há exceção por identificador. O corte com elemento segue reprovando nessas cenas: o "3 vencimentos · a partir
    /// de amanhã" numa linha só reprova depois do arrasto (a mutação da T34). O corte dentro do .ignore da linha do gasto tem a
    /// guarda Node; o detalhe rolado e as edições ficam sem a tolerância. Roda no job laudo-etapa3-b.
    @MainActor func testFolhasDeOrigemNoMaiorTamanho() throws {
        for (dados, abrir, folha, edicao, espera) in [("vitrine", "obra:v1", "aPagar:v1", "", "resumoDoAPagar"),
                                                     ("porTopico", "orcamento:v1", "topico:v1:revest", "", "orcamentoDoTopico"),
                                                     ("vitrine", "obra:v1", "aPagar:v1", "g039", "salvarGasto"),
                                                     ("porTopico", "orcamento:v1", "topico:v1:revest", "g021", "salvarGasto")] {
            let app = abrirApp(conta: "senha", dados: dados, abrir: abrir, folha: folha,
                               argumentos: maiorLetra + parado + (edicao.isEmpty ? [] : ["-custta.origem", "editar:\(edicao)"]))
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), "\(folha) \(edicao)")
            Thread.sleep(forTimeInterval: 1)
            try auditar(app, tiposDeAuditoria, corteSemElemento: edicao.isEmpty)
            if edicao.isEmpty {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 1.5)
                try auditar(app, tiposDeAuditoria, corteSemElemento: folha.hasPrefix("aPagar"))
            }
            app.terminate()
        }
    }

    /// As mesmas folhas no escuro e no claro, com superfícies sólidas: o A pagar, a Cerâmica no topo e rolada, a Estrutura (a
    /// frase do "passou" no Alerta) e as duas edições (o "Apagar gasto" no Negativo). Roda no job laudo-etapa3-b.
    @MainActor func testContrasteDasFolhasDeOrigemNosDoisTemas() throws {
        for tema in temas {
            let combo = ["-custta.tema", tema] + solido + parado
            for (dados, abrir, folha, edicao, espera) in [("vitrine", "obra:v1", "aPagar:v1", "", "resumoDoAPagar"),
                                                         ("porTopico", "orcamento:v1", "topico:v1:revest", "", "orcamentoDoTopico"),
                                                         ("porTopico", "orcamento:v1", "topico:v1:estrutura", "", "orcamentoDoTopico"),
                                                         ("vitrine", "obra:v1", "aPagar:v1", "g039", "salvarGasto"),
                                                         ("porTopico", "orcamento:v1", "topico:v1:revest", "g021", "salvarGasto")] {
                let app = abrirApp(conta: "senha", dados: dados, abrir: abrir, folha: folha,
                                   argumentos: combo + (edicao.isEmpty ? [] : ["-custta.origem", "editar:\(edicao)"]))
                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), "\(tema) \(folha) \(edicao)")
                Thread.sleep(forTimeInterval: 1)
                try auditar(app, [.contrast])
                if folha == "topico:v1:revest", edicao.isEmpty {
                    rolar(app)
                    try auditar(app, [.contrast])
                }
                app.terminate()
            }
        }
    }
}
