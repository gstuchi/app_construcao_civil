import Foundation
import Testing
@testable import CusttaNucleo

struct VetoresTests {
    @Test func arquivoDoSiteLidoPeloNucleo() {
        #expect(Vetores.todos.formato == 1)
        #expect(Vetores.todos.fuso == "America/Sao_Paulo")
        #expect(Vetores.casos("calc.DIAS_MES").first?.saida == .numero(30.44))
    }

    @Test func valorJSONLeOQueOJavaScriptEscreve() throws {
        let texto = #"{"a":[1,2.5,"x",true,null,{"b":{}}],"c":-0.001}"#
        let v = try JSONDecoder().decode(ValorJSON.self, from: Data(texto.utf8))
        #expect(v == .objeto(["a": .lista([.numero(1), .numero(2.5), .texto("x"), .booleano(true), .nulo, .objeto(["b": .objeto([:])])]),
                              "c": .numero(-0.001)]))
        #expect(v.comoObjeto?["a"]?.comoLista?.count == 6)
        #expect(ValorJSON.texto("x").comoNumero == nil)
    }

    /// A tolerância relativa do `.continua` multiplica pelo maior lado: com um lado infinito, ela vira infinito e aceitava
    /// qualquer número do outro lado (o multiplicador TIR ÷ 0 passava contra o 0 do site).
    @Test func continuaReprovaQuandoSoUmLadoNaoEFinito() {
        withKnownIssue("infinito contra zero") { confere(.numero(.infinity), .numero(0), .continua, "∞ × 0") }
        withKnownIssue("menos infinito contra número") { confere(.numero(-.infinity), .numero(2.5), .continua, "-∞ × 2,5") }
        withKnownIssue("número contra infinito") { confere(.numero(1e300), .numero(.infinity), .continua, "1e300 × ∞") }
        // o 1e300 é inteiro e o ramo do inteiro o reprova sozinho; só uma fração prova a guarda do lado esperado
        withKnownIssue("fração contra infinito") { confere(.numero(2.5), .numero(.infinity), .continua, "2,5 × ∞") }
        withKnownIssue("NaN contra número") { confere(.numero(.nan), .numero(0), .continua, "NaN × 0") }
        confere(.numero(.infinity), .numero(.infinity), .continua, "∞ × ∞")
        confere(.numero(0.1 + 0.2), .numero(0.3), .continua, "a tolerância relativa continua")
        confere(.numero(2), .numero(2), .continua, "inteiro exato")
    }
}
