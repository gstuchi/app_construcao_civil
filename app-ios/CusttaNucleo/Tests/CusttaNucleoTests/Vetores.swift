import Foundation
import Testing
@testable import CusttaNucleo

/* Leitura de tests/vetores/calc.json (gerado do site por scripts/vetores-calc.mjs) e as
   comparações que os testes usam. Dinheiro bate no centavo; valor contínuo (taxa, TIR, meses)
   com tolerância relativa de 1e-9; texto, booleano e inteiro, exatos. */

struct CasoVetor: Decodable, Sendable {
    let caso: String
    let args: [ValorJSON]
    let saida: ValorJSON
    let gerar: Gerar?
    let tamanho: Int?

    struct Gerar: Decodable, Sendable {
        let base: ValorJSON
        let campo: String
        let letra: String
        let vezes: Int
    }

    enum CodingKeys: String, CodingKey { case caso, args, saida, gerar, tamanho }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        caso = try c.decode(String.self, forKey: .caso)
        args = try c.decodeIfPresent([ValorJSON].self, forKey: .args) ?? []
        saida = try c.decode(ValorJSON.self, forKey: .saida)
        gerar = try c.decodeIfPresent(Gerar.self, forKey: .gerar)
        tamanho = try c.decodeIfPresent(Int.self, forKey: .tamanho)
    }

    /// Argumento i; nil quando o caso chamou a função com menos argumentos (o undefined do JavaScript).
    func arg(_ i: Int) -> ValorJSON? { i < args.count ? args[i] : nil }
}

struct Vetores: Decodable, Sendable {
    let formato: Int
    let fuso: String
    let grupos: [String: [CasoVetor]]

    /// app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ → raiz do repositório → tests/vetores/calc.json
    static let arquivo: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { u.deleteLastPathComponent() }
        return u.appending(path: "tests/vetores/calc.json")
    }()

    static let todos: Vetores = {
        do { return try JSONDecoder().decode(Vetores.self, from: Data(contentsOf: arquivo)) }
        catch { fatalError("não li \(arquivo.path): \(error)") }
    }()

    static func casos(_ grupo: String) -> [CasoVetor] {
        let l = todos.grupos[grupo] ?? []
        if l.isEmpty { Issue.record("grupo \(grupo) sem casos em tests/vetores/calc.json") }
        return l
    }
}

enum Tolerancia { case exata, dinheiro, continua }

func confere(_ obtido: ValorJSON, _ esperado: ValorJSON, _ tolerancia: Tolerancia, _ onde: String,
             sourceLocation: SourceLocation = #_sourceLocation) {
    switch (obtido, esperado) {
    case let (.numero(a), .numero(b)):
        let ok: Bool = switch tolerancia {
        case .exata: a == b
        case .dinheiro: abs(a - b) < 0.005
        case .continua: a == b || abs(a - b) <= max(1e-9 * max(abs(a), abs(b)), 1e-12)   // piso: perto de zero o relativo não fecha
        }
        #expect(ok, "\(onde): obtido \(a), esperado \(b)", sourceLocation: sourceLocation)
    case let (.lista(a), .lista(b)):
        #expect(a.count == b.count, "\(onde): \(a.count) itens, esperado \(b.count)", sourceLocation: sourceLocation)
        for (i, (x, y)) in zip(a, b).enumerated() { confere(x, y, tolerancia, "\(onde)[\(i)]", sourceLocation: sourceLocation) }
    case let (.objeto(a), .objeto(b)):
        #expect(Set(a.keys) == Set(b.keys), "\(onde): chaves \(a.keys.sorted()), esperado \(b.keys.sorted())", sourceLocation: sourceLocation)
        for (k, y) in b { if let x = a[k] { confere(x, y, tolerancia, "\(onde).\(k)", sourceLocation: sourceLocation) } }
    default:
        #expect(obtido == esperado, "\(onde): obtido \(obtido), esperado \(esperado)", sourceLocation: sourceLocation)
    }
}

/// Número opcional do Swift na forma do JavaScript (null quando nil).
func opcional(_ n: Double?) -> ValorJSON { n.map(ValorJSON.numero) ?? .nulo }

extension ValorJSON {
    var numero: Double { comoNumero ?? .nan }
    var textoOuNil: String? { comoTexto }
    var numeroOuNil: Double? { comoNumero }
}
