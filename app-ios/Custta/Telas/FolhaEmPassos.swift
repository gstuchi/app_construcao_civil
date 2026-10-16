import SwiftUI
import UIKit

/* A folha do sistema com passos (conselho de 13/10, decisão b): um NavigationStack dentro da .sheet, com o voltar e o
   gesto da borda do sistema; o × fecha, à esquerda na raiz e à direita nos passos de dentro (o voltar fica à esquerda);
   o título em duas linhas na barra; o fundo na Folha. Quando há o que perder, fechar pergunta antes, por qualquer
   caminho: o ×, puxar a folha para baixo (a ponte para o "tentou fechar" do UIKit, que o SwiftUI não expõe) e o gesto
   de escapar do VoiceOver (Z com dois dedos) na raiz. Serve ao gasto, à venda e à obra. Os círculos da barra são o vidro
   do sistema, não os sólidos do mockup: com eles vem o voltar pela borda (exceção levada ao Giovani). */

/// O que um passo da folha chama para fechar: pergunta antes, se houver o que perder.
struct PedidoDeFechar {
    let pedir: () -> Void
    func callAsFunction() { pedir() }
}

extension EnvironmentValues {
    @Entry var pedirParaFechar = PedidoDeFechar {}
}

extension View {
    /// Em volta do NavigationStack da folha: a Folha de fundo, a pergunta antes de descartar e a ponte do puxar para baixo.
    /// `perguntar` diz se há o que perder; `pergunta` e `descartar` são os textos do alerta ("Você já preencheu este
    /// gasto." / "Descartar gasto"); `fechar` fecha de fato.
    func folhaDoApp(perguntar: Bool, pergunta: String, descartar: String, fechar: @escaping () -> Void) -> some View {
        modifier(FolhaDoApp(perguntar: perguntar, pergunta: pergunta, descartar: descartar, fechar: fechar))
    }

    /// Um passo da folha: o título na barra, o × no lado dado (nil: sem ×, como a lista de tópicos), o fundo transparente
    /// para a Folha aparecer. Na raiz, o escapar do VoiceOver fecha (pedindo antes).
    func passoDaFolha(_ titulo: String, subtitulo: String? = nil, fechar lado: LadoDoFechar?, raiz: Bool = false) -> some View {
        modifier(PassoDaFolha(titulo: titulo, subtitulo: subtitulo, lado: lado, raiz: raiz))
    }
}

enum LadoDoFechar { case esquerda, direita }

private struct FolhaDoApp: ViewModifier {
    let perguntar: Bool
    let pergunta: String
    let descartar: String
    let fechar: () -> Void
    @State private var confirmando = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    #if DEBUG
    @AppStorage("custta.textoApagado") private var textoApagado = ""
    #endif

    func body(content: Content) -> some View {
        let pedido = PedidoDeFechar { if perguntar { confirmando = true } else { fechar() } }
        content
            #if DEBUG
            // Laudo de leitura: o apagador de texto da raiz não chega dentro da .sheet.
            .modifier(ApagaTexto(ativo: textoApagado == "tudo"))
            #endif
            .environment(\.pedirParaFechar, pedido)
            .interactiveDismissDisabled(perguntar)
            .background { PonteDeFechamento { if perguntar { confirmando = true } } }
            .alert(pergunta, isPresented: $confirmando) {
                Button(descartar, role: .destructive, action: fechar)
                Button("Continuar editando", role: .cancel) {}
            }
            .presentationDragIndicator(.visible)
            .presentationBackground {
                // A Folha (vidro denso do mockup): a cor do token sobre o desfoque do que fica atrás. Com "Reduzir
                // transparência", opaca: a Folha sobre o Fundo, sem material.
                if opcoes.reduzirTransparencia {
                    Rectangle().fill(paleta.cor(.folha)).background(paleta.cor(.fundo))
                } else {
                    Rectangle().fill(paleta.cor(.folha)).background(.ultraThinMaterial)
                }
            }
    }
}

private struct PassoDaFolha: ViewModifier {
    let titulo: String
    let subtitulo: String?
    let lado: LadoDoFechar?
    let raiz: Bool
    @Environment(\.pedirParaFechar) private var pedirParaFechar
    @Environment(\.paleta) private var paleta

    @ViewBuilder func body(content: Content) -> some View {
        let passo = content
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { TituloDaFolha(titulo: titulo, subtitulo: subtitulo) }
                if let lado {
                    ToolbarItem(placement: lado == .esquerda ? .topBarLeading : .topBarTrailing) {
                        Button(role: .close) { pedirParaFechar() }
                            .tint(paleta.cor(.texto))
                            .accessibilityIdentifier("fecharFolha")
                    }
                }
            }
        // Só na raiz: num passo de dentro, a ação de escape (mesmo vazia) engole o escape do VoiceOver, e o Z deixa de
        // voltar ao passo anterior pelo NavigationStack.
        if raiz { passo.accessibilityAction(.escape) { pedirParaFechar() } } else { passo }
    }
}

// MARK: - Ponte para o "tentou fechar"

/// Um controlador invisível dentro da folha: acha o presentation controller dela e põe na frente do delegado do SwiftUI
/// um repassador que avisa a tentativa de fechar (puxar a folha com o fechar desligado) e repassa todo o resto ao
/// original. Quando a folha some, devolve o delegado original, para nada ficar preso.
struct PonteDeFechamento: UIViewControllerRepresentable {
    let tentou: () -> Void

    func makeUIViewController(context: Context) -> ControladorDaPonte { ControladorDaPonte() }

    func updateUIViewController(_ controlador: ControladorDaPonte, context: Context) {
        controlador.tentou = tentou
        controlador.instalar()
    }
}

final class ControladorDaPonte: UIViewController {
    var tentou: (() -> Void)?
    private var repassador: RepassadorDeFechamento?
    private weak var controle: UIPresentationController?
    #if DEBUG
    /// Pontes vivas: o teste de tela abre e fecha a folha e confere que nenhuma ficou para trás.
    nonisolated(unsafe) static var vivas = 0
    #endif

    init() {
        super.init(nibName: nil, bundle: nil)
        #if DEBUG
        Self.vivas += 1
        #endif
    }

    required init?(coder: NSCoder) { fatalError("sem storyboard") }

    deinit {
        #if DEBUG
        Self.vivas -= 1
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        instalar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        instalar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var raiz: UIViewController = self
        while let pai = raiz.parent { raiz = pai }
        // A folha desceu: o delegado volta a ser o do SwiftUI (o repassador segurava o original com referência forte).
        if raiz.isBeingDismissed || raiz.presentingViewController == nil { desinstalar() }
    }

    func instalar() {
        var raiz: UIViewController = self
        while let pai = raiz.parent { raiz = pai }
        // Sem pai, ou se a raiz não foi apresentada, ler presentationController criaria um à toa.
        guard raiz !== self, raiz.presentingViewController != nil, let controle = raiz.presentationController else { return }
        if let atual = controle.delegate as? RepassadorDeFechamento, atual === repassador { return }
        let novo = RepassadorDeFechamento(original: controle.delegate) { [weak self] in self?.tentou?() }
        repassador = novo
        self.controle = controle
        controle.delegate = novo
    }

    private func desinstalar() {
        if let controle, let repassador, controle.delegate === repassador { controle.delegate = repassador.original }
        repassador = nil
    }
}

@MainActor
final class RepassadorDeFechamento: NSObject, UIAdaptivePresentationControllerDelegate {
    /// Forte de propósito (experimento de 13/10): o presentation controller só segura o delegado com referência fraca.
    nonisolated(unsafe) let original: (any UIAdaptivePresentationControllerDelegate)?
    private let tentou: () -> Void

    init(original: (any UIAdaptivePresentationControllerDelegate)?, tentou: @escaping () -> Void) {
        self.original = original
        self.tentou = tentou
        super.init()
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        tentou()
        original?.presentationControllerDidAttemptToDismiss?(presentationController)
    }

    nonisolated override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return original?.responds(to: aSelector) ?? false
    }

    nonisolated override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}
