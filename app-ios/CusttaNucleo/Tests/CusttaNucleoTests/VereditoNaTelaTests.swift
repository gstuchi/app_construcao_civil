import Testing
@testable import CusttaNucleo

/* O bloco do veredito do "Vale a pena?" no app (mockup da etapa 4, parte2.js, `telaSimula`): os mesmos textos do site
   (`textosSimulador`), arrumados em linhas em vez de juntos por " · ", com a taxa partida em número e unidade. */
struct VereditoNaTelaTests {
    private func conta(venda: Double = 1_450_000, meses: Int = 6, corrigido: Double = 901_820.11, novaDemais: Bool = false,
                       tir: Double? = 3.52, multiplicador: Double = 3.52) -> ContaDoSimulador {
        ContaDoSimulador(venda: venda, meses: meses, alvo: "2027-04-12", bruto: 842_317.45, corrigido: corrigido,
                         novaDemais: novaDemais, tir: tir, acima: tir.map { $0 - 1 }, vale: venda > corrigido,
                         multiplicador: multiplicador)
    }

    @Test func valeAPenaComATaxaEmNumeroEUnidade() {
        let v = vereditoNaTela(conta(), taxa: 1)
        #expect(v.vale)
        #expect(v.titulo == "Vale a pena")
        #expect(v.numero == "3,52")
        #expect(v.unidade == "% ao mês")
        #expect(v.linhas == ["vendendo daqui a 6 meses", "banco paga 1% · rende 3,5× o banco"])
        #expect(v.falado == "Vale a pena, 3,52% ao mês, vendendo daqui a 6 meses, banco paga 1%, rende 3,5× o banco")
    }

    @Test func rendeMenosQueOBancoNaoDizQuantasVezes() {
        // Abaixo do banco, o multiplicador fica abaixo de 1 e o site não o mostra.
        let v = vereditoNaTela(conta(venda: 880_000, meses: 1, tir: 0.41, multiplicador: 0.41), taxa: 1)
        #expect(!v.vale)
        #expect(v.titulo == "Rende menos que o banco")
        #expect(v.numero == "0,41")
        #expect(v.linhas == ["vendendo daqui a 1 mês", "banco paga 1%"])
        #expect(v.falado == "Rende menos que o banco, 0,41% ao mês, vendendo daqui a 1 mês, banco paga 1%")
    }

    @Test func obraComMenosDeUmMesFicaSemTaxaEComOAviso() {
        let v = vereditoNaTela(conta(meses: 0, novaDemais: true, tir: nil, multiplicador: 0), taxa: 1.5)
        #expect(v.vale, "o veredito sai pelo preço contra o custo corrigido, como no site")
        #expect(v.numero == "—")
        #expect(v.unidade == nil)
        #expect(v.linhas == ["vendendo hoje", "banco paga 1,5%", "obra com menos de 1 mês — % ao mês ainda não diz muito"])
        #expect(v.falado == "Vale a pena, sem taxa ao mês, vendendo hoje, banco paga 1,5%, obra com menos de 1 mês — % ao mês ainda não diz muito")
    }

    @Test func osTextosSaoOsDoSite() {
        // As linhas são os `detalhes` do site, na mesma ordem: nenhuma frase a mais nem a menos.
        for c in [conta(), conta(venda: 880_000, tir: 0.41, multiplicador: 0.41), conta(novaDemais: true, tir: nil, multiplicador: 0)] {
            let site = textosSimulador(c, taxa: 1, area: nil)
            let v = vereditoNaTela(c, taxa: 1)
            #expect(v.titulo == site.veredito)
            #expect(v.linhas.flatMap { $0.components(separatedBy: " · ") } == site.detalhes)
            #expect(v.numero + (v.unidade ?? "") == site.taxa)
        }
    }
}
