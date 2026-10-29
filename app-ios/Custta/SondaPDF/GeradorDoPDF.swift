import Foundation
import UIKit

/* SONDA DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main). O gerador: a página 1 sai do ImageRenderer na thread
   principal (PaginaUmDoPDF.swift) e entra por drawPDFPage; da página 2 em diante, o UIGraphicsPDFRenderer desenha as
   tabelas com NSAttributedString.draw(with:) na altura prevista, num Task.detached, com uma autoreleasepool por página,
   escrevendo direto no arquivo. A marcação para leitor de tela usa a API do iOS 13 (CGPDFContextBeginTag/EndTag). */

/// Como o PDF é marcado para leitor de tela (API do iOS 13). A API grava a árvore pela pilha de tags de cada página.
struct MarcacaoDoPDF: Sendable {
    enum Tabela: Sendable {
        /// Um Table por página, cada um com a linha de cabeçalho (TH).
        case porPagina
        /// Um Table só, aberto na primeira página da tabela e fechado na última (o que o spec quer).
        case unica
    }
    enum Idioma: Sendable {
        /// pt-BR em cada elemento do topo (H1, P, Figure, Table…), abaixo do Document que a API cria sozinha.
        case emCadaElemento
        /// Um Document explícito com pt-BR, aberto na página 1 e fechado na última.
        case documentoExplicito
    }
    var tabela: Tabela = .porPagina
    var idioma: Idioma = .emCadaElemento
    static let padrao = MarcacaoDoPDF()
}

struct ResumoDoPDF: Sendable {
    var paginas = 0
    var bytes = 0
    var paginacao: Double = 0
    var paginaUm: Double = 0
    var escrita: Double = 0
    var total: Double = 0
    /// A página de tabela mais demorada (s).
    var maiorPagina: Double = 0
    /// A paginação e a escrita rodaram fora da thread principal.
    var foraDaPrincipal = false
}

enum ErroDoPDF: Error {
    case paginaUm
}

enum GeradorDoPDF {
    static let titulo = "Relatório da obra"
    static let idioma = "pt-BR"

    /// O fluxo de produção: paginação e escrita num Task.detached; só a página 1 (ImageRenderer) na principal.
    /// Cancelar a tarefa de quem chama cancela a escrita, que apaga o arquivo parcial.
    @MainActor
    static func gerar(_ r: RelatorioDoPDF, em url: URL, marcacao: MarcacaoDoPDF?) async throws -> ResumoDoPDF {
        var resumo = ResumoDoPDF()
        let inicio = CACurrentMediaTime()
        let paginar = Task.detached(priority: .userInitiated) { () -> (PaginacaoDoPDF, Double, Bool) in
            let t = CACurrentMediaTime()
            let p = PaginacaoDoPDF.paginar(r)
            return (p, CACurrentMediaTime() - t, pthread_main_np() == 0)
        }
        let (paginacao, tempoDaPaginacao, paginouFora) = await withTaskCancellationHandler {
            await paginar.value
        } onCancel: {
            paginar.cancel()
        }
        try Task.checkCancellation()
        let t1 = CACurrentMediaTime()
        let figura = paginaUm(r, total: paginacao.total)
        resumo.paginaUm = CACurrentMediaTime() - t1
        let escrita = Task.detached(priority: .userInitiated) { () throws -> (Double, Double, Bool) in
            let t = CACurrentMediaTime()
            let maior = try escrever(r, paginacao: paginacao, paginaUm: figura, em: url, marcacao: marcacao)
            return (maior, CACurrentMediaTime() - t, pthread_main_np() == 0)
        }
        let (maiorPagina, tempoDaEscrita, escreveuFora) = try await withTaskCancellationHandler {
            try await escrita.value
        } onCancel: {
            escrita.cancel()
        }
        resumo.paginacao = tempoDaPaginacao
        resumo.escrita = tempoDaEscrita
        resumo.maiorPagina = maiorPagina
        resumo.foraDaPrincipal = paginouFora && escreveuFora
        resumo.total = CACurrentMediaTime() - inicio
        resumo.paginas = paginacao.total
        resumo.bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return resumo
    }

    /// O arquivo inteiro. Não toca na thread principal: roda no Task.detached de `gerar` (ou, para comparar, nela).
    /// Devolve o tempo da página de tabela mais demorada.
    static func escrever(_ r: RelatorioDoPDF, paginacao: PaginacaoDoPDF, paginaUm: Data, em url: URL,
                         marcacao: MarcacaoDoPDF?) throws -> Double {
        let formato = UIGraphicsPDFRendererFormat()
        formato.documentInfo = [kCGPDFContextTitle as String: "\(titulo) · \(r.nome)", kCGPDFContextCreator as String: "Custta"]
        let renderer = UIGraphicsPDFRenderer(bounds: MedidaDoPDF.pagina, format: formato)
        guard let provedor = CGDataProvider(data: paginaUm as CFData), let p1 = CGPDFDocument(provedor)?.page(at: 1) else {
            throw ErroDoPDF.paginaUm
        }
        var maior = 0.0, cancelado = false
        try renderer.writePDF(to: url) { ctx in
            autoreleasepool {
                desenharPaginaUm(Pincel(ctx: ctx, marcacao: marcacao), r: r, figura: p1, total: paginacao.total)
            }
            for (i, pagina) in paginacao.paginas.enumerated() {
                if Task.isCancelled { cancelado = true; break }
                let t = CACurrentMediaTime()
                autoreleasepool {
                    desenharTabela(Pincel(ctx: ctx, marcacao: marcacao), r: r, pagina: pagina, indice: i,
                                   total: paginacao.total, ultima: i == paginacao.paginas.count - 1)
                }
                maior = max(maior, CACurrentMediaTime() - t)
            }
        }
        if cancelado {
            try? FileManager.default.removeItem(at: url)
            throw CancellationError()
        }
        return maior
    }

    // MARK: - Desenho

    private static func desenharPaginaUm(_ d: Pincel, r: RelatorioDoPDF, figura: CGPDFPage, total: Int) {
        typealias E = EstiloDoPDF
        d.ctx.beginPage()
        d.retangulo(MedidaDoPDF.pagina, .white)
        if d.marcacao?.idioma == .documentoExplicito { d.abrir(.document, idiomaExplicito: true) }
        cabecalho(d, subtitulo: "\(titulo) · \(r.dataTexto)")
        d.marcar(.header1) {
            d.esquerda(d.texto(r.nome, E.titulo, E.texto, kern: -0.96), x: 44, y: 81, h: 30, f: E.titulo)
        }
        d.marcar(.paragraph) {
            d.texto(r.meta, E.meta, E.secundario).draw(with: CGRect(x: 44, y: 114, width: 507, height: 40),
                                                       options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
                                                       context: nil)
        }
        d.marcar(.figure, alt: r.textoDaFigura) {
            let cg = d.cg
            cg.saveGState()
            cg.translateBy(x: 0, y: MedidaDoPDF.pagina.height)
            cg.scaleBy(x: 1, y: -1)
            cg.drawPDFPage(figura)
            cg.restoreGState()
        }
        d.marcar(.paragraph) {
            d.esquerda(d.texto("Os gastos, um por um, com o valor corrigido, vêm a seguir, tópico por tópico.", E.meta, E.secundario),
                       x: 44, y: LayoutDaPaginaUm.fimDaFigura + 10, h: 14, f: E.meta)
        }
        rodape(d, numero: 1, total: total)
        // Document explícito: aberto aqui e fechado só na última página (o que a API faz com isso é o que a sonda mostra).
    }

    private static func cabecalho(_ d: Pincel, subtitulo: String) {
        typealias E = EstiloDoPDF
        d.esquerda(d.texto("custta.", E.logo, E.forte, kern: -0.6), x: 44, y: 34, h: 20, f: E.logo)
        d.direita(d.texto(subtitulo, E.cabecalho, E.secundario), x: 551, y: 34, h: 20, f: E.cabecalho)
        d.retangulo(CGRect(x: 44, y: 66, width: 507, height: 1), E.grade)
    }

    private static func rodape(_ d: Pincel, numero: Int, total: Int) {
        typealias E = EstiloDoPDF
        d.retangulo(CGRect(x: 44, y: 798, width: 507, height: 1), E.grade)
        d.esquerda(d.texto("Gerado pelo Custta", E.rodape, E.secundario), x: 44, y: 807, h: E.rodape.lineHeight, f: E.rodape)
        d.direita(d.texto("página \(numero) de \(total)", E.rodape, E.secundario), x: 551, y: 807, h: E.rodape.lineHeight, f: E.rodape)
    }

    /// Uma página da tabela, em dois passos: primeiro o que é só desenho (fundo, cabeçalho, rodapé, faixas e linhas),
    /// fora de qualquer tag; depois o texto de cada célula, dentro da tag dela.
    private static func desenharTabela(_ d: Pincel, r: RelatorioDoPDF, pagina: PaginaDoPDF, indice: Int, total: Int, ultima: Bool) {
        typealias E = EstiloDoPDF
        typealias P = PaginacaoDoPDF
        d.ctx.beginPage()
        let topo: CGFloat = 34 + P.cabecalho + (indice == 0 ? P.subtitulo : 0)
        // 1º passo: desenho sem texto de dado
        d.retangulo(MedidaDoPDF.pagina, .white)
        cabecalho(d, subtitulo: "\(r.nome) · Relatório · \(r.dataTexto)")
        d.retangulo(CGRect(x: 44, y: topo + 17, width: 507, height: 1), E.texto)
        var y = topo + P.cabecalhoDaTabela
        for item in pagina.itens {
            switch item {
            case let .topico(ti, _):
                d.retangulo(CGRect(x: 44, y: y, width: 507, height: P.topico), E.caixa)
                d.cg.setFillColor(E.paleta[r.topicos[ti].cor % E.paleta.count].cgColor)
                d.cg.fillEllipse(in: CGRect(x: 50, y: y + (P.topico - 7) / 2, width: 7, height: 7))
                y += P.topico
            case let .gasto(_, _, h, _):
                d.retangulo(CGRect(x: 44, y: y + h - 1, width: 507, height: 1), E.grade)
                y += h
            case .total:
                d.retangulo(CGRect(x: 44, y: y, width: 507, height: 1.5), E.texto)
                y += P.totalGeral
            case .venda:
                y += P.venda
            }
        }
        rodape(d, numero: indice + 2, total: total)

        // 2º passo: o texto, marcado
        if indice == 0 {
            d.marcar(.header2) {
                d.esquerda(d.texto("Gastos por tópico", E.subtitulo, E.texto, kern: -0.64), x: 44, y: 34 + P.cabecalho, h: 20, f: E.subtitulo)
            }
        }
        let abreTabela = d.marcacao.map { $0.tabela == .porPagina || indice == 0 } ?? false
        let fechaTabela = d.marcacao.map { $0.tabela == .porPagina || ultima } ?? false
        if abreTabela { d.abrir(.table) }
        d.linha {
            d.celula(.tableHeaderCell) { d.esquerda(d.texto("Gasto", E.th, E.secundario), x: 50, y: topo, h: 17, f: E.th) }
            d.celula(.tableHeaderCell) {
                d.esquerda(d.texto("Data", E.th, E.secundario), x: ColunasDoPDF.direita(0) + ColunasDoPDF.folga, y: topo, h: 17, f: E.th)
            }
            for (col, s) in [(2, "Bruto (R$)"), (3, "Corrigido (R$)"), (4, "Correção (R$)")] {
                d.celula(.tableHeaderCell) {
                    d.direita(d.texto(s, E.th, E.secundario), x: ColunasDoPDF.direita(col) - ColunasDoPDF.folga, y: topo, h: 17, f: E.th)
                }
            }
        }
        y = topo + P.cabecalhoDaTabela
        for item in pagina.itens {
            switch item {
            case let .topico(ti, continuacao):
                let t = r.topicos[ti], h = P.topico
                d.linha {
                    d.celula(.tableDataCell) {
                        let nome = d.texto(t.nome, E.topico, E.texto)
                        d.esquerda(nome, x: 63, y: y, h: h, f: E.topico)
                        let qt = continuacao ? "(continuação)" : "\(t.linhas.count) \(t.linhas.count == 1 ? "gasto" : "gastos")"
                        d.esquerda(d.texto(qt, E.quantidade, E.secundario), x: 63 + nome.size().width + 4, y: y, h: h, f: E.quantidade)
                    }
                    if !continuacao {
                        d.celula(.tableDataCell) {}
                        d.celula(.tableDataCell) { d.numero(t.bruto, col: 2, y: y, h: h, f: E.numeroNegrito, cor: E.secundario) }
                        d.celula(.tableDataCell) { d.numero(t.corrigido, col: 3, y: y, h: h, f: E.numeroNegrito) }
                        d.celula(.tableDataCell) { d.numero(t.corrigido - t.bruto, col: 4, y: y, h: h, f: E.numeroNegrito, sinal: true) }
                    }
                }
                y += h
            case let .gasto(ti, k, h, previsto):
                let l = r.topicos[ti].linhas[k]
                let topoDoTexto = y + MedidaDoPDF.recuoDeCima, linha = MedidaDoPDF.fonteDaDescricao.lineHeight
                d.linha {
                    d.celula(.tableDataCell) {
                        // Sempre na altura prevista: num retângulo de altura infinita o draw(with:) apaga linhas.
                        MedidaDoPDF.descricao(l.texto).draw(
                            with: CGRect(x: ColunasDoPDF.esquerda + ColunasDoPDF.recuoDoGasto, y: topoDoTexto,
                                         width: MedidaDoPDF.larguraDaDescricao, height: ceil(previsto) + 1),
                            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    }
                    d.celula(.tableDataCell) {
                        d.esquerda(d.texto(l.data, MedidaDoPDF.fonteDaDescricao, E.secundario),
                                   x: ColunasDoPDF.direita(0) + ColunasDoPDF.folga, y: topoDoTexto, h: linha, f: MedidaDoPDF.fonteDaDescricao)
                    }
                    d.celula(.tableDataCell) { d.numero(l.bruto, col: 2, y: topoDoTexto, h: linha) }
                    d.celula(.tableDataCell) { d.numero(l.corrigido, col: 3, y: topoDoTexto, h: linha) }
                    d.celula(.tableDataCell) { d.numero(l.corrigido - l.bruto, col: 4, y: topoDoTexto, h: linha, sinal: true) }
                }
                y += h
            case .total:
                let h = P.totalGeral
                d.linha {
                    d.celula(.tableDataCell) { d.esquerda(d.texto("Total", E.negrito, E.texto), x: 50, y: y, h: h, f: E.negrito) }
                    d.celula(.tableDataCell) {}
                    d.celula(.tableDataCell) { d.numero(r.totalBruto, col: 2, y: y, h: h, f: E.numeroNegrito, cor: E.secundario) }
                    d.celula(.tableDataCell) { d.numero(r.totalCorrigido, col: 3, y: y, h: h, f: E.numeroNegrito) }
                    d.celula(.tableDataCell) {
                        d.numero(r.totalCorrigido - r.totalBruto, col: 4, y: y, h: h, f: E.numeroNegrito, sinal: true)
                    }
                }
                y += h
            case let .venda(k):
                let h = P.venda
                d.linha {
                    d.celula(.tableDataCell) {
                        d.esquerda(d.texto(k == 0 ? "Venda estimada" : "Margem estimada (estimado − corrigido)", E.semi, E.texto),
                                   x: 50, y: y, h: h, f: E.semi)
                    }
                    d.celula(.tableDataCell) {}
                    d.celula(.tableDataCell) {
                        d.numero(k == 0 ? (r.venda ?? 0) : (r.margem ?? 0), col: 2, y: y, h: h, f: E.numeroSemi, cor: E.secundario)
                    }
                }
                y += h
            }
        }
        if fechaTabela { d.fechar() }
        if ultima && r.venda == nil {
            d.marcar(.paragraph) {
                d.esquerda(d.texto("Venda estimada não informada nesta obra.", E.italico, E.secundario), x: 44, y: y + 8,
                           h: E.italico.lineHeight, f: E.italico)
            }
        }
        if ultima && d.marcacao?.idioma == .documentoExplicito { d.fechar() }
    }
}

/// Colunas da tabela (x da página): Gasto 44–253,5 · Data –317 · Bruto –387 · Corrigido –469,5 · Correção –551.
enum ColunasDoPDF {
    static let larguras: [CGFloat] = [209.5, 63.5, 70, 82.5, 81.5]
    static let esquerda: CGFloat = 44, folga: CGFloat = 6, recuoDoGasto: CGFloat = 19
    static func direita(_ i: Int) -> CGFloat { esquerda + larguras[0...i].reduce(0, +) }
}

enum EstiloDoPDF {
    static func cor(_ hex: UInt32, _ a: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
    }
    static let forte = cor(0x177A4A), texto = cor(0x13261E), secundario = cor(0x3B574B), caixa = cor(0xF2F7F4), grade = cor(0x142B23, 0.14)
    static let paleta: [UIColor] = [0x10976A, 0x2A78D6, 0xD14F86, 0x6250D6, 0xDC5A1E, 0x0C86A4, 0x5E7A6E].map { cor($0) }
    static let numero = UIFont.monospacedSystemFont(ofSize: 9.5, weight: .medium)
    static let numeroNegrito = UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
    static let numeroSemi = UIFont.monospacedSystemFont(ofSize: 9.5, weight: .semibold)
    static let th = UIFont.systemFont(ofSize: 9, weight: .semibold)
    static let topico = UIFont.systemFont(ofSize: 10, weight: .semibold)
    static let quantidade = UIFont.systemFont(ofSize: 9)
    static let negrito = UIFont.systemFont(ofSize: 9.5, weight: .bold)
    static let semi = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
    static let subtitulo = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
    static let titulo = UIFont.monospacedSystemFont(ofSize: 24, weight: .semibold)
    static let meta = UIFont.systemFont(ofSize: 10.5)
    static let logo = UIFont.systemFont(ofSize: 18, weight: .heavy)
    static let cabecalho = UIFont.systemFont(ofSize: 10)
    static let rodape = UIFont.systemFont(ofSize: 9)
    static let italico = UIFont.italicSystemFont(ofSize: 10)
}

/// O contexto da página e as tags. Sem marcação, `marcar`, `linha` e `celula` só desenham.
private struct Pincel {
    let ctx: UIGraphicsPDFRendererContext
    let marcacao: MarcacaoDoPDF?
    var cg: CGContext { ctx.cgContext }

    func texto(_ s: String, _ f: UIFont, _ c: UIColor, kern: CGFloat = 0) -> NSAttributedString {
        var a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: c]
        if kern != 0 { a[.kern] = kern }
        return NSAttributedString(string: s, attributes: a)
    }
    /// Uma linha, centrada na faixa [y, y + h].
    func esquerda(_ a: NSAttributedString, x: CGFloat, y: CGFloat, h: CGFloat, f: UIFont) {
        a.draw(at: CGPoint(x: x, y: y + (h - f.lineHeight) / 2))
    }
    func direita(_ a: NSAttributedString, x: CGFloat, y: CGFloat, h: CGFloat, f: UIFont) {
        a.draw(at: CGPoint(x: x - a.size().width, y: y + (h - f.lineHeight) / 2))
    }
    func retangulo(_ r: CGRect, _ c: UIColor) { cg.setFillColor(c.cgColor); cg.fill(r) }
    func numero(_ v: Double, col: Int, y: CGFloat, h: CGFloat, f: UIFont = EstiloDoPDF.numero, sinal: Bool = false,
                cor: UIColor = EstiloDoPDF.texto) {
        direita(texto(FormatoDoPDF.numero(v, sinal: sinal), f, cor, kern: -0.285), x: ColunasDoPDF.direita(col) - ColunasDoPDF.folga,
                y: y, h: h, f: f)
    }

    // MARK: tags (API do iOS 13)

    /// Abre uma tag. As do topo (filhas do Document que a API cria) levam o idioma, quando a marcação pede assim.
    func abrir(_ tipo: CGPDFTagType, alt: String? = nil, idiomaExplicito: Bool = false) {
        guard let marcacao else { return }
        var propriedades: [String: Any] = [:]
        let doTopo = tipo != .tableRow && tipo != .tableHeaderCell && tipo != .tableDataCell
        if idiomaExplicito || (doTopo && marcacao.idioma == .emCadaElemento && tipo != .document) {
            propriedades[CGPDFTagProperty.languageText.rawValue as String] = GeradorDoPDF.idioma
        }
        if let alt { propriedades[CGPDFTagProperty.alternativeText.rawValue as String] = alt }
        CGPDFContextBeginTag(cg, tipo, propriedades as CFDictionary)
    }
    func fechar() {
        guard marcacao != nil else { return }
        CGPDFContextEndTag(cg)
    }
    func marcar(_ tipo: CGPDFTagType, alt: String? = nil, _ desenho: () -> Void) {
        abrir(tipo, alt: alt)
        desenho()
        fechar()
    }
    func linha(_ desenho: () -> Void) { marcar(.tableRow, desenho) }
    func celula(_ tipo: CGPDFTagType, _ desenho: () -> Void) { marcar(tipo, desenho) }
}
