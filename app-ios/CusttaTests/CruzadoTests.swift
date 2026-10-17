import Foundation
import Testing
import FirebaseAuth
@testable import Custta
import CusttaNucleo

/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
   documento e segue os roteiros do site pelas mesmas regras das telas: o dos gastos (lançar no Pix e no cartão
   parcelado, editar um gasto e uma parcela, apagar um gasto e a compra toda) e o da obra (criar, editar, marcar como
   pronta, vender, desfazer a venda e apagar). O núcleo confere e monta cada mudança, o estado muda pelas mutações e
   cada passo grava pelo Sincronizador, como um toque em "Salvar", "Confirmar venda" ou "Apagar". Os ids vêm do
   roteiro, para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o
   que o site gravaria com as mesmas respostas e que nada do site se perdeu. */
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
        s.parar()
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
