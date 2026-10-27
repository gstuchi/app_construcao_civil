import SwiftUI
import notify

#if DEBUG
/// Sonda da cena "A pagar, fim" do laudo no iOS 26 (27/10, temporária): com `-custta.sondaFim <variante>`, o app avisa o
/// teste por notify_post das paradas da thread principal (e do relógio fora dela) e de cada volta da rolagem fixa.
/// Variantes: `controle`, `semObraFixa` (a obra sem a rolagem fixa; a folha segue com a dela) e `semRolagem`.
enum SondaFim {
    static let variante = UserDefaults.standard.string(forKey: "custta.sondaFim") ?? ""
    static var semObraFixa: Bool { variante == "semObraFixa" }
    @MainActor private static var iniciada = false

    static func avisar(_ nome: String, _ estado: UInt64 = 0) {
        guard !variante.isEmpty else { return }
        let cheio = "br.com.custta.sondaFim.\(nome)"
        var token: Int32 = 0
        notify_register_check(cheio, &token)
        notify_set_state(token, estado)
        notify_cancel(token)
        notify_post(cheio)
    }

    @MainActor static func iniciar() {
        guard !variante.isEmpty, !iniciada else { return }
        iniciada = true
        Thread.detachNewThread {
            while true {
                let antes = Date.now
                Thread.sleep(forTimeInterval: 0.1)
                let ms = Date.now.timeIntervalSince(antes) * 1000 - 100
                if ms > 500 { avisar("congelou", UInt64(ms)) }
            }
        }
        Thread.detachNewThread {
            while true {
                let antes = Date.now
                let sinal = DispatchSemaphore(value: 0)
                DispatchQueue.main.async { sinal.signal() }
                sinal.wait()
                let ms = Date.now.timeIntervalSince(antes) * 1000
                if ms > 500 { avisar("parada", UInt64(ms)) }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}

extension View {
    /// A rolagem fixa da obra, ou nenhuma com `-custta.sondaFim semObraFixa`.
    @ViewBuilder func rolagemFixaDaObraComASondaFim() -> some View {
        if SondaFim.semObraFixa { self } else { modifier(RolagemFixaDoTeste(onde: 0)) }
    }
}
#endif
