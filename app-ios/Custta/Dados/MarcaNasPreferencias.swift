import Foundation
import CusttaNucleo

/// A marca "o servidor já respondeu" de cada conta (`MarcaDoServidor`, do Sincronizador), nas preferências do app. O
/// BancoFirebase a apaga junto com o cache local: as duas dizem o que este aparelho já viu da conta, e uma sem a outra
/// faria o cache vazio de um aparelho limpo passar por conta vazia.
@MainActor
final class MarcaNasPreferencias: MarcaDoServidor {
    static let chave = "custta-servidor-respondeu"
    private let preferencias: UserDefaults

    init(preferencias: UserDefaults = .standard) { self.preferencias = preferencias }

    func respondeu(uid: String) -> Bool { (preferencias.stringArray(forKey: Self.chave) ?? []).contains(uid) }

    func marcar(uid: String) {
        var contas = preferencias.stringArray(forKey: Self.chave) ?? []
        guard !contas.contains(uid) else { return }
        contas.append(uid)
        preferencias.set(contas, forKey: Self.chave)
    }
}
