/// Tópico de gasto com o nome e o ícone que a tela mostra (campos `id`, `nm` e `ic` do site).
public struct Topico: Equatable, Hashable, Sendable {
    public let id: String
    public let nome: String
    public let icone: String
    public init(id: String, nome: String, icone: String) { self.id = id; self.nome = nome; self.icone = icone }
}

/// Os 21 tópicos fixos, na ordem do TOPICOS do calc.js.
public let topicosPadrao: [Topico] = [
    Topico(id: "terreno", nome: "Terreno", icone: "mapa"),
    Topico(id: "projeto", nome: "Documentação", icone: "documento"),
    Topico(id: "matbasicos", nome: "Materiais básicos", icone: "tijolos"),
    Topico(id: "fundacao", nome: "Fundação", icone: "pa"),
    Topico(id: "ferragem", nome: "Ferragem", icone: "vergalhao"),
    Topico(id: "estrutura", nome: "Estrutura", icone: "guindaste"),
    Topico(id: "alvenaria", nome: "Alvenaria", icone: "tijolos"),
    Topico(id: "telhado", nome: "Telhado", icone: "casa"),
    Topico(id: "eletrica", nome: "Elétrica", icone: "raio"),
    Topico(id: "hidraulica", nome: "Encanamento", icone: "gota"),
    Topico(id: "esquadrias", nome: "Esq. de alumínio", icone: "porta"),
    Topico(id: "revest", nome: "Cerâmica", icone: "ladrilho"),
    Topico(id: "pintura", nome: "Pintura", icone: "rolo"),
    Topico(id: "acabamento", nome: "Acabamento", icone: "rolo"),
    Topico(id: "piscina", nome: "Piscina", icone: "piscina"),
    Topico(id: "paisagismo", nome: "Jardim", icone: "arvore"),
    Topico(id: "maoobra", nome: "Mão de obra", icone: "capacete"),
    Topico(id: "aluguelmaq", nome: "Aluguel de máquina", icone: "engrenagem"),
    Topico(id: "matextra", nome: "Materiais extra", icone: "caixa"),
    Topico(id: "extras", nome: "Extras", icone: "mais"),
    Topico(id: "outros", nome: "Outros", icone: "caixa"),
]

/// O TOP_MAP do app.js: padrões e próprios por id; o próprio vence o padrão de mesmo id.
public func mapaDeTopicos(_ proprios: [TopicoProprio]) -> [String: Topico] {
    var mapa: [String: Topico] = [:]
    for t in topicosPadrao { mapa[t.id] = t }
    for t in proprios { mapa[t.id] = Topico(id: t.id, nome: t.nome, icone: t.icone) }
    return mapa
}

/// Os tópicos na ordem do formulário do site: os 21 fixos e depois os próprios (o `topicos()` do app.js).
public func topicosDoFormulario(_ proprios: [TopicoProprio]) -> [Topico] {
    let mapa = mapaDeTopicos(proprios)
    var vistos = Set<String>()
    return (topicosPadrao.map(\.id) + proprios.map(\.id)).compactMap { id in
        guard vistos.insert(id).inserted else { return nil }
        return mapa[id]
    }
}

/// "Usados nesta obra" (regra do app, aprovada no mockup da etapa 2): os três tópicos com mais gastos na obra; no empate,
/// o do gasto mais recente (data e id, a ordem da lista). Só tópicos que existem na lista.
public func usadosNestaObra(_ obra: Obra, topicos: [Topico]) -> [Topico] {
    let existentes = Dictionary(topicos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    var contagem: [String: (vezes: Int, ultimo: String)] = [:]
    for g in obra.gastos where existentes[g.topico] != nil {
        let chave = g.data + g.id
        let atual = contagem[g.topico] ?? (0, "")
        contagem[g.topico] = (atual.vezes + 1, menorJS(atual.ultimo, chave) ? chave : atual.ultimo)
    }
    let ordem = contagem.sorted { a, b in
        a.value.vezes != b.value.vezes ? a.value.vezes > b.value.vezes : menorJS(b.value.ultimo, a.value.ultimo)
    }
    return ordem.prefix(3).compactMap { existentes[$0.key] }
}

/// O tópico com que um gasto novo começa (regra do app, aprovada no mockup): o do último gasto lançado na obra (o site
/// põe o gasto novo no fim da lista); obra sem gasto, ou tópico que não existe mais, começa no primeiro, como no site.
public func topicoInicial(_ obra: Obra, topicos: [Topico]) -> String {
    if let ultimo = obra.gastos.last?.topico, topicos.contains(where: { $0.id == ultimo }) { return ultimo }
    return topicos.first?.id ?? "terreno"
}
