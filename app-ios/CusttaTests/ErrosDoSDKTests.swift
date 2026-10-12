import Testing
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
@testable import Custta
import CusttaNucleo

/* As tabelas do núcleo (ErrosFirebase.swift) usam números para não depender dos SDKs. Aqui elas são
   conferidas contra as constantes dos próprios SDKs travados no projeto (roda na CI, sem rede). */
struct ErrosDoSDKTests {
    @Test func dominiosIguaisAosDosSDKs() {
        #expect(dominioAuth == AuthErrorDomain)
        #expect(dominioFirestore == FirestoreErrorDomain)
        #expect(dominioApple == ASAuthorizationError.errorDomain)
        #expect(dominioGoogle == kGIDSignInErrorDomain)
    }

    @Test func codigosDoAuthIguaisAosDoSDK() {
        let pares: [(AuthErrorCode, String)] = [
            (.invalidCredential, "auth/invalid-credential"), (.userDisabled, "auth/user-disabled"),
            (.operationNotAllowed, "auth/operation-not-allowed"), (.emailAlreadyInUse, "auth/email-already-in-use"),
            (.invalidEmail, "auth/invalid-email"), (.wrongPassword, "auth/wrong-password"),
            (.tooManyRequests, "auth/too-many-requests"), (.userNotFound, "auth/user-not-found"),
            (.accountExistsWithDifferentCredential, "auth/account-exists-with-different-credential"),
            (.requiresRecentLogin, "auth/requires-recent-login"), (.invalidUserToken, "auth/invalid-user-token"),
            (.networkError, "auth/network-request-failed"), (.userTokenExpired, "auth/user-token-expired"),
            (.weakPassword, "auth/weak-password"), (.missingEmail, "auth/missing-email"), (.quotaExceeded, "auth/quota-exceeded"),
        ]
        for (codigo, esperado) in pares {
            #expect(codigoDeErroDeConta(dominio: AuthErrorDomain, codigo: codigo.rawValue) == esperado, "\(codigo)")
        }
    }

    @Test func desistenciaNaAppleENoGoogleNaoViraMensagem() {
        #expect(codigoDeErroDeConta(dominio: ASAuthorizationError.errorDomain, codigo: ASAuthorizationError.Code.canceled.rawValue) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: ASAuthorizationError.errorDomain, codigo: ASAuthorizationError.Code.unknown.rawValue) == "1000")
        #expect(codigoDeErroDeConta(dominio: kGIDSignInErrorDomain, codigo: GIDSignInError.Code.canceled.rawValue) == "auth/user-cancelled")
    }

    @Test func codigosDoFirestoreIguaisAosDoSDK() {
        let pares: [(FirestoreErrorCode.Code, String)] = [
            (.cancelled, "cancelled"), (.invalidArgument, "invalid-argument"), (.notFound, "not-found"),
            (.permissionDenied, "permission-denied"), (.resourceExhausted, "resource-exhausted"),
            (.failedPrecondition, "failed-precondition"), (.unavailable, "unavailable"), (.unauthenticated, "unauthenticated"),
        ]
        for (codigo, esperado) in pares {
            #expect(codigoDeErroFirestore(dominio: FirestoreErrorDomain, codigo: codigo.rawValue) == esperado, "\(codigo)")
        }
    }
}
