import SwiftUI
import UIKit

/* A ponte do UIKit para rolar a obra até o gasto salvo. A obra é uma List (UICollectionView), e o scrollTo dela só acha a
   linha, que é o cartão do mês inteiro (na maior letra, um mês da obra pesada passa de 13 mil pt), e trata a âncora
   fracionária como o centro: a 1ª parcela de uma compra no cartão parava fora da tela. A ponte guarda uma marca (uma vista
   vazia) em cada linha acesa depois de salvar. Da marca, ela sobe até a rolagem que a contém, a da List; o quadro da marca,
   convertido para a rolagem, diz onde o gasto está no conteúdo, e a rolagem anda até o meio dele. A ponte tenta uma vez por
   quadro, até a lista parar de se medir, sem forçar o layout: um cartão gigante se mediria de novo, de uma vez, na thread
   principal.
   RISCO: a ponte depende de a List ser uma UICollectionView com as vistas da linha dentro dela, que é detalhe do SwiftUI. Se
   um iOS novo mudar isso, ela não acha a rolagem ou a marca e não rola: a lista fica no topo do cartão, e o teste da maior
   letra (GastoUITests) cai e avisa. */
@MainActor
final class PonteDaRolagem {
    private var marcas: [String: Fraca] = [:]

    private final class Fraca {
        weak var vista: UIView?
        init(_ vista: UIView) { self.vista = vista }
    }

    func marcar(_ vista: UIView, gasto: String) { marcas[gasto] = Fraca(vista) }

    /// A rolagem em que a marca do gasto está, se ela está na tela.
    private func rolagem(de gasto: String) -> (UIScrollView, UIView)? {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "custta.semPonte") { return nil }   // o caminho manso, para o teste que o reprova
        #endif
        guard let marca = marcas[gasto]?.vista, marca.window != nil else { return nil }
        var vista = marca.superview
        while let atual = vista, !(atual is UIScrollView) { vista = atual.superview }
        return (vista as? UIScrollView).map { ($0, marca) }
    }

    /// Tenta uma vez por quadro, até `quadros` vezes: quando a marca do gasto está na tela e a altura do conteúdo é a mesma
    /// em dois quadros seguidos (a lista parou de se medir), rola até o meio dele. Devolve se rolou; sem a marca, a lista
    /// fica onde está. Nada força o layout: a lista se mede no tempo dela.
    @discardableResult func rolarQuandoAssentar(ate gasto: String, quadros: Int, animado: Bool) async -> Bool {
        var anterior: CGFloat?
        for _ in 0..<quadros {
            try? await Task.sleep(for: .milliseconds(16))
            guard let (rolagem, marca) = rolagem(de: gasto) else { anterior = nil; continue }
            let altura = rolagem.contentSize.height
            if altura == anterior {
                let quadro = marca.convert(marca.bounds, to: rolagem)
                let y = deslocamentoAteOMeio(de: quadro, recuoDeCima: rolagem.adjustedContentInset.top,
                                             recuoDeBaixo: rolagem.adjustedContentInset.bottom, altura: rolagem.bounds.height,
                                             conteudo: altura)
                rolagem.setContentOffset(CGPoint(x: rolagem.contentOffset.x, y: y), animated: animado)
                return true
            }
            anterior = altura
        }
        return false
    }
}

/// O deslocamento da rolagem que põe o meio do quadro (na régua do conteúdo) no meio da parte à vista, entre os recuos de
/// cima e de baixo, preso ao começo e ao fim do conteúdo.
func deslocamentoAteOMeio(de quadro: CGRect, recuoDeCima: CGFloat, recuoDeBaixo: CGFloat, altura: CGFloat,
                          conteudo: CGFloat) -> CGFloat {
    let visivel = altura - recuoDeCima - recuoDeBaixo
    let comeco = -recuoDeCima
    let fim = max(comeco, conteudo + recuoDeBaixo - altura)
    return min(max(quadro.midY - recuoDeCima - visivel / 2, comeco), fim)
}

/// A marca de uma linha acesa: uma vista vazia no fundo da linha do gasto, que a ponte converte para a rolagem.
struct MarcaDaLinha: UIViewRepresentable {
    let ponte: PonteDaRolagem
    let gasto: String

    func makeUIView(context: Context) -> UIView {
        let vista = UIView()
        vista.isUserInteractionEnabled = false
        return vista
    }

    func updateUIView(_ uiView: UIView, context: Context) { ponte.marcar(uiView, gasto: gasto) }
}
