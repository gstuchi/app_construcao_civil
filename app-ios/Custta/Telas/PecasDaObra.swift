import SwiftUI
import CusttaNucleo

/* As peças da tela da obra (mockup aprovado da etapa 2, parte 1): o título com o nome, a pílula da fase e do tempo,
   os indicadores na opção A, a pílula "Lançamentos", o "A vencer", o cabeçalho do mês e a linha do gasto. Medidas do
   mockup: margem de 20, cartões de raio 24 e recuo interno de 18 em tudo, para o texto de cima e o de baixo começarem
   na mesma vertical. Nenhum token novo; nunca vidro dentro de vidro (o que fica dentro de um cartão é sólido). */

/// O nome da obra no título grande, em quantas linhas precisar (o título grande do sistema corta nome longo), com o
/// halo atrás do bloco inteiro no escuro, como o título grande de Obras. Nas alturas do mockup: 6 pt acima do início da
/// rolagem e a pílula da fase 8 pt abaixo (2 a menos que o espaço da pilha).
struct TituloDaObra: View {
    let nome: String
    var identificador = "tituloDaObra"
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(nome)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(paleta.cor(.texto))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(identificador)    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra, noClaro: HaloDoTitulo.naObraNoClaro) }
            .padding(EdgeInsets(top: -6, leading: 0, bottom: -2, trailing: 0))
    }
}

/// Fase e tempo numa pílula de vidro: um cartão baixo de raio 24 com a etiqueta da fase e "começou em… · N meses", a 16 pt
/// do total gasto, como no mockup (6 além do espaço da pilha).
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
        .padding(.bottom, 6)
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

/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com o orçamento (etapa 3, a primeira linha,
/// só com orçamento), Corrigido, A pagar (a folha e a seta são da etapa 3) e Venda. Os textos e as contas são os do site
/// (indicadoresDaObra, orcamentoObra).
struct IndicadoresDaObraView: View {
    let indicadores: IndicadoresDaObra
    var orcamento: ResumoOrcamento? = nil
    /// Para onde a linha do orçamento leva (a tela Orçamento da obra).
    var rotaDoOrcamento: RotaDeObras? = nil
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    /// "N lançamentos" na marca; "sem gastos" neutra, como o chip cinza do mockup.
    private var corDoTotal: EtiquetaDoIndicador.Cor { indicadores.etiquetaDoTotal == "sem gastos" ? .neutro : .marca }

    var body: some View {
        VStack(spacing: 10) {
            heroi
            VStack(spacing: 0) {
                if let orcamento {
                    if let rotaDoOrcamento {
                        NavigationLink(value: rotaDoOrcamento) { LinhaDoOrcamento(resumo: orcamento, comSeta: true) }
                            .buttonStyle(.plain)
                            // O Controle por Voz chama pelo nome da linha ("Tocar Orçamento"), não pelo rótulo inteiro.
                            .accessibilityInputLabels(["Orçamento"])
                    } else {
                        LinhaDoOrcamento(resumo: orcamento)
                    }
                    LinhaFina().padding(.leading, 18)
                }
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
            // O "—" de valor nenhum (venda sem estimativa) vai no secundário, como no mockup.
            ValorEmDinheiro(texto: valor, fonte: .title2.weight(.bold), cor: valor == "—" ? vidro.secundario : .texto)
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

    var body: some View { PilulaDaLista(titulo: "Lançamentos", quantidade: quantidade, identificador: "lancamentos") }
}

/// A pílula de vidro antes de uma lista ("Lançamentos 46"; na tela Orçamento, "Por tópico 14" e "Gasto por tópico 14"): o
/// título em subheadline semibold e o número em peso médio, no secundário.
struct PilulaDaLista: View {
    let titulo: String
    let quantidade: Int
    let identificador: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        HStack(spacing: 4) {                             // um espaço de texto, como no mockup
            Text(titulo).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            Text("\(quantidade)").font(.subheadline.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .superficie(.conteudo, em: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier(identificador)
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
    /// Acabou de ser salvo: o fundo Aceso por 2 s; `novo` põe a etiqueta (gasto lançado, não editado).
    var acesa = false
    var novo = false
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.colorScheme) private var esquema
    @Environment(\.displayScale) private var escala

    var body: some View {
        Group {
            if tamanho.isAccessibilitySize { empilhada } else { normal }
        }
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(acesa ? paleta.cor(.aceso) : .clear)
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

    /// A etiqueta "novo" vai no fim do texto, colada à última palavra (mockup: `::after` em linha, 8 pt depois), e não ao
    /// lado do bloco: ao lado, ela tomava 53 pt da largura e o título quebrava uma linha a mais (3 no 13 mini). O espaço
    /// rígido não deixa a etiqueta descer sozinha para a linha de baixo.
    private var titulo: some View {
        Group {
            if acesa && novo,
               let etiqueta = EtiquetaNovo.imagem(paleta: paleta, esquema: esquema, tamanho: tamanho, escala: escala) {
                Text("\(linha.titulo)\u{a0}\(Text(Image(uiImage: etiqueta)).baselineOffset(-2.5))")
            } else {
                Text(linha.titulo)
            }
        }
        .font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
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

/// A etiqueta "novo" da linha que acabou de ser lançada (some com o destaque, em ~2 s).
struct EtiquetaNovo: View {
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text("novo")
            .font(.caption.weight(.bold))
            .foregroundStyle(paleta.cor(.sobreMarca))
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(paleta.cor(.marca), in: .capsule)
            .accessibilityHidden(true)
    }

    /// A etiqueta como imagem, para entrar no Text do título da linha. O ImageRenderer não herda nada da tela: a pele, o
    /// esquema de cor, o tamanho de letra e a escala vêm de quem desenha a linha, que os lê do environment e refaz a
    /// imagem quando um deles muda (nada guardado em estado).
    @MainActor static func imagem(paleta: Paleta, esquema: ColorScheme, tamanho: DynamicTypeSize, escala: CGFloat) -> UIImage? {
        let r = ImageRenderer(content: EtiquetaNovo().padding(.leading, 4)
            .environment(\.paleta, paleta).environment(\.colorScheme, esquema).environment(\.dynamicTypeSize, tamanho))
        r.scale = escala
        return r.uiImage
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

/// As ações da fase, logo abaixo dos indicadores (mockup da etapa 2, parte 3): o próximo passo numa pílula sólida da marca
/// ("Marcar como pronta", "Registrar venda"); voltar numa pílula de vidro ("Voltar pra construção", "Desfazer venda").
/// Pílulas de 52 pt que crescem com a letra, 10 entre elas, ícone de 20 e o texto em .body semibold. Sem orçamento e fora da
/// vendida (o `pecasOrcamento` do site), "Definir orçamento" vem depois delas, em vidro (mockup da etapa 3).
struct AcoesDaFaseView: View {
    let fase: Fase
    var definirOrcamento: (() -> Void)? = nil
    let agir: (AcaoDaFase) -> Void
    @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 20

    var body: some View {
        VStack(spacing: 10) {
            ForEach(acoesDaFase(fase), id: \.self) { acao in
                Button { agir(acao) } label: {
                    Label {
                        Text(acao.rotulo).multilineTextAlignment(.center)
                    } icon: {
                        Image(decorative: "Icones/\(acao.icone)").resizable().frame(width: min(icone, 34), height: min(icone, 34))
                    }
                }
                .buttonStyle(PilulaDaAcao(principal: acao.principal))
                .accessibilityIdentifier("acao-\(acao.rawValue)")
            }
            if let definirOrcamento {
                Button(action: definirOrcamento) {
                    Label {
                        Text("Definir orçamento").multilineTextAlignment(.center)
                    } icon: {
                        Image(decorative: "Icones/alvo").resizable().frame(width: min(icone, 34), height: min(icone, 34))
                    }
                }
                .buttonStyle(PilulaDaAcao(principal: false))
                .accessibilityIdentifier("definirOrcamento")
            }
        }
    }
}

/// A pílula de uma ação da fase: sólida na Marca, com o texto em SobreMarca, ou no vidro do conteúdo, com o texto na cor
/// do texto. Encolhe no toque, como os botões do app. Nos tamanhos de acessibilidade o recuo interno cai de 20 para 10,
/// como no mockup em 375 pt: "construção" cabe ao lado do ícone, em vez de partir com hífen.
struct PilulaDaAcao: ButtonStyle {
    let principal: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho

    func makeBody(configuration: Configuration) -> some View {
        let rotulo = configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(principal ? .sobreMarca : .texto))
            .padding(.horizontal, tamanho.isAccessibilitySize ? 10 : 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
        Group {
            if principal { rotulo.background(paleta.cor(.marca), in: .capsule) }
            else { rotulo.superficie(.conteudo, em: .capsule) }
        }
        .contentShape(.capsule)
        .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
        .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O lápis da barra da obra: círculo de vidro com o ícone do site, como o sair do topo; abre "Editar obra" (na tela
/// Orçamento, "Editar orçamento").
struct BotaoDeEditarObra: View {
    var rotulo = "Editar obra"
    var identificador = "editarObra"
    let editar: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        Button(action: editar) {
            Image(decorative: "Icones/lapis")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundStyle(paleta.cor(.texto))
                .frame(width: 44, height: 44)
                .superficie(.navegacao, em: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotulo)
        .accessibilityIdentifier(identificador)
    }
}
