#if DEBUG
import Foundation
import notify

/// Testes de tela: com `CUSTTA_APAGAR_OBRA=aviso`, o apagar obra pelo lápis só grava quando o teste avisa (notify_post de
/// "br.com.custta.falso.apagarObra"). O meio segundo entre voltar à lista e gravar, em que o + já abre "Nova obra", fica
/// aberto o quanto o teste precisar; por relógio, o teste corria contra ele (mais lento na CI).
@MainActor
func esperarOAvisoDoTesteParaApagarObra() async {
    guard ProcessInfo.processInfo.environment["CUSTTA_APAGAR_OBRA"] == "aviso" else { return }
    await withCheckedContinuation { (avisado: CheckedContinuation<Void, Never>) in
        var token: Int32 = 0
        notify_register_dispatch("br.com.custta.falso.apagarObra", &token, .main) { t in
            notify_cancel(t)
            avisado.resume()
        }
    }
}
#endif
