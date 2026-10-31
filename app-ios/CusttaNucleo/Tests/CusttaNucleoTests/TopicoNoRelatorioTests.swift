import Testing
@testable import CusttaNucleo

/* A linha do tópico no Relatório do app (regra do app, sem vetor do site): quantos gastos, o "N de M gastos" da busca e a
   parte da obra com 1 casa. */
struct TopicoNoRelatorioTests {
    @Test func contagemDosGastos() {
        #expect(contagemDeGastos(1) == "1 gasto")
        #expect(contagemDeGastos(2) == "2 gastos")
        // Na busca, o substantivo vai pelo total do tópico.
        #expect(contagemDeGastos(1, de: 3) == "1 de 3 gastos")
        #expect(contagemDeGastos(11, de: 11) == "11 de 11 gastos")
        #expect(contagemDeGastos(1, de: 1) == "1 de 1 gasto")
        #expect(contagemDeGastos(12, de: 46) == "12 de 46 gastos")   // o resumo dos achados
    }

    @Test func parteDaObraComUmaCasa() {
        #expect(parteComUmaCasa(380, total: 1000) == "38,0%")
        #expect(parteComUmaCasa(1000, total: 1000) == "100,0%")
        #expect(parteComUmaCasa(9995, total: 10_000) == "100,0%")
        // 0,15% sobe para 0,2%, como o toLocaleString pt-BR (o toFixed do JavaScript daria 0,1%).
        #expect(parteComUmaCasa(15, total: 10_000) == "0,2%")
        // Abaixo de 0,1%, "<0,1%", como o "<1%" do anel; o zero continua zero.
        #expect(parteComUmaCasa(9, total: 10_000) == "<0,1%")
        #expect(parteComUmaCasa(10, total: 10_000) == "0,1%")
        #expect(parteComUmaCasa(0, total: 1000) == "0,0%")
        #expect(parteComUmaCasa(0, total: 0) == "0,0%")
        // A conta é a do site e do mockup, bruto / total * 100: 29 de 400 (7,25% exato) dá 7,249999999999999 em ponto
        // flutuante e fica 7,2%; bruto * 100 / total daria 7,3%.
        #expect(parteComUmaCasa(29, total: 400) == "7,2%")
    }

    @Test func casasNoFormatoDoSite() {
        #expect(casasPtBR(1234.56, 1) == "1.234,6")
        #expect(casasPtBR(-1234.56, 1) == "-1.234,6")
        #expect(casasPtBR(0.05, 1) == "0,1")
        #expect(casasPtBR(0.04, 1) == "0,0")
        #expect(casasPtBR(99.95, 1) == "100,0")
        #expect(casasPtBR(12.25, 2) == "12,25")
        #expect(casasPtBR(2.5, 0) == "3")
        #expect(casasPtBR(0, 1) == "0,0")
    }

    @Test func linhaDoTopico() {
        #expect(linhaDoTopicoNoRelatorio(2, bruto: 380, total: 1000) == "2 gastos · 38,0%")
        #expect(linhaDoTopicoNoRelatorio(11, de: 11, bruto: 380, total: 1000) == "11 de 11 gastos · 38,0%")
        #expect(linhaDoTopicoNoRelatorio(1, de: 3, bruto: 50, total: 1000) == "1 de 3 gastos · 5,0%")
    }
}
