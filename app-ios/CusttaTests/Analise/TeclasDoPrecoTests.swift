import Testing
import CusttaNucleo
@testable import Custta

/* O que as teclas do preço do "Vale a pena?" gravam nos campos e o que o VoiceOver fala a cada tecla. A fala acompanha a
   linha do preço: com o campo vazio, "sem preço", como o valor dela, e não o "0,00" do teclado de valor. */
@MainActor
struct TeclasDoPrecoTests {
    @Test func oApagarQueLimpaFalaSemPreco() {
        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
        #expect(TeclasDoPreco.tocar(.apagar, &preco, &campos) == "sem preço")
        #expect(campos.precoDigitado == 0)
        #expect(TeclasDoPreco.semPreco == "sem preço", "o mesmo texto do valor da linha do preço")
    }

    @Test func apagarTudoTambemFalaSemPreco() {
        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
        #expect(TeclasDoPreco.tocar(.digito(7), &preco, &campos) == "0,07")
        #expect(TeclasDoPreco.tocar(.apagar, &preco, &campos) == "sem preço")
    }

    @Test func cadaDigitoFalaOValorNovo() {
        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
        for tecla in [TeclaDeValor.digito(8), .duploZero, .duploZero, .duploZero] { _ = TeclasDoPreco.tocar(tecla, &preco, &campos) }
        #expect(campos.precoDigitado == 80_000)
        #expect(TeclasDoPreco.tocar(.digito(0), &preco, &campos) == "800.000,00")
    }

    @Test func aTeclaQueNaoMudaNadaNaoFala() {
        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
        #expect(TeclasDoPreco.tocar(.digito(0), &preco, &campos) == nil)
        #expect(TeclasDoPreco.tocar(.duploZero, &preco, &campos) == nil)
        #expect(campos.precoDigitado == nil)
    }
}
