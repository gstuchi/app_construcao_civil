import Testing
@testable import CusttaNucleo

/* O preço nas teclas do "Vale a pena?" (decisões do Giovani de 24/11/2026): as teclas abrem com o valor do campo à vista, a
   primeira tecla o substitui, o apagar como primeira tecla limpa o campo e o OK sem digitar deixa os campos como estavam.
   Cada teste toca as teclas como a grade do app faz: pergunta ao `PrecoNasTeclas` o que a tecla faz e só grava o preço
   quando ele devolve um. */
struct PrecoNasTeclasTests {
    private let hoje = "2026-10-12"

    private func obra(_ id: String, estimada: Double? = nil) -> Obra {
        var arvore: [String: ValorJSON] = [
            "id": .texto(id), "nome": .texto("Obra \(id)"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-10"),
            "gastos": .lista([.objeto(["id": .texto("\(id)-g"), "valor": .numero(100_000), "data": .texto("2026-01-15")])]),
        ]
        if let estimada { arvore["valorEstimadoVenda"] = .numero(estimada) }
        return Obra(arvore: arvore)
    }

    private func precoNaTela(_ campos: CamposDoSimulador, _ obras: [Obra]) -> Double? {
        simulacaoNaTela(campos, obras: obras, hoje: hoje, taxa: 1).preco
    }

    /// Uma tecla, como as `TeclasDoPreco`: o campo só muda quando a tecla devolve um preço.
    private func tocar(_ tecla: TeclaDeValor, _ teclas: inout PrecoNasTeclas, _ campos: inout CamposDoSimulador) {
        if let preco = teclas.tocar(tecla) { campos.precoDigitado = preco }
    }

    @Test func oOkSemDigitarDeixaOsCamposComoEstavam() {
        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
        var campos = CamposDoSimulador()
        let antes = campos
        let teclas = PrecoNasTeclas()
        #expect(teclas.centavos == 0)
        #expect(!teclas.digitou)
        // Abrir as teclas e dar OK não grava nada: o preço continua acompanhando a venda estimada da obra escolhida.
        #expect(campos == antes)
        #expect(precoNaTela(campos, [a, b]) == 300_000)
        campos.obraId = "b"
        #expect(precoNaTela(campos, [a, b]) == 180_000)
    }

    @Test func aPrimeiraTeclaSubstituiOValorAVista() {
        let a = obra("a", estimada: 300_000)
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        tocar(.digito(5), &teclas, &campos)
        // Parte do zero, e não dos R$ 300.000,00 que estavam à vista (com o dígito a mais, seriam R$ 3.000.000,05).
        #expect(teclas.centavos == 5)
        #expect(teclas.digitou)
        #expect(campos.precoDigitado == 0.05)
        #expect(precoNaTela(campos, [a]) == 0.05)
    }

    @Test func tambemSubstituiOPrecoQueAPessoaJaTinhaDigitado() {
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        campos.precoDigitado = 250_000
        tocar(.digito(9), &teclas, &campos)
        #expect(campos.precoDigitado == 0.09)
    }

    @Test func asTeclasSeguintesEntramPelaDireita() {
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        for tecla in [TeclaDeValor.digito(1), .digito(4), .digito(5), .duploZero, .duploZero, .duploZero] {
            tocar(tecla, &teclas, &campos)
        }
        #expect(teclas.centavos == 145_000_000)
        #expect(campos.precoDigitado == 1_450_000)
        tocar(.apagar, &teclas, &campos)
        #expect(campos.precoDigitado == 145_000)
    }

    /// O 0 e o 00 como primeira tecla seguem sem fazer nada: o Giovani decidiu só o apagar (24/11).
    @Test func oZeroEOZeroZeroNaPrimeiraTeclaNaoMudamNada() {
        let a = obra("a", estimada: 300_000)
        for tecla in [TeclaDeValor.digito(0), .duploZero] {
            var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
            tocar(tecla, &teclas, &campos)
            #expect(!teclas.digitou, "\(tecla.nome)")
            #expect(campos.precoDigitado == nil, "\(tecla.nome)")
            #expect(precoNaTela(campos, [a]) == 300_000, "\(tecla.nome)")
        }
    }

    /// "Apagar limpa o campo" (decisão do Giovani de 24/11): com o valor à vista, o apagar como primeira tecla deixa o campo
    /// vazio, como apagar tudo; a tecla seguinte parte do zero, e outro apagar no campo vazio não faz nada.
    @Test func oApagarNaPrimeiraTeclaLimpaOCampo() {
        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        tocar(.apagar, &teclas, &campos)
        #expect(teclas.digitou)
        #expect(teclas.centavos == 0)
        #expect(campos.precoDigitado == 0)
        #expect(precoNaTela(campos, [a, b]) == nil)
        campos.obraId = "b"
        #expect(precoNaTela(campos, [a, b]) == nil, "campo tocado: não volta para a venda estimada")
        #expect(teclas.tocar(.apagar) == nil, "o apagar no campo vazio não faz nada")
        tocar(.digito(5), &teclas, &campos)
        #expect(campos.precoDigitado == 0.05)
    }

    @Test func tambemLimpaOPrecoQueAPessoaJaTinhaDigitado() {
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        campos.precoDigitado = 250_000
        tocar(.apagar, &teclas, &campos)
        #expect(campos.precoDigitado == 0)
    }

    @Test func digitarEApagarTudoDeixaOCampoVazio() {
        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
        tocar(.digito(7), &teclas, &campos)
        tocar(.apagar, &teclas, &campos)
        #expect(teclas.centavos == 0)
        #expect(teclas.digitou)
        // O campo apagado é campo tocado: fica vazio e não volta para a estimada, nem trocando de obra (como no site).
        #expect(campos.precoDigitado == 0)
        #expect(precoNaTela(campos, [a, b]) == nil)
        campos.obraId = "b"
        #expect(precoNaTela(campos, [a, b]) == nil)
    }
}
