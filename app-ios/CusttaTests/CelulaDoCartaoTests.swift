import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* Os cartões dos meses numa List como a da obra, em escala 3, nas colunas do iPhone 18 Pro (370 pt) e do Pro Max (408). A
   célula sobe a altura que o cartão mede ao pixel seguinte, e a soma das alturas das linhas, em Double, às vezes passa do pixel
   por um resto de 1e-13. Com os dados de 08/11/26, o cartão de novembro do 18 Pro, de 920 px, ficava numa célula de 921, centrado
   nela e em meio pixel: o 1º fio dele sumia, o 2º saía com 2 px, e as células abaixo desciam 1 px. No Pro Max, o mesmo em
   novembro e em outubro. A data é fixa porque a vitrine conta a partir de hoje, e em outro dia as alturas são outras. */
@MainActor
struct CelulaDoCartaoTests {
    private final class Medidas {
        var cartoes: [String: CGRect] = [:]
    }

    private struct ListaDeMeses: View {
        let meses: [MesDeGastos]
        let topicos: [String: Topico]
        let medidas: Medidas
        @State private var aberta: String?
        @AccessibilityFocusState private var foco: AlvoDoFoco?

        var body: some View {
            let acoes = AcoesDaLista(aberta: $aberta, acesos: [], novos: false, foco: $foco, tocar: { _ in }, apagar: { _ in })
            List {
                ForEach(meses) { mes in
                    CartaoDoMes(mes: mes, topicos: topicos, lista: acoes)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { medidas.cartoes[mes.id] = $0 }
                }
                .linhaDaListaDaObra()
            }
            .listStyle(.plain)
            .listRowSpacing(Grade.entreBlocos)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .environment(\.linhaMono, true)
            .contentMargins(.horizontal, Grade.externa, for: .scrollContent)
        }
    }

    private func colecao(em vista: UIView) -> UICollectionView? {
        if let achada = vista as? UICollectionView { return achada }
        for filha in vista.subviews {
            if let achada = colecao(em: filha) { return achada }
        }
        return nil
    }

    private func quadrosDasCelulas(em janela: UIWindow) -> [CGRect] {
        (colecao(em: janela)?.visibleCells ?? []).map { $0.convert($0.bounds, to: nil) }.sorted { $0.minY < $1.minY }
    }

    @Test(arguments: [CGFloat(370), 408])
    func celulaTemAAlturaDoCartaoEOCartaoFicaEmPixelInteiro(coluna: CGFloat) async throws {
        let hoje = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 12)))
        let estado = Estado.de(DadosDeExemplo.vitrine(hoje: hoje))
        let meses = Array(listaDaObra(estado.obras[0], hoje: dataLocalISO(hoje, fuso: .current)).meses.prefix(5))
        #expect(meses.count == 5)

        let medidas = Medidas()
        let cena = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let janela = UIWindow(windowScene: cena)
        janela.frame = CGRect(x: 0, y: 0, width: coluna + 2 * Grade.externa, height: 4000)
        janela.rootViewController = UIHostingController(rootView: ListaDeMeses(
            meses: meses, topicos: mapaDeTopicos(estado.config.topicosProprios), medidas: medidas))
        janela.isHidden = false
        defer { janela.isHidden = true }

        for _ in 0..<80 {
            try await Task.sleep(for: .milliseconds(50))
            if medidas.cartoes.count == meses.count && quadrosDasCelulas(em: janela).count == meses.count { break }
        }
        // A lista assenta depois de medir as linhas.
        try await Task.sleep(for: .milliseconds(300))
        let celulas = quadrosDasCelulas(em: janela)
        let cartoes = medidas.cartoes.values.sorted { $0.minY < $1.minY }
        try #require(cartoes.count == meses.count && celulas.count == meses.count)

        let escala = janela.screen.scale
        for (cartao, celula) in zip(cartoes, celulas) {
            let onde = "coluna \(coluna), cartão de \(cartao.height * escala) px"
            #expect(abs(celula.height - cartao.height) * escala < 0.5, "\(onde): célula de \(celula.height * escala) px")
            let topo = cartao.minY * escala
            #expect(abs(topo.rounded() - topo) < 0.01, "\(onde): topo em \(topo) px")
        }
    }
}
