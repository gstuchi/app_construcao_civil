import Testing
@testable import CusttaNucleo

@MainActor
struct SincronizadorEscritaTests {
    let transporte = TransporteFalso()
    let relogio = RelogioFalso()

    /// Conta aberta e já vista: o servidor respondeu que o documento ainda não existe.
    func montar(online: Bool = true) -> Sincronizador {
        let s = Sincronizador(transporte: transporte, relogio: relogio, online: online)
        s.iniciar(uid: "u1")
        transporte.chega(nil)
        return s
    }

    @Test func salvarEntregaNaHoraEVoltaSoComAConfirmacao() async throws {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Casa"]))) }
        await ate { transporte.gravacoes.count == 1 }
        #expect(transporte.gravacoes[0].uid == "u1")
        #expect(s.estadoSinc == .salvando)
        #expect(s.estado.obras.map(\.nome) == ["Casa"], "a tela vê a mudança antes do servidor")
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
        #expect(!s.temPendencia)
    }

    @Test func semRedeMostraSemConexaoEEnviaMesmoAssim() async throws {
        let s = montar(online: false)
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Casa"]))) }
        await ate { transporte.gravacoes.count == 1 }
        #expect(s.estadoSinc == .offline)
        s.redeMudou(online: true)
        #expect(s.estadoSinc == .salvando)
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func soAConfirmacaoDaVersaoMaisNovaConta() async throws {
        let s = montar()
        let primeira = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        let segunda = Task { try await s.salvar(Estado.de(blobCom(["A", "B"]))) }
        await ate { transporte.gravacoes.count == 2 }
        transporte.gravacoes[0].concluir(nil)
        #expect(s.estadoSinc == .salvando, "confirmação velha não encerra a fila")
        transporte.gravacoes[1].concluir(nil)
        try await primeira.value
        try await segunda.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func erroTerminalParaERejeita() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("permission-denied")
        await #expect(throws: ErroSinc(codigo: "permission-denied")) { try await tarefa.value }
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .escrita))
        #expect(relogio.proximos.isEmpty, "terminal não agenda nova tentativa")
        #expect(avisos == [.naoSalvou(codigo: "permission-denied", terminal: true)])
        #expect(indicador(s.estadoSinc)?.rotulo == "Não salvou")
    }

    @Test func erroTransitorioTentaDeNovoComBackoff() async throws {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        #expect(s.estadoSinc == .repetindo)
        #expect(relogio.proximos == [1000])
        relogio.avancar(1000)
        #expect(transporte.gravacoes.count == 2)
        transporte.gravacoes[1].concluir("unavailable")
        #expect(relogio.proximos == [2000])
        relogio.avancar(2000)
        transporte.gravacoes[2].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func acimaDoLimiteNaoGravaEAvisa() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let grande = Estado.de(blobCom(["A"], extra: ["notas": .texto(String(repeating: "a", count: 900_000))]))
        await #expect(throws: ErroSinc(codigo: "limite")) { try await s.salvar(grande) }
        #expect(transporte.gravacoes.isEmpty)
        #expect(s.estadoSinc == .erro(codigo: "limite", origem: .escrita))
        #expect(avisos.last?.mensagem == "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.")
    }

    @Test func pertoDoLimiteAvisaUmaVezAteVoltarParaBaixo() async throws {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let perto = Estado.de(blobCom(["A"], extra: ["notas": .texto(String(repeating: "a", count: 750_000))]))
        for i in 0..<2 {
            let t = Task { try await s.salvar(perto) }
            await ate { transporte.gravacoes.count == i + 1 }
            transporte.gravacoes[i].concluir(nil)
            try await t.value
        }
        #expect(avisos.filter { $0 == .pertoDoLimite }.count == 1)
        let pequeno = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 3 }
        transporte.gravacoes[2].concluir(nil)
        try await pequeno.value
        let t = Task { try await s.salvar(perto) }
        await ate { transporte.gravacoes.count == 4 }
        transporte.gravacoes[3].concluir(nil)
        try await t.value
        #expect(avisos.filter { $0 == .pertoDoLimite }.count == 2, "voltou para baixo de 700 mil: avisa de novo")
    }

    @Test func redeQueVoltaTentaJaOQueEstavaPendente() async throws {
        let s = montar()
        var pedidosDeSessao: [Bool] = []
        s.aoPedirVerificacaoDeSessao = { pedidosDeSessao.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        relogio.avancar(1000)
        transporte.gravacoes[1].concluir("unavailable")
        s.redeMudou(online: true)
        relogio.avancar(0)
        #expect(transporte.gravacoes.count == 3, "não espera os 2 s do backoff")
        #expect(pedidosDeSessao == [false], "rede que volta confere a sessão sem forçar, como o cloud.js")
        transporte.gravacoes[2].concluir(nil)
        try await tarefa.value
    }

    @Test func redeQueCaiMostraSemConexaoMasNaoApagaErro() async {
        let s = montar()
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .offline)
        s.redeMudou(online: true)
        #expect(s.estadoSinc == .ocioso)
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("invalid-argument")
        _ = try? await tarefa.value
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .erro(codigo: "invalid-argument", origem: .escrita))
        s.redeMudou(online: true)
        relogio.avancar(0)
        #expect(s.estadoSinc == .erro(codigo: "invalid-argument", origem: .escrita), "nem a rede que volta apaga o erro terminal")
        #expect(transporte.gravacoes.count == 1, "erro terminal só sobe de novo pelo toque, como no cloud.js")
    }

    @Test func tentarDeNovoDepoisDeErroTerminalReenvia() async throws {
        let s = montar()
        let primeira = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("permission-denied")
        _ = try? await primeira.value
        s.tentarDeNovo()
        #expect(transporte.gravacoes.count == 2)
        #expect(s.estadoSinc == .salvando)
        transporte.gravacoes[1].concluir(nil)
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func naoAutenticadoPedeParaConferirASessao() async {
        let s = montar()
        var pedidos: [Bool] = []
        s.aoPedirVerificacaoDeSessao = { pedidos.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unauthenticated")
        _ = try? await tarefa.value
        #expect(pedidos == [true], "sessão recusada na escrita força a conferência, como o cloud.js")
    }

    @Test func semContaNaoSalva() async {
        let s = Sincronizador(transporte: transporte, relogio: relogio)
        var avisos: [AvisoSinc] = []
        s.aoAvisar = { avisos.append($0) }
        await #expect(throws: ErroSinc(codigo: "cancelled")) { try await s.salvar(.vazio) }
        #expect(transporte.gravacoes.isEmpty)
        #expect(avisos == [.naoSalvou(codigo: "cancelled", terminal: true)])
    }

    @Test func avisoTransitorioNoMaximoUmACada30Segundos() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        relogio.avancar(1000)
        transporte.gravacoes[1].concluir("unavailable")
        #expect(avisos.count == 1)
        relogio.avancar(30_000)
        transporte.gravacoes[2].concluir("unavailable")
        #expect(avisos.count == 2)
        #expect(avisos[0].mensagem == "Sem salvar na nuvem agora — vamos tentar de novo sozinhos.")
        s.parar()
        _ = try? await tarefa.value
    }

    @Test func aguardarFilaEsperaATarefaEOSDK() async {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        let fila = Task { await s.aguardarFila() }
        await ate { transporte.esperasDePendentes.count == 1 }
        transporte.gravacoes.last!.concluir(nil)
        transporte.esperasDePendentes[0](nil)
        #expect(await fila.value == true)
        _ = try? await tarefa.value
    }

    @Test func aguardarFilaDesisteDepoisDoTempo() async {
        let s = montar()
        let fila = Task { await s.aguardarFila(timeoutMs: 5000) }
        await ate { transporte.esperasDePendentes.count == 1 }
        relogio.avancar(5000)
        #expect(await fila.value == false)
    }

    @Test func pararRejeitaQuemEsperavaEZeraTudo() async {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        s.parar()
        await #expect(throws: ErroSinc(codigo: "cancelled")) { try await tarefa.value }
        transporte.gravacoes[0].concluir(nil)
        #expect(s.estadoSinc == .ocioso)
        #expect(s.estado == .vazio)
        #expect(transporte.escutas[0].cancelada)
    }

    @Test func trocaDeContaNaoGravaNadaNaContaNova() async {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Da u1"]))) }
        await ate { transporte.gravacoes.count == 1 }
        s.iniciar(uid: "u2")
        await #expect(throws: ErroSinc(codigo: "cancelled")) { try await tarefa.value }
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { d.terminou }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"), "a conta que entrou ainda não teve os dados vistos")
        transporte.gravacoes[0].concluir("unavailable")
        relogio.avancar(30_000)
        #expect(transporte.gravacoes.count == 1, "a falha atrasada da u1 não volta para a fila e não sobe na u2")
    }
}

@MainActor
struct SincronizadorLeituraTests {
    let transporte = TransporteFalso()
    let relogio = RelogioFalso()

    func montar() -> Sincronizador {
        let s = Sincronizador(transporte: transporte, relogio: relogio)
        s.iniciar(uid: "u1")
        return s
    }

    @Test func snapshotNormalizaETrocaOEstado() {
        let s = montar()
        #expect(!s.dadosCarregados)
        transporte.chega(blobCom(["Casa"], taxa: 99))
        #expect(s.estado.obras.map(\.nome) == ["Casa"])
        #expect(s.estado.config.taxaMensal == 1, "passou pela normalização")
        #expect(s.dadosCarregados)
    }

    @Test func documentoQueNaoExisteViraEstadoVazio() {
        let s = montar()
        transporte.chega(nil)
        #expect(s.estado == .vazio)
        #expect(s.dadosCarregados)
    }

    @Test func snapshotIgualNaoTrocaOEstado() {
        let s = montar()
        transporte.chega(blobCom(["Casa"]))
        let antes = s.estado
        transporte.chega(blobCom(["Casa"]))
        #expect(s.estado == antes)
    }

    @Test func ecoComGravacaoLocalPendenteEIgnorado() async throws {
        let s = montar()
        transporte.chega(blobCom(["Velha"]))
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.chega(blobCom(["Velha"]), doCache: true, pendente: true)
        #expect(s.estado.obras.map(\.nome) == ["Nova"], "snapshot com edição local pendente não troca o estado")
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        transporte.chega(blobCom(["Do site"]))
        #expect(s.estado.obras.map(\.nome) == ["Do site"], "depois da confirmação, mudança de fora entra")
    }

    @Test func gravacaoPendenteNoCacheMostraSalvando() {
        let s = montar()
        transporte.chega(blobCom(["A"]), doCache: true, pendente: true)
        #expect(s.estadoSinc == .salvando)
        transporte.chega(blobCom(["A"]))
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func erroDeLeituraMostraNaoSincronizouEAvisa() {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        transporte.escutas[0].aoFalhar("permission-denied")
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .leitura))
        #expect(indicador(s.estadoSinc)?.rotulo == "Não sincronizou")
        #expect(avisos == [.naoLeu(codigo: "permission-denied")])
        #expect(avisos[0].mensagem == "Não consegui ler seus dados da nuvem agora (permission-denied).")
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .leitura), "erro de leitura não some sozinho")
    }

    @Test func tentarDeNovoReabreAEscutaQueFalhou() {
        let s = montar()
        transporte.escutas[0].aoFalhar("unavailable")
        s.tentarDeNovo()
        #expect(transporte.escutas.count == 2)
        transporte.chega(blobCom(["A"]))
        #expect(s.estadoSinc == .ocioso)
        #expect(s.estado.obras.count == 1)
    }

    @Test func snapshotDeEscutaAntigaEIgnorado() {
        let s = montar()
        let antiga = transporte.escutas[0]
        s.iniciar(uid: "u2")
        antiga.aoReceber(Instantaneo(dados: blobCom(["Da outra conta"]), doCache: false, gravacaoPendente: false))
        #expect(s.estado == .vazio)
        #expect(antiga.cancelada)
    }

    @Test func indicadorInvisivelQuandoEmDia() {
        #expect(indicador(.ocioso) == nil)
        #expect(indicador(.salvando)?.girando == true)
        #expect(indicador(.repetindo)?.rotulo == "Salvando…")
        #expect(indicador(.offline)?.rotulo == "Sem conexão")
        #expect(indicador(.erro(codigo: "x", origem: .escrita))?.dica == "Não foi possível sincronizar. Toque para tentar de novo.")
    }
}

/// Os três jeitos de abrir o app: só grava quem já viu os dados de verdade.
struct CenarioDeAbertura: Sendable, CustomTestStringConvertible {
    let nome: String
    let doCache: Bool
    let comDocumento: Bool
    let podeGravar: Bool
    var testDescription: String { nome }
}

private let cenariosDeAbertura = [
    CenarioDeAbertura(nome: "sem rede e sem dados no aparelho", doCache: true, comDocumento: false, podeGravar: false),
    CenarioDeAbertura(nome: "com rede e conta ainda sem documento", doCache: false, comDocumento: false, podeGravar: true),
    CenarioDeAbertura(nome: "sem rede e com o blob no cache", doCache: true, comDocumento: true, podeGravar: true),
]

/* Sem a guarda, `salvar` ficaria esperando uma confirmação que o transporte falso nunca dá. As esperas
   destes testes são limitadas (`Desfecho` e `ate`), então eles falham na hora em vez de travar; o
   limite de tempo é a última trava. */
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SincronizadorCarregamentoTests {
    @Test(arguments: cenariosDeAbertura)
    func salvarSoDepoisDeVerOsDados(_ c: CenarioDeAbertura) async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), online: !c.doCache)
        s.iniciar(uid: "u1")
        transporte.chega(c.comDocumento ? blobCom(["Casa"]) : nil, doCache: c.doCache)
        #expect(s.dadosCarregados == c.podeGravar)
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        if c.podeGravar {
            await ate { transporte.gravacoes.count == 1 }
            #expect(transporte.gravacoes.count == 1)
            transporte.gravacoes.first?.concluir(nil)
            await ate { d.terminou }
            #expect(d.terminou && d.erro == nil)
        } else {
            await ate { d.terminou }
            #expect(d.terminou, "salvar tem de recusar na hora")
            #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
            #expect(transporte.gravacoes.isEmpty, "nada sobe por cima do documento que só o servidor tem")
            #expect(s.estado == .vazio, "a edição recusada não troca o estado")
        }
    }

    @Test func erroDeLeituraAntesDeCarregarNaoDeixaGravar() async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.escutas[0].aoFalhar("formato-desconhecido")
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { d.terminou }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
        #expect(transporte.gravacoes.isEmpty)
        #expect(indicador(s.estadoSinc)?.rotulo == "Não sincronizou")
    }

    @Test func documentoIlegivelDepoisDeCarregadoVoltaANaoGravar() async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.chega(blobCom(["Casa"]), doCache: true)
        #expect(s.dadosCarregados)
        transporte.escutas[0].aoFalhar("formato-desconhecido")
        #expect(!s.dadosCarregados, "quem não leu o documento inteiro não grava")
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { d.terminou }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
        #expect(transporte.gravacoes.isEmpty)
        #expect(s.estado.obras.map(\.nome) == ["Casa"], "a tela continua com o que já tinha lido")
        transporte.chega(blobCom(["Casa", "Sobrado"]))
        #expect(s.dadosCarregados, "um snapshot bom depois volta a deixar gravar")
    }

    @Test func erroDoFirestoreDepoisDeCarregadoNaoBloqueia() {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.chega(blobCom(["Casa"]))
        transporte.escutas[0].aoFalhar("unavailable")
        #expect(s.dadosCarregados, "o que foi lido continua inteiro; como no site, dá para gravar")
    }
}
