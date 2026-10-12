import Foundation
import FirebaseFirestore
import CusttaNucleo

/* O TransporteDados do Sincronizador sobre o Firestore: fino de propósito. A regra mora no
   núcleo; aqui só a conversão de tipos e de códigos de erro. Os retornos chegam na fila
   principal (BancoFirebase põe dispatchQueue = .main), e leitura e gravação passam por
   `banco.quandoPronto`, que segura tudo enquanto o cache está sendo limpo. */
@MainActor
final class TransporteFirebase: TransporteDados {
    private let banco: BancoFirebase

    init(banco: BancoFirebase) { self.banco = banco }

    /// A escuta começa quando o banco está pronto; cancelada antes disso, nem começa.
    private final class Escuta: Cancelavel {
        var registro: ListenerRegistration?
        var cancelada = false
        func cancelar() {
            cancelada = true
            registro?.remove()
            registro = nil
        }
    }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let escuta = Escuta()
        banco.quandoPronto { db in
            guard !escuta.cancelada else { return }
            let documento = db.collection("dados").document(uid)
            escuta.registro = documento.addSnapshotListener(includeMetadataChanges: true) { snap, erro in
                MainActor.assumeIsolated {
                    if let erro { aoFalhar(Self.codigo(erro)); return }
                    guard let snap else { return }
                    let doCache = snap.metadata.isFromCache, pendente = snap.metadata.hasPendingWrites
                    guard let bruto = snap.data() else {
                        aoReceber(Instantaneo(dados: nil, doCache: doCache, gravacaoPendente: pendente))
                        return
                    }
                    guard let dados = Self.valor(bruto) else { aoFalhar("formato-desconhecido"); return }
                    aoReceber(Instantaneo(dados: dados, doCache: doCache, gravacaoPendente: pendente))
                }
            }
        }
        return escuta
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        banco.quandoPronto { db in
            guard var dados = blob.paraFoundation as? [String: Any] else { concluir("invalid-argument"); return }
            dados["_atualizado"] = FieldValue.serverTimestamp()
            db.collection("dados").document(uid).setData(dados) { erro in
                MainActor.assumeIsolated { concluir(erro.map(Self.codigo)) }
            }
        }
    }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        banco.quandoPronto { db in
            db.waitForPendingWrites { erro in
                MainActor.assumeIsolated { concluir(erro.map(Self.codigo)) }
            }
        }
    }

    /// O documento como o site o lê: sem `_atualizado` (cloud.js apaga). nil se houver tipo que o
    /// JSON não tem (data, referência, bytes): a leitura falha com "formato-desconhecido" e nada é
    /// gravado por cima. Nenhum dos dois apps grava esses tipos em `dados/{uid}`.
    nonisolated static func valor(_ dados: [String: Any]) -> ValorJSON? {
        var dados = dados
        dados.removeValue(forKey: "_atualizado")
        return ValorJSON(foundation: dados)
    }

    nonisolated static func codigo(_ erro: Error) -> String {
        let n = erro as NSError
        return codigoDeErroFirestore(dominio: n.domain, codigo: n.code)
    }
}
