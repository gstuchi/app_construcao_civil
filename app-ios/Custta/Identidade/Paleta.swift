import SwiftUI

/* Cores só por tokens (spec, seção 8): cada token existe no Assets.xcassets para as duas peles
   (Esmeralda e Azul), com variante clara e escura, gerado por scripts/cores-app-ios.mjs.
   Nenhuma cor solta nas telas (componentes RGB ou cor nomeada do sistema): tests/app-ios.test.cjs confere. */

enum Pele: String, CaseIterable, Sendable {
    case esmeralda = "Esmeralda"
    case azul = "Azul"
}

enum Token: String, CaseIterable, Sendable {
    case fundo = "Fundo"
    case superficie = "Superficie"
    case linha = "Linha"
    /// A linha fina dentro dos cartões de vidro: clara no escuro (o Linha sólido sumia sobre o vidro).
    case linhaNoVidro = "LinhaNoVidro"
    case texto = "Texto"
    case textoSecundario = "TextoSecundario"
    case textoTerciario = "TextoTerciario"
    case marca = "Marca"
    case destaque = "Destaque"
    case positivo = "Positivo"
    case positivoFundo = "PositivoFundo"
    case alerta = "Alerta"
    case alertaFundo = "AlertaFundo"
    /// O texto âmbar sobre a AlertaFundo (etiquetas): no claro, mais escuro que o Alerta do site.
    case alertaEtiqueta = "AlertaEtiqueta"
    case informacao = "Informacao"
    case informacaoFundo = "InformacaoFundo"
    case negativo = "Negativo"
    /// Texto sobre a cor da marca (o --btn-ink do site): escuro no tema escuro, branco no claro.
    case sobreMarca = "SobreMarca"
    case tinta = "Tinta"
    case sobreTinta = "SobreTinta"
    case campo = "Campo"
    case campoBorda = "CampoBorda"
    case fantasmaFundo = "FantasmaFundo"
    case fantasmaTexto = "FantasmaTexto"
    case secundarioFosco = "SecundarioFosco"
    case secundarioTransparente = "SecundarioTransparente"
    case secundarioSolido = "SecundarioSolido"
    case linkNoVidro = "LinkNoVidro"
    case erroNoVidro = "ErroNoVidro"
    case contorno = "Contorno"
    case tintaConteudo = "TintaConteudo"
    case tintaCartao = "TintaCartao"
    case tintaNavegacao = "TintaNavegacao"
    case aurora1 = "Aurora1"
    case aurora2 = "Aurora2"
    case aurora3 = "Aurora3"
    case aurora4 = "Aurora4"
    case realceLogo = "RealceLogo"
    case sombraDoTexto = "SombraDoTexto"
    /// "Finalizar saída": o escurecido do app sob o alerta, somado ao do sistema (no claro, nenhum), e o total dos dois
    /// sem o alerta.
    case escurecidoSobOAlerta = "EscurecidoSobOAlerta"
    case escurecido = "Escurecido"
    case googleFundo = "GoogleFundo"
    case googleBorda = "GoogleBorda"
    case googleTexto = "GoogleTexto"
    case globoTerra = "GloboTerra"
    case globoBrilho = "GloboBrilho"
    case globoOceano = "GloboOceano"
    case globoHalo = "GloboHalo"
    case globoAro = "GloboAro"
    /// O lucro e o prejuízo da obra vendida sobre o vidro (o Positivo e o Negativo não fechavam 4,5:1 com a aurora atrás).
    case positivoNoVidro = "PositivoNoVidro"
    case negativoNoVidro = "NegativoNoVidro"
    /// A folha do sistema (etapa 2): o fundo, os grupos sólidos dentro dela e a linha fina entre as linhas de um grupo.
    case folha = "Folha"
    case linhaDaFolha = "LinhaDaFolha"
    case separadorDaFolha = "SeparadorDaFolha"
    /// Teclas do teclado de valor, soltas e tocadas.
    case tecla = "Tecla"
    case teclaTocada = "TeclaTocada"
    /// O segmentado Pix | Cartão: o trilho e a opção escolhida.
    case segmentadoFundo = "SegmentadoFundo"
    case segmentadoEscolhido = "SegmentadoEscolhido"
    /// O botão do arrastar para apagar e o texto sobre ele.
    case apagar = "Apagar"
    case sobreApagar = "SobreApagar"
    /// Texto sobre o Alerta ("Salvar mesmo assim").
    case sobreAlerta = "SobreAlerta"
    /// O fundo da linha que acabou de entrar.
    case aceso = "Aceso"
}

struct Paleta: Equatable, Sendable {
    var pele: Pele = .esmeralda

    /// Nome no catálogo: "Esmeralda/Marca".
    static func nome(_ token: Token, _ pele: Pele) -> String { "\(pele.rawValue)/\(token.rawValue)" }

    func cor(_ token: Token) -> Color { Color(Self.nome(token, pele)) }
}

extension EnvironmentValues {
    @Entry var paleta = Paleta()
}

/// Aparência deste aparelho: escuro, esmeralda e vidro Transparente por padrão. A tela de Ajustes da
/// etapa 5 grava as três chaves; os testes de tela passam `-custta.tema claro -custta.pele azul -custta.vidro fosco`.
enum Aparencia {
    static let chaveTema = "custta.tema"
    static let chavePele = "custta.pele"
    static let chaveVidro = "custta.vidro"
    static func esquema(_ tema: String) -> ColorScheme { tema == "claro" ? .light : .dark }
    static func pele(_ valor: String) -> Pele { valor == "azul" ? .azul : .esmeralda }
    static func vidro(_ valor: String) -> EscolhaDeVidro { valor == "fosco" ? .fosco : .transparente }
}
