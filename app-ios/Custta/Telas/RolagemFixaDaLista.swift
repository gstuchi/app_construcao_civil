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
    private static var observacoes: [NSKeyValueObservation] = []
    /// Uma vez por abertura do app: a obra que volta à tela não rola de novo.
    private static var feito = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // O argumento de lançamento chega como texto ("400"): o double(forKey:) o converte.
        let pedida = UserDefaults.standard.object(forKey: "custta.rolagem") != nil
        let y = UserDefaults.standard.double(forKey: "custta.rolagem")
        guard window != nil, !Self.feito, pedida, y >= 0 else { return }
        var vista: UIView? = superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        guard let lista = vista as? UICollectionView else { return }
        Self.feito = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            // Um passo por quadro: a lista mede as linhas por onde passou no tempo dela, sem layout forçado.
            var atual = lista.contentOffset.y
            let alvo = y - lista.adjustedContentInset.top
            while atual < alvo {
                atual = min(alvo, atual + lista.bounds.height / 2)
                lista.setContentOffset(CGPoint(x: 0, y: atual), animated: false)
                try? await Task.sleep(for: .milliseconds(16))
            }
            lista.setContentOffset(CGPoint(x: 0, y: alvo), animated: false)
            Self.segurar(lista, y: y)
        }
    }

    /// Segura a linha que ficou no alto da parte à vista, no mesmo ponto dela, até alguém arrastar. Não segura o número:
    /// quando os dados mudam (a busca, o filtro do mês), a List volta as linhas de cima da tela à altura estimada, e o UIKit
    /// compensa a rolagem para a tela não pular. Segurando o número, a busca de "achados" ia parar 300 pt abaixo da pílula. A
    /// linha do alto também desfaz o que mexe na rolagem sozinho (a ponte, o scrollTo, a volta ao topo do iOS 26), como o
    /// gancho da ScrollView. O ponto é a fração da linha, e não os pontos dentro dela: a auditoria troca a letra, e, na letra
    /// padrão, uma folga em pontos passava do fim da linha e mostrava outras, que a auditoria perdia ("sem elemento").
    private static func segurar(_ lista: UICollectionView, y: Double) {
        let topo = lista.contentOffset.y + lista.adjustedContentInset.top
        let ancora = lista.indexPathsForVisibleItems
            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } }
            .filter { $0.1.maxY > topo }
            .min { $0.1.minY < $1.1.minY }
        let indice = ancora?.0
        let fracao = ancora.map { max(0, topo - $0.1.minY) / max(1, $0.1.height) } ?? 0
        observacoes = [
            lista.observe(\.contentOffset, options: [.new]) { rolada, _ in
                MainActor.assumeIsolated { ajustar(rolada, y: y, ancora: indice, fracao: fracao) }
            },
            lista.observe(\.contentSize, options: [.new]) { rolada, _ in
                MainActor.assumeIsolated { ajustar(rolada, y: y, ancora: indice, fracao: fracao) }
            },
        ]
    }

    private static func ajustar(_ lista: UICollectionView, y: Double, ancora: IndexPath?, fracao: CGFloat) {
        if lista.isTracking || lista.isDragging { observacoes = []; return }
        var topo = CGFloat(y)
        if let indice = ancora, indice.section < lista.numberOfSections,
           indice.item < lista.numberOfItems(inSection: indice.section),
           let quadro = lista.layoutAttributesForItem(at: indice)?.frame {
            topo = quadro.minY + fracao * quadro.height
        }
        // Preso ao fim do conteúdo, como o scrollTo(y:) da ScrollView: a busca que acha pouco encolhe a lista.
        let cima = lista.adjustedContentInset.top
        let fim = max(-cima, lista.contentSize.height + lista.adjustedContentInset.bottom - lista.bounds.height)
        let alvo = min(topo - cima, fim)
        if abs(lista.contentOffset.y - alvo) > 0.5 { lista.contentOffset.y = alvo }
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
