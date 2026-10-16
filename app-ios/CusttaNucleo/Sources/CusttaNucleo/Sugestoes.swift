import Foundation

/* A descrição do gasto como o formulário do site a trata (calc.js): as sugestões de descrição, o aviso de
   gasto repetido e a leitura da taxa de juros do cartão. Cada regra tem caso nos vetores. */

/// `normalizaDescricao` do calc.js: sem acento, em minúsculas, aparada e com os espaços do meio juntados.
public func normalizaDescricao(_ s: String?) -> String {
    var r = String.UnicodeScalarView()
    var emEspaco = false
    for u in aparadoJS(semAcento(s)).unicodeScalars {
        if ehEspacoJS(u) {
            if !emEspaco { r.append(" ") }
            emEspaco = true
        } else {
            r.append(u)
            emEspaco = false
        }
    }
    return String(r)
}

/// `distanciaEdicao` do calc.js: Levenshtein em unidades UTF-16, como o índice das strings do JavaScript.
public func distanciaEdicao(_ a: String, _ b: String) -> Int {
    let x = Array(a.utf16), y = Array(b.utf16)
    if x == y { return 0 }
    if x.isEmpty { return y.count }
    if y.isEmpty { return x.count }
    var anterior = Array(0...y.count)
    for i in 1...x.count {
        var atual = [i]
        for j in 1...y.count {
            atual.append(min(atual[j - 1] + 1, anterior[j] + 1, anterior[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1)))
        }
        anterior = atual
    }
    return anterior[y.count]
}

/// O `localeCompare(b, 'pt-BR')` do site: a comparação do iOS com a localidade pt_BR (o mesmo ICU no fundo) e, no
/// empate de formas que ele junta (ligadura "ﬁ" e "fi", "º" e "o"), a ordem das unidades UTF-16, que é a do V8.
func ordemPtBR(_ a: String, _ b: String) -> ComparisonResult {
    let r = a.compare(b, locale: Locale(identifier: "pt_BR"))
    if r != .orderedSame || a == b { return r }
    return menorJS(a, b) ? .orderedAscending : menorJS(b, a) ? .orderedDescending : .orderedSame
}

/// Uma sugestão de descrição: o texto do lançamento mais recente com essa descrição e de onde ela vem.
public struct SugestaoDeDescricao: Equatable, Sendable {
    public let texto: String
    public let chave: String
    public let vezes: Int
    public let mesmaObra: Bool
    public let mesmoTopico: Bool
    public let ultima: String

    /// O que o formulário mostra ao lado: "mesmo tópico" ou "N× usado".
    public var contexto: String { mesmoTopico ? "mesmo tópico" : "\(vezes)× usado" }

    var peso: Int { (mesmoTopico ? 100 : 0) + (mesmaObra ? 40 : 0) + min(vezes, 10) }
}

/// `sugestoesDescricao` do calc.js: as descrições já lançadas em todas as obras, sem repetir, que contêm o termo ou, com
/// 4 letras ou mais, ficam a até 2 edições dele. Pesam o mesmo tópico, a mesma obra, o começo igual e o uso; até 5.
/// `ignorarId` tira o gasto em edição (só na obra dele).
public func sugestoesDescricao(_ obras: [Obra], obraId: String, topicoId: String, termo: String,
                               ignorarId: String?) -> [SugestaoDeDescricao] {
    let busca = normalizaDescricao(termo)
    if busca.isEmpty { return [] }
    var ordem: [String] = []
    var itens: [String: SugestaoDeDescricao] = [:]
    for o in obras {
        for g in o.gastos {
            if o.id == obraId && g.id == ignorarId { continue }
            let texto = aparadoJS(g.descricao), chave = normalizaDescricao(texto)
            if chave.isEmpty { continue }
            let anterior = itens[chave]
            if anterior == nil { ordem.append(chave) }
            let base = anterior ?? SugestaoDeDescricao(texto: texto, chave: chave, vezes: 0, mesmaObra: false, mesmoTopico: false, ultima: "")
            let maisNova = !menorJS(g.data, base.ultima)
            itens[chave] = SugestaoDeDescricao(texto: maisNova ? texto : base.texto, chave: chave, vezes: base.vezes + 1,
                                               mesmaObra: base.mesmaObra || o.id == obraId,
                                               mesmoTopico: base.mesmoTopico || g.topico == topicoId,
                                               ultima: maisNova ? g.data : base.ultima)
        }
    }
    let tamanho = busca.utf16.count
    let candidatas = ordem.compactMap { itens[$0] }.filter { x in
        contem(x.chave, busca)
            || (tamanho >= 4 && abs(x.chave.utf16.count - tamanho) <= 2 && distanciaEdicao(x.chave, busca) <= 2)
    }
    func peso(_ x: SugestaoDeDescricao) -> Int { x.peso + (x.chave.utf16.starts(with: busca.utf16) ? 25 : 0) }
    let ordenadas = ordenadoEstavel(candidatas) { a, b in
        let pa = peso(a), pb = peso(b)
        if pa != pb { return pa > pb }
        if a.ultima != b.ultima { return menorJS(b.ultima, a.ultima) }
        return ordemPtBR(a.texto, b.texto) == .orderedAscending
    }
    return Array(ordenadas.prefix(5))
}

/// `gastoRepetido` do calc.js: mesma descrição comparável, mesmo valor em centavos e mesma data de um gasto da obra.
/// Sem descrição nunca parece repetido; `ignorarId` tira o gasto em edição.
public func gastoRepetido(_ obra: Obra, descricao: String, valor: Double, data: String, ignorarId: String?) -> Bool {
    if descricao.isEmpty { return false }
    let chave = normalizaDescricao(descricao), centavos = arredondarJS(valor * 100)
    return obra.gastos.contains { x in
        x.id != ignorarId && normalizaDescricao(x.descricao) == chave && arredondarJS(x.valor * 100) == centavos && x.data == data
    }
}

/// `lerTaxaCartao` do calc.js: dígitos com vírgula ou ponto decimal, sem sinal (o `\d` do JavaScript é só o ASCII);
/// o resto é NaN.
public func lerTaxaCartao(_ texto: String?) -> Double {
    let t = Array(aparadoJS(texto ?? "").unicodeScalars)
    let separadores = t.indices.filter { t[$0] == "," || t[$0] == "." }
    guard !t.isEmpty, separadores.count <= 1, t.allSatisfy({ ehDigito($0) || $0 == "," || $0 == "." }) else { return .nan }
    if let s = separadores.first, s == t.count - 1 { return .nan }        // "5," e "5." não valem
    var r = String.UnicodeScalarView()
    r.append(contentsOf: t.map { $0 == "," ? "." : $0 })
    return Double(String(r)) ?? .nan
}

/// As descrições já lançadas, prontas para as sugestões do formulário: monta uma vez ao abrir a folha e responde a cada
/// letra sem passar por todos os gastos de novo. O resultado é o de `sugestoesDescricao` (o do site); os testes conferem
/// os dois em todos os casos dos vetores.
public struct IndiceDeSugestoes: Sendable {
    struct Entrada: Sendable {
        let texto: String
        let chave: String
        let vezes: Int
        let naObra: Bool
        let topicos: Set<String>
        let ultima: String
    }
    private let entradas: [Entrada]

    /// `obraId`: a obra do gasto (pesa "mesma obra" e é onde o `ignorarId`, o gasto em edição, sai).
    public init(_ obras: [Obra], obraId: String, ignorarId: String?) {
        var ordem: [String] = []
        var itens: [String: (texto: String, vezes: Int, naObra: Bool, topicos: Set<String>, ultima: String)] = [:]
        for o in obras {
            for g in o.gastos {
                if o.id == obraId && g.id == ignorarId { continue }
                let texto = aparadoJS(g.descricao), chave = normalizaDescricao(texto)
                if chave.isEmpty { continue }
                var item = itens[chave] ?? (texto, 0, false, [], "")
                if itens[chave] == nil { ordem.append(chave) }
                item.vezes += 1
                if o.id == obraId { item.naObra = true }
                item.topicos.insert(g.topico)
                if !menorJS(g.data, item.ultima) { item.ultima = g.data; item.texto = texto }
                itens[chave] = item
            }
        }
        entradas = ordem.compactMap { chave in
            itens[chave].map { Entrada(texto: $0.texto, chave: chave, vezes: $0.vezes, naObra: $0.naObra, topicos: $0.topicos, ultima: $0.ultima) }
        }
    }

    public func sugestoes(topicoId: String, termo: String) -> [SugestaoDeDescricao] {
        let busca = normalizaDescricao(termo)
        if busca.isEmpty { return [] }
        let tamanho = busca.utf16.count
        let candidatas = entradas.filter { x in
            contem(x.chave, busca)
                || (tamanho >= 4 && abs(x.chave.utf16.count - tamanho) <= 2 && distanciaEdicao(x.chave, busca) <= 2)
        }.map { x in
            SugestaoDeDescricao(texto: x.texto, chave: x.chave, vezes: x.vezes, mesmaObra: x.naObra,
                                mesmoTopico: x.topicos.contains(topicoId), ultima: x.ultima)
        }
        func peso(_ x: SugestaoDeDescricao) -> Int { x.peso + (x.chave.utf16.starts(with: busca.utf16) ? 25 : 0) }
        let ordenadas = ordenadoEstavel(candidatas) { a, b in
            let pa = peso(a), pb = peso(b)
            if pa != pb { return pa > pb }
            if a.ultima != b.ultima { return menorJS(b.ultima, a.ultima) }
            return ordemPtBR(a.texto, b.texto) == .orderedAscending
        }
        return Array(ordenadas.prefix(5))
    }
}
