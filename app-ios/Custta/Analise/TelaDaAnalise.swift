import SwiftUI
import CusttaNucleo

/* A costura das telas da análise (etapa 4) com o resto do app: elas moram nesta pasta e chegam ao app só por aqui (spec da
   etapa 4, "Telas"). Gráficos e Relatório são empurrados no caminho de Obras, sobre a obra, como a tela Orçamento
   (`RotaDeObras.analise`), e o + da cápsula lança gasto nessa obra (confirmação 6). Ainda não há porta: até o PR que completa
   cada destino (a barra empilhada da obra no 2b, a fileira de portas no 3b), só a abertura de Debug chega a elas
   (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`, no PrincipalView), e cada uma é uma tela provisória, que a de verdade
   troca no `DestinoDaAnalise` (os Gráficos no 2a, o Relatório no 3a). O "Vale a pena?" não passa por aqui: é uma aba, que
   chega no 4a com a cápsula de três abas. */

/// Uma tela da análise de uma obra, empurrada no caminho de Obras.
enum TelaDaAnalise: Hashable, Sendable {
    case graficos(String)
    case relatorio(String)

    /// A obra da tela: o + da cápsula lança gasto nela, como na tela Orçamento.
    var obraId: String {
        switch self {
        case .graficos(let id), .relatorio(let id): return id
        }
    }

    /// O título da barra.
    var titulo: String {
        switch self {
        case .graficos: return "Gráficos"
        case .relatorio: return "Relatório"
        }
    }
}

/// Para onde cada tela da análise leva no caminho de Obras: a única peça que as telas de verdade trocam fora delas.
struct DestinoDaAnalise: View {
    let tela: TelaDaAnalise
    @Binding var caminho: [RotaDeObras]

    var body: some View {
        TelaProvisoriaDaAnalise(tela: tela)
    }
}

/// A tela provisória, só pela abertura de Debug: o título na barra e o nome da obra.
struct TelaProvisoriaDaAnalise: View {
    let tela: TelaDaAnalise
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        let obra = modelo.sincronizador.estado.obras.first { $0.id == tela.obraId }
        ScrollView {
            Text(obra?.nome ?? "")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("obraDaAnalise")
        }
        .containerBackground(.clear, for: .navigation)
        .navigationTitle(tela.titulo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
extension TelaDaAnalise {
    /// A tela do gancho de abertura dos testes de tela, do laudo e da conferência visual: `graficos:<id>` ou `relatorio:<id>`;
    /// nil para as outras aberturas (`obra:`, `orcamento:`, `afazeres:`) e sem o id.
    init?(gancho: String) {
        let partes = gancho.split(separator: ":", maxSplits: 1).map(String.init)
        guard partes.count == 2, !partes[1].isEmpty else { return nil }
        switch partes[0] {
        case "graficos": self = .graficos(partes[1])
        case "relatorio": self = .relatorio(partes[1])
        default: return nil
        }
    }
}
#endif
