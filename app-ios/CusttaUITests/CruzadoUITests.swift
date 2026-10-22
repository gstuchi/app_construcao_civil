import XCTest

/* Metade tela da conferência cruzada (tests/app-ios/cruzado.mjs): entra pelo formulário na
   conta que o "site" criou, confere o total e o orçamento que o site calculou e pede ao roteiro
   uma mudança feita como o site faz; ela tem de aparecer sozinha na lista e, nos afazeres que o site anotou e marcou,
   na linha da obra e na tela Afazeres, na ordem que o site mostra. Os elementos são achados pelo identificador, de
   qualquer tipo: o visual pode mudar sem quebrar o teste. */
final class CruzadoUITests: XCTestCase {
    private let ambiente = ProcessInfo.processInfo.environment

    private struct Esperado: Decodable {
        let id: String
        let nome: String
        let total: String
        let orcamento: String?
    }

    private struct AfazeresEsperados: Decodable {
        let obra: String
        let linha: String
        let pendentes: [String]
        let feitos: [String]
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(ambiente["CUSTTA_CRUZADO"] == "1", "só na conferência cruzada: npm run test:app-ios:cruzado")
        continueAfterFailure = false
    }

    @MainActor func testMudancaNoSiteChegaAoApp() async throws {
        let v1 = try JSONDecoder().decode([Esperado].self, from: Data(ambiente["CUSTTA_ESPERADO_V1"]!.utf8))
        let v2 = try JSONDecoder().decode([Esperado].self, from: Data(ambiente["CUSTTA_ESPERADO_V2"]!.utf8))
        let app = XCUIApplication()
        app.launchEnvironment = ["CUSTTA_EMULADORES": "1", "CUSTTA_SAIR_AO_ABRIR": "1"]
        app.launch()
        let elemento = { (id: String) in app.descendants(matching: .any).matching(identifier: id).firstMatch }

        let email = elemento("email")
        XCTAssertTrue(email.waitForExistence(timeout: 30))
        email.tap()
        email.typeText(ambiente["CUSTTA_EMAIL"]!)
        let senha = elemento("senha")
        senha.tap()
        senha.typeText(ambiente["CUSTTA_SENHA"]!)
        elemento("entrar").tap()

        for obra in v1 { await confere(app, obra) }

        var pedido = URLRequest(url: URL(string: "http://127.0.0.1:8124/site/mudar")!)
        pedido.httpMethod = "POST"
        let (_, resposta) = try await URLSession.shared.data(for: pedido)
        XCTAssertEqual((resposta as? HTTPURLResponse)?.statusCode, 200)

        for obra in v2 { await confere(app, obra) }

        // Os afazeres da v2, na obra e na tela Afazeres: os pendentes e, abertos os Feitos, os feitos, na ordem do site.
        let afazeres = try JSONDecoder().decode(AfazeresEsperados.self, from: Data(ambiente["CUSTTA_ESPERADO_AFAZERES"]!.utf8))
        app.recusarGuardarSenha()                       // a oferta do iOS de guardar a senha do formulário cobre a lista
        elemento("obra-\(afazeres.obra)").tap()
        let linha = elemento("linhaDosAfazeres")
        XCTAssertTrue(linha.waitForExistence(timeout: 30))
        app.rolarAte(linha)
        XCTAssertEqual(linha.value as? String, afazeres.linha)
        linha.tap()
        XCTAssertTrue(elemento("pendentes").waitForExistence(timeout: 10))
        XCTAssertEqual(rotulosDosAfazeres(app), afazeres.pendentes, "os pendentes, com os Feitos fechados")
        elemento("feitos").tap()
        XCTAssertEqual(rotulosDosAfazeres(app), afazeres.pendentes + afazeres.feitos, "abertos os Feitos")
    }

    /// Os afazeres à vista, de cima para baixo, pelo texto.
    @MainActor private func rotulosDosAfazeres(_ app: XCUIApplication) -> [String] {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'afazer-'")).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }.map(\.label)
    }

    /// A linha da obra traz no valor de acessibilidade o total completo e a linha do orçamento.
    @MainActor private func confere(_ app: XCUIApplication, _ obra: Esperado) async {
        let linha = app.descendants(matching: .any).matching(identifier: "obra-\(obra.id)").firstMatch
        XCTAssertTrue(linha.waitForExistence(timeout: 30), "a obra \(obra.nome) não apareceu")
        for trecho in [obra.total] + (obra.orcamento.map { [$0] } ?? []) {
            let chegou = expectation(for: NSPredicate(format: "value CONTAINS %@", trecho), evaluatedWith: linha)
            await fulfillment(of: [chegou], timeout: 30)
        }
        XCTAssertEqual(linha.label, obra.nome)
    }
}
