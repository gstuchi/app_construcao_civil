import Foundation
import Observation

/* A folha aberta por cima das abas (o + da cápsula, o toque numa linha de gasto) e o que a tela da obra faz quando ela
   termina de descer: rolar até o gasto que acabou de entrar e acendê-lo, ou apagar com a animação à vista. Mora acima
   das abas, como o caminho de Obras, porque o + é da cápsula. */
@MainActor @Observable
final class Folhas {
    enum Qual: Identifiable, Hashable {
        case novoGasto(obraId: String)
        case editarGasto(obraId: String, gastoId: String)

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

    var aberta: Qual?
    private(set) var destaque: Destaque?
    private(set) var pedidoDeApagar: PedidoDeApagar?
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
}
