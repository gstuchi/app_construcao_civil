#if DEBUG
import Foundation
import CusttaNucleo

/* A obra do mockup aprovado da etapa 2 (parte1.html, de 12/10/2026): a Casa Alphaville com os 46 lançamentos, contados em
   dias a partir de hoje para a tela mostrar os números do mockup em qualquer dia: R$ 842.317,45 gastos, R$ 926.847,69
   corrigido, 3 vencimentos em 30 dias (R$ 13.250,00), 13 gastos a vencer e as compras no cartão em 10x, 6x e 3x. */
extension DadosDeExemplo {
    typealias GastoDaVitrine = (id: String, dias: Int, valor: Double, topico: String, descricao: String, pagamento: String,
                                parcela: (n: Int, de: Int, grupo: String)?)

    static let gastosDaCasaAlphaville: [GastoDaVitrine] = [
        ("g001", -424, 199847.85, "terreno", "Entrada do terreno", "pix", nil),
        ("g002", -418, 18500, "projeto", "Projeto arquitetônico", "pix", nil),
        ("g003", -410, 4380.5, "projeto", "Taxas e alvará da prefeitura", "pix", nil),
        ("g004", -397, 120000, "terreno", "Parcela final do terreno", "pix", nil),
        ("g005", -389, 9800, "maoobra", "Limpeza e terraplanagem", "pix", nil),
        ("g006", -371, 64200, "fundacao", "Sapatas e baldrames", "pix", nil),
        ("g007", -355, 21450.8, "ferragem", "Vergalhão 10 mm e estribos", "pix", nil),
        ("g008", -334, 14320, "matbasicos", "Cimento, areia e brita", "pix", nil),
        ("g009", -319, 12600, "maoobra", "Quinzena da equipe da fundação", "pix", nil),
        ("g010", -307, 38900, "estrutura", "Concreto usinado da laje do térreo", "pix", nil),
        ("g011", -297, 17240.6, "ferragem", "Ferragem da laje", "pix", nil),
        ("g012", -271, 11870, "alvenaria", "Tijolos cerâmicos de 8 furos", "pix", nil),
        ("g013", -255, 16400, "maoobra", "Pedreiro e ajudantes", "pix", nil),
        ("g014", -238, 52300, "estrutura", "Pilares e vigas do pavimento superior", "pix", nil),
        ("g015", -215, 27650, "telhado", "Madeiramento do telhado", "pix", nil),
        ("g016", -201, 18420.3, "telhado", "Telhas de cerâmica", "pix", nil),
        ("g017", -187, 6890.4, "eletrica", "Eletrodutos e caixas", "pix", nil),
        ("g018", -171, 9740, "hidraulica", "Tubulação de água e esgoto", "pix", nil),
        ("g019", -152, 13200, "maoobra", "Eletricista e encanador", "pix", nil),
        ("g020", -136, 8350.9, "matbasicos", "Argamassa e reboco", "pix", nil),
        ("g021", -124, 15200, "revest", "Contrapiso e regularização", "pix", nil),
        ("g028", -99, 6150, "revest", "Porcelanato 60×60", "cartao", (1, 10, "vpor")),
        ("g022", -83, 11480.2, "eletrica", "Fios, cabos e quadro de luz", "pix", nil),
        ("g029", -68, 6150, "revest", "Porcelanato 60×60", "cartao", (2, 10, "vpor")),
        ("g023", -55, 8400, "maoobra", "Quinzena do pedreiro", "pix", nil),
        ("g030", -37, 6150, "revest", "Porcelanato 60×60", "cartao", (3, 10, "vpor")),
        ("g038", -27, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (1, 6, "vjan")),
        ("g024", -18, 7320.5, "hidraulica", "Louças e metais", "pix", nil),
        ("g025", -10, 3275.4, "eletrica", "Luminárias e tomadas", "pix", nil),
        ("g031", -7, 6150, "revest", "Porcelanato 60×60", "cartao", (4, 10, "vpor")),
        ("g044", -6, 2300, "pintura", "Tinta acrílica", "cartao", (1, 3, "vtin")),
        ("g026", -4, 8400, "maoobra", "Quinzena do pedreiro", "pix", nil),
        ("g027", -2, 4980, "matbasicos", "Cimento CP-II, 120 sacos", "pix", nil),
        ("g039", 3, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (2, 6, "vjan")),
        ("g032", 24, 6150, "revest", "Porcelanato 60×60", "cartao", (5, 10, "vpor")),
        ("g045", 25, 2300, "pintura", "Tinta acrílica", "cartao", (2, 3, "vtin")),
        ("g040", 34, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (3, 6, "vjan")),
        ("g033", 54, 6150, "revest", "Porcelanato 60×60", "cartao", (6, 10, "vpor")),
        ("g046", 55, 2300, "pintura", "Tinta acrílica", "cartao", (3, 3, "vtin")),
        ("g041", 64, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (4, 6, "vjan")),
        ("g034", 85, 6150, "revest", "Porcelanato 60×60", "cartao", (7, 10, "vpor")),
        ("g042", 95, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (5, 6, "vjan")),
        ("g035", 116, 6150, "revest", "Porcelanato 60×60", "cartao", (8, 10, "vpor")),
        ("g043", 126, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (6, 6, "vjan")),
        ("g036", 144, 6150, "revest", "Porcelanato 60×60", "cartao", (9, 10, "vpor")),
        ("g037", 175, 6150, "revest", "Porcelanato 60×60", "cartao", (10, 10, "vpor")),    ]

    /// Os gastos da Casa Alphaville do mockup, com as datas contadas de hoje; as parcelas com o grupo e as condições da
    /// compra (sem juros), como o site grava.
    static func gastosDaVitrine(hoje: Date) -> ValorJSON {
        let calendario = Calendar(identifier: .gregorian)
        let compras = Dictionary(grouping: gastosDaCasaAlphaville.filter { $0.parcela != nil }) { $0.parcela!.grupo }
        return .lista(gastosDaCasaAlphaville.map { g in
            var campos: [String: ValorJSON] = [
                "id": .texto(g.id), "valor": .numero(g.valor), "topico": .texto(g.topico), "descricao": .texto(g.descricao),
                "data": .texto(dataLocalISO(calendario.date(byAdding: .day, value: g.dias, to: hoje) ?? hoje, fuso: .current)),
                "pagamento": .texto(g.pagamento),
            ]
            if let p = g.parcela {
                let total = (compras[p.grupo] ?? []).reduce(0) { $0 + $1.valor }
                campos["grupoId"] = .texto(p.grupo)
                campos["parcela"] = .objeto(["n": .numero(Double(p.n)), "de": .numero(Double(p.de))])
                campos["jurosCartao"] = .objeto(["taxaMensal": .numero(0), "valorCompra": .numero(total), "nParcelas": .numero(Double(p.de)),
                                                 "totalCompra": .numero(total), "jurosCompra": .numero(0)])
            }
            return .objeto(campos)
        })
    }

    /// Os afazeres da Casa Alphaville do mockup da etapa 3 (parte 2, seção 4): 3 pendentes (um de 213 caracteres, que se lê
    /// inteiro na tela Afazeres) e 4 feitos, na ordem do array.
    static let afazeresDaVitrine: ValorJSON = .lista([
        afazer("a1", "Pagar a quinzena do pedreiro na sexta", feito: false),
        afazer("a2", "Ligar para o vidraceiro e confirmar a medida das janelas da sala, do quarto do casal e do banheiro social "
               + "antes de sexta. Ele pediu as medidas por escrito, com a altura do peitoril e o lado de abrir de cada folha.",
               feito: false),
        afazer("a3", "Comprar 10 sacos de argamassa para o banheiro", feito: false),
        afazer("a4", "Agendar a entrega do porcelanato", feito: true),
        afazer("a5", "Buscar a tinta na loja", feito: true),
        afazer("a6", "Mandar o projeto elétrico para a concessionária", feito: true),
        afazer("a7", "Trocar o cadeado do portão", feito: true),
    ])

    /// Um afazer como o site grava.
    static func afazer(_ id: String, _ texto: String, feito: Bool) -> ValorJSON {
        .objeto(["id": .texto(id), "texto": .texto(texto), "feito": .booleano(feito)])
    }
}

extension DadosDeExemplo {
    /// A vitrine com a Casa Tamboré 4 vendida com prejuízo (R$ 800 mil por R$ 976 mil gastos): a nota do prejuízo no laudo.
    static func vitrineComPrejuizo() -> ValorJSON {
        guard case .objeto(var raiz) = vitrine(), case .lista(var obras) = raiz["obras"], case .objeto(var tambore) = obras[2],
              case .objeto(var venda) = tambore["venda"] else { return vitrine() }
        venda["valor"] = .numero(800_000)
        tambore["venda"] = .objeto(venda)
        obras[2] = .objeto(tambore)
        raiz["obras"] = .lista(obras)
        return .objeto(raiz)
    }

    /// A vitrine com um vencimento à vista no A pagar (`CUSTTA_DADOS=avista`): a caçamba de entulho no Pix, agendada para
    /// daqui a 2 dias, antes das três parcelas do mockup. O apagar à vista de dentro da folha do A pagar ("Apagar este
    /// gasto?", com o nome e o valor).
    static func vitrineComVencimentoAVista(hoje: Date = .now) -> ValorJSON {
        guard case .objeto(var raiz) = vitrine(hoje: hoje), case .lista(var obras) = raiz["obras"], case .objeto(var alphaville) = obras[0],
              case .lista(var gastos) = alphaville["gastos"] else { return vitrine(hoje: hoje) }
        let dia = Calendar(identifier: .gregorian).date(byAdding: .day, value: 2, to: hoje) ?? hoje
        gastos.append(.objeto(["id": .texto("g047"), "valor": .numero(650), "topico": .texto("outros"), "descricao": .texto("Caçamba de entulho"),
                               "data": .texto(dataLocalISO(dia, fuso: .current)), "pagamento": .texto("pix")]))
        alphaville["gastos"] = .lista(gastos)
        obras[0] = .objeto(alphaville)
        raiz["obras"] = .lista(obras)
        return .objeto(raiz)
    }

    /// O teto das rules: 300 obras ("Obra 1" a "Obra 300"), para o aviso de "Nova obra".
    static func noTeto() -> ValorJSON {
        .objeto([
            "obras": .lista((1...limiteDeObras).map { i in
                .objeto(["id": .texto("t\(i)"), "nome": .texto("Obra \(i)"), "dataInicio": .texto("2026-01-01"), "fase": .texto("construcao"),
                         "gastos": .lista([])])
            }),
            "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
        ])
    }
}
#endif
