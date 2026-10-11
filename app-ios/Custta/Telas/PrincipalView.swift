import SwiftUI
import CusttaNucleo

/* O app por dentro: as abas da etapa 1 (Obras e Ajustes; "Vale a pena?" chega na etapa 4 e o + na 2)
   com a cápsula de abas própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro,
   como no site. Sair pede confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida
   fica montada: o TabView do sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a
   aurora), e uma aba só escondida continuaria na árvore do VoiceOver pela barra de navegação. O que
   precisar sobreviver à troca de aba (o caminho dentro de Obras, na etapa 2) mora aqui, no PrincipalView. */
struct PrincipalView: View {
    @State private var aba = Aba.obras

    var body: some View {
        Group {
            switch aba {
            case .obras: ObrasView()
            case .ajustes: AjustesView()
            }
        }
        // Barra própria: o que rola por baixo dela passa pela borda suave de cada tela (BordaDeRolagem).
        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba) }
        // A cápsula se mede da borda da tela, como a barra de abas do sistema, e não acompanha o teclado: ao
        // entrar com ele aberto, o teclado da entrada ainda está fechando quando esta tela aparece, e a barra
        // nascia em cima dele, no meio da tela, e saltava. As telas das abas não têm campo de texto.
        .ignoresSafeArea(edges: .bottom)
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
                    Text(i.rotulo).font(.footnote.weight(.semibold)).lineLimit(1)
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

    func body(content: Content) -> some View {
        content
            .alert("Sair da conta?", isPresented: $confirmar) {
                Button("Cancelar", role: .cancel) {}
                Button("Sair", role: .destructive) {
                    Task { erro = await modelo.sair() }
                }
            }
            .alert(erro ?? "", isPresented: Binding(get: { erro != nil }, set: { if !$0 { erro = nil } })) {
                Button("OK", role: .cancel) {}
            }
            .pausaOFundo(enquanto: confirmar || erro != nil)
    }
}
