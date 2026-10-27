import SwiftUI
import UIKit
import notify

/// Sonda do foco da busca no iOS 26 (27/10, temporária; run 40440188222: o teclado caiu durante a digitação do "cimen",
/// antes da mudança remota). Com `-custta.sondaFoco <variante>`, o app avisa o teste por notify_post: foco, campo, edição,
/// teclado, texto e paradas da thread principal. Variantes: `nenhum`, `vstack` (a obra num VStack, sem o LazyVStack),
/// `lento` (a thread principal parada 1,5 s a cada letra, como a VM lenta) e `lentoVstack`.
enum SondaFoco {
    static let variante = UserDefaults.standard.string(forKey: "custta.sondaFoco") ?? ""
    static var vstack: Bool { variante.lowercased().hasSuffix("vstack") }
    static var lento: Bool { variante.hasPrefix("lento") }
    static var semSoma: Bool { variante == "semSoma" }
    @MainActor private static var iniciada = false

    static func avisar(_ nome: String, _ estado: UInt64 = 0) {
        guard !variante.isEmpty else { return }
        let cheio = "br.com.custta.sonda.\(nome)"
        var token: Int32 = 0
        notify_register_check(cheio, &token)
        notify_set_state(token, estado)
        notify_cancel(token)
        notify_post(cheio)
    }

    @MainActor static func iniciar() {
        guard !variante.isEmpty, !iniciada else { return }
        iniciada = true
        let centro = NotificationCenter.default
        let avisos: [(Notification.Name, String, UInt64)] = [
            (UIResponder.keyboardWillShowNotification, "teclado.mostra", 0),
            (UIResponder.keyboardWillHideNotification, "teclado.esconde", 0),
            (UITextView.textDidBeginEditingNotification, "edicao.comeca", 0),
            (UITextView.textDidEndEditingNotification, "edicao.acaba", 0),
            (UITextField.textDidBeginEditingNotification, "edicao.comeca", 1),
            (UITextField.textDidEndEditingNotification, "edicao.acaba", 1),
        ]
        for (nome, aviso, estado) in avisos {
            centro.addObserver(forName: nome, object: nil, queue: .main) { _ in avisar(aviso, estado) }
        }
        // O relógio, numa thread que não depende da principal: se ele também atrasa, quem parou foi a VM, e não o app.
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

    /// `lento`: a thread principal parada 1,5 s a cada letra.
    @MainActor static func pararSeLento() { if lento { Thread.sleep(forTimeInterval: 1.5) } }
}

/// A pilha da obra: o LazyVStack de sempre, ou um VStack com `-custta.sondaFoco vstack`.
struct PilhaDaObra<Conteudo: View>: View {
    let conteudo: Conteudo
    init(@ViewBuilder conteudo: () -> Conteudo) { self.conteudo = conteudo() }
    var body: some View {
        if SondaFoco.vstack {
            VStack(alignment: .leading, spacing: 10) { conteudo }
        } else {
            LazyVStack(alignment: .leading, spacing: 10) { conteudo }
        }
    }
}
