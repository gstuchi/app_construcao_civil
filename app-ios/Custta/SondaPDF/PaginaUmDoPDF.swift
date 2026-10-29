import Foundation
import SwiftUI

/* SONDA DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main). A figura da página 1 (números e gráficos), composta à
   parte em SwiftUI com o ambiente explícito (claro, letra padrão, pt-BR, a paleta do PDF) e fontes fixas. O
   ImageRenderer a desenha na thread principal num PDF de uma página, que o gerador põe na página 1 por drawPDFPage,
   dentro da tag Figure. O título (H1) e os parágrafos (P) da página 1 o gerador escreve em UIKit, fora da figura. Na
   produção, os gráficos usam as marcas do item 1 do spec (geometria e Shape); aqui, um desenho que basta para medir. */

enum LayoutDaPaginaUm {
    static let inicioDaFigura: CGFloat = 166
    static let fimDaFigura: CGFloat = 166 + 66 + 10 + 186 + 10 + 150
}

extension GeradorDoPDF {
    /// A figura da página 1 num PDF de uma página. Só ela precisa da thread principal (ImageRenderer).
    @MainActor
    static func paginaUm(_ r: RelatorioDoPDF, total: Int) -> Data {
        let dados = NSMutableData()
        var caixa = MedidaDoPDF.pagina
        guard let consumidor = CGDataConsumer(data: dados as CFMutableData),
              let cg = CGContext(consumer: consumidor, mediaBox: &caixa, nil) else { return Data() }
        let renderer = ImageRenderer(content: PaginaUmDoPDF(r: r))
        renderer.proposedSize = ProposedViewSize(width: caixa.width, height: caixa.height)
        renderer.render { _, desenhar in
            cg.beginPDFPage(nil)
            desenhar(cg)
            cg.endPDFPage()
        }
        cg.closePDF()
        return dados as Data
    }
}

private enum CoresDaFigura {
    static func cor(_ hex: UInt32, _ a: Double = 1) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: a)
    }
    static let forte = cor(0x177A4A), texto = cor(0x13261E), secundario = cor(0x3B574B), caixa = cor(0xF2F7F4)
    static let paleta: [Color] = [0x10976A, 0x2A78D6, 0xD14F86, 0x6250D6, 0xDC5A1E, 0x0C86A4, 0x5E7A6E].map { cor($0) }
}

struct PaginaUmDoPDF: View {
    let r: RelatorioDoPDF

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                kpi("Total gasto", r.totalBruto, "\(r.lancamentos) lançamentos", forte: true)
                kpi("Corrigido", r.totalCorrigido, "correção de +R$ \(FormatoDoPDF.numero(r.totalCorrigido - r.totalBruto))")
                if let v = r.venda { kpi("Venda estimada", v, "margem de R$ \(FormatoDoPDF.numero(r.margem ?? 0))") }
            }
            .frame(height: 66, alignment: .top)
            HStack(alignment: .top, spacing: 10) {
                caixa("Gastos por tópico") {
                    HStack(spacing: 8) {
                        AnelDaFigura(pedacos: r.pedacos).frame(width: 112, height: 112)
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(r.pedacos.indices, id: \.self) { i in
                                let p = r.pedacos[i]
                                HStack(spacing: 5) {
                                    Circle().fill(CoresDaFigura.paleta[p.cor % CoresDaFigura.paleta.count]).frame(width: 7, height: 7)
                                    Text(p.nome).font(.system(size: 9.5)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                                    Text(p.pct < 1 ? "<1%" : "\(Int(p.pct.rounded()))%")
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                }
                            }
                        }
                        .foregroundStyle(CoresDaFigura.texto)
                    }
                }
                caixa("Gasto acumulado") {
                    HStack(spacing: 10) {
                        HStack(spacing: 4) { CoresDaFigura.forte.frame(width: 12, height: 2); Text("gasto") }
                        HStack(spacing: 4) { CoresDaFigura.secundario.frame(width: 12, height: 1); Text("corrigido pelo banco") }
                    }
                    .font(.system(size: 9.5)).foregroundStyle(CoresDaFigura.secundario).padding(.bottom, 4)
                    CurvaDaFigura(pontos: r.acumulado).frame(width: 218, height: 118)
                }
            }
            .frame(height: 186, alignment: .top)
            caixa("Gasto por mês") {
                BarrasDaFigura(meses: r.meses).frame(width: 479, height: 92)
                HStack {
                    Text(r.meses.first?.rotulo ?? "")
                    Spacer()
                    Text(r.meses.last?.rotulo ?? "")
                }
                .font(.system(size: 8.5, design: .monospaced)).foregroundStyle(CoresDaFigura.secundario).padding(.top, 3)
            }
            .frame(height: 150, alignment: .top)
        }
        .frame(width: 507, alignment: .topLeading)
        .padding(.leading, 44)
        .padding(.top, LayoutDaPaginaUm.inicioDaFigura)
        .frame(width: MedidaDoPDF.pagina.width, height: MedidaDoPDF.pagina.height, alignment: .topLeading)
        .environment(\.colorScheme, .light)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .environment(\.legibilityWeight, .regular)
        .dynamicTypeSize(.large)
    }

    private func kpi(_ rotulo: String, _ v: Double, _ sub: String, forte: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rotulo).font(.system(size: 10, weight: .semibold))
            Text("R$ \(FormatoDoPDF.numero(v))").font(.system(size: 15, weight: .semibold, design: .monospaced)).tracking(-0.5)
                .foregroundStyle(forte ? Color.white : CoresDaFigura.texto)
            Text(sub).font(.system(size: 9.5))
        }
        .foregroundStyle(forte ? Color.white.opacity(0.92) : CoresDaFigura.secundario)
        .padding(.vertical, 10).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(forte ? CoresDaFigura.forte : CoresDaFigura.caixa))
    }

    private func caixa<C: View>(_ titulo: String, @ViewBuilder _ conteudo: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo).font(.system(size: 11, weight: .bold)).foregroundStyle(CoresDaFigura.texto).padding(.bottom, 8)
            conteudo()
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 14).fill(CoresDaFigura.caixa))
    }
}

private struct AnelDaFigura: View {
    let pedacos: [PedacoDoPDF]
    var body: some View {
        let total = max(pedacos.reduce(0) { $0 + $1.valor }, 0.01)
        var inicio = -90.0
        let arcos: [(Double, Double, Int)] = pedacos.map { p in
            let a = p.valor / total * 360
            defer { inicio += a }
            return (inicio, inicio + a, p.cor)
        }
        return ZStack {
            ForEach(arcos.indices, id: \.self) { i in
                let (a0, a1, cor) = arcos[i], folga = min(7.0, (a1 - a0) / 3)
                Path { p in
                    p.addArc(center: CGPoint(x: 56, y: 56), radius: 45, startAngle: .degrees(a0 + folga), endAngle: .degrees(a1 - folga),
                             clockwise: false)
                }
                .stroke(CoresDaFigura.paleta[cor % CoresDaFigura.paleta.count], style: StrokeStyle(lineWidth: 14, lineCap: .round))
            }
        }
    }
}

private struct CurvaDaFigura: View {
    let pontos: [PontoDoPDF]
    var body: some View {
        let maximo = max((pontos.map(\.corrigido).max() ?? 1) * 1.06, 1)
        let x = { (i: Int) in 4 + CGFloat(i) * 210 / CGFloat(max(1, pontos.count - 1)) }
        let y = { (v: Double) in 114 - CGFloat(v / maximo) * 108 }
        func caminho(_ k: KeyPath<PontoDoPDF, Double>) -> Path {
            Path { p in
                for (i, pt) in pontos.enumerated() {
                    let q = CGPoint(x: x(i), y: y(pt[keyPath: k]))
                    if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
                }
            }
        }
        return ZStack {
            caminho(\.corrigido).stroke(CoresDaFigura.secundario, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))
            caminho(\.bruto).stroke(CoresDaFigura.forte, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct BarrasDaFigura: View {
    let meses: [MesDoPDF]
    var body: some View {
        let maximo = max(1, meses.map(\.total).max() ?? 1)
        let largura = (479 - 4 * CGFloat(max(0, meses.count - 1))) / CGFloat(max(1, meses.count))
        func retangulos(futuros: Bool) -> Path {
            Path { p in
                for (i, m) in meses.enumerated() where m.futuro == futuros {
                    let h = max(2, CGFloat(m.total / maximo) * 86)
                    p.addRoundedRect(in: CGRect(x: CGFloat(i) * (largura + 4), y: 90 - h, width: largura, height: h),
                                     cornerSize: CGSize(width: 3, height: 3))
                }
            }
        }
        return ZStack {
            retangulos(futuros: false).fill(CoresDaFigura.forte)
            retangulos(futuros: true).stroke(CoresDaFigura.forte, style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
        }
    }
}
