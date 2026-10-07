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
