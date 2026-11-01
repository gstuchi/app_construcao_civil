import Testing
import UIKit
import SwiftUI
@testable import Custta

/* Cores só por tokens: cada token existe na pele Esmeralda, com variante clara e escura; os de fundo e de
   texto mudam entre claro e escuro. */
@MainActor
struct CoresTests {
    @Test(arguments: Pele.allCases)
    func todoTokenExisteNaPele(_ pele: Pele) {
        for token in Token.allCases {
            let nome = Paleta.nome(token, pele)
            let cor = UIColor(named: nome, in: .main, compatibleWith: nil)
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) != nil, "\(nome) sem variante clara")
        }
    }

    @Test(arguments: Pele.allCases)
    func fundoETextoMudamComOTema(_ pele: Pele) {
        for token in [Token.fundo, .superficie, .texto, .textoSecundario, .marca, .campo] {
            let cor = UIColor(named: Paleta.nome(token, pele), in: .main, compatibleWith: nil)
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                    != cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)), "\(token) igual nos dois temas")
        }
    }

    /// "#RRGGBB" da cor do catálogo no esquema dado; com transparência, "#RRGGBBAA".
    private func hex(_ token: Token, _ estilo: UIUserInterfaceStyle) -> String {
        guard let cor = UIColor(named: Paleta.nome(token, .esmeralda), in: .main, compatibleWith: nil)?
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: estilo)) else { return "" }
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        cor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        return a < 1 ? rgb + String(format: "%02X", Int((a * 255).rounded())) : rgb
    }

    /// A identidade nova da etapa 4, com os valores do mockup aprovado (spec 2026-10-29, "Tokens: do mockup para o app"),
    /// nos dois temas: só os tokens que o app ainda não tinha. O DestaqueNumero do mockup é o PositivoNoVidro, a LinhaBanco é
    /// o SecundarioTransparente e o AmbarTexto é o AlertaNoVidro.
    @Test func tokensDaIdentidadeNova() {
        let tabela: [(Token, escuro: String, claro: String)] = [
            (.destaqueSolido, "#3AD17E", "#3AD17E"), (.tintaSobreDestaque, "#04100C", "#04100C"),
            (.destaqueTexto, "#3AD17E", "#0E7A41"),
            (.solidoAmbar, "#FFD98A", "#F2C15A"), (.tintaSobreAmbar, "#2B1B00", "#2B1B00"),   // o claro: confirmação 1 de 29/10
            (.placa, "#04100C94", "#FFFFFFA8"), (.placaForte, "#04100CD6", "#FFFFFFEB"),        // 58% e 66%; 84% e 92%
            (.grafico1, "#199E70", "#10976A"), (.grafico2, "#3987E5", "#2A78D6"), (.grafico3, "#D55181", "#D14F86"),
            (.grafico4, "#9085E9", "#6250D6"), (.grafico5, "#D95926", "#DC5A1E"), (.grafico6, "#14A3C7", "#0C86A4"),
            (.graficoOutros, "#8FA89C", "#5E7A6E"),
            (.barraApagada, "#EAFFF666", "#142B2394"),                                          // 40% e 58%
            (.gradeGrafico, "#EAFFF624", "#142B2324"), (.eixoGrafico, "#EAFFF64D", "#142B2352"), // 14%; 30% e 32%
            (.anelApagado, "#123128", "#DCEAE3"), (.anelSeparador, "#04100C8C", "#FFFFFFBF"),   // 55% e 75%
            (.luzDoSolido, "#FFFFFF59", "#FFFFFF59"),                                         // o filete do sólido: branco a 35%
        ]
        for (token, escuro, claro) in tabela {
            #expect(hex(token, .dark) == escuro, "\(token) no escuro")
            #expect(hex(token, .light) == claro, "\(token) no claro")
        }
    }

    /// O âmbar de texto sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #5E3A03, o texto mais escuro do
    /// claro da etapa 4 (era #6F4705); no escuro, #FFD98A.
    /// E a decisão 6: no Fosco escuro, o secundário é o do Transparente; no claro, o do Fosco fica.
    @Test func ambarSobreOVidroESecundarioDoFoscoNoEscuro() {
        #expect(hex(.alertaNoVidro, .light) == "#5E3A03")
        #expect(hex(.alertaNoVidro, .dark) == "#FFD98A")
        #expect(hex(.secundarioFosco, .dark) == hex(.secundarioTransparente, .dark))
        #expect(hex(.secundarioFosco, .light) != hex(.secundarioTransparente, .light))
    }

    @Test func aparenciaPadraoEscuraTransparente() {
        #expect(Aparencia.esquema("qualquer") == .dark)
        #expect(Aparencia.esquema("claro") == .light)
        #expect(Aparencia.vidro("fosco") == .fosco && Aparencia.vidro("") == .transparente)
    }
}

/* Dose de vidro por tela, do mockup aprovado. */
struct VidroTokensTests {
    @Test func entradaSempreFosco() {
        for escolha in EscolhaDeVidro.allCases {
            #expect(VidroTokens.para(tela: .entrada, escolha: escolha, opcoes: OpcoesDoAparelho()).nivel == .fosco)
        }
    }

    @Test func appSegueAEscolha() {
        #expect(VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho()).nivel == .transparente)
        #expect(VidroTokens.para(tela: .app, escolha: .fosco, opcoes: OpcoesDoAparelho()).nivel == .fosco)
    }

    @Test func opcoesDoIPhonePassamPorCima() {
        let contraste = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho(aumentarContraste: true))
        #expect(contraste.nivel == .fosco && contraste.contorno, "Aumentar contraste: Fosco com contorno")
        let solido = VidroTokens.para(tela: .entrada, escolha: .fosco,
                                      opcoes: OpcoesDoAparelho(reduzirTransparencia: true, aumentarContraste: true))
        #expect(solido.nivel == .solido && !solido.contorno, "Reduzir transparência: superfícies sólidas")
    }

    @Test func tintasDoMockup() {
        let transparente = VidroTokens(nivel: .transparente, contorno: false), fosco = VidroTokens(nivel: .fosco, contorno: false)
        #expect(transparente.tinta(.conteudo, escuro: true) == 0.06 && transparente.tinta(.conteudo, escuro: false) == 0.14)
        #expect(transparente.tinta(.navegacao, escuro: true) == 0.08 && transparente.tinta(.navegacao, escuro: false) == 0.16)
        #expect(fosco.tinta(.cartaoEntrada, escuro: true) == 0.44 && fosco.tinta(.cartaoEntrada, escuro: false) == 0.52)
        #expect(fosco.tinta(.segmentado, escuro: true) == 0.24 && fosco.tinta(.conteudo, escuro: false) == 0.34)
        #expect(fosco.tinta(.navegacao, escuro: true) == 0.22 && fosco.tinta(.navegacao, escuro: false) == 0.36)
    }

    @Test func escurecimentoSobOVidroSoNoEscuro() {
        let transparente = VidroTokens(nivel: .transparente, contorno: false), fosco = VidroTokens(nivel: .fosco, contorno: true)
        for papel in [PapelDoVidro.conteudo, .cartaoEntrada, .segmentado, .navegacao] {
            #expect(transparente.escurecimento(papel, escuro: true) == 0.5)
            #expect(fosco.escurecimento(papel, escuro: true) == 0.2)
            #expect(transparente.escurecimento(papel, escuro: false) == 0 && fosco.escurecimento(papel, escuro: false) == 0)
        }
        #expect(VidroTokens(nivel: .solido, contorno: false).escurecimento(.conteudo, escuro: true) == 0)
    }

    @Test func veuDaBordaDoMockup() {
        #expect(VeuDaBorda.opacidade(grande: false, reduzirTransparencia: false) == (0.50, 0), "embaixo, só a borda do sistema")
        #expect(VeuDaBorda.opacidade(grande: true, reduzirTransparencia: false) == (0.70, 0.60))
        #expect(VeuDaBorda.opacidade(grande: false, reduzirTransparencia: true) == (0.88, 0.80))
        #expect(VeuDaBorda.opacidade(grande: true, reduzirTransparencia: true) == (0.88, 0.80))
    }

    @Test func haloNoMenorPassoQuePassaNoProMax() {
        #expect(HaloDoTitulo.naEntrada == 0.50, "com 45%, a dica da entrada ficava em 4,06:1")
        #expect(HaloDoTitulo.naBarra == 0.05, "sem halo, o título grande ficava em 4,41:1")
        #expect(HaloDoTitulo.naObraNoClaro == 0.10, "sem halo no claro, o nome da obra ficava em 4,40:1 no 17 Pro da CI")
    }

    @Test func textoSobreOVidroPorNivel() {
        #expect(VidroTokens(nivel: .transparente, contorno: false).secundario == .secundarioTransparente)
        #expect(VidroTokens(nivel: .fosco, contorno: false).secundario == .secundarioFosco)
        #expect(VidroTokens(nivel: .solido, contorno: false).secundario == .secundarioSolido)
        #expect(VidroTokens(nivel: .fosco, contorno: true).secundario == .secundarioTransparente,
                "com Aumentar contraste, o secundário mais forte: ligar a opção não pode baixar a leitura")
        #expect(VidroTokens(nivel: .transparente, contorno: false).link == .texto, "link solto na cor do texto")
        #expect(VidroTokens(nivel: .fosco, contorno: false).link == .linkNoVidro)
    }

    @Test func contagemDeObrasEmPilulaForaDoFosco() {
        #expect(VidroTokens(nivel: .transparente, contorno: false).contagemEmPilula)
        #expect(VidroTokens(nivel: .solido, contorno: false).contagemEmPilula, "Reduzir transparência: pílula sólida, como no mockup")
        #expect(!VidroTokens(nivel: .fosco, contorno: true).contagemEmPilula, "Fosco e Aumentar contraste: texto solto")
    }

    @Test func fundoSoAndaSemReduzirMovimentoESemPoucaEnergia() {
        #expect(OpcoesDoAparelho().animaFundo)
        #expect(!OpcoesDoAparelho(reduzirMovimento: true).animaFundo)
        #expect(!OpcoesDoAparelho(poucaEnergia: true).animaFundo)
    }
}

/* A Superficie desenha o que os tokens decidem: sólida com "Reduzir transparência" e com o contorno do
   "Aumentar contraste" só na borda. Desenhada pelo ImageRenderer, num quadrado de 40 pt a 1x, no escuro. */
@MainActor
struct SuperficieTests {
    /// RGBA do pixel (x, y) da superfície de 40 × 40 desenhada com os tokens dados.
    private func pixel(_ vidro: VidroTokens, x: Int, y: Int) -> [UInt8] {
        let renderer = ImageRenderer(content: Color.clear.frame(width: 40, height: 40)
            .superficie(.conteudo, em: Rectangle()).environment(\.vidro, vidro).environment(\.colorScheme, .dark))
        renderer.scale = 1
        guard let imagem = renderer.cgImage else { return [] }
        var rgba = [UInt8](repeating: 0, count: 4)
        let contexto = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        contexto?.draw(imagem, in: CGRect(x: -x, y: y - imagem.height + 1, width: imagem.width, height: imagem.height))
        return rgba
    }

    @Test func reduzirTransparenciaDesenhaASuperficieSolida() {
        let solido = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho(reduzirTransparencia: true))
        #expect(pixel(solido, x: 20, y: 20) == [0x0C, 0x24, 0x1D, 0xFF], "Esmeralda/Superficie do escuro, sem vidro")
    }

    @Test func aumentarContrasteDesenhaOContornoSoNaBorda() {
        let contorno = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho(aumentarContraste: true))
        let fosco = VidroTokens.para(tela: .app, escolha: .fosco, opcoes: OpcoesDoAparelho())
        #expect(pixel(contorno, x: 0, y: 20) != pixel(fosco, x: 0, y: 20), "contorno de 1,5 pt na borda")
        #expect(pixel(contorno, x: 20, y: 20) == pixel(fosco, x: 20, y: 20), "o miolo é o mesmo Fosco")
    }
}
