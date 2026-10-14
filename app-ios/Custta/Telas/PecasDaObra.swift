import SwiftUI
import CusttaNucleo

/* As peças da tela da obra (mockup aprovado da etapa 2, parte 1): o título com o nome, a pílula da fase e do tempo,
   os indicadores na opção A, a pílula "Lançamentos", o "A vencer", o cabeçalho do mês e a linha do gasto. Medidas do
   mockup: margem de 20, cartões de raio 24 e recuo interno de 18 em tudo, para o texto de cima e o de baixo começarem
   na mesma vertical. Nenhum token novo; nunca vidro dentro de vidro (o que fica dentro de um cartão é sólido). */

/// O nome da obra no título grande, em quantas linhas precisar (o título grande do sistema corta nome longo), com o
/// halo atrás do bloco inteiro no escuro, como o título grande de Obras.
struct TituloDaObra: View {
    let nome: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(nome)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(paleta.cor(.texto))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("tituloDaObra")    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra) }
    }
}

/// Fase e tempo numa pílula de vidro: um cartão baixo de raio 24 com a etiqueta da fase e "começou em… · N meses".
struct PilulaDaFase: View {
    let obra: Obra
    let hoje: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EtiquetaDeFase(fase: obra.fase, grande: true)
            Text(textoDoInicio(obra, hoje: hoje))
                .font(.subheadline)
                .foregroundStyle(paleta.cor(.texto))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("faseDaObra")
    }
}

/// Uma etiqueta pequena colorida ao lado do rótulo de um indicador ("46 lançamentos", "3 vencimentos", "estimativa"), nas
/// medidas do mockup: footnote semibold, recuo de 10 nos lados e 3 em cima e embaixo.
struct EtiquetaDoIndicador: View {
    enum Cor { case marca, alerta, positivo, neutro }
    let texto: String
    let cor: Cor
    @Environment(\.paleta) private var paleta

    var body: some View {
        let (frente, fundo): (Token, Token) = switch cor {
        case .marca: (.fantasmaTexto, .fantasmaFundo)
        case .alerta: (.alertaEtiqueta, .alertaFundo)
        case .positivo: (.positivo, .positivoFundo)
        case .neutro: (.textoSecundario, .campo)
        }
        Text(texto)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(paleta.cor(frente))
            .fixedSize(horizontal: false, vertical: true)    // na letra grande, quebra em vez de cortar
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(paleta.cor(fundo), in: .capsule)
    }
}

/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com Corrigido, A pagar (a folha e a seta são
/// da etapa 3) e Venda. Os textos e as contas são os do site (indicadoresDaObra).
struct IndicadoresDaObraView: View {
    let indicadores: IndicadoresDaObra
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    /// "N lançamentos" na marca; "sem gastos" neutra, como o chip cinza do mockup.
    private var corDoTotal: EtiquetaDoIndicador.Cor { indicadores.etiquetaDoTotal == "sem gastos" ? .neutro : .marca }

    var body: some View {
        VStack(spacing: 10) {
            heroi
            VStack(spacing: 0) {
                linha(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido,
                      identificador: "indicadorCorrigido")
                LinhaFina().padding(.leading, 18)
                // Sem a seta e sem o "Ver" até a etapa 3, que traz a folha do A pagar: a seta prometeria navegação (regra
                // do Giovani de 08/10 para a seta das obras).
                linha(rotulo: "A pagar · 30 dias", etiqueta: (indicadores.etiquetaDoAPagar, .alerta), valor: indicadores.aPagar,
                      nota: "Parcelas e gastos futuros", identificador: "indicadorAPagar")
                LinhaFina().padding(.leading, 18)
                venda
            }
            .superficie(.conteudo, em: .rect(cornerRadius: 24))
        }
    }

    private var heroi: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    rotulo("Total gasto")
                    Spacer(minLength: 8)
                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
                }
                VStack(alignment: .leading, spacing: 6) {
                    rotulo("Total gasto")
                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
                }
            }
            ValorEmDinheiro(texto: indicadores.totalGasto, fonte: .largeTitle.weight(.bold))
            Text("bruto, sem correção").font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorTotal")
    }

    @ViewBuilder private var venda: some View {
        switch indicadores.venda {
        case .vendida(let valor, let etiqueta, let nota, let lucroPositivo):
            linha(rotulo: "Venda", etiqueta: (etiqueta, .positivo), valor: valor, nota: nota, identificador: "indicadorVenda",
                  corDaNota: lucroPositivo ? .positivoNoVidro : .negativoNoVidro)
        case .estimada(let valor, let nota):
            linha(rotulo: "Venda estimada", etiqueta: ("estimativa", .positivo), valor: valor, nota: nota, identificador: "indicadorVenda")
        case .semEstimativa:
            linha(rotulo: "Venda estimada", etiqueta: nil, valor: "—", nota: "Toque no lápis para informar o valor",
                  identificador: "indicadorVenda")
        }
    }

    /// Na letra grande, o rótulo ao lado da etiqueta recebia a altura de uma linha e cortava ("A pagar · 3…"): a altura
    /// ideal para a largura dada resolve.
    private func rotulo(_ texto: String) -> some View {
        Text(texto).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
    }

    private func linha(rotulo texto: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       identificador: String, corDaNota: Token? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    rotulo(texto)
                    Spacer(minLength: 8)
                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
                }
                VStack(alignment: .leading, spacing: 6) {
                    rotulo(texto)
                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
                }
            }
            ValorEmDinheiro(texto: valor, fonte: .title2.weight(.bold))
            Text(nota).font(.subheadline).foregroundStyle(paleta.cor(corDaNota ?? vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identificador)
    }
}

/// "Lançamentos 46": a pílula de vidro antes da lista, nas medidas do mockup (subheadline, o número em peso médio).
struct PilulaDeLancamentos: View {
    let quantidade: Int
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        HStack(spacing: 4) {                             // um espaço de texto, como no mockup
            Text("Lançamentos").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            Text("\(quantidade)").font(.subheadline.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .superficie(.conteudo, em: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("lancamentos")
    }
}

/// O cabeçalho de um mês dentro do cartão: o nome e o total; sem espaço, o total quebra para baixo, numa linha só (na
/// letra máxima, num iPhone de 375 pt, um total de seis dígitos em texto puro partia em "R$" e "222.728,35").
struct CabecalhoDoMes: View {
    let mes: MesDeGastos
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { titulo; Spacer(minLength: 8); total }
            VStack(alignment: .leading, spacing: 2) { titulo; total }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(paleta.cor(vidro.secundario))
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 6, trailing: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("mes-\(mes.id)")
    }

    private var titulo: some View { Text(mes.titulo) }
    private var total: some View {
        ValorEmDinheiro(texto: moeda(mes.total), fonte: .footnote.weight(.semibold), cor: vidro.secundario)
    }
}

/// A linha do "A vencer", fechado ou aberto: ícone de calendário, título, total, chevron e o resumo.
struct LinhaDoAVencer: View {
    let grupo: GrupoAVencer
    let aberto: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho
    @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 38

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !tamanho.isAccessibilitySize {
                Image(decorative: "Icones/calendario")
                    .resizable().frame(width: icone * 0.55, height: icone * 0.55)
                    .foregroundStyle(paleta.cor(.alertaEtiqueta))
                    .frame(width: icone, height: icone)
                    .background(paleta.cor(.alertaFundo), in: .rect(cornerRadius: 11))
            }
            VStack(alignment: .leading, spacing: 2) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("A vencer").font(.body.weight(.semibold))
                        Spacer(minLength: 8)
                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A vencer").font(.body.weight(.semibold))
                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
                    }
                }
                .foregroundStyle(paleta.cor(.texto))
                Text(grupo.resumo).font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
            }
            Image(systemName: aberto ? "chevron.down" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(vidro.secundario))
                .accessibilityHidden(true)
                .foraDoLaudo()
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 16))
        .contentShape(.rect)
    }
}

/// A linha de um gasto: ícone do tópico (sólido), título e valor, e embaixo o tópico, o pagamento e a data. O valor vem
/// sem vermelho, só com o "−"; "Pix" e "Cartão" por extenso. Na letra grande, cada informação numa linha, sem o ícone e
/// sem os "·". O VoiceOver lê "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" e o valor.
struct LinhaDeGastoView: View {
    let gasto: Gasto
    let linha: LinhaDeGasto
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        Group {
            if tamanho.isAccessibilitySize { empilhada } else { normal }
        }
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(linha.rotulo)
        .accessibilityValue(linha.valorFalado)
        .accessibilityIdentifier("gasto-\(gasto.id)")
    }

    private var normal: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(decorative: iconeDoCatalogo(linha.icone))
                .resizable().frame(width: 20, height: 20)
                .foregroundStyle(paleta.cor(.marca))
                .frame(width: 38, height: 38)
                .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titulo
                    Spacer(minLength: 0)
                    valor
                }
                meta
            }
        }
    }

    private var empilhada: some View {
        VStack(alignment: .leading, spacing: 4) {
            titulo
            valor
            if let topico = linha.topico { detalhe(topico) }
            if let pagamento = linha.pagamento { detalhe(pagamento) }
            detalhe(linha.data)
        }
    }

    private var titulo: some View {
        Text(linha.titulo).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
    }

    private var valor: some View { ValorEmDinheiro(texto: linha.valor, fonte: .body.weight(.semibold)) }

    /// Tópico · forma de pagamento com o ícone · data, num texto só (quebra sozinho; um "·" solto era um texto de 4 pt
    /// que a auditoria de contraste do Xcode não conseguia medir). Os ícones do pagamento são os do sistema, que crescem
    /// com a letra dentro do texto: o raio do Pix ("bolt") e o cartão ("creditcard").
    private var meta: some View {
        var partes: [Text] = []
        if let topico = linha.topico { partes.append(Text(topico)) }
        if let pagamento = linha.pagamento {
            partes.append(Text("\(Image(systemName: pagamento == "Pix" ? "bolt" : "creditcard")) \(pagamento)"))
        }
        partes.append(Text(linha.data))
        let junto = partes.dropFirst().reduce(partes[0]) { Text("\($0) · \($1)") }
        return junto.font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }

    private func detalhe(_ texto: String) -> some View {
        Text(texto).font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }
}

/// A linha fina entre as linhas de um cartão de vidro (hairline), no token LinhaNoVidro.
struct LinhaFina: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.displayScale) private var escala

    var body: some View {
        Rectangle().fill(paleta.cor(.linhaNoVidro)).frame(height: 1 / escala).accessibilityHidden(true)
    }
}

/// Cartão de vidro da lista da obra (um mês, o "A vencer"): o conteúdo recortado no raio do cartão (a linha arrastada não
/// passa do canto) e o vidro atrás, como fundo à parte. Com o vidro aplicado ao conteúdo (`.superficie` direto), no iOS 27
/// o cartão que cresce (o "A vencer" abrindo, um gasto entrando no mês) levava junto o quadro de acessibilidade da primeira
/// linha: o cabeçalho passava a responder pelo cartão inteiro, no VoiceOver e no XCUITest. Com o vidro de fundo, não.
struct CartaoDaLista<Conteudo: View>: View {
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: conteudo)
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .background { Color.clear.superficie(.conteudo, em: .rect(cornerRadius: 24, style: .continuous)) }
    }
}
