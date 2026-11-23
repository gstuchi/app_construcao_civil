import Testing
import UIKit
@testable import Custta

/* As abas da cápsula: cada uma com o título e o ícone dela, e a aba em que o app abre (Obras; em Debug, a do gancho
   `CUSTTA_ABRIR=aba:<nome>`, que leva o laudo e a auditoria a uma aba sem tocar na cápsula). */
@MainActor
struct CapsulaDeAbasTests {
    @Test func cadaAbaTemOTituloEOIconeDela() {
        #expect(Aba.allCases.map(\.rawValue) == ["obras", "valeAPena", "ajustes"], "a ordem da cápsula")
        #expect(Aba.allCases.map(\.titulo) == ["Obras", "Vale a pena?", "Ajustes"])
        #expect(Aba.allCases.map(\.icone) == ["Icones/predio", "Icones/balanca", "Icones/engrenagem"])
        for aba in Aba.allCases {
            #expect(UIImage(named: aba.icone) != nil, "o ícone de \(aba.rawValue) está no catálogo")
        }
    }

    @Test func oGanchoEscolheAAbaESoEle() {
        #expect(PrincipalView.aba(doGancho: "aba:ajustes") == .ajustes)
        #expect(PrincipalView.aba(doGancho: "aba:obras") == .obras)
        #expect(PrincipalView.aba(doGancho: "aba:valeAPena").rawValue == "valeAPena")
        // Sem gancho, com o gancho de outra tela ou com uma aba que não existe, o app abre em Obras.
        for outro in [nil, "", "aba:", "aba:nada", "obra:v1", "ajustes", "graficos:v1"] {
            #expect(PrincipalView.aba(doGancho: outro) == .obras, "\(outro ?? "nil")")
        }
    }
}
