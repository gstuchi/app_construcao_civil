import Foundation
import CryptoKit
import Security

/* Regras das telas da etapa 1 que não dependem de SwiftUI nem do Firebase: validação dos
   formulários de conta (na ordem do auth.js), ordem e textos da lista de obras e o nonce do
   login com a Apple. */

/// O `/^\S+@\S+\.\S+$/` do auth.js: sem espaço, com "@" e um ponto depois dele que não é a primeira nem a última letra.
public func emailParece(_ email: String) -> Bool {
    let u = Array(email.unicodeScalars)
    if u.isEmpty || u.contains(where: ehEspacoJS) { return false }
    for (i, c) in u.enumerated() where c == "@" && i >= 1 {
        let resto = Array(u[(i + 1)...])
        if resto.count >= 3, resto[1...(resto.count - 2)].contains(".") { return true }
    }
    return false
}

/// Mensagem do formulário de entrar (auth.js), ou nil se pode tentar.
public func validarEntrada(email: String, senha: String) -> String? {
    if !emailParece(aparadoJS(email)) { return "Digite seu e-mail." }
    if senha.isEmpty { return "Digite a senha." }
    return nil
}

public enum ResultadoCadastro: Equatable, Sendable {
    case ok(PerfilCadastro)
    /// `campo`: "nome", "sobrenome", "email", "senha", "confirmacao", "origem" ou "origemDetalhe".
    case falhou(campo: String, erro: String)
}

/// Validação do criar conta na ordem do auth.js: nome e sobrenome, e-mail, senha, confirmação, origem.
public func validarCadastro(nome: String, sobrenome: String, email: String, senha: String, confirmacao: String,
                            origem: String?, origemDetalhe: String) -> ResultadoCadastro {
    let perfil = normalizaPerfil(nome: nome, sobrenome: sobrenome, origem: origem, origemDetalhe: origemDetalhe)
    if !perfil.ok && (perfil.campo == "nome" || perfil.campo == "sobrenome") { return .falhou(campo: perfil.campo, erro: perfil.erro) }
    let e = aparadoJS(email)
    if !emailParece(e) { return .falhou(campo: "email", erro: "E-mail inválido.") }
    let regra = validaSenha(senha, email: e)
    if !regra.ok { return .falhou(campo: "senha", erro: regra.erro) }
    if confirmacao != senha { return .falhou(campo: "confirmacao", erro: "As senhas não são iguais.") }
    if !perfil.ok { return .falhou(campo: perfil.campo, erro: perfil.erro) }
    return .ok(perfil.perfil!)
}

public extension Fase {
    /// Rótulo da fase no site (FASES do app.js).
    var rotulo: String {
        switch self {
        case .construcao: return "Em construção"
        case .pronta: return "Pronta · à venda"
        case .vendida: return "Vendida"
        }
    }
}

/// Ordem da lista de obras do app.js: não vendidas primeiro, depois a que começou mais recente.
public func obrasOrdenadas(_ obras: [Obra]) -> [Obra] {
    ordenadoEstavel(obras) { a, b in
        let va = a.fase == .vendida, vb = b.fase == .vendida
        if va != vb { return !va }
        return menorJS(b.dataInicio, a.dataInicio)
    }
}

/// Texto da linha de orçamento na lista de obras: "X% do orçamento" ou "X% · passou R$ Y".
public func textoOrcamentoNaLista(_ r: ResumoOrcamento) -> String {
    let pct = numeroJS(r.geral.pct)
    return r.geral.nivel == .passou ? "\(pct)% · passou \(moedaCurtaSemZero(-r.geral.sobra))" : "\(pct)% do orçamento"
}

/// Texto da lista de obras quando a leitura falha antes de carregar. Nada foi gravado: o app só grava
/// depois de ver os dados (Sincronizador).
public func textoErroDeLeitura(_ codigo: String) -> String {
    if codigo == "formato-desconhecido" {
        return "Seus dados na nuvem têm um formato que este app ainda não sabe ler. Nada foi alterado: as obras continuam salvas como estavam."
    }
    return "Não deu para buscar suas obras agora. Confira a internet e tente de novo. Nada foi alterado: as obras continuam salvas como estavam."
}

/// Nonce do login com a Apple: 32 bytes aleatórios em hexadecimal (a Apple assina o SHA-256 dele).
public enum Nonce {
    public static func gerar() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes falhou: \(status)")
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256(_ texto: String) -> String {
        SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Uma barra do "Comparativo entre obras" (drawComp do app.js): gasto bruto e corrigido pela taxa, com as
/// larguras em fração do maior corrigido.
public struct LinhaComparativo: Equatable, Sendable, Identifiable {
    public let id: String
    public let nome: String
    public let bruto: Double
    public let corrigido: Double
    public let fracaoBruto: Double
    public let fracaoCorrigido: Double
}

/// O comparativo da lista de obras: as obras com gasto, na ordem da lista; vazio com menos de duas.
public func comparativoEntreObras(_ obras: [Obra], taxa: Double, hoje: String) -> [LinhaComparativo] {
    let comGasto = obrasOrdenadas(obras).filter { totalBruto($0) > 0 }
    guard comGasto.count >= 2 else { return [] }
    let valores = comGasto.map { (obra: $0, bruto: totalBruto($0), corrigido: totalCorrigido($0, taxa: taxa, hoje: hoje)) }
    let maior = max(valores.map(\.corrigido).max() ?? 1, 1)
    return valores.map {
        LinhaComparativo(id: $0.obra.id, nome: $0.obra.nome, bruto: $0.bruto, corrigido: $0.corrigido,
                         fracaoBruto: $0.bruto / maior, fracaoCorrigido: $0.corrigido / maior)
    }
}
