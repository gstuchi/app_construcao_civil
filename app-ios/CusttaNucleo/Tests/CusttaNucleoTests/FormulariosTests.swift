import Testing
@testable import CusttaNucleo

extension EntradaDoGasto {
    /// A entrada de um caso dos vetores; juros ilegíveis vêm como null (o NaN do site).
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valor: o["valor"]!.numero, topico: o["topico"]!.comoTexto!, descricao: o["descricao"]!.comoTexto!,
                  data: o["data"]!.comoTexto!, pagamento: o["pagamento"]!.comoTexto!,
                  parcelas: Int(o["parcelas"]!.numero), juros: o["juros"]?.comoNumero ?? .nan)
    }
}

extension Parcelamento {
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valorCompra: o["valorCompra"]!.numero, taxaMensal: o["taxaMensal"]!.numero, nParcelas: Int(o["nParcelas"]!.numero),
                  totalCompra: o["totalCompra"]!.numero, jurosCompra: o["jurosCompra"]!.numero,
                  parcelas: o["parcelas"]!.comoLista!.map { ParcelaGerada(valor: $0.comoObjeto!["valor"]!.numero, data: $0.comoObjeto!["data"]!.comoTexto!) })
    }
}

extension GastoConferido {
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valor: o["valor"]!.numero, data: o["data"]!.comoTexto!, parcelas: Int(o["parcelas"]!.numero),
                  cartao: o["cartao"] == .nulo ? nil : Parcelamento(caso: o["cartao"]!))
    }
    var json: ValorJSON {
        .objeto(["valor": .numero(valor), "data": .texto(data), "parcelas": .numero(Double(parcelas)), "cartao": cartao?.json ?? .nulo])
    }
}

extension ErroDeFormulario {
    var json: ValorJSON {
        var o: [String: ValorJSON] = ["erro": .texto(campo)]
        if let mensagem { o["mensagem"] = .texto(mensagem) }
        return .objeto(o)
    }
}

/// Os ids de um caso, um a cada pedido, na ordem.
@MainActor final class FilaDeIds {
    private var ids: [String]
    init(_ v: ValorJSON) { ids = v.comoLista!.map { $0.comoTexto! } }
    func proximo() -> String { ids.removeFirst() }
}

@MainActor
struct FormulariosTests {
    @Test func conferirGastoNaOrdemDoFormulario() {
        for c in Vetores.casos("dados.conferirGasto") {
            let editado = c.args[1] == .nulo ? nil : Gasto(campos: c.args[1].comoObjeto!)
            let r = conferirGasto(EntradaDoGasto(caso: c.args[0]), editado: editado, hoje: c.args[2].comoTexto!)
            switch r {
            case .success(let g): confere(g.json, c.saida, .exata, c.caso)
            case .failure(let e): confere(e.json, c.saida, .exata, c.caso)
            }
        }
    }

    @Test func gastosLancadosComoOSiteGrava() {
        for c in Vetores.casos("dados.gastosLancados") {
            let fila = FilaDeIds(c.args[2])
            let r = gastosLancados(EntradaDoGasto(caso: c.args[0]), GastoConferido(caso: c.args[1]), novoId: fila.proximo)
            confere(.lista(r.map { .objeto($0.campos) }), c.saida, .exata, c.caso)
        }
    }

    @Test func gastoEditadoComoOSiteGrava() {
        for c in Vetores.casos("dados.gastoEditado") {
            let r = gastoEditado(Gasto(campos: c.args[0].comoObjeto!), EntradaDoGasto(caso: c.args[1]), GastoConferido(caso: c.args[2]))
            confere(.objeto(r.campos), c.saida, .exata, c.caso)
        }
    }
}

extension CamposDaObra {
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(nome: o["nome"]!.comoTexto!, dataInicio: o["dataInicio"]!.comoTexto!, valorEstimadoVenda: o["valorEstimadoVenda"]!.numero,
                  areaM2: o["areaM2"]!.numero, orcamento: o["orcamento"]?.comoNumero ?? 0)
    }
}

struct FormulariosDaObraTests {
    @Test func tetoDeObrasDasRules() {
        #expect(Vetores.casos("dados.LIMITE_OBRAS").first?.saida == .numero(Double(limiteDeObras)))
        for c in Vetores.casos("dados.avisoLimiteDeObras") {
            let r = avisoLimiteDeObras(Int(c.args[0].numero))
            confere(r.map { .objeto(["titulo": .texto($0.titulo), "texto": .texto($0.texto)]) } ?? .nulo, c.saida, .exata, c.caso)
        }
    }

    @Test func conferirObraNaOrdemDoFormulario() {
        for c in Vetores.casos("dados.conferirObra") {
            let r = conferirObra(CamposDaObra(caso: c.args[0]), nova: c.args[1] == .booleano(true))
            confere(r?.json ?? .nulo, c.saida, .exata, c.caso)
        }
    }

    @Test func obraNovaComoOSiteGrava() {
        for c in Vetores.casos("dados.obraNova") {
            confere(.objeto(obraNova(CamposDaObra(caso: c.args[0]), id: c.args[1].comoTexto!, hoje: c.args[2].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func obraEditadaComoOSiteGrava() {
        for c in Vetores.casos("dados.obraEditada") {
            confere(.objeto(obraEditada(c.args[0].comoObjeto!, CamposDaObra(caso: c.args[1]))), c.saida, .exata, c.caso)
        }
    }

    @Test func vendaEntreOInicioEHoje() {
        for c in Vetores.casos("dados.conferirVenda") {
            let r = conferirVenda(valor: c.args[0].numero, data: c.args[1].comoTexto!, dataInicio: c.args[2].comoTexto!, hoje: c.args[3].comoTexto!)
            confere(r?.json ?? .nulo, c.saida, .exata, c.caso)
        }
    }
}

struct ResumoEAssinaturaTests {
    @Test func resumoDoCartaoComOTextoDoSite() {
        #expect(resumoDoCartao(parcelamentoCartao(100, 3, 0, "2026-01-15"))
                == "3x de R$\u{a0}33,33 (última: R$\u{a0}33,34) · Juros do cartão: R$\u{a0}0,00 · Total: R$\u{a0}100,00")
        #expect(resumoDoCartao(parcelamentoCartao(1000, 2, 10, "2026-10-11"))
                == "2x de R$\u{a0}576,19 · Juros do cartão: R$\u{a0}152,38 · Total: R$\u{a0}1.152,38", "o exemplo do teste do site (cartao.cjs)")
        #expect(resumoDoCartao(nil) == "Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês.")
    }

    @Test func assinaturaMudaComQualquerCampo() throws {
        let e = EntradaDoGasto(valor: 1380, topico: "matbasicos", descricao: "Cimento", data: "2026-10-12", pagamento: "pix")
        let c = try conferirGasto(e, editado: nil, hoje: "2026-10-12").get()
        let a = assinaturaDoGasto(obraId: "o1", entrada: e, conferido: c)
        #expect(a == "o1|matbasicos|cimento|138000|2026-10-12|1|")
        var outra = e
        outra.descricao = "Cimento cola"
        #expect(assinaturaDoGasto(obraId: "o1", entrada: outra, conferido: try conferirGasto(outra, editado: nil, hoje: "2026-10-12").get()) != a)
        #expect(assinaturaDoGasto(obraId: "o2", entrada: e, conferido: c) != a)
    }
}

struct TextosDaFolhaDoGastoTests {
    @Test func avisoDaParcelaEAjuda() {
        #expect(avisoDaParcela(Parcela(n: 4, de: 10)) == "Parcela 4/10 de uma compra no cartão — a edição vale só pra esta parcela.")
        #expect(ajudaDoCartao.hasPrefix("0 = sem juros.") && ajudaDoCartao.hasSuffix("A data abaixo é o primeiro vencimento."))
    }

    @Test func condicoesOriginaisComATaxaDoJavaScript() {
        let g = Gasto(campos: ["id": .texto("p"), "jurosCartao": .objeto(["taxaMensal": .numero(2.5), "valorCompra": .numero(1000),
                                                                       "nParcelas": .numero(10), "totalCompra": .numero(1124.6),
                                                                       "jurosCompra": .numero(124.6)])])
        #expect(condicoesOriginais(g) == "Condições originais da compra: 2,5% ao mês · 10x · juros R$\u{a0}124,60 · total R$\u{a0}1.124,60. "
                + "O valor editável já inclui juros; não serão aplicados novamente.")
        #expect(condicoesOriginais(Gasto(campos: ["id": .texto("x")])) == nil)
    }
}
