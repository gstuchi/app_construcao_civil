import SwiftUI

/* Cores só por tokens (spec, seção 8): cada token existe no Assets.xcassets, com variante clara e escura,
   gerado por scripts/cores-app-ios.mjs.
   Nenhuma cor solta nas telas (componentes RGB ou cor nomeada do sistema): tests/app-ios.test.cjs confere. */

/// A pele do catálogo ("Esmeralda/Marca"). Desde 21/10/2026 o Custta só tem a Esmeralda (a Azul saiu do site e do app).
enum Pele: String, CaseIterable, Sendable {
    case esmeralda = "Esmeralda"
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
    /// O texto âmbar sobre o vidro do conteúdo (etapa 3): o aviso dos tópicos na linha do orçamento e o "Passou … do
    /// previsto". No claro, mais escuro que o Alerta, que não fechava 4,5:1 sobre a aurora clara.
    case alertaNoVidro = "AlertaNoVidro"
    /// A folha do sistema (etapa 2): o fundo, os grupos sólidos dentro dela e a linha fina entre as linhas de um grupo.
    case folha = "Folha"
    case linhaDaFolha = "LinhaDaFolha"
    case separadorDaFolha = "SeparadorDaFolha"
    /// Teclas do teclado de valor, soltas e tocadas.
    case tecla = "Tecla"
    case teclaTocada = "TeclaTocada"
    /// O segmentado Pix | Cartão: o trilho, a opção escolhida e a sombra sob ela.
    case segmentadoFundo = "SegmentadoFundo"
    case segmentadoEscolhido = "SegmentadoEscolhido"
    case sombraDoSegmentado = "SombraDoSegmentado"
    /// O botão do arrastar para apagar e o texto sobre ele.
    case apagar = "Apagar"
    case sobreApagar = "SobreApagar"
    /// Texto sobre o Alerta ("Salvar mesmo assim").
    case sobreAlerta = "SobreAlerta"
    /// O fundo da linha que acabou de entrar.
    case aceso = "Aceso"
    /// O aro claro das barrinhas de vidro desenhadas na miniatura de cada opção do vidro (Ajustes › Aparência).
    case aroDaMiniatura = "AroDaMiniatura"
    /// A identidade nova (etapa 4): o bloco sólido protagonista de cada tela, que não é vidro, e o texto sobre ele; o texto
    /// verde sobre o vidro; o sólido âmbar do "Rende menos que o banco" e o texto sobre ele.
    case destaqueSolido = "DestaqueSolido"
    case tintaSobreDestaque = "TintaSobreDestaque"
    case destaqueTexto = "DestaqueTexto"
    case solidoAmbar = "SolidoAmbar"
    case tintaSobreAmbar = "TintaSobreAmbar"
    /// A placa, um tom chapado sem desfoque (não é vidro), atrás do anel e dos gráficos; a forte, atrás da barra empilhada
    /// da obra. Com ela, as marcas ficam a 3:1 com a aurora atrás.
    case placa = "Placa"
    case placaForte = "PlacaForte"
    /// As seis cores do anel e da barra empilhada, do maior tópico para o menor, e o cinza de "Outros".
    case grafico1 = "Grafico1"
    case grafico2 = "Grafico2"
    case grafico3 = "Grafico3"
    case grafico4 = "Grafico4"
    case grafico5 = "Grafico5"
    case grafico6 = "Grafico6"
    case graficoOutros = "GraficoOutros"
    /// Os gráficos de mês: os meses não escolhidos e a hachura das parcelas a vencer, a grade e os eixos.
    case barraApagada = "BarraApagada"
    case gradeGrafico = "GradeGrafico"
    case eixoGrafico = "EixoGrafico"
    /// O anel: o trilho e os pedaços apagados pelo toque (por cor, sem opacidade, para as emendas não virarem bolinhas), e
    /// o aro na ponta de cada pedaço.
    case anelApagado = "AnelApagado"
    case anelSeparador = "AnelSeparador"
    /// O filete de luz no topo do bloco sólido (o inset do mockup, branco a 35%).
    case luzDoSolido = "LuzDoSolido"
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

/// Aparência deste aparelho: escuro e vidro Transparente por padrão. Ajustes › Aparência grava as duas chaves; os testes
/// de tela passam `-custta.tema claro -custta.vidro fosco`.
enum Aparencia {
    static let chaveTema = "custta.tema"
    static let chaveVidro = "custta.vidro"
    static func esquema(_ tema: String) -> ColorScheme { tema == "claro" ? .light : .dark }
    static func vidro(_ valor: String) -> EscolhaDeVidro { valor == "fosco" ? .fosco : .transparente }
}
