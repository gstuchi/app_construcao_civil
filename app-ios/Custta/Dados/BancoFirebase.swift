import Foundation
import os
import FirebaseCore
import FirebaseFirestore

/// Diagnóstico no registro do sistema (Console do Mac, sysdiagnose): a marca de limpeza que sobra fica anotada.
private let registro = Logger(subsystem: "br.com.custta.app", category: "banco")

/// O que a conta lê de um documento (`perfis/{uid}`): se existe e os campos de texto. Sendable, para atravessar a
/// espera da leitura.
struct Documento: Sendable, Equatable {
    let existe: Bool
    let textos: [String: String]
}

/* Acesso ao Firestore do app. Sair da conta encerra a instância para limpar o cache, e o SDK
   devolve uma instância nova na próxima chamada; por isso ninguém guarda a instância: todo mundo
   pede aqui, e cada instância nova recebe as configurações antes do primeiro uso.

   A limpeza segue o cloud.js: a marca persistida (`chaveLimpeza`) é gravada antes do signOut e só
   sai quando o cache foi apagado. Se o app fechar no meio, a próxima abertura termina a limpeza
   antes de qualquer leitura. Durante uma limpeza, quem vai ler ou gravar espera na fila de
   `quandoPronto`, na ordem de chegada. Se a limpeza falhar (no sair ou na abertura), a fila continua
   presa e o banco fica bloqueado até `tentarLimparDeNovo` dar certo, como o `cacheBloqueado` do
   cloud.js: soltar a fila com o cache velho apagaria, na abertura seguinte, gravações sem rede da
   sessão nova. */
@MainActor
final class BancoFirebase {
    static let chaveLimpeza = "custta-limpar-cache"

    private let app: FirebaseApp
    private let emulador: (host: String, porta: Int)?
    private let preferencias: UserDefaults
    /// Apaga o cache de uma instância encerrada ou ainda sem uso (os testes injetam a falha).
    private let apagar: @MainActor (Firestore) async throws -> Void
    /// Lê um documento no SDK (os testes injetam um servidor que nunca responde).
    private let leitor: Leitor
    typealias Leitor = @MainActor (DocumentReference, FirestoreSource, @escaping @MainActor (Documento?, Error?) -> Void) -> Void
    /// Leituras pedidas que o SDK ainda não respondeu.
    private var leiturasEmVoo: [UUID: CheckedContinuation<Documento, Error>] = [:]
    private weak var configurada: Firestore?
    /// Limpeza em andamento (a retomada na abertura ou a de um "sair"), ou bloqueada por uma falha.
    private var ocupado = false
    private var esperando: [@MainActor (Firestore) -> Void] = []
    private var ouvintesDoBloqueio: [@MainActor (Bool) -> Void] = []
    /// A limpeza falhou: a fila de `quandoPronto` fica presa e a marca, de pé, até `tentarLimparDeNovo` dar certo.
    private(set) var bloqueado = false {
        didSet { if bloqueado != oldValue { ouvintesDoBloqueio.forEach { $0(bloqueado) } } }
    }

    init(app: FirebaseApp, emulador: (host: String, porta: Int)? = nil, preferencias: UserDefaults = .standard,
         apagar: @escaping @MainActor (Firestore) async throws -> Void = { try await $0.clearPersistence() },
         leitor: @escaping Leitor = BancoFirebase.lerNoSDK) {
        self.app = app
        self.emulador = emulador
        self.preferencias = preferencias
        self.apagar = apagar
        self.leitor = leitor
        if preferencias.bool(forKey: Self.chaveLimpeza) {
            ocupado = true
            Task { [weak self] in await self?.terminarLimpezaInterrompida() }
        }
    }

    var limpezaPendente: Bool { preferencias.bool(forKey: Self.chaveLimpeza) }

    /// Avisa a cada mudança do bloqueio; quem se inscreve recebe o estado atual logo em seguida.
    func observarBloqueio(_ aoMudar: @escaping @MainActor (Bool) -> Void) {
        ouvintesDoBloqueio.append(aoMudar)
        let atual = bloqueado
        Task { @MainActor in aoMudar(atual) }
    }

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

    static let lerNoSDK: Leitor = { ref, fonte, fim in
        ref.getDocument(source: fonte) { doc, erro in
            MainActor.assumeIsolated {
                fim(doc.map { Documento(existe: $0.exists, textos: ($0.data() ?? [:]).compactMapValues { $0 as? String }) }, erro)
            }
        }
    }

    /// Lê `caminho` depois de uma limpeza em andamento, na instância do momento. Se um `sair` encerrar a instância
    /// com a leitura em voo, ela responde "cancelled".
    func ler(_ caminho: String, fonte: FirestoreSource = .default) async throws -> Documento {
        await aguardarPronto()
        let id = UUID()
        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<Documento, Error>) in
            leiturasEmVoo[id] = c
            leitor(firestore().document(caminho), fonte) { [weak self] documento, erro in
                guard let c = self?.leiturasEmVoo.removeValue(forKey: id) else { return }
                if let documento { c.resume(returning: documento) } else { c.resume(throwing: erro ?? ErroConta(codigo: "unknown")) }
            }
        }
    }

    var leiturasPendentes: Int { leiturasEmVoo.count }

    /// Antes do signOut: se o app fechar daqui até o fim da limpeza, a próxima abertura termina.
    func marcarLimpeza() { preferencias.set(true, forKey: Self.chaveLimpeza) }
    func desmarcarLimpeza() { preferencias.removeObject(forKey: Self.chaveLimpeza) }

    /// Encerra a instância e apaga o cache persistente (o IndexedDB do site); tira a marca no fim e solta a fila.
    /// Falhou: a marca fica, a fila continua presa e o banco fica bloqueado até `tentarLimparDeNovo`.
    func limparCache() async throws {
        ocupado = true
        do { try await encerrarEApagar() } catch {
            registro.error("limpeza do cache falhou; bloqueado até tentar de novo: \(String(describing: error), privacy: .public)")
            bloqueado = true
            throw error
        }
        liberar()
    }

    /// "Tentar limpar novamente": a limpeza que falhou, de novo. Dando certo, solta a fila e tira o bloqueio.
    func tentarLimparDeNovo() async throws {
        guard bloqueado else { return }
        do { try await encerrarEApagar() } catch {
            registro.error("nova tentativa de limpar o cache falhou: \(String(describing: error), privacy: .public)")
            throw error
        }
        bloqueado = false
        liberar()
    }

    private func encerrarEApagar() async throws {
        // O terminate corta as leituras em voo e o SDK nunca as responde (uma tarefa da conta ficaria pendurada).
        let cortadas = leiturasEmVoo
        leiturasEmVoo = [:]
        cortadas.values.forEach { $0.resume(throwing: ErroConta(codigo: "cancelled")) }
        let db = firestore()
        try await db.terminate()
        try await apagar(db)
        cacheApagado()
    }

    private func terminarLimpezaInterrompida() async {
        registro.notice("limpeza do cache interrompida encontrada na abertura; terminando antes de ler")
        do {
            try await apagar(firestore())      // instância nova, ainda sem uso
            cacheApagado()
        } catch {
            registro.error("limpeza retomada falhou; bloqueado até tentar de novo: \(String(describing: error), privacy: .public)")
            bloqueado = true
            return
        }
        liberar()
    }

    /// O cache foi apagado: some a marca "o servidor já respondeu" de todas as contas (o aparelho deixou de ter o que ela
    /// garantia) e só depois a da limpeza; se o app fechar no meio, a abertura seguinte limpa de novo e apaga as duas.
    private func cacheApagado() {
        preferencias.removeObject(forKey: MarcaNasPreferencias.chave)
        desmarcarLimpeza()
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
