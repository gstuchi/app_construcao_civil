import Testing
@testable import CusttaNucleo

struct ErrosFirebaseTests {
    @Test func contaNoFormatoDoSite() {
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17009) == "auth/wrong-password")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17020) == "auth/network-request-failed")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17052) == "auth/quota-exceeded")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 99999) == "auth/erro-99999")
        #expect(codigoDeErroDeConta(dominio: dominioApple, codigo: 1001) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: dominioApple, codigo: 1000) == "1000")
        #expect(codigoDeErroDeConta(dominio: dominioGoogle, codigo: -5) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: "NSURLErrorDomain", codigo: -1009) == "auth/network-request-failed")
        #expect(mensagemErroSocial(codigo: codigoDeErroDeConta(dominio: dominioApple, codigo: 1001), provedor: "apple.com") == "")
        #expect(mensagemErroSenha(codigo: codigoDeErroDeConta(dominio: dominioAuth, codigo: 17004), tela: "login") == "E-mail ou senha incorretos.")
    }

    @Test func firestoreNoFormatoDoSite() {
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 7) == "permission-denied")
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 14) == "unavailable")
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 16) == "unauthenticated")
        #expect(codigoDeErroFirestore(dominio: "outro", codigo: 7) == "desconhecido")
        #expect(erroEhTerminal(codigo: codigoDeErroFirestore(dominio: dominioFirestore, codigo: 3)))
        #expect(!erroEhTerminal(codigo: codigoDeErroFirestore(dominio: dominioFirestore, codigo: 14)))
    }

    @Test func sessaoQueEncerraAConta() {
        #expect(sessaoInvalida("auth/user-token-expired"))
        #expect(sessaoInvalida("auth/user-not-found"))
        #expect(!sessaoInvalida("auth/network-request-failed"), "falta de rede nunca desloga")
    }
}
