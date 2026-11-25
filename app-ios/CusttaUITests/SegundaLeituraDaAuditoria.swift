import XCTest

/* A auditoria de acessibilidade em duas leituras (24/11). Na imagem macos-26-arm64 20261117 (Xcode 26.6, iOS 26), a
   testParte3NoMaiorTamanho caía na main 2 de 3 vezes com "Audit failed to complete in time" (Code=-56; run 45513708306) e,
   no 4a, 1 de 3 com "Dynamic Type font sizes are partially unsupported" em todos os textos da folha da venda ou da obra
   (runs 45512527720 e 45512533450), passando nas outras duas iterações com o mesmo código: a letra vai e volta enquanto a
   auditoria troca os tamanhos, e o achado não é do app.

   O critério muda assim: um achado que o julgamento da tela reprova só reprova se aparecer de novo numa segunda auditoria da
   mesma cena, com o mesmo tipo, a mesma descrição e o mesmo elemento (identificador e rótulo; sem elemento, a descrição).
   Defeito de verdade (fonte fixa, texto cortado, rótulo faltando) aparece nas duas leituras; o vaivém da letra não se
   repete. A segunda leitura vale só no iOS 26 (no 27, o achado reprova na primeira, como antes), em toda auditoria que passa
   pelo `auditar` compartilhado: o -56 também derrubou a testOrcamentoNoMaiorTamanho (CI do 3878471, 432 s). E o -56 ganha uma nova tentativa da auditoria na mesma cena; dois seguidos reprovam. Toda segunda leitura e toda
   nova tentativa vão para o log com a cena, e o fim do teste traz a contagem, para se ver se a imagem piora. */
extension XCTestCase {
    /// Audita `app` com `julgar` (true: o achado fica de fora) em duas leituras. A cena sai do que abriu o app (folha, tela
    /// aberta ou dados, e a rolagem fixa), com o número da auditoria no teste.
    @MainActor func auditarEmDuasLeituras(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
                                          julgar: @escaping (XCUIAccessibilityAuditIssue) throws -> Bool) throws {
        let cena = RegistroDaAuditoria.cena(de: app, em: self)
        // No iOS 27 a letra não vai e volta: o achado reprova na primeira leitura, como antes.
        guard !ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0)) else {
            return try auditarComNovaTentativa(app, tipos, cena: cena, julgar)
        }
        var reprovados: [String: String] = [:]
        try auditarComNovaTentativa(app, tipos, cena: cena) { achado in
            if try julgar(achado) { return true }
            reprovados[Self.chave(achado)] = achado.compactDescription
            return true   // segura até a segunda leitura
        }
        guard !reprovados.isEmpty else { return }
        Swift.print("auditoria | 2ª leitura | \(cena) | \(reprovados.count) achado(s) da 1ª: "
                    + reprovados.values.sorted().joined(separator: "; "))
        var repetidos = Set<String>()
        try auditarComNovaTentativa(app, tipos, cena: cena) { achado in
            if try julgar(achado) { return true }
            let chave = Self.chave(achado)
            guard reprovados[chave] != nil else {
                Swift.print("auditoria | 2ª leitura | \(cena) | só na 2ª, não repetiu: \(achado.compactDescription)")
                RegistroDaAuditoria.anotar(naoRepetiu: cena, em: self)
                return true
            }
            repetidos.insert(chave)
            return false   // apareceu nas duas leituras: reprova
        }
        for chave in reprovados.keys.sorted() where !repetidos.contains(chave) {
            Swift.print("auditoria | 2ª leitura | \(cena) | só na 1ª, não repetiu: \(chave)")
            RegistroDaAuditoria.anotar(naoRepetiu: cena, em: self)
        }
    }

    @MainActor private func auditarComNovaTentativa(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType, cena: String,
                                                    _ julgar: @escaping (XCUIAccessibilityAuditIssue) throws -> Bool) throws {
        do {
            try app.performAccessibilityAudit(for: tipos, julgar)
        } catch let erro as NSError where erro.domain == "com.apple.xcode.xctest.accessibilityAudit" && erro.code == -56 {
            Swift.print("auditoria | nova tentativa por -56 | \(cena) | \(erro.localizedDescription)")
            RegistroDaAuditoria.anotar(retentativa: cena, em: self)
            try app.performAccessibilityAudit(for: tipos, julgar)
        }
    }

    /// O mesmo achado nas duas leituras: tipo, descrição e elemento. O quadro fica fora: a auditoria rola a tela.
    private static func chave(_ achado: XCUIAccessibilityAuditIssue) -> String {
        let elemento = achado.element.map { "\($0.elementType.rawValue) \"\($0.label)\" \($0.identifier)" } ?? "sem elemento"
        return "\(achado.auditType.rawValue) \(achado.compactDescription) | \(elemento)"
    }
}

/// As segundas leituras e as novas tentativas de cada teste, contadas para o resumo do fim dele.
@MainActor enum RegistroDaAuditoria {
    private struct Contagem {
        var auditorias = 0
        var retentativas: [String] = []
        var naoRepetiram: [String] = []
    }
    private static var porTeste: [ObjectIdentifier: Contagem] = [:]

    static func cena(de app: XCUIApplication, em teste: XCTestCase) -> String {
        let chave = ObjectIdentifier(teste)
        if porTeste[chave] == nil {
            porTeste[chave] = Contagem()
            teste.addTeardownBlock { @MainActor in resumir(teste) }
        }
        porTeste[chave]!.auditorias += 1
        let ambiente = app.launchEnvironment
        var nome = ambiente["CUSTTA_FOLHA"].map { "folha \($0)" } ?? ambiente["CUSTTA_ABRIR"] ?? "dados \(ambiente["CUSTTA_DADOS"] ?? "?")"
        if let i = app.launchArguments.firstIndex(of: "-custta.rolagem"), i + 1 < app.launchArguments.count {
            nome += " a \(app.launchArguments[i + 1])"
        }
        return "\(nome) #\(porTeste[chave]!.auditorias)"
    }

    static func anotar(retentativa cena: String, em teste: XCTestCase) { porTeste[ObjectIdentifier(teste)]?.retentativas.append(cena) }
    static func anotar(naoRepetiu cena: String, em teste: XCTestCase) { porTeste[ObjectIdentifier(teste)]?.naoRepetiram.append(cena) }

    private static func resumir(_ teste: XCTestCase) {
        guard let c = porTeste.removeValue(forKey: ObjectIdentifier(teste)) else { return }
        func lista(_ cenas: [String]) -> String {
            guard !cenas.isEmpty else { return "0" }
            var vezes: [String: Int] = [:]
            for cena in cenas { vezes[cena, default: 0] += 1 }
            return "\(cenas.count) (" + vezes.keys.sorted().map { vezes[$0]! > 1 ? "\($0) ×\(vezes[$0]!)" : $0 }.joined(separator: ", ") + ")"
        }
        Swift.print("auditoria | resumo | \(teste.name) | \(c.auditorias) auditorias | retentativas: \(lista(c.retentativas)), "
                    + "achados que não repetiram: \(lista(c.naoRepetiram))")
    }
}
