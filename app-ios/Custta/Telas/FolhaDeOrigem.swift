import SwiftUI
import UIKit
import CusttaNucleo

/* A volta à folha de origem (etapa 3; decisão 1 do conselho de 19/10). Editar um gasto de dentro de uma folha (o A pagar;
   o detalhe do tópico vem depois) empurra a edição da etapa 2 no NavigationStack da própria folha, sem o ×, com o voltar e
   o nome da origem no subtítulo. "Salvar" e o voltar voltam à origem, que fica montada embaixo: a mesma rolagem, os
   números novos e, no "Salvar", a linha acesa. Puxar fecha a folha inteira e, com mudança, pergunta antes. Continua uma folha por vez: o `Folhas` é só a folha sobre as abas, e o estado da volta mora na folha de origem
   (`OrigemDaEdicao`). */

/// Um passo empurrado na folha de origem: a edição de um gasto e, em cima dela, o teclado do valor e a lista de tópicos.
enum PassoDaOrigem: Hashable {
    case editar(String)
    case valor
    case topicos

    init?(passo: PassoDoGasto) {
        switch passo {
        case .valor: self = .valor
        case .topicos: self = .topicos
        case .detalhes, .obras: return nil
        }
    }

    var passoDoGasto: PassoDoGasto? {
        switch self {
        case .valor: .valor
        case .topicos: .topicos
        case .editar: nil
        }
    }
}

/// O que a folha de origem guarda da edição empurrada dentro dela, e o que a lista faz quando a edição volta.
@MainActor @Observable
final class OrigemDaEdicao {
    /// Quanto dura o voltar do NavigationStack: o foco do VoiceOver e o anúncio contam do fim dele.
    static let fimDoVoltar = Duration.milliseconds(500)

    /// O título da folha de origem ("A pagar · 30 dias"): o voltar do sistema da edição se chama assim, e o chevron próprio
    /// também (medido no simulador em 20/10).
    let titulo: String
    /// O nome curto da origem, no subtítulo da edição ("A pagar"): diz para onde ela volta.
    let nome: String

    init(titulo: String, nome: String) {
        self.titulo = titulo
        self.nome = nome
    }

    /// Como a edição voltou, para a lista: rolar até a linha e apagar a luz, mover o foco.
    struct Volta: Equatable {
        enum Motivo: Equatable {
            /// "Salvar": a linha volta acesa.
            case salvou(String)
            /// O voltar sem salvar: o do sistema, sem mudança; o chevron, a borda ou o Z, descartando.
            case voltou(String)
            /// O gasto sumiu com a edição aberta (apagado em outro aparelho).
            case sumiu(String)
        }

        let motivo: Motivo
        /// A ordem das linhas quando a edição abriu: a vizinha de uma linha que saiu da lista vem dela.
        let ordem: [String]
        let vez: Int
    }

    /// O caminho da pilha. A volta à raiz, por qualquer caminho (o voltar do sistema também), solta a edição e avisa a lista.
    var caminho: [PassoDaOrigem] = [] {
        didSet {
            guard caminho.isEmpty, case .editar(let id)? = oldValue.first else { return }
            let motivo = motivoDaVolta ?? .voltou(id)
            motivoDaVolta = nil
            edicao = nil
            vezes += 1
            volta = Volta(motivo: motivo, ordem: ordemAoAbrir, vez: vezes)
        }
    }
    /// O rascunho da edição: criado ao empurrar e solto quando o caminho volta à raiz (voltar do valor ou dos tópicos não
    /// perde nada).
    private(set) var edicao: RascunhoDoGasto?
    /// As linhas acesas depois de salvar (2 s), e quantas vezes acenderam: a luz de um "Salvar" não apaga a do seguinte.
    var acesos: Set<String> = []
    @ObservationIgnored private(set) var vezDoAceso = 0
    /// A última volta da edição.
    private(set) var volta: Volta?
    @ObservationIgnored private var motivoDaVolta: Volta.Motivo?
    @ObservationIgnored private var ordemAoAbrir: [String] = []
    @ObservationIgnored private var vezes = 0

    /// A edição mudou alguma coisa: o puxar e o voltar perguntam antes de descartar.
    var temOQuePerder: Bool { edicao?.temOQuePerder ?? false }

    /// A edição deste gasto está no topo do caminho, e o "Salvar" pode gravar: o segundo toque de um toque duplo chega com
    /// ela já voltando.
    func editando(_ gastoId: String?) -> Bool {
        guard let gastoId else { return false }
        return caminho.last == .editar(gastoId)
    }

    /// Empurra a edição de um gasto da lista; `ordem` são as linhas na ordem da tela.
    func abrir(_ rascunho: RascunhoDoGasto, ordem: [String]) {
        guard caminho.isEmpty, let id = rascunho.editado?.id else { return }
        edicao = rascunho
        ordemAoAbrir = ordem
        caminho = [.editar(id)]
    }

    /// Os passos em cima da edição (o valor e os tópicos), no caminho do PassoDosDetalhes.
    var passosDaEdicao: [PassoDoGasto] {
        get { caminho.dropFirst().compactMap(\.passoDoGasto) }
        set {
            guard case .editar(let id)? = caminho.first else { return }
            caminho = [.editar(id)] + newValue.compactMap(PassoDaOrigem.init(passo:))
        }
    }

    /// "Pronto" no valor, o tópico escolhido: volta à edição. O segundo toque não volta além dela (e `removeLast` num
    /// caminho vazio derrubaria o app).
    func voltarDoPasso(_ passo: PassoDaOrigem) {
        if caminho.count > 1, caminho.last == passo { caminho.removeLast() }
    }

    /// "Salvar" gravou: a edição volta e a linha fica acesa.
    func salvou(_ ids: [String]) {
        guard case .editar(let id)? = caminho.first else { return }
        acesos = Set(ids)
        vezDoAceso += 1
        sair(.salvou(id))
    }

    /// "Descartar mudanças" (no chevron, na borda ou no Z) ou o Z sem mudança: volta sem salvar.
    func voltar() {
        guard case .editar(let id)? = caminho.first else { return }
        sair(.voltou(id))
    }

    /// O gasto da edição sumiu (apagado em outro aparelho): volta, em vez de fechar a folha.
    func sumiu(_ gastoId: String) { sair(.sumiu(gastoId)) }

    /// Volta à raiz pelo motivo dado; com o caminho já na raiz, nada (o segundo toque, a volta repetida).
    private func sair(_ motivo: Volta.Motivo) {
        guard !caminho.isEmpty else { return }
        motivoDaVolta = motivo
        caminho = []
    }
}

/// Para onde a edição de um gasto vai quando termina. `.folha`: a folha do gasto da etapa 2, que desce, e a obra acende ou
/// apaga a linha, como sempre. `.origem`: a edição está empurrada numa folha de origem e volta para ela.
enum SaidaDaEdicao: Sendable {
    case folha
    case origem(OrigemDaEdicao)

    /// A edição ainda está à vista e pode gravar: a folha aberta; na origem, a edição no topo do caminho.
    @MainActor func aberta(_ folhas: Folhas, gastoId: String?) -> Bool {
        switch self {
        case .folha: folhas.aberta != nil
        case .origem(let origem): origem.editando(gastoId)
        }
    }
}

extension EnvironmentValues {
    @Entry var saidaDaEdicao = SaidaDaEdicao.folha
    /// Os alertas à vista dentro de uma folha de origem.
    @Entry var alertasNaFolha: AlertasNaFolha? = nil
}

/// Os alertas à vista dentro de uma folha de origem (cada `.pausaOFundo(enquanto:)` de dentro dela conta um). O "Não salvou"
/// de dentro da folha só aparece sem nenhum outro à vista: no iOS 27, um alerta toma o lugar de outro.
@MainActor @Observable
final class AlertasNaFolha {
    private(set) var abertos = 0
    var nenhum: Bool { abertos == 0 }

    func mudou(_ aberto: Bool) { abertos = max(0, abertos + (aberto ? 1 : -1)) }
}

/// O que aconteceu com uma linha da folha de origem, para o foco do VoiceOver.
enum SaidaDaLinha: Equatable {
    case salvou(String)
    case voltou(String)
    case sumiu(String)
}

/// Para onde o VoiceOver vai na lista da folha de origem, e o que ele ouve depois.
struct FocoNaOrigem: Equatable {
    let alvo: AlvoDoFoco
    let anuncio: String?
}

/// "Salvar": a linha editada; se ela saiu da lista (no A pagar, a data passou dos 30 dias), a vizinha, com "O gasto saiu
/// desta lista.". O voltar sem salvar: a linha que abriu a edição. O gasto apagado em outro aparelho: a vizinha, com o
/// anúncio do apagar da etapa 2. A lista que ficou vazia: o cartão do vazio. A vizinha é a próxima linha que ficou, senão a
/// anterior, na ordem de `antes` (a lista antes da mudança); `depois` é a lista de agora.
func focoNaOrigem(_ saida: SaidaDaLinha, antes: [String], depois: [String]) -> FocoNaOrigem {
    func vizinha(_ saem: Set<String>) -> AlvoDoFoco {
        let ficam = Set(depois).subtracting(saem)
        guard let i = antes.firstIndex(where: saem.contains) else { return depois.first(where: ficam.contains).map(AlvoDoFoco.gasto) ?? .vazio }
        let v = antes[i...].first(where: ficam.contains) ?? antes[..<i].last(where: ficam.contains)
        return v.map(AlvoDoFoco.gasto) ?? .vazio
    }
    switch saida {
    case .salvou(let id):
        return depois.contains(id) ? FocoNaOrigem(alvo: .gasto(id), anuncio: nil)
                                   : FocoNaOrigem(alvo: vizinha([id]), anuncio: "O gasto saiu desta lista.")
    case .voltou(let id):
        return FocoNaOrigem(alvo: depois.contains(id) ? .gasto(id) : vizinha([id]), anuncio: nil)
    case .sumiu(let id):
        return FocoNaOrigem(alvo: vizinha([id]), anuncio: "Gasto apagado")
    }
}

/// Um passo empurrado na folha de origem. Cada um guarda o rascunho que recebeu ao entrar: quando o caminho volta à raiz, a
/// origem solta o rascunho, e o passo que sai ainda está na tela, na animação do voltar.
struct DestinoNaOrigem: View {
    let passo: PassoDaOrigem
    let origem: OrigemDaEdicao
    @State private var rascunho: RascunhoDoGasto?
    @Environment(ModeloApp.self) private var modelo

    init(passo: PassoDaOrigem, origem: OrigemDaEdicao) {
        self.passo = passo
        self.origem = origem
        _rascunho = State(initialValue: origem.edicao)
    }

    var body: some View {
        if let rascunho {
            switch passo {
            case .editar(let id):
                PassoDosDetalhes(rascunho: rascunho, caminho: Binding(get: { origem.passosDaEdicao }, set: { origem.passosDaEdicao = $0 }),
                                 subtitulo: origem.nome, raiz: false)
                    .environment(\.saidaDaEdicao, .origem(origem))
                    // O gasto apagado em outro aparelho com a edição aberta: volta à origem, que move o foco e avisa.
                    .onChange(of: existe(id, em: rascunho.obraId)) { _, agora in if !agora { origem.sumiu(id) } }
            case .valor:
                PassoDoValor(rascunho: rascunho, titulo: "Valor", subtitulo: origem.nome, acao: "Pronto", raiz: false) {
                    origem.voltarDoPasso(.valor)
                }
            case .topicos:
                ListaDeTopicos(rascunho: rascunho) { origem.voltarDoPasso(.topicos) }
            }
        }
    }

    private func existe(_ gastoId: String, em obraId: String) -> Bool {
        modelo.sincronizador.estado.obras.first { $0.id == obraId }?.gastos.contains { $0.id == gastoId } ?? false
    }
}

/// A volta da edição empurrada na folha de origem. Sem mudança, o voltar do sistema, com o gesto da borda. Com mudança, o
/// voltar do sistema sai (ele e a borda descartariam calados: medido em 19/10) e entram o chevron próprio, no mesmo círculo
/// de vidro da barra e com o mesmo rótulo, e a borda que pergunta; os dois, como o Z do VoiceOver, perguntam antes de
/// descartar, e "Descartar mudanças" volta à origem. A troca é por modificador, nunca por um `if` de estrutura: trocar o ramo
/// recriaria o passo e derrubaria o foco do teclado na primeira tecla.
struct VoltaNaOrigem: ViewModifier {
    let saida: SaidaDaEdicao
    let sujo: Bool
    @Binding var perguntando: Bool
    @Environment(\.paleta) private var paleta

    @ViewBuilder func body(content: Content) -> some View {
        switch saida {
        case .folha:
            content
        case .origem(let origem):
            content
                .navigationBarBackButtonHidden(sujo)
                .toolbar {
                    if sujo {
                        ToolbarItem(placement: .topBarLeading) {
                            // O chevron do voltar do sistema (a mesma cor e o mesmo peso, medidos por pixel), para a troca não
                            // aparecer; o mesmo rótulo e, no Controle por Voz, também "Voltar" e o nome da origem.
                            Button { perguntando = true } label: { Image(systemName: "chevron.backward").fontWeight(.semibold) }
                                .tint(paleta.cor(.texto))
                                .accessibilityLabel(origem.titulo)
                                .accessibilityInputLabels(["Voltar", origem.nome])
                                .accessibilityIdentifier("voltarDaEdicao")
                        }
                    }
                }
                .gesture(BordaQuePergunta(ativa: sujo) { perguntando = true })
                .background {
                    Color.clear
                        .alert("Você mudou este gasto.", isPresented: $perguntando) {
                            Button("Descartar mudanças", role: .destructive) { origem.voltar() }
                            Button("Continuar editando", role: .cancel) {}
                        } message: {
                            Text("As mudanças ainda não foram salvas.")
                        }
                        .tint(paleta.cor(.texto))
                }
                .pausaOFundo(enquanto: perguntando)
        }
    }

}

/// A borda esquerda com mudança. Com o voltar do sistema escondido, o gesto da borda do sistema não faz nada, e o arrasto que
/// passa por cima de um botão vira toque nele (medido em 19/10: abria "Apagar este gasto?"). Este pan da borda, ligado só com
/// mudança, faz a pergunta do chevron; reconhecido, cancela o toque de baixo. Os outros gestos (a rolagem, os botões) esperam
/// por ele só quando o dedo começa na borda: fora dela, ele falha no primeiro toque.
struct BordaQuePergunta: UIGestureRecognizerRepresentable {
    let ativa: Bool
    let perguntar: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordenador { Coordenador() }

    func makeUIGestureRecognizer(context: Context) -> UIScreenEdgePanGestureRecognizer {
        let borda = UIScreenEdgePanGestureRecognizer()
        borda.edges = .left
        borda.delegate = context.coordinator
        borda.isEnabled = ativa
        return borda
    }

    func updateUIGestureRecognizer(_ recognizer: UIScreenEdgePanGestureRecognizer, context: Context) {
        recognizer.isEnabled = ativa
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIScreenEdgePanGestureRecognizer, context: Context) {
        if recognizer.state == .began { perguntar() }
    }

    @MainActor final class Coordenador: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy outro: UIGestureRecognizer) -> Bool { true }
    }
}
