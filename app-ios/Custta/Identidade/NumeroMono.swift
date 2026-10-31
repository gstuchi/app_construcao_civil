import SwiftUI

/* O número da identidade nova (etapa 4, brief 2): SF Mono 600, com o R$ e os centavos menores na linha do número, nunca
   sobrescritos e nunca abaixo de 11 pt (parte1.css:150-152). É a forma mono do `ValorEmDinheiro` (spec, "O número que
   encolhe"): um texto só, que encolhe para caber até o R$ chegar a 11 pt, no lugar da metade fixa da forma de antes. */

/// Os tamanhos do número mono, na letra padrão e na máxima (AX5), do mockup (--n-gig, --n-gr, --n-med, --n-pq e --n-ax).
/// Entre os dois, ele cresce com o corpo do texto, a cada passo da letra, como o texto do sistema: chega ao tamanho do
/// mockup na máxima sem parar no caminho.
enum TamanhoDoNumero: Sendable, CaseIterable {
    /// O número do sólido: 40 pt; 56 na letra máxima.
    case principal
    /// 30 e 48.
    case grande
    /// O número de um bloco de vidro: 22 e 40.
    case bloco
    /// O valor de uma linha (um lançamento, uma lista): 17 e 34.
    case linha
    /// O total do mês e os números miúdos: 17 e 30.
    case miudo

    var padrao: CGFloat {
        switch self {
        case .principal: 40
        case .grande: 30
        case .bloco: 22
        case .linha, .miudo: 17
        }
    }

    var maximo: CGFloat {
        switch self {
        case .principal: 56
        case .grande: 48
        case .bloco: 40
        case .linha: 34
        case .miudo: 30
        }
    }

    /// As medidas no corpo de texto dado (o `body` do Dynamic Type: 17 pt na letra padrão, 53 na máxima).
    func medidas(corpo: CGFloat) -> MedidasDoNumero {
        let numero = crescendoComALetra(de: padrao, ate: maximo, corpo: corpo)
        // O `max(.58em, min(1em, 11px))` do mockup: 58% do número, mas nunca abaixo de 11 pt (salvo número menor que isso).
        let menor = { (fracao: CGFloat) in max(fracao * numero, min(numero, 11)) }
        let moeda = menor(0.58)
        return MedidasDoNumero(numero: numero, moeda: moeda, centavos: menor(0.62), fatorMinimo: min(1, 11 / moeda))
    }
}

/// O número, o R$ e os centavos em pontos, e o quanto o texto pode encolher para caber: até o R$, o menor dos três, chegar
/// a 11 pt. Na linha (17 pt), o R$ já está em 11, e o número não encolhe.
struct MedidasDoNumero: Equatable, Sendable {
    let numero: CGFloat
    let moeda: CGFloat
    let centavos: CGFloat
    let fatorMinimo: CGFloat
}

/// O valor partido para o número mono: o que vem antes do "R$" (o "−" do gasto, o "+" do lucro), os dígitos e os centavos,
/// sem a vírgula.
struct PartesDoValor: Equatable, Sendable {
    let sinal: String
    let inteiro: String
    let centavos: String?
}

/// O corpo do texto (o `body`) no tamanho de letra dado: 17 pt na letra padrão, 53 na máxima. É o tamanho da fonte, e não
/// o `@ScaledMetric(relativeTo: .body)`, que para em 48 na máxima.
func corpoDoTexto(_ tamanho: DynamicTypeSize) -> CGFloat {
    UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(tamanho)))
        .pointSize
}

/// Um tamanho do mockup que vai do da letra padrão ao da máxima junto com o corpo do texto (de 17 a 53 pt), a cada passo.
func crescendoComALetra(de padrao: CGFloat, ate maximo: CGFloat, corpo: CGFloat) -> CGFloat {
    padrao + (maximo - padrao) * (corpo - 17) / (53 - 17)
}

/// As partes de um valor do núcleo ("R$ 842.317,45", "−R$ 4.980,00"); nil sem "R$" (o "—" da venda sem estimativa).
func partesDoValor(_ texto: String) -> PartesDoValor? {
    guard let rs = texto.range(of: "R$") else { return nil }
    let resto = texto[rs.upperBound...].trimmingCharacters(in: .whitespaces)
    guard let virgula = resto.lastIndex(of: ",") else {
        return PartesDoValor(sinal: String(texto[..<rs.lowerBound]), inteiro: resto, centavos: nil)
    }
    return PartesDoValor(sinal: String(texto[..<rs.lowerBound]), inteiro: String(resto[..<virgula]),
                         centavos: String(resto[resto.index(after: virgula)...]))
}

extension ValorEmDinheiro {
    /// O número mono da identidade nova, no tamanho dado. Dentro do sólido, na tinta dele.
    init(_ texto: String, mono tamanho: TamanhoDoNumero, cor: Token = .texto) {
        self.init(texto: texto, fonte: .body, cor: cor, mono: tamanho)
    }

    /// O sinal e os dígitos no tamanho do número, com o tracking de −0,035 do mockup; o R$ e os centavos menores, na mesma
    /// linha de base, e o R$ com o respiro de 0,22 do tamanho dele antes dos dígitos.
    func textoMono(_ medidas: MedidasDoNumero, cor: Color) -> Text {
        let fonte = { (tamanho: CGFloat) in Font.system(size: tamanho, weight: .semibold, design: .monospaced) }
        guard let partes = partesDoValor(texto) else {
            return Text(texto).font(fonte(medidas.numero)).tracking(-0.035 * medidas.numero).foregroundStyle(cor)
        }
        let sinal = Text(partes.sinal).font(fonte(medidas.numero))
        let moeda = Text("\(Text("R"))\(Text("$").kerning(0.22 * medidas.moeda))").font(fonte(medidas.moeda))
        let digitos = Text(partes.inteiro).font(fonte(medidas.numero)).tracking(-0.035 * medidas.numero)
        let centavos = Text(partes.centavos.map { ",\($0)" } ?? "").font(fonte(medidas.centavos))
        return Text("\(sinal)\(moeda)\(digitos)\(centavos)").foregroundStyle(cor)
    }
}
