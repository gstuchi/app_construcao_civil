import Testing
@testable import CusttaNucleo

/* A paginação da tabela do PDF (conta pura, sem UIKit): as colunas pelo maior valor, a quebra de página, o "(continuação)",
   a descrição maior que uma página, o fim inteiro e o "página N de M". O motor do desenho é falso aqui: 40 caracteres por
   linha de 11,34 pt, a medida do protótipo para a letra de 9,5 pt na coluna da descrição. */
struct PaginacaoDoPDFTests {
    static let linha = 11.34

    func medido(_ texto: String) -> GastoMedidoDoPDF {
        GastoMedidoDoPDF(linhas: Array(repeating: Self.linha, count: max(1, (texto.count + 39) / 40)))
    }

    func linhas(_ n: Int, de altura: Double = Self.linha) -> GastoMedidoDoPDF { GastoMedidoDoPDF(linhas: Array(repeating: altura, count: n)) }

    /// Páginas de 200 pt de tabela, sem cabeçalhos, com linhas de 20 pt: as contas do limite ficam inteiras.
    var redondas: MedidasDoPDF {
        var m = MedidasDoPDF()
        m.altura = 200; m.margemDeCima = 0; m.margemDeBaixo = 0; m.cabecalho = 0; m.subtitulo = 0; m.cabecalhoDaTabela = 0
        m.linhaDoTopico = 20; m.linhaMinimaDoGasto = 20; m.respiroDoGasto = 0; m.linhaDoTotal = 20; m.linhaDaVenda = 20; m.avisoSemVenda = 0
        return m
    }

    /// Confere o que vale para toda paginação: nenhuma página fica vazia nem passa do espaço; o usado é a soma das linhas; os
    /// gastos aparecem todos, na ordem, com as linhas do texto inteiras e sem repetir; a página que continua um tópico começa
    /// por ele com "(continuação)"; nenhum tópico fica sozinho no fim da página; o fim é o último item, uma vez só.
    func confere(_ p: PaginacaoDoPDF, _ topicos: [[GastoMedidoDoPDF]], fim: FimDoRelatorio?, _ m: MedidasDoPDF) {
        var pedacos: [(t: Int, g: Int, linhas: Range<Int>)] = []
        for (i, pagina) in p.paginas.enumerated() {
            #expect(!pagina.itens.isEmpty, "página \(i) vazia")
            #expect(pagina.usado <= m.espaco(i), "página \(i): \(pagina.usado) de \(m.espaco(i))")
            var soma = 0.0
            for (k, item) in pagina.itens.enumerated() {
                switch item {
                case let .topico(t, continuacao):
                    soma += m.linhaDoTopico
                    if continuacao { #expect(k == 0 && pedacos.last?.t == t, "página \(i): continuação fora do lugar") }
                    if !topicos[t].isEmpty, case let .gasto(t2, _, _)? = pagina.itens.dropFirst(k + 1).first {
                        #expect(t2 == t, "página \(i): tópico \(t) sem gasto embaixo")
                    } else if !topicos[t].isEmpty {
                        Issue.record("página \(i): tópico \(t) sozinho no fim")
                    }
                case let .gasto(t, g, l):
                    soma += alturaDoGasto(topicos[t][g].linhas[l], m)
                    pedacos.append((t, g, l))
                case .fim:
                    soma += m.alturaDoFim(fim)
                    #expect(i == p.paginas.count - 1 && k == pagina.itens.count - 1, "o fim não é o último item")
                }
            }
            #expect(abs(soma - pagina.usado) < 1e-9, "página \(i): usado \(pagina.usado), soma \(soma)")
            if i > 0, case .gasto? = pagina.itens.first { Issue.record("página \(i) começa por um gasto, sem o tópico") }
        }
        var esperados: [(Int, Int)] = []
        for (t, gs) in topicos.enumerated() { for g in gs.indices { esperados.append((t, g)) } }
        var proximo = 0
        for (t, g) in esperados {
            var linha = 0
            while proximo < pedacos.count, pedacos[proximo].t == t, pedacos[proximo].g == g {
                #expect(pedacos[proximo].linhas.lowerBound == linha, "gasto \(t).\(g): linhas fora de ordem")
                linha = pedacos[proximo].linhas.upperBound
                proximo += 1
            }
            #expect(linha == topicos[t][g].linhas.count, "gasto \(t).\(g): \(linha) de \(topicos[t][g].linhas.count) linhas")
        }
        #expect(proximo == pedacos.count, "pedaços a mais")
        #expect(p.paginas.flatMap(\.itens).filter { $0 == .fim }.count == 1)
    }

    @Test func umaPaginaSo() {
        let topicos = [[linhas(1), linhas(1), linhas(1)], [linhas(1), linhas(3)]]
        let p = paginarTabelaDoPDF(topicos, fim: .estimada(valor: 900_000, margem: 10_000))
        #expect(p.paginas.count == 1)
        #expect(p.paginas[0].itens == [.topico(0, continuacao: false), .gasto(topico: 0, gasto: 0, linhas: 0..<1),
                                       .gasto(topico: 0, gasto: 1, linhas: 0..<1), .gasto(topico: 0, gasto: 2, linhas: 0..<1),
                                       .topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<1),
                                       .gasto(topico: 1, gasto: 1, linhas: 0..<3), .fim])
        // 20 + 3 × 15 + 20 + 15 + (35 + 3) + (22 + 2 × 18): o texto de 3 linhas tem 34,02 pt, que vão a 35, mais o respiro.
        #expect(p.paginas[0].usado == Double(20 + 45 + 20 + 15 + 38 + 58))
        #expect(p.total == 2)
        #expect(rodapeDoPDF(pagina: 2, de: p.total) == "página 2 de 2")
        #expect(rodapeDoPDF(pagina: 2, de: 5) == "página 2 de 5")
        confere(p, topicos, fim: .estimada(valor: 900_000, margem: 10_000), MedidasDoPDF())
    }

    @Test func espacoDaPaginaEFim() {
        let m = MedidasDoPDF()
        #expect(m.espaco(0) == 663)                     // 842 − 34 − 50 − 47 − 30 (o subtítulo) − 18
        #expect(m.espaco(1) == 693)
        #expect(m.espaco(7) == 693)
        #expect(m.alturaDoFim(.venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1)) == 76)
        #expect(m.alturaDoFim(.estimada(valor: 1, margem: 1)) == 58)
        #expect(m.alturaDoFim(nil) == 45)
        // A linha curta fica com a mínima: 8 pt de texto e 3 de respiro dariam 11.
        #expect(alturaDoGasto(linhas(1, de: 8).linhas[...], m) == 15)
    }

    @Test func limiteExato() {
        let m = redondas
        // 20 do tópico + 9 gastos de 20 = 200: a página enche no limite e o 10º gasto vai para a seguinte, com a continuação.
        let dez = [Array(repeating: linhas(1, de: 20), count: 10)]
        let p = paginarTabelaDoPDF(dez, fim: .estimada(valor: 1, margem: 1), medidas: m)
        #expect(p.paginas.map(\.usado) == [200, Double(20 + 20 + 60)])
        #expect(p.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 9, linhas: 0..<1)])
        confere(p, dez, fim: .estimada(valor: 1, margem: 1), m)
        // O fim de 20 pt (sem venda, com o aviso de 0 pt aqui) cabe nos últimos 20 pt; o de 60, não.
        let oito = [Array(repeating: linhas(1, de: 20), count: 8)]
        #expect(paginarTabelaDoPDF(oito, fim: nil, medidas: m).paginas.count == 1)
        #expect(paginarTabelaDoPDF(oito, fim: .estimada(valor: 1, margem: 1), medidas: m).paginas.map(\.itens) == [
            [.topico(0, continuacao: false)] + (0..<8).map { .gasto(topico: 0, gasto: $0, linhas: 0..<1) }, [.fim]])
    }

    @Test func topicoNaoFicaSozinho() {
        let m = redondas
        // O 1º tópico deixa 30 pt: cabe o tópico (20), mas não o tópico com o 1º gasto (40). O 2º tópico vai inteiro para a
        // página seguinte, sem "(continuação)".
        let topicos = [[linhas(1, de: 50), linhas(1, de: 50), linhas(1, de: 50)], [linhas(1, de: 20), linhas(1, de: 20)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil, medidas: m)
        #expect(p.paginas[0].usado == 170)
        #expect(p.paginas[1].itens.first == .topico(1, continuacao: false))
        confere(p, topicos, fim: nil, m)
        // Com 40 pt sobrando, o tópico e o 1º gasto ficam; o 2º gasto continua na seguinte.
        let justo = [[linhas(1, de: 70), linhas(1, de: 70)], [linhas(1, de: 20), linhas(1, de: 20)]]
        let q = paginarTabelaDoPDF(justo, fim: nil, medidas: m)
        #expect(q.paginas[0].itens.suffix(2) == [.topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<1)])
        #expect(q.paginas[1].itens.prefix(2) == [.topico(1, continuacao: true), .gasto(topico: 1, gasto: 1, linhas: 0..<1)])
        confere(q, justo, fim: nil, m)
    }

    @Test func gastoQueCabeNumaPaginaNaoParte() {
        let m = redondas
        // 17 linhas de 10 pt (170): não cabem no que sobra (140) e cabem numa página nova com a continuação (180): vão inteiras.
        let topicos = [[linhas(1, de: 40), linhas(17, de: 10)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil, medidas: m)
        #expect(p.paginas[0].itens.count == 2)
        #expect(p.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 0..<17)])
        confere(p, topicos, fim: nil, m)
        // A linha curta fica com a altura mínima (20 pt aqui).
        #expect(paginarTabelaDoPDF([[linhas(1, de: 10)]], fim: nil, medidas: m).paginas[0].usado == Double(20 + 20 + 20))
        // O que chega exatamente ao fim da página nova (180 pt, os 200 menos o tópico) também vai inteiro: o 2º gasto do tópico
        // e o 1º do tópico seguinte. Com 190 pt já não cabe nela, e é partido a partir do que sobra na página.
        let exato = [[linhas(1, de: 40), linhas(9, de: 20)]]
        let e = paginarTabelaDoPDF(exato, fim: nil, medidas: m)
        #expect(e.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 0..<9)])
        confere(e, exato, fim: nil, m)
        let doOutroTopico = [[linhas(1, de: 40)], [linhas(9, de: 20)]]
        let o = paginarTabelaDoPDF(doOutroTopico, fim: nil, medidas: m)
        #expect(o.paginas[1].itens.prefix(2) == [.topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<9)])
        confere(o, doOutroTopico, fim: nil, m)
        let alto = [[linhas(1, de: 40), linhas(19, de: 10)]]
        let a = paginarTabelaDoPDF(alto, fim: nil, medidas: m)
        #expect(a.paginas[0].itens.last == .gasto(topico: 0, gasto: 1, linhas: 0..<14))
        #expect(a.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 14..<19)])
        confere(a, alto, fim: nil, m)
        // A exceção é a 1ª página da tabela ainda vazia, menor por causa do subtítulo: 58 linhas (661 pt) cabem numa página
        // nova (673, depois do tópico), mas não nos 643 da 1ª. Abrir outra a deixaria em branco: o gasto é partido ali.
        let quaseUmaPagina = [[linhas(58)]]
        let q = paginarTabelaDoPDF(quaseUmaPagina, fim: nil)
        #expect(q.paginas.map(\.itens) == [[.topico(0, continuacao: false), .gasto(topico: 0, gasto: 0, linhas: 0..<56)],
                                           [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 0, linhas: 56..<58), .fim]])
        for n in 57...59 { confere(paginarTabelaDoPDF([[linhas(n)]], fim: nil), [[linhas(n)]], fim: nil, MedidasDoPDF()) }
        // Com a 1ª página já ocupada, o mesmo gasto vai inteiro para a seguinte, com o tópico.
        let depois = [[linhas(1)], [linhas(58)]]
        let r = paginarTabelaDoPDF(depois, fim: nil)
        #expect(r.paginas[1].itens.prefix(2) == [.topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<58)])
        confere(r, depois, fim: nil, MedidasDoPDF())
    }

    @Test func descricaoDe3000Caracteres() {
        // 75 linhas de 11,34 pt (851 pt com o respiro): maior que uma página. Começa no que sobra da 1ª página e continua na
        // seguinte, partida entre as linhas.
        let longa = medido(String(repeating: "Telha cerâmica ", count: 200))
        #expect(longa.linhas.count == 75)
        let topicos = [[linhas(1), longa, linhas(1)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil)
        #expect(p.paginas.count == 2)
        // 1ª página: 663 − 20 do tópico − 15 do 1º gasto = 628; cabem 55 linhas (624 + 3 = 627 pt, pelo teto de 623,7).
        #expect(p.paginas[0].itens.last == .gasto(topico: 0, gasto: 1, linhas: 0..<55))
        #expect(p.paginas[1].itens.prefix(3) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 55..<75),
                                                .gasto(topico: 0, gasto: 2, linhas: 0..<1)])
        confere(p, topicos, fim: nil, MedidasDoPDF())
        // Como 1º gasto do tópico, ela leva o tópico junto, com a 1ª linha embaixo dele.
        let primeiro = [[linhas(40)], [longa]]
        let q = paginarTabelaDoPDF(primeiro, fim: nil)
        #expect(q.paginas[0].itens.suffix(2).first == .topico(1, continuacao: false))
        confere(q, primeiro, fim: nil, MedidasDoPDF())
        // Maior que duas páginas: três pedaços.
        let enorme = [[linhas(150)]]
        let r = paginarTabelaDoPDF(enorme, fim: .venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1))
        #expect(r.paginas.count == 3)
        confere(r, enorme, fim: .venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1), MedidasDoPDF())
        // Uma linha mais alta que a página inteira (texto nenhum do formulário chega a isso) vai sozinha numa página, e o laço
        // segue: sem a guarda, ele abriria páginas sem fim.
        #expect(paginarTabelaDoPDF([[linhas(1), linhas(1, de: 700)]], fim: nil).paginas.map(\.itens) == [
            [.topico(0, continuacao: false), .gasto(topico: 0, gasto: 0, linhas: 0..<1)],
            [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 0..<1)], [.fim]])
    }

    @Test func obraDe5000Gastos() {
        let ids = ["terreno", "projeto", "matbasicos", "fundacao", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica",
                   "revest", "pintura", "maoobra", "extras", "outros"]
        let gastos: [ValorJSON] = (0..<5000).map { i in
            let descricao = i % 997 == 0 ? String(repeating: "Concreto usinado fck 30 ", count: 125) : String(repeating: "Cimento ", count: 1 + i % 9)
            return .objeto(["id": .texto("g\(i)"), "valor": .numero(Double(100 + (i * 7919) % 90_000) + 0.45), "topico": .texto(ids[i % 14]),
                            "descricao": .texto(descricao), "data": .texto("2025-\(i % 12 < 9 ? "0" : "")\(i % 12 + 1)-\(10 + i % 18)"),
                            "pagamento": .texto("pix")])
        }
        let obra = Obra(arvore: ["id": .texto("o1"), "valorEstimadoVenda": .numero(9_000_000), "gastos": .lista(gastos)])
        let r = relatorioObra(obra, hoje: "2026-10-12", taxa: 1)
        let fim = fimRelatorio(obra, hoje: "2026-10-12", taxa: 1)
        let topicos = r.grupos.map { $0.itens.map { medido($0.gasto.descricao) } }
        let p = paginarTabelaDoPDF(topicos, fim: fim)
        #expect(topicos.joined().count == 5000)
        #expect(p.paginas.count > 100)
        confere(p, topicos, fim: fim, MedidasDoPDF())
        #expect(rodapeDoPDF(pagina: p.total, de: p.total) == "página \(p.total) de \(p.total)")
    }

    @Test func colunaDeValorPeloMaiorValor() {
        #expect(valorNoPDF(319_847.85) == "319.847,85")
        #expect(correcaoNoPDF(46_338.31) == "+46.338,31")
        #expect(correcaoNoPDF(0) == "+0,00")
        #expect(correcaoNoPDF(-1234.5) == "-1.234,50")
        let c = colunasDoPDF(larguraDoMaiorValor: 57)
        #expect(c == ColunasDoPDF(gasto: 236.5, data: 63.5, valor: 69, texto: 211.5))       // 595 − 2 × 44 − 63,5 − 3 × 69
        // O título da coluna, se for mais largo que o maior valor, manda.
        #expect(colunasDoPDF(larguraDoMaiorValor: 40, larguraDoMaiorTitulo: 60).valor == 72)
        // O maior texto pode ser a correção, pelo "+": R$ 900 mil de 2020, corrigido a 1% ao mês, passa de 1,9 milhão.
        let velha = Obra(arvore: ["id": .texto("o1"), "gastos": .lista([
            .objeto(["id": .texto("a"), "valor": .numero(900_000), "topico": .texto("terreno"), "data": .texto("2020-01-10")]),
            .objeto(["id": .texto("b"), "valor": .numero(5_000), "topico": .texto("projeto"), "data": .texto("2026-10-01")])])])
        let r = relatorioObra(velha, hoje: "2026-10-12", taxa: 1)
        let maior = maiorValorDoPDF(r)
        #expect(maior.hasPrefix("+1."))
        #expect(maior.count == 13)
        // Ou o total, que passa de qualquer tópico, ou o corrigido, quando a correção é pequena: R$ 500 mil e R$ 499 mil de um mês
        // atrás, a 1% ao mês, dão 999 mil de gasto (10 caracteres), 1.008.844,89 de corrigido (12) e só +9.844,89 de correção (9).
        let recente = Obra(arvore: ["id": .texto("o1"), "gastos": .lista([
            .objeto(["id": .texto("a"), "valor": .numero(500_000), "topico": .texto("terreno"), "data": .texto("2026-09-12")]),
            .objeto(["id": .texto("b"), "valor": .numero(499_000), "topico": .texto("projeto"), "data": .texto("2026-09-12")])])])
        #expect(maiorValorDoPDF(relatorioObra(recente, hoje: "2026-10-12", taxa: 1)) == "1.008.844,89")
    }
}
