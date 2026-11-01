import SwiftUI

/* O título e a cápsula de metadados da identidade nova (etapa 4; ajustes 1 e 2 do mockup aprovado, parte1.css:143-149 e
   :365-366): o título solto em SF Mono 600 e o pequeno da barra, e a cápsula de vidro com o que fica embaixo do título (a
   fase e "começou em … · N meses" na obra, o nome da obra nas telas da análise). Nenhuma tela os usa ainda. */

/// O título solto: SF Mono 600, 30 pt com o tracking de −0,045 em (44 na letra máxima, crescendo a cada passo), em quantas
/// linhas precisar (o nome comprido quebra), a 16 pt da borda. Atrás dele, no escuro, o halo do nome da obra de hoje (30%,
/// e 10% no claro): o do mockup (38%, 62% na letra máxima) se calibra pelo laudo, na obra (PR 1c).
struct TituloMono: View {
    let texto: String
    var identificador = "tituloDaObra"
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let tamanho = crescendoComALetra(de: 30, ate: 44, corpo: corpoDoTexto(letra))
        Text(texto)
            .font(.system(size: tamanho, weight: .semibold, design: .monospaced))
            .tracking(-0.045 * tamanho)
            .foregroundStyle(paleta.cor(.texto))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(identificador)    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra, noClaro: HaloDoTitulo.naObraNoClaro) }
    }
}

/// O título pequeno da barra no mono: 16 pt (20 na letra máxima, crescendo a cada passo), numa linha só, até 236 pt, como
/// o `TituloPequenoDaBarra` da obra de hoje, com o Visualizador de Conteúdo Grande.
struct TituloPequenoMono: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    /// A letra da tela, lida fora da barra: dentro do ToolbarItem, o dynamicTypeSize para antes da letra de acessibilidade.
    let letra: DynamicTypeSize

    var body: some View {
        let tamanho = crescendoComALetra(de: 16, ate: 20, corpo: corpoDoTexto(letra))
        Text(texto)
            .font(.system(size: tamanho, weight: .semibold, design: .monospaced))
            .tracking(-0.02 * tamanho)
            .foregroundStyle(paleta.cor(.texto))
            .lineLimit(1)
            .frame(maxWidth: 236)
            .accessibilityAddTraits(.isHeader)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("tituloPequenoDaBarra")
    }
}

/// A cápsula de metadados embaixo do título: o vidro do conteúdo, que abraça o que leva (até a largura toda), a 16 pt da
/// borda e com o texto a 34; uma coluna com 6 pt entre as linhas, em subheadline no secundário do vidro. Cantos de 22 pt e
/// recuo de 10 × 18 × 12, que passam a 30 e 16 × 18 × 18 na letra de acessibilidade (8 pt entre as linhas): o raio de uma
/// linha, e não a cápsula da altura toda, para a quina não comer o texto quando ele quebra.
struct CapsulaDeMetadados<Conteudo: View>: View {
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let grande = letra.isAccessibilitySize
        VStack(alignment: .leading, spacing: grande ? 8 : 6) { conteudo }
            .font(.subheadline)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .padding(EdgeInsets(top: grande ? 16 : 10, leading: Grade.recuo, bottom: grande ? 18 : 12, trailing: Grade.recuo))
            .superficie(.conteudo, em: .rect(cornerRadius: grande ? 30 : 22))
    }
}
