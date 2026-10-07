import Foundation
import Testing
@testable import CusttaNucleo

/* Todo grupo dos vetores precisa de um teste que leia os casos dele. Em vez de uma lista escrita à
   mão, a cobertura lê os próprios arquivos de teste desta pasta: grupo novo no gerador do site sem
   nenhuma leitura no núcleo faz este falhar (o site ganhou regra que o app ainda não tem). */
struct CoberturaTests {
    static func gruposLidosNosTestes() throws -> Set<String> {
        let pasta = URL(filePath: #filePath).deletingLastPathComponent()
        let leitura = /casos\("([^"]+)"\)/
        var grupos: Set<String> = []
        for arquivo in try FileManager.default.contentsOfDirectory(at: pasta, includingPropertiesForKeys: nil)
        where arquivo.pathExtension == "swift" {
            for m in try String(contentsOf: arquivo, encoding: .utf8).matches(of: leitura) { grupos.insert(String(m.1)) }
        }
        return grupos
    }

    @Test func todoGrupoTemTeste() throws {
        let lidos = try Self.gruposLidosNosTestes()
        let semTeste = Set(Vetores.todos.grupos.keys).subtracting(lidos).sorted()
        #expect(semTeste.isEmpty, "grupos sem teste no núcleo: \(semTeste)")
        let sumiram = lidos.subtracting(Vetores.todos.grupos.keys).sorted()
        #expect(sumiram.isEmpty, "testes que leem grupos que o gerador não produz mais: \(sumiram)")
    }
}
