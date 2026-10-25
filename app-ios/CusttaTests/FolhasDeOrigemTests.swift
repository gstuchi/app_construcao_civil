import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A lógica das folhas de origem da etapa 3 (o A pagar): as peças da lista, filhas diretas da LazyVStack, com o lugar de
   cada uma no grupo do mês (o fundo do grupo é desenhado por peça); a volta da edição empurrada (o caminho, o rascunho
   que sai na raiz, a volta por qualquer caminho, a guarda do toque duplo, o apagar); e para onde o VoiceOver vai quando a
   edição volta ou uma linha sai. */
@MainActor
struct FolhasDeOrigemTests {
    /// A obra com três vencimentos e o rascunho da edição do primeiro.
    func edicao() -> (Obra, RascunhoDoGasto) {
        let o = obra([gasto("a", "2026-10-15"), gasto("b", "2026-11-05"), gasto("c", "2026-11-06")])
        return (o, RascunhoDoGasto(obra: o, editado: o.gastos[0], todas: [o], proprios: [], hoje: "2026-10-12"))
    }

    @Test func aEdicaoEntraNaPilhaEOVoltarDoSistemaSoltaORascunho() {
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        let (_, r) = edicao()
        origem.abrir(r, ordem: ["a", "b", "c"])
        #expect(origem.caminho == [.editar("a")])
        #expect(origem.editando("a"))
        #expect(!origem.temOQuePerder)
        r.descricao = "outra"
        #expect(origem.temOQuePerder, "a edição mudou: o puxar e o voltar perguntam")
        origem.caminho = []                              // o voltar do sistema (ou a borda), pela pilha
        #expect(origem.volta?.motivo == .voltou("a"))
        #expect(origem.volta?.ordem == ["a", "b", "c"])
        #expect(origem.edicao == nil, "na raiz, o rascunho sai")
        #expect(!origem.temOQuePerder, "e o puxar da lista fecha sem perguntar")
    }

    @Test func salvarVoltaUmaVezComALinhaAcesa() {
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        origem.abrir(edicao().1, ordem: ["a", "b", "c"])
        origem.salvou(["a"])
        #expect(origem.caminho.isEmpty)
        #expect(origem.acesos == ["a"])
        #expect(origem.volta?.motivo == .salvou("a"))
        #expect(origem.volta?.vez == 1)
        #expect(!origem.editando("a"), "o segundo toque de um toque duplo já não grava")
        origem.salvou(["a"])
        origem.voltar()
        #expect(origem.volta?.vez == 1, "voltar de novo não faz nada (removeLast num caminho vazio derrubaria o app)")
        #expect(origem.caminho.isEmpty)
    }

    @Test func oValorEOsTopicosEmCimaDaEdicaoNaoPerdemNada() {
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        let (_, r) = edicao()
        origem.abrir(r, ordem: ["a"])
        origem.passosDaEdicao.append(.valor)
        #expect(origem.caminho == [.editar("a"), .valor])
        r.centavos = 12_345
        origem.voltarDoPasso(.valor)
        origem.voltarDoPasso(.valor)
        #expect(origem.caminho == [.editar("a")], "o segundo Pronto não volta além da edição")
        #expect(origem.edicao === r && r.centavos == 12_345, "voltar do valor não perde nada")
        origem.passosDaEdicao.append(.topicos)
        origem.voltarDoPasso(.valor)
        #expect(origem.caminho == [.editar("a"), .topicos], "só volta do passo que está no topo")
        #expect(origem.volta == nil, "nada voltou à raiz")
    }

    @Test func oGastoQueSumiuVoltaComOMotivo() {
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        origem.abrir(edicao().1, ordem: ["a", "b"])
        origem.sumiu("a")
        #expect(origem.volta?.motivo == .sumiu("a"))
        #expect(origem.caminho.isEmpty)
        origem.abrir(edicao().1, ordem: ["a", "b"])
        origem.voltar()
        #expect(origem.volta?.motivo == .voltou("a"), "o motivo de uma volta não fica para a seguinte")
        #expect(origem.volta?.vez == 2)
    }

    @Test func aEdicaoGravaSoAbertaNaFolhaOuNoTopoDaOrigem() {
        let folhas = Folhas()
        #expect(!SaidaDaEdicao.folha.aberta(folhas, gastoId: "a"), "a folha descendo")
        folhas.aberta = .editarGasto(obraId: "o1", gastoId: "a")
        #expect(SaidaDaEdicao.folha.aberta(folhas, gastoId: "a"))
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        origem.abrir(edicao().1, ordem: ["a"])
        #expect(SaidaDaEdicao.origem(origem).aberta(folhas, gastoId: "a"))
        origem.passosDaEdicao.append(.valor)
        #expect(!SaidaDaEdicao.origem(origem).aberta(folhas, gastoId: "a"), "com o valor em cima, a edição não está no topo")
        origem.voltarDoPasso(.valor)
        origem.salvou(["a"])
        #expect(!SaidaDaEdicao.origem(origem).aberta(folhas, gastoId: "a"), "voltando: o segundo toque não grava")
    }

    @Test func apagarDaEdicaoVoltaComOPedido() {
        let origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
        origem.abrir(edicao().1, ordem: ["a", "b"])
        let pedido = Folhas.PedidoDeApagar(obraId: "o1", gastoId: "a", grupoId: nil)
        origem.apagou(pedido)
        #expect(origem.volta?.motivo == .apagou(pedido), "a lista apaga a linha, à vista")
        #expect(origem.caminho.isEmpty)
        #expect(origem.edicao == nil)
    }

    @Test func focoDoVoiceOverDepoisDeApagar() {
        let antes = ["a", "b", "c"]
        #expect(focoNaOrigem(.apagou(["b"], compra: false), antes: antes, depois: ["a", "c"]) == FocoNaOrigem(alvo: .gasto("c"), anuncio: "Gasto apagado"))
        #expect(focoNaOrigem(.apagou(["c"], compra: false), antes: antes, depois: ["a", "b"]) == FocoNaOrigem(alvo: .gasto("b"), anuncio: "Gasto apagado"),
                "a última: a anterior")
        #expect(focoNaOrigem(.apagou(["b", "fora"], compra: true), antes: antes, depois: ["a", "c"])
                == FocoNaOrigem(alvo: .gasto("c"), anuncio: "Compra apagada"), "a compra toda, com parcelas fora da lista")
        #expect(focoNaOrigem(.apagou(["a"], compra: false), antes: ["a"], depois: []) == FocoNaOrigem(alvo: .vazio, anuncio: "Gasto apagado"),
                "o A pagar que fica vazio: o cartão do vazio")
    }

    @Test func focoDoVoiceOverNaVoltaDaEdicao() {
        let antes = ["a", "b", "c"]
        #expect(focoNaOrigem(.salvou("b"), antes: antes, depois: ["a", "c", "b"]) == FocoNaOrigem(alvo: .gasto("b"), anuncio: nil),
                "a linha salva, mesmo em outro lugar")
        #expect(focoNaOrigem(.salvou("b"), antes: antes, depois: ["a", "c"])
                == FocoNaOrigem(alvo: .gasto("c"), anuncio: "O gasto saiu desta lista."), "saiu da lista: a próxima")
        #expect(focoNaOrigem(.salvou("c"), antes: antes, depois: ["a", "b"]) == FocoNaOrigem(alvo: .gasto("b"), anuncio: "O gasto saiu desta lista."),
                "a última saiu: a anterior")
        #expect(focoNaOrigem(.salvou("a"), antes: ["a"], depois: []) == FocoNaOrigem(alvo: .vazio, anuncio: "O gasto saiu desta lista."),
                "a lista ficou vazia: o cartão do vazio")
        #expect(focoNaOrigem(.voltou("b"), antes: antes, depois: antes) == FocoNaOrigem(alvo: .gasto("b"), anuncio: nil),
                "sem salvar: a linha que abriu a edição")
        #expect(focoNaOrigem(.voltou("b"), antes: antes, depois: ["a", "c"]) == FocoNaOrigem(alvo: .gasto("c"), anuncio: nil),
                "sem salvar, com a linha fora da lista (mudou em outro aparelho): a vizinha, sem anúncio")
        #expect(focoNaOrigem(.sumiu("a"), antes: antes, depois: ["b", "c"]) == FocoNaOrigem(alvo: .gasto("b"), anuncio: "Gasto apagado"),
                "apagado em outro aparelho: a vizinha")
        #expect(focoNaOrigem(.salvou("b"), antes: ["a", "b", "c", "d"], depois: ["a", "d"]) == FocoNaOrigem(alvo: .gasto("d"), anuncio: "O gasto saiu desta lista."),
                "a vizinha é a próxima que ficou, pulando a que também saiu")
    }
    func gasto(_ id: String, _ data: String, _ valor: Double = 100) -> ValorJSON {
        .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto("outros"), "descricao": .texto(""), "data": .texto(data),
                 "pagamento": .texto("pix")])
    }

    func obra(_ gastos: [ValorJSON]) -> Obra {
        Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "gastos": .lista(gastos)])
    }

    @Test func pecasDoAPagarPorMesComOLugarNoGrupo() {
        // Hoje 12/10/26: três vencimentos em outubro e novembro, um hoje (fica fora) e um depois dos 30 dias (fica fora).
        let o = obra([gasto("c", "2026-11-06"), gasto("hoje", "2026-10-12"), gasto("a", "2026-10-15"), gasto("b", "2026-11-05"),
                      gasto("depois", "2026-11-12")])
        let pecas = pecasDaOrigem(aPagarDaObra(o, hoje: "2026-10-12").meses)
        #expect(pecas.map(\.id) == ["mes-2026-10", "a", "mes-2026-11", "b", "c"])
        #expect(pecas.map(\.primeiro) == [false, true, false, true, false], "o primeiro gasto do grupo vem sem a linha fina em cima")
        #expect(pecas.map(\.ultimo) == [false, true, false, false, true], "o último gasto do grupo leva os cantos de baixo")
    }

    @Test func pecasSemVencimentoNenhuma() {
        #expect(pecasDaOrigem(aPagarDaObra(obra([gasto("p", "2026-10-01")]), hoje: "2026-10-12").meses).isEmpty)
    }
}
