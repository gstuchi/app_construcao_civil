import SwiftUI
import CusttaNucleo

/* A folha "A pagar · 30 dias" (mockup da etapa 3, parte 2, seção 1; o sheetAPagar do site), aberta pela seta do indicador:
   o mesmo total e os mesmos vencimentos do indicador, a partir de amanhã, num grupo de resumo; os vencimentos por mês,
   como no "A vencer", com a linha de gasto da etapa 2 e sem a etiqueta "a vencer" em cada linha (aqui tudo vence); no fim,
   a frase do que vem depois dos 30 dias, que está no "A vencer" da obra. Vazia, abre com "Nenhum gasto previsto para esse
   período." e não fecha quando fica vazia (site); fecham o × e o puxar (o "Fechar" do site sai). Tocar num vencimento
   empurra a edição na mesma folha (a volta à folha de origem, FolhaDeOrigem.swift). Dentro da folha tudo é sólido. */
struct FolhaDoAPagar: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
    @State private var alertas = AlertasNaFolha()

    private var obra: Obra? { modelo.sincronizador.estado.obras.first { $0.id == obraId } }

    var body: some View {
        NavigationStack(path: $origem.caminho) {
            ListaDoAPagar(obraId: obraId, origem: origem)
                .passoDaFolha(origem.titulo, subtitulo: obra?.nome, fechar: .esquerda, escape: .fechar)
                .navigationDestination(for: PassoDaOrigem.self) { passo in
                    DestinoNaOrigem(passo: passo, origem: origem)
                }
        }
        // O "Não salvou" de uma edição salva aqui: a folha de origem não desce, e o da raiz só aparece com a folha fechada.
        .alertaDeNaoSalvou(quando: alertas.nenhum)
        // A trava do puxar fica fora da pilha: dentro do passo, ela não chega à folha (medido em 19/10). Quem lê a mudança é
        // o próprio FolhaDoApp, e não este corpo, para cada tecla da descrição não refazer a lista.
        .folhaDoApp(perguntar: { origem.temOQuePerder }, pergunta: "Você mudou este gasto.",
                    mensagem: "As mudanças ainda não foram salvas.", descartar: "Descartar mudanças") { folhas.fechar() }
        .environment(\.alertasNaFolha, alertas)
        // A obra apagada em outro aparelho com a folha aberta: não há o que mostrar; a folha fecha.
        .onChange(of: obra == nil) { _, sumiu in if sumiu { folhas.fechar() } }
    }
}

/// O resumo, os vencimentos por mês e a frase do fim. As peças da lista (cabeçalho de mês e gasto) são filhas diretas da
/// LazyVStack, com o fundo do grupo desenhado por peça: a pilha só fatia filhos diretos, e um grupo inteiro num VStack seria
/// uma peça só (o detalhe do tópico, com a mesma lista, passa de cem gastos). Arrastar uma linha para a esquerda mostra
/// "Apagar", como na lista da obra; a folha fica aberta.
private struct ListaDoAPagar: View {
    let obraId: String
    @Bindable var origem: OrigemDaEdicao
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.opcoes) private var opcoes
    /// Para onde o VoiceOver vai quando a edição volta ou uma linha sai.
    @AccessibilityFocusState private var foco: AlvoDoFoco?
    /// "Apagar" tocado na linha: o gasto da pergunta. Fica depois que o alerta fecha, para ele não trocar de texto saindo.
    @State private var alvoDoApagar: Gasto?
    @State private var perguntando = false
    @State private var naoCarregado = false

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == obraId }) {
            let aPagar = aPagarDaObra(obra, hoje: dataLocalISO(.now, fuso: .current))
            let topicos = mapaDeTopicos(estado.config.topicosProprios)
            let pecas = pecasDaOrigem(aPagar.meses)
            let ordem = aPagar.meses.flatMap(\.gastos).map(\.id)
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
                        ResumoDoAPagar(total: aPagar.total, qtd: aPagar.qtd)
                        if aPagar.meses.isEmpty {
                            VazioDoAPagar()
                                .accessibilityFocused($foco, equals: .vazio)
                                .padding(.top, 20)
                        }
                        ForEach(pecas) { peca in
                            switch peca.tipo {
                            case .mes(let mes):
                                CabecalhoDoMes(mes: mes)
                                    .modifier(FundoDoGrupo(cima: true, baixo: false))
                                    .padding(.top, 20)
                            case .gasto(let gasto):
                                LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: acoes)
                                    .overlay(alignment: .top) { if !peca.primeiro { SeparadorDaFolha(recuo: 67) } }
                                    .modifier(FundoDoGrupo(cima: false, baixo: peca.ultimo))
                            }
                        }
                        if let ponte = aPagar.ponte {
                            NotaDaFolha(texto: ponte, identificador: "ponteDoAPagar").padding(.top, 14)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 48)
                    // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
                    .contentShape(.rect)
                    .onTapGesture { if origem.linhaAberta != nil { fecharLinha() } }
                }
                .onScrollPhaseChange { _, fase in if fase != .idle, origem.linhaAberta != nil { fecharLinha() } }
                .onChange(of: origem.volta) { _, volta in if let volta { voltou(volta, depois: ordem, leitor: leitor) } }
            }
            .environment(\.dentroDaFolha, true)
            .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
                apagar(pedido, antes: ordem, depoisDoVoltar: false)
            })
            .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
            .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
            .pausaOFundo(enquanto: naoCarregado)
        } else {
            Color.clear
        }
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
    /// onde o `focoNaOrigem` diz, quando o voltar termina, e ouve depois o que aconteceu.
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
    /// totais mudam na mesma transação; a folha fica aberta, mesmo vazia (site). O VoiceOver vai depois para a vizinha (ou
    /// para o cartão do vazio) e ouve o que aconteceu, nos tempos da lista da obra; vindo da edição, contados do fim do
    /// voltar. `antes` é a ordem das linhas antes de apagar.
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
            .map { aPagarDaObra($0, hoje: dataLocalISO(.now, fuso: .current)).meses.flatMap(\.gastos).map(\.id) } ?? []
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

/// O total e "{N} vencimentos · a partir de amanhã" (o texto do site, também no zero), num grupo sólido: o valor em 28
/// bold, como o resumo do detalhe do tópico (mockup).
private struct ResumoDoAPagar: View {
    let total: Double
    let qtd: Int
    @Environment(\.paleta) private var paleta

    var body: some View {
        GrupoDaFolha {
            VStack(alignment: .leading, spacing: 2) {
                ValorEmDinheiro(texto: moeda(total), fonte: .title.weight(.bold))
                Text(textoVencimentos(qtd))
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("resumoDoAPagar")
        }
    }
}

/// "Nenhum gasto previsto para esse período." (o texto do site), com o calendário no quadrado de raio 14; o ícone sai na
/// letra grande, como no cartão de estado da lista.
private struct VazioDoAPagar: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        GrupoDaFolha {
            VStack(spacing: 10) {
                if !tamanho.isAccessibilitySize {
                    Image(decorative: "Icones/calendario")
                        .resizable().frame(width: 26, height: 26)
                        .foregroundStyle(paleta.cor(.linkNoVidro))
                        .frame(width: 48, height: 48)
                        .background(paleta.cor(.tecla), in: .rect(cornerRadius: 14, style: .continuous))
                }
                Text("Nenhum gasto previsto para esse período.")
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("aPagarVazio")
        }
    }
}

/// Uma peça da lista de uma folha de origem, filha direta da LazyVStack: o cabeçalho de um mês ou um gasto, com o lugar
/// dele no grupo do mês.
struct PecaDaOrigem: Identifiable, Equatable {
    enum Tipo: Equatable {
        case mes(MesDeGastos)
        case gasto(Gasto)
    }

    let tipo: Tipo
    /// O primeiro gasto do grupo: sem a linha fina em cima.
    let primeiro: Bool
    /// O último gasto do grupo: com os cantos de baixo do grupo.
    let ultimo: Bool

    var id: String {
        switch tipo {
        case .mes(let mes): "mes-\(mes.id)"
        case .gasto(let gasto): gasto.id
        }
    }
}

/// As peças da lista, na ordem: cada mês, o cabeçalho e os gastos dele.
func pecasDaOrigem(_ meses: [MesDeGastos]) -> [PecaDaOrigem] {
    meses.flatMap { mes in
        [PecaDaOrigem(tipo: .mes(mes), primeiro: false, ultimo: false)]
            + mes.gastos.enumerated().map { i, g in
                PecaDaOrigem(tipo: .gasto(g), primeiro: i == 0, ultimo: i == mes.gastos.count - 1)
            }
    }
}

/// O fundo sólido do grupo, desenhado por peça (as peças são filhas diretas da LazyVStack): os cantos de cima no
/// cabeçalho, os de baixo no último gasto, e o recorte nos mesmos cantos.
struct FundoDoGrupo: ViewModifier {
    let cima: Bool
    let baixo: Bool
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let forma = UnevenRoundedRectangle(topLeadingRadius: cima ? 24 : 0, bottomLeadingRadius: baixo ? 24 : 0,
                                           bottomTrailingRadius: baixo ? 24 : 0, topTrailingRadius: cima ? 24 : 0, style: .continuous)
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(paleta.cor(.linhaDaFolha), in: forma)
            .clipShape(forma)
            .padding(.horizontal, 16)
    }
}
