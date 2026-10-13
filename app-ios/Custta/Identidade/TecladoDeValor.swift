import SwiftUI
import CusttaNucleo

/* O teclado de valor (teclado.js, mockup da etapa 2, parte 2): centavos entram pela direita, "00" e apagar, teto de
   R$ 99.999.999,99 (a tecla que passaria do teto é ignorada). As teclas vêm na ordem do telefone, 1 2 3 em cima
   (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda, ao valor estimado e ao orçamento: quem usa
   dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero, como no site. */
struct TecladoDeValor: View {
    @Binding var centavos: Int
    let acao: String
    let confirmar: () -> Void
    @Environment(\.paleta) private var paleta

    private static let linhas: [[TeclaDeValor]] = [
        [.digito(1), .digito(2), .digito(3)],
        [.digito(4), .digito(5), .digito(6)],
        [.digito(7), .digito(8), .digito(9)],
        [.duploZero, .digito(0), .apagar],
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VisorDoValor(centavos: centavos)
            Spacer(minLength: 12)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(Self.linhas.indices, id: \.self) { i in
                    GridRow {
                        ForEach(Self.linhas[i], id: \.nome) { tecla in
                            // A letra das teclas cresce até o AX2 (mockup): o limite fica por fora, para a medida de dentro
                            // (@ScaledMetric) já ler o tamanho limitado.
                            TeclaDoValor(tecla: tecla) { tocar(tecla) }
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                    }
                }
            }
            Button(acao, action: confirmar)
                .buttonStyle(BotaoDaFolha())
                .disabled(centavos == 0)
                .padding(.top, 14)
                .accessibilityIdentifier("confirmarValor")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tocar(_ tecla: TeclaDeValor) {
        let novo = aplicarTecla(centavos, tecla)
        guard novo != centavos else { return }
        centavos = novo
        // VoiceOver: o visor é um elemento só; a cada tecla, o valor novo é falado.
        AccessibilityNotification.Announcement(fmtCentavos(novo)).post()
    }
}

/// "R$" e o valor, centrados; o número encolhe para caber (R$ 1.380.000,00 não cabia em 64 pt). Zero fica apagado.
struct VisorDoValor: View {
    let centavos: Int
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Tamanhos fixos de propósito (mockup): o número de 64 pt já passa do texto na maior letra e encolhe para caber;
            // os identificadores levam a exceção da auditoria de tipo dinâmico, que olha cada texto.
            Text("R$")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(paleta.cor(.textoSecundario))
                .accessibilityIdentifier("visorDoValor-rs")
            Text(fmtCentavos(centavos))
                .font(.system(size: 64, weight: .bold).monospacedDigit())
                .foregroundStyle(paleta.cor(centavos == 0 ? .textoTerciario : .texto))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .accessibilityIdentifier("visorDoValor-numero")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Valor")
        .accessibilityValue("R$ \(fmtCentavos(centavos))")
        .accessibilityIdentifier("visorDoValor")
    }
}

/// Uma tecla: 62 pt de altura, raio 20, na cor Tecla; encolhe e acende no toque. A letra (30) e a altura crescem com o
/// tamanho de letra, como o .title; quem usa limita no AX2 (mockup). Com a letra fixa, o limite não faria nada.
struct TeclaDoValor: View {
    let tecla: TeclaDeValor
    let tocar: () -> Void
    @Environment(\.paleta) private var paleta
    @ScaledMetric(relativeTo: .title) private var letra: CGFloat = 30
    @ScaledMetric(relativeTo: .title) private var simbolo: CGFloat = 26
    @ScaledMetric(relativeTo: .title) private var altura: CGFloat = 62

    var body: some View {
        Button(action: tocar) {
            Group {
                switch tecla {
                case .apagar: Image(systemName: "delete.left").font(.system(size: simbolo, weight: .regular))
                case .duploZero: Text("00")
                case .digito(let d): Text(String(d))
                }
            }
            .font(.system(size: letra, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: altura)
        }
        .buttonStyle(EstiloDaTecla())
        .accessibilityLabel(rotulo)
        .accessibilityIdentifier("tecla-\(tecla.nome)")
    }

    private var rotulo: String {
        switch tecla {
        case .apagar: "Apagar"
        case .duploZero: "zero zero"
        case .digito(let d): String(d)
        }
    }
}

private struct EstiloDaTecla: ButtonStyle {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(paleta.cor(.texto))
            .background(paleta.cor(configuration.isPressed ? .teclaTocada : .tecla), in: .rect(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.96 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O botão grande da folha ("Avançar", "Salvar", "Confirmar venda"): 56 pt, raio 28, na Marca; desabilitado, apagado.
/// `ambar` é o "Salvar mesmo assim" do gasto repetido.
struct BotaoDaFolha: ButtonStyle {
    var ambar = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        let fundo: Color = !habilitado ? paleta.cor(.texto).opacity(0.12) : paleta.cor(ambar ? .alerta : .marca)
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(!habilitado ? .textoTerciario : ambar ? .sobreAlerta : .sobreMarca))
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 16)
            .background(fundo, in: .capsule)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}
