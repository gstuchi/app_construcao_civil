import Foundation
import UIKit

/* SONDA DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main). O gerador do relatório da obra em PDF escrito como
   seria o de produção, no alvo do app, para o Swift 6.3.3 da CI compilar com as configurações do alvo (Swift 6,
   concorrência estrita, sem isolamento padrão). Desenho: spec da etapa 4, "PDF: tabelas em UIKit, página 1 à parte".
   Aqui: o relatório já montado, a medida do texto e a paginação. Na produção a paginação mora no núcleo e recebe as
   alturas medidas por este mesmo motor. */

struct LinhaDoPDF: Sendable {
    let id: String
    let texto: String
    let data: String
    let bruto: Double
    let corrigido: Double
}

struct TopicoDoPDF: Sendable {
    let nome: String
    let cor: Int
    let linhas: [LinhaDoPDF]
    let bruto: Double
    let corrigido: Double
}

struct PedacoDoPDF: Sendable {
    let nome: String
    let valor: Double
    let cor: Int
    let pct: Double
}

struct PontoDoPDF: Sendable {
    let bruto: Double
    let corrigido: Double
}

struct MesDoPDF: Sendable {
    let rotulo: String
    let total: Double
    let futuro: Bool
}

struct RelatorioDoPDF: Sendable {
    let nome: String
    let meta: String
    let dataTexto: String
    let lancamentos: Int
    let totalBruto: Double
    let totalCorrigido: Double
    let venda: Double?
    let topicos: [TopicoDoPDF]
    let pedacos: [PedacoDoPDF]
    let acumulado: [PontoDoPDF]
    let meses: [MesDoPDF]

    var margem: Double? { venda.map { $0 - totalCorrigido } }

    /// O texto alternativo da figura da página 1: o que os gráficos mostram, em frases.
    var textoDaFigura: String {
        var s = "Resumo da obra. Total gasto: R$ \(FormatoDoPDF.numero(totalBruto)) em \(lancamentos) lançamentos. "
        s += "Corrigido: R$ \(FormatoDoPDF.numero(totalCorrigido)). "
        if let venda { s += "Venda estimada: R$ \(FormatoDoPDF.numero(venda)). " }
        s += "Gastos por tópico: " + pedacos.map { "\($0.nome), \($0.pct < 1 ? "menos de 1" : String(Int($0.pct.rounded())))%" }
            .joined(separator: "; ") + ". "
        if let primeiro = meses.first, let ultimo = meses.last {
            s += "Gasto por mês, de \(primeiro.rotulo) a \(ultimo.rotulo), com o acumulado de cada mês."
        }
        return s
    }
}

enum FormatoDoPDF {
    /// 319847.85 → "319.847,85" (pt-BR, à mão: rápido e sem NumberFormatter fora da thread principal).
    static func numero(_ v: Double, sinal: Bool = false) -> String {
        let centavos = Int64((abs(v) * 100).rounded())
        let digitos = Array(String(centavos / 100))
        var s = ""
        for (i, ch) in digitos.enumerated() {
            if i > 0 && (digitos.count - i) % 3 == 0 { s.append(".") }
            s.append(ch)
        }
        let frac = centavos % 100
        let prefixo = v < 0 && centavos > 0 ? "-" : (sinal ? "+" : "")
        return prefixo + s + "," + (frac < 10 ? "0" : "") + String(frac)
    }
}

/// Medida do texto da descrição: a mesma string, a mesma fonte e a mesma largura no desenho e na paginação.
enum MedidaDoPDF {
    static let pagina = CGRect(x: 0, y: 0, width: 595, height: 842)
    static let larguraDaDescricao: CGFloat = 184.5
    static let fonteDaDescricao = UIFont.systemFont(ofSize: 9.5)
    static let corDoTexto = UIColor(red: 0x13 / 255, green: 0x26 / 255, blue: 0x1E / 255, alpha: 1)
    /// Recuo do texto dentro da linha (a linha de uma linha só tem 15 pt; a letra de 9,5 pt ocupa ~11,3).
    static let recuoDeCima: CGFloat = 1.8

    static func descricao(_ s: String) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [.font: fonteDaDescricao, .foregroundColor: corDoTexto])
    }
    static func alturaDoTexto(_ s: String) -> CGFloat {
        descricao(s).boundingRect(with: CGSize(width: larguraDaDescricao, height: .greatestFiniteMagnitude),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
    }
    static func alturaDaLinha(texto h: CGFloat) -> CGFloat { max(15, ceil(h) + 3) }
}

enum ItemDaPaginaDoPDF: Sendable {
    case topico(Int, continuacao: Bool)
    case gasto(Int, Int, altura: CGFloat, alturaDoTexto: CGFloat)
    case total
    case venda(Int)
}

struct PaginaDoPDF: Sendable {
    var itens: [ItemDaPaginaDoPDF] = []
    var usado: CGFloat = 0
}

/// Onde a página quebra (conta pura sobre as alturas medidas). Repete o tópico com "(continuação)" e mantém o fim
/// (total e venda) inteiro numa página.
struct PaginacaoDoPDF: Sendable {
    let paginas: [PaginaDoPDF]
    /// Páginas do arquivo: a 1 (resumo) e as da tabela.
    var total: Int { paginas.count + 1 }

    static let uso: CGFloat = 842 - 34 - 50, cabecalho: CGFloat = 47, subtitulo: CGFloat = 30, cabecalhoDaTabela: CGFloat = 18
    static let topico: CGFloat = 20, totalGeral: CGFloat = 22, venda: CGFloat = 18

    static func capacidade(_ i: Int) -> CGFloat { uso - cabecalho - (i == 0 ? subtitulo : 0) - cabecalhoDaTabela }
    /// Topo da primeira linha da tabela na página i da tabela (coordenadas da página, de cima).
    static func topoDaTabela(_ i: Int) -> CGFloat { 34 + cabecalho + (i == 0 ? subtitulo : 0) + cabecalhoDaTabela }

    static func paginar(_ r: RelatorioDoPDF) -> PaginacaoDoPDF {
        var pags = [PaginaDoPDF()]
        func nova() { pags.append(PaginaDoPDF()) }
        func cabe(_ h: CGFloat) -> Bool { pags[pags.count - 1].usado + h <= capacidade(pags.count - 1) }
        func por(_ item: ItemDaPaginaDoPDF, _ h: CGFloat) { pags[pags.count - 1].itens.append(item); pags[pags.count - 1].usado += h }
        for (ti, t) in r.topicos.enumerated() {
            let alturas = t.linhas.map { l -> (CGFloat, CGFloat) in
                let h = MedidaDoPDF.alturaDoTexto(l.texto)
                return (MedidaDoPDF.alturaDaLinha(texto: h), h)
            }
            if !cabe(topico + (alturas.first?.0 ?? 0)) { nova() }
            por(.topico(ti, continuacao: false), topico)
            for (k, (h, texto)) in alturas.enumerated() {
                if !cabe(h) { nova(); por(.topico(ti, continuacao: true), topico) }
                por(.gasto(ti, k, altura: h, alturaDoTexto: texto), h)
            }
        }
        let vendas = r.venda == nil ? 0 : 2
        if !cabe(totalGeral + CGFloat(vendas) * venda) { nova() }
        por(.total, totalGeral)
        for k in 0..<vendas { por(.venda(k), venda) }
        return PaginacaoDoPDF(paginas: pags)
    }
}
