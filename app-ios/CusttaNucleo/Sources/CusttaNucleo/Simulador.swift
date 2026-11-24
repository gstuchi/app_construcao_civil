import Foundation

/* O "Vale a pena?", como o calc.js o calcula e escreve (morava no app.js renderSimula e simulaCompute). Conferido pelos
   vetores do site (SimuladorTests). */

/// As obras do simulador e a escolhida.
public struct ObrasDoSimulador: Equatable, Sendable {
    /// As não vendidas com gastos, na ordem do documento.
    public let elegiveis: [Obra]
    /// A escolhida, enquanto elegível; senão, a primeira; nil sem nenhuma.
    public let escolhida: String?
}

/// `obrasSimulador` do calc.js.
public func obrasSimulador(_ obras: [Obra], escolhida: String?) -> ObrasDoSimulador {
    let elegiveis = obras.filter { $0.fase != .vendida && !$0.gastos.isEmpty }
    let mantida = elegiveis.contains { $0.id == escolhida } ? escolhida : nil
    return ObrasDoSimulador(elegiveis: elegiveis, escolhida: mantida ?? elegiveis.first?.id)
}

/// `precoInicialSimulador` do calc.js: o preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou;
/// nil sem estimada (a zero não conta, como no site).
public func precoInicialSimulador(_ obra: Obra) -> Double? {
    guard let estimada = obra.valorEstimadoVenda, estimada != 0 else { return nil }
    return estimada
}

/// `MESES_SIMULADOR` do calc.js: os meses da venda vão de 0 a 120 na conta.
public let mesesSimulador = 120

public struct ContaDoSimulador: Equatable, Sendable {
    public let venda: Double
    /// Os meses da conta, entre 0 e 120.
    public let meses: Int
    /// Hoje mais os meses (`addMesesClampado`).
    public let alvo: String
    public let bruto: Double
    /// Corrigido até o alvo.
    public let corrigido: Double
    /// Menos de 1 mês de obra até o alvo: fica sem taxa.
    public let novaDemais: Bool
    /// A TIR, em % ao mês; nil sem taxa.
    public let tir: Double?
    public let acima: Double?
    /// A venda passa do corrigido.
    public let vale: Bool
    /// TIR ÷ taxa; 0 sem TIR.
    public let multiplicador: Double
}

/// `contaSimulador` do calc.js: vender a obra por `venda` daqui a `meses`, sem gasto novo até lá; nil sem preço.
public func contaSimulador(_ obra: Obra, venda: Double, meses: Int, hoje: String, taxa: Double) -> ContaDoSimulador? {
    if venda <= 0 { return nil }
    let m = min(mesesSimulador, max(0, meses))
    let alvo = addMesesClampado(hoje, m)
    let corrigido = totalCorrigido(obra, taxa: taxa, hoje: alvo)
    let novaDemais = mesesDeObra(obra, hoje: alvo) < 1
    let tir = novaDemais ? nil : tirMensal(obra.gastos, venda: venda, alvo: alvo)
    return ContaDoSimulador(venda: venda, meses: m, alvo: alvo, bruto: totalBruto(obra), corrigido: corrigido, novaDemais: novaDemais,
                            tir: tir, acima: rendimentoAcima(tir, taxa: taxa), vale: venda > corrigido,
                            multiplicador: tir.map { taxa > 0 ? $0 / taxa : 0 } ?? 0)
}

/// A cor de um número da tabela, pelo sinal.
public enum SinalDaSimulacao: String, Sendable {
    case positivo, negativo
}

public struct LinhaDaSimulacao: Equatable, Sendable {
    public let rotulo: String
    /// Pelo bruto.
    public let bruto: String
    /// Pelo corrigido.
    public let corrigido: String
    /// Só no lucro e nas duas porcentagens; nil sem valor.
    public let sinalBruto: SinalDaSimulacao?
    public let sinalCorrigido: SinalDaSimulacao?
    /// A linha do lucro.
    public let destaque: Bool
}

public struct TextosDoSimulador: Equatable, Sendable {
    /// "Vale a pena" ou "Rende menos que o banco".
    public let veredito: String
    /// "8,63% ao mês" ou "—".
    public let taxa: String
    /// "vendendo hoje", "banco paga 1%", "rende 8,6× o banco" e o aviso da obra com menos de 1 mês (o site junta com " · ").
    public let detalhes: [String]
    public let tabela: [LinhaDaSimulacao]
}

/// `textosSimulador` do calc.js: o cartão e a tabela da simulação. O R$/m² só com área.
public func textosSimulador(_ conta: ContaDoSimulador, taxa: Double, area: Double?) -> TextosDoSimulador {
    func virgula(_ v: Double, _ casas: Int) -> String { toFixedJS(v, casas).replacingOccurrences(of: ".", with: ",") }
    func din(_ v: Double?) -> String { v.map { moeda($0) } ?? "—" }
    func pct1(_ v: Double?) -> String { v.map { virgula($0, 1) + "%" } ?? "—" }
    func taxa2(_ v: Double?) -> String { v.map { virgula($0, 2) + "% a.m." } ?? "—" }
    func sinal(_ v: Double?) -> SinalDaSimulacao? { v.map { $0 >= 0 ? .positivo : .negativo } }
    func linha(_ rotulo: String, _ bruto: String, _ corrigido: String, sinais: (Double?, Double?)? = nil,
               destaque: Bool = false) -> LinhaDaSimulacao {
        LinhaDaSimulacao(rotulo: rotulo, bruto: bruto, corrigido: corrigido, sinalBruto: sinais.flatMap { sinal($0.0) },
                         sinalCorrigido: sinais.flatMap { sinal($0.1) }, destaque: destaque)
    }
    let rb = resumoVenda(conta.venda, custo: conta.bruto)
    let rc = resumoVenda(conta.venda, custo: conta.corrigido)
    var detalhes = [conta.meses == 0 ? "vendendo hoje" : "vendendo daqui a \(conta.meses) \(conta.meses == 1 ? "mês" : "meses")",
                    "banco paga \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))%"]
    if conta.tir != nil && conta.multiplicador >= 1 { detalhes.append("rende \(virgula(conta.multiplicador, 1))× o banco") }
    if conta.novaDemais { detalhes.append("obra com menos de 1 mês — % ao mês ainda não diz muito") }
    var tabela = [
        linha("Custo até a venda", moeda(conta.bruto), moeda(conta.corrigido)),
        linha("Venda", moeda(conta.venda), moeda(conta.venda)),
        linha("Lucro", din(rb.lucro), din(rc.lucro), sinais: (rb.lucro, rc.lucro), destaque: true),
        linha("% sobre o custo", pct1(rb.pctCusto), pct1(rc.pctCusto), sinais: (rb.pctCusto, rc.pctCusto)),
        linha("% sobre a venda", pct1(rb.pctVenda), pct1(rc.pctVenda), sinais: (rb.pctVenda, rc.pctVenda)),
        linha("Rendimento ao mês", taxa2(conta.tir), taxa2(conta.acima)),
    ]
    if let area, area > 0 {
        tabela.append(linha("Preço por m² (\(numeroJS(area).replacingOccurrences(of: ".", with: ",")) m²)", moeda(conta.venda / area),
                            moeda(conta.venda / area)))
    }
    return TextosDoSimulador(veredito: conta.vale ? "Vale a pena" : "Rende menos que o banco",
                             taxa: conta.tir.map { virgula($0, 2) + "% ao mês" } ?? "—", detalhes: detalhes, tabela: tabela)
}

/* A faixa "Onde a sua venda cai" (regra nova do app, sem vetor do site: o site não tem a faixa). Vem do mockup aprovado da
   etapa 4 (parte2.js, `telaSimula`): a escala começa 3% abaixo do menor entre o custo e a venda e termina 3% acima do maior
   entre o empate e a venda, para nenhuma marca encostar na borda. O empate é o custo corrigido até a venda: vendendo por
   esse valor, a obra rendeu o mesmo que o banco. */

/// Cada marca da faixa, na ordem da legenda.
public enum MarcaDaFaixa: String, Sendable, CaseIterable {
    case custo, empate, venda
}

public struct LinhaDaFaixa: Equatable, Sendable {
    public let marca: MarcaDaFaixa
    /// "custo (bruto)", "empata com o banco" ou "sua venda".
    public let rotulo: String
    /// O valor inteiro, como "R$ 842.317,45".
    public let valor: String
    /// Onde a marca cai na faixa, de 0 (a borda esquerda) a 1.
    public let fracao: Double
}

public struct FaixaDoSimulador: Equatable, Sendable {
    /// Custo, empate e venda, nesta ordem.
    public let linhas: [LinhaDaFaixa]
    /// A venda passa do empate: a zona hachurada, do empate até o fim da faixa, é "acima do banco".
    public let acima: Bool
    /// "acima do banco" ou "abaixo do banco".
    public let pilula: String
    /// O que o VoiceOver lê na faixa, num elemento só.
    public let falado: String
}

/// A faixa de uma conta do simulador.
public func faixaSimulador(_ conta: ContaDoSimulador) -> FaixaDoSimulador {
    let inicio = min(conta.bruto, conta.venda) * 0.97
    let fim = max(conta.corrigido, conta.venda) * 1.03
    func fracao(_ valor: Double) -> Double { fim > inicio ? (valor - inicio) / (fim - inicio) : 0 }
    func linha(_ marca: MarcaDaFaixa, _ rotulo: String, _ valor: Double) -> LinhaDaFaixa {
        LinhaDaFaixa(marca: marca, rotulo: rotulo, valor: moeda(valor), fracao: fracao(valor))
    }
    return FaixaDoSimulador(
        linhas: [linha(.custo, "custo (bruto)", conta.bruto), linha(.empate, "empata com o banco", conta.corrigido),
                 linha(.venda, "sua venda", conta.venda)],
        acima: conta.vale, pilula: conta.vale ? "acima do banco" : "abaixo do banco",
        falado: "Custo \(moeda(conta.bruto)), empata com o banco em \(moeda(conta.corrigido)), sua venda \(moeda(conta.venda))")
}

/* O veredito no app (mockup da etapa 4, parte2.js, `telaSimula`): os textos são os do site (`textosSimulador`), arrumados
   para o bloco sólido. A taxa vem partida em número e unidade, porque o número é o protagonista do bloco; e os detalhes,
   que o site junta com " · ", vêm em linhas: quando vende, o banco com o "rende N× o banco" e, na obra com menos de 1 mês,
   o aviso numa linha só dele. */
public struct VereditoNaTela: Equatable, Sendable {
    /// A venda passa do custo corrigido: o bloco é o verde; senão, o âmbar.
    public let vale: Bool
    /// "Vale a pena" ou "Rende menos que o banco".
    public let titulo: String
    /// "3,52", ou "—" na obra com menos de 1 mês.
    public let numero: String
    /// "% ao mês"; nil sem taxa.
    public let unidade: String?
    public let linhas: [String]
    /// O bloco inteiro para o VoiceOver, num elemento só.
    public let falado: String
}

public func vereditoNaTela(_ conta: ContaDoSimulador, taxa: Double) -> VereditoNaTela {
    let site = textosSimulador(conta, taxa: taxa, area: nil)
    // "3,52% ao mês" vira "3,52" e "% ao mês"; o "—" da obra com menos de 1 mês fica inteiro, sem unidade.
    let corte = site.taxa.firstIndex(of: "%")
    let numero = corte.map { String(site.taxa[..<$0]) } ?? site.taxa
    let unidade = corte.map { String(site.taxa[$0...]) }
    // Os detalhes do site, na ordem: quando vende, o banco, o "rende N× o banco" (só quando rende) e o aviso da obra nova.
    var detalhes = site.detalhes
    let aviso = conta.novaDemais ? detalhes.popLast() : nil
    let doBanco = detalhes.dropFirst().joined(separator: " · ")
    let linhas = Array(detalhes.prefix(1)) + (doBanco.isEmpty ? [] : [doBanco]) + (aviso.map { [$0] } ?? [])
    return VereditoNaTela(vale: conta.vale, titulo: site.veredito, numero: numero, unidade: unidade, linhas: linhas,
                          falado: ([site.veredito, unidade == nil ? "sem taxa ao mês" : site.taxa] + site.detalhes)
                              .joined(separator: ", "))
}

/* Os campos do "Vale a pena?" e o que a tela mostra com eles. Moram na aba enquanto o app está aberto (spec da etapa 4,
   "Dados e estado"), e o comportamento é o do site (app.js, `simulaCompute`): enquanto a pessoa não digitou, o preço
   acompanha a venda estimada da obra escolhida; depois de digitar, vale o digitado, mesmo trocando de obra; os meses
   começam em 0, como o campo do site, e andam de 0 a 120. */
public struct CamposDoSimulador: Equatable, Sendable {
    /// A obra escolhida na lista; nil até a pessoa escolher, e aí vale a primeira elegível.
    public var obraId: String?
    /// O preço digitado, em reais; nil enquanto a pessoa não digitou. Zero é o campo apagado.
    public var precoDigitado: Double?
    /// Daqui a quantos meses vende.
    public private(set) var meses = 0

    public init() {}

    /// O − e o + dos meses, presos entre 0 e `mesesSimulador`.
    public mutating func andarMeses(_ passo: Int) {
        meses = min(mesesSimulador, max(0, meses + passo))
    }
}

/* O preço nas teclas do "Vale a pena?" (decisões do Giovani de 24/11/2026; o mockup só desenha as teclas com o campo vazio).
   As teclas abrem com o valor do campo à vista; a primeira tecla o substitui: a digitação parte do zero, e não do valor que
   estava, que quase sempre é a venda estimada (com os centavos entrando pela direita, um dígito a mais faria de
   R$ 1.450.000,00 R$ 14.500.000,0X). O OK sem digitar deixa os campos como estavam, com o preço ainda acompanhando a venda
   estimada da obra: enquanto a pessoa não digita, nada é gravado nos campos. Vale enquanto as teclas estão abertas; ao abrir
   de novo, começa outro. */
public struct PrecoNasTeclas: Equatable, Sendable {
    /// Os centavos digitados desde que as teclas abriram: zero até a primeira tecla, e é dele que ela parte.
    public private(set) var centavos = 0
    /// A pessoa já digitou desde que as teclas abriram.
    public private(set) var digitou = false

    public init() {}

    /// Uma tecla: devolve o preço novo, em reais, para o campo, ou nil quando a tecla não muda nada. O apagar como primeira
    /// tecla limpa o campo ("apagar limpa o campo", decisão do Giovani de 24/11); as outras seguem a regra do teclado de
    /// valor, a partir do zero. O 0 e o 00 como primeira tecla não mudam nada: sobre eles, ele não decidiu.
    public mutating func tocar(_ tecla: TeclaDeValor) -> Double? {
        if tecla == .apagar && !digitou { return digitar(0) }
        let novo = aplicarTecla(centavos, tecla)
        guard novo != centavos else { return nil }
        return digitar(novo)
    }

    /// As teclas mudaram o valor: guarda os centavos e devolve o preço, em reais, para o campo. Zero é o campo apagado.
    public mutating func digitar(_ centavos: Int) -> Double {
        self.centavos = max(0, centavos)
        digitou = true
        return centavosParaReais(self.centavos)
    }
}

/// O que a tela do "Vale a pena?" mostra.
public struct SimulacaoNaTela: Equatable, Sendable {
    /// As obras da lista "Obra", na ordem do documento; vazia, a tela diz "— crie uma obra com gastos —".
    public let elegiveis: [Obra]
    /// A obra da conta: a escolhida enquanto elegível; senão, a primeira.
    public let obra: Obra?
    /// O preço do campo: o digitado ou, sem digitar, a venda estimada da obra; nil é o campo vazio.
    public let preco: Double?
    public let meses: Int
    /// O − e o + nos limites.
    public let podeMenos: Bool
    public let podeMais: Bool
    /// nil sem obra ou sem preço: a tela diz "Digite o preço de venda pra ver a conta."
    public let conta: ContaDoSimulador?
    public let veredito: VereditoNaTela?
    public let textos: TextosDoSimulador?
    public let faixa: FaixaDoSimulador?
}

/// A tela do "Vale a pena?" para os campos de agora.
public func simulacaoNaTela(_ campos: CamposDoSimulador, obras: [Obra], hoje: String, taxa: Double) -> SimulacaoNaTela {
    let lista = obrasSimulador(obras, escolhida: campos.obraId)
    let obra = lista.elegiveis.first { $0.id == lista.escolhida }
    // O campo apagado (zero) fica vazio: não volta para a estimada, como o campo já tocado do site.
    let preco = (campos.precoDigitado ?? obra.flatMap(precoInicialSimulador)).flatMap { $0 > 0 ? $0 : nil }
    let conta = obra.flatMap { o in preco.flatMap { contaSimulador(o, venda: $0, meses: campos.meses, hoje: hoje, taxa: taxa) } }
    return SimulacaoNaTela(elegiveis: lista.elegiveis, obra: obra, preco: preco, meses: campos.meses, podeMenos: campos.meses > 0,
                           podeMais: campos.meses < mesesSimulador, conta: conta,
                           veredito: conta.map { vereditoNaTela($0, taxa: taxa) },
                           textos: conta.map { textosSimulador($0, taxa: taxa, area: obra?.areaM2) }, faixa: conta.map(faixaSimulador))
}
