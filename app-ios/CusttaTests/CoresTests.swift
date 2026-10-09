import Testing
import UIKit
import SwiftUI
@testable import Custta

/* Cores só por tokens: cada token existe nas duas peles, com variante clara e escura; os de fundo e de
   texto mudam entre claro e escuro. */
@MainActor
struct CoresTests {
    @Test(arguments: Pele.allCases)
    func todoTokenExisteNaPele(_ pele: Pele) {
        for token in Token.allCases {
            let nome = Paleta.nome(token, pele)
            let cor = UIColor(named: nome, in: .main, compatibleWith: nil)
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) != nil, "\(nome) sem variante clara")
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)) != nil, "\(nome) sem variante escura")
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

    @Test func aparenciaPadraoEscuraEsmeraldaTransparente() {
        #expect(Aparencia.esquema("qualquer") == .dark)
        #expect(Aparencia.esquema("claro") == .light)
        #expect(Aparencia.pele("azul") == .azul && Aparencia.pele("") == .esmeralda)
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
        for papel in [PapelDoVidro.conteudo, .cartaoEntrada, .segmentado] {
            #expect(transparente.escurecimento(papel, escuro: true) == 0.45)
            #expect(fosco.escurecimento(papel, escuro: true) == 0.2)
            #expect(transparente.escurecimento(papel, escuro: false) == 0 && fosco.escurecimento(papel, escuro: false) == 0)
        }
        #expect(transparente.escurecimento(.navegacao, escuro: true) == 0, "a navegação tem o véu da borda")
        #expect(VidroTokens(nivel: .solido, contorno: false).escurecimento(.conteudo, escuro: true) == 0)
    }

    @Test func veuDaBordaDoMockup() {
        #expect(VeuDaBorda.opacidade(grande: false, reduzirTransparencia: false) == (0.50, 0.35))
        #expect(VeuDaBorda.opacidade(grande: true, reduzirTransparencia: false) == (0.70, 0.60))
        #expect(VeuDaBorda.opacidade(grande: false, reduzirTransparencia: true) == (0.88, 0.80))
        #expect(VeuDaBorda.opacidade(grande: true, reduzirTransparencia: true) == (0.88, 0.80))
    }

    @Test func textoSobreOVidroPorNivel() {
        #expect(VidroTokens(nivel: .transparente, contorno: false).secundario == .secundarioTransparente)
        #expect(VidroTokens(nivel: .fosco, contorno: false).secundario == .secundarioFosco)
        #expect(VidroTokens(nivel: .solido, contorno: false).secundario == .secundarioSolido)
        #expect(VidroTokens(nivel: .transparente, contorno: false).link == .texto, "link solto na cor do texto")
        #expect(VidroTokens(nivel: .fosco, contorno: false).link == .linkNoVidro)
    }

    @Test func fundoSoAndaSemReduzirMovimentoESemPoucaEnergia() {
        #expect(OpcoesDoAparelho().animaFundo)
        #expect(!OpcoesDoAparelho(reduzirMovimento: true).animaFundo)
        #expect(!OpcoesDoAparelho(poucaEnergia: true).animaFundo)
    }
}
