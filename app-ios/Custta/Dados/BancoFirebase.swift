import Foundation
import os
import FirebaseCore
import FirebaseFirestore

/// Diagnóstico no registro do sistema (Console do Mac, sysdiagnose): a marca de limpeza que sobra fica anotada.
private let registro = Logger(subsystem: "br.com.custta.app", category: "banco")

/* Acesso ao Firestore do app. Sair da conta encerra a instância para limpar o cache, e o SDK
   devolve uma instância nova na próxima chamada; por isso ninguém guarda a instância: todo mundo
   pede aqui, e cada instância nova recebe as configurações antes do primeiro uso.

   A limpeza segue o cloud.js: a marca persistida (`chaveLimpeza`) é gravada antes do signOut e só
   sai quando o cache foi apagado. Se o app fechar no meio, a próxima abertura termina a limpeza
   antes de qualquer leitura. Durante uma limpeza, quem vai ler ou gravar espera na fila de
   `quandoPronto`, na ordem de chegada. */
@MainActor
final class BancoFirebase {
    static let chaveLimpeza = "custta-limpar-cache"

    private let app: FirebaseApp
    private let emulador: (host: String, porta: Int)?
    private let preferencias: UserDefaults
    private weak var configurada: Firestore?
    /// Limpeza em andamento (a retomada na abertura ou a de um "sair").
    private var ocupado = false
    private var esperando: [@MainActor (Firestore) -> Void] = []

    init(app: FirebaseApp, emulador: (host: String, porta: Int)? = nil, preferencias: UserDefaults = .standard) {
        self.app = app
        self.emulador = emulador
        self.preferencias = preferencias
        if preferencias.bool(forKey: Self.chaveLimpeza) {
            ocupado = true
            Task { [weak self] in await self?.terminarLimpezaInterrompida() }
        }
    }

    var limpezaPendente: Bool { preferencias.bool(forKey: Self.chaveLimpeza) }

    /// Roda `uso` com o Firestore pronto: na hora, se não há limpeza; senão, logo que ela termina,
    /// na ordem de chegada (gravações saem na mesma ordem em que o Sincronizador mandou).
    func quandoPronto(_ uso: @escaping @MainActor (Firestore) -> Void) {
        if ocupado { esperando.append(uso) } else { uso(firestore()) }
    }

    /// Espera uma limpeza em andamento terminar (para quem usa o Firestore com async/await).
    func aguardarPronto() async {
        guard ocupado else { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            esperando.append { _ in c.resume() }
        }
    }

    /// A instância atual, configurada antes do primeiro uso. Instância já configurada nunca é
    /// reconfigurada: mudar `settings` de uma instância em uso (ou em encerramento) derruba o app.
    func firestore() -> Firestore {
        let db = Firestore.firestore(app: app)
        if configurada !== db {
            let ajustes = db.settings
            ajustes.cacheSettings = PersistentCacheSettings()
            ajustes.dispatchQueue = .main
            if let emulador {
                ajustes.host = "\(emulador.host):\(emulador.porta)"
                ajustes.isSSLEnabled = false
            }
            db.settings = ajustes
            configurada = db
        }
        return db
    }

    /// Antes do signOut: se o app fechar daqui até o fim da limpeza, a próxima abertura termina.
    func marcarLimpeza() { preferencias.set(true, forKey: Self.chaveLimpeza) }
    func desmarcarLimpeza() { preferencias.removeObject(forKey: Self.chaveLimpeza) }

    /// Encerra a instância e apaga o cache persistente (o IndexedDB do site); tira a marca no fim.
    /// Falhou no meio: a marca fica e a próxima abertura termina a limpeza.
    func limparCache() async throws {
        ocupado = true
        defer { liberar() }
        do {
            let db = firestore()
            try await db.terminate()
            try await db.clearPersistence()
            desmarcarLimpeza()
        } catch {
            registro.error("limpeza do cache falhou; a marca fica para a próxima abertura: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private func terminarLimpezaInterrompida() async {
        registro.notice("limpeza do cache interrompida encontrada na abertura; terminando antes de ler")
        defer { liberar() }
        do {
            try await firestore().clearPersistence()      // instância nova, ainda sem uso
            desmarcarLimpeza()
        } catch {
            registro.error("limpeza retomada falhou; a marca fica para a próxima abertura: \(String(describing: error), privacy: .public)")
        }
    }

    private func liberar() {
        ocupado = false
        let fila = esperando
        esperando = []
        guard !fila.isEmpty else { return }
        let db = firestore()
        fila.forEach { $0(db) }
    }
}
