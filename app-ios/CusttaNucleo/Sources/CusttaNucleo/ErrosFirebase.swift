import Foundation

/* Os SDKs do iOS devolvem NSError com domínio e número; o site trabalha com os códigos do SDK
   JavaScript ("auth/wrong-password", "permission-denied"). Estas tabelas traduzem um no outro
   para as mensagens (cadastro) e a fila (erroEhTerminal) serem as mesmas do site.
   Números de FIRAuthErrors.h e FIRFirestoreErrors.h (códigos do gRPC). */

public let dominioAuth = "FIRAuthErrorDomain"
public let dominioFirestore = "FIRFirestoreErrorDomain"
public let dominioApple = "com.apple.AuthenticationServices.AuthorizationError"
public let dominioGoogle = "com.google.GIDSignIn"

private let errosAuth: [Int: String] = [
    17004: "auth/invalid-credential", 17005: "auth/user-disabled", 17006: "auth/operation-not-allowed",
    17007: "auth/email-already-in-use", 17008: "auth/invalid-email", 17009: "auth/wrong-password",
    17010: "auth/too-many-requests", 17011: "auth/user-not-found", 17012: "auth/account-exists-with-different-credential",
    17014: "auth/requires-recent-login", 17017: "auth/invalid-user-token", 17020: "auth/network-request-failed",
    17021: "auth/user-token-expired", 17026: "auth/weak-password", 17034: "auth/missing-email", 17052: "auth/quota-exceeded",
]

private let errosFirestore: [Int: String] = [
    1: "cancelled", 2: "unknown", 3: "invalid-argument", 4: "deadline-exceeded", 5: "not-found", 6: "already-exists",
    7: "permission-denied", 8: "resource-exhausted", 9: "failed-precondition", 10: "aborted", 11: "out-of-range",
    12: "unimplemented", 13: "internal", 14: "unavailable", 15: "data-loss", 16: "unauthenticated",
]

/// Código no formato do site para erro de login (Firebase Auth, Apple, Google ou rede).
public func codigoDeErroDeConta(dominio: String, codigo: Int) -> String {
    switch dominio {
    case dominioAuth: return errosAuth[codigo] ?? "auth/erro-\(codigo)"
    case dominioApple: return codigo == 1001 ? "auth/user-cancelled" : codigo == 1000 ? "1000" : "auth/apple-\(codigo)"
    case dominioGoogle: return codigo == -5 ? "auth/user-cancelled" : "auth/google-\(codigo)"
    case NSURLErrorDomain: return "auth/network-request-failed"
    default: return "auth/erro-\(codigo)"
    }
}

/// Código no formato do site para erro do Firestore ("permission-denied"); "desconhecido" fora do domínio.
public func codigoDeErroFirestore(dominio: String, codigo: Int) -> String {
    guard dominio == dominioFirestore else { return "desconhecido" }
    return errosFirestore[codigo] ?? "desconhecido"
}

/// Erros de sessão que encerram a conta no aparelho (SESSAO_INVALIDA do cloud.js). Falta de rede nunca está aqui.
/// `auth/invalid-refresh-token` fica pela paridade com o site: nenhum código do SDK iOS chega nele.
public func sessaoInvalida(_ codigo: String) -> Bool {
    ["auth/invalid-refresh-token", "auth/user-disabled", "auth/user-token-expired", "auth/user-not-found", "auth/invalid-user-token"].contains(codigo)
}
