import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As peças da lista da obra na grade nova (etapa 4, PR 1c): o "A vencer" fechado e o cabeçalho do mês na forma mono, e o
   bloco dos afazeres, não passam da largura da coluna em nenhum tamanho de letra, com e sem o Negrito, nas larguras dos
   iPhones (375, 402 e 440 pt menos as bordas de 16), em escala 3, com o cabeçalho de cada mês da Casa Alphaville. Com o
   Negrito, o "A vencer" mono passava 1/3 de pt nas três larguras: o Spacer ao lado do título arredondava para cima, como no
   cabeçalho dos blocos do PR 1b. */
@MainActor
struct ListaDaObraTests {
    /// A largura que a peça ocupa na coluna, na forma mono da lista da obra.
    private func medida(de peca: AnyView, letra: DynamicTypeSize, negrito: Bool, em coluna: CGFloat) -> CGFloat {
        UIHostingController(rootView: peca.environment(\.linhaMono, true).dynamicTypeSize(letra)
            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3))
            .sizeThatFits(in: CGSize(width: coluna, height: CGFloat.infinity)).width
    }

    @Test func pecasDaListaNaoPassamDaLargura() throws {
        let hoje = Date.now
        let casa = Estado.de(DadosDeExemplo.vitrine(hoje: hoje)).obras[0]
        let lista = listaDaObra(casa, hoje: dataLocalISO(hoje, fuso: .current))
        let aVencer = try #require(lista.aVencer)
        #expect(!lista.meses.isEmpty)
        let afazeres = linhaDosAfazeres(casa.afazeres)
        for negrito in [false, true] {
            for letra in DynamicTypeSize.allCases {
                for largura in [CGFloat(343), 370, 408] {
                    let medir = { (peca: AnyView) in medida(de: peca, letra: letra, negrito: negrito, em: largura) }
                    let onde = "\(letra), negrito \(negrito), em \(largura)"
                    let bloco = medir(AnyView(LinhaDosAfazeresView(linha: afazeres)))
                    #expect(bloco == largura, "afazeres, \(onde): \(bloco)")
                    // Na letra de acessibilidade, o "A vencer" empilha o título e o total e abraça o texto; fora dela, ocupa a
                    // coluna inteira.
                    let linha = medir(AnyView(LinhaDoAVencer(grupo: aVencer, aberto: false)))
                    if letra.isAccessibilitySize {
                        #expect(linha <= largura, "A vencer, \(onde): \(linha)")
                    } else {
                        #expect(linha == largura, "A vencer, \(onde): \(linha)")
                    }
                    // O cabeçalho de um mês de nome longo empilha o total já no xxxLarge com o Negrito, em 343, e abraça o texto.
                    for mes in lista.meses {
                        let cabecalho = medir(AnyView(CabecalhoDoMes(mes: mes)))
                        #expect(cabecalho <= largura, "\(mes.titulo), \(onde): \(cabecalho)")
                    }
                }
            }
        }
    }
}
