import XCTest

/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase. `abrir: "obra:v1"` já abre a obra;
/// `extra` passa outras variáveis dos falsos (`CUSTTA_APAGAR_REMOTO`).
@MainActor
func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, argumentos: [String] = [],
              extra: [String: String] = [:]) -> XCUIApplication {
    let app = XCUIApplication()
    var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados].merging(extra) { _, novo in novo }
    if let abrir { ambiente["CUSTTA_ABRIR"] = abrir }
    if let marca { ambiente["CUSTTA_MARCA"] = marca }
    if let rede { ambiente["CUSTTA_REDE"] = rede }
    if let leitura { ambiente["CUSTTA_LEITURA"] = leitura }
    if let limpeza { ambiente["CUSTTA_LIMPEZA"] = limpeza }
    app.launchEnvironment = ambiente
    app.launchArguments += argumentos
    app.launch()
    return app
}

extension XCUIApplication {
    /// Elemento por identificador, de qualquer tipo (linha de lista, seção, texto).
    func elemento(_ id: String) -> XCUIElement { descendants(matching: .any).matching(identifier: id).firstMatch }

    /// Rola aos poucos até o elemento ficar à vista acima da cápsula de abas: o que passa por baixo dela não recebe o
    /// toque, e o `isHittable` do XCUITest não sabe disso (o toque cai na aba). O arrasto termina parado, sem impulso:
    /// um toque com a lista ainda deslizando só a para e não chega ao botão.
    func rolarAte(_ elemento: XCUIElement, tentativas: Int = 12) {
        let capsula = buttons["aba-obras"]
        let limite = (capsula.exists ? capsula.frame.minY : frame.maxY) - 16
        // Sai assim que chega: o `where` do for não sai do laço, e cada volta ociosa custa três consultas (~1,8 s na CI).
        for _ in 0..<tentativas {
            if elemento.exists && elemento.isHittable && elemento.frame.maxY < limite { return }
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)),
                       withVelocity: .slow, thenHoldForDuration: 0.3)
        }
    }

    /// Volta pelo gesto da borda esquerda, como o polegar (o XCUITest não tem "voltar" do sistema).
    func voltarPelaBorda() {
        let borda = coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        borda.press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
    }

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
