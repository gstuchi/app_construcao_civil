import Foundation
import Testing
import FirebaseAuth
@testable import Custta
import CusttaNucleo

/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
   documento e segue o roteiro de gastos do site (lançar no Pix e no cartão parcelado, editar um gasto e uma parcela,
   apagar um gasto e a compra toda) pelas mesmas regras das telas: o núcleo confere e monta cada gasto, o estado muda
   pelas mutações e cada passo grava pelo Sincronizador, como um toque em "Salvar" ou "Apagar". Os ids vêm do roteiro,
   para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o que o
   site gravaria com as mesmas respostas e que nada do site se perdeu. */
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
struct CruzadoTests {
    @Test func appSegueORoteiroDeGastosDoSite() async throws {
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
        try await #require(ultima).confirmada()
        s.parar()
    }

    private func entradaDoRoteiro(_ passo: [String: ValorJSON]) throws -> EntradaDoGasto {
        let e = try #require(passo["entrada"]?.comoObjeto)
        return EntradaDoGasto(valor: try #require(e["valor"]?.comoNumero), topico: try #require(e["topico"]?.comoTexto),
                              descricao: e["descricao"]?.comoTexto ?? "", data: e["data"]?.comoTexto ?? "",
                              pagamento: try #require(e["pagamento"]?.comoTexto), parcelas: Int(e["parcelas"]?.comoNumero ?? 1),
                              juros: e["juros"]?.comoNumero ?? 0)
    }
}
