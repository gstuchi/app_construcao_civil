import Foundation
import Testing
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
@testable import Custta
import CusttaNucleo

/* ContaFirebase contra os emuladores (npm run test:app-ios:emuladores). Fora deles, pulam. */
extension NoEmulador {
    @MainActor
    @Suite struct ContaFirebaseTests {
        func conta() -> ContaFirebase { ContaFirebase(app: Emulador.app, banco: Emulador.banco, online: { true }) }

        @Test func criarContaGravaPerfilAceitoPelasRules() async throws {
            let c = conta()
            let email = "cadastro-\(UUID().uuidString.prefix(8).lowercased())@example.com"
            try await c.criarConta(email: email, senha: "Casa2026x", perfil: PerfilCadastro(nome: "Ana", sobrenome: "Lima", origem: "indicacao", origemDetalhe: "Pedro"))
            let uid = try #require(Auth.auth(app: Emulador.app).currentUser?.uid)
            let dados = try #require(try await Emulador.banco.firestore().collection("perfis").document(uid).getDocument(source: .server).data())
            #expect(Set(dados.keys) == ["email", "criado", "tz", "nome", "sobrenome", "origem", "origemDetalhe"])
            #expect(dados["email"] as? String == email)
            #expect((dados["criado"] as? String)?.count == 24, "ISO com milissegundos, como o toISOString do site")
            #expect(await c.lerNome() == "Ana Lima")
            try await c.sair()
        }

        @Test func senhaErradaViraAMensagemDoSite() async throws {
            let c = conta()
            let u = try await Emulador.novaConta()
            try Auth.auth(app: Emulador.app).signOut()
            await #expect(throws: ErroConta.self) { try await c.entrar(email: u.email!, senha: "Errada123") }
            do { try await c.entrar(email: u.email!, senha: "Errada123") }
            catch let e as ErroConta { #expect(mensagemErroSenha(codigo: e.codigo, tela: "login") == "E-mail ou senha incorretos.") }
        }

        @Test func contaGoogleSemPerfilFicaPendenteAteCompletar() async throws {
            let c = conta()
            let sub = UUID().uuidString.lowercased()
            // O emulador do Auth aceita um token "falso" em JSON para os provedores federados.
            let tokenFalso = #"{"sub":"\#(sub)","email":"\#(sub.prefix(8))@example.com","email_verified":true}"#
            _ = try await Auth.auth(app: Emulador.app).signIn(with: GoogleAuthProvider.credential(withIDToken: tokenFalso, accessToken: "x"))
            for _ in 0..<100 where c.usuario?.contaSocial != true { try await Task.sleep(for: .milliseconds(20)) }
            #expect(await c.perfilPendente())
            try await c.completarPerfil(PerfilCadastro(nome: "Gi", origem: "google"))
            #expect(await c.perfilPendente() == false)
            try await c.sair()
        }

        @Test func sairNoMeioDoPerfilPendenteNaoDerrubaOApp() async throws {
            let c = conta()
            let sub = UUID().uuidString.lowercased()
            let tokenFalso = #"{"sub":"\#(sub)","email":"\#(sub.prefix(8))@example.com","email_verified":true}"#
            _ = try await Auth.auth(app: Emulador.app).signIn(with: GoogleAuthProvider.credential(withIDToken: tokenFalso, accessToken: "x"))
            for _ in 0..<100 where c.usuario?.contaSocial != true { try await Task.sleep(for: .milliseconds(20)) }
            /* A fila principal é FIFO: o perfilPendente roda até a leitura do cache e para ali; o sair encerra a
               instância antes de essa leitura voltar. Ler o servidor pela instância encerrada derruba o app
               (VerifyNotTerminated lança exceção do Objective-C, que o Swift não pega). */
            let pendente = Task { await c.perfilPendente() }
            await Task.yield()
            try await c.sair()
            #expect(await pendente.value == false, "a leitura do servidor espera a limpeza e usa a instância nova")
        }

        private func gravar(_ t: TransporteFirebase, _ uid: String, _ blob: ValorJSON) async -> String? {
            await withCheckedContinuation { c in t.gravar(uid: uid, blob: blob) { c.resume(returning: $0) } }
        }

        @Test func sairLimpaOCacheEOutraContaUsaOMesmoBanco() async throws {
            let c = conta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let config = ValorJSON.objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])])
            let u = try await Emulador.novaConta()
            #expect(await gravar(transporte, u.uid, .objeto(["obras": .lista([]), "config": config])) == nil)
            _ = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .cache)
            try await c.sair()
            #expect(!Emulador.banco.limpezaPendente, "a marca sai quando o cache foi apagado")

            // Outra conta no mesmo BancoFirebase: instância nova depois do terminate, com settings e host do emulador.
            let outra = try await Emulador.novaConta()
            let blob = ValorJSON.objeto(["obras": .lista([.objeto(["id": .texto("o9"), "nome": .texto("Da outra conta"),
                                                                    "dataInicio": .texto("2026-01-01"), "gastos": .lista([])])]), "config": config])
            #expect(await gravar(transporte, outra.uid, blob) == nil)
            let lido = try await Emulador.banco.firestore().collection("dados").document(outra.uid).getDocument(source: .server).data()
            #expect(TransporteFirebase.valor(try #require(lido)).map(canonico) == canonico(blob), "a outra conta grava e lê do servidor pelo mesmo banco")
            // Com a instância viva (provado acima), a conta que saiu não está no cache: foi apagada, não só encerrada.
            await #expect(throws: (any Error).self, "o documento da conta que saiu não fica no aparelho") {
                _ = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .cache)
            }
        }

        @Test func esqueciASenhaAceitaNoEmulador() async throws {
            let u = try await Emulador.novaConta()
            try await conta().redefinirSenha(email: u.email!)
            try Auth.auth(app: Emulador.app).signOut()
        }

        /// Desativa a conta pela API de administrador do emulador do Auth: a próxima renovação do token volta USER_DISABLED.
        private func desativar(_ uid: String) async throws {
            var pedido = URLRequest(url: URL(string: "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/\(Emulador.projeto)/accounts:update")!)
            pedido.httpMethod = "POST"
            pedido.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
            pedido.setValue("application/json", forHTTPHeaderField: "Content-Type")
            pedido.httpBody = try JSONSerialization.data(withJSONObject: ["localId": uid, "disableUser": true])
            let (_, resposta) = try await URLSession.shared.data(for: pedido)
            #expect((resposta as? HTTPURLResponse)?.statusCode == 200)
        }

        @Test func sessaoInvalidadaSaiNaConferenciaForcadaMesmoDentroDoMinuto() async throws {
            let c = conta()
            let u = try await Emulador.novaConta()
            for _ in 0..<100 where c.usuario?.uid != u.uid { try await Task.sleep(for: .milliseconds(20)) }
            await c.verificarSessao(forcar: false)                  // começa a contar o minuto
            try await desativar(u.uid)
            await c.verificarSessao(forcar: false)                  // a volta da rede, dentro do minuto: não confere
            #expect(Auth.auth(app: Emulador.app).currentUser?.uid == u.uid, "a não forçada sai no máximo uma vez por minuto")
            await c.verificarSessao(forcar: true)                   // a escrita voltou unauthenticated: confere na hora
            #expect(Auth.auth(app: Emulador.app).currentUser == nil, "sessão invalidada sai da conta")
        }

        @Test func erroDeRedeNaConferenciaNaoSaiDaConta() async throws {
            // App próprio: depois do login, o Auth dele aponta para uma porta sem ninguém e renovar o token dá erro de rede.
            let nome = "rede-\(UUID().uuidString.prefix(8).lowercased())"
            FirebaseApp.configure(name: nome, options: Emulador.app.options)
            let app = try #require(FirebaseApp.app(name: nome))
            let auth = Auth.auth(app: app)
            auth.useEmulator(withHost: "127.0.0.1", port: 9099)
            _ = try await auth.createUser(withEmail: "\(nome)@example.com", password: "Casa2026x")
            auth.useEmulator(withHost: "127.0.0.1", port: 9)
            let c = ContaFirebase(app: app, banco: Emulador.banco, online: { true })
            await c.verificarSessao(forcar: true)
            #expect(auth.currentUser != nil, "falta de rede nunca tira da conta")
            try auth.signOut()
        }

        /// A marca já está gravada quando chega o aviso de que a conta saiu. Não prova a ordem entre a marca e o
        /// signOut: o Auth avisa pela fila principal, depois das duas linhas, que só importa se o app fechar entre elas.
        @Test func marcaDaLimpezaJaGravadaQuandoChegaOAvisoDeSaida() async throws {
            let c = conta()
            let u = try await Emulador.novaConta()
            for _ in 0..<100 where c.usuario?.uid != u.uid { try await Task.sleep(for: .milliseconds(20)) }
            var marcadaAoSair: Bool?
            c.observar { if $0 == nil, marcadaAoSair == nil { marcadaAoSair = Emulador.banco.limpezaPendente } }
            try await c.sair()
            #expect(marcadaAoSair == true, "o app pode fechar logo depois do signOut: a marca já tem de estar gravada")
            #expect(!Emulador.banco.limpezaPendente)
        }
    }
}
