import SwiftUI
import CusttaNucleo

/* A tela da obra, em blocos na identidade nova (etapa 4, PR 1c; mockup aprovado, parte1.html): o nome no título mono, a
   cápsula da fase e do tempo, o sólido e os blocos de vidro (BlocosDaObra.swift), as ações da fase, os afazeres, a pílula
   "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado no alto; o lápis na barra abre "Editar obra". Entra
   pelo push do NavigationStack de Obras e volta pelo círculo e pela borda (sistema). A obra que some (apagada em outro
   aparelho) fecha a tela, como o site volta ao Início. Na etapa 3, a busca e o mês ao lado da pílula filtram só a lista
   (BuscaDaObra.swift); os blocos e o orçamento ficam com a obra inteira. */
struct ObraView: View {
    let id: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.opcoes) private var opcoes
    @Environment(\.paleta) private var paleta
    @State private var aVencerAberto = false
    /// A busca e o mês da lista: moram aqui, e não no modelo, para zerar ao trocar de obra e para o redesenho que chega
    /// do Sincronizador não apagar o que está sendo digitado nem tirar o foco do campo.
    @State private var busca = BuscaDaObra()
    @FocusState private var buscaEmFoco: Bool
    /// O dedo rola a lista (ou ela desacelera depois dele): se o campo da busca sai da tela nesse meio tempo, o teclado fecha.
    @State private var dedoRolando = false
    /// O "A vencer" com filtro abre sozinho, com os achados, a cada filtro novo; fechá-lo aí não mexe no de sem filtro.
    @State private var aVencerAbertoNaBusca = true
    /// A linha arrastada que mostra "Apagar" (uma por vez).
    @State private var linhaAberta: String?
    /// "Apagar" tocado na linha: o gasto da pergunta. Fica depois que o alerta fecha, para ele não trocar de texto saindo.
    @State private var alvoDoApagar: Gasto?
    @State private var perguntando = false
    @State private var naoCarregado = false
    /// "Desfazer venda" tocado: a pergunta do site.
    @State private var desfazendo = false
    /// Muda a cada ação da fase feita aqui: a vibração leve do mockup (a de outro aparelho não vibra).
    @State private var mudouAFase = 0
    /// Os gastos que acabaram de ser salvos (acesos por 2 s) e se levam a etiqueta "novo".
    @State private var acesos: Set<String> = []
    @State private var novos = false
    @AccessibilityFocusState private var foco: AlvoDoFoco?
    /// O título pequeno mora num objeto próprio, lido só pela peça da barra: ao cruzar o limite no meio da rolagem, só
    /// ela se refaz, e não a tela inteira (lista, indicadores e cartões).
    @State private var barra = BarraDaObra()
    #if DEBUG
    /// Laudo e conferência visual: a linha que abre mostrando "Apagar" (`-custta.linhaAberta g027`).
    @AppStorage("custta.linhaAberta") private var linhaDeTeste = ""
    #endif

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == id }) {
            conteudo(obra, taxa: estado.config.taxaMensal, topicos: mapaDeTopicos(estado.config.topicosProprios))
        } else if !modelo.sincronizador.dadosCarregados {
            ProgressView()                               // aberta antes de os dados chegarem (o caminho sobrevive à troca de conta)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear                                  // a obra sumiu (apagada em outro aparelho): volta para Obras
                .onAppear { caminho.removeAll { $0 == .obra(id) } }
        }
    }

    private func conteudo(_ obra: Obra, taxa: Double, topicos: [String: Topico]) -> some View {
        let hoje = dataLocalISO(.now, fuso: .current)
        let filtrando = busca.filtrando
        let achados = filtrando ? filtraGastos(obra.gastos, topicos: topicos, filtro: busca.filtro) : obra.gastos
        let lista = listaDaObra(obra.comOsGastos(achados), hoje: hoje)
        let acoes = AcoesDaLista(aberta: $linhaAberta, acesos: acesos, novos: novos, foco: $foco,
                                 tocar: { gasto in
                                     if linhaAberta != nil { fecharLinha(); return }
                                     folhas.aberta = .editarGasto(obraId: obra.id, gastoId: gasto.id)
                                 },
                                 apagar: { gasto in
                                     alvoDoApagar = gasto
                                     perguntando = true
                                 })
        return ScrollViewReader { leitor in
            // A obra numa List (UICollectionView), uma peça por linha e um cartão por mês numa linha: no iOS 26, a LazyVStack
            // entrava em laço de layout ao arrastar na maior letra numa obra de lista curta (#99).
            List {
                Group {
                    // O título solto e a cápsula com a fase e o tempo: 8 pt entre eles e 16 até o sólido (mockup, .ob-meta-w).
                    TituloMono(texto: obra.nome)
                        .padding(EdgeInsets(top: -6, leading: 0, bottom: -4, trailing: 0))
                        .background { QuadroProprio() }
                    CapsulaDeMetadados {
                        EtiquetaDeFase(fase: obra.fase, grande: true)
                        Text(textoDoInicio(obra, hoje: hoje))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("faseDaObra")
                    .background { QuadroProprio() }
                    // Do sólido para baixo, uma Section própria: os 16 pt até o sólido vêm do espaço entre as Sections, e não
                    // de um recuo na célula da cápsula, que é o elemento de acessibilidade dela (o anel do VoiceOver).
                    Section {
                    BlocosDaObra(obra: obra, taxa: taxa, hoje: hoje) {
                        // Com uma linha arrastada aberta, o toque só a fecha, como o das linhas.
                        if linhaAberta != nil { fecharLinha(); return }
                        folhas.aberta = .aPagar(obraId: obra.id)
                    }
                    AcoesDaFaseView(fase: obra.fase,
                                    definirOrcamento: pecasOrcamento(obra).definir ? { folhas.aberta = .orcamento(obraId: obra.id) } : nil) {
                        agir($0, obra: obra)
                    }
                    // Os afazeres, 12 abaixo das ações, em todas as fases.
                    NavigationLink(value: RotaDeObras.afazeres(obra.id)) {
                        LinhaDosAfazeresView(linha: linhaDosAfazeres(obra.afazeres))
                    }
                    .buttonStyle(.plain)
                    // Os gastos por tópico, só com gastos: a barra empilhada no lugar do mini-anel (pedida em 29/10), sem toque
                    // e sem "Gráficos ›" até os Gráficos chegarem (PR 2b).
                    if !obra.gastos.isEmpty {
                        let pedacos = pedacosDoAnel(gastoPorTopico(obra))
                        // Um elemento só para o VoiceOver, como os outros blocos: o título e os pedaços com o %, sem a
                        // legenda, que repetiria os maiores. Com o .contain, o título vinha duas vezes (no texto e na barra),
                        // e esconder um filho dentro dele não o tira da árvore.
                        BlocoDeVidro {
                            Text("Gastos por tópico").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
                                .padding(.bottom, 8)
                            BarraDeTopicos(pedacos: pedacos, topicos: topicos)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Gastos por tópico")
                        .accessibilityValue(faladoDaBarra(pedacos, topicos: topicos))
                        .accessibilityIdentifier("gastosPorTopico")
                    }
                    // 18 pt acima dos lançamentos (mockup, .lan-cab). O id fica na linha inteira, por fora do recuo: o scrollTo
                    // da List só acha o id da linha, e a lupa rola até a pílula com os 6 pt de cima dela.
                    CabecalhoDosLancamentos(contador: contadorLancamentos(total: obra.gastos.count, achados: achados.count, filtro: busca.filtro),
                                            busca: busca, meses: mesesDoFiltro(obra.gastos, escolhido: busca.mes),
                                            comBotoes: !obra.gastos.isEmpty || filtrando || busca.aberta, foco: $foco,
                                            abrir: { abrirBusca(leitor) }, fechar: fecharBusca)
                        .padding(.top, 6)
                        .id("lancamentos")
                    if busca.aberta {
                        CampoDaBusca(texto: $busca.texto, foco: $buscaEmFoco, fechar: fecharBusca)
                            // O teclado fecha quando o dedo rola o campo para fora da tela, como na LazyVStack de antes, em
                            // que o campo saía da janela dela e perdia o foco. Na List, a célula com o foco fica viva, e o
                            // .interactively sozinho só fecha quando o arrasto chega ao teclado; o arrasto curto, com o campo
                            // à vista, segue sem fechar. Só com o dedo: quando os dados mudam (o ×, cada letra), a List refaz
                            // a linha do campo, e a visibilidade dele pisca sem ninguém rolar (no iOS 27, o campo perdia o
                            // foco no meio da busca).
                            .onScrollVisibilityChange(threshold: 0.01) { visivel in
                                if !visivel && dedoRolando { buscaEmFoco = false }
                            }
                    }
                    if !busca.mes.isEmpty {
                        ChipDoMes(mes: busca.mes, tirar: tirarOMes)
                    }
                    if let soma = somaDosAchados(achados, filtrando: filtrando) {
                        SomaDosAchadosView(soma: soma)
                            .background { QuadroProprio() }
                    }
                    if obra.gastos.isEmpty {
                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.", icone: "Icones/notas",
                                       identificador: "obraSemGastos") { EmptyView() }
                    } else if achados.isEmpty {
                        VazioDaBuscaView(vazio: vazioDaBusca(obra.gastos, texto: busca.texto, mes: busca.mes), limpar: limparFiltro,
                                         verTodos: tirarOMes)
                    } else {
                        if let aVencer = lista.aVencer {
                            CartaoDoAVencer(grupo: aVencer, aberto: filtrando ? $aVencerAbertoNaBusca : $aVencerAberto, topicos: topicos,
                                            lista: acoes)
                                .id("aVencer")
                        }
                        ForEach(lista.meses) { mes in
                            CartaoDoMes(mes: mes, topicos: topicos, lista: acoes)
                        }
                    }
                    }
                    .listSectionSpacing(16)
                }
                // Sem recuo, separador nem fundo de linha. A borda de 16 pt vem da margem da List, e não do recuo da linha: a
                // célula, que na List é o elemento de acessibilidade, fica com a largura do bloco (x 16, 370 pt num 402).
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                // O Orçamento e os afazeres (NavigationLink) sem o chevron da célula, que estreitava o bloco.
                .navigationLinkIndicatorVisibility(.hidden)
            }
            .listStyle(.plain)
            .listRowSpacing(Grade.entreBlocos)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            // Cada botão de uma linha responde ao próprio toque (a lupa e o mês ao lado da pílula), e não ao da linha inteira.
            .buttonStyle(.borderless)
            // A linha do gasto na forma mono da identidade nova (as folhas ficam com a da etapa 3).
            .environment(\.linhaMono, true)
            .contentMargins(.horizontal, Grade.externa, for: .scrollContent)
            // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
            // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
            .contentMargins(.bottom, 98, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
            // Só com a obra à vista: o gasto lançado pelo + da tela Orçamento não rola nem leva o foco aqui, por baixo dela.
            .onChange(of: folhas.destaque) { _, d in if let d, caminho.last == .obra(obra.id) { mostrar(d, lista: lista, leitor: leitor) } }
        }
        .scrollIndicators(.hidden)
        .onScrollPhaseChange { _, fase in
            if fase != .idle, linhaAberta != nil { fecharLinha() }
            dedoRolando = fase == .tracking || fase == .interacting || fase == .decelerating
        }
        .onChange(of: folhas.aberta) { _, aberta in if aberta != nil { linhaAberta = nil } }
        .onChange(of: busca.filtrando) { _, agora in if agora { aVencerAbertoNaBusca = true } }
        .onChange(of: folhas.pedidoDeApagar) { _, p in if let p, p.obraId == obra.id { apagar(p, obra: obra, lista: lista) } }
        .onDisappear { linhaAberta = nil }
        .sensoryFeedback(.success, trigger: folhas.destaque)
        .sensoryFeedback(.impact(weight: .light), trigger: mudouAFase)
        .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
            apagar(pedido, obra: obra, lista: lista)
        })
        .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
        .background {
            Color.clear
                .alert(textoDeDesfazerVenda.titulo, isPresented: $desfazendo) {
                    Button("Cancelar", role: .cancel) {}
                    Button(textoDeDesfazerVenda.botao, role: .destructive) { mudar(obra) { $0.desfazendoVenda(obra.id) } }
                } message: { Text(textoDeDesfazerVenda.mensagem) }
                .tint(paleta.cor(.texto))
        }
        .pausaOFundo(enquanto: desfazendo)
        .tituloPequenoAoRolar(barra)
        .background { LeitorDaLetra(barra: barra) }
        #if DEBUG
        .task { if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste } }
        .rolagemFixaSemFolha()
        #endif
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle(obra.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome, mono: true) }
            ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) { BotaoDeEditarObra { folhas.aberta = .editarObra(obraId: obra.id) } }
                .sharedBackgroundVisibility(.hidden)
        }
    }
}

extension ObraView {
    /// Uma ação da fase: mudar entre construção e pronta na hora, sem pergunta (o mudarFase do site), com a etiqueta e as
    /// ações trocando na mola; a venda abre a folha; desfazer pergunta.
    private func agir(_ acao: AcaoDaFase, obra: Obra) {
        switch acao {
        case .marcarPronta: mudar(obra) { $0.mudandoFase(obra.id, para: .pronta) }
        case .voltarConstrucao: mudar(obra) { $0.mudandoFase(obra.id, para: .construcao) }
        case .registrarVenda: folhas.aberta = .venda(obraId: obra.id)
        case .desfazerVenda: desfazendo = true
        }
    }

    private func mudar(_ obra: Obra, _ mudanca: (Estado) -> Estado?) {
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.35, bounce: 0)) { modelo.gravar(mudanca) }
        if resultado == .naoCarregado { naoCarregado = true }
        if resultado == .gravou { mudouAFase += 1 }
    }

    private func fecharLinha() {
        guard linhaAberta != nil else { return }
        if opcoes.reduzirMovimento { linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { linhaAberta = nil } }
    }

    /// O "A vencer" à vista agora: o da busca, com filtro, ou o de sempre.
    private var aVencerAbertoAgora: Bool { busca.filtrando ? aVencerAbertoNaBusca : aVencerAberto }

    private func abrirAVencer() {
        if busca.filtrando { aVencerAbertoNaBusca = true } else { aVencerAberto = true }
    }

    /// A lupa: abre o campo embaixo da pílula, rola a lista até a pílula e põe o teclado; com o campo aberto, só devolve o
    /// foco a ele.
    private func abrirBusca(_ leitor: ScrollViewProxy) {
        let rolar = !busca.aberta
        busca.aberta = true
        Task { @MainActor in
            if rolar {
                withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo("lancamentos", anchor: .top) }
            }
            buscaEmFoco = true
        }
    }

    /// O × da busca (ou a lupa, na maior letra): fecha o campo e limpa o texto; o VoiceOver vai para "Lançamentos".
    private func fecharBusca() {
        buscaEmFoco = false
        busca.fechar()
        foco = .lancamentos
    }

    /// O × do chip e o "Ver todos os meses": tira o mês (a busca fica).
    private func tirarOMes() {
        busca.mes = ""
        foco = .lancamentos
    }

    /// "Limpar a busca", "Limpar o mês" ou "Limpar busca e mês".
    private func limparFiltro() {
        busca.limpar()
        foco = .lancamentos
    }

    /// Depois de salvar: rola em dois tempos (o cartão, que a LazyVStack cria, e depois a linha), abre o "A vencer" se o
    /// gasto foi para lá, acende por 2 s e leva o VoiceOver para a linha.
    private func mostrar(_ d: Folhas.Destaque, lista: ListaDaObra, leitor: ScrollViewProxy) {
        guard let primeiro = d.ids.first else { return }
        let noAVencer = lista.aVencer?.meses.contains { $0.gastos.contains { $0.id == primeiro } } ?? false
        let cartao = noAVencer ? "aVencer" : lista.meses.first { $0.gastos.contains { $0.id == primeiro } }.map(\.id)
        acesos = Set(d.ids)
        novos = d.novo
        Task { @MainActor in
            if let cartao { leitor.scrollTo(cartao, anchor: .center) }
            // O "A vencer" abre depois de a lista chegar nele, ainda fechado: aberto antes, na maior letra (milhares de
            // pontos que a LazyVStack ainda não criou), a rolagem parava num mês lá embaixo.
            if noAVencer {
                try? await Task.sleep(for: .milliseconds(80))
                abrirAVencer()
            }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo(primeiro, anchor: .center) }
            try? await Task.sleep(for: .milliseconds(450))
            foco = .gasto(primeiro)
            try? await Task.sleep(for: .seconds(2))
            guard folhas.destaque == d else { return }
            withAnimation(.easeOut(duration: 0.4)) { acesos = [] }
        }
    }

    /// Apaga um gasto (ou a compra toda) com a animação do sistema: a linha sai pela esquerda, as de baixo sobem e os
    /// totais mudam na mesma transação. Depois, o VoiceOver vai para a linha vizinha (ou para "Lançamentos") e ouve o
    /// que aconteceu, um depois do outro.
    private func apagar(_ p: Folhas.PedidoDeApagar, obra: Obra, lista: ListaDaObra) {
        let saem: Set<String> = p.grupoId.map { g in Set(obra.gastos.filter { $0.grupoId == g }.map(\.id)) } ?? [p.gastoId]
        let ordem = (aVencerAbertoAgora ? (lista.aVencer?.meses ?? []) : []).flatMap(\.gastos).map(\.id)
            + lista.meses.flatMap(\.gastos).map(\.id)
        let vizinho = vizinhoDepoisDeApagar(saem, ordem: ordem)
        // A linha sai aberta, com o "Apagar": fechar antes, fora da transação, a fazia voltar num quadro e só então sair.
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
            linhaAberta = nil
            return modelo.gravar { e in p.grupoId.map { e.apagandoCompra($0, daObra: p.obraId) } ?? e.apagandoGasto(p.gastoId, daObra: p.obraId) }
        }
        if resultado == .naoCarregado { naoCarregado = true; return }
        guard resultado == .gravou else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            foco = vizinho.map(AlvoDoFoco.gasto) ?? .lancamentos
            try? await Task.sleep(for: .milliseconds(700))
            var aviso = AttributedString(saem.count > 1 ? "Compra apagada" : "Gasto apagado")
            aviso.accessibilitySpeechAnnouncementPriority = .low
            AccessibilityNotification.Announcement(aviso).post()
        }
    }
}

/// Onde o VoiceOver vai depois de apagar: a próxima linha que fica na lista, senão a anterior; nil, "Lançamentos".
func vizinhoDepoisDeApagar(_ saem: Set<String>, ordem: [String]) -> String? {
    guard let i = ordem.firstIndex(where: saem.contains) else { return nil }
    return ordem[i...].first { !saem.contains($0) } ?? ordem[..<i].last { !saem.contains($0) }
}

/// Para onde o VoiceOver vai na lista da obra e na de uma folha de origem.
enum AlvoDoFoco: Hashable {
    case gasto(String)
    case lancamentos
    /// O cartão do vazio de uma folha de origem (o A pagar sem nenhum vencimento).
    case vazio
}

/// O que as linhas da lista fazem, passado do ObraView aos cartões.
struct AcoesDaLista {
    let aberta: Binding<String?>
    let acesos: Set<String>
    let novos: Bool
    let foco: AccessibilityFocusState<AlvoDoFoco?>.Binding
    let tocar: (Gasto) -> Void
    let apagar: (Gasto) -> Void
}

/// Uma linha de gasto na lista: tocar edita, arrastar mostra "Apagar", acende depois de salvar. Para o VoiceOver é um
/// botão (abre a edição) com a ação "Apagar"; o Controle por Voz chama pelo título.
struct LinhaDaLista: View {
    let gasto: Gasto
    let linha: LinhaDeGasto
    let lista: AcoesDaLista

    var body: some View {
        LinhaArrastavel(id: gasto.id, aberta: lista.aberta, apagar: { lista.apagar(gasto) }) {
            LinhaDeGastoView(gasto: gasto, linha: linha, acesa: lista.acesos.contains(gasto.id), novo: lista.novos)
                .onTapGesture { lista.tocar(gasto) }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { lista.tocar(gasto) }
                .accessibilityInputLabels([linha.titulo])
                .accessibilityFocused(lista.foco, equals: .gasto(gasto.id))
        }
        .id(gasto.id)
        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
    }
}

/// Se o título pequeno aparece na barra da obra.
@MainActor @Observable
final class BarraDaObra {
    var tituloVisivel = false
    /// A letra da tela, para o título pequeno mono: dentro do ToolbarItem, o dynamicTypeSize para antes da letra de
    /// acessibilidade. Mora aqui, e não num @Environment da ObraView: só o título pequeno se refaz quando a letra muda (a
    /// obra inteira refeita pesava a troca por trás da folha; o toque duplo é segurado pela marca `gravado` do rascunho
    /// do gasto, na FolhaDoGasto).
    var letra: DynamicTypeSize = .large
}

/// Lê a letra da tela fora da barra e a guarda na BarraDaObra: só o título pequeno se refaz quando ela muda.
private struct LeitorDaLetra: View {
    let barra: BarraDaObra
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: letra, initial: true) { _, nova in if barra.letra != nova { barra.letra = nova } }
    }
}

extension View {
    /// O título pequeno entra na barra quando o grande sai de baixo dela, como o título grande do sistema (a obra e a tela
    /// Orçamento). Só esmaece, sem movimento: fica igual com Reduzir movimento.
    func tituloPequenoAoRolar(_ barra: BarraDaObra) -> some View {
        onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
            withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
        }
    }
}

/// O título pequeno só existe depois que o grande sai de baixo da barra, e sai enquanto a pílula de sincronização aparece
/// (na barra não cabem os dois com o voltar e o lápis). Fora disso, nem fica invisível na árvore; vazio, a barra
/// mostraria o título do sistema (branco) por cima do título grande.
struct TituloDaBarraDaObra: View {
    let barra: BarraDaObra
    let nome: String
    /// O título pequeno em SF Mono da identidade nova (a obra, desde a etapa 4), na letra da tela, lida fora da barra
    /// (`barra.letra`); a tela Orçamento fica com o de antes.
    var mono = false
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        if barra.tituloVisivel && indicador(modelo.sincronizador.estadoSinc) == nil {
            Group {
                if mono { TituloPequenoMono(texto: nome, letra: barra.letra) } else { TituloPequenoDaBarra(nome: nome) }
            }
            .transition(.opacity)
        } else {
            Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
        }
    }
}

/// O nome da obra na barra, depois de rolar: uma linha só, até 236 pt, como o título pequeno do sistema (que corta o nome
/// longo em vez de empurrar o voltar e o lápis). Na letra grande para perto de 22 pt (mockup) e mostra o Visualizador de
/// Conteúdo Grande, como a cápsula de abas.
struct TituloPequenoDaBarra: View {
    let nome: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(nome)
            .font(.headline)
            .foregroundStyle(paleta.cor(.texto))
            .lineLimit(1)
            .frame(maxWidth: 236)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityAddTraits(.isHeader)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("tituloPequenoDaBarra")
    }
}

/// O "A vencer": fechado, uma linha; aberto, o mesmo cartão com os meses futuros dentro.
struct CartaoDoAVencer: View {
    let grupo: GrupoAVencer
    @Binding var aberto: Bool
    let topicos: [String: Topico]
    let lista: AcoesDaLista
    @Environment(\.opcoes) private var opcoes
    @Environment(\.paleta) private var paleta

    var body: some View {
        CartaoDaLista {
            LinhaDoAVencer(grupo: grupo, aberto: aberto)
                .onTapGesture(perform: alternar)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("A vencer, \(moeda(grupo.total)), \(grupo.resumo.replacingOccurrences(of: " · ", with: ", "))")
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(aberto ? "aberto" : "fechado")
                .accessibilityHint(aberto ? "Fecha os gastos a vencer" : "Mostra os gastos a vencer")
                .accessibilityAction { alternar() }
                .accessibilityIdentifier("aVencer")
            if aberto {
                ForEach(grupo.meses) { mes in
                    CabecalhoDoMes(mes: mes)
                    linhas(mes)
                }
                Color.clear.frame(height: 6)             // só no fim do cartão, como no do mês
            }
        }
    }

    private func alternar() {
        // Com uma linha aberta, o toque só fecha a linha.
        if lista.aberta.wrappedValue != nil {
            if opcoes.reduzirMovimento { lista.aberta.wrappedValue = nil }
            else { withAnimation(.spring(duration: 0.3, bounce: 0)) { lista.aberta.wrappedValue = nil } }
            return
        }
        if opcoes.reduzirMovimento { aberto.toggle() } else { withAnimation(.snappy) { aberto.toggle() } }
    }

    @ViewBuilder private func linhas(_ mes: MesDeGastos) -> some View {
        ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
            if i > 0 { SeparadorDaLista() }
            LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
        }
    }
}

/// Um mês: o cartão de vidro com o cabeçalho e as linhas sólidas dentro.
struct CartaoDoMes: View {
    let mes: MesDeGastos
    let topicos: [String: Topico]
    let lista: AcoesDaLista
    @Environment(\.paleta) private var paleta

    var body: some View {
        CartaoDaLista {
            CabecalhoDoMes(mes: mes)
            ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
                if i > 0 { SeparadorDaLista() }
                LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
            }
            Color.clear.frame(height: 6)
        }
    }
}

/// A linha fina entre dois gastos de um cartão: depois do ícone, na linha da etapa 3; na mono, nos 18 pt do recuo dos dois
/// lados, como na vitrine das peças.
struct SeparadorDaLista: View {
    @Environment(\.linhaMono) private var mono

    var body: some View {
        if mono { LinhaFina().padding(.horizontal, Grade.recuo) } else { LinhaFina().padding(.leading, 67) }
    }
}

/// O quadro próprio de uma peça sozinha numa linha da List (o título, a cápsula, a soma dos achados): uma vista vazia do
/// UIKit no fundo da linha. Sem ela, a célula inteira vira o elemento de acessibilidade, e o anel do VoiceOver toma a linha
/// toda (a cápsula com 370 pt de largura, e não os 269 dela). Com ela, a célula vira um contêiner, e a peça fica com o quadro
/// dela, igual ao da ScrollView. Depende de a List ser uma UICollectionView, como a ponte; o testOAltoEmBlocosNaGrade vigia.
private struct QuadroProprio: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let vista = UIView()
        vista.isUserInteractionEnabled = false
        return vista
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
