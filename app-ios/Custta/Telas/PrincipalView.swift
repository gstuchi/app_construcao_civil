import SwiftUI
import CusttaNucleo

/* O app por dentro: as abas (Obras e Ajustes; "Vale a pena?" chega na etapa 4) com a cápsula de abas
   própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro, como no site. Sair pede
   confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida fica montada: o TabView do
   sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a aurora), e uma aba só escondida
   continuaria na árvore do VoiceOver pela barra de navegação. Por isso o caminho dentro de Obras mora aqui:
   quem vai a Ajustes e volta encontra a obra que tinha aberto. */
struct PrincipalView: View {
    @State private var aba = Aba.obras
    @State private var caminhoDeObras = PrincipalView.caminhoInicial
    @State private var folhas = Folhas()
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        Group {
            switch aba {
            case .obras: ObrasView(caminho: $caminhoDeObras)
            case .ajustes: AjustesView()
            }
        }
        .environment(folhas)
        // Barra própria: o que rola por baixo dela passa pela borda suave de cada tela (BordaDeRolagem).
        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba, mais: acaoDoMais) }
        .sheet(item: $folhas.aberta, onDismiss: folhas.fechou) { qual in
            Group {
                switch qual {
                case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil)
                case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId)
                case .venda(let obraId): FolhaDaVenda(obraId: obraId)
                }
            }
            .environment(folhas)
        }
        // Com a folha aberta o fundo para: ela cobre quase tudo, e cada quadro da aurora refaria o desfoque dela.
        .pausaOFundo(enquanto: folhas.aberta != nil)
        .modifier(AvisosDoPrincipal(folhaAberta: folhas.aberta != nil))
        #if DEBUG
        .task { await abrirFolhaDoGancho() }
        // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
        .overlay(alignment: .topLeading) {
            if UserDefaults.standard.bool(forKey: "custta.contarPontes") {
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    Text("pontes \(ControladorDaPonte.vivas)").font(.caption2).accessibilityIdentifier("pontesVivas")
                }
            }
        }
        #endif
        // A cápsula se mede da borda da tela, como a barra de abas do sistema, e não acompanha o teclado: ao
        // entrar com ele aberto, o teclado da entrada ainda está fechando quando esta tela aparece, e a barra
        // nascia em cima dele, no meio da tela, e saltava. As telas das abas não têm campo de texto.
        .ignoresSafeArea(edges: .bottom)
    }
}

extension PrincipalView {
    /// O + da cápsula: dentro de uma obra que ainda recebe gasto, lança gasto nela. Obra vendida não recebe gasto novo
    /// (como no site); a escolha de outra obra chega no PR 3, junto com "Nova obra" na lista.
    private var acaoDoMais: AcaoDoMais? {
        guard aba == .obras, case .obra(let id)? = caminhoDeObras.last,
              let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == id }), obra.fase != .vendida else { return nil }
        return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) }
    }

    #if DEBUG
    /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`venda:<id>`,
    /// `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
    /// `-custta.folha <passo>` abre a folha do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e
    /// `-custta.folha editar:<gasto>`, a edição.
    private func abrirFolhaDoGancho() async {
        let pedido = ProcessInfo.processInfo.environment["CUSTTA_FOLHA"]
        let passo = UserDefaults.standard.string(forKey: "custta.folha")
        guard pedido != nil || passo != nil else { return }
        for _ in 0..<50 where !modelo.sincronizador.dadosCarregados { try? await Task.sleep(for: .milliseconds(100)) }
        try? await Task.sleep(for: .milliseconds(300))
        if let pedido {
            let partes = pedido.split(separator: ":", maxSplits: 1).map(String.init)
            let id = partes.count > 1 ? partes[1] : ""
            switch partes[0] {
            case "venda": folhas.aberta = .venda(obraId: id)
            case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
            default: break
            }
        } else if let passo, case .obra(let obraId)? = caminhoDeObras.last {
            folhas.aberta = passo.hasPrefix("editar:") ? .editarGasto(obraId: obraId, gastoId: String(passo.dropFirst(7)))
                                                       : .novoGasto(obraId: obraId)
        }
    }
    #endif

    /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto (testes de tela, laudo
    /// de leitura e conferência visual).
    static var caminhoInicial: [RotaDeObras] {
        #if DEBUG
        if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("obra:") {
            return [.obra(String(abrir.dropFirst(5)))]
        }
        #endif
        return []
    }
}

/// O alerta do "Não salvou" (uma vez por erro, com "Tentar de novo") por cima das abas, num fundo vazio, com os botões na
/// cor do texto, como o "Sair da conta?". Espera a folha aberta descer.
private struct AvisosDoPrincipal: ViewModifier {
    let folhaAberta: Bool
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let gravacao = modelo.alertaDeGravacao
        content
            .background {
                Color.clear
                    .alert(gravacao?.titulo ?? "", isPresented: Binding(get: { gravacao != nil && !folhaAberta },
                                                                         set: { if !$0 { modelo.fecharAlertaDeGravacao() } })) {
                        Button("OK", role: .cancel) {}
                        Button("Tentar de novo") { modelo.tentarDeNovo() }
                    } message: {
                        Text(gravacao?.mensagem ?? "")
                    }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: gravacao != nil && !folhaAberta)
    }
}

/// Sincronização e sair, no canto da barra de Obras e de Ajustes.
struct BarraDoApp: ToolbarContent {
    @Binding var confirmarSaida: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
            .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .topBarTrailing) { BotaoSairDoTopo(confirmar: $confirmarSaida) }
            .sharedBackgroundVisibility(.hidden)
    }
}

/// O indicador de sincronização do site: some em dia; tocar no erro tenta de novo. Nos erros, o rótulo
/// fica na cor do texto e só o ponto em vermelho (no site o vermelho não fechava o contraste).
struct IndicadorDeSincronizacao: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let i = indicador(modelo.sincronizador.estadoSinc) {
            Button {
                if i.erro { modelo.tentarDeNovo() }
            } label: {
                HStack(spacing: 7) {
                    if i.girando { ProgressView().controlSize(.mini) }
                    else { Circle().fill(paleta.cor(i.erro ? .erroNoVidro : .texto)).frame(width: 8, height: 8).opacity(i.erro ? 1 : 0.75) }
                    // Na barra da obra, ao lado do lápis, a barra oferecia uns 2 pt a menos do que o rótulo pede e cortava
                    // "Sem conex…": o rótulo fica na largura dele.
                    Text(i.rotulo).font(.footnote.weight(.semibold)).lineLimit(1).fixedSize()
                }
                .foregroundStyle(paleta.cor(.texto))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .superficie(.navegacao, em: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(i.rotulo)
            .accessibilityHint(i.dica)
            .accessibilityIdentifier("indicadorSincronizacao")
        }
    }
}

/// O sair do topo, mantido como no site: círculo de vidro com o ícone de saída, na cor do texto nos dois
/// temas (decisão do Giovani em 09/10: na cor da marca, no claro, caía para 2,5:1 quando o "Já confirmei"
/// passava por baixo).
struct BotaoSairDoTopo: View {
    @Binding var confirmar: Bool
    @Environment(\.paleta) private var paleta

    var body: some View {
        Button { confirmar = true } label: {
            Image(decorative: "Icones/sair")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundStyle(paleta.cor(.texto))
                .frame(width: 44, height: 44)
                .superficie(.navegacao, em: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sair da conta")
        .accessibilityIdentifier("sairTopo")
    }
}

extension View {
    /// "Sair da conta?" pelo alerta do sistema; sem rede (ou se não der), explica num segundo alerta.
    func confirmaSaida(_ confirmar: Binding<Bool>) -> some View { modifier(ConfirmacaoDeSaida(confirmar: confirmar)) }
}

private struct ConfirmacaoDeSaida: ViewModifier {
    @Binding var confirmar: Bool
    @Environment(ModeloApp.self) private var modelo
    @State private var erro: String?
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        content
            // Os alertas ficam num fundo vazio para o tint valer só neles: os botões na cor do texto, como no mockup
            // v3 (na cápsula do alerta, a Marca fica em 2,5:1 e o LinkNoVidro, em 4,46:1 no escuro azul). O "Sair"
            // destrutivo fica no vermelho do sistema, que não segue o tint: o padrão da Apple (decisão de 11/10).
            .background {
                Color.clear
                    .alert("Sair da conta?", isPresented: $confirmar) {
                        Button("Cancelar", role: .cancel) {}
                        Button("Sair", role: .destructive) {
                            Task { erro = await modelo.sair() }
                        }
                    }
                    .alert(erro ?? "", isPresented: Binding(get: { erro != nil }, set: { if !$0 { erro = nil } })) {
                        Button("OK", role: .cancel) {}
                    }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: confirmar || erro != nil)
    }
}
