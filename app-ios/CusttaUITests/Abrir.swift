import XCTest

/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase.
@MainActor
func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
              argumentos: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados]
    if let rede { ambiente["CUSTTA_REDE"] = rede }
    if let leitura { ambiente["CUSTTA_LEITURA"] = leitura }
    app.launchEnvironment = ambiente
    app.launchArguments += argumentos
    app.launch()
    return app
}

extension XCUIApplication {
    /// Elemento por identificador, de qualquer tipo (linha de lista, seção, texto).
    func elemento(_ id: String) -> XCUIElement { descendants(matching: .any).matching(identifier: id).firstMatch }

    /// Troca de aba pela cápsula de abas (aba-obras, aba-ajustes).
    func abrirAba(_ aba: String) {
        let botao = buttons["aba-\(aba)"]
        XCTAssertTrue(botao.waitForExistence(timeout: 10), "aba \(aba)")
        botao.tap()
    }

    func digitar(_ texto: String, em id: String, seguro: Bool = false) {
        let campo = seguro ? secureTextFields[id] : textFields[id]
        XCTAssertTrue(campo.waitForExistence(timeout: 10), "campo \(id)")
        campo.tap()
        if seguro { recusarSenhaForte() }
        campo.typeText(texto)
    }

    /// O iOS 27 do simulador oferece uma senha forte ao focar um campo de senha nova (.newPassword), mesmo com o
    /// app sem domínio associado: a folha "Use Strong Password?" toma o lugar do teclado e engole a digitação.
    /// Quando ela aparece (até 2 s), é fechada; no iOS 26 da CI ela pode não aparecer. A folha é de outro processo,
    /// que o XCUITest não espera assentar: tocado na animação de entrada, o xmark perde o toque e a folha fica
    /// (cada tecla troca então o caractere do campo). Por isso o toque se repete até a folha sair.
    func recusarSenhaForte() {
        let oferta = buttons["GenerateStrongPasswordButton"]
        guard oferta.waitForExistence(timeout: 2) else { return }
        for _ in 1...3 where oferta.exists {
            buttons["xmark"].tap()
            _ = oferta.waitForNonExistence(timeout: 1.5)
        }
        XCTAssertFalse(oferta.exists, "a oferta de senha forte não fechou")
    }
}
