import SwiftUI
import AuthenticationServices
import CusttaNucleo

/* Peças das telas com a cara do PWA, escritas uma vez: campo sólido com rótulo, botões (principal,
   secundário, Apple e Google), mensagem com ícone, link sublinhado, divisor "ou", etiqueta de fase,
   barra de orçamento e a borda de rolagem. Cores só por token; textos com Dynamic Type, menos os botões
   da Apple e do Google, que não crescem (decisão do mockup) e mostram o Visualizador de Conteúdo Grande. */

/// Campo sólido do cartão de entrada: rótulo em cima, exemplo na cor secundária, olho na senha.
struct CampoDeEntrada: View {
    let rotulo: String
    var opcional = false
    let exemplo: String
    @Binding var texto: String
    let identificador: String
    var senha = false
    var invalido = false
    var tipo: UITextContentType?
    var teclado: UIKeyboardType = .default
    var maiusculas: TextInputAutocapitalization = .sentences
    /// Foco compartilhado pela tela, pela chave do campo (a mesma da validação: "email", "senha"…).
    var foco: FocusState<String?>.Binding
    let chave: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var mostrar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text(rotulo).foregroundStyle(paleta.cor(vidro.secundario))
             + Text(opcional ? " (opcional)" : "").foregroundStyle(paleta.cor(.textoTerciario)))
                .font(.footnote.weight(.medium))
                .accessibilityHidden(true)
                .padding(.vertical, 1)          // linha de 18 pt, a do rótulo no site e no mockup (o footnote ocupa 16)
            HStack(spacing: 8) {
                Group {
                    if senha && !mostrar {
                        SecureField(rotulo, text: $texto, prompt: Text(exemplo).foregroundStyle(paleta.cor(vidro.secundario)))
                    } else {
                        TextField(rotulo, text: $texto, prompt: Text(exemplo).foregroundStyle(paleta.cor(vidro.secundario)), axis: senha ? .horizontal : .vertical)
                    }
                }
                .textContentType(tipo)
                .keyboardType(teclado)
                .textInputAutocapitalization(maiusculas)
                .autocorrectionDisabled()
                .font(.body)
                .foregroundStyle(paleta.cor(.texto))
                .focused(foco, equals: chave)
                .accessibilityLabel(rotulo)
                .accessibilityIdentifier(identificador)
                if senha {
                    Button { mostrar.toggle() } label: {
                        Image(decorative: mostrar ? "Icones/olhoFechado" : "Icones/olho")
                            .resizable().frame(width: 20, height: 20)
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(mostrar ? "Esconder senha" : "Mostrar senha")
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, senha ? 2 : 13)
            .padding(.vertical, senha ? 2 : 11)
            .frame(minHeight: 48)
            .background(paleta.cor(.campo), in: .rect(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(paleta.cor(invalido ? .alerta : .campoBorda), lineWidth: 1))
        }
    }
}

/// Botão principal: sempre sólido, na cor da marca (como no site), com 52 pt como no mockup e no site. O
/// `pequeno` é o `.btn.peq` do mockup (aviso de e-mail, enviar confirmação): 48 pt, a favor do alvo de toque.
struct BotaoPrincipal: ButtonStyle {
    var pequeno = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(.sobreMarca))
            .frame(maxWidth: .infinity, minHeight: pequeno ? 48 : 52)
            .padding(.horizontal, 16)
            .background(paleta.cor(.marca), in: .capsule)
            .opacity(habilitado ? 1 : 0.6)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// Botão secundário do site ("ghost"): "Reenviar link", "Sair da conta". Mesmas alturas do principal.
struct BotaoSecundario: ButtonStyle {
    var pequeno = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(.fantasmaTexto))
            .frame(maxWidth: .infinity, minHeight: pequeno ? 48 : 52)
            .padding(.horizontal, 16)
            .background(paleta.cor(.fantasmaFundo), in: .capsule)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O botão oficial da Apple ("Continuar com a Apple"), branco no escuro e preto no claro, em cápsula.
struct BotaoApple: View {
    let pedir: (ASAuthorizationAppleIDRequest) -> Void
    let concluir: (Result<ASAuthorization, Error>) -> Void
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        SignInWithAppleButton(.continue, onRequest: pedir, onCompletion: concluir)
            .signInWithAppleButtonStyle(esquema == .dark ? .white : .black)
            .frame(height: 52)
            .clipShape(.capsule)
            .accessibilityIdentifier("entrarComApple")
    }
}

/// O botão do Google pelas regras do Google: cores fixas, Roboto Medium 14/20 e o G oficial.
struct BotaoGoogle: View {
    /// Texto confirmado pelo Giovani em 08/10. Se o Google pedir outro, troca aqui e no filtro de rótulo
    /// da `AuditoriaUITests`.
    static let texto = "Continuar com o Google"
    let acao: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 10) {
                Image(decorative: "LogoGoogle").resizable().frame(width: 18, height: 18)
                Text(Self.texto)
                    .font(.custom("Roboto-Medium", fixedSize: 14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(paleta.cor(.googleTexto))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(paleta.cor(.googleFundo), in: .capsule)
            .overlay(Capsule().strokeBorder(paleta.cor(.googleBorda), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.texto)
        .accessibilityShowsLargeContentViewer { Label(Self.texto, image: "LogoGoogle") }
        .accessibilityIdentifier("entrarComGoogle")
    }
}

/// Mensagem de um formulário: erro em vermelho, sucesso com ✓ na cor do link, sessão expirada com
/// cadeado neutro e atenção em âmbar (o site deixava sucesso e sessão expirada em vermelho).
struct Mensagem: View {
    enum Tipo { case erro, ok, cadeado, atencao }
    let tipo: Tipo
    let texto: String
    var identificador: String?
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        Label {
            Text(texto).foregroundStyle(paleta.cor(tipo == .erro ? .erroNoVidro : vidro.secundario))
        } icon: {
            Image(systemName: icone).foregroundStyle(paleta.cor(corDoIcone))
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(texto)
        .accessibilityIdentifier(identificador ?? "")
        .onAppear { AccessibilityNotification.Announcement(texto).post() }
    }

    private var icone: String {
        switch tipo {
        case .erro: return "exclamationmark.circle.fill"
        case .ok: return "checkmark.circle.fill"
        case .cadeado: return "lock.fill"
        case .atencao: return "exclamationmark.circle.fill"
        }
    }

    private var corDoIcone: Token {
        switch tipo {
        case .erro: return .erroNoVidro
        case .ok: return .linkNoVidro
        case .cadeado: return vidro.secundario
        case .atencao: return .alerta
        }
    }
}

/// Link solto: sublinhado, na cor do link sobre o vidro (no Transparente, a do texto com o traço da marca).
struct LinkSublinhado: ButtonStyle {
    var neutro = false
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(vidro.nivel == .transparente && !neutro ? .semibold : .regular))
            .foregroundStyle(paleta.cor(neutro ? vidro.secundario : vidro.link))
            .underline(true, color: paleta.cor(neutro ? vidro.secundario : .linkNoVidro))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// O "ou" entre os botões sociais e o e-mail.
struct DivisorOu: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(paleta.cor(.linha)).frame(height: 1)
            Text("ou").font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
            Rectangle().fill(paleta.cor(.linha)).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

/// Etiqueta da fase da obra, nas cores do site (âmbar, azul e verde).
struct EtiquetaDeFase: View {
    let fase: Fase
    @Environment(\.paleta) private var paleta

    var body: some View {
        let (texto, fundo): (Token, Token) = switch fase {
        case .construcao: (.alerta, .alertaFundo)
        case .pronta: (.informacao, .informacaoFundo)
        case .vendida: (.positivo, .positivoFundo)
        }
        Text(fase.rotulo)
            .font(.caption.weight(.semibold))
            .foregroundStyle(paleta.cor(texto))
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(paleta.cor(fundo), in: .capsule)
    }
}

/// Barra fina de progresso: degradê da marca, ou âmbar quando pede atenção.
struct BarraDeProgresso: View {
    let fracao: Double
    let atencao: Bool
    var altura: CGFloat = 6
    @Environment(\.paleta) private var paleta

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(paleta.cor(.texto).opacity(0.12))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(atencao ? AnyShapeStyle(paleta.cor(.alerta))
                                      : AnyShapeStyle(LinearGradient(colors: [paleta.cor(.marca), paleta.cor(.destaque)],
                                                                     startPoint: .leading, endPoint: .trailing)))
                        .frame(width: geo.size.width * min(1, max(0, fracao)))
                }
        }
        .frame(height: altura)
        .accessibilityHidden(true)
    }
}

/// Borda de rolagem suave, a mesma em todas as telas (mockup v2, decisão do Giovani em 09/10): a borda `.soft`
/// do iOS 26 desfoca aos poucos o que passa por baixo das barras, e o véu do tom do fundo (`VeuDaBorda`), mais
/// forte na beirada, some até 140 pt. A aurora e o conteúdo continuam aparecendo. No alto, só com conteúdo por
/// baixo (rolou mais de 40 pt, como no mockup); embaixo, só nas telas com a cápsula de abas.
struct BordaDeRolagem: ViewModifier {
    let abas: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho
    @State private var rolou = false

    func body(content: Content) -> some View {
        let veu = VeuDaBorda.opacidade(grande: tamanho.isAccessibilitySize, reduzirTransparencia: opcoes.reduzirTransparencia)
        content
            .scrollEdgeEffectStyle(.soft, for: .all)
            .scrollEdgeEffectHidden(opcoes.reduzirTransparencia, for: .all)
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 40 } action: { _, agora in
                rolou = agora
            }
            .overlay {
                VStack(spacing: 0) {
                    faixa(veu.topo, paradas: [(0, 1), (0.55, 0.85), (0.80, 0.4), (1, 0)], de: .top, ate: .bottom)
                        .opacity(rolou ? 1 : 0)
                        .animation(.easeOut(duration: 0.2), value: rolou)
                    Spacer(minLength: 0)
                    if abas { faixa(veu.base, paradas: [(0, 1), (0.50, 0.85), (0.78, 0.4), (1, 0)], de: .bottom, ate: .top) }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }

    private func faixa(_ a: Double, paradas: [(Double, Double)], de inicio: UnitPoint, ate fim: UnitPoint) -> some View {
        let fundo = paleta.cor(.fundo)
        return LinearGradient(stops: paradas.map { .init(color: fundo.opacity(a * $0.1), location: $0.0) },
                              startPoint: inicio, endPoint: fim)
            .frame(height: 140)
    }
}

extension View {
    /// A borda de rolagem suave da tela; `abas` liga a de baixo, sob a cápsula de abas.
    func bordaDeRolagem(abas: Bool) -> some View { modifier(BordaDeRolagem(abas: abas)) }
}
