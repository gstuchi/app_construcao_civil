import Foundation
@testable import Custta

/// Deixa as tarefas da fila principal andarem até a condição valer (desiste em uns 4 s).
@MainActor func ate(_ condicao: @MainActor () -> Bool) async {
    for _ in 0..<200 where !condicao() { try? await Task.sleep(for: .milliseconds(20)) }
}

/// Roda a operação sem deixar o teste travar: o teste espera o fim com `ate` e, se ela não terminar,
/// falha em vez de esperar para sempre. O `.timeLimit` sozinho não basta: a espera de `salvar` não
/// responde a cancelamento, e o teste ficaria preso mesmo depois de registrar a falha.
@MainActor final class Desfecho {
    private(set) var terminou = false
    private(set) var erro: (any Error)?
    init(_ operacao: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do { try await operacao() } catch { self.erro = error }
            self.terminou = true
        }
    }
}

extension ModeloApp.Fase {
    var ehPrincipal: Bool { if case .principal = self { return true }; return false }
    var ehFaltaPouco: Bool { if case .faltaPouco = self { return true }; return false }
}

/// Liga quando algo acontece (observação, uso do banco).
@MainActor final class Bandeira { var ligada = false }
