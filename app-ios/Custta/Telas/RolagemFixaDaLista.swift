#if DEBUG
import SwiftUI
import UIKit

/* O gancho `-custta.rolagem` dos testes de tela (laudo, auditoria, prints) na obra, que é uma List: o `.scrollPosition` da
   RolagemFixaDoTeste não rola a List (UICollectionView). Uma vista vazia no fundo da 1ª linha acha a rolagem acima dela, põe
   o deslocamento pedido, na régua do gancho da ScrollView (y = contentOffset.y + o recuo de cima ajustado), e o segura até
   alguém arrastar: no iOS 26, a lista às vezes volta sozinha ao topo depois de rolada (RolagemFixaDoTeste). A List só mede
   as linhas por onde passa, e as outras ficam na altura estimada: um salto direto a 2.600 pt caía além do conteúdo estimado
   ao abrir (2.063 pt), no vazio. Por isso a rolagem vai em passos de meia tela, um por quadro. */
struct RolagemFixaDaLista: UIViewRepresentable {
    func makeUIView(context: Context) -> AncoraDaRolagemFixa { AncoraDaRolagemFixa() }
    func updateUIView(_ uiView: AncoraDaRolagemFixa, context: Context) {}
}

final class AncoraDaRolagemFixa: UIView {
    /// Fora da instância: a célula da 1ª linha sai da tela, e a âncora com ela, e o gancho segue segurando.
    private static var observacao: NSKeyValueObservation?
    /// Uma vez por abertura do app: a obra que volta à tela não rola de novo.
    private static var feito = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // O argumento de lançamento chega como texto ("400"): o double(forKey:) o converte.
        let pedida = UserDefaults.standard.object(forKey: "custta.rolagem") != nil
        let y = UserDefaults.standard.double(forKey: "custta.rolagem")
        guard window != nil, !Self.feito, pedida, y >= 0 else { return }
        var vista: UIView? = superview
        while let atual = vista, !(atual is UIScrollView) { vista = atual.superview }
        guard let rolagem = vista as? UIScrollView else { return }
        Self.feito = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            // Um passo por quadro: a lista mede as linhas por onde passou no tempo dela, sem layout forçado.
            var atual = rolagem.contentOffset.y
            let alvo = y - rolagem.adjustedContentInset.top
            while atual < alvo {
                atual = min(alvo, atual + rolagem.bounds.height / 2)
                rolagem.setContentOffset(CGPoint(x: 0, y: atual), animated: false)
                try? await Task.sleep(for: .milliseconds(16))
            }
            rolagem.setContentOffset(CGPoint(x: 0, y: alvo), animated: false)
            Self.observacao = rolagem.observe(\.contentOffset, options: [.new]) { rolada, _ in
                MainActor.assumeIsolated {
                    if rolada.isTracking || rolada.isDragging { AncoraDaRolagemFixa.observacao = nil; return }
                    let alvo = y - rolada.adjustedContentInset.top
                    if abs(rolada.contentOffset.y - alvo) > 0.5 { rolada.contentOffset.y = alvo }
                }
            }
        }
    }
}

extension View {
    /// O gancho da rolagem fixa na obra: só com o `-custta.rolagem` e sem folha na cena. Na cena que abre uma folha
    /// (`CUSTTA_FOLHA`), a rolagem é só da folha, como na `rolagemFixaSemFolha` das telas em ScrollView.
    @ViewBuilder func rolagemFixaDaLista() -> some View {
        let pedida = UserDefaults.standard.object(forKey: "custta.rolagem") != nil
        let comFolha = ProcessInfo.processInfo.environment["CUSTTA_FOLHA"] != nil
        if pedida && !comFolha { background { RolagemFixaDaLista().frame(width: 0, height: 0) } } else { self }
    }
}
#endif
