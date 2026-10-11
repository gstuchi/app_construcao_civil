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
        private func desativar(_ uid: String) async throws { try await alterarConta(uid, ["disableUser": true]) }

        /// Muda a conta pela API de administrador do emulador do Auth (conta desativada, link de confirmação clicado).
        private func alterarConta(_ uid: String, _ campos: [String: Any]) async throws {
            var pedido = URLRequest(url: URL(string: "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/\(Emulador.projeto)/accounts:update")!)
            pedido.httpMethod = "POST"
            pedido.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
            pedido.setValue("application/json", forHTTPHeaderField: "Content-Type")
            pedido.httpBody = try JSONSerialization.data(withJSONObject: campos.merging(["localId": uid]) { $1 })
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

        @Test func limpezaQueFalhaAoSairBloqueiaEntrarAteDarCerto() async throws {
            // App e banco próprios: a falha de apagar o cache não pode encostar na instância do Emulador.banco.
            let nome = "bloqueio-\(UUID().uuidString.prefix(8).lowercased())"
            FirebaseApp.configure(name: nome, options: Emulador.app.options)
            let app = try #require(FirebaseApp.app(name: nome))
            let auth = Auth.auth(app: app)
            auth.useEmulator(withHost: "127.0.0.1", port: 9099)
            let falha = Bandeira()
            falha.ligada = true
            let banco = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080), preferencias: try #require(UserDefaults(suiteName: nome)),
                                      apagar: { db in
                                          if falha.ligada { throw ErroConta(codigo: "disco") }
                                          try await db.clearPersistence()
                                      })
            let c = ContaFirebase(app: app, banco: banco, online: { true })
            let email = "\(nome)@example.com"
            _ = try await auth.createUser(withEmail: email, password: "Casa2026x")
            await #expect(throws: ErroConta(codigo: "cache")) { try await c.sair() }
            #expect(auth.currentUser == nil, "saiu da conta antes de a limpeza falhar")
            await #expect(throws: ErroConta(codigo: "cache"), "entrar recusa com o cache velho no aparelho") {
                try await c.entrar(email: email, senha: "Casa2026x")
            }
            await #expect(throws: ErroConta(codigo: "cache"), "criar conta também") {
                try await c.criarConta(email: "outra-\(email)", senha: "Casa2026x", perfil: PerfilCadastro(nome: "Gi", origem: "indicacao"))
            }
            #expect(auth.currentUser == nil)
            falha.ligada = false
            try await c.tentarLimparDeNovo()
            try await c.entrar(email: email, senha: "Casa2026x")
            #expect(auth.currentUser != nil, "limpou: entrar volta a funcionar")
            try auth.signOut()
        }

        @Test func sairNoMeioDaLeituraDoNomeNaoPenduraATarefa() async throws {
            // App e banco próprios: o servidor não responde a leitura, como depois do terminate de um sair (T13).
            let nome = "corte-\(UUID().uuidString.prefix(8).lowercased())"
            FirebaseApp.configure(name: nome, options: Emulador.app.options)
            let app = try #require(FirebaseApp.app(name: nome))
            let auth = Auth.auth(app: app)
            auth.useEmulator(withHost: "127.0.0.1", port: 9099)
            let banco = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080), preferencias: try #require(UserDefaults(suiteName: nome)),
                                      leitor: { _, _, _ in })
            let c = ContaFirebase(app: app, banco: banco, online: { true })
            _ = try await auth.createUser(withEmail: "\(nome)@example.com", password: "Casa2026x")
            let leitura = Desfecho { _ = await c.lerNome() }
            await ate { banco.leiturasPendentes == 1 }
            #expect(banco.leiturasPendentes == 1, "a leitura do nome passa pelo banco, que responde a ela no sair")
            try await c.sair()
            await ate { leitura.terminou }
            #expect(leitura.terminou, "a leitura do nome cortada pelo sair termina, em vez de deixar a tarefa pendurada")
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

        @Test func trocaDeContaRecomecaAContarOMinuto() async throws {
            let c = conta()
            let primeira = try await Emulador.novaConta()
            for _ in 0..<100 where c.usuario?.uid != primeira.uid { try await Task.sleep(for: .milliseconds(20)) }
            await c.verificarSessao(forcar: false)                  // a primeira conta começa a contar o minuto
            let outra = try await Emulador.novaConta()              // outra conta no aparelho, dentro do minuto
            for _ in 0..<100 where c.usuario?.uid != outra.uid { try await Task.sleep(for: .milliseconds(20)) }
            try await desativar(outra.uid)
            await c.verificarSessao(forcar: false)                  // a volta da rede, já com a outra conta
            #expect(Auth.auth(app: Emulador.app).currentUser == nil, "a espera de 60 s é por conta (cloud.js): a conta nova confere na hora")
        }

        /// Grava como outro aparelho: REST do emulador do Firestore com o dono, sem passar pelo cache deste.
        private func gravarComoOutroAparelho(_ caminho: String, _ campos: [String: String]) async throws {
            var pedido = URLRequest(url: URL(string: "http://127.0.0.1:8080/v1/projects/\(Emulador.projeto)/databases/(default)/documents/\(caminho)")!)
            pedido.httpMethod = "PATCH"
            pedido.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
            pedido.setValue("application/json", forHTTPHeaderField: "Content-Type")
            pedido.httpBody = try JSONSerialization.data(withJSONObject: ["fields": campos.mapValues { ["stringValue": $0] }])
            let (_, resposta) = try await URLSession.shared.data(for: pedido)
            #expect((resposta as? HTTPURLResponse)?.statusCode == 200)
        }

        @Test func perfilGravadoPorOutroAparelhoNoFaltaPoucoSegueParaALista() async throws {
            let c = conta()
            let sub = UUID().uuidString.lowercased()
            let email = "\(sub.prefix(8))@example.com"
            let tokenFalso = #"{"sub":"\#(sub)","email":"\#(email)","email_verified":true}"#
            _ = try await Auth.auth(app: Emulador.app).signIn(with: GoogleAuthProvider.credential(withIDToken: tokenFalso, accessToken: "x"))
            for _ in 0..<100 where c.usuario?.contaSocial != true { try await Task.sleep(for: .milliseconds(20)) }
            let uid = try #require(c.usuario?.uid)
            #expect(await c.perfilPendente())
            // Este aparelho está no "Falta pouco"; o outro completa primeiro.
            try await gravarComoOutroAparelho("perfis/\(uid)", ["email": email, "criado": "2026-10-11T12:00:00.000Z", "nome": "Outro"])
            /* As rules recusam o segundo (criado e origem mudariam), e o ModeloApp.completarPerfil depende deste
               código: com "permission-denied" e o perfil no servidor, segue para a lista em vez de prender no "Falta pouco". */
            await #expect(throws: ErroConta(codigo: "permission-denied")) {
                try await c.completarPerfil(PerfilCadastro(nome: "Gi", origem: "google"))
            }
            #expect(await c.perfilPendente() == false, "o perfil do outro aparelho conta")
            #expect(await c.lerNome() == "Outro", "o segundo não sobrescreve o primeiro")
            try await c.sair()
        }

        @Test func emailConfirmadoChegaAoUsuarioSemReabrir() async throws {
            let c = conta()
            let u = try await Emulador.novaConta()
            for _ in 0..<100 where c.usuario?.uid != u.uid { try await Task.sleep(for: .milliseconds(20)) }
            #expect(c.usuario?.precisaConfirmarEmail == true)
            #expect(try await c.reenviarVerificacao(), "ainda não confirmado: manda o link")
            #expect(await c.conferirVerificacao() == false, "o link ainda não foi clicado")
            try await alterarConta(u.uid, ["emailVerified": true])     // o clique no link
            #expect(await c.conferirVerificacao())
            #expect(c.usuario?.emailVerificado == true, "o aviso de confirmar o e-mail some sem reabrir o app")
            #expect(try await c.reenviarVerificacao() == false, "já confirmado: não manda de novo")
            try Auth.auth(app: Emulador.app).signOut()
        }
    }
}
