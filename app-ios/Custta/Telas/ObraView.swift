import SwiftUI
import CusttaNucleo

/* A tela da obra (mockup aprovado da etapa 2, partes 1 e 3): o nome no título grande, a pílula da fase e do tempo, os
   indicadores na opção A, as ações da fase, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado
   no alto; o lápis na barra abre "Editar obra". Entra pelo push do NavigationStack de Obras e volta pelo círculo e pela
   borda (sistema). A obra que some (apagada em outro aparelho) fecha a tela, como o site volta ao Início. Na etapa 3, a
   busca e o mês ao lado da pílula filtram só a lista (BuscaDaObra.swift); indicadores e orçamento ficam com a obra inteira. */
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
            ScrollView {
                // As peças de cima, do título à soma dos achados, ficam fora da pilha preguiçosa, que fica só com a lista: no
                // iOS 26, a LazyVStack refazia o campo da busca à vista quando o teclado subia, e o foco caía (sonda do foco,
                // run 40508695109; o teclado foi embora no run 40440188222).
                VStack(alignment: .leading, spacing: 10) {
                    TituloDaObra(nome: obra.nome)
                    PilulaDaFase(obra: obra, hoje: hoje)
                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra),
                                          rotaDoOrcamento: .orcamento(obra.id)) {
                        // Com uma linha arrastada aberta, o toque só a fecha, como o das linhas.
                        if linhaAberta != nil { fecharLinha(); return }
                        folhas.aberta = .aPagar(obraId: obra.id)
                    }
                    AcoesDaFaseView(fase: obra.fase,
                                    definirOrcamento: pecasOrcamento(obra).definir ? { folhas.aberta = .orcamento(obraId: obra.id) } : nil) {
                        agir($0, obra: obra)
                    }
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                    // Os afazeres, 12 abaixo das ações e 24 acima dos lançamentos (mockup da etapa 3), em todas as fases.
                    NavigationLink(value: RotaDeObras.afazeres(obra.id)) {
                        LinhaDosAfazeresView(linha: linhaDosAfazeres(obra.afazeres))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 14)
                    CabecalhoDosLancamentos(contador: contadorLancamentos(total: obra.gastos.count, achados: achados.count, filtro: busca.filtro),
                                            busca: busca, meses: mesesDoFiltro(obra.gastos, escolhido: busca.mes),
                                            comBotoes: !obra.gastos.isEmpty || filtrando || busca.aberta, foco: $foco,
                                            abrir: { abrirBusca(leitor) }, fechar: fecharBusca)
                        .id("lancamentos")
                    if busca.aberta {
                        CampoDaBusca(texto: $busca.texto, foco: $buscaEmFoco, fechar: fecharBusca)
                    }
                    if !busca.mes.isEmpty {
                        ChipDoMes(mes: busca.mes, tirar: tirarOMes)
                    }
                    if let soma = somaDosAchados(achados, filtrando: filtrando) {
                        SomaDosAchadosView(soma: soma)
                    }
                    if obra.gastos.isEmpty {
                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.", icone: "Icones/notas",
                                       identificador: "obraSemGastos") { EmptyView() }
                    } else if achados.isEmpty {
                        VazioDaBuscaView(vazio: vazioDaBusca(obra.gastos, texto: busca.texto, mes: busca.mes), limpar: limparFiltro,
                                         verTodos: tirarOMes)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if let aVencer = lista.aVencer {
                                CartaoDoAVencer(grupo: aVencer, aberto: filtrando ? $aVencerAbertoNaBusca : $aVencerAberto,
                                                topicos: topicos, lista: acoes)
                                    .id("aVencer")
                            }
                            ForEach(lista.meses) { mes in
                                CartaoDoMes(mes: mes, topicos: topicos, lista: acoes)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
                // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
                .padding(.bottom, 98)
                // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
                .contentShape(.rect)
                .onTapGesture { if linhaAberta != nil { fecharLinha() } }
            }
            // Só com a obra à vista: o gasto lançado pelo + da tela Orçamento não rola nem leva o foco aqui, por baixo dela.
            .onChange(of: folhas.destaque) { _, d in if let d, caminho.last == .obra(obra.id) { mostrar(d, lista: lista, leitor: leitor) } }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
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
        #if DEBUG
        .task { if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste } }
        .modifier(RolagemFixaDoTeste())
        #endif
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle(obra.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome) }
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
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        if barra.tituloVisivel && indicador(modelo.sincronizador.estadoSinc) == nil {
            TituloPequenoDaBarra(nome: nome).transition(.opacity)
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
            if i > 0 { LinhaFina().padding(.leading, 67) }
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
                if i > 0 { LinhaFina().padding(.leading, 67) }
                LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
            }
            Color.clear.frame(height: 6)
        }
    }
}
