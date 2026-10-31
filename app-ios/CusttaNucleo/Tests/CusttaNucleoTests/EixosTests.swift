import Testing
@testable import CusttaNucleo

/* Os eixos dos gráficos de mês (regra do app, sem vetor do site): a escala em números redondos, os rótulos dos meses e o
   mês sob o dedo. */
struct EixosTests {
    /// Os meses AAAA-MM de `inicio` em diante, como a série mensal os dá.
    func meses(_ inicio: String, _ n: Int) -> [String] {
        var (ano, mes) = (Int(inicio.prefix(4))!, Int(inicio.suffix(2))!)
        return (0..<n).map { _ in
            defer { mes += 1; if mes > 12 { mes = 1; ano += 1 } }
            return "\(ano)-" + (mes < 10 ? "0\(mes)" : "\(mes)")
        }
    }

    @Test func escalaEmNumerosRedondos() {
        let e = escalaRedonda(777_000, divisoes: 4)
        #expect(e.passo == 250_000)
        #expect(e.topo == 1_000_000)
        #expect(e.linhas == [250_000, 500_000, 750_000, 1_000_000])
        #expect(e.rotulos == ["R$ 250 mil", "R$ 500 mil", "R$ 750 mil", "R$ 1,00 mi"])   // o site daria R$ 233 mil, 465 mil…
        // Na letra máxima, 2 divisões.
        #expect(escalaRedonda(777_000, divisoes: 2).rotulos == ["R$ 500 mil", "R$ 1,00 mi"])
        #expect(escalaRedonda(46_000, divisoes: 4).rotulos == ["R$ 12 mil", "R$ 24 mil", "R$ 36 mil", "R$ 48 mil"])
        #expect(escalaRedonda(5_400, divisoes: 4).passo == 1_500)
        // A potência de 10 vem do piso do log: 3.502 fica na casa do milhar (passo 4 mil), não na da dezena de milhar.
        #expect(escalaRedonda(13_600, divisoes: 4).passo == 4_000)
    }

    @Test func escalaComFolgaNoTopo() {
        // R$ 1 milhão não encosta no topo: os 3% de folga passam o passo de 250 para 300 mil.
        #expect(escalaRedonda(1_000_000, divisoes: 4).topo == 1_200_000)
        #expect(escalaRedonda(970_000, divisoes: 4).topo == 1_000_000)
        // Sem valor (gastos de zero), a escala de R$ 1, para o gráfico nunca dividir por zero. Abaixo de mil, o moneyShort do
        // site cai no money, com o espaço sem quebra depois do R$.
        #expect(escalaRedonda(0, divisoes: 4).rotulos == ["R$\u{00A0}0,30", "R$\u{00A0}0,60", "R$\u{00A0}0,90", "R$\u{00A0}1,20"])
    }

    @Test func rotulosDosMesesComOAnoQuandoMuda() {
        let m = meses("2025-08", 14)
        #expect(rotulosDoEixoX(m, quantos: 4) == [RotuloDoEixoX(indice: 0, texto: "ago/25"), RotuloDoEixoX(indice: 4, texto: "dez"),
                                                 RotuloDoEixoX(indice: 9, texto: "mai/26"), RotuloDoEixoX(indice: 13, texto: "set")])
        // Na letra máxima, 3; o meio sobe no empate, como o Math.round (6 meses: 2,5 vira 3).
        #expect(rotulosDoEixoX(meses("2026-01", 6), quantos: 3).map(\.indice) == [0, 3, 5])
        #expect(rotulosDoEixoX(meses("2024-11", 24), quantos: 3).map(\.texto) == ["nov/24", "nov/25", "out/26"])
        // Um mês só e dois meses.
        #expect(rotulosDoEixoX(["2026-10"], quantos: 4) == [RotuloDoEixoX(indice: 0, texto: "out/26")])
        #expect(rotulosDoEixoX(meses("2026-09", 2), quantos: 4).map(\.texto) == ["set/26", "out"])
        #expect(rotulosDoEixoX([], quantos: 4).isEmpty)
    }

    @Test func rotuloDoMesEscolhido() {
        let m = meses("2025-08", 14)
        let fixos = rotulosDoEixoX(m, quantos: 4)
        #expect(rotuloDoMes(m, indice: 9, fixos: fixos) == "mai/26")   // fixo: o texto dele
        #expect(rotuloDoMes(m, indice: 5, fixos: fixos) == "jan/26")   // janeiro leva o ano
        #expect(rotuloDoMes(m, indice: 6, fixos: fixos) == "fev")
    }

    @Test func mesSobODedo() {
        // Gasto por mês: 12 colunas de 20 pt a partir de x = 40.
        #expect(mesNaColuna(x: 40, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 59.99, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 60, inicio: 40, largura: 240, meses: 12) == 1)
        #expect(mesNaColuna(x: 279.9, inicio: 40, largura: 240, meses: 12) == 11)
        #expect(mesNaColuna(x: 400, inicio: 40, largura: 240, meses: 12) == 11)
        #expect(mesNaColuna(x: 0, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 50, inicio: 40, largura: 0, meses: 12) == 0)
        // Evolução: 12 pontos de 20 em 20 pt a partir de x = 40; o mais perto, com o meio subindo.
        #expect(mesNoPonto(x: 49.99, inicio: 40, largura: 220, meses: 12) == 0)
        #expect(mesNoPonto(x: 50, inicio: 40, largura: 220, meses: 12) == 1)
        #expect(mesNoPonto(x: 255, inicio: 40, largura: 220, meses: 12) == 11)
        #expect(mesNoPonto(x: 500, inicio: 40, largura: 220, meses: 12) == 11)
        #expect(mesNoPonto(x: -20, inicio: 40, largura: 220, meses: 12) == 0)
        #expect(mesNoPonto(x: 100, inicio: 40, largura: 220, meses: 1) == 0)
    }
}
