import Foundation
import Testing
import FirebaseFirestore
@testable import Custta
import CusttaNucleo

extension NoEmulador {
    @MainActor
    @Suite struct TransporteFirebaseTests {
        @Test func gravaELeODocumentoInteiroSemPerderCampoDoSite() async throws {
            let u = try await Emulador.novaConta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let blob = ValorJSON.objeto([
                "obras": .lista([.objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .texto("fica"),
                                          "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1500), "data": .texto("2026-01-02"), "nota": .numero(1500.5)])])])]),
                "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
            ])
            let codigo: String? = await withCheckedContinuation { c in transporte.gravar(uid: u.uid, blob: blob) { c.resume(returning: $0) } }
            #expect(codigo == nil)

            var recebido: Instantaneo?
            let escuta = transporte.escutar(uid: u.uid, aoReceber: { if !$0.doCache { recebido = $0 } }, aoFalhar: { Issue.record("leitura falhou: \($0)") })
            for _ in 0..<100 where recebido == nil { try await Task.sleep(for: .milliseconds(50)) }
            escuta.cancelar()
            let dados = try #require(recebido?.dados)
            #expect(canonico(dados) == canonico(blob), "volta igual, sem _atualizado e com o campo que só o site conhece")

            let bruto = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .server).data()
            #expect(bruto?["_atualizado"] is Timestamp, "_atualizado é a hora do servidor")
            let gasto = ((bruto?["obras"] as? [[String: Any]])?.first?["gastos"] as? [[String: Any]])?.first
            #expect((gasto?["valor"] as? NSNumber).map { CFNumberIsFloatType($0) } == false, "1500 vai como inteiro, como o JavaScript grava")
        }

        @Test func rulesRecusamChaveNovaNoBlob() async throws {
            let u = try await Emulador.novaConta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let blob = ValorJSON.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([]), "nova": .numero(1)])])
            let codigo: String? = await withCheckedContinuation { c in transporte.gravar(uid: u.uid, blob: blob) { c.resume(returning: $0) } }
            #expect(codigo == "permission-denied")
            #expect(erroEhTerminal(codigo: codigo))
        }
    }
}

/* Conversão do documento, sem emulador (roda na CI). */
struct ConversaoDoDocumentoTests {
    @Test func atualizadoSaiETipoForaDoJSONRecusaOBlob() {
        let simples: [String: Any] = ["obras": [Any](), "_atualizado": Timestamp(date: Date())]
        #expect(TransporteFirebase.valor(simples) == .objeto(["obras": .lista([])]))
        let comData: [String: Any] = ["obras": [["id": "o1", "quando": Timestamp(date: Date())]]]
        #expect(TransporteFirebase.valor(comData) == nil,
                "Timestamp dentro do blob: recusa ler em vez de virar null e sumir na próxima gravação")
    }
}
