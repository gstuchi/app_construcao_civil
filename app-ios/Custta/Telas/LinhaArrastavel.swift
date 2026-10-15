import SwiftUI
import UIKit

/* Arrastar a linha de gasto para a esquerda mostra "Apagar" (conselho de 13/10, decisão a). O .swipeActions do sistema
   só existe dentro de List, e a List não desenha um cartão de vidro por mês (vira um vidro por linha, com emenda); o
   swipeActionsContainer do iOS 27 ignora a cor e não compila no Xcode da CI. Por isso o arrastar é próprio, com a física
   da List: só começa num arrasto mais horizontal que vertical, para a esquerda (para a direita só com a linha aberta);
   os 20 pt da borda esquerda ficam com o voltar do sistema; a linha abre em −96 pt (o botão de 80, 10 da borda e 6 até a linha, como o mockup), estica
   com resistência além disso, decide no soltar pela posição projetada com o impulso (gestos.js) e assenta numa mola sem
   quique que parte da velocidade do dedo. Vibra uma vez ao passar de −40 pt. Nunca apaga no arrasto até o fim: o botão
   pergunta antes. Tocar com uma linha aberta só fecha; rolar fecha. */

struct LinhaArrastavel<Conteudo: View>: View {
    let id: String
    @Binding var aberta: String?
    let apagar: () -> Void
    @ViewBuilder let conteudo: () -> Conteudo
    @State private var arrasto: CGFloat = 0
    @State private var passou = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    /// O botão cresce com a letra até o tamanho AX2 (mockup: "Apagar" de 13 pt num botão de 80).
    @ScaledMetric(relativeTo: .footnote) private var larguraDoBotao: CGFloat = 80

    private var largura: CGFloat { min(larguraDoBotao, 120) }
    private var revelado: CGFloat { largura + 16 }
    static var limiar: CGFloat { 40 }

    var body: some View {
        let estaAberta = aberta == id
        let x = posicao(base: estaAberta ? -revelado : 0, arrasto: arrasto)
        ZStack(alignment: .trailing) {
            if x < 0 {
                Button(action: apagar) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash").font(.subheadline.weight(.semibold))
                        Text("Apagar").font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(paleta.cor(.sobreApagar))
                    .frame(width: largura)
                    .frame(maxHeight: .infinity)
                    .background(paleta.cor(.apagar), in: .rect(cornerRadius: 22, style: .continuous))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .padding(.trailing, 10)
                .opacity(min(1, -x / 70))
                .accessibilityLabel("Apagar")
                .accessibilityIdentifier("apagar-\(id)")
            }
            conteudo()
                .background(x < 0 ? paleta.cor(.linhaDaFolha) : .clear)
                .offset(x: x)
                .accessibilityAction(named: "Apagar", apagar)
        }
        .clipped()
        .gesture(ArrastoParaApagar(aberta: estaAberta, mudou: { t in
            arrasto = t
            let alem = !estaAberta && posicao(base: 0, arrasto: t) < -Self.limiar
            if alem != passou { passou = alem }
        }, terminou: { t, velocidade in soltar(t, velocidade: velocidade, estavaAberta: estaAberta) }))
        .sensoryFeedback(.impact(weight: .medium), trigger: passou) { antes, agora in agora && !antes }
    }

    /// A posição da linha: até −revelado acompanha o dedo; além, estica com um quarto do arrasto; nunca passa de 0.
    private func posicao(base: CGFloat, arrasto: CGFloat) -> CGFloat {
        let p = base + arrasto
        if p > 0 { return 0 }
        if p < -revelado { return -revelado + (p + revelado) * 0.25 }
        return p
    }

    private func soltar(_ t: CGFloat, velocidade: CGFloat, estavaAberta: Bool) {
        let p = posicao(base: estavaAberta ? -revelado : 0, arrasto: t)
        // O ponto final projetado com o impulso (taxa 0,995 por ms, como o gestos.js): ~0,2 s de velocidade.
        let abrir = -(p + velocidade * 0.199) > Self.limiar
        let alvo: CGFloat = abrir ? -revelado : 0
        let distancia = alvo - p
        // A mola parte da velocidade do dedo, medida em "distâncias por segundo" (o que a API pede); só a favor do alvo
        // e limitada, para um arremesso não atravessar o botão.
        let inicial = distancia == 0 ? 0 : min(max(velocidade / distancia, 0), 15)
        let animacao: Animation = opcoes.reduzirMovimento ? .easeOut(duration: 0.2)
            : .interpolatingSpring(Spring(duration: 0.3, bounce: 0), initialVelocity: inicial)
        withAnimation(animacao) {
            arrasto = 0
            if abrir { aberta = id } else if aberta == id { aberta = nil }
        }
        passou = false
    }
}

/// O pan do UIKit: começa só num arrasto mais horizontal que vertical (|dx| > 1,2·|dy|, como o gestos.js), para a
/// esquerda (para a direita só com a linha aberta, para fechar) e fora dos 20 pt da borda esquerda (o voltar do
/// sistema). Vertical fica com a rolagem.
struct ArrastoParaApagar: UIGestureRecognizerRepresentable {
    let aberta: Bool
    let mudou: (CGFloat) -> Void
    let terminou: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordenador { Coordenador() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        context.coordinator.aberta = aberta
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.aberta = aberta
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let t = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed: mudou(t)
        case .ended: terminou(t, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed: terminou(0, 0)
        default: break
        }
    }

    @MainActor final class Coordenador: NSObject, UIGestureRecognizerDelegate {
        var aberta = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            if let janela = pan.view?.window, pan.location(in: janela).x < 20 { return false }
            let v = pan.velocity(in: pan.view)
            guard abs(v.x) > abs(v.y) * 1.2 else { return false }
            return v.x < 0 || aberta
        }
    }
}
