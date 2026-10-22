import SwiftUI
import CusttaNucleo

/* O teclado de valor (teclado.js, mockup da etapa 2, parte 2): centavos entram pela direita, "00" e apagar, teto de
   R$ 99.999.999,99 (a tecla que passaria do teto é ignorada). As teclas vêm na ordem do telefone, 1 2 3 em cima
   (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda e ao valor estimado e ao orçamento da obra
   nova: quem usa dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero,
   como no site; nos valores opcionais da obra (valor estimado e orçamento), zero vale: é como apagar o valor. As teclas
   são a GradeDeTeclas, a mesma das teclas encaixadas da folha do orçamento (etapa 3). */
struct TecladoDeValor: View {
    @Binding var centavos: Int
    let acao: String
    var permiteZero = false
    let confirmar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VisorDoValor(centavos: centavos)
            Spacer(minLength: 12)
            Spacer(minLength: 0)
            GradeDeTeclas(centavos: $centavos, tamanho: .padrao)
            Button(acao, action: confirmar)
                .buttonStyle(BotaoDaFolha())
                .disabled(centavos == 0 && !permiteZero)
                .padding(.top, 16)
                .accessibilityIdentifier("confirmarValor")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
    }
}

/// O tamanho das teclas: o do TecladoDeValor, que ocupa a folha, e o das teclas encaixadas embaixo da folha do orçamento
/// (mockup da etapa 3, `.kv`). As duas crescem com a letra até o AX2.
enum TamanhoDasTeclas: Sendable {
    /// Teclas de 62 pt (até 72 na letra grande), raio 20, 10 de vão, letra de 30.
    case padrao
    /// Teclas de 50 pt (até 64 na letra grande), raio 17, 8 de vão, letra de 27.
    case encaixado

    var altura: CGFloat { self == .padrao ? 62 : 50 }
    var alturaMaxima: CGFloat { self == .padrao ? 72 : 64 }
    var raio: CGFloat { self == .padrao ? 20 : 17 }
    var vao: CGFloat { self == .padrao ? 10 : 8 }
    var letra: CGFloat { self == .padrao ? 30 : 27 }
    var simbolo: CGFloat { self == .padrao ? 26 : 24 }
}

/// As doze teclas do teclado de valor e o que cada uma faz com os centavos: a regra do núcleo (o teto e a tecla ignorada) e
/// o valor novo falado pelo VoiceOver a cada tecla. Serve ao TecladoDeValor e ao TecladoEncaixado.
struct GradeDeTeclas: View {
    @Binding var centavos: Int
    let tamanho: TamanhoDasTeclas

    static let linhas: [[TeclaDeValor]] = [
        [.digito(1), .digito(2), .digito(3)],
        [.digito(4), .digito(5), .digito(6)],
        [.digito(7), .digito(8), .digito(9)],
        [.duploZero, .digito(0), .apagar],
    ]

    var body: some View {
        Grid(horizontalSpacing: tamanho.vao, verticalSpacing: tamanho.vao) {
            ForEach(Self.linhas.indices, id: \.self) { i in
                GridRow {
                    ForEach(Self.linhas[i], id: \.nome) { tecla in
                        // A letra das teclas cresce até o AX2 (mockup): o limite fica por fora, para a medida de dentro
                        // (@ScaledMetric) já ler o tamanho limitado.
                        TeclaDoValor(tecla: tecla, tamanho: tamanho) { tocar(tecla) }
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    }
                }
            }
        }
    }

    private func tocar(_ tecla: TeclaDeValor) {
        let novo = aplicarTecla(centavos, tecla)
        guard novo != centavos else { return }
        centavos = novo
        // VoiceOver: o valor (o visor ou a linha) é um elemento só; a cada tecla, o valor novo é falado.
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
                .foregroundStyle(paleta.cor(.secundarioTransparente))
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

/// Uma tecla: 62 pt de altura, raio 20, na cor Tecla (encaixada, 50 e raio 17); encolhe e acende no toque. A letra (30;
/// encaixada, 27) e a altura crescem com o tamanho de letra, como o .title; quem usa limita no AX2 (mockup). Com a letra
/// fixa, o limite não faria nada. A altura para em 72 (encaixada, 64), a do mockup na AX5: as quatro fileiras cabem com o
/// visor e o botão (encaixada, com a barra e um pedaço da lista à vista).
struct TeclaDoValor: View {
    let tecla: TeclaDeValor
    let tamanho: TamanhoDasTeclas
    let tocar: () -> Void
    @Environment(\.paleta) private var paleta
    @ScaledMetric private var letra: CGFloat
    @ScaledMetric private var simbolo: CGFloat
    @ScaledMetric private var altura: CGFloat

    init(tecla: TeclaDeValor, tamanho: TamanhoDasTeclas = .padrao, tocar: @escaping () -> Void) {
        self.tecla = tecla
        self.tamanho = tamanho
        self.tocar = tocar
        _letra = ScaledMetric(wrappedValue: tamanho.letra, relativeTo: .title)
        _simbolo = ScaledMetric(wrappedValue: tamanho.simbolo, relativeTo: .title)
        _altura = ScaledMetric(wrappedValue: tamanho.altura, relativeTo: .title)
    }

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
            .frame(maxWidth: .infinity, minHeight: min(altura, tamanho.alturaMaxima))
        }
        .buttonStyle(EstiloDaTecla(raio: tamanho.raio))
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
    let raio: CGFloat
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(paleta.cor(.texto))
            .background(paleta.cor(configuration.isPressed ? .teclaTocada : .tecla), in: .rect(cornerRadius: raio, style: .continuous))
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.96 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O botão grande da folha ("Avançar", "Salvar", "Confirmar venda"): 56 pt, raio 28, na Marca; desabilitado, apagado.
/// Na letra grande, 72 pt no mínimo, com 8 de recuo em cima e embaixo e 20 dos lados (o `.btn-f` do mockup na AX5).
/// `ambar` é o "Salvar mesmo assim" do gasto repetido.
struct BotaoDaFolha: ButtonStyle {
    var ambar = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.isEnabled) private var habilitado
    @Environment(\.dynamicTypeSize) private var tamanho

    func makeBody(configuration: Configuration) -> some View {
        let fundo: Color = !habilitado ? paleta.cor(.texto).opacity(0.12) : paleta.cor(ambar ? .alerta : .marca)
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(!habilitado ? .textoTerciario : ambar ? .sobreAlerta : .sobreMarca))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: tamanho.isAccessibilitySize ? 72 : 56)
            .padding(.horizontal, tamanho.isAccessibilitySize ? 20 : 16)
            .background(fundo, in: .capsule)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}
