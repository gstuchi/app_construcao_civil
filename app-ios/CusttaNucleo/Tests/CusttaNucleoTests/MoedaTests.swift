import Testing
@testable import CusttaNucleo

/// Entrada de texto como o JavaScript a recebe: número vira texto do JavaScript, nulo vira nil.
private func textoDeEntrada(_ v: ValorJSON?) -> String? {
    switch v {
    case .numero(let n)?: return numeroJS(n)
    case .texto(let s)?: return s
    default: return nil
    }
}

struct MoedaTests {
    @Test func mascaraAoDigitar() {
        for c in Vetores.casos("calc.fmtDigitado") { #expect(fmtDigitado(textoDeEntrada(c.arg(0))) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func mascaraCompleta() {
        for c in Vetores.casos("calc.fmtCompleto") { #expect(fmtCompleto(textoDeEntrada(c.arg(0))) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func numeroParaCampo() {
        for c in Vetores.casos("calc.numParaCampo") {
            let n: Double? = c.arg(0)?.comoNumero          // nulo e texto vazio dão "" no site
            #expect(numParaCampo(n) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func leituraDoCampo() {
        for c in Vetores.casos("calc.parseNum") {
            let lido = c.arg(0)?.comoNumero.map { lerNumero($0) } ?? lerNumero(c.arg(0)?.comoTexto)
            confere(.numero(lido), c.saida, .exata, c.caso)
        }
    }

    @Test func moedaPorExtenso() {
        for c in Vetores.casos("calc.money") { #expect(moeda(c.arg(0)?.comoNumero) == c.saida.comoTexto, "\(c.caso)") }
        #expect(moeda(1234.5).contains("\u{00A0}"), "espaço não separável depois de R$, como o Intl do site")
    }

    @Test func moedaCurtaComoOSite() {
        for c in Vetores.casos("calc.moneyShort") { #expect(moedaCurta(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
        for c in Vetores.casos("calc.moneyCurto") { #expect(moedaCurtaSemZero(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func mesesDeObraPorExtenso() {
        for c in Vetores.casos("calc.fmtMeses") { #expect(fmtMeses(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
    }

    /// JSON não leva infinito nem NaN, então estes ficam fora dos vetores; as saídas são as do Node.
    @Test func infinitoENaNComoOSite() {
        #expect(moeda(.infinity) == "R$\u{a0}∞")
        #expect(moeda(-.infinity) == "-R$\u{a0}∞")
        #expect(moeda(.nan) == "R$\u{a0}0,00")
        #expect(moedaCurta(.infinity) == "R$ Infinity mi")
        #expect(fmtMeses(.infinity) == "Infinity meses")
        #expect(fmtMeses(.nan) == "NaN meses")
        #expect(lerNumero(.infinity) == 0)
    }
}
