import Testing
@testable import CusttaNucleo

extension ParcelaGerada { var json: ValorJSON { .objeto(["valor": .numero(valor), "data": .texto(data)]) } }
extension Parcelamento {
    var json: ValorJSON {
        .objeto(["valorCompra": .numero(valorCompra), "taxaMensal": .numero(taxaMensal), "nParcelas": .numero(Double(nParcelas)),
                 "totalCompra": .numero(totalCompra), "jurosCompra": .numero(jurosCompra), "parcelas": .lista(parcelas.map(\.json))])
    }
}

struct ParcelasTests {
    @Test func parcelasComRestoNaUltima() {
        for c in Vetores.casos("calc.gerarParcelas") {
            guard let n = Int(exactly: c.args[1].numero) else {
                #expect(c.saida == .lista([]), "\(c.caso): n não inteiro dá lista vazia no site")
                continue
            }
            confere(.lista(gerarParcelas(c.args[0].numero, n, c.args[2].comoTexto!).map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func parcelamentoPrice() {
        for c in Vetores.casos("calc.parcelamentoCartao") {
            guard let n = Int(exactly: c.args[1].numero) else {
                #expect(c.saida == .nulo, "\(c.caso): n não inteiro dá null no site")
                continue
            }
            let r = parcelamentoCartao(c.args[0].numero, n, c.args[2].numero, c.args[3].comoTexto!)
            confere(r?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }
}
