import Foundation
import Testing
@testable import CusttaNucleo

struct DatasTests {
    let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!

    @Test func dataLocalNoFusoDeBrasilia() {
        #expect(Vetores.todos.fuso == "America/Sao_Paulo")
        for c in Vetores.casos("calc.dataLocalISO") {
            let instante = Date(timeIntervalSince1970: c.args[0].numero / 1000)
            #expect(dataLocalISO(instante, fuso: saoPaulo) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func diaDependeDoFusoDoAparelho() {
        let instante = Date(timeIntervalSince1970: 1_787_707_800)     // 2026-08-26 01:30 UTC
        #expect(dataLocalISO(instante, fuso: saoPaulo) == "2026-08-25")
        #expect(dataLocalISO(instante, fuso: TimeZone(identifier: "Asia/Tokyo")!) == "2026-08-26")
    }

    @Test func dataValida() {
        for c in Vetores.casos("calc.dataISOValida") {
            #expect(dataISOValida(c.arg(0)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func igualOuDepois() {
        for c in Vetores.casos("calc.dataIgualOuDepois") {
            #expect(dataIgualOuDepois(c.arg(0)?.textoOuNil, c.arg(1)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func diasEntreDatas() {
        for c in Vetores.casos("calc.diasEntre") {
            #expect(Double(diasEntre(c.args[0].comoTexto!, c.args[1].comoTexto!)) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func somaMesesComClamp() {
        for c in Vetores.casos("calc.addMesesClampado") {
            #expect(addMesesClampado(c.args[0].comoTexto!, Int(c.args[1].numero)) == c.saida.comoTexto, "\(c.caso)")
        }
    }
}
