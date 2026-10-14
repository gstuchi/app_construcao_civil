import Foundation

/* O que os formulários do site gravam (dados.js): a conferência na ordem do formulário e os objetos que vão para o
   documento. O app grava exatamente o que o site gravaria com as mesmas respostas; cada regra tem caso nos vetores. */

/// Erro de um formulário. Sem mensagem, a tela volta ao campo (o valor do gasto, o nome da obra) sem texto, como o site.
public struct ErroDeFormulario: Error, Equatable, Sendable {
    public let campo: String
    public let mensagem: String?
    public init(campo: String, mensagem: String? = nil) { self.campo = campo; self.mensagem = mensagem }
}

/// O que a pessoa respondeu no formulário do gasto: valor em reais, descrição aparada, parcelas inteiras e os juros já
/// lidos por `lerTaxaCartao` (NaN quando ilegíveis).
public struct EntradaDoGasto: Equatable, Sendable {
    public var valor: Double
    public var topico: String
    public var descricao: String
    /// AAAA-MM-DD; vazia vale a data do gasto em edição, ou hoje.
    public var data: String
    /// "pix" ou "cartao".
    public var pagamento: String
    public var parcelas: Int
    public var juros: Double

    public init(valor: Double, topico: String, descricao: String, data: String, pagamento: String, parcelas: Int = 1, juros: Double = 0) {
        self.valor = valor; self.topico = topico; self.descricao = descricao; self.data = data
        self.pagamento = pagamento; self.parcelas = parcelas; self.juros = juros
    }
}

/// O gasto conferido: o valor que vai para o documento (no cartão, o total com juros), a data (no cartão, o primeiro
/// vencimento), quantas parcelas e o parcelamento do cartão num lançamento novo.
public struct GastoConferido: Equatable, Sendable {
    public let valor: Double
    public let data: String
    public let parcelas: Int
    public let cartao: Parcelamento?
}

/// `conferirGasto` do dados.js: o "Salvar" do gasto na ordem do formulário (valor, descrição, cartão).
public func conferirGasto(_ entrada: EntradaDoGasto, editado: Gasto?, hoje: String) -> Result<GastoConferido, ErroDeFormulario> {
    let valor = entrada.valor
    if !valor.isFinite || valor <= 0 { return .failure(ErroDeFormulario(campo: "valor")) }
    if entrada.descricao.utf16.count > Limites.descricao {
        return .failure(ErroDeFormulario(campo: "descricao", mensagem: "Use até \(Limites.descricao) caracteres."))
    }
    let data = entrada.data.isEmpty ? (editado?.data ?? hoje) : entrada.data
    let parcelaDeCompra = editado?.grupoId != nil
    let cartao = entrada.pagamento == "cartao"
    let parcelas = !parcelaDeCompra && cartao && entrada.parcelas != 0 ? entrada.parcelas : 1   // o `parcelas || 1` do site
    var parcelamento: Parcelamento?
    if editado == nil && cartao {
        // A data crua, como a prévia do site (atualizarCartao): no cartão, a data vazia não vira hoje, é recusada.
        guard let p = parcelamentoCartao(valor, entrada.parcelas, entrada.juros, entrada.data) else {
            return .failure(ErroDeFormulario(campo: "cartao", mensagem: "Confira valor, parcelas, data e taxa de juros"))
        }
        parcelamento = p
    }
    return .success(GastoConferido(valor: parcelamento?.totalCompra ?? valor, data: data, parcelas: parcelas, cartao: parcelamento))
}

/// `gastosLancados` do dados.js: no cartão parcelado, um gasto por parcela, com o mesmo `grupoId` (o primeiro id pedido)
/// e `parcela {n, de}`; no cartão, as condições da compra em `jurosCartao`; senão, um gasto só.
public func gastosLancados(_ entrada: EntradaDoGasto, _ conferido: GastoConferido, novoId: () -> String) -> [Gasto] {
    var condicoes: [String: ValorJSON] = [:]
    if let c = conferido.cartao {
        condicoes["jurosCartao"] = .objeto(["taxaMensal": .numero(c.taxaMensal), "valorCompra": .numero(c.valorCompra),
                                            "nParcelas": .numero(Double(c.nParcelas)), "totalCompra": .numero(c.totalCompra),
                                            "jurosCompra": .numero(c.jurosCompra)])
    }
    if conferido.parcelas > 1, let c = conferido.cartao {
        let grupoId = novoId()
        return c.parcelas.enumerated().map { i, p in
            var campos: [String: ValorJSON] = ["id": .texto(novoId()), "valor": .numero(p.valor), "topico": .texto(entrada.topico),
                                               "descricao": .texto(entrada.descricao), "data": .texto(p.data), "pagamento": .texto("cartao"),
                                               "grupoId": .texto(grupoId),
                                               "parcela": .objeto(["n": .numero(Double(i + 1)), "de": .numero(Double(conferido.parcelas))])]
            campos.merge(condicoes) { _, novo in novo }
            return Gasto(campos: campos)
        }
    }
    var campos: [String: ValorJSON] = ["id": .texto(novoId()), "valor": .numero(conferido.valor), "topico": .texto(entrada.topico),
                                       "descricao": .texto(entrada.descricao), "data": .texto(conferido.data),
                                       "pagamento": .texto(entrada.pagamento)]
    campos.merge(condicoes) { _, novo in novo }
    return [Gasto(campos: campos)]
}

/// `gastoEditado` do dados.js: valor, tópico, descrição e data; o pagamento só fora de uma compra parcelada; fora do
/// cartão, sem `jurosCartao`. Os outros campos, inclusive os que o app não conhece, ficam como estavam.
public func gastoEditado(_ gasto: Gasto, _ entrada: EntradaDoGasto, _ conferido: GastoConferido) -> Gasto {
    var g = gasto
    g.valor = conferido.valor
    g.topico = entrada.topico
    g.descricao = entrada.descricao
    g.data = conferido.data
    if gasto.grupoId == nil { g.pagamento = entrada.pagamento }
    if entrada.pagamento != "cartao" { g.campos["jurosCartao"] = nil }
    return g
}
