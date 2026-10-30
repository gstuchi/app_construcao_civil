import Testing
@testable import CusttaNucleo

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra (regra do app, sem vetor do site): até 7 tópicos, um pedaço
   cada; com 8 ou mais, os 6 maiores e "Outros"; o fixo "Outros" sempre no cinza; o piso de arco e de largura; o pedaço sob
   o dedo; o "<1%" e o "menos de 1%" falado. */
struct PedacosTests {
    /// Tópicos já na ordem do `gastoPorTopico` (do maior para o menor), com ids t1, t2…
    func topicos(_ brutos: [Double]) -> [GastoDoTopico] {
        brutos.enumerated().map { i, b in GastoDoTopico(id: "t\(i + 1)", bruto: b, pct: 0) }
    }

    func perto(_ a: [Double], _ b: [Double]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 1e-12 }
    }

    @Test func umPedacoPorTopicoAteSete() {
        let um = pedacosDoAnel(topicos([500]))
        #expect(um == [PedacoDoAnel(topicos: topicos([500]), bruto: 500, cor: 0, outros: false)])
        let sete = pedacosDoAnel(topicos([70, 60, 50, 40, 30, 20, 10]))
        #expect(sete.map(\.cor) == [0, 1, 2, 3, 4, 5, nil])
        #expect(sete.map(\.outros) == [false, false, false, false, false, false, false])
        #expect(sete.map { $0.topicos.map(\.id) } == [["t1"], ["t2"], ["t3"], ["t4"], ["t5"], ["t6"], ["t7"]])
        #expect(pedacosDoAnel([]).isEmpty)
    }

    @Test func oitoOuMaisViramSeisEOutros() {
        let oito = pedacosDoAnel(topicos([80, 70, 60, 50, 40, 30, 20, 10]))
        #expect(oito.count == 7)
        #expect(oito.map(\.cor) == [0, 1, 2, 3, 4, 5, nil])
        #expect(oito.map(\.outros) == [false, false, false, false, false, false, true])
        #expect(oito[6].topicos.map(\.id) == ["t7", "t8"])
        #expect(oito[6].bruto == 30)
        let quatorze = pedacosDoAnel(topicos((1...14).map { Double(15 - $0) * 1000.25 }))
        #expect(quatorze.count == 7)
        #expect(quatorze[6].topicos.map(\.id) == ["t7", "t8", "t9", "t10", "t11", "t12", "t13", "t14"])
        #expect(quatorze[6].bruto == [8.0, 7, 6, 5, 4, 3, 2, 1].map { $0 * 1000.25 }.reduce(0, +))
        #expect(quatorze[5].topicos.map(\.id) == ["t6"])
    }

    /// `total` tópicos já na ordem do `gastoPorTopico` (brutos de 10 × `total` a 10), com o fixo "Outros" (id `outros`) na
    /// posição dada (0 é o maior) e os comuns c1, c2… nas outras.
    func comOFixo(total: Int, em posicao: Int) -> [GastoDoTopico] {
        var comum = 0
        return (0..<total).map { i in
            let bruto = Double(total - i) * 10
            if i == posicao { return GastoDoTopico(id: "outros", bruto: bruto, pct: 0) }
            comum += 1
            return GastoDoTopico(id: "c\(comum)", bruto: bruto, pct: 0)
        }
    }

    @Test func oFixoComAteSeisComunsFicaSozinhoNoCinza() {
        // O maior, no meio e o menor: os comuns ganham as cores, e o fixo vai para o fim, cinza e com o nome dele.
        for (total, posicoes) in [(3, [0, 1, 2]), (7, [0, 3, 6])] {
            for p in posicoes {
                let pedacos = pedacosDoAnel(comOFixo(total: total, em: p))
                let comuns = (1..<total).map { ["c\($0)"] }
                #expect(pedacos.map { $0.topicos.map(\.id) } == comuns + [["outros"]], "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.map(\.cor) == Array(0..<total - 1) + [nil], "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.allSatisfy { !$0.outros }, "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.last?.bruto == Double(total - p) * 10, "\(total) tópicos, o fixo em \(p)")
            }
        }
        // Só o fixo: o anel inteiro cinza.
        #expect(pedacosDoAnel(comOFixo(total: 1, em: 0)) == [PedacoDoAnel(topicos: comOFixo(total: 1, em: 0), bruto: 10, cor: nil, outros: false)])
    }

    @Test func oFixoComSeteComunsOuMaisEntraNoOutros() {
        // 7 comuns + o fixo: os 6 maiores comuns coloridos e, por último, o "Outros" com o 7º comum e o fixo, do maior para o
        // menor, mesmo quando o fixo é o maior.
        for (p, juntos) in [(0, ["outros", "c7"]), (3, ["outros", "c7"]), (7, ["c7", "outros"])] {
            let pedacos = pedacosDoAnel(comOFixo(total: 8, em: p))
            #expect(pedacos.count == 7, "o fixo em \(p)")
            #expect(pedacos.prefix(6).map { $0.topicos.map(\.id) } == (1...6).map { ["c\($0)"] }, "o fixo em \(p)")
            #expect(pedacos.map(\.cor) == [0, 1, 2, 3, 4, 5, nil], "o fixo em \(p)")
            #expect(pedacos.map(\.outros) == [false, false, false, false, false, false, true], "o fixo em \(p)")
            #expect(pedacos[6].topicos.map(\.id) == juntos, "o fixo em \(p)")
            #expect(pedacos[6].bruto == Double(8 - p) * 10 + (p == 7 ? 20 : 10), "o fixo em \(p)")
            #expect(rotuloDoOutros(pedacos[6]) == "Outros · 2 tópicos", "o fixo em \(p)")
        }
        // O fixo no meio dos que o "Outros" junta fica no lugar dele, e conta no rótulo e no "e mais".
        let dez = pedacosDoAnel(comOFixo(total: 10, em: 7))
        #expect(dez[6].topicos.map(\.id) == ["c7", "outros", "c8", "c9"])
        #expect(rotuloDoOutros(dez[6]) == "Outros · 4 tópicos")
        #expect(legendaDaBarra(dez, quantos: 4).mais == "e mais 6 tópicos")
    }

    @Test func pisoDeArcoSaiDoMaior() {
        // Num anel de 1.000 pt e piso de 10 pt (1%), os dois pedaços de 0,5% sobem para 1%, e o 1% que eles ganham sai do maior.
        let arcos = arcosDoAnel(pedacosDoAnel(topicos([900, 90, 5, 5])), circunferencia: 1000, piso: 10)
        #expect(perto(arcos.map(\.inicio), [0, 0.89, 0.98, 0.99]))
        #expect(perto(arcos.map(\.fim), [0.89, 0.98, 0.99, 1]))
        // No empate do maior, o primeiro perde.
        let empate = arcosDoAnel(pedacosDoAnel(topicos([495, 495, 5, 5])), circunferencia: 1000, piso: 10)
        #expect(perto(empate.map(\.fim), [0.485, 0.98, 0.99, 1]))
        // Com o piso do anel de verdade (10 pt numa circunferência de 2π × 100), o pequeno fica com 10 pt de arco.
        let anel = arcosDoAnel(pedacosDoAnel(topicos([999, 1])), circunferencia: 2 * Double.pi * 100)
        #expect(abs((anel[1].fim - anel[1].inicio) * 2 * Double.pi * 100 - 10) < 1e-9)
        #expect(anel[1].fim == 1)
        // O tópico de bruto zero (um gasto de R$ 0) fica sem arco e sem piso, como o arco de comprimento 0 do site.
        let zero = arcosDoAnel(pedacosDoAnel(topicos([900, 100, 0])), circunferencia: 1000, piso: 10)
        #expect(perto(zero.map(\.inicio), [0, 0.9, 1]))
        #expect(perto(zero.map(\.fim), [0.9, 1, 1]))
    }

    @Test func pisoQueNaoCabeDeixaTudoIgual() {
        // Sem bruto (gastos de valor zero), sem comprimento e quando o piso de todos passa do comprimento, as partes ficam iguais.
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([0, 0])), circunferencia: 1000).map(\.fim), [0.5, 1]))
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([3, 1])), circunferencia: 0).map(\.fim), [0.5, 1]))
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 30, piso: 8, vao: 3), [8, 8, 8]))
        #expect(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 5) == [0, 0, 0])
        // Com 4 pt a mais, o piso já cabe: os dois pequenos ficam com 8 pt, e o maior, com o resto.
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 34, piso: 8, vao: 3), [12, 8, 8]))
        // O maior não desce abaixo do piso: com 4 pedaços grandes e 3 pequenos num piso de 7%, a conta tiraria demais dele.
        let apertado = partesComPiso([25, 25, 25, 24.97, 0.01, 0.01, 0.01], comprimento: 100, piso: 7)
        #expect(perto(apertado, Array(repeating: 1.0 / 7, count: 7)))
        // As partes iguais ficam só entre os tópicos com bruto: o de bruto zero continua sem arco.
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([3, 1, 0])), circunferencia: 0).map(\.fim), [0.5, 1, 1]))
    }

    @Test func barraComVaosEPiso() {
        let pedacos = pedacosDoAnel(topicos([700, 200, 95, 5]))
        let larguras = largurasDaBarra(pedacos, largura: 309)
        // 309 − 3 vãos de 3 pt = 300 pt para os pedaços; o de 5 (1,5 pt) sobe para 8, e os 6,5 pt saem do maior.
        #expect(perto(larguras, [203.5, 60, 28.5, 8]))
        // Na letra máxima, o piso e o vão crescem.
        #expect(perto(largurasDaBarra(pedacos, largura: 412, piso: 12, vao: 4), [270, 80, 38, 12]))
        #expect(largurasDaBarra([], largura: 300).isEmpty)
        // O pedaço de bruto zero fica sem largura e sem vão: 303 − 1 vão de 3 pt = 300 pt para os dois com bruto.
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([900, 100, 0])), largura: 303), [270, 30, 0]))
    }

    @Test func pedacoSobODedo() {
        let arcos = [ArcoDoPedaco(inicio: 0, fim: 0.5), ArcoDoPedaco(inicio: 0.5, fim: 0.75), ArcoDoPedaco(inicio: 0.75, fim: 1)]
        #expect(pedacoNoAnel(x: 0, y: -100, arcos: arcos) == 0)        // topo
        #expect(pedacoNoAnel(x: 100, y: 0, arcos: arcos) == 0)         // direita: 1/4 da volta
        #expect(pedacoNoAnel(x: 0, y: 100, arcos: arcos) == 1)         // embaixo: metade, o começo do 2º
        #expect(pedacoNoAnel(x: -100, y: 0, arcos: arcos) == 2)        // esquerda: 3/4, o começo do 3º
        #expect(pedacoNoAnel(x: -1, y: -100, arcos: arcos) == 2)       // logo antes do topo
        #expect(pedacoNoAnel(x: -1e-20, y: -100, arcos: arcos) == 2)   // tão perto do topo que a fração arredonda para 1
        #expect(pedacoNoAnel(x: 0, y: -100, arcos: []) == nil)
        // O arco vazio do tópico de bruto zero, no fim, nunca fica sob o dedo, nem no topo.
        let comZero = [ArcoDoPedaco(inicio: 0, fim: 0.9), ArcoDoPedaco(inicio: 0.9, fim: 1), ArcoDoPedaco(inicio: 1, fim: 1)]
        #expect(pedacoNoAnel(x: -1e-20, y: -100, arcos: comZero) == 1)
        #expect(abs(fracaoNoAnel(x: 1, y: 1) - 0.375) < 1e-15)      // embaixo, à direita
    }

    @Test func porcentoComMenosDeUm() {
        #expect(porcentoDoTopico(380, total: 1000) == "38%")
        #expect(porcentoDoTopico(125, total: 1000) == "13%")          // o Math.round do site: o meio sobe
        #expect(porcentoDoTopico(4, total: 1000) == "<1%")            // o site diria 0%
        #expect(porcentoDoTopico(7, total: 1000) == "<1%")            // o site diria 1%
        #expect(porcentoDoTopico(10, total: 1000) == "1%")
        #expect(porcentoDoTopico(996, total: 1000) == "100%")
        #expect(porcentoDoTopico(0, total: 1000) == "0%")
        #expect(porcentoDoTopico(0, total: 0) == "0%")
    }

    @Test func porcentoFaladoSemOSinal() {
        // O VoiceOver lê o "<1%" como "menos de 1%", sozinho (a barra) e na frase (a lista e o detalhe do tópico).
        #expect(porcentoFalado(porcentoDoTopico(4, total: 1000)) == "menos de 1%")
        #expect(porcentoFalado("<1% da obra") == "menos de 1% da obra")
        #expect(porcentoFalado("3 gastos · <1% da obra") == "3 gastos · menos de 1% da obra")
        #expect(porcentoFalado("38%") == "38%")
        #expect(porcentoFalado("1 gasto · 1% da obra") == "1 gasto · 1% da obra")
    }

    @Test func textosDosTopicos() {
        #expect(contagemDeTopicos(1) == "1 tópico")
        #expect(contagemDeTopicos(14) == "14 tópicos")
        let pedacos = pedacosDoAnel(topicos((1...14).map { Double(15 - $0) }))
        #expect(rotuloDoOutros(pedacos[6]) == "Outros · 8 tópicos")
        let legenda = legendaDaBarra(pedacos, quantos: 4)
        #expect(legenda.pedacos.map { $0.topicos[0].id } == ["t1", "t2", "t3", "t4"])
        #expect(legenda.mais == "e mais 10 tópicos")
        #expect(legendaDaBarra(pedacos, quantos: 3).mais == "e mais 11 tópicos")
        #expect(legendaDaBarra(pedacosDoAnel(topicos([5, 4, 3, 2, 1])), quantos: 4).mais == "e mais 1 tópico")
        #expect(legendaDaBarra(pedacosDoAnel(topicos([4, 3, 2, 1])), quantos: 4).mais == nil)
        #expect(legendaDaBarra(pedacosDoAnel(topicos([2, 1])), quantos: 4).pedacos.count == 2)
    }
}
