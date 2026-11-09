#if DEBUG
import UIKit
import notify

/// Testes de tela: com `CUSTTA_TROCA_LETRA=aviso`, cada aviso do teste (notify_post de "br.com.custta.falso.trocarLetra")
/// troca o Tamanho do Texto do app, como a pessoa pela Central de Controle: o 1º põe a letra padrão por cima da do
/// lançamento, o 2º tira, e assim por diante. A troca é pelo traço da cena, que chega ao UIKit e ao SwiftUI como a do sistema.
@MainActor
enum TrocaDeLetraDoTeste {
    private static var padrao = false

    static func vigiar() {
        guard ProcessInfo.processInfo.environment["CUSTTA_TROCA_LETRA"] == "aviso" else { return }
        var token: Int32 = 0
        notify_register_dispatch("br.com.custta.falso.trocarLetra", &token, .main) { _ in
            MainActor.assumeIsolated { trocar() }
        }
    }

    private static func trocar() {
        padrao.toggle()
        for case let cena as UIWindowScene in UIApplication.shared.connectedScenes {
            if padrao {
                cena.traitOverrides.preferredContentSizeCategory = .large
            } else {
                cena.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
            }
        }
    }
}
#endif
