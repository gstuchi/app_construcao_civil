import Foundation

/* Regras e textos das telas da obra na etapa 2, parte 3 (mockup aprovado em 13/10): as ações da fase com os textos do
   site (renderObra, app.js:392-397), as perguntas de apagar a obra e de desfazer a venda, as notas das folhas, a lista
   vazia, o alerta de "Não salvou" e o campo da área. Os textos vêm do site; onde o mockup acrescenta (o "Não dá para
   desfazer", o plural de "lançamentos"), fica o do mockup, como no apagar gasto. */

/// Uma ação da fase, logo abaixo dos indicadores.
public enum AcaoDaFase: String, Sendable, CaseIterable {
    case marcarPronta, registrarVenda, voltarConstrucao, desfazerVenda

    public var rotulo: String {
        switch self {
        case .marcarPronta: return "Marcar como pronta"
        case .registrarVenda: return "Registrar venda"
        case .voltarConstrucao: return "Voltar pra construção"
        case .desfazerVenda: return "Desfazer venda"
        }
    }

    /// O ícone do site (icons.js).
    public var icone: String {
        switch self {
        case .marcarPronta: return "casa"
        case .registrarVenda: return "acordo"
        case .voltarConstrucao, .desfazerVenda: return "voltar"
        }
    }

    /// O próximo passo vai sólido, na marca (o `primary` do site); voltar, em vidro (o `ghost`).
    public var principal: Bool { self == .marcarPronta || self == .registrarVenda }
}

/// As ações de cada fase, na ordem do site: construção → pronta; pronta → venda ou de volta; vendida → desfazer.
public func acoesDaFase(_ fase: Fase) -> [AcaoDaFase] {
    switch fase {
    case .construcao: return [.marcarPronta]
    case .pronta: return [.registrarVenda, .voltarConstrucao]
    case .vendida: return [.desfazerVenda]
    }
}

/// O alerta de apagar a obra: o nome no título, com as aspas do site, e quantos lançamentos se perdem.
public func textoDeApagarObra(nome: String, lancamentos n: Int) -> (titulo: String, mensagem: String) {
    let perdidos = n == 0 ? "" : n == 1 ? "1 lançamento dela será perdido. " : "Os \(n) lançamentos dela serão perdidos. "
    return ("Apagar “\(nome)”?", perdidos + "Não dá para desfazer.")
}

/// A pergunta do "Desfazer venda" (app.js:477), em título e mensagem.
public let textoDeDesfazerVenda = (titulo: "Desfazer a venda?", mensagem: "A obra volta pra “Pronta”.", botao: "Desfazer venda")

/// A nota embaixo da data da venda.
public func notaDaDataDaVenda(dataInicio: String) -> String {
    "Entre o início da obra (\(dataCurta(dataInicio))) e hoje. A correção pelo banco para nessa data."
}

/// A nota da linha "Obra" no gasto lançado de dentro de uma obra vendida.
public func notaDaObraVendida(_ nome: String) -> String { "\(nome) está vendida; o gasto vai para uma obra aberta." }

/// A lista de obras vazia, com os dados já vistos (app.js:222, com "para").
public let listaDeObrasVazia = (titulo: "Nenhuma obra ainda.", texto: "Toque no + para criar a primeira obra.")

/// O alerta de quando a gravação não passa sozinha (o erro terminal): o texto do site (`AvisoSinc.naoSalvou`), partido
/// em título e mensagem no primeiro ponto.
public func alertaDeNaoSalvou(codigo: String) -> (titulo: String, mensagem: String) {
    let texto = AvisoSinc.naoSalvou(codigo: codigo, terminal: true).mensagem
    guard let ponto = texto.range(of: ". ") else { return (texto, "") }
    return (String(texto[..<ponto.lowerBound]), String(texto[ponto.upperBound...]))
}

/// A área no campo da edição, com vírgula ("3,125"), como o `formEditarObra` do site: o número cru ("3.125") o
/// `parseNum` leria como milhar (3125). Vazio sem área.
public func areaParaCampo(_ area: Double?) -> String {
    guard let area else { return "" }
    return numeroJS(area).replacingOccurrences(of: ".", with: ",")
}

/// As obras que recebem gasto novo (não vendidas), na ordem da lista de obras.
public func obrasAbertas(_ obras: [Obra]) -> [Obra] { obrasOrdenadas(obras).filter { $0.fase != .vendida } }
