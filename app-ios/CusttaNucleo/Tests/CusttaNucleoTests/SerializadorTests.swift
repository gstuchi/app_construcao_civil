import Foundation
import Testing
@testable import CusttaNucleo

struct SerializadorTests {
    @Test func canonIgualAoDoSite() {
        for c in Vetores.casos("calc.canon") {
            let obtido = canonico(c.args[0]), esperado = c.saida.comoTexto!
            #expect(obtido.utf8.elementsEqual(esperado.utf8), "\(c.caso): \(obtido) ≠ \(esperado)")
        }
    }

    @Test func stringifyDePrimitivasIgualAoDoSite() {
        for c in Vetores.casos("js.stringify") {
            let obtido = canonico(c.args[0]), esperado = c.saida.comoTexto!
            #expect(obtido.utf8.elementsEqual(esperado.utf8), "\(c.caso): \(obtido) ≠ \(esperado)")
        }
    }

    @Test func tamanhoDoBlobIgualAoDoSite() {
        for c in Vetores.casos("calc.tamanhoBlob") {
            #expect(Double(tamanhoBlob(c.args[0])) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func limiteDoBlob() {
        #expect(Double(limiteBlob) == Vetores.casos("calc.LIMITE_BLOB").first?.saida.comoNumero)
        #expect(Double(avisoBlob) == Vetores.casos("calc.AVISO_BLOB").first?.saida.comoNumero)
        for c in Vetores.casos("calc.blobCabe") {
            var blob = c.args.first ?? .nulo
            if let g = c.gerar {
                var base = g.base.comoObjeto!
                base[g.campo] = .texto(String(repeating: g.letra, count: g.vezes))
                blob = .objeto(base)
                #expect(tamanhoBlob(blob) == c.tamanho, "\(c.caso): tamanho montado")
            }
            #expect(blobCabe(blob) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func mesmoConteudoIgnoraOrdemEIgualaNumeroInteiroEDecimal() {
        #expect(mesmoConteudo(.objeto(["a": .numero(1), "b": .lista([])]), .objeto(["b": .lista([]), "a": .numero(1.0)])))
        #expect(!mesmoConteudo(.objeto(["a": .numero(1)]), .objeto(["a": .texto("1")])))
    }
    @Test func mesmoConteudoComparaBytesComoOSite() {
        #expect(mesmoConteudo(.texto("Caf\u{E9}"), .texto("Caf\u{E9}")))
        #expect(!mesmoConteudo(.texto("Caf\u{E9}"), .texto("Cafe\u{301}")),
                "o === do site compara unidade por unidade; o == do Swift igualaria NFC e NFD")
    }

    @Test func pontesComOFoundation() throws {
        let foundation: [String: Any] = ["inteiro": NSNumber(value: Int64(1500)), "decimal": NSNumber(value: 1500.5),
                                         "verdade": NSNumber(value: true), "texto": "ção", "nulo": NSNull(),
                                         "lista": [NSNumber(value: 1), "x"], "objeto": ["a": NSNumber(value: false)]]
        let v = try #require(ValorJSON(foundation: foundation))
        #expect(v == .objeto(["inteiro": .numero(1500), "decimal": .numero(1500.5), "verdade": .booleano(true), "texto": .texto("ção"),
                              "nulo": .nulo, "lista": .lista([.numero(1), .texto("x")]), "objeto": .objeto(["a": .booleano(false)])]))
        #expect(ValorJSON(foundation: Date()) == nil, "tipo que o JSON não tem fica para quem chama")
        #expect(ValorJSON(foundation: ["obras": [["quando": Date()]]]) == nil,
                "dentro do blob também: virar null apagaria o dado na próxima gravação, que reescreve o documento inteiro")
        #expect(ValorJSON(foundation: [NSNumber(value: 1), Data()]) == nil)

        let volta = try #require(ValorJSON.objeto(["i": .numero(1500), "d": .numero(1500.5), "grande": .numero(9_007_199_254_740_992),
                                                   "menosZero": .numero(-0.0), "b": .booleano(true)]).paraFoundation as? [String: Any])
        #expect(volta["i"] as? Int64 == 1500, "inteiro seguro vai como inteiro, como o SDK JavaScript grava")
        #expect(volta["d"] as? Double == 1500.5)
        #expect(volta["grande"] as? Double == 9_007_199_254_740_992, "acima de 2^53 − 1 vai como decimal")
        #expect((volta["menosZero"] as? Double)?.sign == .minus)
        #expect(volta["b"] as? Bool == true)

        let blob: ValorJSON = .objeto(["obras": .lista([.objeto(["id": .texto("o"), "areaM2": .nulo,
                                                                 "orcamento": .objeto(["modo": .texto("total"), "total": .numero(250_000)])])]),
                                       "config": .objeto(["taxaMensal": .numero(1.5), "topicosCustom": .lista([])])])
        #expect(ValorJSON(foundation: blob.paraFoundation) == blob, "ida e volta, com inteiro seguro aninhado (vai como Int64)")
    }
}
