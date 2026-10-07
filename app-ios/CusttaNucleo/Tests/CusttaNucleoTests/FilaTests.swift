import Testing
@testable import CusttaNucleo

struct FilaTests {
    @Test func erroTerminal() {
        for c in Vetores.casos("calc.erroEhTerminal") {
            var codigo: String?
            if let o = c.arg(0)?.comoObjeto, verdadeiroJS(o["code"]) {
                switch o["code"]! {
                case .texto(let s): codigo = s
                case .numero(let n): codigo = numeroJS(n)
                default: codigo = nil
                }
            }
            #expect(erroEhTerminal(codigo: codigo) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func backoff() {
        for c in Vetores.casos("calc.proximoBackoff") {
            #expect(Double(proximoBackoff(paraNumeroJS(c.arg(0)))) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func versao() {
        for c in Vetores.casos("calc.versaoMaior") {
            #expect(versaoMaior(c.arg(0)?.textoOuNil, c.arg(1)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }
}
