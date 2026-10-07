import Foundation

public struct ItemAPagar: Equatable, Sendable {
    public let obraId: String
    public let gasto: Gasto
}

public struct APagar: Equatable, Sendable {
    public let total: Double
    public let qtd: Int
    public let itens: [ItemAPagar]
}

/// `aPagar` do calc.js: gastos com data depois de hoje e até hoje + `dias`, por data.
public func aPagar(_ obras: [Obra], hoje: String, dias: Int = 30) -> APagar {
    let limite = somarDias(hoje, dias)
    var total = 0.0, qtd = 0
    var itens: [ItemAPagar] = []
    for o in obras {
        for g in o.gastos where menorJS(hoje, g.data) && !menorJS(limite, g.data) {
            total += g.valor
            qtd += 1
            itens.append(ItemAPagar(obraId: o.id, gasto: g))
        }
    }
    return APagar(total: total, qtd: qtd, itens: ordenadoEstavel(itens) { menorJS($0.gasto.data, $1.gasto.data) })
}

public struct GastoRecente: Equatable, Sendable {
    public let obraId: String
    public let obraNome: String
    public let gasto: Gasto
}

/// `gastosRecentes` do calc.js: os n mais recentes de todas as obras, por data e depois id, decrescente.
/// O site compara com localeCompare; para datas e ids em base 36 dá a mesma ordem que a comparação de código.
public func gastosRecentes(_ obras: [Obra], n: Int = 5) -> [GastoRecente] {
    let todos = obras.flatMap { o in o.gastos.map { GastoRecente(obraId: o.id, obraNome: o.nome, gasto: $0) } }
    let ordenados = ordenadoEstavel(todos) { menorJS($1.gasto.data + $1.gasto.id, $0.gasto.data + $0.gasto.id) }
    // slice(0, n) do JavaScript: n negativo conta do fim.
    let fim = n >= 0 ? min(n, ordenados.count) : max(ordenados.count + n, 0)
    return Array(ordenados[..<fim])
}

/// `semAcento` do calc.js: minúsculas, sem os acentos combinantes (U+0300 a U+036F).
public func semAcento(_ s: String?) -> String {
    let decomposto = (s ?? "").lowercased().decomposedStringWithCanonicalMapping
    var r = String.UnicodeScalarView()
    r.append(contentsOf: decomposto.unicodeScalars.filter { !(0x300...0x36F).contains($0.value) })
    return String(r)
}

/// O `includes` do JavaScript: contém a sequência de caracteres (escalares Unicode).
func contem(_ texto: String, _ trecho: String) -> Bool {
    if trecho.isEmpty { return true }
    let a = Array(texto.unicodeScalars), b = Array(trecho.unicodeScalars)
    guard b.count <= a.count else { return false }
    for i in 0...(a.count - b.count) where a[i] == b[0] && Array(a[i..<(i + b.count)]) == b { return true }
    return false
}

public struct FiltroGastos: Equatable, Sendable {
    public var texto: String?
    public var mes: String?
    public init(texto: String? = nil, mes: String? = nil) { self.texto = texto; self.mes = mes }
}

/// `filtraGastos` do calc.js: texto na descrição ou no nome do tópico (sem acento) e mês AAAA-MM, em E.
public func filtraGastos(_ gastos: [Gasto], topicos: [String: Topico], filtro: FiltroGastos?) -> [Gasto] {
    let texto = semAcento(filtro?.texto)
    let mes = filtro?.mes ?? ""
    return gastos.filter { g in
        if !mes.isEmpty && String(g.data.prefix(7)) != mes { return false }
        if texto.isEmpty { return true }
        return contem(semAcento(g.descricao), texto) || contem(semAcento(topicos[g.topico]?.nome ?? g.topico), texto)
    }
}
