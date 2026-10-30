import Testing
@testable import CusttaNucleo

extension ContaDoSimulador {
    var json: ValorJSON {
        .objeto(["venda": .numero(venda), "meses": .numero(Double(meses)), "alvo": .texto(alvo), "bruto": .numero(bruto),
                 "corrigido": .numero(corrigido), "novaDemais": .booleano(novaDemais), "tir": opcional(tir), "acima": opcional(acima),
                 "vale": .booleano(vale), "multiplicador": .numero(multiplicador)])
    }
}

extension ValorJSON {
    /// A conta do contaSimulador do site.
    var contaDoSimulador: ContaDoSimulador {
        let o = comoObjeto ?? [:]
        return ContaDoSimulador(venda: o["venda"]!.numero, meses: Int(o["meses"]!.numero), alvo: o["alvo"]!.comoTexto!,
                                bruto: o["bruto"]!.numero, corrigido: o["corrigido"]!.numero, novaDemais: o["novaDemais"] == .booleano(true),
                                tir: o["tir"]?.numeroOuNil, acima: o["acima"]?.numeroOuNil, vale: o["vale"] == .booleano(true),
                                multiplicador: o["multiplicador"]!.numero)
    }
}

extension TextosDoSimulador {
    var json: ValorJSON {
        .objeto(["veredito": .texto(veredito), "taxa": .texto(taxa), "detalhes": .lista(detalhes.map(ValorJSON.texto)),
                 "tabela": .lista(tabela.map { l in
                     .objeto(["rotulo": .texto(l.rotulo), "bruto": .texto(l.bruto), "corrigido": .texto(l.corrigido),
                              "sinalBruto": l.sinalBruto.map { .texto($0.rawValue) } ?? .nulo,
                              "sinalCorrigido": l.sinalCorrigido.map { .texto($0.rawValue) } ?? .nulo, "destaque": .booleano(l.destaque)])
                 })])
    }
}

/* O "Vale a pena?" (calc.js contaSimulador e companhia), conferido contra os vetores do site. */
struct SimuladorTests {
    @Test func mesesDoSimulador() {
        #expect(Double(mesesSimulador) == Vetores.casos("calc.MESES_SIMULADOR")[0].saida.comoNumero)
    }

    @Test func contaDoSimulador() {
        for c in Vetores.casos("calc.contaSimulador") {
            let r = contaSimulador(c.args[0].obra, venda: c.args[1].numero, meses: Int(c.args[2].numero), hoje: c.args[3].comoTexto!,
                                   taxa: c.args[4].numero)
            confere(r?.json ?? .nulo, c.saida, .continua, c.caso)
            // A tolerância relativa deixa passar infinito contra 0 (o confere): sem taxa, o multiplicador é 0, nunca TIR ÷ 0.
            #expect(r.map { $0.multiplicador.isFinite } ?? true, "\(c.caso): multiplicador infinito")
        }
    }

    @Test func textosDoSimulador() {
        for c in Vetores.casos("calc.textosSimulador") {
            confere(textosSimulador(c.args[0].contaDoSimulador, taxa: c.args[1].numero, area: c.args[2].numeroOuNil).json, c.saida, .exata, c.caso)
        }
    }
}
