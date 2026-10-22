import Foundation
import Testing
import FirebaseAuth
@testable import Custta
import CusttaNucleo

/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
   documento e segue os roteiros do site pelas mesmas regras das telas: o dos gastos (lançar no Pix e no cartão
   parcelado, editar um gasto e uma parcela, apagar um gasto e a compra toda), o da obra (criar, editar, marcar como
   pronta, vender, desfazer a venda e apagar), o do orçamento (as respostas da folha pelo rascunho dela, salvar e tirar),
   o das folhas de origem (a edição empurrada no A pagar e no detalhe do tópico pelo rascunho do gasto, e o apagar de um
   gasto só) e o dos afazeres (adicionar pelo conferirAfazer, marcar, desmarcar e apagar, como a tela Afazeres). O núcleo
   confere e monta cada mudança, o estado muda pelas mutações e cada passo grava pelo Sincronizador, como um toque em
   "Salvar", "Confirmar venda" ou "Apagar". Os ids vêm do roteiro, para o site montar o mesmo resultado. O roteiro
   confere depois, com o SDK JavaScript, que o documento é o que o site gravaria com as mesmas respostas e que nada do site
   se perdeu; no orçamento e nos afazeres, antes e a cada passo, e nas folhas, a cada passo, pelo auxiliar do roteiro. */
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
struct CruzadoTests {
    @Test func appSegueOsRoteirosDoSite() async throws {
        let ambiente = ProcessInfo.processInfo.environment
        let u = try await Auth.auth(app: Emulador.app).signIn(withEmail: ambiente["CUSTTA_EMAIL"]!, password: ambiente["CUSTTA_SENHA"]!).user
        let s = Sincronizador(transporte: TransporteFirebase(banco: Emulador.banco), relogio: RelogioDoSistema())
        s.iniciar(uid: u.uid)
        for _ in 0..<200 where !s.dadosCarregados { try await Task.sleep(for: .milliseconds(50)) }
        try #require(s.dadosCarregados, "o app não carregou o documento que o site gravou")
        let roteiro = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO"]).utf8))
        var ids = try #require(ambiente["CUSTTA_IDS"]).split(separator: ",").map(String.init)
        let novoId = { ids.removeFirst() }
        let hoje = try #require(ambiente["CUSTTA_HOJE"])
        var ultima: Gravacao?
        for passo in try #require(roteiro.comoLista) {
            let p = try #require(passo.comoObjeto)
            let acao = try #require(p["acao"]?.comoTexto), obraId = try #require(p["obra"]?.comoTexto)
            let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
            let novo: Estado?
            switch acao {
            case "lancar":
                let entrada = try entradaDoRoteiro(p)
                let conferido = try conferirGasto(entrada, editado: nil, hoje: hoje).get()
                novo = s.estado.lancandoGastos(gastosLancados(entrada, conferido, novoId: novoId), naObra: obraId)
            case "editar":
                let editado = try #require(obra.gastos.first { $0.id == p["gasto"]?.comoTexto })
                let entrada = try entradaDoRoteiro(p)
                let conferido = try conferirGasto(entrada, editado: editado, hoje: hoje).get()
                novo = s.estado.editandoGasto(editado.id, entrada, conferido, naObra: obraId)
            case "apagar":
                novo = s.estado.apagandoGasto(try #require(p["gasto"]?.comoTexto), daObra: obraId)
            default:
                novo = s.estado.apagandoCompra(try #require(p["grupo"]?.comoTexto), daObra: obraId)
            }
            ultima = try s.aplicar(try #require(novo, "o passo \(acao) achou o que mudar"))
        }
        // A obra (parte 3): cada passo como a folha da obra, as ações da fase e a folha da venda gravam.
        let roteiroDaObra = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_OBRA"]).utf8))
        for passo in try #require(roteiroDaObra.comoLista) {
            let p = try #require(passo.comoObjeto)
            let acao = try #require(p["acao"]?.comoTexto), obraId = p["obra"]?.comoTexto ?? ""
            let novo: Estado?
            switch acao {
            case "criar":
                let campos = try camposDoRoteiro(p)
                try #require(conferirObra(campos, nova: true) == nil)
                novo = s.estado.criandoObra(obraNova(campos, id: try #require(p["id"]?.comoTexto), hoje: hoje))
            case "editar":
                let campos = try camposDoRoteiro(p)
                try #require(conferirObra(campos, nova: false) == nil)
                novo = s.estado.editandoObra(obraId, campos)
            case "fase":
                let fase = try #require(p["fase"]?.comoTexto)
                novo = s.estado.mudandoFase(obraId, para: try #require(Fase(rawValue: fase)))
            case "vender":
                let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
                let valor = try #require(p["valor"]?.comoNumero), data = try #require(p["data"]?.comoTexto)
                try #require(conferirVenda(valor: valor, data: data, dataInicio: obra.dataInicio, hoje: hoje) == nil)
                novo = s.estado.registrandoVenda(obraId, valor: valor, data: data)
            case "desfazer":
                novo = s.estado.desfazendoVenda(obraId)
            default:
                novo = s.estado.apagandoObra(obraId)
            }
            ultima = try s.aplicar(try #require(novo, "o passo \(acao) da obra achou o que mudar"))
        }
        try await #require(ultima).confirmada()
        // Os roteiros do gasto e da obra gravaram em seguida, sem leitura no meio: o roteiro guarda esse documento (o passo 0).
        try await pedirConferencia(0)
        // O orçamento (etapa 3): cada passo como a folha grava (o rascunho dela, montado do orçamento do momento, com o modo e as
        // linhas do passo), e o roteiro confere o documento logo depois de o servidor confirmar. A pessoa abre a folha depois de
        // chegar o eco da gravação anterior: o estado já é o documento relido, que a leitura normaliza como a do site.
        let roteiroDoOrcamento = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_ORCAMENTO"]).utf8))
        for (i, passo) in try #require(roteiroDoOrcamento.comoLista).enumerated() {
            try await esperarOEco(s, antesDo: "passo \(i + 1) do orçamento")
            let p = try #require(passo.comoObjeto)
            let obraId = try #require(p["obra"]?.comoTexto)
            let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
            let novo: Estado?
            if p["acao"]?.comoTexto == "tirar" {
                novo = s.estado.tirandoOrcamento(daObra: obraId)
            } else {
                let r = RascunhoDoOrcamento(obra: obra, topicos: topicosDoFormulario(s.estado.config.topicosProprios))
                r.trocarModo(p["modo"]?.comoTexto == "topicos" ? .topicos : .total)
                r.total = reaisParaCentavos(p["total"]?.comoNumero ?? 0)
                for t in r.topicos { r.definir(.topico(t.id), reaisParaCentavos(p["valores"]?.comoObjeto?[t.id]?.comoNumero ?? 0)) }
                let g = r.gravacao
                novo = s.estado.salvandoOrcamento(modo: g.modo, total: g.total, valores: g.valores, naObra: obraId)
            }
            try await s.aplicar(try #require(novo, "o passo \(i + 1) do orçamento achou a obra")).confirmada()
            try await pedirConferencia(i + 1)
        }
        // As folhas de origem (etapa 3, PR 2): cada passo como o A pagar e o detalhe do tópico gravam, também a partir do
        // documento relido. A edição empurrada é o rascunho do gasto (o da folha, montado do gasto), com o que o passo muda
        // por cima, e o "Salvar" dela; o "Apagar" da linha, ou o "só esta parcela" da edição, tira um gasto só.
        let roteiroDasFolhas = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_FOLHAS"]).utf8))
        for (i, passo) in try #require(roteiroDasFolhas.comoLista).enumerated() {
            for _ in 0..<200 {
                if mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore) { break }
                try await Task.sleep(for: .milliseconds(50))
            }
            try #require(mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore), "o eco da gravação antes do passo \(i + 1) das folhas não chegou")
            let p = try #require(passo.comoObjeto)
            let obraId = try #require(p["obra"]?.comoTexto)
            let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
            let gasto = try #require(obra.gastos.first { $0.id == p["gasto"]?.comoTexto }, "o gasto do passo \(i + 1) das folhas")
            let novo: Estado?
            if p["acao"]?.comoTexto == "apagar" {
                novo = s.estado.apagandoGasto(gasto.id, daObra: obraId)
            } else {
                let r = RascunhoDoGasto(obra: obra, editado: gasto, todas: s.estado.obras, proprios: s.estado.config.topicosProprios, hoje: hoje)
                let mudar = try #require(p["mudar"]?.comoObjeto)
                if let topico = mudar["topico"]?.comoTexto { r.topico = topico }
                if let data = mudar["data"]?.comoTexto { r.data = data }
                let entrada = r.entrada
                let conferido = try conferirGasto(entrada, editado: r.editado, hoje: hoje).get()
                novo = s.estado.editandoGasto(gasto.id, entrada, conferido, naObra: obraId)
            }
            try await s.aplicar(try #require(novo, "o passo \(i + 1) das folhas achou o gasto")).confirmada()
            try await pedirConferencia(i + 1, de: "folhas")
        }
        // Os afazeres (etapa 3, PR 3), depois do orçamento e das folhas inteiros e do mesmo jeito: cada passo como a tela
        // Afazeres grava (o texto pelo conferirAfazer, o círculo que marca e desmarca, o arrastar que apaga), a partir do
        // documento relido, e o roteiro confere o documento logo depois de o servidor confirmar; antes do primeiro, guarda o
        // documento (o passo 0).
        try await pedirConferencia(0, de: "afazeres")
        let roteiroDosAfazeres = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_AFAZERES"]).utf8))
        for (i, passo) in try #require(roteiroDosAfazeres.comoLista).enumerated() {
            try await esperarOEco(s, antesDo: "passo \(i + 1) dos afazeres")
            let p = try #require(passo.comoObjeto)
            let acao = try #require(p["acao"]?.comoTexto), obraId = try #require(p["obra"]?.comoTexto)
            let novo: Estado?
            switch acao {
            case "adicionar":
                guard case .ok(let texto) = conferirAfazer(try #require(p["texto"]?.comoTexto)) else {
                    Issue.record("o afazer do passo \(i + 1) não passou no conferirAfazer"); return
                }
                novo = s.estado.adicionandoAfazer(texto, id: try #require(p["id"]?.comoTexto), naObra: obraId)
            case "marcar", "desmarcar":
                let id = try #require(p["afazer"]?.comoTexto)
                let afazer = try #require(s.estado.obras.first(where: { $0.id == obraId })?.afazeres.first(where: { $0.id == id }), "o afazer \(id)")
                try #require(afazer.feito == (acao == "desmarcar"), "\(acao) \(id): o afazer no estado de antes")
                novo = s.estado.alternandoAfazer(id, naObra: obraId)
            default:
                novo = s.estado.apagandoAfazer(try #require(p["afazer"]?.comoTexto), daObra: obraId)
            }
            try await s.aplicar(try #require(novo, "o passo \(i + 1) dos afazeres achou o que mudar")).confirmada()
            try await pedirConferencia(i + 1, de: "afazeres")
        }
        s.parar()
    }

    /// Espera o eco da gravação anterior: a pessoa abre a folha ou a tela depois de ele chegar, e o estado já é o documento
    /// relido, que a leitura normaliza como a do site.
    private func esperarOEco(_ s: Sincronizador, antesDo passo: String) async throws {
        for _ in 0..<200 {
            guard !mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore) else { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore), "o eco da gravação antes do \(passo) não chegou")
    }

    /// Pede ao roteiro que confira o documento do momento: o do passo n do orçamento, ou o de antes dele (0), o do passo n
    /// das folhas, e o do passo n dos afazeres, ou o de antes deles (0).
    private func pedirConferencia(_ n: Int, de roteiro: String = "orcamento") async throws {
        var pedido = URLRequest(url: try #require(URL(string: "http://127.0.0.1:8124/app/\(roteiro)/\(n)")))
        pedido.httpMethod = "POST"
        let (corpo, resposta) = try await URLSession.shared.data(for: pedido)
        #expect((resposta as? HTTPURLResponse)?.statusCode == 200, "\(String(decoding: corpo, as: UTF8.self))")
    }

    private func camposDoRoteiro(_ passo: [String: ValorJSON]) throws -> CamposDaObra {
        let c = try #require(passo["campos"]?.comoObjeto)
        return CamposDaObra(nome: try #require(c["nome"]?.comoTexto), dataInicio: c["dataInicio"]?.comoTexto ?? "",
                            valorEstimadoVenda: c["valorEstimadoVenda"]?.comoNumero ?? 0, areaM2: c["areaM2"]?.comoNumero ?? 0,
                            orcamento: c["orcamento"]?.comoNumero ?? 0)
    }

    private func entradaDoRoteiro(_ passo: [String: ValorJSON]) throws -> EntradaDoGasto {
        let e = try #require(passo["entrada"]?.comoObjeto)
        return EntradaDoGasto(valor: try #require(e["valor"]?.comoNumero), topico: try #require(e["topico"]?.comoTexto),
                              descricao: e["descricao"]?.comoTexto ?? "", data: e["data"]?.comoTexto ?? "",
                              pagamento: try #require(e["pagamento"]?.comoTexto), parcelas: Int(e["parcelas"]?.comoNumero ?? 1),
                              juros: e["juros"]?.comoNumero ?? 0)
    }
}
