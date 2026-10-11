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
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)

        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        #expect(!usou.ligada, "ninguém lê antes de a limpeza terminar")
        await banco.aguardarPronto()
        #expect(usou.ligada)
        #expect(!banco.limpezaPendente, "a abertura terminou a limpeza e tirou a marca")
    }

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
