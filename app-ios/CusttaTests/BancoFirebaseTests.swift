import Foundation
import Testing
import FirebaseCore
import FirebaseFirestore
@testable import Custta

/* A limpeza do cache interrompida (o app fechou no meio de um "sair") termina na abertura seguinte,
   antes de qualquer leitura; se a limpeza falha, a fila fica presa até a nova tentativa dar certo.
   Sem rede e sem emulador: apagar o cache é local (roda na CI). */

@MainActor
struct BancoFirebaseTests {
    @Test func limpezaInterrompidaTerminaAntesDaPrimeiraLeitura() async throws {
        let nome = "limpeza-\(UUID().uuidString.prefix(8).lowercased())"
        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
        let preferencias = try #require(UserDefaults(suiteName: nome))
        preferencias.set(true, forKey: BancoFirebase.chaveLimpeza)
        MarcaNasPreferencias(preferencias: preferencias).marcar(uid: "u1")
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)

        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        #expect(!usou.ligada, "ninguém lê antes de a limpeza terminar")
        await banco.aguardarPronto()
        #expect(usou.ligada)
        #expect(!banco.limpezaPendente, "a abertura terminou a limpeza e tirou a marca")
        #expect(!MarcaNasPreferencias(preferencias: preferencias).respondeu(uid: "u1"), "a limpeza retomada também apaga a marca do servidor")
    }

    @Test func apagarOCacheLevaJuntoAMarcaDoServidor() async throws {
        // A marca diz que o cache sem documento é conta vazia; sem o cache, ela mentiria.
        let nome = "marca-\(UUID().uuidString.prefix(8).lowercased())"
        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
        let preferencias = try #require(UserDefaults(suiteName: nome))
        let marca = MarcaNasPreferencias(preferencias: preferencias)
        marca.marcar(uid: "u1")
        marca.marcar(uid: "u2")
        #expect(marca.respondeu(uid: "u1") && marca.respondeu(uid: "u2") && !marca.respondeu(uid: "u3"))
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)
        banco.marcarLimpeza()
        try await banco.limparCache()
        #expect(!marca.respondeu(uid: "u1") && !marca.respondeu(uid: "u2"), "sem o cache, nenhuma conta fica marcada")
        #expect(!banco.limpezaPendente)
    }

    @Test func desmarcarTiraSoAConta() throws {
        let preferencias = try #require(UserDefaults(suiteName: "desmarcar-\(UUID().uuidString.prefix(8).lowercased())"))
        let marca = MarcaNasPreferencias(preferencias: preferencias)
        marca.marcar(uid: "u1")
        marca.marcar(uid: "u2")
        marca.desmarcar(uid: "u1")
        marca.desmarcar(uid: "u3")
        #expect(!marca.respondeu(uid: "u1") && marca.respondeu(uid: "u2"), "só a conta que apareceu com documento perde a marca")
    }

    @Test func limpezaRetomadaApagaOCacheDeVerdade() async throws {
        // O app fechou no meio de um "sair": gravação só no cache (sem rede), instância encerrada e a marca de pé.
        let nome = "retomada-\(UUID().uuidString.prefix(8).lowercased())"
        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
        let app = try #require(FirebaseApp.app(name: nome))
        let preferencias = try #require(UserDefaults(suiteName: nome))
        let antes = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080), preferencias: preferencias)
        let db = antes.firestore()
        try await db.disableNetwork()
        let ref = db.collection("dados").document(nome)
        gravarSoNoCache(ref)
        #expect(try await ref.getDocument(source: .cache).exists, "a gravação está no cache")
        antes.marcarLimpeza()
        try await db.terminate()
        // A abertura seguinte: o banco novo termina a limpeza antes de qualquer leitura.
        let depois = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080), preferencias: preferencias)
        await depois.aguardarPronto()
        #expect(!depois.limpezaPendente)
        await #expect(throws: (any Error).self, "o cache foi apagado: a leitura só do cache não acha a gravação") {
            try await depois.firestore().collection("dados").document(nome).getDocument(source: .cache)
        }
    }

    @Test func leituraEmVooQuandoOSairEncerraAInstanciaResponde() async throws {
        // O servidor não responde antes do sair e, depois do terminate, o SDK nunca mais responde (visto na T13).
        let nome = "corte-\(UUID().uuidString.prefix(8).lowercased())"
        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080),
                                  preferencias: try #require(UserDefaults(suiteName: nome)), leitor: { _, _, _ in })
        let leitura = Desfecho { _ = try await banco.ler("perfis/\(nome)", fonte: .server) }
        await ate { banco.leiturasPendentes == 1 }
        banco.marcarLimpeza()
        try await banco.limparCache()
        await ate { leitura.terminou }
        #expect(leitura.terminou, "a leitura cortada pelo sair responde, em vez de deixar a tarefa pendurada")
        #expect((leitura.erro as? ErroConta)?.codigo == "cancelled")
        #expect(banco.leiturasPendentes == 0)
    }

    /// Sem rede, a confirmação do servidor nunca vem: fora do contexto assíncrono, o setData sem espera.
    private func gravarSoNoCache(_ ref: DocumentReference) { ref.setData(["obras": []]) }

    /// Banco num app próprio, sem rede (a limpeza só mexe no disco); com `falha` ligada, apagar o cache falha.
    private func bancoQueFalha(marcado: Bool, _ falha: Bandeira) throws -> BancoFirebase {
        let nome = "falha-\(UUID().uuidString.prefix(8).lowercased())"
        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
        let preferencias = try #require(UserDefaults(suiteName: nome))
        if marcado { preferencias.set(true, forKey: BancoFirebase.chaveLimpeza) }
        return BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias,
                             apagar: { db in
                                 if falha.ligada { throw ErroConta(codigo: "disco") }
                                 try await db.clearPersistence()
                             })
    }

    @Test func limpezaQueFalhaAoSairPrendeAFilaAteDarCerto() async throws {
        let falha = Bandeira()
        falha.ligada = true
        let banco = try bancoQueFalha(marcado: false, falha)
        banco.marcarLimpeza()
        await #expect(throws: ErroConta(codigo: "disco")) { try await banco.limparCache() }
        #expect(banco.bloqueado && banco.limpezaPendente, "a marca fica e o banco bloqueia, como o cacheBloqueado do cloud.js")
        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        try await Task.sleep(for: .milliseconds(100))
        #expect(!usou.ligada, "ninguém lê nem grava com o cache velho no aparelho")
        await #expect(throws: ErroConta(codigo: "disco")) { try await banco.tentarLimparDeNovo() }
        #expect(banco.bloqueado && !usou.ligada, "falhou de novo: continua preso")
        falha.ligada = false
        try await banco.tentarLimparDeNovo()
        #expect(usou.ligada && !banco.bloqueado && !banco.limpezaPendente, "deu certo: solta a fila e tira o bloqueio e a marca")
    }

    @Test func limpezaRetomadaQueFalhaNaAberturaBloqueia() async throws {
        let falha = Bandeira()
        falha.ligada = true
        let banco = try bancoQueFalha(marcado: true, falha)
        let viuBloqueio = Bandeira(), viuFim = Bandeira()
        banco.observarBloqueio { if $0 { viuBloqueio.ligada = true } else if viuBloqueio.ligada { viuFim.ligada = true } }
        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        await ate { banco.bloqueado }
        #expect(banco.bloqueado && banco.limpezaPendente && !usou.ligada, "a abertura não terminou a limpeza: ninguém lê")
        falha.ligada = false
        try await banco.tentarLimparDeNovo()
        #expect(usou.ligada && !banco.bloqueado && !banco.limpezaPendente)
        await ate { viuFim.ligada }
        #expect(viuBloqueio.ligada && viuFim.ligada, "quem observa fica sabendo do bloqueio e do fim dele")
    }
}
