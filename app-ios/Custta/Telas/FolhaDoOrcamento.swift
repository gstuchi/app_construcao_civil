import SwiftUI
import CusttaNucleo

/* A folha "Orçamento da obra" (mockup aprovado da etapa 3, parte 1, seção 4; formOrcamento do site; conselho de 19/10,
   decisão 2). Abre no modo salvo; sem orçamento (o "Definir orçamento" das ações da fase), em "Só o total", com as teclas já
   abertas e o "Salvar" apagado até ter valor. O segmentado e o total ficam no alto, fora da lista (na letra de
   acessibilidade, rolam com ela). Por tópico: os 21 fixos e depois os próprios, uma linha cada, e o total ao vivo; trocar
   para "Só o total" com o total vazio preenche com a soma dos tópicos. O valor de cada linha entra nas teclas encaixadas
   embaixo da folha: a linha ativa acende, ‹ › andam pelas linhas e "Pronto" fecha. Trocar de modo não grava; o "Salvar"
   grava só o modo ativo (a regra 4 do site, pelo núcleo, guardando o que a folha não mostra). "Tirar orçamento" e o
   "Salvar" com tudo vazio fazem a pergunta do site, tiram o orçamento e levam a tela Orçamento de volta para a obra. */

/// A linha da folha que recebe as teclas.
enum CampoDoOrcamento: Hashable {
    case total
    case topico(String)
}

/// O formulário enquanto a folha está aberta: montado ao abrir, do orçamento da obra naquele momento (uma mudança vinda de
/// outro aparelho não o refaz), em centavos, como o teclado de valor.
@MainActor @Observable
final class RascunhoDoOrcamento {
    enum Modo: String { case total, topicos }

    let obraId: String
    /// As linhas da folha, na ordem do site: os 21 fixos e depois os próprios.
    let topicos: [Topico]
    /// A obra tinha orçamento quando a folha abriu: há o que tirar, e o "Salvar" com tudo vazio pergunta antes.
    let tinhaOrcamento: Bool
    private(set) var modo: Modo
    var total: Int
    /// O valor de cada linha; a linha sem valor fica de fora.
    var valores: [String: Int]
    /// "Preenchido com a soma dos tópicos.", depois de trocar para "Só o total" com o total vazio.
    private(set) var nota: String? = nil
    /// O formulário como abriu, para saber se algo mudou.
    private let inicial: [String]

    init(obra: Obra, topicos: [Topico]) {
        let orcamento = obra.orcamento?.comoObjeto
        // Como o site: abre no modo salvo; o total só no modo total e os tópicos só no modo por tópico.
        let modo: Modo = orcamento?["modo"] == .texto("topicos") ? .topicos : .total
        let total = modo == .total ? reaisParaCentavos(orcamento?["total"]?.comoNumero ?? 0) : 0
        let previstos = modo == .topicos ? orcamento?["topicos"]?.comoObjeto ?? [:] : [:]
        let valores = Dictionary(uniqueKeysWithValues: topicos.compactMap { t -> (String, Int)? in
            guard let reais = previstos[t.id]?.comoNumero else { return nil }
            let centavos = reaisParaCentavos(reais)
            return centavos > 0 ? (t.id, centavos) : nil
        })
        obraId = obra.id
        self.topicos = topicos
        tinhaOrcamento = orcamentoObra(obra) != nil
        self.modo = modo
        self.total = total
        self.valores = valores
        inicial = Self.foto(modo, total, valores, topicos)
    }

    /// Fechar pergunta antes quando algo mudou desde que a folha abriu (trocar de modo também).
    var temOQuePerder: Bool { Self.foto(modo, total, valores, topicos) != inicial }

    private static func foto(_ modo: Modo, _ total: Int, _ valores: [String: Int], _ topicos: [Topico]) -> [String] {
        [modo.rawValue, String(total)] + topicos.map { String(valores[$0.id] ?? 0) }
    }

    /// Nada no modo ativo.
    var vazio: Bool { modo == .total ? total == 0 : !valores.values.contains { $0 > 0 } }

    /// Sem orçamento antes, o "Salvar" fica apagado enquanto tudo está vazio; com orçamento, salvar vazio pergunta e tira.
    var salvarHabilitado: Bool { tinhaOrcamento || !vazio }

    /// Os valores das linhas em reais, na ordem da folha (vazia = 0).
    private var numeros: [Double] { topicos.map { centavosParaReais(valores[$0.id] ?? 0) } }

    /// O total ao vivo do modo por tópico (`somaTopicosOrc` do site).
    var soma: Double { somaTopicosOrc(numeros) }

    /// "14 de 22 tópicos com valor".
    var comValor: String {
        topicosComValor(Dictionary(uniqueKeysWithValues: topicos.map { ($0.id, centavosParaReais(valores[$0.id] ?? 0)) }), de: topicos.count)
    }

    /// Troca o modo sem gravar. Para "Só o total" com o total vazio, a soma dos tópicos preenche o total
    /// (`totalPreenchidoOrc` do site), com a frase que diz isso.
    func trocarModo(_ novo: Modo) {
        guard novo != modo else { return }
        modo = novo
        nota = nil
        guard novo == .total else { return }
        let campo = total == 0 ? "" : numParaCampo(centavosParaReais(total))
        let preenchido = totalPreenchidoOrc(campo, numeros)
        if campo.isEmpty, !preenchido.isEmpty {
            total = reaisParaCentavos(lerNumero(preenchido))
            nota = "Preenchido com a soma dos tópicos."
        }
    }

    /// O que o "Salvar" grava (`orcamentoGravado` pelo `salvandoOrcamento` do núcleo): o modo ativo, o total em reais e um
    /// valor por linha da folha, a vazia com 0 (é ela que separa o tópico zerado aqui, que sai, do que a folha não mostra,
    /// que fica).
    var gravacao: (modo: String, total: Double, valores: [String: Double]) {
        (modo.rawValue, centavosParaReais(total),
         Dictionary(uniqueKeysWithValues: topicos.map { ($0.id, centavosParaReais(valores[$0.id] ?? 0)) }))
    }

    /// A linha ativa nas teclas: o valor dela, que muda a cada tecla.
    func centavos(_ campo: CampoDoOrcamento) -> Int {
        switch campo {
        case .total: return total
        case .topico(let id): return valores[id] ?? 0
        }
    }

    func definir(_ campo: CampoDoOrcamento, _ centavos: Int) {
        switch campo {
        case .total: total = centavos
        case .topico(let id): valores[id] = centavos > 0 ? centavos : nil
        }
    }

    /// A linha antes ou depois na ordem da folha (‹ ›); nas pontas, nil (as setas não fazem nada, como no mockup).
    func vizinho(_ campo: CampoDoOrcamento, passo: Int) -> CampoDoOrcamento? {
        guard case .topico(let id) = campo, let i = topicos.firstIndex(where: { $0.id == id }), topicos.indices.contains(i + passo) else {
            return nil
        }
        return .topico(topicos[i + passo].id)
    }

    /// "Elétrica · 9 de 71", na barra das teclas; nil no total.
    func nome(_ campo: CampoDoOrcamento) -> String? {
        guard case .topico(let id) = campo, let i = topicos.firstIndex(where: { $0.id == id }) else { return nil }
        return "\(topicos[i].nome) · \(i + 1) de \(topicos.count)"
    }
}

struct FolhaDoOrcamento: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDoOrcamento?
    @State private var ativoAoAbrir: CampoDoOrcamento?

    var body: some View {
        Group {
            if let rascunho {
                FolhaDoOrcamentoAberta(rascunho: rascunho, ativoAoAbrir: ativoAoAbrir)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra sumiu (apagada em outro aparelho) com a folha aberta: não há onde gravar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool { modelo.sincronizador.estado.obras.contains { $0.id == obraId } }

    private func montar() {
        guard rascunho == nil else { return }
        let estado = modelo.sincronizador.estado
        guard let obra = estado.obras.first(where: { $0.id == obraId }) else { folhas.fechar(); return }
        let r = RascunhoDoOrcamento(obra: obra, topicos: topicosDoFormulario(estado.config.topicosProprios))
        // "Definir orçamento": as teclas já abertas no total.
        ativoAoAbrir = r.tinhaOrcamento ? nil : .total
        #if DEBUG
        abrirNoPassoDeTeste(r)
        #endif
        rascunho = r
    }

    #if DEBUG
    /// Testes de tela, laudo e conferência visual (`-custta.folha`, com `CUSTTA_FOLHA=orcamento:<obra>`): `total` troca para
    /// "Só o total" (com a soma, se vazio), `topicos` para "Por tópico", `teclas:<tópico>` (ou `teclas:total`) abre as teclas
    /// na linha.
    private func abrirNoPassoDeTeste(_ r: RascunhoDoOrcamento) {
        guard let passo = UserDefaults.standard.string(forKey: "custta.folha") else { return }
        if passo == "total" { r.trocarModo(.total) }
        if passo == "topicos" { r.trocarModo(.topicos) }
        if passo.hasPrefix("teclas:") {
            let alvo = String(passo.dropFirst(7))
            if alvo != "total" { r.trocarModo(.topicos) }
            ativoAoAbrir = alvo == "total" ? .total : .topico(alvo)
        }
    }
    #endif
}

private struct FolhaDoOrcamentoAberta: View {
    @Bindable var rascunho: RascunhoDoOrcamento
    @State private var ativo: CampoDoOrcamento?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    init(rascunho: RascunhoDoOrcamento, ativoAoAbrir: CampoDoOrcamento?) {
        self.rascunho = rascunho
        _ativo = State(initialValue: ativoAoAbrir)
    }

    private var nomeDaObra: String { modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? "" }

    var body: some View {
        NavigationStack {
            CorpoDaFolhaDoOrcamento(rascunho: rascunho, ativo: $ativo)
                .passoDaFolha("Orçamento da obra", subtitulo: nomeDaObra, fechar: .esquerda, escape: .fechar)
        }
        .folhaDoApp(perguntar: { rascunho.temOQuePerder },
                    pergunta: rascunho.tinhaOrcamento ? "Você mudou este orçamento." : "Você já preencheu este orçamento.",
                    descartar: rascunho.tinhaOrcamento ? "Descartar alterações" : "Descartar orçamento") {
            folhas.fechar()
        }
    }
}

/// A rolagem até a linha ativa: guardada fora do estado observado, para a geometria mudar sem refazer a folha.
@MainActor
private final class MedidasDaFolhaDoOrcamento {
    /// A linha que espera a lista encolher para rolar até ela: ao tocar numa linha, a faixa das teclas ainda não tem altura.
    var pendente: CampoDoOrcamento?
    /// A linha que a lista segura no meio da faixa à vista até alguém rolar. Na lista preguiçosa, as linhas que ela ainda não
    /// criou têm altura estimada: o `scrollTo` pode parar longe e, quando as linhas de verdade chegam, a lista ainda anda (no
    /// iOS 26, na maior letra, a folha aberta com as teclas deixava a Elétrica fora da vista). A cada mudança da rolagem ou da
    /// linha, a folha confere onde ela ficou e, fora do lugar, rola de novo.
    var alvo: CampoDoOrcamento?
    /// Quantas vezes a conferência já rolou até o alvo (no máximo 6), e se há uma conferência marcada.
    var tentativas = 0
    var marcada = false
    /// A rolagem animada que a própria folha pediu, até parar: enquanto anda, nada se confere; outra animação (a do VoiceOver)
    /// é de quem rolou.
    var animando = false
    /// O meio da linha ativa no espaço da rolagem (só ela é medida) e a geometria da rolagem.
    var meio: (campo: CampoDoOrcamento, y: CGFloat)?
    var geometria: ScrollGeometry?

    init(alvo: CampoDoOrcamento?) { self.alvo = alvo }
}

private struct CorpoDaFolhaDoOrcamento: View {
    @Bindable var rascunho: RascunhoDoOrcamento
    @Binding var ativo: CampoDoOrcamento?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.pedirParaFechar) private var pedirParaFechar
    @AccessibilityFocusState private var foco: CampoDoOrcamento?
    @FocusState private var tecladoFisico: Bool
    @State private var medidas: MedidasDaFolhaDoOrcamento
    @State private var tirando = false
    @State private var naoCarregado = false

    init(rascunho: RascunhoDoOrcamento, ativo: Binding<CampoDoOrcamento?>) {
        self.rascunho = rascunho
        _ativo = ativo
        // Aberta já com as teclas ("Definir orçamento"): a lista segura a linha ativa no meio desde a primeira medida.
        _medidas = State(initialValue: MedidasDaFolhaDoOrcamento(alvo: ativo.wrappedValue))
    }

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        VStack(spacing: 0) {
            if !grande { cabecalho }
            ScrollViewReader { leitor in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if grande { cabecalho }
                        if rascunho.modo == .topicos { linhasDosTopicos(leitor) } else { linhaDoTotal(leitor) }
                        if rascunho.tinhaOrcamento {
                            GrupoDaFolha {
                                // A linha inteira do grupo recebe o toque (o .f-lin.destr do mockup), não só o texto.
                                Button { tirando = true } label: {
                                    Text("Tirar orçamento")
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 11)
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                        .contentShape(.rect)
                                }
                                .foregroundStyle(paleta.cor(.negativo))
                                .accessibilityIdentifier("tirarOrcamento")
                            }
                            .padding(.top, 28)
                        }
                    }
                    .padding(.top, grande ? 4 : 8)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("listaDoOrcamento")
                // As teclas acabaram de abrir (a lista encolheu): agora a linha ativa vai para o meio da faixa à vista.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { _ in
                    guard let pendente = medidas.pendente, ativo == pendente else { return }
                    medidas.pendente = nil
                    rolar(ate: pendente, leitor)
                }
                // A cada mudança da rolagem (as linhas que a lista preguiçosa cria, a faixa que muda), a linha que a lista segura
                // é conferida.
                .onScrollGeometryChange(for: ScrollGeometry.self) { $0 } action: { _, geometria in
                    medidas.geometria = geometria
                    conferir(leitor)
                }
                // Quem rola a lista (o dedo, o VoiceOver) leva a rolagem: a folha para de segurar a linha e não puxa ninguém de
                // volta. A rolagem animada da própria folha é conferida quando para.
                .onScrollPhaseChange { _, fase in
                    switch fase {
                    case .idle:
                        if medidas.animando {
                            medidas.animando = false
                            conferir(leitor)
                        }
                    case .animating:
                        if !medidas.animando { medidas.alvo = nil }
                    default:
                        medidas.alvo = nil
                    }
                }
                // A letra mudou com as teclas abertas (pela Central de Controle, por exemplo): as linhas mudam de altura e a rolagem
                // fica onde estava, com a linha ativa longe da vista; ela volta ao meio da faixa.
                .onChange(of: tamanho) { if let ativo { rolar(ate: ativo, leitor) } }
                .onChange(of: ativo) { antes, agora in
                    guard let agora else {
                        medidas.alvo = nil
                        return
                    }
                    foco = agora
                    anunciar(agora)
                    // Com as teclas já abertas (‹ ›), a lista não muda de altura: rola já.
                    if antes != nil { rolar(ate: agora, leitor) }
                }
            }
            if let campo = ativo {
                TecladoEncaixado(centavos: Binding(get: { rascunho.centavos(campo) }, set: { rascunho.definir(campo, $0) }),
                                 nome: rascunho.nome(campo),
                                 anterior: { ativo = rascunho.vizinho(campo, passo: -1) ?? campo },
                                 proximo: { ativo = rascunho.vizinho(campo, passo: 1) ?? campo },
                                 pronto: { ativo = nil },
                                 salvarHabilitado: rascunho.salvarHabilitado,
                                 salvar: salvar)
                    .focusable()
                    .focused($tecladoFisico)
                    .focusEffectDisabled()
                    .onAppear { tecladoFisico = true }
                    // Teclado físico: os dígitos e o apagar entram na linha ativa, como as teclas da tela.
                    .onKeyPress(characters: .decimalDigits, phases: .down) { tecla in
                        guard let d = tecla.characters.first?.wholeNumberValue else { return .ignored }
                        tocar(.digito(d), em: campo)
                        return .handled
                    }
                    // O apagar do teclado físico (o ⌫ chega como .delete, U+0008) e o apagar para a frente (⌦) tiram o último dígito,
                    // como a tecla da tela (não há cursor no valor).
                    .onKeyPress(keys: [.delete, .deleteForward], phases: .down) { _ in
                        tocar(.apagar, em: campo)
                        return .handled
                    }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if ativo == nil {
                // O identificador no próprio botão (o fundo desce até a borda; ver a folha do gasto).
                Button("Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha())
                    .disabled(!rascunho.salvarHabilitado)
                    .accessibilityIdentifier("salvarOrcamento")
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 0)
                    // O degradê da folha atrás do botão, como nas outras folhas (o .f-pe do mockup).
                    .background {
                        LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                       startPoint: .bottom, endPoint: .top)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
            }
        }
        // Escapar (Z com dois dedos): com as teclas abertas, fecha as teclas; sem elas, fecha a folha (pedindo antes).
        .accessibilityAction(.escape) { if ativo != nil { ativo = nil } else { pedirParaFechar() } }
        .background {
            Color.clear
                .alert("Tirar o orçamento desta obra?", isPresented: $tirando) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Tirar orçamento", role: .destructive, action: tirar)
                } message: {
                    Text("Os gastos continuam como estão.")
                }
                .tint(paleta.cor(.texto))
        }
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("O orçamento continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .pausaOFundo(enquanto: tirando || naoCarregado)
    }

    // MARK: - O alto: o segmentado e o total

    private var cabecalho: some View {
        VStack(spacing: 12) {
            SegmentadoDaFolha(opcoes: [(RascunhoDoOrcamento.Modo.total, "Só o total", nil), (.topicos, "Por tópico", nil)],
                              escolhida: Binding(get: { rascunho.modo }, set: { trocarModo($0) }), identificador: "modoDoOrcamento",
                              larguraToda: true)
            if rascunho.modo == .topicos { TotalAoVivo(soma: rascunho.soma, comValor: rascunho.comValor) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        // No "Só o total" não há o Total ao vivo: os 10 com os 8 do alto da lista dão os 18 do mockup até a linha do total.
        .padding(.bottom, tamanho.isAccessibilitySize ? 16 : (rascunho.modo == .total ? 10 : 0))
    }

    private func trocarModo(_ modo: RascunhoDoOrcamento.Modo) {
        ativo = nil
        rascunho.trocarModo(modo)
        if let nota = rascunho.nota { AccessibilityNotification.Announcement(nota).post() }
    }

    // MARK: - As linhas

    /// Os tópicos, filhos diretos da lista preguiçosa (até 71 linhas): cada uma desenha o seu pedaço do grupo, e uma tecla
    /// refaz só a linha ativa (as outras são iguais à vez anterior).
    @ViewBuilder private func linhasDosTopicos(_ leitor: ScrollViewProxy) -> some View {
        let ultimo = rascunho.topicos.count - 1
        ForEach(Array(rascunho.topicos.enumerated()), id: \.element.id) { i, t in
            let campo = CampoDoOrcamento.topico(t.id)
            LinhaDoTopicoNaFolha(topico: t, centavos: rascunho.valores[t.id] ?? 0, ativa: ativo == campo,
                                 proprio: !topicosPadrao.contains { $0.id == t.id }, primeira: i == 0, ultima: i == ultimo)
                .equatable()
                .background { if ativo == campo { medida(campo, leitor) } }
                .onTapGesture { abrir(campo) }
                .accessibilityAction { abrir(campo) }
                .accessibilityActions {
                    if ativo == campo {
                        Button("Tópico anterior") { ativo = rascunho.vizinho(campo, passo: -1) ?? campo }
                        Button("Próximo tópico") { ativo = rascunho.vizinho(campo, passo: 1) ?? campo }
                        Button("Pronto") { ativo = nil }
                    }
                }
                .accessibilityFocused($foco, equals: campo)
                .id(campo)
        }
        NotaDaFolha(texto: "Tópico sem valor não entra na comparação.").padding(.top, 8)
    }

    /// "Orçamento total", a linha de 60 pt do valor, e as frases do modo.
    @ViewBuilder private func linhaDoTotal(_ leitor: ScrollViewProxy) -> some View {
        GrupoDaFolha {
            LinhaDoTotalNaFolha(centavos: rascunho.total, ativa: ativo == .total)
                .onTapGesture { abrir(.total) }
                .accessibilityAction { abrir(.total) }
                .accessibilityActions { if ativo == .total { Button("Pronto") { ativo = nil } } }
                .accessibilityFocused($foco, equals: .total)
        }
        .background { if ativo == .total { medida(.total, leitor) } }
        .id(CampoDoOrcamento.total)
        VStack(spacing: 8) {
            if let nota = rascunho.nota { NotaDaFolha(texto: nota, cor: .alerta, identificador: "notaDaSoma") }
            NotaDaFolha(texto: "Comparado com o Total gasto (bruto), com as parcelas a vencer.")
        }
        .padding(.top, 8)
    }

    // MARK: - As teclas

    /// Abre as teclas na linha (ou troca a linha). Ao abrir, a lista ainda não encolheu: a rolagem espera a nova altura.
    private func abrir(_ campo: CampoDoOrcamento) {
        if ativo == nil { medidas.pendente = campo }
        ativo = campo
    }

    private func tocar(_ tecla: TeclaDeValor, em campo: CampoDoOrcamento) {
        let antes = rascunho.centavos(campo), novo = aplicarTecla(antes, tecla)
        guard novo != antes else { return }
        rascunho.definir(campo, novo)
        AccessibilityNotification.Announcement(fmtCentavos(novo)).post()
    }

    /// "Elétrica, 9 de 71, R$ 30.000,00" a cada troca de linha.
    private func anunciar(_ campo: CampoDoOrcamento) {
        let valor = rascunho.centavos(campo)
        let nome = rascunho.nome(campo)?.replacingOccurrences(of: " · ", with: ", ") ?? "Orçamento total"
        AccessibilityNotification.Announcement("\(nome), \(valor > 0 ? moeda(centavosParaReais(valor)) : "sem valor")").post()
    }

    /// Põe a linha ativa no meio da faixa à vista e a segura ali até alguém rolar. A lista fica entre o alto (o segmentado e o
    /// total, ou a barra) e as teclas, que moram fora dela: o meio da rolagem é o meio da faixa (no protótipo de 19/10, com as
    /// teclas por cima da lista, a âncora mínima deixava a linha embaixo delas e o meio da rolagem errava na letra grande). Já
    /// no lugar, não rola (uma animação que não anda não avisaria que parou).
    private func rolar(ate campo: CampoDoOrcamento, _ leitor: ScrollViewProxy) {
        medidas.alvo = campo
        medidas.tentativas = 0
        guard !estaNoLugar(campo) else { return }
        medidas.animando = !opcoes.reduzirMovimento
        if opcoes.reduzirMovimento { leitor.scrollTo(campo, anchor: .center) }
        else { withAnimation(.easeOut(duration: 0.25)) { leitor.scrollTo(campo, anchor: .center) } }
    }

    /// Confere a linha que a lista segura: fora do lugar, rola de novo até ela, sem animar (até 6 vezes). A rolagem e a linha
    /// avisam em separado, e uma mudança só (a folha subindo, as teclas abrindo) dá vários avisos: a conferência fica para a
    /// vez seguinte da fila principal, com as medidas da mudança inteira.
    private func conferir(_ leitor: ScrollViewProxy) {
        guard medidas.alvo != nil, !medidas.marcada else { return }
        medidas.marcada = true
        Task { @MainActor in
            medidas.marcada = false
            guard let alvo = medidas.alvo, alvo == ativo, !medidas.animando, let g = medidas.geometria, g.containerSize.height > 0,
                  !estaNoLugar(alvo), medidas.tentativas < 6 else { return }
            medidas.tentativas += 1
            leitor.scrollTo(alvo, anchor: .center)
        }
    }

    /// A linha está onde o `scrollTo` a põe: com o meio no meio da faixa à vista, que é a moldura da rolagem (na letra grande,
    /// o que a lista tem por baixo da barra da folha fica fora dela, na margem de cima), ou, nas pontas da lista, o mais perto
    /// dele que a rolagem chega.
    private func estaNoLugar(_ campo: CampoDoOrcamento) -> Bool {
        guard let meio = medidas.meio, meio.campo == campo, let g = medidas.geometria else { return false }
        let centro = g.containerSize.height / 2, rolado = g.contentOffset.y + g.contentInsets.top
        return abs(meio.y - centro) <= 1 || (meio.y < centro && rolado <= 0.5)
            || (meio.y > centro && rolado >= g.contentSize.height - g.containerSize.height - 0.5)
    }

    /// Mede o meio da linha ativa no espaço da rolagem: é por ele que a conferência sabe onde a linha ficou.
    private func medida(_ campo: CampoDoOrcamento, _ leitor: ScrollViewProxy) -> some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).midY } action: { y in
                medidas.meio = (campo, y)
                conferir(leitor)
            }
            .onDisappear { if medidas.meio?.campo == campo { medidas.meio = nil } }
    }

    // MARK: - Gravar

    private func salvar() {
        // A folha já está descendo (o primeiro toque gravou): o segundo toque de um toque duplo não grava de novo.
        guard folhas.aberta != nil else { return }
        let g = rascunho.gravacao
        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == rascunho.obraId }) else { folhas.fechar(); return }
        // Tudo vazio tira o orçamento: a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar; achado 6).
        if orcamentoGravado(obra.orcamento, modo: g.modo, total: g.total, valores: g.valores) == nil { tirando = true; return }
        gravar { $0.salvandoOrcamento(modo: g.modo, total: g.total, valores: g.valores, naObra: rascunho.obraId) }
    }

    private func tirar() {
        guard folhas.aberta != nil else { return }
        gravar(tirou: true) { $0.tirandoOrcamento(daObra: rascunho.obraId) }
    }

    private func gravar(tirou: Bool = false, _ mudanca: (Estado) -> Estado?) {
        switch modelo.gravar(mudanca) {
        case .gravou where tirou:
            // Sem orçamento, a tela Orçamento (por trás da folha) volta para a obra, e a folha desce no turno seguinte, com a
            // animação dela: no mesmo turno, a navegação levaria junto a descida da folha.
            folhas.navegar(.sairDoOrcamento(rascunho.obraId))
            Task { @MainActor in folhas.fechar() }
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        }
    }
}

/// O total ao vivo do modo por tópico, preso no alto com o segmentado: "Total", a soma e "N de M tópicos com valor".
private struct TotalAoVivo: View {
    let soma: Double
    let comValor: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                                 : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        // Os identificadores vão também em cada texto: o VoiceOver lê o total como um elemento só, mas a auditoria do Xcode
        // olha cada texto (e a exceção dela no iOS 26 é por identificador).
        layout {
            Text("Total").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioTransparente))
                .accessibilityIdentifier("totalDoOrcamento-rotulo")
            if !tamanho.isAccessibilitySize { Spacer(minLength: 0) }
            VStack(alignment: tamanho.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
                ValorEmDinheiro(texto: moeda(soma), fonte: .title3.weight(.bold))
                    .accessibilityIdentifier("totalDoOrcamento-soma")
                Text(comValor).font(.footnote).foregroundStyle(paleta.cor(.secundarioTransparente))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("totalDoOrcamento-comValor")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paleta.cor(.linhaDaFolha), in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("totalDoOrcamento")
    }
}

/// Uma linha de tópico da folha: o ícone, o nome (com "próprio" nos tópicos próprios) e o valor, ou "sem valor"; a ativa
/// acende, com o valor na cor do link e o cursor. Desenha o seu pedaço do grupo (os cantos de cima na primeira, os de baixo
/// na última, e a linha fina recuada em cima das outras), para ser filha direta da lista preguiçosa. Na letra grande, sem o
/// ícone e com o valor embaixo do nome. Para o VoiceOver, um botão: o nome e o valor.
struct LinhaDoTopicoNaFolha: View, Equatable {
    let topico: Topico
    let centavos: Int
    let ativa: Bool
    let proprio: Bool
    let primeira: Bool
    let ultima: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    nonisolated static func == (a: Self, b: Self) -> Bool {
        a.topico == b.topico && a.centavos == b.centavos && a.ativa == b.ativa && a.proprio == b.proprio
            && a.primeira == b.primeira && a.ultima == b.ultima
    }

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let forma = UnevenRoundedRectangle(topLeadingRadius: primeira ? 24 : 0, bottomLeadingRadius: ultima ? 24 : 0,
                                           bottomTrailingRadius: ultima ? 24 : 0, topTrailingRadius: primeira ? 24 : 0,
                                           style: .continuous)
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            if !grande { IconeDoTopico(icone: topico.icone) }
            nome
            if !grande { Spacer(minLength: 8) }
            ValorDaLinhaDoOrcamento(centavos: centavos, ativa: ativa)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background {
            ZStack {
                forma.fill(paleta.cor(.linhaDaFolha))
                if ativa { forma.fill(paleta.cor(.aceso)) }
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) { if !primeira { SeparadorDaFolha(recuo: grande ? 16 : 60) } }
        .contentShape(.rect)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(topico.nome + (proprio ? ", próprio" : ""))
        .accessibilityValue(centavos > 0 ? moeda(centavosParaReais(centavos)) : "sem valor")
        .accessibilityAddTraits(ativa ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("linhaOrc-\(topico.id)")
    }

    /// O nome e, no tópico próprio, a etiqueta "próprio" (o `.proprio` do mockup: 12 pt semibold no secundário, na cápsula do
    /// trilho do segmentado).
    private var nome: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(topico.nome).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
            if proprio {
                Text("próprio")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(paleta.cor(.segmentadoFundo), in: .capsule)
            }
        }
    }
}

/// O valor de uma linha da folha: "R$ 30.000,00" (na ativa, na cor do link e com o cursor) ou "sem valor".
private struct ValorDaLinhaDoOrcamento: View {
    let centavos: Int
    let ativa: Bool
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if centavos > 0 || ativa {
                ValorEmDinheiro(texto: moeda(centavosParaReais(centavos)), fonte: .body.weight(ativa ? .semibold : .regular),
                                cor: ativa ? .linkNoVidro : .texto)
            } else {
                Text("sem valor").foregroundStyle(paleta.cor(.secundarioTransparente))
            }
            if ativa { CursorDaLinha() }
        }
    }
}

/// "Orçamento total" e o valor, a linha de 60 pt do modo "Só o total" (a do valor do gasto): o rótulo no secundário, "R$" e
/// o valor em title2 bold; ativa, na cor do link e com o cursor.
private struct LinhaDoTotalNaFolha: View {
    let centavos: Int
    let ativa: Bool
    @Environment(\.paleta) private var paleta

    var body: some View {
        LinhaDaFolhaComRotulo(rotulo: "Orçamento total", altura: 60) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                ValorEmDinheiro(texto: fmtCentavos(centavos), fonte: .title2.weight(.bold), cor: ativa ? .linkNoVidro : .texto,
                                prefixo: .callout.weight(.semibold))
                if ativa { CursorDaLinha() }
            }
        }
        .background(ativa ? paleta.cor(.aceso) : .clear)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Orçamento total")
        .accessibilityValue(moeda(centavosParaReais(centavos)))
        .accessibilityAddTraits(ativa ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("linhaOrcamentoTotal")
    }
}

/// O cursor da linha ativa: 2 pt na cor do link, da altura da letra, piscando a 2 Hz (pelo relógio, sem animação); parado
/// com Reduzir movimento.
private struct CursorDaLinha: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @ScaledMetric(relativeTo: .body) private var altura: CGFloat = 20

    var body: some View {
        Group {
            if opcoes.reduzirMovimento {
                barra(visivel: true)
            } else {
                TimelineView(.periodic(from: .now, by: 0.5)) { contexto in
                    barra(visivel: Int(contexto.date.timeIntervalSinceReferenceDate * 2) % 2 == 0)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func barra(visivel: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1).fill(paleta.cor(.linkNoVidro)).frame(width: 2, height: altura).opacity(visivel ? 1 : 0)
            .alignmentGuide(.firstTextBaseline) { $0.height * 0.8 }
    }
}
