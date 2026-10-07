import Foundation

/// `hashEndpoint` do push.js: djb2 sobre as unidades UTF-16 do token, em 32 bits sem sinal, base 36.
/// É a chave do token em `push/{uid}.tokens`.
public func chaveDoToken(_ token: String) -> String {
    var h: UInt32 = 5381
    for c in token.utf16 { h = (h &<< 5) &+ h &+ UInt32(c) }
    return String(h, radix: 36)
}

private let base36: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyz")

/// Milissegundos desde 1970, inteiros, como o Date.now() do JavaScript.
public func agoraEmMilissegundos() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)) }

/// `uid()` do app.js: milissegundos em base 36 mais 4 caracteres aleatórios de base 36.
public func gerarId(agoraMs: Int64 = agoraEmMilissegundos(), sorteio: (Int) -> Int = { Int.random(in: 0..<$0) }) -> String {
    String(agoraMs, radix: 36) + String((0..<4).map { _ in base36[sorteio(36)] })
}
