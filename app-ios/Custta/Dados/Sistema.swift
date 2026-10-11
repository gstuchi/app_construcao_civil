import Foundation
import Network
import Observation
import UIKit
import CusttaNucleo

/// O Relogio do Sincronizador com a fila principal.
@MainActor
final class RelogioDoSistema: Relogio {
    private final class Tarefa: Cancelavel {
        let item: DispatchWorkItem
        init(_ item: DispatchWorkItem) { self.item = item }
        func cancelar() { item.cancel() }
    }

    var agoraMs: Int64 { agoraEmMilissegundos() }

    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel {
        let item = DispatchWorkItem { MainActor.assumeIsolated { acao() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(ms), execute: item)
        return Tarefa(item)
    }
}

/// Rede do aparelho (o navigator.onLine do site).
@MainActor @Observable
final class MonitorDeRede {
    private(set) var online: Bool
    @ObservationIgnored var aoMudar: ((Bool) -> Void)?
    @ObservationIgnored private let monitor = NWPathMonitor()

    /// `forcarSemRede`: só nos testes de tela, para abrir o app "em modo avião".
    init(forcarSemRede: Bool = false) {
        online = !forcarSemRede
        guard !forcarSemRede else { return }
        monitor.pathUpdateHandler = { [weak self] caminho in
            let ok = caminho.status == .satisfied
            Task { @MainActor in self?.atualizar(ok) }
        }
        monitor.start(queue: DispatchQueue(label: "br.com.custta.rede"))
    }

    private func atualizar(_ ok: Bool) {
        guard ok != online else { return }
        online = ok
        aoMudar?(ok)
    }
}

/// A janela do app, para quem precisa apresentar tela do sistema (login do Google).
@MainActor
func controladorNoTopo() -> UIViewController? {
    let janela = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows).first(where: \.isKeyWindow)
    var topo = janela?.rootViewController
    while let apresentado = topo?.presentedViewController { topo = apresentado }
    return topo
}
