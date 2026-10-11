@testable import CusttaNucleo

/* Transporte e relógio falsos: o teste decide quando o servidor confirma, quando chega
   snapshot e quando o tempo passa. */

@MainActor final class TransporteFalso: TransporteDados {
    final class Escuta: Cancelavel {
        let uid: String
        let aoReceber: @MainActor (Instantaneo) -> Void
        let aoFalhar: @MainActor (String) -> Void
        var cancelada = false
        init(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void, aoFalhar: @escaping @MainActor (String) -> Void) {
            self.uid = uid; self.aoReceber = aoReceber; self.aoFalhar = aoFalhar
        }
        func cancelar() { cancelada = true }
    }
    struct Gravacao {
        let uid: String
        let blob: ValorJSON
        let concluir: @MainActor (String?) -> Void
    }

    var escutas: [Escuta] = []
    var gravacoes: [Gravacao] = []
    var esperasDePendentes: [@MainActor (String?) -> Void] = []

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let e = Escuta(uid: uid, aoReceber: aoReceber, aoFalhar: aoFalhar)
        escutas.append(e)
        return e
    }
    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        gravacoes.append(Gravacao(uid: uid, blob: blob, concluir: concluir))
    }
    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        esperasDePendentes.append(concluir)
    }

    /// Snapshot na escuta mais recente.
    func chega(_ dados: ValorJSON?, doCache: Bool = false, pendente: Bool = false) {
        escutas.last!.aoReceber(Instantaneo(dados: dados, doCache: doCache, gravacaoPendente: pendente))
    }
}

@MainActor final class RelogioFalso: Relogio {
    final class Agendado: Cancelavel {
        let quando: Int64
        let acao: @MainActor () -> Void
        var cancelado = false
        init(quando: Int64, acao: @escaping @MainActor () -> Void) { self.quando = quando; self.acao = acao }
        func cancelar() { cancelado = true }
    }
    var agoraMs: Int64 = 1_000_000
    var agendados: [Agendado] = []

    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel {
        let a = Agendado(quando: agoraMs + Int64(ms), acao: acao)
        agendados.append(a)
        return a
    }
    /// Esperas ainda valendo, em milissegundos a partir de agora.
    var proximos: [Int64] { agendados.filter { !$0.cancelado }.map { $0.quando - agoraMs } }

    func avancar(_ ms: Int) {
        agoraMs += Int64(ms)
        while let a = agendados.first(where: { !$0.cancelado && $0.quando <= agoraMs }) {
            a.cancelado = true
            a.acao()
        }
    }
}

/// Deixa as tarefas da fila principal andarem até a condição valer (ou desiste depois de 200 voltas).
@MainActor func ate(_ condicao: @MainActor () -> Bool) async {
    for _ in 0..<200 where !condicao() { await Task.yield() }
}

func blobCom(_ nomes: [String], taxa: Double = 1, extra: [String: ValorJSON] = [:]) -> ValorJSON {
    .objeto(["obras": .lista(nomes.enumerated().map { i, nome in
        .objeto(["id": .texto("o\(i)"), "nome": .texto(nome), "dataInicio": .texto("2026-01-01"), "gastos": .lista([])].merging(extra) { $1 })
    }), "config": .objeto(["taxaMensal": .numero(taxa), "topicosCustom": .lista([])])])
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
