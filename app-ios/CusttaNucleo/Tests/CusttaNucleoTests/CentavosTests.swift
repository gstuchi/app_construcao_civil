import Testing
@testable import CusttaNucleo

struct CentavosTests {
    @Test func tetoDoSite() {
        #expect(Vetores.casos("teclado.TETO").first?.saida == .numero(Double(tetoDoTeclado)))
    }

    @Test func teclaPelaDireitaComoAMaquininha() {
        for c in Vetores.casos("teclado.aplicarTecla") {
            let centavos = Int(c.args[0].numero)
            let r = TeclaDeValor(nome: c.args[1].comoTexto!).map { aplicarTecla(centavos, $0) } ?? centavos   // não é tecla: o site ignora
            confere(.numero(Double(r)), c.saida, .exata, c.caso)
        }
    }

    @Test func nomeDaTeclaIdaEVolta() {
        for t in [TeclaDeValor.digito(0), .digito(9), .duploZero, .apagar] { #expect(TeclaDeValor(nome: t.nome) == t) }
        #expect(TeclaDeValor(nome: "10") == nil)
        #expect(TeclaDeValor(nome: "x") == nil)
    }

    @Test func visorDoValor() {
        for c in Vetores.casos("teclado.fmtCentavos") { confere(.texto(fmtCentavos(Int(c.args[0].numero))), c.saida, .exata, c.caso) }
    }

    @Test func centavosEReais() {
        for c in Vetores.casos("teclado.centavosParaReais") {
            confere(.numero(centavosParaReais(Int(c.args[0].numero))), c.saida, .exata, c.caso)
        }
        for c in Vetores.casos("teclado.reaisParaCentavos") {
            confere(.numero(Double(reaisParaCentavos(c.args[0].numero))), c.saida, .exata, c.caso)
        }
    }
}
