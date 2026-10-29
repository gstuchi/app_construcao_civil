import Foundation
import UIKit
import PDFKit
import MachO
import Testing
@testable import Custta

/* SONDA DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main). Apoio dos testes das duas sondas: dados sintéticos,
   saída, instrumentos (bloqueio da thread principal, memória, stderr), comparação de PDFs e leitura da árvore. */

// MARK: - Saída

enum SaidaDaSonda {
    /// Pasta dos PDFs guardados e das linhas da sonda: SONDA_PDF_SAIDA (na CI, TEST_RUNNER_SONDA_PDF_SAIDA) ou o tmp.
    static let pasta: URL = {
        let caminho = ProcessInfo.processInfo.environment["SONDA_PDF_SAIDA"]
        let url = caminho.map { URL(fileURLWithPath: $0) } ?? FileManager.default.temporaryDirectory.appendingPathComponent("sonda-pdf")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    static func guardado(_ nome: String) -> URL { pasta.appendingPathComponent(nome) }
    static func temporario(_ nome: String) -> URL {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent("sonda-pdf-tmp")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d.appendingPathComponent(nome)
    }
    /// Uma linha "sonda-pdf | passo | resultado", no log e em linhas.txt.
    static func registrar(_ passo: String, _ resultado: String) {
        let linha = "sonda-pdf | \(passo) | \(resultado)"
        print(linha)
        let url = pasta.appendingPathComponent("linhas.txt")
        if let h = try? FileHandle(forWritingTo: url) {
            _ = try? h.seekToEnd(); try? h.write(contentsOf: Data((linha + "\n").utf8)); try? h.close()
        } else {
            try? Data((linha + "\n").utf8).write(to: url)
        }
    }
    static func ms(_ s: Double) -> String { String(format: "%.1f", s * 1000) }
    static func mb(_ b: Double) -> String { String(format: "%.1f", b / 1_048_576) }
    static func mediana(_ v: [Double]) -> Double { let s = v.sorted(); return s.isEmpty ? 0 : s[s.count / 2] }
}

@MainActor func registrarAmbiente(_ passo: String) {
    SaidaDaSonda.registrar(passo, "iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model) · "
                           + "verificador da thread principal carregado: \(VerificadorDaThreadPrincipal.carregado())")
}

// MARK: - Dados sintéticos (determinísticos)

enum DadosDaSonda {
    struct Sorteio {
        var estado: UInt64
        mutating func proximo() -> UInt64 {
            estado &+= 0x9E37_79B9_7F4A_7C15
            var z = estado
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        mutating func uniforme() -> Double { Double(proximo() >> 11) / Double(1 << 53) }
        mutating func inteiro(_ faixa: ClosedRange<Int>) -> Int { faixa.lowerBound + Int(proximo() % UInt64(faixa.count)) }
        mutating func um<T>(_ a: [T]) -> T { a[Int(proximo() % UInt64(a.count))] }
    }

    static let topicos: [(nome: String, peso: Double, base: Double)] = [
        ("Terreno", 0.004, 160_000), ("Mão de obra", 0.20, 3_400), ("Estrutura", 0.10, 5_800), ("Alvenaria", 0.09, 2_400),
        ("Fundação", 0.05, 4_900), ("Cobertura", 0.05, 3_900), ("Instalações elétricas", 0.08, 1_700),
        ("Instalações hidráulicas", 0.08, 1_550), ("Esquadrias", 0.05, 4_300), ("Revestimentos", 0.09, 2_700),
        ("Pintura", 0.06, 1_450), ("Acabamentos", 0.07, 2_150), ("Projetos e taxas", 0.03, 2_900), ("Outros", 0.026, 880),
    ]
    static let palavras = ["cimento", "areia média", "brita 1", "tijolo baiano", "bloco de concreto", "vergalhão de 10 mm",
                           "concreto usinado", "tubulação de água e esgoto", "fiação", "disjuntores", "telhas", "madeira",
                           "porcelanato", "argamassa", "rejunte", "tinta acrílica", "massa corrida", "portas", "janelas de alumínio",
                           "frete", "diária do pedreiro", "servente", "eletricista", "encanador", "projeto estrutural",
                           "taxa da prefeitura", "da área gourmet", "do banheiro social", "da suíte", "da cozinha", "da garagem",
                           "do muro", "da laje", "do telhado", "impermeabilização", "caixa d'água", "reboco", "contrapiso",
                           "gesso", "esquadria", "vidro temperado", "louças", "metais", "aterro", "terraplenagem", "andaime"]

    static func descricao(_ s: inout Sorteio, tamanho: ClosedRange<Int>) -> String {
        var t = s.um(palavras).capitalizedFirst
        while t.count < tamanho.lowerBound { t += " " + s.um(palavras) }
        if t.count > tamanho.upperBound { t = String(t.prefix(tamanho.upperBound)).trimmingCharacters(in: .whitespaces) }
        return t
    }

    /// Uma obra de n gastos, em 24 meses até 29/10/2026 (5% a vencer), 12% das compras parceladas "(n/de)", descrições
    /// de 15 a 60 caracteres, 3% com 300–500 e 1% com 1.500.
    static func relatorio(gastos n: Int, semente: UInt64 = 2026) -> RelatorioDoPDF {
        var s = Sorteio(estado: semente &+ UInt64(n))
        let somaDosPesos = topicos.reduce(0) { $0 + $1.peso }
        // dias desde 01/11/2024 (o dia 0); hoje é o dia 727 (29/10/2026)
        let hoje = 727
        var porTopico = [[(dia: Int, linha: LinhaDoPDF)]](repeating: [], count: topicos.count)
        for i in 0..<n {
            var u = s.uniforme() * somaDosPesos, t = 0
            while t < topicos.count - 1 && u > topicos[t].peso { u -= topicos[t].peso; t += 1 }
            if i == 0 { t = 0 }   // o terreno sempre aparece
            let sorteioDoTamanho = s.uniforme()
            let tamanho: ClosedRange<Int> = sorteioDoTamanho < 0.01 ? 1_500...1_500 : sorteioDoTamanho < 0.04 ? 300...500 : 15...60
            var texto = descricao(&s, tamanho: tamanho)
            if s.uniforme() < 0.12 { let de = s.inteiro(2...10); texto += " (\(s.inteiro(1...de))/\(de))" }
            let dia = s.uniforme() < 0.05 ? hoje + s.inteiro(1...150) : s.inteiro(0...hoje)
            let valor = (topicos[t].base * (0.2 + 1.6 * s.uniforme()) * 100).rounded() / 100
            let meses = max(0, Double(hoje - dia) / 30.44)
            let corrigido = dia > hoje ? valor : (valor * pow(1.008, meses) * 100).rounded() / 100
            porTopico[t].append((dia, LinhaDoPDF(id: "g\(i)", texto: texto, data: data(dia), bruto: valor, corrigido: corrigido)))
        }
        var grupos: [TopicoDoPDF] = []
        for (t, itens) in porTopico.enumerated() where !itens.isEmpty {
            let linhas = itens.sorted { ($0.dia, $0.linha.id) < ($1.dia, $1.linha.id) }.map(\.linha)
            grupos.append(TopicoDoPDF(nome: topicos[t].nome, cor: 0, linhas: linhas, bruto: linhas.reduce(0) { $0 + $1.bruto },
                                      corrigido: linhas.reduce(0) { $0 + $1.corrigido }))
        }
        grupos.sort { ($0.bruto, $1.nome) > ($1.bruto, $0.nome) }
        grupos = grupos.enumerated().map { i, g in TopicoDoPDF(nome: g.nome, cor: min(i, 6), linhas: g.linhas, bruto: g.bruto, corrigido: g.corrigido) }
        let totB = grupos.reduce(0) { $0 + $1.bruto }, totC = grupos.reduce(0) { $0 + $1.corrigido }
        var pedacos = grupos.prefix(6).enumerated().map { i, g in PedacoDoPDF(nome: g.nome, valor: g.bruto, cor: i, pct: g.bruto / totB * 100) }
        let resto = grupos.dropFirst(6).reduce(0) { $0 + $1.bruto }
        if resto > 0 { pedacos.append(PedacoDoPDF(nome: "Outros", valor: resto, cor: 6, pct: resto / totB * 100)) }
        // meses: de nov/24 até o último gasto
        var porMes: [Int: (b: Double, c: Double)] = [:]
        for itens in porTopico { for (dia, l) in itens { porMes[dia / 30, default: (0, 0)].b += l.bruto; porMes[dia / 30, default: (0, 0)].c += l.corrigido } }
        let ultimoMes = porMes.keys.max() ?? 0, mesDeHoje = hoje / 30
        let meses = (0...ultimoMes).map { m in MesDoPDF(rotulo: rotuloDoMes(m), total: porMes[m]?.b ?? 0, futuro: m > mesDeHoje) }
        var acB = 0.0, acC = 0.0
        let acumulado = (0...min(ultimoMes, mesDeHoje)).map { m -> PontoDoPDF in
            acB += porMes[m]?.b ?? 0; acC += porMes[m]?.c ?? 0
            return PontoDoPDF(bruto: acB, corrigido: acC)
        }
        let meta = "Em construção · começou em 01/11/24 · 24 meses · 182 m² · correção de 0,8% ao mês, da data de cada gasto até hoje"
        return RelatorioDoPDF(nome: "Casa Alphaville", meta: meta, dataTexto: "29/10/2026", lancamentos: n, totalBruto: totB,
                              totalCorrigido: totC, venda: 1_450_000, topicos: grupos, pedacos: pedacos, acumulado: acumulado, meses: meses)
    }

    static func data(_ dia: Int) -> String {
        var d = dia + 1, m = 11, a = 2024
        let dias = { (m: Int, a: Int) -> Int in [31, a % 4 == 0 ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1] }
        while d > dias(m, a) { d -= dias(m, a); m += 1; if m > 12 { m = 1; a += 1 } }
        return String(format: "%02d/%02d/%02d", d, m, a % 100)
    }
    static func rotuloDoMes(_ k: Int) -> String {
        let nomes = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
        let m = (10 + k) % 12, a = 24 + (10 + k) / 12
        return "\(nomes[m])/\(a)"
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - Instrumentos

/// Maior bloqueio contínuo da principal, por dois relógios: um Timer de 1 ms no run loop principal (maior intervalo
/// entre dois disparos) e um "ping" de outra thread (maior espera até a fila principal rodar um bloco).
final class VigiaDaThreadPrincipal: @unchecked Sendable {
    private let trava = NSLock()
    private var ultimoTique = 0.0, maiorLacuna = 0.0, maiorPing = 0.0, ligado = false
    private var timer: Timer?
    private let fim = DispatchSemaphore(value: 0)

    @MainActor func comecar() {
        trava.withLock { ultimoTique = CACurrentMediaTime(); maiorLacuna = 0; maiorPing = 0; ligado = true }
        let t = Timer(timeInterval: 0.001, repeats: true) { [self] _ in tique() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        let th = Thread { [self] in pingar() }
        th.qualityOfService = .userInteractive
        th.start()
    }
    private func tique() {
        let a = CACurrentMediaTime()
        trava.withLock { maiorLacuna = max(maiorLacuna, a - ultimoTique); ultimoTique = a }
    }
    private func pingar() {
        while trava.withLock({ ligado }) {
            let s = DispatchSemaphore(value: 0), t0 = CACurrentMediaTime()
            DispatchQueue.main.async { s.signal() }
            s.wait()
            let d = CACurrentMediaTime() - t0
            trava.withLock { maiorPing = max(maiorPing, d) }
            usleep(500)
        }
        fim.signal()
    }
    @MainActor func parar() async -> (lacuna: Double, ping: Double) {
        timer?.invalidate(); timer = nil
        tique()
        trava.withLock { ligado = false }
        let s = fim
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in DispatchQueue.global().async { s.wait(); c.resume() } }
        return trava.withLock { (maiorLacuna, maiorPing) }
    }
}

/// phys_footprint (task_info TASK_VM_INFO), amostrado a cada 1 ms numa thread à parte.
final class AmostradorDeMemoria: @unchecked Sendable {
    static func pegada() -> UInt64 {
        var info = task_vm_info_data_t()
        var n = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) { p in
            p.withMemoryRebound(to: integer_t.self, capacity: Int(n)) { task_info(task_self_trap(), task_flavor_t(TASK_VM_INFO), $0, &n) }
        }
        return kr == KERN_SUCCESS ? info.phys_footprint : 0
    }
    private let trava = NSLock()
    private var ligado = false, pico: UInt64 = 0, base: UInt64 = 0
    private let fim = DispatchSemaphore(value: 0)
    func comecar() {
        let b = Self.pegada()
        trava.withLock { base = b; pico = b; ligado = true }
        let th = Thread { [self] in
            while true {
                let p = Self.pegada()
                let continua = trava.withLock { pico = max(pico, p); return ligado }
                if !continua { break }
                usleep(1000)
            }
            fim.signal()
        }
        th.qualityOfService = .userInteractive
        th.start()
    }
    /// O pico menos a base e o pico absoluto, em bytes.
    func parar() -> (aumento: Double, pico: Double) {
        let p = Self.pegada()
        trava.withLock { pico = max(pico, p); ligado = false }
        fim.wait()
        return trava.withLock { (Double(pico) - Double(base), Double(pico)) }
    }
}

enum VerificadorDaThreadPrincipal {
    /// A libMainThreadChecker está no processo (o xcodebuild a injeta quando o esquema liga o verificador).
    static func carregado() -> Bool {
        for i in 0..<_dyld_image_count() {
            if let n = _dyld_get_image_name(i), String(cString: n).contains("libMainThreadChecker") { return true }
        }
        return false
    }
    /// Avisos do verificador num texto (o relato começa sempre assim).
    static func avisos(em texto: String) -> [String] {
        texto.split(separator: "\n").map(String.init).filter { $0.contains("Main Thread Checker:") }
    }
    /// Com MTC_CRASH_ON_REPORT o verificador derruba o processo no primeiro relato: aí não se captura o stderr, para
    /// o relato sair no log do xcodebuild.
    static var derrubaNoRelato: Bool { ProcessInfo.processInfo.environment["MTC_CRASH_ON_REPORT"] != nil }
}

/// Desvia o stderr (fd 2) do processo para um arquivo enquanto a sonda roda. O verificador da thread principal relata
/// no stderr.
final class CapturaDoStderr {
    private let url: URL
    private let salvo: Int32
    private let arquivo: Int32

    init() {
        url = SaidaDaSonda.temporario("stderr-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        arquivo = open(url.path, O_WRONLY | O_APPEND)
        fflush(nil)
        salvo = dup(STDERR_FILENO)
        dup2(arquivo, STDERR_FILENO)
    }
    func terminar() -> String {
        fflush(nil)
        dup2(salvo, STDERR_FILENO)
        close(salvo)
        close(arquivo)
        defer { try? FileManager.default.removeItem(at: url) }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}

enum AmbienteDaSonda {
    /// O app hospedeiro mostra a abertura animada (aurora e globo): troca por uma tela parada, para a principal ficar
    /// livre, como o fundo que para durante a geração (spec).
    @MainActor static func esvaziarApp() {
        for cena in UIApplication.shared.connectedScenes {
            guard let ws = cena as? UIWindowScene else { continue }
            for janela in ws.windows { let vc = UIViewController(); vc.view.backgroundColor = .black; janela.rootViewController = vc }
        }
    }
}

// MARK: - Comparação de PDFs

struct ComparacaoDePDF {
    var paginasA = 0, paginasB = 0, textoDiferente = 0, palavrasDiferentes = 0, pixelDiferente = 0, maiorDiferenca = 0
    var primeiraComTextoDiferente: Int?

    var resumo: String {
        "páginas \(paginasA) × \(paginasB); texto diferente em \(textoDiferente) (palavras diferentes, fora a ordem, em "
            + "\(palavrasDiferentes)); pixels diferentes em \(pixelDiferente)" + (pixelDiferente > 0 ? " (até \(maiorDiferenca) por página)" : "")
    }

    /// Mesmo texto por página (PDFKit) e mesmos pixels por página, desenhada em escala 1.
    @MainActor static func comparar(_ a: URL, _ b: URL) -> ComparacaoDePDF {
        var c = ComparacaoDePDF()
        guard let da = PDFDocument(url: a), let db = PDFDocument(url: b), let ca = CGPDFDocument(a as CFURL), let cb = CGPDFDocument(b as CFURL) else {
            c.paginasA = -1; return c
        }
        c.paginasA = da.pageCount; c.paginasB = db.pageCount
        for i in 0..<min(da.pageCount, db.pageCount) {
            let ta = da.page(at: i)?.string ?? "", tb = db.page(at: i)?.string ?? ""
            if ta != tb {
                c.textoDiferente += 1
                if c.primeiraComTextoDiferente == nil { c.primeiraComTextoDiferente = i + 1 }
                let pa = ta.split(whereSeparator: { $0.isWhitespace }).sorted(), pb = tb.split(whereSeparator: { $0.isWhitespace }).sorted()
                if pa != pb { c.palavrasDiferentes += 1 }
            }
            autoreleasepool {
                if let pa = ca.page(at: i + 1), let pb = cb.page(at: i + 1) {
                    let d = diferenca(bytes(pa), bytes(pb))
                    if d != 0 { c.pixelDiferente += 1; c.maiorDiferenca = max(c.maiorDiferenca, d) }
                }
            }
        }
        return c
    }

    static func bytes(_ pagina: CGPDFPage, escala: CGFloat = 1) -> [UInt8] {
        let w = Int(MedidaDoPDF.pagina.width * escala), h = Int(MedidaDoPDF.pagina.height * escala)
        var b = [UInt8](repeating: 255, count: w * h * 4)
        b.withUnsafeMutableBytes { m in
            guard let ctx = CGContext(data: m.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return }
            ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            ctx.scaleBy(x: escala, y: escala)
            ctx.drawPDFPage(pagina)
        }
        return b
    }
    static func diferenca(_ x: [UInt8], _ y: [UInt8]) -> Int {
        guard x.count == y.count else { return -1 }
        if x == y { return 0 }
        var n = 0
        for i in stride(from: 0, to: x.count, by: 4) where x[i] != y[i] || x[i + 1] != y[i + 1] || x[i + 2] != y[i + 2] { n += 1 }
        return n
    }
}

// MARK: - Árvore de estrutura, lida de volta pelo catálogo do CGPDFDocument

struct ElementoDaEstrutura {
    var tipo: String
    /// Página do elemento (/Pg), contada de 1; nil se o elemento não diz.
    var pagina: Int?
    var alt: String?
    var lang: String?
    var filhos: [ElementoDaEstrutura] = []
    /// Conteúdo marcado (MCID) ligado direto a este elemento, com a página de cada um.
    var conteudos: [(pagina: Int?, mcid: Int)] = []

    var todos: [ElementoDaEstrutura] { [self] + filhos.flatMap(\.todos) }
    /// Páginas citadas por este elemento e pelos descendentes (/Pg do elemento e de cada conteúdo).
    var paginas: Set<Int> {
        var s = Set(conteudos.compactMap(\.pagina))
        if let pagina { s.insert(pagina) }
        for f in filhos { s.formUnion(f.paginas) }
        return s
    }
    func contorno(_ nivel: Int = 0, limite: Int = 6) -> [String] {
        var linha = String(repeating: "  ", count: nivel) + "/" + tipo
        if let pagina { linha += " pg\(pagina)" }
        if let lang { linha += " Lang=\(lang)" }
        if let alt { linha += " Alt=\"\(alt.prefix(48))…\"" }
        if !conteudos.isEmpty { linha += " mcid×\(conteudos.count)" }
        var r = [linha]
        for (i, f) in filhos.enumerated() {
            if i == limite { r.append(String(repeating: "  ", count: nivel + 1) + "… +\(filhos.count - limite)"); break }
            r += f.contorno(nivel + 1, limite: limite)
        }
        return r
    }
}

struct EstruturaDoPDF {
    var marcado: Bool?
    var langDoCatalogo: String?
    var temStructTreeRoot = false
    var temK = false
    var temParentTree = false
    var temIDTree = false
    var parentTreeNoArquivo = false
    var idTreeNoArquivo = false
    var raiz: [ElementoDaEstrutura] = []
    var paginas = 0
    var paginasComStructParents = 0

    var todos: [ElementoDaEstrutura] { raiz.flatMap(\.todos) }
    func contagem() -> [String: Int] { todos.reduce(into: [:]) { $0[$1.tipo, default: 0] += 1 } }
    var contagemEmTexto: String { contagem().sorted { $0.key < $1.key }.map { "\($0.key)×\($0.value)" }.joined(separator: " ") }
}

enum LeitorDaEstrutura {
    static func nome(_ d: CGPDFDictionaryRef, _ k: String) -> String? {
        var p: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(d, k, &p), let p else { return nil }
        return String(cString: p)
    }
    static func texto(_ d: CGPDFDictionaryRef, _ k: String) -> String? {
        var s: CGPDFStringRef?
        guard CGPDFDictionaryGetString(d, k, &s), let s, let c = CGPDFStringCopyTextString(s) else { return nil }
        return c as String
    }
    static func inteiro(_ d: CGPDFDictionaryRef, _ k: String) -> Int? {
        var i: CGPDFInteger = 0
        return CGPDFDictionaryGetInteger(d, k, &i) ? Int(i) : nil
    }
    static func dicionario(_ d: CGPDFDictionaryRef, _ k: String) -> CGPDFDictionaryRef? {
        var r: CGPDFDictionaryRef?
        return CGPDFDictionaryGetDictionary(d, k, &r) ? r : nil
    }

    static func ler(_ url: URL) -> EstruturaDoPDF? {
        guard let doc = CGPDFDocument(url as CFURL), let catalogo = doc.catalog else { return nil }
        var e = EstruturaDoPDF()
        e.paginas = doc.numberOfPages
        var porPonteiro: [UInt: Int] = [:], porStructParents: [Int: Int] = [:]
        for i in 1...max(1, doc.numberOfPages) {
            guard let p = doc.page(at: i)?.dictionary else { continue }
            porPonteiro[unsafeBitCast(p, to: UInt.self)] = i
            if let sp = inteiro(p, "StructParents") { porStructParents[sp] = i; e.paginasComStructParents += 1 }
        }
        func pagina(_ pg: CGPDFDictionaryRef) -> Int? {
            if let i = porPonteiro[unsafeBitCast(pg, to: UInt.self)] { return i }
            if let sp = inteiro(pg, "StructParents") { return porStructParents[sp] }
            return nil
        }
        if let mi = dicionario(catalogo, "MarkInfo") {
            var b: CGPDFBoolean = 0
            if CGPDFDictionaryGetBoolean(mi, "Marked", &b) { e.marcado = b != 0 }
        }
        e.langDoCatalogo = texto(catalogo, "Lang")
        guard let raiz = dicionario(catalogo, "StructTreeRoot") else { return e }
        e.temStructTreeRoot = true
        e.temParentTree = dicionario(raiz, "ParentTree") != nil
        e.temIDTree = dicionario(raiz, "IDTree") != nil
        if let bytes = try? Data(contentsOf: url) {
            e.parentTreeNoArquivo = bytes.range(of: Data("/ParentTree".utf8)) != nil
            e.idTreeNoArquivo = bytes.range(of: Data("/IDTree".utf8)) != nil
        }
        var k: CGPDFObjectRef?
        guard CGPDFDictionaryGetObject(raiz, "K", &k), let k else { return e }
        e.temK = true

        func elemento(_ d: CGPDFDictionaryRef, herdada: Int?, prof: Int) -> ElementoDaEstrutura {
            let pg = dicionario(d, "Pg").flatMap(pagina)
            var el = ElementoDaEstrutura(tipo: nome(d, "S") ?? "?", pagina: pg, alt: texto(d, "Alt"), lang: texto(d, "Lang"))
            var kk: CGPDFObjectRef?
            if prof < 64, CGPDFDictionaryGetObject(d, "K", &kk), let kk { filhos(kk, &el, herdada: pg ?? herdada, prof: prof + 1) }
            return el
        }
        func filhos(_ o: CGPDFObjectRef, _ el: inout ElementoDaEstrutura, herdada: Int?, prof: Int) {
            switch CGPDFObjectGetType(o) {
            case .integer:
                var i: CGPDFInteger = 0
                if CGPDFObjectGetValue(o, .integer, &i) { el.conteudos.append((herdada, Int(i))) }
            case .dictionary:
                var d: CGPDFDictionaryRef?
                guard CGPDFObjectGetValue(o, .dictionary, &d), let d else { return }
                let tipo = nome(d, "Type")
                if tipo == "MCR" {
                    el.conteudos.append((dicionario(d, "Pg").flatMap(pagina) ?? herdada, inteiro(d, "MCID") ?? -1))
                } else if tipo == "OBJR" {
                    el.conteudos.append((dicionario(d, "Pg").flatMap(pagina) ?? herdada, -2))
                } else {
                    el.filhos.append(elemento(d, herdada: herdada, prof: prof))
                }
            case .array:
                var a: CGPDFArrayRef?
                guard CGPDFObjectGetValue(o, .array, &a), let a else { return }
                for j in 0..<CGPDFArrayGetCount(a) {
                    var x: CGPDFObjectRef?
                    if CGPDFArrayGetObject(a, j, &x), let x { filhos(x, &el, herdada: herdada, prof: prof) }
                }
            default: break
            }
        }
        var topo = ElementoDaEstrutura(tipo: "StructTreeRoot")
        filhos(k, &topo, herdada: nil, prof: 0)
        e.raiz = topo.filhos
        return e
    }
}
