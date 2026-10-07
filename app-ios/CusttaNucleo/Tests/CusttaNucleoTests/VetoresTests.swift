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
}
