import SwiftUI

/* Dose de vidro por tela (decisão do Giovani em 06/10; mockup aprovado, "Tokens de vidro, agora por
   tela"): entrar, criar conta e falta pouco usam sempre o Fosco; as telas do app, o Transparente
   (padrão) ou o Fosco escolhido em Ajustes › Aparência (etapa 5). As opções do iPhone passam por
   cima das duas: "Aumentar contraste" leva tudo ao Fosco com contorno de 1,5 pt e "Reduzir
   transparência", a superfícies sólidas (a aurora continua). Aro especular, sombra e refração são
   do glassEffect do sistema; no escuro, uma camada do tom do fundo sob o vidro do conteúdo faz o que o
   vidro do mockup fazia ao escurecer o fundo. Nunca vidro dentro de vidro: o que fica dentro de uma
   superfície é sólido. */

enum TelaDoVidro: Sendable { case entrada, app }

/// A escolha de Ajustes › Aparência (etapa 5); até lá vale o padrão, Transparente.
enum EscolhaDeVidro: String, CaseIterable, Sendable { case transparente, fosco }

/// O nível que vale de fato, depois das opções do iPhone.
enum NivelDeVidro: Sendable { case transparente, fosco, solido }

/// O papel de cada superfície: a tinta muda com ele.
enum PapelDoVidro: Sendable {
    /// O cartão de entrar, criar conta e falta pouco.
    case cartaoEntrada
    /// "Entrar | Criar conta", fora do cartão.
    case segmentado
    /// Cartões e painéis das telas do app.
    case conteudo
    /// Cápsula de abas, sair e sincronização.
    case navegacao
}

/// As opções do iPhone que mudam o visual, lidas uma vez na raiz. Em Debug, os testes de tela ligam
/// cada uma por argumento (`-custta.reduzirMovimento YES`), porque o XCUITest não muda os ajustes do sistema.
struct OpcoesDoAparelho: Equatable, Sendable {
    var reduzirMovimento = false
    var reduzirTransparencia = false
    var aumentarContraste = false
    /// Modo de Pouca Energia: aurora, globo e logo param, como com Reduzir movimento.
    var poucaEnergia = false
    /// Aparelho quente (estado térmico sério ou crítico): param como na Pouca Energia.
    var calor = false

    /// Animação própria (aurora, globo e logo) só sem os três.
    var animaFundo: Bool { !reduzirMovimento && !poucaEnergia && !calor }

    /// Estados térmicos em que o fundo para (o ThermalState não é Comparable).
    static func quente(_ estado: ProcessInfo.ThermalState) -> Bool { estado == .serious || estado == .critical }
}

struct VidroTokens: Equatable, Sendable {
    let nivel: NivelDeVidro
    let contorno: Bool

    static func para(tela: TelaDoVidro, escolha: EscolhaDeVidro, opcoes: OpcoesDoAparelho) -> VidroTokens {
        if opcoes.reduzirTransparencia { return VidroTokens(nivel: .solido, contorno: false) }
        let fosco = tela == .entrada || escolha == .fosco || opcoes.aumentarContraste
        return VidroTokens(nivel: fosco ? .fosco : .transparente, contorno: opcoes.aumentarContraste)
    }

    /// Opacidade da tinta sobre o vidro, do mockup aprovado.
    func tinta(_ papel: PapelDoVidro, escuro: Bool) -> Double {
        switch (nivel, papel) {
        case (.solido, _): return 1
        case (.fosco, .cartaoEntrada): return escuro ? 0.44 : 0.52
        case (.fosco, .segmentado), (.fosco, .conteudo): return escuro ? 0.24 : 0.34
        case (.fosco, .navegacao): return escuro ? 0.22 : 0.36
        case (.transparente, .navegacao): return escuro ? 0.08 : 0.16
        case (.transparente, _): return escuro ? 0.06 : 0.14
        }
    }

    /// Escurecimento sob o vidro: só no escuro e fora da navegação, 45% no Transparente e 20% no Fosco (decisão
    /// do Giovani em 09/10, com o laudo de leitura como juiz). O vidro do iOS clareia o fundo e quase não o
    /// desfoca, e o texto dos cartões não fechava 4,5:1 sobre a aurora e os pontos do globo; o vidro do mockup
    /// escurecia o fundo (brilho de 0,84 no Transparente e 0,56 no Fosco). A navegação tem o véu da borda.
    func escurecimento(_ papel: PapelDoVidro, escuro: Bool) -> Double {
        guard escuro, papel != .navegacao else { return 0 }
        switch nivel {
        case .transparente: return 0.45
        case .fosco: return 0.2
        case .solido: return 0
        }
    }

    func corDaTinta(_ papel: PapelDoVidro) -> Token {
        switch papel {
        case .cartaoEntrada: return .tintaCartao
        case .segmentado, .conteudo: return .tintaConteudo
        case .navegacao: return .tintaNavegacao
        }
    }

    /// Texto secundário sobre a superfície (o --muted do site não fecha 4,5:1 sobre o vidro).
    var secundario: Token {
        switch nivel {
        case .transparente: return .secundarioTransparente
        case .fosco: return .secundarioFosco
        case .solido: return .secundarioSolido
        }
    }

    /// Link solto: no Transparente, a cor do texto com sublinhado da marca; nos outros, a cor do link sobre o vidro.
    var link: Token { nivel == .transparente ? .texto : .linkNoVidro }

    /// O "N obras" de Obras: pílula no Transparente e, sólida, com Reduzir transparência (mockup aprovado);
    /// texto solto no Fosco, que é também o nível do Aumentar contraste.
    var contagemEmPilula: Bool { nivel != .fosco }
}

/// O véu da borda de rolagem (mockup v2, decisão do Giovani em 09/10), em opacidade do tom do fundo na beirada
/// de cima e na de baixo: 50% e nenhum (embaixo fica só a borda do sistema: com a pílula sólida, o rótulo da
/// aba escolhida não depende do véu; decisão do Giovani em 10/10); nos tamanhos de acessibilidade, 70% e 60%
/// (o texto grande que passa por baixo é mais claro); com Reduzir transparência, sem o desfoque, 88% e 80%.
enum VeuDaBorda {
    static func opacidade(grande: Bool, reduzirTransparencia: Bool) -> (topo: Double, base: Double) {
        if reduzirTransparencia { return (0.88, 0.80) }
        return grande ? (0.70, 0.60) : (0.50, 0)
    }
}

extension EnvironmentValues {
    @Entry var opcoes = OpcoesDoAparelho()
    @Entry var vidro = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho())
}

/// Superfície de vidro (ou sólida) no papel dado, com a tinta, o material e o contorno do nível.
struct Superficie<Forma: InsettableShape>: ViewModifier {
    let papel: PapelDoVidro
    let forma: Forma
    @Environment(\.vidro) private var vidro
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    #if DEBUG
    @Environment(\.apagaTextoDaNavegacao) private var apagaTextoDaNavegacao
    #endif

    func body(content: Content) -> some View {
        let escuro = esquema == .dark
        let tinta = paleta.cor(vidro.corDaTinta(papel)).opacity(vidro.tinta(papel, escuro: escuro))
        // Atrás do vidro: o vidro vê o fundo já escurecido.
        let sob = paleta.cor(.fundo).opacity(vidro.escurecimento(papel, escuro: escuro))
        Group {
            switch vidro.nivel {
            case .solido: conteudo(content).background(paleta.cor(.superficie), in: forma)
            case .fosco: conteudo(content).glassEffect(.regular.tint(tinta), in: forma).background(sob, in: forma)
            case .transparente: conteudo(content).glassEffect(.clear.tint(tinta), in: forma).background(sob, in: forma)
            }
        }
        .overlay {
            if vidro.contorno { forma.strokeBorder(paleta.cor(.contorno), lineWidth: 1.5) }
        }
    }

    private func conteudo(_ content: Content) -> some View {
        #if DEBUG
        return content.modifier(ApagaTexto(ativo: apagaTextoDaNavegacao && papel == .navegacao))
        #else
        return content
        #endif
    }
}

#if DEBUG
/// Laudo de leitura (Tarefa 11, só Debug): o texto some sem mexer no layout, para o print mostrar só o que
/// fica atrás dele. Com `-custta.textoApagado tudo` some todo texto do SwiftUI; com `navegacao`, só o da
/// cápsula de abas e da barra, para medir os rótulos delas sobre o conteúdo que passa por baixo.
struct TextoApagado: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {}
}

struct ApagaTexto: ViewModifier {
    let ativo: Bool

    func body(content: Content) -> some View {
        if ativo { content.textRenderer(TextoApagado()) } else { content }
    }
}

extension EnvironmentValues {
    @Entry var apagaTextoDaNavegacao = false
}
#endif

extension View {
    func superficie<Forma: InsettableShape>(_ papel: PapelDoVidro, em forma: Forma) -> some View {
        modifier(Superficie(papel: papel, forma: forma))
    }
}
