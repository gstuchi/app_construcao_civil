import Foundation
import PDFKit
import Testing
import UIKit
@testable import Custta

/* SONDA 2 DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main): a marcação para leitor de tela pela API do iOS 13
   (CGPDFContextBeginTag/EndTag), lida de volta pelo catálogo do CGPDFDocument. Um método por variante.
   (a) arvoreGravada: /MarkInfo /Marked, /StructTreeRoot com /K, o idioma, os tipos (H1, P, Figure com /Alt, Table,
       TR, TH, TD) e o que um Document explícito vira; guarda o PDF marcado de 500 gastos;
   (b) tabelaAtravessaPaginas: um Table só, aberto da primeira à última página da tabela, e o que a API faz com ele;
   (c) custoDaMarcacao5000: tempo com e sem marcação (mediana de 3), memória e tamanho, com 5.000 gastos;
   (d) semMarcacaoMesmoTexto: sem marcação, o mesmo PDF: as mesmas palavras em cada página (a ordem em que o PDFKit as
       extrai muda com a árvore) e os mesmos pixels. */

@Suite(.serialized)
struct SondaPDFMarcacaoTests {
    typealias S = SaidaDaSonda

    // MARK: (a) a árvore gravada

    @Test @MainActor func arvoreGravada() async throws {
        let passo = "marcacao-arvore"
        registrarAmbiente(passo)
        let r = DadosDaSonda.relatorio(gastos: 500)
        let url = S.guardado("marcado-500.pdf")
        let captura = CapturaDoStderr()
        let resumo = try await GeradorDoPDF.gerar(r, em: url, marcacao: .padrao)
        let stderr = captura.terminar()
        let dadosDoMarcado = try Data(contentsOf: url)
        Attachment.record(dadosDoMarcado, named: "marcado-500.pdf")
        let e = try #require(LeitorDaEstrutura.ler(url))
        let n = e.contagem()
        let topo = e.raiz.first?.filhos ?? []
        let semIdioma = topo.filter { $0.lang != GeradorDoPDF.idioma }
        let figuras = e.todos.filter { $0.tipo == "Figure" }
        S.registrar(passo, "\(resumo.paginas) páginas, \(resumo.bytes) bytes; /MarkInfo /Marked: \(e.marcado.map { String($0) } ?? "ausente"); "
                    + "/StructTreeRoot: \(e.temStructTreeRoot); /K: \(e.temK); /ParentTree no arquivo: \(e.parentTreeNoArquivo), resolve: "
                    + "\(e.temParentTree); /IDTree no arquivo: \(e.idTreeNoArquivo), resolve: \(e.temIDTree); páginas com /StructParents: "
                    + "\(e.paginasComStructParents) de \(e.paginas)")
        S.registrar(passo, "raiz: \(e.raiz.map(\.tipo)) (Lang da raiz: \(e.raiz.first?.lang ?? "ausente")); /Lang do catálogo: "
                    + "\(e.langDoCatalogo ?? "ausente"); elementos do topo: \(topo.count) (\(Set(topo.map(\.tipo)).sorted())), sem pt-BR: \(semIdioma.count)")
        S.registrar(passo, "tipos: \(e.contagemEmTexto)")
        S.registrar(passo, "Figure: \(figuras.count), com /Alt: \(figuras.filter { !($0.alt ?? "").isEmpty }.count), na página "
                    + "\(figuras.first?.pagina.map(String.init) ?? "?"); Alt: \(figuras.first?.alt?.prefix(120) ?? "ausente")")
        for linha in (e.raiz.first?.contorno(0, limite: 7) ?? []).prefix(28) { S.registrar(passo, "árvore: " + linha) }
        registrarStderr(passo, stderr)
        #expect(e.marcado == true)
        #expect(e.temStructTreeRoot && e.temK)
        #expect(e.raiz.count == 1 && e.raiz.first?.tipo == "Document")
        #expect(!topo.isEmpty && semIdioma.isEmpty)
        for tipo in ["H1", "P", "Figure", "Table", "TR", "TH", "TD"] { #expect((n[tipo] ?? 0) > 0, "falta \(tipo)") }
        #expect(figuras.count == 1 && !(figuras.first?.alt ?? "").isEmpty)

        // O idioma num Document explícito, aberto na página 1 e fechado na última: o que a API grava.
        let urlDocumento = S.temporario("marcado-documento-explicito-500.pdf")
        let capturaDoc = CapturaDoStderr()
        _ = try await GeradorDoPDF.gerar(r, em: urlDocumento, marcacao: MarcacaoDoPDF(idioma: .documentoExplicito))
        let stderrDoc = capturaDoc.terminar()
        let d = try #require(LeitorDaEstrutura.ler(urlDocumento))
        let documentos = d.todos.filter { $0.tipo == "Document" }
        S.registrar(passo + "-documento", "Document explícito com pt-BR: \(documentos.count) Document na árvore; "
                    + documentos.map { "Lang \($0.lang ?? "ausente"), páginas \(paginasEmTexto($0.paginas))" }.joined(separator: " · ")
                    + "; filhos da raiz: \(d.raiz.first?.filhos.count ?? 0)")
        for linha in (d.raiz.first?.contorno(0, limite: 4) ?? []).prefix(12) { S.registrar(passo + "-documento", "árvore: " + linha) }
        registrarStderr(passo + "-documento", stderrDoc)
    }

    // MARK: (b) a tabela atravessando páginas

    @Test @MainActor func tabelaAtravessaPaginas() async throws {
        let passo = "marcacao-tabela"
        registrarAmbiente(passo)
        let r = DadosDaSonda.relatorio(gastos: 500)
        // O que o spec quer: um Table só, aberto na primeira página da tabela e fechado na última.
        let urlUnica = S.guardado("marcado-tabela-unica-500.pdf")
        let captura = CapturaDoStderr()
        let resumo = try await GeradorDoPDF.gerar(r, em: urlUnica, marcacao: MarcacaoDoPDF(tabela: .unica))
        let stderr = captura.terminar()
        let e = try #require(LeitorDaEstrutura.ler(urlUnica))
        let tabelas = e.todos.filter { $0.tipo == "Table" }
        let orfaos = (e.raiz.first?.filhos ?? []).filter { $0.tipo == "TR" }
        let linhasNaTabela = tabelas.reduce(0) { $0 + $1.filhos.filter { $0.tipo == "TR" }.count }
        S.registrar(passo, "Table aberto na página 2 e fechado na \(resumo.paginas): \(tabelas.count) Table; páginas de cada: "
                    + tabelas.map { paginasEmTexto($0.paginas) }.joined(separator: " · ") + "; TR dentro de Table: \(linhasNaTabela); "
                    + "TR soltos, filhos do Document: \(orfaos.count), nas páginas \(paginasEmTexto(Set(orfaos.flatMap(\.paginas))))")
        registrarStderr(passo, stderr)
        withKnownIssue("A API do iOS 13 fecha a tag no fim da página: o Table não atravessa", isIntermittent: false) {
            #expect(tabelas.count == 1 && (tabelas.first?.paginas.count ?? 0) >= 2)
        }

        // O que a API deixa: um Table por página, cada um com a linha de cabeçalho (TH).
        let urlPorPagina = S.temporario("marcado-por-pagina-500.pdf")
        let resumoPorPagina = try await GeradorDoPDF.gerar(r, em: urlPorPagina, marcacao: .padrao)
        let p = try #require(LeitorDaEstrutura.ler(urlPorPagina))
        let porPagina = p.todos.filter { $0.tipo == "Table" }
        let comTH = porPagina.filter { $0.filhos.first?.filhos.contains { $0.tipo == "TH" } ?? false }
        let deUmaPagina = porPagina.filter { $0.paginas.count == 1 }
        let soltos = (p.raiz.first?.filhos ?? []).filter { $0.tipo == "TR" }
        S.registrar(passo, "um Table por página: \(porPagina.count) Table em \(resumoPorPagina.paginas - 1) páginas de tabela; "
                    + "com a linha de TH: \(comTH.count); de uma página só: \(deUmaPagina.count); TR soltos: \(soltos.count)")
        #expect(porPagina.count == resumoPorPagina.paginas - 1)
        #expect(comTH.count == porPagina.count)
        #expect(deUmaPagina.count == porPagina.count)
        #expect(soltos.isEmpty)
    }

    // MARK: (c) o custo com 5.000 gastos

    @Test @MainActor func custoDaMarcacao5000() async throws {
        let passo = "marcacao-custo"
        registrarAmbiente(passo)
        AmbienteDaSonda.esvaziarApp()
        let r500 = DadosDaSonda.relatorio(gastos: 500)
        _ = try await GeradorDoPDF.gerar(r500, em: S.temporario("aquecimento-sem.pdf"), marcacao: nil)
        _ = try await GeradorDoPDF.gerar(r500, em: S.temporario("aquecimento-com.pdf"), marcacao: .padrao)
        let r = DadosDaSonda.relatorio(gastos: 5000)
        var tempos: [Bool: [Double]] = [false: [], true: []], escritas: [Bool: [Double]] = [false: [], true: []]
        var memorias: [Bool: [Double]] = [false: [], true: []], picos: [Bool: [Double]] = [false: [], true: []]
        var bytes: [Bool: Int] = [:], paginas = 0
        for k in 1...3 {
            for marcar in [false, true] {
                let url = S.temporario("custo-\(marcar ? "com" : "sem")-5000.pdf")
                try? FileManager.default.removeItem(at: url)
                let memoria = AmostradorDeMemoria()
                memoria.comecar()
                let resumo = try await GeradorDoPDF.gerar(r, em: url, marcacao: marcar ? .padrao : nil)
                let mem = memoria.parar()
                tempos[marcar, default: []].append(resumo.total)
                escritas[marcar, default: []].append(resumo.escrita)
                memorias[marcar, default: []].append(mem.aumento)
                picos[marcar, default: []].append(mem.pico)
                bytes[marcar] = resumo.bytes
                paginas = resumo.paginas
                S.registrar(passo, "rodada \(k), \(marcar ? "com" : "sem") marcação: total \(S.ms(resumo.total)) ms (escrita "
                            + "\(S.ms(resumo.escrita))); memória +\(S.mb(mem.aumento)) MB (pico \(S.mb(mem.pico)) MB); \(resumo.bytes) bytes; "
                            + "\(resumo.paginas) páginas")
                try await Task.sleep(for: .milliseconds(100))
            }
        }
        let sem = S.mediana(tempos[false] ?? []), com = S.mediana(tempos[true] ?? [])
        let bSem = Double(bytes[false] ?? 0), bCom = Double(bytes[true] ?? 0)
        let custo = (com / max(sem, 0.000_001) - 1) * 100
        S.registrar(passo, "mediana de 3 com 5.000 gastos (\(paginas) páginas): sem \(S.ms(sem)) ms, com \(S.ms(com)) ms ("
                    + String(format: "%+.1f%%", custo) + ", alvo até +15%: \(custo <= 15 ? "dentro" : "fora")); escrita sem "
                    + "\(S.ms(S.mediana(escritas[false] ?? []))) ms, com \(S.ms(S.mediana(escritas[true] ?? []))) ms; memória sem +"
                    + "\(S.mb(S.mediana(memorias[false] ?? []))) MB, com +\(S.mb(S.mediana(memorias[true] ?? []))) MB (1ª rodada: sem +"
                    + "\(S.mb(memorias[false]?.first ?? 0)), com +\(S.mb(memorias[true]?.first ?? 0)); maior pico: sem "
                    + "\(S.mb(picos[false]?.max() ?? 0)), com \(S.mb(picos[true]?.max() ?? 0))); tamanho sem "
                    + "\(Int(bSem)) bytes, com \(Int(bCom)) bytes (" + String(format: "%+.1f%%", (bCom / max(bSem, 1) - 1) * 100) + ")")
    }

    // MARK: (d) sem marcação, o mesmo texto

    @Test @MainActor func semMarcacaoMesmoTexto() async throws {
        let passo = "marcacao-texto"
        registrarAmbiente(passo)
        let r = DadosDaSonda.relatorio(gastos: 500)
        let urlSem = S.guardado("sem-marcacao-500.pdf"), urlCom = S.temporario("com-marcacao-500.pdf")
        _ = try await GeradorDoPDF.gerar(r, em: urlSem, marcacao: nil)
        _ = try await GeradorDoPDF.gerar(r, em: urlCom, marcacao: .padrao)
        let c = ComparacaoDePDF.comparar(urlSem, urlCom)
        let eSem = LeitorDaEstrutura.ler(urlSem)
        S.registrar(passo, "sem × com marcação: \(c.resumo); o sem marcação tem /StructTreeRoot: \(eSem?.temStructTreeRoot ?? false), "
                    + "/MarkInfo: \(eSem?.marcado.map { String($0) } ?? "ausente")")
        // Com a árvore, o PDFKit lê o texto na ordem da estrutura: o que conta é o mesmo texto, fora a ordem, e os mesmos pixels.
        for i in [1, 2] {
            let a = PDFTexto.daPagina(urlSem, i), b = PDFTexto.daPagina(urlCom, i)
            S.registrar(passo, "página \(i), texto extraído sem marcação: \(a.prefix(220).replacingOccurrences(of: "\n", with: "⏎"))")
            S.registrar(passo, "página \(i), texto extraído com marcação: \(b.prefix(220).replacingOccurrences(of: "\n", with: "⏎"))")
        }
        #expect(c.paginasA == c.paginasB && c.paginasA > 1)
        #expect(c.palavrasDiferentes == 0)
        #expect(c.pixelDiferente == 0)
        #expect(eSem?.temStructTreeRoot == false)
    }

    // MARK: apoio

    private func paginasEmTexto(_ s: Set<Int>) -> String {
        let p = s.sorted()
        guard let a = p.first, let b = p.last else { return "nenhuma" }
        return a == b ? "\(a)" : "\(a)–\(b) (\(p.count))"
    }

    /// O que o CoreGraphics disse no stderr durante a geração (erro de tag, por exemplo).
    private func registrarStderr(_ passo: String, _ stderr: String) {
        let linhas = stderr.split(separator: "\n").map { String($0.prefix(200)) }
        S.registrar(passo, "stderr na geração: \(linhas.count) linhas" + (linhas.isEmpty ? "" : " · " + linhas.prefix(3).joined(separator: " ⏎ ")))
    }
}

enum PDFTexto {
    @MainActor static func daPagina(_ url: URL, _ numero: Int) -> String {
        PDFDocument(url: url)?.page(at: numero - 1)?.string ?? ""
    }
}
