#if DEBUG
import Foundation
import CusttaNucleo

/* Os orçamentos do mockup aprovado da etapa 3 (parte1.html, de 18/10/2026) sobre a vitrine: a Casa Alphaville com os 46
   lançamentos e o orçamento em cada situação dos quadros, para a tela mostrar os números do mockup em qualquer dia.
   CUSTTA_DADOS (MontarFalso):
   porTopico      o orçamento por tópico em 14 tópicos (R$ 1.019.847,85 previstos, 80% usado, Estrutura e Fundação
                  passaram, três perto, Documentação e Pintura fora), um tópico próprio ("Gesso e drywall", 22 linhas na
                  folha) e a Casa Tamboré 4, vendida, com o orçamento total de R$ 1.000.000,00
   perto, passou  o total de R$ 920.000,00 (92%) e de R$ 800.000,00 (105%)
   semOrcamento   a Casa Alphaville sem orçamento ("Definir orçamento")
   muitosTopicos  o porTopico com 50 tópicos próprios, o limite das rules: 71 linhas na folha
   topicoLongo    o porTopico com 120 diárias da equipe na Mão de obra (100 pagas e 20 a vencer, de R$ 350,00 no Pix): a
                  lista longa do detalhe do tópico
   Na vitrine de sempre, o total de R$ 1.200.000,00 (70%, dentro do previsto). */
extension DadosDeExemplo {
    /// Os previstos por tópico do mockup.
    static let previstosDoMockup: [String: Double] = [
        "terreno": 319_847.85, "estrutura": 85_000, "revest": 80_000, "maoobra": 150_000, "fundacao": 60_000, "telhado": 50_000,
        "ferragem": 45_000, "esquadrias": 40_000, "matbasicos": 40_000, "eletrica": 30_000, "hidraulica": 25_000,
        "alvenaria": 20_000, "acabamento": 60_000, "paisagismo": 15_000,
    ]

    static func vitrineDoOrcamento(_ variante: String, hoje: Date = .now) -> ValorJSON {
        let base = vitrine(hoje: hoje)
        guard case .objeto(var raiz) = base, case .lista(var obras) = raiz["obras"], obras.count == 3,
              case .objeto(var casa) = obras[0], case .objeto(var tambore) = obras[2],
              case .objeto(var config) = raiz["config"] else { return base }
        func total(_ valor: Double) -> ValorJSON { .objeto(["modo": .texto("total"), "total": .numero(valor)]) }
        switch variante {
        case "perto": casa["orcamento"] = total(920_000)
        case "passou": casa["orcamento"] = total(800_000)
        case "semOrcamento": casa["orcamento"] = nil
        default:
            casa["orcamento"] = .objeto(["modo": .texto("topicos"), "topicos": .objeto(previstosDoMockup.mapValues(ValorJSON.numero))])
            tambore["orcamento"] = total(1_000_000)
            let proprios = [("c_gesso", "Gesso e drywall")]
                + (variante == "muitosTopicos" ? (2...limiteDeTopicosProprios).map { ("c_proprio\($0)", "Tópico próprio \($0)") } : [])
            config["topicosCustom"] = .lista(proprios.map { .objeto(["id": .texto($0.0), "nm": .texto($0.1), "ic": .texto("etiqueta")]) })
            if variante == "topicoLongo", case .lista(let gastos) = casa["gastos"] {
                casa["gastos"] = .lista(gastos + diariasDaEquipe(hoje: hoje))
            }
        }
        obras[0] = .objeto(casa)
        obras[2] = .objeto(tambore)
        raiz["obras"] = .lista(obras)
        raiz["config"] = .objeto(config)
        return .objeto(raiz)
    }

    /// As 120 diárias do `topicoLongo`, na Mão de obra: 100 pagas, uma por dia de ontem para trás, e 20 a vencer, de amanhã
    /// em diante.
    static func diariasDaEquipe(hoje: Date) -> [ValorJSON] {
        let calendario = Calendar(identifier: .gregorian)
        return (1...120).map { i in
            let dia = calendario.date(byAdding: .day, value: i <= 100 ? -i : i - 100, to: hoje) ?? hoje
            return .objeto(["id": .texto(String(format: "d%03d", i)), "valor": .numero(350), "topico": .texto("maoobra"),
                            "descricao": .texto("Diária da equipe"), "data": .texto(dataLocalISO(dia, fuso: .current)),
                            "pagamento": .texto("pix")])
        }
    }

    /// O limite de tópicos próprios das rules (`topicosCustom.size() <= 50`).
    static let limiteDeTopicosProprios = 50
}
#endif
