import Foundation
import SwiftUI
import Testing
@testable import Custta

/* O tempo do fundo e as curvas do CSS. */
struct MovimentoTests {
    @Test func tempoSoCorreRodando() {
        let t0 = Date(timeIntervalSince1970: 1000)
        var tempo = TempoPausavel()
        #expect(tempo.segundos(em: t0) == 0)
        tempo.rodar(em: t0)
        #expect(tempo.segundos(em: t0.addingTimeInterval(2)) == 2)
        tempo.parar(em: t0.addingTimeInterval(3))
        #expect(tempo.segundos(em: t0.addingTimeInterval(60)) == 3, "parado não anda")
        tempo.rodar(em: t0.addingTimeInterval(60))
        #expect(tempo.segundos(em: t0.addingTimeInterval(61)) == 4, "volta de onde parou, sem pular")
    }

    @MainActor @Test func relogioDoFundoNaoPula() {
        let relogio = RelogioDoFundo()
        relogio.avancar(para: 100)
        #expect(relogio.segundos == 0, "o primeiro quadro só marca a hora")
        relogio.avancar(para: 100 + 1.0 / 30)
        #expect(abs(relogio.segundos - 1.0 / 30) < 1e-9)
        relogio.avancar(para: 160)
        #expect(abs(relogio.segundos - (1.0 / 30 + RelogioDoFundo.passoMaximo)) < 1e-9,
                "um minuto sem quadros (segundo plano, travada) anda no máximo 1/15 s")
    }

    @Test func fundoParaQuandoAlgoSegura() {
        let livre = OpcoesDoAparelho()
        #expect(livre.fundoAnda(ativo: true, rolando: false, teclado: false, coberto: false))
        #expect(!livre.fundoAnda(ativo: false, rolando: false, teclado: false, coberto: false), "app fora de ativo")
        #expect(!livre.fundoAnda(ativo: true, rolando: true, teclado: false, coberto: false), "rolando")
        #expect(!livre.fundoAnda(ativo: true, rolando: false, teclado: true, coberto: false), "teclado aberto")
        #expect(!livre.fundoAnda(ativo: true, rolando: false, teclado: false, coberto: true), "alerta por cima")
        for parado in [OpcoesDoAparelho(reduzirMovimento: true), OpcoesDoAparelho(poucaEnergia: true), OpcoesDoAparelho(calor: true)] {
            #expect(!parado.fundoAnda(ativo: true, rolando: false, teclado: false, coberto: false))
        }
        #expect(OpcoesDoAparelho.quente(.serious) && OpcoesDoAparelho.quente(.critical))
        #expect(!OpcoesDoAparelho.quente(.nominal) && !OpcoesDoAparelho.quente(.fair))
    }

    @MainActor @Test func alertaSeguraOFundoAteSumir() {
        let pausas = PausasDoFundo()
        pausas.cobrir(true)
        #expect(pausas.cobertas == 1)
        pausas.cobrir(false)
        pausas.cobrir(false)
        #expect(pausas.cobertas == 0, "nunca negativo")
    }

    @Test func curvasDoCSS() {
        #expect(CurvaBezier.suave.y(0) == 0 && CurvaBezier.suave.y(1) == 1)
        #expect(abs(CurvaBezier.suave.y(0.5) - 0.5) < 1e-6, "ease-in-out é simétrica")
        #expect(CurvaBezier.suave.y(0.25) < 0.25, "começa devagar")
        let carimbo = CurvaBezier(x1: 0.3, y1: 1.6, x2: 0.5, y2: 1)
        #expect((0..<100).map { carimbo.y(Double($0) / 100) }.max()! > 1, "o carimbo do ponto passa do tamanho e volta")
    }
}

/* A aurora e o globo do PWA. */
struct FundoTests {
    @Test func intensidadeDaAuroraPorTela() {
        #expect(Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true) == 0.92)
        #expect(Aurora.intensidade(tela: .entrada, pele: .azul, escuro: true) == 1)
        #expect(Aurora.intensidade(tela: .app, pele: .esmeralda, escuro: true) == 0.48)
        #expect(Aurora.intensidade(tela: .app, pele: .azul, escuro: true) == 0.52)
        for tela in [TelaDoVidro.entrada, .app] {
            #expect(Aurora.intensidade(tela: tela, pele: .esmeralda, escuro: false) == 0.55)
            #expect(Aurora.intensidade(tela: tela, pele: .azul, escuro: false) == 0.52)
        }
    }

    @Test func globoMaisFundoDentroDoAppNoEscuro() {
        #expect(Globo.intensidade(tela: .app, escuro: true) == 0.4)
        #expect(Globo.intensidade(tela: .entrada, escuro: true) == 1)
        #expect(Globo.intensidade(tela: .app, escuro: false) == 1, "no claro a marca-d'água já deixa o globo a 40%")
    }

    /// O pior caso do laudo de leitura é o mais claro dos quadros, pixel a pixel, e nunca mais claro que ele.
    @MainActor @Test func piorCasoDaAuroraEOMaisClaroDosQuadros() throws {
        let paleta = Paleta(pele: .esmeralda)
        let camada = CamadaAurora(cores: [paleta.cor(.aurora1), paleta.cor(.aurora2), paleta.cor(.aurora3), paleta.cor(.aurora4)],
                                  intensidade: 0.48)
        let fundo = paleta.cor(.fundo)
        func pixels(_ vista: some View) throws -> [UInt8] {
            let r = ImageRenderer(content: vista.frame(width: 60, height: 90).environment(\.colorScheme, .dark))
            r.scale = 1
            let imagem = try #require(r.cgImage)
            var dados = [UInt8](repeating: 0, count: 60 * 90 * 4)
            dados.withUnsafeMutableBytes { bytes in
                let contexto = CGContext(data: bytes.baseAddress, width: 60, height: 90, bitsPerComponent: 8, bytesPerRow: 240,
                                         space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                contexto.draw(imagem, in: CGRect(x: 0, y: 0, width: 60, height: 90))
            }
            return dados
        }
        let quadros = try [0, 13].map { s in try pixels(FundoAurora.movida(camada, Deriva.em(segundos: Double(s)), 60, 90).background(fundo)) }
        let envelope = try pixels(EnvelopeDaAurora(camada: camada, fundo: fundo, escuro: true, largura: 60, altura: 90, segundos: [0, 13]))
        var longe = 0
        for i in envelope.indices where i % 4 != 3 && abs(Int(envelope[i]) - Int(max(quadros[0][i], quadros[1][i]))) > 3 { longe += 1 }
        #expect(longe == 0, "\(longe) canais fora do mais claro dos dois quadros")
    }

    @Test func derivaPassaPelosQuadrosDoSiteEVolta() {
        func perto(_ a: Deriva, _ b: Deriva) -> Bool {
            abs(a.x - b.x) < 1e-9 && abs(a.y - b.y) < 1e-9 && abs(a.giro - b.giro) < 1e-9 && abs(a.escala - b.escala) < 1e-9
        }
        #expect(perto(Deriva.em(segundos: 0), Deriva.quadros[0]))
        #expect(perto(Deriva.em(segundos: 13), Deriva.quadros[1]))
        #expect(perto(Deriva.em(segundos: 26), Deriva.quadros[2]))
        #expect(perto(Deriva.em(segundos: 39), Deriva.quadros[1]), "na volta passa pelo meio de novo")
        #expect(perto(Deriva.em(segundos: 52), Deriva.quadros[0]), "ciclo de 52 s")
    }

    @Test func globoComTerraEOceano() {
        let pontos = PontosDoGlobo.todos
        #expect(pontos.terra.count > 1000 && pontos.oceano.count > 3000)
        #expect(PontosDoGlobo.ehTerra(-47, -15), "Brasil")
        #expect(!PontosDoGlobo.ehTerra(-30, 0), "Atlântico")
        #expect(PontosDoGlobo.ehTerra(0, -80), "Antártida")
        for p in pontos.terra.prefix(50) { #expect(abs(p.x * p.x + p.y * p.y + p.z * p.z - 1) < 1e-9) }
    }
}
