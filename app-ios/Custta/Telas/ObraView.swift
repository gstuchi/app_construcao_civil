import SwiftUI
import CusttaNucleo

/* A tela da obra (mockup aprovado da etapa 2, partes 1 e 3): o nome no título grande, a pílula da fase e do tempo, os
   indicadores na opção A, as ações da fase, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado
   no alto; o lápis na barra abre "Editar obra". Entra pelo push do NavigationStack de Obras e volta pelo círculo e pela
   borda (sistema). A obra que some (apagada em outro aparelho) fecha a tela, como o site volta ao Início. */
struct ObraView: View {
    let id: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.opcoes) private var opcoes
    @Environment(\.paleta) private var paleta
    @State private var aVencerAberto = false
    /// A linha arrastada que mostra "Apagar" (uma por vez).
    @State private var linhaAberta: String?
    /// "Apagar" tocado na linha: o gasto da pergunta. Fica depois que o alerta fecha, para ele não trocar de texto saindo.
    @State private var alvoDoApagar: Gasto?
    @State private var perguntando = false
    @State private var naoCarregado = false
    @State private var contaReal = false
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
    /// Laudo de leitura e conferência visual: a tela parada numa rolagem dada, em pt (o mesmo gancho de Obras).
    @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
    /// Laudo e conferência visual: a linha que abre mostrando "Apagar" (`-custta.linhaAberta g027`).
    @AppStorage("custta.linhaAberta") private var linhaDeTeste = ""
    @State private var posicao = ScrollPosition(edge: .top)
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
        let lista = listaDaObra(obra, hoje: hoje)
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
                LazyVStack(alignment: .leading, spacing: 10) {
                    TituloDaObra(nome: obra.nome)
                    PilulaDaFase(obra: obra, hoje: hoje)
                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
                    AcoesDaFaseView(fase: obra.fase) { agir($0, obra: obra) }
                        .padding(.top, 2)
                        .padding(.bottom, 14)
                    PilulaDeLancamentos(quantidade: obra.gastos.count)
                        .accessibilityFocused($foco, equals: .lancamentos)
                    if obra.gastos.isEmpty {
                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.", icone: "Icones/notas",
                                       identificador: "obraSemGastos") { EmptyView() }
                    } else {
                        if let aVencer = lista.aVencer {
                            CartaoDoAVencer(grupo: aVencer, aberto: $aVencerAberto, topicos: topicos, lista: acoes)
                                .id("aVencer")
                        }
                        ForEach(lista.meses) { mes in
                            CartaoDoMes(mes: mes, topicos: topicos, lista: acoes)
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
            .onChange(of: folhas.destaque) { _, d in if let d { mostrar(d, lista: lista, leitor: leitor) } }
        }
        .scrollIndicators(.hidden)
        .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
        .onChange(of: folhas.aberta) { _, aberta in if aberta != nil { linhaAberta = nil } }
        .onChange(of: folhas.pedidoDeApagar) { _, p in if let p, p.obraId == obra.id { apagar(p, obra: obra, lista: lista) } }
        .onDisappear { linhaAberta = nil }
        .sensoryFeedback(.success, trigger: folhas.destaque)
        .sensoryFeedback(.impact(weight: .light), trigger: mudouAFase)
        .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
            apagar(pedido, obra: obra, lista: lista)
        })
        .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
        .background {
            Color.clear
                .alert(textoDeDesfazerVenda.titulo, isPresented: $desfazendo) {
                    Button("Cancelar", role: .cancel) {}
                    Button(textoDeDesfazerVenda.botao, role: .destructive) { mudar(obra) { $0.desfazendoVenda(obra.id) } }
                } message: { Text(textoDeDesfazerVenda.mensagem) }
                .tint(paleta.cor(.texto))
        }
        .pausaOFundo(enquanto: desfazendo)
        // O título pequeno entra na barra quando o grande sai de baixo dela (como o título grande do sistema).
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
            withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
        }
        #if DEBUG
        .scrollPosition($posicao)
        .task {
            if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste }
            guard rolagemFixa >= 0 else { return }
            try? await Task.sleep(for: .milliseconds(300))
            posicao.scrollTo(y: rolagemFixa)
        }
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
        if resultado == .contaReal { contaReal = true }
        if resultado == .gravou { mudouAFase += 1 }
    }

    private func fecharLinha() {
        guard linhaAberta != nil else { return }
        if opcoes.reduzirMovimento { linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { linhaAberta = nil } }
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
                aVencerAberto = true
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
        let ordem = (aVencerAberto ? (lista.aVencer?.meses ?? []) : []).flatMap(\.gastos).map(\.id)
            + lista.meses.flatMap(\.gastos).map(\.id)
        let vizinho = vizinhoDepoisDeApagar(saem, ordem: ordem)
        // A linha sai aberta, com o "Apagar": fechar antes, fora da transação, a fazia voltar num quadro e só então sair.
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
            linhaAberta = nil
            return modelo.gravar { e in p.grupoId.map { e.apagandoCompra($0, daObra: p.obraId) } ?? e.apagandoGasto(p.gastoId, daObra: p.obraId) }
        }
        if resultado == .naoCarregado { naoCarregado = true; return }
        if resultado == .contaReal { contaReal = true; return }
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

/// Para onde o VoiceOver vai na lista da obra.
enum AlvoDoFoco: Hashable {
    case gasto(String)
    case lancamentos
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
