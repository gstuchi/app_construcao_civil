import Testing
import CusttaNucleo
@testable import Custta

/* A tabela do "Vale a pena?": a cor de cada valor sai do sinal que o núcleo deu. Negativo é âmbar, nunca vermelho (mockup
   da etapa 4, nota do quadro `sim-abaixo-baixo`). */
@MainActor
struct TabelaDoValeAPenaTests {
    @Test func negativoVaiEmAmbarNuncaEmVermelho() {
        #expect(TabelaDoValeAPena.cor(.negativo) == .alertaNoVidro)
        #expect(TabelaDoValeAPena.cor(.positivo) == .positivoNoVidro)
        #expect(TabelaDoValeAPena.cor(nil) == .texto)
        for sinal in [SinalDaSimulacao.positivo, .negativo] {
            #expect(![Token.negativo, .negativoNoVidro, .erroNoVidro].contains(TabelaDoValeAPena.cor(sinal)))
        }
    }

    @Test func asColunasSaoAsDoSite() {
        #expect(TabelaDoValeAPena.colunas == ["Pelo bruto", "Pelo corrigido"])
    }
}
