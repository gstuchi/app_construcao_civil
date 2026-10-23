import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O rascunho da folha do orçamento (etapa 3, PR 1): o que ele lê do orçamento ao abrir (como o formOrcamento do site), a
   soma que preenche o total ao trocar de modo, quando o "Salvar" fica apagado e o que ele entrega para gravar. */
@MainActor
struct FolhaDoOrcamentoTests {
    private func obra(_ orcamento: ValorJSON?) -> Obra {
        var arvore: [String: ValorJSON] = ["id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"),
                                           "dataInicio": .texto("2026-01-01"), "gastos": .lista([])]
        if let orcamento { arvore["orcamento"] = orcamento }
        return Obra(arvore: arvore)
    }

    private let proprio = TopicoProprio(campos: ["id": .texto("c_gesso"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
    private var linhas: [Topico] { topicosDoFormulario([proprio]) }

    @Test func semOrcamentoAbreNoTotalVazioComOSalvarApagado() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        #expect(!r.tinhaOrcamento && r.modo == .total && r.total == 0 && r.valores.isEmpty)
        #expect(r.vazio && !r.salvarHabilitado && !r.temOQuePerder)
        r.total = 120_000_000
        #expect(r.salvarHabilitado && r.temOQuePerder)
        r.trocarModo(.topicos)
        #expect(r.vazio && !r.salvarHabilitado, "por tópico, sem nenhum tópico com valor")
        r.definir(.topico("terreno"), 5_000)
        #expect(r.salvarHabilitado)
        r.definir(.topico("terreno"), 0)
        #expect(r.valores.isEmpty, "a linha zerada fica sem valor")
    }

    /// Como o site: abre no modo salvo, o total só no modo total e os tópicos só no por tópico; o tópico que a folha não
    /// mostra (próprio apagado) fica fora das linhas, para o núcleo guardá-lo.
    @Test func abreNoModoSalvoComOsValoresDele() {
        let porTopico = obra(.objeto(["modo": .texto("topicos"), "total": .numero(9),
                                      "topicos": .objeto(["terreno": .numero(319_847.85), "c_gesso": .numero(1_000), "c_apagado": .numero(7_000)])]))
        let r = RascunhoDoOrcamento(obra: porTopico, topicos: linhas)
        #expect(r.tinhaOrcamento && r.modo == .topicos && r.total == 0)
        #expect(r.valores == ["terreno": 31_984_785, "c_gesso": 100_000])
        #expect(r.comValor == "2 de 22 tópicos com valor" && moeda(r.soma) == "R$\u{a0}320.847,85")
        let total = RascunhoDoOrcamento(obra: obra(.objeto(["modo": .texto("total"), "total": .numero(1_200_000),
                                                            "topicos": .objeto(["terreno": .numero(5)])])), topicos: linhas)
        #expect(total.modo == .total && total.total == 120_000_000 && total.valores.isEmpty)
        total.definir(.total, 0)
        #expect(total.vazio && total.salvarHabilitado, "com orçamento antes, salvar vazio vale (pergunta e tira)")
    }

    /// Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos e diz isso; com o total já preenchido, ou
    /// com a soma zero, nada muda. Trocar de modo é mudança: fechar pergunta.
    @Test func trocarParaOTotalPreencheComASoma() {
        let r = RascunhoDoOrcamento(obra: obra(.objeto(["modo": .texto("topicos"),
                                                        "topicos": .objeto(["terreno": .numero(319_847.85), "estrutura": .numero(85_000)])])),
                                    topicos: linhas)
        r.trocarModo(.total)
        #expect(r.modo == .total && r.total == 40_484_785 && r.nota == "Preenchido com a soma dos tópicos.")
        #expect(r.temOQuePerder)
        r.trocarModo(.topicos)
        #expect(r.nota == nil)
        r.total = 100
        r.trocarModo(.total)
        #expect(r.total == 100 && r.nota == nil, "o total preenchido fica como está")
        let vazio = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        vazio.trocarModo(.topicos)
        #expect(vazio.temOQuePerder, "só trocar de modo já é mudança")
        vazio.trocarModo(.total)
        #expect(vazio.total == 0 && vazio.nota == nil, "sem soma, nada a preencher")
        #expect(!vazio.temOQuePerder, "de volta ao modo de antes, nada mudou")
    }

    /// O que vai para o salvandoOrcamento: o modo ativo, o total em reais e um valor por linha da folha, a vazia com 0.
    @Test func gravacaoComUmValorPorLinha() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        r.trocarModo(.topicos)
        r.definir(.topico("c_gesso"), 123_456)
        let g = r.gravacao
        #expect(g.modo == "topicos" && g.total == 0)
        #expect(g.valores.count == 22 && g.valores["c_gesso"] == 1_234.56 && g.valores["terreno"] == 0)
    }

    /// ‹ › andam na ordem da folha (os 21 fixos e depois os próprios) e param nas pontas; o nome da barra conta a linha.
    @Test func setasENomeNaOrdemDaFolha() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        #expect(r.vizinho(.topico("terreno"), passo: -1) == nil, "na primeira, ‹ não faz nada")
        #expect(r.vizinho(.topico("terreno"), passo: 1) == .topico("projeto"))
        #expect(r.vizinho(.topico("outros"), passo: 1) == .topico("c_gesso"), "depois dos fixos, os próprios")
        #expect(r.vizinho(.topico("c_gesso"), passo: 1) == nil, "na última, › não faz nada")
        #expect(r.vizinho(.total, passo: 1) == nil)
        #expect(r.nome(.topico("eletrica")) == "Elétrica · 9 de 22" && r.nome(.total) == nil)
    }
}
