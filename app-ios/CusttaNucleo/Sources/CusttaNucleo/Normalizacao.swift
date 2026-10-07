import Foundation

/* Porte do dados.js: o que o app faz ao carregar o documento. Campo desconhecido é preservado;
   entrada inválida não chega à tela. Cada regra tem caso nos vetores (grupo dados.normaliza). */

/// Limites de texto da edição (LIMITES do dados.js). Contam unidades UTF-16, como o `length` do JavaScript.
public enum Limites {
    public static let nome = 120
    public static let descricao = 500
    public static let topico = 80
    public static let afazer = 500
}

let maximoDeTopicosNoOrcamento = 100

private func objeto(_ v: ValorJSON?) -> [String: ValorJSON]? { v?.comoObjeto }

/// `texto()` do dados.js: texto passa, número finito vira texto como no JavaScript, o resto vira "".
func textoDoDocumento(_ v: ValorJSON?) -> String {
    switch v {
    case .texto(let s)?: return s
    case .numero(let n)? where n.isFinite: return numeroJS(n)
    default: return ""
    }
}

/// `numero()` do dados.js: número finito, ou texto não vazio que o Number() lê como finito.
func numeroDoDocumento(_ v: ValorJSON?) -> Double? {
    switch v {
    case .numero(let n)?: return n.isFinite ? n : nil
    case .texto(let s)?:
        guard !aparadoJS(s).isEmpty else { return nil }
        let n = numeroDeTextoJS(s)
        return n.isFinite ? n : nil
    default: return nil
    }
}

/// `positivo()` do dados.js: número maior ou igual a zero.
func positivoDoDocumento(_ v: ValorJSON?) -> Double? {
    guard let n = numeroDoDocumento(v), n >= 0 else { return nil }
    return n
}

/// `data()` do dados.js: AAAA-MM-DD que existe no calendário (o ano 0000 vale aqui, ao contrário de dataISOValida).
func dataDoDocumentoValida(_ v: ValorJSON?) -> Bool {
    guard let s = v?.comoTexto, let c = componentesISO(s) else { return false }
    return (1...12).contains(c.mes) && (1...diasNoMes(ano: c.ano, mes: c.mes)).contains(c.dia)
}

func ehInteiroJS(_ n: Double) -> Bool { n.isFinite && n.rounded(.towardZero) == n }

private func lista(_ v: ValorJSON?, _ f: ([String: ValorJSON]) -> ValorJSON?) -> [ValorJSON] {
    guard let l = v?.comoLista else { return [] }
    return l.compactMap { item in item.comoObjeto.flatMap(f) }
}

private func orcamento(_ v: ValorJSON?) -> ValorJSON? {
    guard var o = objeto(v) else { return nil }
    func maior(_ x: ValorJSON?) -> Double? {
        guard let n = numeroDoDocumento(x), n > 0 else { return nil }
        return n
    }
    if o["modo"] == .texto("topicos") {
        let origem = objeto(o["topicos"]) ?? [:]
        var topicos: [String: ValorJSON] = [:]
        /* O JavaScript percorre na ordem de inserção; o Firestore do iOS não guarda ordem. Os
           vetores e qualquer orçamento feito pela tela (no máximo 71 tópicos) não dependem disso. */
        for id in ordemCanonica(Array(origem.keys)) {
            if topicos.count >= maximoDeTopicosNoOrcamento { break }
            if !aparadoJS(id).isEmpty, id.utf16.count <= Limites.topico, let valor = maior(origem[id]) {
                topicos[id] = .numero(valor)
            }
        }
        if topicos.isEmpty { return nil }
        o["modo"] = .texto("topicos")
        o["topicos"] = .objeto(topicos)
        o["total"] = nil
        return .objeto(o)
    }
    guard let total = maior(o["total"]) else { return nil }
    o["modo"] = .texto("total")
    o["total"] = .numero(total)
    o["topicos"] = nil
    return .objeto(o)
}

private func gasto(_ g: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(g["id"])
    guard !id.isEmpty, dataDoDocumentoValida(g["data"]), let valor = positivoDoDocumento(g["valor"]) else { return nil }
    var r = g
    r["id"] = .texto(id)
    r["valor"] = .numero(valor)
    let topico = textoDoDocumento(g["topico"])
    r["topico"] = .texto(topico.isEmpty ? "outros" : topico)
    r["descricao"] = .texto(textoDoDocumento(g["descricao"]))
    let pagamento = textoDoDocumento(g["pagamento"])
    r["pagamento"] = .texto(pagamento.isEmpty ? "pix" : pagamento)
    if verdadeiroJS(g["grupoId"]) || verdadeiroJS(g["parcela"]) {
        if var p = objeto(g["parcela"]), let n = numeroDoDocumento(p["n"]), let de = numeroDoDocumento(p["de"]),
           ehInteiroJS(n), ehInteiroJS(de), n > 0, de >= n {
            r["grupoId"] = .texto(textoDoDocumento(g["grupoId"]))
            p["n"] = .numero(n)
            p["de"] = .numero(de)
            r["parcela"] = .objeto(p)
        } else {
            r["grupoId"] = nil
            r["parcela"] = nil
        }
    }
    return .objeto(r)
}

private func afazer(_ a: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(a["id"])
    guard !id.isEmpty else { return nil }
    var r = a
    r["id"] = .texto(id)
    r["texto"] = .texto(textoDoDocumento(a["texto"]))
    r["feito"] = .booleano(a["feito"] == .booleano(true))
    return .objeto(r)
}

private func obra(_ o: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(o["id"])
    guard !id.isEmpty, dataDoDocumentoValida(o["dataInicio"]) else { return nil }
    var venda = ValorJSON.nulo
    if var v = objeto(o["venda"]), dataDoDocumentoValida(v["data"]), let valor = positivoDoDocumento(v["valor"]) {
        v["valor"] = .numero(valor)
        venda = .objeto(v)
    }
    var r = o
    r["id"] = .texto(id)
    let nome = textoDoDocumento(o["nome"])
    r["nome"] = .texto(nome.isEmpty ? "Obra sem nome" : nome)
    var fase = "construcao"
    if let f = o["fase"]?.comoTexto, ["construcao", "pronta", "vendida"].contains(f), f != "vendida" || venda != .nulo { fase = f }
    r["fase"] = .texto(fase)
    r["venda"] = venda
    r["valorEstimadoVenda"] = positivoDoDocumento(o["valorEstimadoVenda"]).map(ValorJSON.numero) ?? .nulo
    r["areaM2"] = positivoDoDocumento(o["areaM2"]).map(ValorJSON.numero) ?? .nulo
    r["gastos"] = .lista(lista(o["gastos"], gasto))
    r["afazeres"] = .lista(lista(o["afazeres"], afazer))
    r["orcamento"] = orcamento(o["orcamento"])
    return .objeto(r)
}

private func topicoProprio(_ t: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(t["id"]), nm = textoDoDocumento(t["nm"])
    guard !id.isEmpty, !nm.isEmpty else { return nil }
    var r = t
    r["id"] = .texto(id)
    r["nm"] = .texto(nm)
    let ic = textoDoDocumento(t["ic"])
    r["ic"] = .texto(ic.isEmpty ? "etiqueta" : ic)
    return .objeto(r)
}

/// `normaliza()` do dados.js.
public func normaliza(_ d: ValorJSON?) -> ValorJSON {
    var r = objeto(d) ?? [:]
    var config = objeto(r["config"]) ?? [:]
    r["obras"] = .lista(lista(r["obras"], obra))
    let taxa = numeroDoDocumento(config["taxaMensal"])
    config["taxaMensal"] = .numero(taxa.map { $0 > 0 && $0 <= 20 ? $0 : 1 } ?? 1)
    config["topicosCustom"] = .lista(lista(config["topicosCustom"], topicoProprio))
    r["config"] = .objeto(config)
    return .objeto(r)
}
