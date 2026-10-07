import Testing
@testable import CusttaNucleo

/* As primitivas do JavaScript que o site usa, conferidas contra o próprio JavaScript (grupos js.*). */
struct PrimitivasJSTests {
    @Test func numeroParaTexto() {
        for c in Vetores.casos("js.numeroParaTexto") {
            #expect(numeroJS(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)")
        }
        #expect(numeroJS(-0.0) == "0")
        #expect(numeroJS(.nan) == "NaN")
    }

    @Test func textoParaNumero() {
        for c in Vetores.casos("js.textoParaNumero") {
            let n = numeroDeTextoJS(c.args[0].comoTexto!)
            confere(n.isFinite ? .numero(n) : .nulo, c.saida, .exata, c.caso)
        }
        // Literal acima de 1024 bits estoura para +infinito, como o Number(); no vetor ele só aparece como null.
        #expect(numeroDeTextoJS("0x" + String(repeating: "f", count: 300)) == .infinity)
        #expect(numeroDeTextoJS("0b" + String(repeating: "1", count: 1100)) == .infinity)
        // Dígitos demais para o Double(String), que desiste acima de 16.384 caracteres; zero à esquerda não conta.
        #expect(numeroDeTextoJS("0x" + String(repeating: "f", count: 20_000)) == .infinity)
        #expect(numeroDeTextoJS("0x" + String(repeating: "0", count: 20_000) + "f") == 15)
    }

    @Test func toFixed() {
        for c in Vetores.casos("js.toFixed") {
            #expect(toFixedJS(c.args[0].numero, Int(c.args[1].numero)) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func mathRound() {
        for c in Vetores.casos("js.round") {
            confere(.numero(arredondarJS(c.args[0].numero)), c.saida, .exata, c.caso)
        }
    }

    @Test func trim() {
        for c in Vetores.casos("js.trim") {
            #expect(aparadoJS(c.args[0].comoTexto!) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func verdadeiroComoNoJavaScript() {
        #expect(!verdadeiroJS(nil))
        #expect(!verdadeiroJS(.nulo))
        #expect(!verdadeiroJS(.numero(0)))
        #expect(!verdadeiroJS(.numero(.nan)))
        #expect(!verdadeiroJS(.texto("")))
        #expect(!verdadeiroJS(.booleano(false)))
        #expect(verdadeiroJS(.numero(-1)))
        #expect(verdadeiroJS(.texto("0")))
        #expect(verdadeiroJS(.lista([])))
        #expect(verdadeiroJS(.objeto([:])))
    }

    @Test func numeroDeValorComoNoJavaScript() {
        #expect(paraNumeroJS(nil).isNaN)
        #expect(paraNumeroJS(.nulo) == 0)
        #expect(paraNumeroJS(.booleano(true)) == 1)
        #expect(paraNumeroJS(.texto(" 3 ")) == 3)
        #expect(paraNumeroJS(.texto("abc")).isNaN)
    }

    /// Saídas do Number() do Node para as mesmas listas.
    @Test func numeroDeListaComoNoJavaScript() {
        #expect(paraNumeroJS(.lista([])) == 0)
        #expect(paraNumeroJS(.lista([.numero(7)])) == 7)
        #expect(paraNumeroJS(.lista([.texto(" 8 ")])) == 8)
        #expect(paraNumeroJS(.lista([.lista([.numero(9)])])) == 9)
        #expect(paraNumeroJS(.lista([.nulo])) == 0)
        #expect(paraNumeroJS(.lista([.numero(1), .numero(2)])).isNaN)
        #expect(paraNumeroJS(.lista([.booleano(true)])).isNaN)
        #expect(paraNumeroJS(.objeto([:])).isNaN)
    }
}
