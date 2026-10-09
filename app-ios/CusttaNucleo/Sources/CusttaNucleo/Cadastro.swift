import Foundation

/* Porte do cadastro.js: regras de senha, nome e "como conheceu", e as mensagens de erro de login.
   As firestore.rules repetem os limites e a lista de origens: mudou aqui, muda lá e no site.
   Tamanhos contam unidades UTF-16, como o `length` do JavaScript (mais restritivo que as rules). */

public struct RegraSenha: Equatable, Sendable {
    public let id: String
    public let texto: String
}

public let regrasSenha: [RegraSenha] = [
    RegraSenha(id: "tamanho", texto: "8 caracteres ou mais"),
    RegraSenha(id: "letra", texto: "Uma letra"),
    RegraSenha(id: "numero", texto: "Um número"),
    RegraSenha(id: "email", texto: "Diferente do e-mail"),
    RegraSenha(id: "comum", texto: "Não é uma senha óbvia"),
]

private let errosSenha = ["tamanho": "Use pelo menos 8 caracteres.", "letra": "Inclua pelo menos uma letra.",
                          "numero": "Inclua pelo menos um número.", "email": "A senha não pode ser igual ao e-mail.",
                          "comum": "Essa senha é muito comum. Escolha outra."]

/// Lista curta de propósito: pega o óbvio que passaria nas outras regras.
private let senhasComuns: Set<String> = ["senha123", "senha1234", "12345678a", "123456789a", "a12345678", "abc12345", "abcd1234",
    "qwerty123", "password1", "password123", "custta123", "obra1234", "mudar123", "brasil123", "admin123"]

public struct RegraAvaliada: Equatable, Sendable {
    public let id: String
    public let texto: String
    public let ok: Bool
}

public struct ResultadoSenha: Equatable, Sendable {
    public let ok: Bool
    public let regras: [RegraAvaliada]
    public let erro: String
}

private func ehLetra(_ u: Unicode.Scalar) -> Bool {
    switch u.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: return true
    default: return false
    }
}

/// `validaSenha` do cadastro.js; o checklist da tela usa `regras`.
public func validaSenha(_ senha: String?, email: String?) -> ResultadoSenha {
    let s = senha ?? ""
    let chave = aparadoJS(s).lowercased()
    let e = aparadoJS(email ?? "").lowercased()
    let passa: [String: Bool] = [
        "tamanho": s.utf16.count >= 8,
        "letra": s.unicodeScalars.contains(where: ehLetra),
        "numero": s.unicodeScalars.contains(where: ehDigito),
        "email": !(!e.isEmpty && chave == e),
        "comum": !senhasComuns.contains(chave),
    ]
    let regras = regrasSenha.map { RegraAvaliada(id: $0.id, texto: $0.texto, ok: passa[$0.id]!) }
    if let falha = regras.first(where: { !$0.ok }) { return ResultadoSenha(ok: false, regras: regras, erro: errosSenha[falha.id]!) }
    if s.utf16.count > 128 { return ResultadoSenha(ok: false, regras: regras, erro: "Use no máximo 128 caracteres.") }
    return ResultadoSenha(ok: true, regras: regras, erro: "")
}

public struct Origem: Equatable, Sendable {
    public let id: String
    public let nome: String
    /// Rótulo do campo de detalhe, quando a origem tem um.
    public let detalhe: String?
}

public let origens: [Origem] = [
    Origem(id: "instagram", nome: "Instagram", detalhe: nil),
    Origem(id: "indicacao", nome: "Indicação de alguém", detalhe: "Quem indicou? (opcional)"),
    Origem(id: "google", nome: "Pesquisa no Google", detalhe: nil),
    Origem(id: "tiktok", nome: "TikTok", detalhe: nil),
    Origem(id: "youtube", nome: "YouTube", detalhe: nil),
    Origem(id: "outro", nome: "Outro", detalhe: "Onde? (opcional)"),
]

public enum LimitesPerfil {
    public static let nome = 60
    public static let sobrenome = 80
    public static let origemDetalhe = 80
}

/// O que vai para `perfis/{uid}` além de e-mail, data e fuso.
public struct PerfilCadastro: Equatable, Sendable {
    public var nome: String?
    public var sobrenome: String?
    public var origem: String?
    public var origemDetalhe: String?

    public init(nome: String? = nil, sobrenome: String? = nil, origem: String? = nil, origemDetalhe: String? = nil) {
        self.nome = nome; self.sobrenome = sobrenome; self.origem = origem; self.origemDetalhe = origemDetalhe
    }

    /// Só as chaves presentes, como o objeto `perfil` do site.
    public var campos: [String: ValorJSON] {
        var c: [String: ValorJSON] = [:]
        if let nome { c["nome"] = .texto(nome) }
        if let sobrenome { c["sobrenome"] = .texto(sobrenome) }
        if let origem { c["origem"] = .texto(origem) }
        if let origemDetalhe { c["origemDetalhe"] = .texto(origemDetalhe) }
        return c
    }
}

public struct ResultadoPerfil: Equatable, Sendable {
    public let ok: Bool
    /// Campo com problema ("nome", "sobrenome", "origem", "origemDetalhe"); "" quando ok.
    public let campo: String
    public let erro: String
    public let perfil: PerfilCadastro?

    static func falhou(_ campo: String, _ erro: String) -> ResultadoPerfil { ResultadoPerfil(ok: false, campo: campo, erro: erro, perfil: nil) }
}

/// `limpa` do cadastro.js: tira os espaços das pontas e junta os do meio num só.
func limpa(_ s: String?) -> String {
    var r = ""
    var espaco = false
    for u in aparadoJS(s ?? "").unicodeScalars {
        if ehEspacoJS(u) { espaco = true; continue }
        if espaco { r.append(" "); espaco = false }
        r.unicodeScalars.append(u)
    }
    return r
}

/// `normalizaNome` do cadastro.js.
public func normalizaNome(nome: String?, sobrenome: String?) -> ResultadoPerfil {
    let n = limpa(nome), s = limpa(sobrenome)
    if n.isEmpty { return .falhou("nome", "Digite seu nome.") }
    if n.utf16.count < 2 { return .falhou("nome", "O nome precisa de pelo menos 2 letras.") }
    if n.utf16.count > LimitesPerfil.nome { return .falhou("nome", "Use no máximo 60 caracteres no nome.") }
    if s.utf16.count > LimitesPerfil.sobrenome { return .falhou("sobrenome", "Use no máximo 80 caracteres no sobrenome.") }
    return ResultadoPerfil(ok: true, campo: "", erro: "", perfil: PerfilCadastro(nome: n, sobrenome: s.isEmpty ? nil : s))
}

/// `normalizaPerfil` do cadastro.js. `nomeOpcional`: conta Apple, cujo nome vem da Apple e a tela não pede de novo.
public func normalizaPerfil(nome: String?, sobrenome: String?, origem: String?, origemDetalhe: String?,
                            nomeOpcional: Bool = false) -> ResultadoPerfil {
    var base = normalizaNome(nome: nome, sobrenome: sobrenome)
    if !base.ok && nomeOpcional { base = ResultadoPerfil(ok: true, campo: "", erro: "", perfil: PerfilCadastro()) }
    if !base.ok { return base }
    guard let o = origens.first(where: { $0.id == origem }) else { return .falhou("origem", "Conte como conheceu o Custta.") }
    var perfil = base.perfil!
    perfil.origem = o.id
    if o.detalhe != nil {
        let detalhe = limpa(origemDetalhe)
        if detalhe.utf16.count > LimitesPerfil.origemDetalhe { return .falhou("origemDetalhe", "Use no máximo 80 caracteres.") }
        if !detalhe.isEmpty { perfil.origemDetalhe = detalhe }
    }
    return ResultadoPerfil(ok: true, campo: "", erro: "", perfil: perfil)
}

/// Os primeiros `n` unidades UTF-16, sem partir um emoji ao meio.
func prefixoUTF16(_ s: String, _ n: Int) -> String {
    var r = String.UnicodeScalarView()
    var usadas = 0
    for u in s.unicodeScalars {
        let tamanho = u.utf16.count
        if usadas + tamanho > n { break }
        r.append(u)
        usadas += tamanho
    }
    return String(r)
}

/// `nomeDoGoogle` do cadastro.js: a primeira palavra é o nome, o resto o sobrenome, cortados nos limites.
public func nomeDoGoogle(_ nomeDeExibicao: String?) -> (nome: String, sobrenome: String) {
    let partes = limpa(nomeDeExibicao).split(separator: " ").map(String.init)
    return (prefixoUTF16(partes.first ?? "", LimitesPerfil.nome),
            prefixoUTF16(partes.dropFirst().joined(separator: " "), LimitesPerfil.sobrenome))
}

private let desistiu: Set<String> = ["auth/popup-closed-by-user", "auth/cancelled-popup-request", "auth/user-cancelled"]
private let muitasTentativas = "Muitas tentativas. Espere um pouco."

/// `mensagemErroSocial` do cadastro.js; "" quando a pessoa desistiu (não é erro para mostrar).
public func mensagemErroSocial(codigo: String?, provedor: String?) -> String {
    let apple = provedor == "apple.com"
    let curto = apple ? "com a Apple" : "com Google"
    let longo = apple ? "com a Apple" : "com o Google"
    guard let c = codigo else { return "Não deu certo entrar \(longo). Tente de novo." }
    if desistiu.contains(c) { return "" }
    if c.contains("quota-exceeded") { return muitasTentativas }
    if c == "1000" && apple { return "Confira se o iPhone está conectado a um ID Apple (em Ajustes) ou entre com e-mail e senha." }
    switch c {
    case "auth/account-exists-with-different-credential": return "Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez."
    case "auth/unauthorized-domain": return "Login \(curto) indisponível neste endereço. Use custta.com.br."
    case "auth/operation-not-allowed": return "Login \(curto) ainda não está disponível. Use e-mail e senha."
    case "auth/operation-not-supported-in-this-environment", "auth/web-storage-unsupported":
        return "Seu navegador bloqueou o login \(curto). Use e-mail e senha."
    case "auth/network-request-failed": return "Sem internet. Conecte pra entrar."
    case "auth/too-many-requests": return muitasTentativas
    default: return "Não deu certo entrar \(longo). Tente de novo."
    }
}

/// `mensagemErroSenha` do cadastro.js; `tela` é "login", "cadastro" ou "redefinir".
public func mensagemErroSenha(codigo: String?, tela: String?) -> String {
    let c = codigo ?? ""
    if c.contains("invalid-credential") || c.contains("wrong-password") || c.contains("user-not-found") { return "E-mail ou senha incorretos." }
    if c.contains("email-already-in-use") { return "Este e-mail já tem conta. Use \"Entrar\"." }
    if c.contains("invalid-email") { return "E-mail inválido." }
    if c.contains("weak-password") { return "Senha fraca: use 8 caracteres ou mais, com letra e número." }
    if c.contains("too-many-requests") {
        return tela == "login" ? "Muitas tentativas. Espere alguns minutos ou redefina a senha em \"Esqueci minha senha\"." : muitasTentativas
    }
    if c.contains("quota-exceeded") { return muitasTentativas }
    if c.contains("network-request-failed") { return "Sem internet. Conecte pra entrar." }
    return "Não deu certo. Tente de novo."
}
