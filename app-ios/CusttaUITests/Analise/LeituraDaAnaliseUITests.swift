import XCTest

/* O laudo de leitura das telas da análise (etapa 4, marco 2), no arquivo delas: o PR que só mexe na análise roda este
   laudo no job laudo-etapa4, sem o laudo inteiro (spec, "Portões por superfície"). A máquina é a do LeituraNoVidroUITests
   (`LaudoDeLeitura`): cada cena em dois prints, um normal e um com o texto apagado, com o fundo parado no pior caso, e o
   portão de 4,5:1 no pior ponto de cada palavra. */
final class LeituraDaAnaliseUITests: XCTestCase, LaudoDeLeitura {
    /// Uma cena do "Vale a pena?", com os falsos da análise: a Casa Alphaville é a primeira obra elegível, com a venda
    /// estimada em R$ 1.450.000,00 (vale a pena).
    private func cena(_ nome: String, _ argumentos: [String], espera: String = "tituloValeAPena", dados: String = "analise",
                      rolagem: Int? = nil, assunto: [String] = [], toques: (@MainActor (XCUIApplication) -> Void)? = nil) -> Cena {
        Cena(nome: "vale a pena, \(nome)", conta: "senha", argumentos: argumentos + (rolagem.map { ["-custta.rolagem", "\($0)"] } ?? []),
             espera: espera, escopo: "tudo", dados: dados, abrir: "aba:valeAPena", rolada: rolagem != nil, toques: toques,
             assunto: assunto)
    }

    /// Escolhe uma obra na lista "Obra" e espera a lista fechar.
    @MainActor private static func escolherObra(_ app: XCUIApplication, _ nome: String) {
        app.buttons["simObra"].tap()
        let obra = app.buttons[nome].firstMatch
        XCTAssertTrue(obra.waitForExistence(timeout: 10), "a obra \(nome) na lista")
        obra.tap()
        XCTAssertTrue(app.buttons["simObra"].waitForExistence(timeout: 10))
    }

    /// Abre as teclas do preço e digita: cada tecla pelo nome ("8", "00", "del").
    @MainActor private static func digitarOPreco(_ app: XCUIApplication, _ teclas: [String] = [], ok: Bool = false) {
        app.elemento("simPreco").tap()
        XCTAssertTrue(app.buttons["teclasDoPreco-ok"].waitForExistence(timeout: 10), "as teclas do preço")
        for tecla in teclas { app.buttons["tecla-\(tecla)"].tap() }
        if ok {
            app.buttons["teclasDoPreco-ok"].tap()
            XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 10), "o OK devolve a cápsula")
        }
    }

    /// O "Vale a pena?" nos dois temas: os campos e o veredito verde no alto (no Transparente e no Fosco); a faixa com a
    /// legenda e a tabela, roladas; o veredito âmbar ("Rende menos que o banco", a R$ 800.000,00, pelas teclas); e as teclas
    /// do preço abertas no lugar da cápsula, com o valor à vista.
    @MainActor func testLeituraDoValeAPena() {
        var cenas: [Cena] = []
        for tema in temas {
            let combo = ["-custta.tema", tema] + piorMomento
            cenas += [
                cena("\(tema), Transparente", combo, assunto: ["simObra", "simPreco", "simNota"]),
                cena("\(tema), Fosco", combo + ["-custta.vidro", "fosco"], assunto: ["simObra", "simPreco", "simNota"]),
                cena("veredito e faixa, \(tema)", combo, espera: "simFaixa", rolagem: Self.rolagemDaFaixa,
                     assunto: ["simVeredito", "simFaixa", "simFaixa-venda"]),
                cena("tabela, \(tema)", combo, espera: "simTabela-6", rolagem: Self.rolagemDaTabela,
                     assunto: ["simTabela-0", "simTabela-6"]),
                cena("rende menos que o banco, \(tema)", combo, rolagem: Self.rolagemDoVeredito, assunto: ["simVeredito"]) { app in
                    Self.digitarOPreco(app, ["8", "0", "00", "00", "00"], ok: true)
                },
                cena("teclas do preço, \(tema)", combo, assunto: ["simPreco", "teclasDoPreco-titulo", "teclasDoPreco-ok"]) { app in
                    Self.digitarOPreco(app)
                },
            ]
        }
        cobrar(cenas)
    }

    /// Os estados do site, no escuro: sem obra elegível, sem preço (o Sobrado Granja Viana não tem venda estimada) e a obra
    /// com menos de 1 mês (o Sobrado Vila Nova: o veredito sem taxa, com a frase do site); e o alto com "Aumentar contraste".
    @MainActor func testLeituraDosEstadosDoValeAPena() {
        let escuro = ["-custta.tema", "escuro"] + piorMomento
        cobrar([
            cena("sem obra", escuro, dados: "vazio", assunto: ["simSemObra", "simNota"]),
            cena("sem preço", escuro, assunto: ["simSemPreco"]) { app in Self.escolherObra(app, "Sobrado Granja Viana") },
            cena("obra com menos de 1 mês", escuro, rolagem: Self.rolagemDoVeredito, assunto: ["simVeredito"]) { app in
                Self.escolherObra(app, "Sobrado Vila Nova")
            },
            cena("com Aumentar contraste", escuro + ["-custta.aumentarContraste", "YES"], assunto: ["simObra", "simPreco", "simNota"]),
        ])
    }

    /// Na maior letra, no escuro: os campos um embaixo do outro, o veredito, a faixa com a legenda, a tabela com um valor por
    /// linha (o começo e o lucro, em verde) e as teclas do preço abertas, com a linha do preço acima delas.
    @MainActor func testLeituraDoValeAPenaNaMaiorLetra() {
        let grande = ["-custta.tema", "escuro"] + piorMomento + maiorLetra
        cobrar([
            cena("na maior letra", grande, assunto: ["simObra"]),
            cena("na maior letra, veredito", grande, espera: "simVeredito", rolagem: Self.rolagemDoVereditoNaMaiorLetra, assunto: ["simVeredito"]),
            cena("na maior letra, faixa", grande, espera: "simFaixa", rolagem: Self.rolagemDaFaixaNaMaiorLetra,
                 assunto: ["simFaixa", "simFaixa-custo"]),
            cena("na maior letra, tabela", grande, espera: "simTabela-0", rolagem: Self.rolagemDaTabelaNaMaiorLetra, assunto: ["simTabela-0"]),
            cena("na maior letra, lucro", grande, espera: "simTabela-2", rolagem: Self.rolagemDoLucroNaMaiorLetra, assunto: ["simTabela-2"]),
            cena("na maior letra, teclas do preço", grande, espera: "simPreco", rolagem: Self.rolagemDoPrecoNaMaiorLetra,
                 assunto: ["simPreco", "teclasDoPreco-ok"]) { app in Self.digitarOPreco(app) },
        ])
    }

    /// O laudo das marcas da faixa "Onde a sua venda cai" (spec da etapa 4, "Laudo das marcas"): o custo, o empate e a venda a
    /// 3:1 com o que fica atrás deles, nos dois temas e nos vidros Transparente e Fosco. Cada cena sai em dois prints, um
    /// normal e um com as marcas apagadas (`-custta.marcasApagadas`, só Debug); a zona, com o recorte em volta das marcas, é
    /// fundo e fica nos dois. Na Casa Alphaville a venda cai dentro da zona: a fenda está no print.
    @MainActor func testMarcasDaFaixaDoValeAPena() {
        var falhas: [String] = []
        for tema in temas {
            for vidro in ["transparente", "fosco"] {
                let nome = "marcas, faixa do vale a pena, \(tema), \(vidro)"
                let argumentos = ["-custta.tema", tema, "-custta.vidro", vidro, "-custta.rolagem", "\(Self.rolagemDaFaixa)"] + piorMomento
                func fotografar(apagadas: Bool) -> (XCUIScreenshot, CGRect, CGFloat) {
                    let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                                       argumentos: argumentos + (apagadas ? ["-custta.marcasApagadas", "YES"] : []))
                    let faixa = app.elemento("simFaixa")
                    XCTAssertTrue(faixa.waitForExistence(timeout: 30), "\(nome): a aba não abriu")
                    Thread.sleep(forTimeInterval: 2)                   // o vidro e a rolagem assentam
                    let foto = XCUIScreen.main.screenshot()
                    // As marcas passam da faixa: 8 pt em cima e embaixo, e o ponto da venda, 15 em cima.
                    let quadro = faixa.frame.insetBy(dx: -4, dy: -18), largura = app.frame.width
                    app.terminate()
                    return (foto, quadro, largura)
                }
                let (normal, quadro, largura) = fotografar(apagadas: false)
                let (semMarcas, _, _) = fotografar(apagadas: true)
                let imagem = normal.image.cgImage!
                let escala = CGFloat(imagem.width) / largura
                let marcas: [LaudoDeContraste.Palavra]
                do {
                    marcas = try LaudoDeContraste.medirMarcas(normal: Retrato(imagem), semMarcas: Retrato(semMarcas.image.cgImage!),
                                                              escala: escala, em: [quadro])
                } catch {
                    XCTFail("\(nome): \(error)")
                    continue
                }
                // O custo, a venda (a barra com o ponto) e os traços do empate.
                XCTAssertGreaterThanOrEqual(marcas.count, 3, "\(nome): \(marcas.map(\.corHex))")
                anexar(nome, normal.image, marcas, escala, portao: Self.portaoDasMarcas, tipo: "marcas")
                Swift.print(String(format: "marcas | %@ | %d marcas | pior nota %.2f", nome, marcas.count, marcas.map(\.nota).min() ?? 0))
                falhas += marcas.filter { $0.nota < Self.portaoDasMarcas }.map { m in
                    "\(nome): marca \(m.corHex) em \(Int(m.caixa.minX)),\(Int(m.caixa.minY)) fica em "
                        + String(format: "%.2f:1 (pior pixel %.2f:1)", m.nota, m.minimo)
                }
            }
        }
        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portaoDasMarcas):1:\n" + falhas.joined(separator: "\n"))
    }

    // As rolagens das cenas, em pontos, medidas no 18 Pro (402 × 874): cada uma deixa o assunto inteiro entre a borda de cima
    // (140 pt) e a de baixo (734), e o `assunto` de cada cena confere isso antes do print, em qualquer aparelho. A do
    // veredito deixa a obra e o preço à vista, para o toque; a da tabela é quase o fim da tela.
    private static let rolagemDoVeredito = 50
    private static let rolagemDaFaixa = 300
    private static let rolagemDaTabela = 605
    private static let rolagemDoVereditoNaMaiorLetra = 1440
    private static let rolagemDaFaixaNaMaiorLetra = 2080
    private static let rolagemDaTabelaNaMaiorLetra = 2760
    private static let rolagemDoLucroNaMaiorLetra = 3340
    private static let rolagemDoPrecoNaMaiorLetra = 250
}
