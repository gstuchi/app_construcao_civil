import Foundation
import Testing
import UIKit
@testable import Custta

/* SONDA 1 DO PDF (ramo proto/etapa4-sondas-pdf; nunca vai à main): o gerador fora da thread principal, compilado pelo
   Swift da CI. Um método por variante; na CI cada um roda sozinho (-only-testing), para uma queda não levar os outros.
   (a) destacadoIgualAoDaPrincipal500/5000: o gerador destacado sai igual ao mesmo gerador todo na principal (texto e
       pixels por página, em escala 1);
   (b) controleDoVerificador: o Main Thread Checker acusa UIKit fora da principal (controle positivo);
       geradorSemAvisoDoVerificador: o gerador não é acusado. Sem MTC_CRASH_ON_REPORT, o relato é lido do stderr
       capturado; com ele, o relato derruba o processo (o controle cai, e o gerador passa);
   (c) bloqueioETempo5000: o maior bloqueio da principal e o tempo total com 5.000 gastos (números, sem reprovar). */

@Suite(.serialized)
struct SondaPDFGeradorTests {

    // MARK: (a) igual fora e dentro da principal

    @Test @MainActor func destacadoIgualAoDaPrincipal500() async throws {
        try await compararPrincipalEDestacado(500)
    }

    @Test @MainActor func destacadoIgualAoDaPrincipal5000() async throws {
        try await compararPrincipalEDestacado(5000)
    }

    @MainActor private func compararPrincipalEDestacado(_ n: Int) async throws {
        let passo = "igual-\(n)"
        registrarAmbiente(passo)
        let r = DadosDaSonda.relatorio(gastos: n)
        let urlPrincipal = SaidaDaSonda.temporario("principal-\(n).pdf"), urlDestacado = SaidaDaSonda.temporario("destacado-\(n).pdf")
        // o mesmo gerador, todo na thread principal
        let t0 = CACurrentMediaTime()
        let paginacao = PaginacaoDoPDF.paginar(r)
        let figura = GeradorDoPDF.paginaUm(r, total: paginacao.total)
        _ = try GeradorDoPDF.escrever(r, paginacao: paginacao, paginaUm: figura, em: urlPrincipal, marcacao: nil)
        let tempoNaPrincipal = CACurrentMediaTime() - t0
        // o fluxo de produção: paginação e tabelas num Task.detached, a página 1 na principal
        let resumo = try await GeradorDoPDF.gerar(r, em: urlDestacado, marcacao: nil)
        let c = ComparacaoDePDF.comparar(urlPrincipal, urlDestacado)
        SaidaDaSonda.registrar(passo, "\(c.resumo); fora da principal: \(resumo.foraDaPrincipal); \(resumo.paginas) páginas, "
                               + "\(resumo.bytes) bytes; tempo todo na principal \(SaidaDaSonda.ms(tempoNaPrincipal)) ms, "
                               + "destacado \(SaidaDaSonda.ms(resumo.total)) ms")
        #expect(resumo.foraDaPrincipal)
        #expect(c.paginasA == paginacao.total && c.paginasB == paginacao.total)
        #expect(c.textoDiferente == 0)
        #expect(c.pixelDiferente == 0)
    }

    // MARK: (b) o Main Thread Checker

    @Test func controleDoVerificador() async throws {
        let carregado = VerificadorDaThreadPrincipal.carregado()
        let derruba = VerificadorDaThreadPrincipal.derrubaNoRelato
        SaidaDaSonda.registrar("mtc-controle", "verificador carregado: \(carregado); MTC_CRASH_ON_REPORT: \(derruba); "
                               + "agora uma chamada de UIView fora da principal, de propósito")
        let captura = derruba ? nil : CapturaDoStderr()
        await Task.detached {
            // Por nome, para o compilador deixar: no Swift 6 a UIView é da MainActor.
            let classe = NSClassFromString("UIView") as? NSObject.Type
            let v = classe?.init()
            _ = v?.perform(NSSelectorFromString("setNeedsLayout"))
        }.value
        let avisos = VerificadorDaThreadPrincipal.avisos(em: captura?.terminar() ?? "")
        SaidaDaSonda.registrar("mtc-controle", "avisos do verificador no stderr: \(avisos.count)" + (avisos.first.map { " · \($0)" } ?? ""))
        #expect(carregado)
        #expect(avisos.count >= 1)
    }

    @Test @MainActor func geradorSemAvisoDoVerificador() async throws {
        registrarAmbiente("mtc-gerador")
        let carregado = VerificadorDaThreadPrincipal.carregado()
        let captura = VerificadorDaThreadPrincipal.derrubaNoRelato ? nil : CapturaDoStderr()
        let semMarcacao = try await GeradorDoPDF.gerar(DadosDaSonda.relatorio(gastos: 5000), em: SaidaDaSonda.temporario("mtc-5000.pdf"),
                                                      marcacao: nil)
        let comMarcacao = try await GeradorDoPDF.gerar(DadosDaSonda.relatorio(gastos: 500), em: SaidaDaSonda.temporario("mtc-marcado-500.pdf"),
                                                      marcacao: .padrao)
        let stderr = captura?.terminar() ?? ""
        let avisos = VerificadorDaThreadPrincipal.avisos(em: stderr)
        let outras = stderr.split(separator: "\n").filter { !$0.contains("Main Thread Checker") }
        SaidaDaSonda.registrar("mtc-gerador", "verificador carregado: \(carregado); MTC_CRASH_ON_REPORT: "
                               + "\(VerificadorDaThreadPrincipal.derrubaNoRelato); 5.000 sem marcação (\(semMarcacao.paginas) páginas) "
                               + "e 500 com marcação (\(comMarcacao.paginas) páginas), fora da principal: "
                               + "\(semMarcacao.foraDaPrincipal && comMarcacao.foraDaPrincipal); avisos do verificador: \(avisos.count)"
                               + (avisos.first.map { " · \($0)" } ?? "") + "; outras linhas no stderr: \(outras.count)"
                               + (outras.first.map { " · \($0.prefix(160))" } ?? ""))
        #expect(carregado)
        #expect(semMarcacao.foraDaPrincipal && comMarcacao.foraDaPrincipal)
        #expect(avisos.isEmpty)
    }

    // MARK: (c) bloqueio da principal e tempo com 5.000 gastos

    @Test @MainActor func bloqueioETempo5000() async throws {
        typealias S = SaidaDaSonda
        registrarAmbiente("bloqueio-5000")
        AmbienteDaSonda.esvaziarApp()
        try await Task.sleep(for: .milliseconds(300))
        // o chão: a principal parada, sem gerar nada
        var chao: [Double] = []
        for _ in 1...3 {
            let v = VigiaDaThreadPrincipal()
            v.comecar()
            try await Task.sleep(for: .milliseconds(500))
            chao.append(await v.parar().lacuna)
        }
        S.registrar("bloqueio-ocioso", "maior intervalo do Timer de 1 ms com a principal parada: \(chao.map(S.ms).joined(separator: ", ")) ms")
        _ = try await GeradorDoPDF.gerar(DadosDaSonda.relatorio(gastos: 500), em: S.temporario("aquecimento.pdf"), marcacao: nil)
        let r = DadosDaSonda.relatorio(gastos: 5000)
        var totais: [Double] = [], lacunas: [Double] = [], pings: [Double] = [], paginasUm: [Double] = [], memorias: [Double] = []
        for k in 1...3 {
            let url = S.temporario("bloqueio-5000.pdf")
            try? FileManager.default.removeItem(at: url)
            let vigia = VigiaDaThreadPrincipal(), memoria = AmostradorDeMemoria()
            vigia.comecar()
            try await Task.sleep(for: .milliseconds(40))
            memoria.comecar()
            let resumo = try await GeradorDoPDF.gerar(r, em: url, marcacao: nil)
            let mem = memoria.parar()
            try await Task.sleep(for: .milliseconds(40))
            let (lacuna, ping) = await vigia.parar()
            totais.append(resumo.total); lacunas.append(lacuna); pings.append(ping); paginasUm.append(resumo.paginaUm); memorias.append(mem.aumento)
            S.registrar("bloqueio-5000", "rodada \(k): total \(S.ms(resumo.total)) ms (paginação \(S.ms(resumo.paginacao)), página 1 "
                        + "\(S.ms(resumo.paginaUm)) na principal, escrita \(S.ms(resumo.escrita)), maior página \(S.ms(resumo.maiorPagina))); "
                        + "maior bloqueio da principal: Timer \(S.ms(lacuna)) ms, ping \(S.ms(ping)) ms; memória +\(S.mb(mem.aumento)) MB "
                        + "(pico \(S.mb(mem.pico)) MB); "
                        + "\(resumo.paginas) páginas, \(resumo.bytes) bytes")
            try await Task.sleep(for: .milliseconds(100))
        }
        S.registrar("bloqueio-5000", "mediana de 3: total \(S.ms(S.mediana(totais))) ms; maior bloqueio da principal: Timer "
                    + "\(S.ms(S.mediana(lacunas))) ms, ping \(S.ms(S.mediana(pings))) ms (pior: \(S.ms(lacunas.max() ?? 0)) e "
                    + "\(S.ms(pings.max() ?? 0))); página 1 \(S.ms(S.mediana(paginasUm))) ms; memória +\(S.mb(S.mediana(memorias))) MB")
    }
}
