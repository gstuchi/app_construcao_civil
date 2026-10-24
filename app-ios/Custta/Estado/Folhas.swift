import Foundation
import Observation

/* A folha aberta por cima das abas (o + da cápsula, o toque numa linha de gasto, o lápis e as ações da obra) e o que as
   telas fazem quando ela termina de descer: rolar até o gasto que acabou de entrar e acendê-lo, apagar com a animação à
   vista, entrar na obra criada ou voltar à lista e apagar a obra. Mora acima das abas, como o caminho de Obras, porque o
   + é da cápsula. */
@MainActor @Observable
final class Folhas {
    enum Qual: Identifiable, Hashable {
        case novoGasto(obraId: String)
        case editarGasto(obraId: String, gastoId: String)
        /// O + numa obra vendida: o gasto vai para uma obra aberta, escolhida na linha "Obra" da folha.
        case gastoDeVendida(vendidaId: String)
        case novaObra
        case editarObra(obraId: String)
        case venda(obraId: String)
        /// "Orçamento da obra" (etapa 3): o "Definir orçamento" da obra e o lápis da tela Orçamento.
        case orcamento(obraId: String)
        /// A seta do indicador "A pagar · 30 dias": os vencimentos da obra por mês (etapa 3).
        case aPagar(obraId: String)
        /// Uma linha da tela Orçamento: o detalhe do tópico, com o resumo e os gastos dele (etapa 3).
        case topico(obraId: String, topicoId: String)

        var id: Self { self }
    }

    /// O que a tela da obra mostra depois de salvar: os gastos que entraram (acendem por 2 s; `novo` põe a etiqueta) e o
    /// primeiro deles (a lista rola até ele). `vez` muda a cada salvar, para o mesmo gasto acender de novo.
    struct Destaque: Equatable {
        let ids: [String]
        let novo: Bool
        let vez: Int
    }

    /// "Apagar gasto" confirmado na folha de edição: a tela da obra apaga quando a folha termina de descer, com a mesma
    /// animação do arrastar. `grupoId` apaga a compra toda.
    struct PedidoDeApagar: Equatable {
        let obraId: String
        let gastoId: String
        let grupoId: String?
        var vez = 0
    }

    /// Para onde Obras vai por causa de uma folha.
    enum Navegacao: Equatable {
        /// Entra na obra (a que acabou de ser criada), com o push do sistema, depois que a folha desce.
        case entrar(String)
        /// Troca a obra aberta sem animação, por trás da folha: o gasto lançado de dentro de uma vendida foi para outra, e
        /// a folha desce mostrando a obra que o recebeu.
        case trocar(String)
        /// Volta à lista e só então apaga a obra, para a linha sair com a animação à vista.
        case apagar(String)
        /// O orçamento saiu (tirado na folha): a tela Orçamento, por trás da folha, volta para a obra.
        case sairDoOrcamento(String)
    }

    struct PedidoDeNavegacao: Equatable {
        let navegacao: Navegacao
        let vez: Int
    }

    var aberta: Qual?
    private(set) var destaque: Destaque?
    private(set) var pedidoDeApagar: PedidoDeApagar?
    private(set) var navegacao: PedidoDeNavegacao?
    @ObservationIgnored private var depoisDeFechar: (() -> Void)?
    @ObservationIgnored private var vezes = 0

    /// Fecha a folha; `depois` roda quando ela terminar de descer (o onDismiss da .sheet).
    func fechar(depois: (() -> Void)? = nil) {
        depoisDeFechar = depois
        aberta = nil
    }

    /// O onDismiss da .sheet.
    func fechou() {
        let f = depoisDeFechar
        depoisDeFechar = nil
        f?()
    }

    func destacar(_ ids: [String], novo: Bool) {
        vezes += 1
        destaque = Destaque(ids: ids, novo: novo, vez: vezes)
    }

    func apagar(_ pedido: PedidoDeApagar) {
        vezes += 1
        var p = pedido
        p.vez = vezes
        pedidoDeApagar = p
    }

    func navegar(_ n: Navegacao) {
        vezes += 1
        navegacao = PedidoDeNavegacao(navegacao: n, vez: vezes)
    }
}
