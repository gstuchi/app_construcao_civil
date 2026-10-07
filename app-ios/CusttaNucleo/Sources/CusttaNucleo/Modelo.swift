import Foundation

/* Tipos do estado do Custta, escritos por cima da árvore original do documento. Cada tipo
   guarda os campos como vieram (`campos`) e lê ou grava neles: campo desconhecido não some.
   Os inicializadores esperam a árvore já normalizada (normaliza(_:)), que sempre traz
   `gastos` e `afazeres` nas obras e `topicosCustom` na configuração. */

public enum Fase: String, Sendable, CaseIterable {
    case construcao, pronta, vendida
}

public struct Venda: Equatable, Sendable {
    public var valor: Double
    public var data: String
    public init(valor: Double, data: String) { self.valor = valor; self.data = data }
}

public struct Parcela: Equatable, Sendable {
    public var n: Int
    public var de: Int
    public init(n: Int, de: Int) { self.n = n; self.de = de }
}

public struct Gasto: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var valor: Double {
        get { campos["valor"]?.comoNumero ?? 0 }
        set { campos["valor"] = .numero(newValue) }
    }
    public var topico: String {
        get { campos["topico"]?.comoTexto ?? "" }
        set { campos["topico"] = .texto(newValue) }
    }
    public var descricao: String {
        get { campos["descricao"]?.comoTexto ?? "" }
        set { campos["descricao"] = .texto(newValue) }
    }
    public var data: String {
        get { campos["data"]?.comoTexto ?? "" }
        set { campos["data"] = .texto(newValue) }
    }
    /// "pix" ou "cartao" no que o site grava; texto livre se vier outra coisa.
    public var pagamento: String {
        get { campos["pagamento"]?.comoTexto ?? "" }
        set { campos["pagamento"] = .texto(newValue) }
    }
    /// Compra parcelada: o mesmo grupoId nos irmãos. Texto vazio conta como sem grupo, como no
    /// JavaScript (o dados.js pode gravar `grupoId: ''` e o site trata como falso).
    public var grupoId: String? {
        get { campos["grupoId"]?.comoTexto.flatMap { $0.isEmpty ? nil : $0 } }
        set { campos["grupoId"] = newValue.map(ValorJSON.texto) }
    }
    /// Escrever mantém os campos desconhecidos de dentro da parcela.
    public var parcela: Parcela? {
        get {
            guard let p = campos["parcela"]?.comoObjeto, let n = p["n"]?.comoNumero, let de = p["de"]?.comoNumero,
                  let ni = Int(exactly: n), let dei = Int(exactly: de) else { return nil }
            return Parcela(n: ni, de: dei)
        }
        set {
            guard let nova = newValue else { campos["parcela"] = nil; return }
            var p = campos["parcela"]?.comoObjeto ?? [:]
            p["n"] = .numero(Double(nova.n))
            p["de"] = .numero(Double(nova.de))
            campos["parcela"] = .objeto(p)
        }
    }
}

public struct Afazer: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var texto: String {
        get { campos["texto"]?.comoTexto ?? "" }
        set { campos["texto"] = .texto(newValue) }
    }
    public var feito: Bool {
        get { campos["feito"]?.comoBooleano ?? false }
        set { campos["feito"] = .booleano(newValue) }
    }
}

public struct Obra: Equatable, Sendable {
    /// Campos da obra menos `gastos` e `afazeres`, que moram nas listas tipadas.
    public var campos: [String: ValorJSON]
    public var gastos: [Gasto]
    public var afazeres: [Afazer]

    public init(arvore: [String: ValorJSON]) {
        var c = arvore
        gastos = (c.removeValue(forKey: "gastos")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Gasto.init(campos:)) }
        afazeres = (c.removeValue(forKey: "afazeres")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Afazer.init(campos:)) }
        campos = c
    }

    /// A obra inteira de volta, para gravar.
    public var arvore: [String: ValorJSON] {
        var c = campos
        c["gastos"] = .lista(gastos.map { .objeto($0.campos) })
        c["afazeres"] = .lista(afazeres.map { .objeto($0.campos) })
        return c
    }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var nome: String {
        get { campos["nome"]?.comoTexto ?? "" }
        set { campos["nome"] = .texto(newValue) }
    }
    public var dataInicio: String {
        get { campos["dataInicio"]?.comoTexto ?? "" }
        set { campos["dataInicio"] = .texto(newValue) }
    }
    public var fase: Fase {
        get { campos["fase"]?.comoTexto.flatMap(Fase.init(rawValue:)) ?? .construcao }
        set { campos["fase"] = .texto(newValue.rawValue) }
    }
    /// Escrever mantém os campos desconhecidos de dentro da venda; nil grava `venda: null`, como o site.
    public var venda: Venda? {
        get {
            guard let v = campos["venda"]?.comoObjeto, let valor = v["valor"]?.comoNumero, let data = v["data"]?.comoTexto else { return nil }
            return Venda(valor: valor, data: data)
        }
        set {
            guard let nova = newValue else { campos["venda"] = .nulo; return }
            var v = campos["venda"]?.comoObjeto ?? [:]
            v["valor"] = .numero(nova.valor)
            v["data"] = .texto(nova.data)
            campos["venda"] = .objeto(v)
        }
    }
    public var valorEstimadoVenda: Double? {
        get { campos["valorEstimadoVenda"]?.comoNumero }
        set { campos["valorEstimadoVenda"] = newValue.map(ValorJSON.numero) ?? .nulo }
    }
    public var areaM2: Double? {
        get { campos["areaM2"]?.comoNumero }
        set { campos["areaM2"] = newValue.map(ValorJSON.numero) ?? .nulo }
    }
    /// O orçamento como está no documento; quem lê é orcamentoObra(_:).
    public var orcamento: ValorJSON? {
        get { campos["orcamento"] }
        set { campos["orcamento"] = newValue }
    }
}

public struct TopicoProprio: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    /// Campo `nm` do documento.
    public var nome: String {
        get { campos["nm"]?.comoTexto ?? "" }
        set { campos["nm"] = .texto(newValue) }
    }
    /// Campo `ic` do documento.
    public var icone: String {
        get { campos["ic"]?.comoTexto ?? "" }
        set { campos["ic"] = .texto(newValue) }
    }
}

public struct Configuracao: Equatable, Sendable {
    /// Campos da configuração menos `topicosCustom`.
    public var campos: [String: ValorJSON]
    public var topicosProprios: [TopicoProprio]

    public init(arvore: [String: ValorJSON]) {
        var c = arvore
        topicosProprios = (c.removeValue(forKey: "topicosCustom")?.comoLista ?? []).compactMap { $0.comoObjeto.map(TopicoProprio.init(campos:)) }
        campos = c
    }

    public var arvore: [String: ValorJSON] {
        var c = campos
        c["topicosCustom"] = .lista(topicosProprios.map { .objeto($0.campos) })
        return c
    }

    public var taxaMensal: Double {
        get { campos["taxaMensal"]?.comoNumero ?? 1 }
        set { campos["taxaMensal"] = .numero(newValue) }
    }
}

/// O documento `dados/{uid}` inteiro, normalizado: o `db` do site.
public struct Estado: Equatable, Sendable {
    /// Chaves de topo menos `obras` e `config`.
    public var campos: [String: ValorJSON]
    public var obras: [Obra]
    public var config: Configuracao

    /// Espera a saída de normaliza(_:).
    public init(normalizado: ValorJSON) {
        var c = normalizado.comoObjeto ?? [:]
        obras = (c.removeValue(forKey: "obras")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Obra.init(arvore:)) }
        config = Configuracao(arvore: c.removeValue(forKey: "config")?.comoObjeto ?? [:])
        campos = c
    }

    /// Normaliza o que veio do banco (ou nada) e monta o estado.
    public static func de(_ bruto: ValorJSON?) -> Estado { Estado(normalizado: normaliza(bruto)) }

    /// `{obras: [], config: {taxaMensal: 1, topicosCustom: []}}`, o blob vazio do site.
    public static var vazio: Estado { .de(nil) }

    /// O documento inteiro de volta, para gravar.
    public var arvore: ValorJSON {
        var c = campos
        c["obras"] = .lista(obras.map { .objeto($0.arvore) })
        c["config"] = .objeto(config.arvore)
        return .objeto(c)
    }
}
