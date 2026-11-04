import XCTest
import notify

/* A tela da obra (etapa 2, PR 1), com os dados da vitrine (a obra do mockup aprovado: 46 lançamentos, 13 a vencer):
   entrar pela lista e voltar pelo círculo e pela borda; o caminho que sobrevive à troca de aba; os indicadores com os
   números do mockup; o "A vencer" fechado que abre e fecha; e a obra sem gastos. */
@MainActor
final class ObraUITests: XCTestCase {
    func testEntrarPelaListaEVoltarPeloCirculo() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let obra = app.elemento("obra-v1")
        XCTAssertTrue(obra.waitForExistence(timeout: 10))
        obra.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a obra abriu")
        XCTAssertTrue(app.buttons["aba-obras"].exists, "a cápsula de abas fica fixa durante o push")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "voltou para Obras")
    }

    func testVoltarPelaBorda() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.voltarPelaBorda()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "a borda esquerda volta para Obras")
    }

    func testAObraAbertaSobreviveATrocaDeAba() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        app.abrirAba("obras")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "volta para a obra que estava aberta")
    }

    func testIndicadoresComOsNumerosDoMockup() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let total = app.elemento("indicadorTotal")
        XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
        XCTAssertTrue(app.elemento("indicadorCorrigido").label.contains("R$\u{a0}926.847,69"))
        let aPagar = app.elemento("indicadorAPagar").label
        XCTAssertTrue(aPagar.contains("R$\u{a0}13.250,00") && aPagar.contains("3 vencimentos"), aPagar)
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.450.000,00"))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        let fase = app.elemento("faseDaObra").label
        XCTAssertTrue(fase.contains("14 meses"), fase)
        let tituloPequeno = app.elemento("tituloPequenoDaBarra")
        XCTAssertFalse(tituloPequeno.exists, "no alto, o nome fica só no título grande")
        // A pílula fica abaixo da dobra: rolada a tela até ela, o nome passa para a barra.
        let lancamentos = app.elemento("lancamentos")
        app.rolarAte(lancamentos)
        XCTAssertTrue(lancamentos.label.contains("46"), lancamentos.label)
        XCTAssertTrue(tituloPequeno.waitForExistence(timeout: 5), "rolada a tela, o nome passa para a barra")
    }

    /// Com a obra rolada na maior letra, o Tamanho do Texto vai à letra padrão e volta, como pela Central de Controle (a
    /// auditoria do iOS 26 faz o mesmo em volta de cada auditoria): a obra volta com a mesma peça no mesmo lugar. A List
    /// guardava o número da rolagem e, na volta, com as linhas de cima na altura estimada, a tela parava num mês lá embaixo.
    func testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"],
                           extra: ["CUSTTA_TROCA_LETRA": "aviso"])
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.5)
        let pecas = ["indicadorTotal", "indicadorCorrigido", "indicadorAPagar", "indicadorVenda", "linhaDosAfazeres", "lancamentos"]
        guard let id = pecas.first(where: { app.elemento($0).exists && app.elemento($0).isHittable }) else {
            return XCTFail("nenhuma peça do alto à vista depois de rolar")
        }
        let peca = app.elemento(id), antes = peca.frame
        notify_post("br.com.custta.falso.trocarLetra")          // a letra padrão
        Thread.sleep(forTimeInterval: 2.5)
        XCTAssertTrue(peca.exists, "\(id) segue na tela na letra padrão")
        XCTAssertLessThan(peca.frame.height, antes.height - 1, "a letra padrão encolhe \(id): a troca chegou ao app")
        notify_post("br.com.custta.falso.trocarLetra")          // de volta à maior
        Thread.sleep(forTimeInterval: 2.5)
        XCTAssertTrue(peca.exists, "\(id) segue na tela depois de a letra ir e voltar")
        XCTAssertEqual(peca.frame.minY, antes.minY, accuracy: 2, "\(id) no mesmo lugar: antes \(antes), depois \(peca.frame)")
    }

    func testAVencerFechadoAbreEFecha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let aVencer = app.elemento("aVencer")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.rolarAte(aVencer)
        XCTAssertEqual(aVencer.value as? String, "fechado")
        XCTAssertFalse(app.elemento("gasto-g037").exists, "as parcelas futuras não aparecem com o grupo fechado")
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForExistence(timeout: 5), "aberto, mostra o próximo vencimento")
        XCTAssertEqual(aVencer.value as? String, "aberto")
        // Aberto, as linhas ficam juntas como no cartão do mês: entre dois gastos do mesmo mês, só a linha fina.
        let porcelanato = app.elemento("gasto-g032"), tinta = app.elemento("gasto-g045")
        XCTAssertLessThan(abs(tinta.frame.minY - porcelanato.frame.maxY), 1, "o vão entre os gastos é o do cartão do mês")
        app.rolarAte(aVencer)
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForNonExistence(timeout: 5), "fechado de novo, as parcelas somem")
        XCTAssertEqual(aVencer.value as? String, "fechado")
    }

    func testLinhaDoGastoComORotuloDoMockup() {
        // Sem rede, com a pílula "Sem conexão" na barra: rolada a tela, o nome da obra não entra ao lado dela.
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let cimento = app.elemento("gasto-g027")
        app.rolarAte(cimento)
        XCTAssertTrue(cimento.waitForExistence(timeout: 5))
        XCTAssertTrue(cimento.label.hasPrefix("Cimento CP-II, 120 sacos. Materiais básicos, Pix, "), cimento.label)
        XCTAssertEqual(cimento.value as? String, "R$\u{a0}4.980,00")
        app.swipeUp()
        XCTAssertTrue(app.elemento("indicadorSincronizacao").exists)
        XCTAssertFalse(app.elemento("tituloPequenoDaBarra").waitForExistence(timeout: 2),
                       "com a pílula de sincronização, o nome não entra na barra")
        // No fim da rolagem, o último gasto fica à vista, acima da cápsula de abas (mockup: o conteúdo termina 132 pt acima
        // da borda de baixo).
        let ultimo = app.elemento("gasto-g001")
        var fim = -1.0                                   // a List cria o último cartão um pouco antes de ele entrar na tela
        for _ in 0..<16 {
            app.swipeUp()
            guard ultimo.exists else { continue }
            if ultimo.frame.maxY == fim { break }
            fim = ultimo.frame.maxY
        }
        XCTAssertLessThanOrEqual(ultimo.frame.maxY, app.buttons["aba-obras"].frame.minY, "o último gasto acima da cápsula")
    }

    func testObraSemGastos() {
        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
        XCTAssertTrue(app.elemento("indicadorTotal").waitForExistence(timeout: 10))
        let total = app.elemento("indicadorTotal").label
        XCTAssertTrue(total.contains("sem gastos") && total.contains("R$\u{a0}0,00"), total)
        // O cartão vazio fica no fim, abaixo da dobra.
        app.rolarAte(app.elemento("obraSemGastos"))
        XCTAssertTrue(app.elemento("obraSemGastos").exists)
        // Etapa 4: o sólido com R$ 0,00 convida a lançar o primeiro gasto.
        XCTAssertTrue(total.contains("Toque no + para lançar o primeiro gasto."), total)
    }

    /// Etapa 4 (PR 1c): o alto em blocos, na grade 16/34. O título, a cápsula e os blocos a 16 pt da borda; os blocos na
    /// largura da coluna, 12 pt um do outro, na ordem do mockup (o sólido do Total gasto, Orçamento, Corrigido, A pagar e
    /// Venda) e a cápsula 16 pt acima do sólido.
    func testOAltoEmBlocosNaGrade() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let largura = app.windows.firstMatch.frame.width
        let ids = ["indicadorTotal", "indicadorOrcamento", "indicadorCorrigido", "indicadorAPagar", "indicadorVenda"]
        let quadros = ids.map { app.elemento($0).frame }
        for (id, quadro) in zip(ids, quadros) {
            XCTAssertEqual(quadro.minX, 16, accuracy: 0.5, "\(id) na borda de 16 pt")
            XCTAssertEqual(quadro.width, largura - 32, accuracy: 0.5, "\(id) na largura da coluna")
        }
        for i in 1..<quadros.count {
            XCTAssertEqual(quadros[i].minY - quadros[i - 1].maxY, 12, accuracy: 0.5, "\(ids[i]) 12 pt abaixo de \(ids[i - 1])")
        }
        let titulo = app.elemento("tituloDaObra").frame, fase = app.elemento("faseDaObra").frame
        XCTAssertEqual(titulo.minX, 16, accuracy: 0.5, "o título solto na borda de 16 pt")
        XCTAssertEqual(fase.minX, 16, accuracy: 0.5, "a cápsula na borda de 16 pt")
        XCTAssertEqual(quadros[0].minY - fase.maxY, 16, accuracy: 0.5, "a cápsula 16 pt acima do sólido")
        // O anel do VoiceOver abraça a peça, e não a linha da List (a cápsula tem 269 pt, o título 258, a coluna 370).
        XCTAssertLessThan(titulo.width, largura - 32 - 40, "o anel do título abraça o título: \(titulo)")
        XCTAssertLessThan(fase.width, largura - 32 - 40, "o anel da cápsula abraça a cápsula: \(fase)")
        XCTAssertFalse(app.elemento("indicadorLucro").exists, "fora da vendida, o sólido é o Total gasto")
    }

    /// A vendida com lucro (decisão 4: A): o sólido é o lucro da venda, e o Total gasto desce para o vidro, logo depois do
    /// Orçamento, com os mesmos números.
    func testVendidaComLucroNoSolido() {
        let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:a1")
        let lucro = app.elemento("indicadorLucro")
        XCTAssertTrue(lucro.waitForExistence(timeout: 10))
        XCTAssertTrue(lucro.label.hasPrefix("Lucro da venda, Vendida em ") && lucro.label.contains(", +R$\u{a0}")
                      && lucro.label.hasSuffix(" acima do banco"), lucro.label)
        let fase = app.elemento("faseDaObra").frame, orcamento = app.elemento("indicadorOrcamento").frame
        let total = app.elemento("indicadorTotal")
        XCTAssertEqual(lucro.frame.minY - fase.maxY, 16, accuracy: 0.5, "o lucro é o sólido, logo abaixo da cápsula")
        XCTAssertEqual(orcamento.minY - lucro.frame.maxY, 12, accuracy: 0.5, "o Orçamento logo depois do sólido")
        XCTAssertEqual(total.frame.minY - orcamento.maxY, 12, accuracy: 0.5, "o Total gasto logo depois do Orçamento")
        XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
        app.rolarAte(app.elemento("indicadorVenda"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
    }

    /// Embaixo das ações, os afazeres e os gastos por tópico, blocos de vidro na grade, 12 pt um do outro: o bloco dos gastos
    /// por tópico é um elemento só no VoiceOver, com o título e os pedaços no rótulo e no valor (a legenda, dentro dele, não
    /// é lida de novo), sem toque (a porta para os Gráficos chega com eles); depois, os lançamentos.
    func testAfazeresEGastosPorTopicoEmBlocos() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let largura = app.windows.firstMatch.frame.width
        let topicos = app.elemento("gastosPorTopico")
        app.rolarAte(topicos)
        XCTAssertTrue(topicos.exists, "o bloco dos gastos por tópico")
        let afazeres = app.elemento("linhaDosAfazeres").frame, bloco = topicos.frame
        for (nome, quadro) in [("afazeres", afazeres), ("gastos por tópico", bloco)] {
            XCTAssertEqual(quadro.minX, 16, accuracy: 0.5, "\(nome) na borda de 16 pt")
            XCTAssertEqual(quadro.width, largura - 32, accuracy: 0.5, "\(nome) na largura da coluna")
        }
        XCTAssertEqual(bloco.minY - afazeres.maxY, 12, accuracy: 0.5, "os gastos por tópico 12 pt abaixo dos afazeres")
        XCTAssertEqual(topicos.label, "Gastos por tópico")
        XCTAssertTrue((topicos.value as? String ?? "").hasPrefix("Terreno, 38%; Estrutura, 11%; Cerâmica, 9%; Mão de obra, 8%"),
                      "\(topicos.value ?? "")")
        // O VoiceOver lê só o bloco. O XCUITest mostra os textos de dentro como filhos dele, como os do `indicadorTotal`
        // (.combine) e o dos afazeres (.ignore); com o .contain de antes, o bloco não tinha rótulo nem valor.
        XCTAssertTrue(topicos.staticTexts["e mais 10 tópicos"].exists, "a legenda dentro do bloco")
        XCTAssertFalse(app.buttons["gastosPorTopico"].exists, "o bloco não é botão")
        XCTAssertGreaterThan(app.elemento("lancamentos").frame.minY, bloco.maxY, "os lançamentos depois")
    }

    /// O "<1%" falado como "menos de 1%" no bloco: a Casa Granja Viana tem o Outros (R$ 950,00) e o Extras (R$ 180,00) abaixo
    /// de 1% da obra. Na Casa Alphaville, a Pintura (0,8%) fica dentro do "Outros · 8 tópicos".
    func testGastosPorTopicoFalaMenosDeUmPorcento() {
        let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:a6")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let topicos = app.elemento("gastosPorTopico")
        app.rolarAte(topicos)
        XCTAssertTrue(topicos.exists, "o bloco dos gastos por tópico")
        let valor = topicos.value as? String ?? ""
        XCTAssertTrue(valor.hasSuffix("Extras, menos de 1%; Outros, menos de 1%") && !valor.contains("<"), valor)
    }

    /// Sem gastos, somem os gastos por tópico (como as portas do site).
    func testSemGastosSemGastosPorTopico() {
        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        // O cartão vazio é a última peça: com a lista nele, o lugar dos gastos por tópico está na tela.
        app.rolarAte(app.elemento("obraSemGastos"))
        XCTAssertTrue(app.elemento("obraSemGastos").exists)
        XCTAssertFalse(app.elemento("gastosPorTopico").exists)
        XCTAssertTrue(app.elemento("linhaDosAfazeres").exists)
    }

    /// Com prejuízo (B), o sólido volta a ser o Total gasto, e o lucro negativo fica no bloco da venda.
    func testVendidaComPrejuizoNoTotal() {
        let app = abrirApp(conta: "senha", dados: "prejuizo", abrir: "obra:v3")
        let total = app.elemento("indicadorTotal")
        XCTAssertTrue(total.waitForExistence(timeout: 10))
        XCTAssertFalse(app.elemento("indicadorLucro").exists, "com prejuízo, nada de lucro no sólido")
        XCTAssertEqual(total.frame.minY - app.elemento("faseDaObra").frame.maxY, 16, accuracy: 0.5, "o Total gasto é o sólido")
        let venda = app.elemento("indicadorVenda").label
        XCTAssertTrue(venda.contains("R$\u{a0}800.000,00") && venda.contains("lucro -R$"), venda)
    }
}
