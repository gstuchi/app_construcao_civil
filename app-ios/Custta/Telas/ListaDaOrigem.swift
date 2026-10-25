import SwiftUI
import CusttaNucleo

/// A lista de uma folha de origem (a do A pagar; o detalhe do tópico monta a mesma): a folha dá as peças, a linha de cada
/// gasto, o cabeçalho, o vazio e o rodapé, e a lista faz o que é igual nas duas. Tocar num gasto empurra a edição na mesma
/// folha (a volta à folha de origem, FolhaDeOrigem.swift); arrastar uma linha para a esquerda mostra "Apagar", como na
/// lista da obra. As peças (cabeçalho de mês ou de seção e gasto) são filhas diretas da LazyVStack, com o fundo do grupo
/// desenhado por peça: a pilha só fatia filhos diretos, e um grupo inteiro num VStack seria uma peça só (o detalhe do tópico
/// passa de cem gastos). O cabeçalho do mês fica dentro do grupo, com os cantos de cima; o da seção, fora, e os cantos vão no
/// primeiro gasto. A lista não fecha a folha: a do detalhe desce sozinha sem gasto, e o `desceSemGasto` só cala o "O gasto
/// saiu desta lista." da última linha.
struct ListaDaOrigem<Cabecalho: View, Vazio: View, Rodape: View>: View {
    let obra: Obra
    @Bindable var origem: OrigemDaEdicao
    /// As peças, na ordem da tela: a ordem das linhas é a dos gastos nelas.
    let pecas: [PecaDaOrigem]
    /// As peças na obra já gravada: dizem para onde o VoiceOver vai depois de apagar.
    let pecasDepois: (Obra) -> [PecaDaOrigem]
    let linha: (Gasto) -> LinhaDeGasto
    /// A folha desce quando a lista fica sem gasto (o detalhe do tópico; o A pagar fica aberto, com o vazio, como no site).
    let desceSemGasto: Bool
    let cabecalho: Cabecalho
    /// O cartão de quando não há peça nenhuma, com o foco do VoiceOver de quando a última linha sai.
    let vazio: Vazio
    let rodape: Rodape
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.opcoes) private var opcoes
    /// Para onde o VoiceOver vai quando a edição volta ou uma linha sai.
    @AccessibilityFocusState private var foco: AlvoDoFoco?
    /// "Apagar" tocado na linha: o gasto da pergunta. Fica depois que o alerta fecha, para ele não trocar de texto saindo.
    @State private var alvoDoApagar: Gasto?
    @State private var perguntando = false
    @State private var naoCarregado = false

    init(obra: Obra, origem: OrigemDaEdicao, pecas: [PecaDaOrigem], pecasDepois: @escaping (Obra) -> [PecaDaOrigem],
         linha: @escaping (Gasto) -> LinhaDeGasto, desceSemGasto: Bool = false, @ViewBuilder cabecalho: () -> Cabecalho,
         @ViewBuilder vazio: () -> Vazio, @ViewBuilder rodape: () -> Rodape) {
        self.obra = obra
        _origem = Bindable(origem)
        self.pecas = pecas
        self.pecasDepois = pecasDepois
        self.linha = linha
        self.desceSemGasto = desceSemGasto
        self.cabecalho = cabecalho()
        self.vazio = vazio()
        self.rodape = rodape()
    }

    var body: some View {
        let ordem = ordemDasLinhas(pecas)
        let acoes = AcoesDaLista(aberta: $origem.linhaAberta, acesos: origem.acesos, novos: false, foco: $foco,
                                 tocar: { gasto in
                                     if origem.linhaAberta != nil { fecharLinha(); return }
                                     editar(gasto, obra: obra, ordem: ordem)
                                 },
                                 apagar: { gasto in
                                     alvoDoApagar = gasto
                                     perguntando = true
                                 })
        ScrollViewReader { leitor in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    cabecalho
                    if pecas.isEmpty {
                        vazio
                            .accessibilityFocused($foco, equals: .vazio)
                            .padding(.top, 20)
                    }
                    ForEach(pecas) { peca in
                        switch peca.tipo {
                        case .mes(let mes):
                            CabecalhoDoMes(mes: mes)
                                .modifier(FundoDoGrupo(cima: true, baixo: false))
                                .padding(.top, 20)
                        case .secao(let titulo, let quantidade):
                            CabecalhoDaSecao(titulo: titulo, quantidade: quantidade)
                        case .gasto(let gasto):
                            LinhaDaLista(gasto: gasto, linha: linha(gasto), lista: acoes)
                                .overlay(alignment: .top) { if !peca.primeiro { SeparadorDaFolha(recuo: 67) } }
                                .modifier(FundoDoGrupo(cima: peca.cima, baixo: peca.ultimo))
                        }
                    }
                    rodape
                }
                .padding(.top, 4)
                .padding(.bottom, 48)
                // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
                .contentShape(.rect)
                .onTapGesture { if origem.linhaAberta != nil { fecharLinha() } }
            }
            #if DEBUG
            // Laudo: a lista parada numa rolagem dada (`-custta.rolagem`); sem o argumento, nada muda.
            .rolagemFixaSoComOArgumento()
            #endif
            .onScrollPhaseChange { _, fase in if fase != .idle, origem.linhaAberta != nil { fecharLinha() } }
            .onChange(of: origem.volta) { _, volta in if let volta { voltou(volta, depois: ordem, leitor: leitor) } }
        }
        #if DEBUG
        .task { abrirAEdicaoDoTeste(ordem: ordem) }
        #endif
        .environment(\.dentroDaFolha, true)
        .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
            apagar(pedido, antes: ordem, depoisDoVoltar: false)
        })
        .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
        .pausaOFundo(enquanto: naoCarregado)
    }

    private func editar(_ gasto: Gasto, obra: Obra, ordem: [String]) {
        let estado = modelo.sincronizador.estado
        let rascunho = RascunhoDoGasto(obra: obra, editado: gasto, todas: estado.obras, proprios: estado.config.topicosProprios,
                                       hoje: dataLocalISO(.now, fuso: .current))
        #if DEBUG
        // Teste de tela: a data da edição trocada para daqui a N dias (`-custta.dataDaEdicao N`), sem passar pelo calendário.
        if let dias = Int(UserDefaults.standard.string(forKey: "custta.dataDaEdicao") ?? ""),
           let dia = Calendar(identifier: .gregorian).date(byAdding: .day, value: dias, to: .now) {
            rascunho.data = dataLocalISO(dia, fuso: .current)
        }
        #endif
        origem.abrir(rascunho, ordem: ordem)
    }

    private func fecharLinha() {
        guard origem.linhaAberta != nil else { return }
        if opcoes.reduzirMovimento { origem.linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { origem.linhaAberta = nil } }
    }

    /// A edição voltou. No "Salvar", a linha fica onde está se continua à vista (a data nova pode tê-la mudado de lugar; se
    /// saiu da vista, a lista rola o mínimo até ela) e apaga a luz em 2 s. No "Apagar", a linha sai no turno seguinte ao
    /// voltar, com a animação dela (no mesmo turno, as transações do voltar e do apagar se misturariam). O VoiceOver vai para
    /// onde o `focoNaOrigem` diz, quando o voltar termina, e ouve depois o que aconteceu; o "Salvar" que tirou a última linha
    /// de uma folha que desce sem gasto, nada (quem ouve já está na tela de trás).
    private func voltou(_ volta: OrigemDaEdicao.Volta, depois: [String], leitor: ScrollViewProxy) {
        let saida: SaidaDaLinha
        switch volta.motivo {
        case .salvou(let id):
            saida = .salvou(id)
            if depois.contains(id) {
                Task { @MainActor in
                    withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo(id) }
                }
            }
            let vez = origem.vezDoAceso
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard origem.vezDoAceso == vez else { return }
                withAnimation(.easeOut(duration: 0.4)) { origem.acesos = [] }
            }
        case .voltou(let id):
            saida = .voltou(id)
        case .sumiu(let id):
            saida = .sumiu(id)
        case .apagou(let pedido):
            Task { @MainActor in apagar(pedido, antes: volta.ordem, depoisDoVoltar: true) }
            return
        }
        if desceSemGasto, depois.isEmpty, case .salvou = saida { return }
        let destino = focoNaOrigem(saida, antes: volta.ordem, depois: depois)
        Task { @MainActor in
            try? await Task.sleep(for: OrigemDaEdicao.fimDoVoltar)
            foco = destino.alvo
            guard let anuncio = destino.anuncio else { return }
            try? await Task.sleep(for: .milliseconds(700))
            anunciar(anuncio)
        }
    }

    /// Apaga um gasto (ou a compra toda) com a animação da lista da obra: a linha sai pela esquerda, as de baixo sobem e os
    /// totais mudam na mesma transação; a lista não fecha a folha (o A pagar fica aberto, mesmo vazio, como no site). O
    /// VoiceOver vai depois para a vizinha (ou para o cartão do vazio) e ouve o que aconteceu, nos tempos da lista da obra;
    /// vindo da edição, contados do fim do voltar. `antes` é a ordem das linhas antes de apagar.
    private func apagar(_ p: Folhas.PedidoDeApagar, antes: [String], depoisDoVoltar: Bool) {
        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == p.obraId }) else { return }
        let saem: Set<String> = p.grupoId.map { g in Set(obra.gastos.filter { $0.grupoId == g }.map(\.id)) } ?? [p.gastoId]
        // A linha sai aberta, com o "Apagar": fechar antes, fora da transação, a fazia voltar num quadro e só então sair.
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
            origem.linhaAberta = nil
            return modelo.gravar { e in p.grupoId.map { e.apagandoCompra($0, daObra: p.obraId) } ?? e.apagandoGasto(p.gastoId, daObra: p.obraId) }
        }
        if resultado == .naoCarregado { naoCarregado = true; return }
        guard resultado == .gravou else { return }
        let depois = modelo.sincronizador.estado.obras.first { $0.id == p.obraId }
            .map { ordemDasLinhas(pecasDepois($0)) } ?? []
        let destino = focoNaOrigem(.apagou(saem, compra: saem.count > 1), antes: antes, depois: depois)
        Task { @MainActor in
            if depoisDoVoltar { try? await Task.sleep(for: OrigemDaEdicao.fimDoVoltar) }
            try? await Task.sleep(for: .milliseconds(500))
            foco = destino.alvo
            guard let anuncio = destino.anuncio else { return }
            try? await Task.sleep(for: .milliseconds(700))
            anunciar(anuncio)
        }
    }

    private func anunciar(_ texto: String) {
        var aviso = AttributedString(texto)
        aviso.accessibilitySpeechAnnouncementPriority = .low
        AccessibilityNotification.Announcement(aviso).post()
    }
}

#if DEBUG
extension ListaDaOrigem {
    /// Laudo e conferência visual: `-custta.origem editar:<gasto>` abre a folha com a edição do gasto já empurrada, como o
    /// toque na linha. Uma vez: a lista que volta da edição já tem a `volta` e não empurra de novo. Sem o argumento, nada.
    fileprivate func abrirAEdicaoDoTeste(ordem: [String]) {
        guard origem.volta == nil, let pedido = UserDefaults.standard.string(forKey: "custta.origem"), pedido.hasPrefix("editar:"),
              let gasto = obra.gastos.first(where: { $0.id == String(pedido.dropFirst(7)) }) else { return }
        editar(gasto, obra: obra, ordem: ordem)
    }
}
#endif

/// A ordem das linhas: os gastos das peças, na ordem delas.
private func ordemDasLinhas(_ pecas: [PecaDaOrigem]) -> [String] {
    pecas.compactMap { peca -> String? in
        guard case .gasto(let gasto) = peca.tipo else { return nil }
        return gasto.id
    }
}
