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
/// A máquina das auditorias: os argumentos, o que fica de fora e a rolagem. Adota quem audita: o AuditoriaUITests e a
/// auditoria de cada área que mora em arquivo próprio (a da análise, em CusttaUITests/Analise).
protocol AuditoriaDeTela: XCTestCase {}

extension AuditoriaDeTela {
    var maiorLetra: [String] { ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
    var tiposDeAuditoria: XCUIAccessibilityAuditType { [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion] }
    /// Fundo parado: aurora no quadro inicial, globo no ângulo de partida, logo pronto.
    var parado: [String] { ["-custta.reduzirMovimento", "YES"] }
    var solido: [String] { ["-custta.reduzirTransparencia", "YES"] }
    var temas: [String] { ["escuro", "claro"] }
    /// A borda de rolagem (`BordaDeRolagem`): o véu do fundo cobre 140 pt no alto, depois de rolar, e embaixo,
    /// nas telas com a cápsula de abas (88% e 80% com "Reduzir transparência").
    var borda: CGFloat { 140 }

    /// Deixa fora o que não cresce de propósito (dinâmico: a cápsula de abas e o texto do botão do Google,
    /// pelo rótulo, porque a auditoria rola a tela sozinha) e o conteúdo que passa por baixo da barra de
    /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
    /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste. Com `corteSemElemento`, deixa passar
    /// também o "Text clipped" sem elemento, e só ele: o ponto cego do ViewThatFits na maior letra (T34), nas cenas com um à vista.
    /// Com `soEm`, só contam os achados nos elementos cujo identificador começa por ele (as pílulas das ações da fase,
    /// `acao-`): os outros, e os sem elemento, vão para o log e não reprovam.
    @MainActor func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
                            corteSemElemento: Bool = false, soEm: String? = nil) throws {
        // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
        let folha = app.elemento("tituloDaFolha").exists
        let abas = folha ? [] : (app.abasDaCapsula + [app.buttons["botaoMais"]]).filter(\.exists).map(\.frame)
        let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
        // Com a folha aberta, a barra é a da folha, e não a da tela por trás dela (a primeira da árvore); e a folha não tem a
        // borda de rolagem das telas: o conteúdo dela começa onde a barra acaba.
        let barra = folha ? app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch : app.navigationBars.firstMatch
        let topoDoConteudo = barra.exists ? (folha ? barra.frame.maxY : max(barra.frame.maxY, borda)) : 0
        let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        // Com as teclas encaixadas abertas (folha do orçamento), a lista termina onde a faixa delas começa: o que a lista tem
        // embaixo da faixa está escondido (montado pela lista preguiçosa, mas fora da vista). As teclas e a barra entram.
        // As teclas do preço do "Vale a pena?" (etapa 4) cobrem a tela da aba do mesmo jeito.
        let teclas = app.elemento(app.elemento("teclasDoPreco").exists ? "teclasDoPreco" : "tecladoEncaixado")
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
        // Em duas leituras (SegundaLeituraDaAuditoria): reprova o achado que se repete na mesma cena.
        try auditarEmDuasLeituras(app, tipos) { achado in
            if let soEm, achado.element?.identifier.hasPrefix(soEm) != true {
                Swift.print("auditoria | \(achado.compactDescription) | \(achado.element?.identifier ?? "sem elemento") | fora de \(soEm)")
                return true
            }
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
            // O título pequeno da obra em SF Mono (etapa 4): numa linha só, até 236 pt, ele corta o nome comprido com reticências,
            // como o título pequeno do sistema, em vez de empurrar o voltar e o lápis; na maior letra (20 pt), "Sobrado Granja
            // Viana" passa dos 236. O nome inteiro está no título grande, no VoiceOver e no Visualizador de Conteúdo Grande.
            case .textClipped where elemento.identifier == "tituloPequenoDaBarra":
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
                    || elemento.identifier.hasPrefix("barraDasTeclas-") || elemento.identifier.hasPrefix("teclasDoPreco-")
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
    @MainActor func rolar(_ app: XCUIApplication) {
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.5)
    }
}

final class AuditoriaUITests: XCTestCase, AuditoriaDeTela {
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

    /// A obra (a v1) na maior letra, no topo. Rolada, não: a obra é uma List, e a auditoria troca a letra (padrão e maior) em
    /// volta de cada auditoria, no iOS 26 e no 27. A List se mede de novo durante a troca, e textos do bloco A pagar ("3
    /// vencimentos", "Parcelas e gastos futuros") saíam como cortados, com a tela mostrando os dois inteiros (problema
    /// conhecido, 03/11; a LazyVStack também não era firme nesse teste no iOS 27, 1 de 2). Abaixo da dobra, a auditoria na
    /// maior letra fica assim: o A pagar na testAPagarNoMaiorTamanho; a v2 a 800 e no fim e a v3 no fim na
    /// testParte3DaObraNoMaiorTamanho; as peças da vitrine no alto dela e numa tela rolada na testVitrineDasPecasNoMaiorTamanho. As
    /// ações, os afazeres, a pílula e o A vencer da v1 rolada ficam sem auditoria na maior letra (problema conhecido).
    @MainActor func testObraNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
    }

    /// As ações da fase na maior letra (achado 9 do marco 1): o "Desfazer venda" da obra vendida e o "Registrar venda" com o
    /// "Voltar pra construção" da pronta, que a auditoria da parte 3 deixou de alcançar com a obra em blocos. Numa obra de
    /// lista longa (a Casa Alphaville dos falsos da análise, com 46 gastos: a1, vendida, e a9, pronta), numa rolagem fixa com
    /// as pílulas à vista: com conteúdo de sobra embaixo, a rolagem não passa do fim nos tamanhos menores que a auditoria
    /// experimenta. Só contam os achados nas pílulas (`acao-`): os blocos em volta têm a auditoria deles no alto e no fim da
    /// obra, e a troca de letra da auditoria dá neles achados que a tela parada não tem (problema conhecido, 03/11).
    @MainActor func testAcoesDaFaseNoMaiorTamanho() throws {
        for (obra, rolagem, acoes) in [("a1", Self.rolagemDasAcoesDaVendida, ["desfazerVenda"]),
                                       ("a9", Self.rolagemDasAcoesDaPronta, ["registrarVenda", "voltarConstrucao"])] {
            let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:\(obra)",
                               argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            // As pílulas inteiras à vista, abaixo da borda de cima e acima da cápsula: é nelas que a auditoria conta.
            let capsula = app.buttons["aba-obras"].frame
            for acao in acoes {
                let pilula = app.buttons["acao-\(acao)"]
                XCTAssertTrue(pilula.waitForExistence(timeout: 5) && pilula.frame.minY >= borda && pilula.frame.maxY <= capsula.minY,
                              "\(obra): a pílula \(acao) à vista (\(pilula.frame); de \(borda) a \(capsula.minY))")
                // A pílula cresce com a letra. Com fonte fixa no rótulo, o achado de tipo dinâmico vem sem elemento e o `soEm`
                // só o registra no log, onde o vaivém da letra do iOS 26 já põe 6 deles com a tela parada: a altura pega.
                XCTAssertGreaterThanOrEqual(pilula.frame.height, Self.pilulaNaMaiorLetra,
                                            "\(obra): a pílula \(acao) cresce com a letra (\(pilula.frame))")
            }
            try auditar(app, tiposDeAuditoria, soEm: "acao-")
            app.terminate()
        }
    }
    // Na maior letra, cada pílula tem 149 pt e fica entre a borda (140 pt) e a cápsula (876 no Pro Max). Medidas a 3050 e
    // 2500: o "Desfazer venda" começava em 245 no 18 Pro e em -13 no Pro Max; o "Registrar venda", em 260 e em 1, com o
    // "Voltar pra construção" 159 pt abaixo. As rolagens ficam no meio do vão comum aos dois: o "Desfazer venda" em 525 e
    // em 267; o "Registrar venda" em 440 e em 181, e o "Voltar pra construção" termina em 748 e em 489.
    private static let rolagemDasAcoesDaVendida = 2770
    private static let rolagemDasAcoesDaPronta = 2320
    // A pílula na maior letra, com o rótulo em duas linhas: 149,3 pt no 18 Pro, no Pro Max e no 17 Pro do iOS 26.5.
    private static let pilulaNaMaiorLetra: CGFloat = 145

    /// O bloco A pagar da obra na maior letra, inteiro: a etiqueta dos vencimentos e a nota "Parcelas e gastos futuros". Na
    /// obra, ele fica abaixo da dobra, e a auditoria olha só o topo; rolado, numa List ou numa ScrollView, a troca de letra
    /// da auditoria tira a rolagem do lugar (na vitrine, as rolagens de 900 a 3600 caíam todas na mesma tela). Aqui ele vem
    /// no alto da vitrine das peças (`-custta.vitrineAPagar`) e é auditado sem rolar.
    @MainActor func testAPagarNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas",
                           argumentos: maiorLetra + parado + ["-custta.vitrineAPagar", "YES"])
        XCTAssertTrue(app.elemento("vitrine-aPagar").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.5)
        try auditar(app, [.dynamicType, .textClipped])
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

    /// As telas da etapa 2, parte 3, na maior letra: a obra pronta e a vendida em rolagens fixas, a lista vazia, as folhas
    /// da obra (nova e editar), a da venda e a do gasto lançado de dentro de uma vendida. Na obra, rolagem fixa e não o
    /// arrasto: logo depois do arrasto, a auditoria marcava "Text clipped" nos indicadores da v2, que parados não cortam
    /// (triagem em 0, 400 e 800 pt, na v1 e na v2). A vendida fica sem os 800 pt: no iOS 26, os blocos de lá davam sete
    /// achados sem elemento enquanto a auditoria trocava o tamanho da letra (CI, 17/10; no Mac passam).
    /// Com a obra em blocos (etapa 4), mais alta, a v2 a 800 cai no Corrigido e no A pagar (18 Pro). No meio da obra não dá:
    /// a auditoria troca o tamanho da letra, nos menores o conteúdo fica mais curto que a rolagem fixa, a lista salta, e os
    /// blocos que estavam à vista saíam da janela da LazyVStack de antes. A auditoria acusa "Dynamic Type font sizes are unsupported"
    /// sem elemento, com o texto crescendo a cada passo de letra (sonda de 02/11, iOS 27: a v2 e a v3 a 1600 com os blocos
    /// soltos, e a v3 a 2000 também com o VStack de antes; a v2 a 1850 já dava o mesmo). Por isso a v2 e a
    /// v3 ficam no topo e no fim (99999, que a rolagem fixa leva ao fim em toda letra), onde a janela fica nas mesmas peças.
    /// As peças do meio (blocos, número mono, cabeçalhos) seguem na maior letra na testVitrineDasPecasNoMaiorTamanho, no alto
    /// dela e numa tela rolada. Prova no PR #99. Na List (03/11), a rolagem fixa é o gancho da List (RolagemFixaDaLista): anda
    /// até a rolagem pedida, presa ao fim do conteúdo que ela mede, e segura a linha do alto; no fim (99999), antes de
    /// auditar, o teste confere que a última linha de gasto (a mais antiga, g0) está à vista, e não o vazio. A parte 3 vem em
    /// três testes (a obra; a lista vazia e as folhas da obra; as folhas da venda), mais curtos que o de antes, de 14 auditorias:
    /// uma cena que cai não esconde as outras.
    @MainActor func testParte3DaObraNoMaiorTamanho() throws {
        for (obra, rolagem) in [("v2", 0), ("v2", 800), ("v2", 99_999), ("v3", 0), ("v3", 99_999)] {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:\(obra)",
                               argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            if rolagem == 99_999 {
                let ultima = app.elemento("gasto-\(obra)g0")
                XCTAssertTrue(ultima.waitForExistence(timeout: 5) && app.frame.intersects(ultima.frame),
                              "\(obra) no fim: a última linha de gasto à vista, \(ultima.frame)")
            }
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    @MainActor func testParte3DasFolhasDaObraNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha", dados: "vazio", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        app.terminate()
        try auditarFolhasDaParte3([("novaObra", "nomeDaObra", nil), ("editarObra:v1", "apagarObra", "obra:v1")])
    }

    @MainActor func testParte3DaVendaNoMaiorTamanho() throws {
        try auditarFolhasDaParte3([("venda:v2", "confirmarVenda", "obra:v2"), ("gastoDeVendida:v3", "linhaObra", "obra:v3")])
    }

    /// Cada folha no alto e rolada.
    @MainActor private func auditarFolhasDaParte3(_ folhas: [(String, String, String?)]) throws {
        for (folha, espera, abrir) in folhas {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
                               argumentos: maiorLetra + parado + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), folha)
            try auditar(app, tiposDeAuditoria)
            app.swipeUp()
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, tiposDeAuditoria)
            app.terminate()
        }
    }

    /// O gancho da rolagem fixa da obra (RolagemFixaDaLista) põe duas vistas vazias na lista. A âncora, no fundo da 1ª linha,
    /// sempre apareceu na árvore de acessibilidade, como um elemento de tamanho zero. A que ajusta a rolagem depois do passe de
    /// layout da lista não pode aparecer: a árvore é o que o laudo e a auditoria leem. A obra aberta com `-custta.rolagem 0` (o
    /// gancho segura a lista no alto, onde ela já está) tem a lista da obra aberta sem o argumento, elemento por elemento e na
    /// mesma ordem, mais a âncora, e só ela.
    @MainActor func testOGanchoDaRolagemSoPoeAAncoraNaListaDaObra() throws {
        struct Elemento: Equatable {
            let texto: String
            let vazio: Bool
        }
        func lista(_ argumentos: [String]) throws -> [Elemento] {
            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", argumentos: parado + argumentos)
            defer { app.terminate() }
            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            var elementos: [Elemento] = []
            func descer(_ no: XCUIElementSnapshot, _ nivel: Int) {
                elementos.append(Elemento(texto: "\(nivel) \(no.elementType.rawValue) \"\(no.label)\" \(no.identifier) \(no.frame)",
                                          vazio: no.elementType == .other && no.label.isEmpty && no.identifier.isEmpty && no.frame.size == .zero))
                no.children.forEach { descer($0, nivel + 1) }
            }
            descer(try app.collectionViews.firstMatch.snapshot(), 0)
            return elementos
        }
        let semOGancho = try lista([]), comOGancho = try lista(["-custta.rolagem", "0"])
        // O que o gancho pôs: o que sobra da lista com ele, tirando na ordem os elementos da lista sem ele.
        var postos: [Elemento] = [], falta = semOGancho[...]
        for elemento in comOGancho {
            if elemento == falta.first { falta = falta.dropFirst() } else { postos.append(elemento) }
        }
        Swift.print("gancho da rolagem | a lista da obra: \(semOGancho.count) elementos sem o gancho, \(comOGancho.count) com ele | "
                    + "postos pelo gancho: \(postos.map(\.texto))")
        XCTAssertGreaterThan(semOGancho.count, 20, "a lista da obra com as linhas dela")
        XCTAssertTrue(falta.isEmpty, "com o gancho, a lista tem os elementos de sem ele, na mesma ordem: faltaram \(falta.map(\.texto))")
        XCTAssertEqual(postos.count, 1, "o gancho só põe a âncora na árvore: \(postos.map(\.texto))")
        XCTAssertTrue(postos.allSatisfy(\.vazio), "a âncora é um elemento vazio, de tamanho zero: \(postos.map(\.texto))")
    }

    /// As mesmas telas no escuro e no claro, com superfícies sólidas. Cada cena espera até 60 s: na CI do fc47363 (run
    /// 45838128547), as consultas do XCUITest ficaram 54 s sem resposta logo depois de abrir a folha de venda no claro, e a
    /// espera de 10 s venceu com a folha já aberta. Quando a cena vem, a espera sai em 1 ou 2 s.
    @MainActor func testContrasteDaParte3NosDoisTemas() throws {
        let cena: TimeInterval = 60
        for tema in temas {
            let combo = ["-custta.tema", tema] + solido + parado
            var app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", argumentos: combo + ["-custta.rolagem", "250"])
            XCTAssertTrue(app.buttons["acao-voltarConstrucao"].waitForExistence(timeout: cena))
            Thread.sleep(forTimeInterval: 1)
            try auditar(app, [.contrast])
            app.terminate()
            app = abrirApp(conta: "senha", dados: "vazio", argumentos: combo)
            XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: cena))
            try auditar(app, [.contrast])
            app.terminate()
            for (folha, espera, abrir) in [("novaObra", "nomeDaObra", nil), ("venda:v2", "confirmarVenda", "obra:v2")] {
                app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
                               argumentos: combo + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: cena), folha)
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
    ///
    /// A linha na obra fica a 700 pt, e a obra é uma List: rolada, ela se mede de novo enquanto a auditoria troca a letra
    /// (testObraNoMaiorTamanho). No iOS 26 da CI, a auditoria de tipo dinâmico lia os quatro textos da linha antes de a lista
    /// refazer o layout de um dos tamanhos e acusava "partially unsupported" em perto de metade das leituras, com o gancho da
    /// rolagem de antes ou com o de agora, e em 1 de 4 dessas também na segunda leitura (sondas de 26/11, 9 iterações por run).
    /// Por isso o tipo dinâmico (e o corte) da linha são auditados com ela no alto da vitrine das peças, sem rolar, como o A
    /// pagar (`-custta.vitrineOrcamento`); na obra a 700 pt ficam os outros tipos.
    @MainActor func testOrcamentoNoMaiorTamanho() throws {
        var app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas", argumentos: maiorLetra + parado + ["-custta.vitrineOrcamento", "YES"])
        XCTAssertTrue(app.elemento("indicadorOrcamento").waitForExistence(timeout: 10), "a linha do orçamento no alto da vitrine")
        Thread.sleep(forTimeInterval: 1.5)
        try auditar(app, [.dynamicType, .textClipped])
        app.terminate()
        for (dados, abrir, rolagem, espera) in [("porTopico", "obra:v1", 700, "editarObra"), ("porTopico", "orcamento:v1", 0, "editarOrcamento"),
                                                ("porTopico", "orcamento:v1", 3000, "editarOrcamento"),
                                                ("vitrine", "orcamento:v1", 2200, "editarOrcamento")] {
            app = abrirApp(conta: "senha", dados: dados, abrir: abrir, argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
            XCTAssertTrue(app.buttons[espera].waitForExistence(timeout: 10), "\(abrir) em \(rolagem)")
            Thread.sleep(forTimeInterval: 1.5)
            try auditar(app, abrir == "obra:v1" ? tiposDeAuditoria.subtracting(.dynamicType) : tiposDeAuditoria)
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
            // As teclas no primeiro tópico, com a lista no alto. Com um tópico do meio em foco (era a Elétrica), no iPhone 18 Pro
            // Max (iOS 27) a auditoria de contraste desta cena não termina: "Audit failed to complete in time" (-56) nas duas
            // tentativas, sempre, com o app parado a 0% de CPU. Quem trava é a detecção de contraste no testmanagerd do
            // simulador, que fica com uma thread a 100% por auditoria estourada e atrasa as rodadas seguintes, até o simulador ser
            // desligado. Medido em 26/11: com a Elétrica, a Cerâmica ou a Mão de obra em foco, a lista monta linhas acima do topo
            // da tela e a auditoria estoura (3 de 3); com o Terreno, não monta e passa em 0,7 s; no 18 Pro, passa com os quatro.
            // O que exatamente a faz travar não foi isolado: outras cenas têm texto acima do topo da tela e passam.
            app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: combo + ["-custta.folha", "teclas:terreno"])
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
    /// guarda Node; as edições ficam sem a tolerância. Roda no job laudo-etapa3-b.
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
                // No detalhe, o "No orçamento" rola para cima da barra, mas segue montado, e o ponto cego dele vai junto conforme
                // onde a rolagem para: no iPhone 18 Pro (o bloco de -214 a 64 pt) a auditoria não acha nada; no 18 Pro Max (de
                // -187 a 91 pt, a rolagem acaba antes) acha os mesmos dois "Text clipped" sem elemento do topo.
                let noOrcamentoMontado = app.elemento("orcamentoDoTopico").exists
                try auditar(app, tiposDeAuditoria, corteSemElemento: folha.hasPrefix("aPagar") || noOrcamentoMontado)
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
