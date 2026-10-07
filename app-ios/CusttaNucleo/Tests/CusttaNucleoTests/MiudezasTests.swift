import Testing
@testable import CusttaNucleo

struct MiudezasTests {
    @Test func chaveDoTokenIgualAoPushJs() {
        for c in Vetores.casos("push.hashEndpoint") { #expect(chaveDoToken(c.args[0].comoTexto!) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func prefixoDoIdEmBase36() {
        for c in Vetores.casos("id.base36") {
            let id = gerarId(agoraMs: Int64(c.args[0].numero), sorteio: { _ in 0 })
            #expect(id == c.saida.comoTexto! + "0000", "\(c.caso)")
        }
    }

    @Test func idTemQuatroCaracteresAleatorios() {
        let base36 = Set("0123456789abcdefghijklmnopqrstuvwxyz")
        let id = gerarId(agoraMs: 1_759_750_000_000, sorteio: { _ in 35 })
        #expect(id.hasSuffix("zzzz"))
        #expect(id.allSatisfy(base36.contains))
        // O sorteio padrão só pelo formato: dois ids no mesmo milissegundo podem coincidir (36^4 finais),
        // então a unicidade se confere com milissegundos diferentes, como acontece no app.
        let padrao = gerarId()
        #expect(padrao.count > 4 && padrao.allSatisfy(base36.contains))
        #expect(Set((0..<200).map { gerarId(agoraMs: 1_759_750_000_000 + Int64($0)) }).count == 200)
    }
}
