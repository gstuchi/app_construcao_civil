import Foundation

/* A linha de cada tópico no Relatório do app ("2 gastos · 38,0%"; na busca, "11 de 11 gastos · 38,0%"), que o site não
   mostra: regra do app, sem vetor do site. A parte do total da soma da seleção, com 2 casas, é a do site (`somaSelecao`). */

/// "1 gasto", "2 gastos"; com o total, "1 de 3 gastos", com o substantivo pelo total. Serve ao tópico na busca, ao resumo
/// dos achados ("12 de 46 gastos") e ao cabeçalho do tópico no PDF.
public func contagemDeGastos(_ n: Int, de total: Int? = nil) -> String {
    (total.map { "\(n) de \($0)" } ?? "\(n)") + ((total ?? n) == 1 ? " gasto" : " gastos")
}

/// `x.toLocaleString('pt-BR', {minimumFractionDigits: casas, maximumFractionDigits: casas})`: sobre os dígitos mais curtos,
/// o meio para longe do zero (o ICU, como o `moeda`), com o ponto de milhar e a vírgula.
func casasPtBR(_ x: Double, _ casas: Int) -> String {
    var digitos = [0], inteiros = 1
    if x.isFinite && x != 0 {
        let (d, n) = digitosMaisCurtos(abs(x))
        digitos = Array(repeating: 0, count: max(0, 1 - n)) + d.map { $0.wholeNumberValue ?? 0 }
        inteiros = max(n, 1)
    }
    digitos += Array(repeating: 0, count: max(0, inteiros + casas + 1 - digitos.count))
    var mantidos = Array(digitos[..<(inteiros + casas)])
    if digitos[inteiros + casas] >= 5 {
        var i = mantidos.count - 1
        while i >= 0 && mantidos[i] == 9 { mantidos[i] = 0; i -= 1 }
        if i >= 0 { mantidos[i] += 1 } else { mantidos.insert(1, at: 0); inteiros += 1 }
    }
    let texto = mantidos.map(String.init).joined()
    return (x < 0 ? "-" : "") + agruparMilhar(String(texto.prefix(inteiros))) + (casas > 0 ? "," + texto.dropFirst(inteiros) : "")
}

/// A parte da obra com 1 casa ("38,0%"), no arredondamento da parte do total da soma da seleção, e "<0,1%" quando a parte
/// verdadeira fica entre 0 e 0,1%, como o "<1%" do anel. Sem total, "0,0%".
public func parteComUmaCasa(_ bruto: Double, total: Double) -> String {
    let pct = total > 0 ? bruto / total * 100 : 0
    if pct > 0 && pct < 0.1 { return "<0,1%" }
    return casasPtBR(pct, 1) + "%"
}

/// A linha do tópico no Relatório: "2 gastos · 38,0%"; na busca, "11 de 11 gastos · 38,0%", com o bruto só dos achados.
public func linhaDoTopicoNoRelatorio(_ n: Int, de total: Int? = nil, bruto: Double, total totalDaObra: Double) -> String {
    contagemDeGastos(n, de: total) + " · " + parteComUmaCasa(bruto, total: totalDaObra)
}
