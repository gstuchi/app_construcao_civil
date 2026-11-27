import SwiftUI
import CusttaNucleo

/* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site), o veredito no bloco sólido, a
   faixa "Onde a sua venda cai" e a tabela do site, pelo bruto e pelo corrigido. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
   enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
   as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. O toque no preço abre as teclas
   (`TeclasDoPreco`) no lugar da cápsula de abas. As teclas são desta tela, na área segura da rolagem, para a linha do preço
   subir acima delas; a cápsula é do PrincipalView, que a tira enquanto o `teclasAbertas` vale: daí ele vir de lá. */
struct ValeAPenaView: View {
    /// A linha do preço na rolagem: com as teclas abertas, ela fica à vista acima delas.
    static let linhaDoPreco = "simLinhaDoPreco"
    @Binding var campos: CamposDoSimulador
    @Binding var teclasAbertas: Bool
    @Environment(ModeloApp.self) private var modelo
    @State private var confirmarSaida = false
    @State private var barra = BarraDaObra()

    var body: some View {
        let estado = modelo.sincronizador.estado
        let tela = simulacaoNaTela(campos, obras: estado.obras, hoje: dataLocalISO(.now, fuso: .current),
                                   taxa: estado.config.taxaMensal)
        NavigationStack {
            ScrollViewReader { leitor in
                ScrollView {
                    VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                        TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
                            .padding(.bottom, 2)
                        CamposDoValeAPena(campos: $campos, tela: tela, teclasAbertas: $teclasAbertas)
                        // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
                        if let veredito = tela.veredito {
                            VereditoDoValeAPena(veredito: veredito)
                            if let faixa = tela.faixa { FaixaDoValeAPena(faixa: faixa) }
                            if let textos = tela.textos { TabelaDoValeAPena(linhas: textos.tabela) }
                        } else if tela.obra != nil {
                            SemPrecoDoValeAPena()
                        }
                    }
                    .padding(.horizontal, Grade.externa)
                }
                .scrollIndicators(.hidden)
                // A tabela termina 48 pt acima da cápsula, pela altura medida dela (a última linha ficava atrás com 24): 40 aqui e
                // os 8 do espaçamento do safeAreaInset das teclas, que valem também com elas fechadas. Com as teclas abertas a
                // cápsula sai, a medida fica a da última vez, e as teclas entram na área segura por cima dela.
                .fimAcimaDaCapsula(ar: 40)
                #if DEBUG
                // O laudo de leitura mede o veredito, a faixa e a tabela com a tela parada numa rolagem dada.
                .rolagemFixaSoComOArgumento()
                #endif
                // Quando as teclas entram, a área de baixo da rolagem cresce: a linha do preço sobe só o que falta para ficar à
                // vista acima delas (na letra máxima ela nasce mais embaixo). O gatilho é a medida, e não um tempo.
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.bottom } action: { antes, depois in
                    if teclasAbertas, depois > antes { leitor.scrollTo(Self.linhaDoPreco) }
                }
                .tituloPequenoAoRolar(barra)
                .background { LeitorDaLetra(barra: barra) }
                .pausaOFundoAoRolar()
                .bordaDeRolagem(abas: true)
                // Por fora da borda de rolagem, que fica atrás das teclas. Os 8 pt são o respiro entre a linha do preço e elas.
                .safeAreaInset(edge: .bottom, spacing: 8) {
                    if teclasAbertas { TeclasDoPreco(campos: $campos) { teclasAbertas = false } }
                }
                .containerBackground(.clear, for: .navigation)
                .navigationTitle("Vale a pena?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Vale a pena?", mono: true) }
                    BarraDoApp(confirmarSaida: $confirmarSaida)
                }
                .confirmaSaida($confirmarSaida)
            }
        }
    }
}

/// O bloco dos campos: a obra, o preço e os meses, uma linha cada (o rótulo à esquerda e o valor à direita; na letra de
/// acessibilidade, um embaixo do outro, como o mockup), e a nota do site. Para o VoiceOver, cada linha é o controle dela,
/// com o rótulo da linha e o valor: o texto do rótulo sai da leitura, para não ser lido duas vezes.
struct CamposDoValeAPena: View {
    @Binding var campos: CamposDoSimulador
    let tela: SimulacaoNaTela
    @Binding var teclasAbertas: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        BlocoDeVidro(recuoVertical: 4) {
            LinhaDoCampo(rotulo: "Obra") { obra }
            LinhaFina()
            preco.id(ValeAPenaView.linhaDoPreco)
            LinhaFina()
            LinhaDoCampo(rotulo: "Daqui a (meses)") { passo }
            LinhaFina()
            Text("A conta considera que não haverá mais gastos até a venda. Mude o preço e os meses pra comparar cenários: vender mais barato agora × esperar mais.")
                .font(.subheadline)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .accessibilityIdentifier("simNota")
        }
    }

    /// A obra: um Menu do sistema com as elegíveis, na ordem do documento, e a marca na escolhida; sem nenhuma, a frase do
    /// site no lugar.
    @ViewBuilder private var obra: some View {
        if let escolhida = tela.obra {
            Menu {
                Picker("Obra", selection: Binding(get: { escolhida.id }, set: { campos.obraId = $0 })) {
                    ForEach(tela.elegiveis, id: \.id) { Text($0.nome).tag($0.id) }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(escolhida.nome)
                        .font(.body)
                        .multilineTextAlignment(tamanho.isAccessibilitySize ? .leading : .trailing)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down").font(.footnote.weight(.semibold)).accessibilityHidden(true)
                }
                .foregroundStyle(paleta.cor(vidro.secundario))
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .accessibilityLabel("Obra")
            .accessibilityValue(escolhida.nome)
            .accessibilityIdentifier("simObra")
        } else {
            Text("— crie uma obra com gastos —")
                .font(.body)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("simSemObra")
        }
    }

    /// O preço: o digitado ou, sem digitar, a venda estimada da obra; vazio, "R$ 0,00" apagado, como o campo do site. A linha
    /// inteira é o botão que abre as teclas; com elas abertas, o cursor do mockup vem depois do valor (vazio, só o cursor).
    private var preco: some View {
        Button { teclasAbertas = true } label: {
            LinhaDoCampo(rotulo: "Se eu vender por") {
                HStack(spacing: 3) {
                    if let valor = tela.preco {
                        ValorEmDinheiro(moeda(valor), mono: .linha)
                    } else if !teclasAbertas {
                        ValorEmDinheiro(moeda(0), mono: .linha, cor: vidro.secundario)
                    }
                    if teclasAbertas {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(paleta.cor(.destaque))
                            .frame(width: 2, height: 1.1 * crescendoComALetra(de: 17, ate: 34, corpo: corpoDoTexto(tamanho)))
                    }
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Se eu vender por")
        .accessibilityValue(tela.preco.map { moeda($0) } ?? TeclasDoPreco.semPreco)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("simPreco")
    }

    /// Os meses: − e + redondos de 44 pt (72 na letra de acessibilidade), que param em 0 e em 120, e o número em mono no meio.
    private var passo: some View {
        let grande = tamanho.isAccessibilitySize
        let numero = crescendoComALetra(de: 17, ate: 34, corpo: corpoDoTexto(tamanho))
        return HStack(spacing: 6) {
            BotaoDoPasso(simbolo: "minus", rotulo: "Um mês a menos", identificador: "simMenos", lado: grande ? 72 : 44) {
                campos.andarMeses(-1)
            }
            .disabled(!tela.podeMenos)
            Text("\(tela.meses)")
                .font(.system(size: numero, weight: .semibold, design: .monospaced))
                .foregroundStyle(paleta.cor(.texto))
                .frame(minWidth: 74)
                .accessibilityLabel("Daqui a")
                .accessibilityValue(tela.meses == 1 ? "1 mês" : "\(tela.meses) meses")
                .accessibilityIdentifier("simMeses")
            BotaoDoPasso(simbolo: "plus", rotulo: "Um mês a mais", identificador: "simMais", lado: grande ? 72 : 44) {
                campos.andarMeses(1)
            }
            .disabled(!tela.podeMais)
        }
    }
}

/// O veredito, o bloco sólido da aba: verde com "Vale a pena" ou âmbar com "Rende menos que o banco", a taxa ao mês com o
/// número em mono grande (40 pt; 56 na letra máxima) e a unidade na metade, e as linhas do site embaixo. A taxa quebra em
/// vez de encolher. Para o VoiceOver, o bloco é um elemento só, com a frase inteira.
struct VereditoDoValeAPena: View {
    let veredito: VereditoNaTela
    @Environment(\.dynamicTypeSize) private var tamanho
    @ScaledMetric(relativeTo: .subheadline) private var icone: CGFloat = 18

    var body: some View {
        let numero = crescendoComALetra(de: 40, ate: 56, corpo: corpoDoTexto(tamanho))
        BlocoSolido(cor: veredito.vale ? .verde : .ambar) {
            HStack(spacing: 6) {
                Image(decorative: veredito.vale ? "Icones/check" : "Icones/alerta").resizable().frame(width: icone, height: icone)
                RotuloDoBloco(texto: veredito.titulo)
            }
            Text("\(Text(veredito.numero).font(.system(size: numero, weight: .semibold, design: .monospaced)).tracking(-0.035 * numero))\(Text(veredito.unidade ?? "").font(.system(size: numero / 2, weight: .bold, design: .monospaced)))")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .padding(.bottom, 2)
            ForEach(veredito.linhas, id: \.self) { NotaDoBloco(texto: $0) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(veredito.falado)
        .accessibilityIdentifier("simVeredito")
    }
}

/// A faixa "Onde a sua venda cai" (mockup da etapa 4, parte2.css:84-99; regra no núcleo, `faixaSimulador`): o trilho, a
/// zona hachurada do empate até o fim ("acima do banco"), o custo numa barra, o empate num tracejado e a venda numa barra
/// com um ponto em cima; a pílula diz de que lado a venda caiu, e os três valores vêm numa lista embaixo, cada um com o
/// marcador dele (decisão 6 da parte 2: sobre a faixa eles se atropelam). Para o VoiceOver, a faixa é uma imagem com a
/// frase dos três valores, e cada linha da lista, o rótulo com o valor.
struct FaixaDoValeAPena: View {
    let faixa: FaixaDoSimulador
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let cabecalho = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        BlocoDeVidro {
            cabecalho {
                Text("Onde a sua venda cai")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(paleta.cor(.texto))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("simTituloDaFaixa")
                EtiquetaDoIndicador(texto: faixa.pilula, cor: faixa.acima ? .positivo : .alerta)
                    .accessibilityIdentifier("simPilula")
            }
            // 20 pt acima e 10 abaixo (mockup); as marcas passam 8 pt da faixa, e o ponto da venda, 15.
            DesenhoDaFaixa(faixa: faixa)
                .frame(height: DesenhoDaFaixa.altura)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(faixa.falado)
                .accessibilityAddTraits(.isImage)
                .accessibilityIdentifier("simFaixa")
            VStack(alignment: .leading, spacing: 2) {
                ForEach(faixa.linhas, id: \.marca) { LinhaDaLegendaDaFaixa(linha: $0) }
            }
            .padding(.top, 6)
        }
    }
}

/// O desenho da faixa, em formas (sem texto): cada marca no x que o núcleo deu, como fração da largura.
struct DesenhoDaFaixa: View {
    static let altura: CGFloat = 46
    /// Do tracejado do empate ao começo da zona: o tracejado tem 2 pt, e sobram 2 de trilho entre ele e a hachura.
    static let vaoDoEmpate: CGFloat = 4
    /// A fenda da zona onde passa a venda: a barra tem 4 pt, e sobram 2 de trilho de cada lado.
    static let fendaDaVenda: CGFloat = 8
    let faixa: FaixaDoSimulador
    @Environment(\.paleta) private var paleta
    #if DEBUG
    @Environment(\.marcasApagadas) private var apagadas
    #endif

    /// O x de cada marca numa faixa da largura dada.
    static func posicoes(_ faixa: FaixaDoSimulador, largura: CGFloat) -> [MarcaDaFaixa: CGFloat] {
        Dictionary(uniqueKeysWithValues: faixa.linhas.map { ($0.marca, largura * CGFloat($0.fracao)) })
    }

    var body: some View {
        GeometryReader { geo in
            let largura = geo.size.width, altura = geo.size.height
            let x = Self.posicoes(faixa, largura: largura)
            let custo = x[.custo] ?? 0, empate = x[.empate] ?? 0, venda = x[.venda] ?? 0
            let tinta = paleta.cor(.texto)
            let zona = UnevenRoundedRectangle(bottomTrailingRadius: 12, topTrailingRadius: 12)
            ZStack(alignment: .topLeading) {
                // O trilho: o texto a 14%, como o da barra do orçamento. A altura vai escrita: a pilha cresce até a marca mais
                // alta (a venda, 16 pt a mais), e um trilho sem altura cresceria com ela, para 62 pt, e sobraria embaixo da zona.
                RoundedRectangle(cornerRadius: 12).fill(tinta.opacity(0.14)).frame(height: altura)
                // A zona "acima do banco", hachurada, com o contorno no destaque, recortada em volta das marcas (decisão do
                // Giovani de 24/11, saída (c) do Croqui): o contorno sob o empate e a venda as deixava em 1,90:1 no escuro e
                // 2,96:1 no claro. Ela começa 4 pt depois do tracejado e abre uma fenda de 8 pt onde passa a venda; atrás das
                // marcas fica o trilho, como atrás do custo. É fundo, e não marca: fica no print das marcas apagadas.
                let inicio = empate + Self.vaoDoEmpate
                zona.fill(paleta.cor(.positivoFundo))
                    .overlay { Hachura(traco: 2, passo: 6).fill(paleta.cor(.destaque).opacity(0.55)).clipShape(zona) }
                    .overlay { zona.strokeBorder(paleta.cor(.destaque), lineWidth: 1.5) }
                    .frame(width: max(0, largura - inicio), height: altura)
                    // A fenda fora da zona (a venda abaixo do banco) não recorta nada.
                    .mask(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                            Rectangle().frame(width: Self.fendaDaVenda)
                                .offset(x: venda - inicio - Self.fendaDaVenda / 2)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    }
                    .offset(x: inicio)
                Group {
                    // O custo: uma barra de 3 pt, 6 acima e 6 abaixo da faixa.
                    RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 3, height: altura + 12).offset(x: custo, y: -6)
                    // O empate com o banco: o tracejado.
                    Path { p in
                        p.move(to: CGPoint(x: empate + 1, y: -6))
                        p.addLine(to: CGPoint(x: empate + 1, y: altura + 6))
                    }
                    .stroke(tinta, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    // A venda: a barra de 4 pt, 8 acima e 8 abaixo, com o ponto de 12 pt em cima.
                    RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 4, height: altura + 16).offset(x: venda - 2, y: -8)
                    Circle().fill(tinta).frame(width: 12, height: 12).offset(x: venda - 6, y: -15)
                }
                .opacity(marcasSomem ? 0 : 1)
            }
        }
    }

    private var marcasSomem: Bool {
        #if DEBUG
        return apagadas
        #else
        return false
        #endif
    }
}

/// Uma linha da lista embaixo da faixa: o marcador da marca, o rótulo e o valor em mono; na letra de acessibilidade, o
/// valor embaixo do rótulo.
private struct LinhaDaLegendaDaFaixa: View {
    let linha: LinhaDaFaixa
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            HStack(spacing: 10) {
                marcador.frame(width: 18, height: 18)
                Text(linha.rotulo)
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
            ValorEmDinheiro(linha.valor, mono: .miudo)
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .padding(.vertical, grande ? 8 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(linha.rotulo)
        .accessibilityValue(linha.valor)
        .accessibilityIdentifier("simFaixa-\(linha.marca.rawValue)")
    }

    @ViewBuilder private var marcador: some View {
        let tinta = paleta.cor(.texto)
        switch linha.marca {
        case .custo: RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 3, height: 18)
        case .empate:
            Path { p in
                p.move(to: CGPoint(x: 9, y: 0))
                p.addLine(to: CGPoint(x: 9, y: 18))
            }
            .stroke(tinta, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
        case .venda: Circle().fill(tinta).frame(width: 12, height: 12)
        }
    }
}

/// A tabela do site, "Relatório da simulação" (mockup da etapa 4, parte2.css:100-107; decisão 7 da parte 2): em pares, com
/// o rótulo em cima e os dois valores embaixo, "Pelo bruto" e "Pelo corrigido"; na letra de acessibilidade, um valor por
/// linha, cada um com o nome da coluna em cima. O lucro vai em negrito. O que é negativo vai em âmbar, nunca em vermelho
/// (nota do quadro `sim-abaixo-baixo`). Para o VoiceOver, cada linha é um elemento, com os dois valores.
struct TabelaDoValeAPena: View {
    static let colunas = ["Pelo bruto", "Pelo corrigido"]
    let linhas: [LinhaDaSimulacao]
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    /// A cor de um valor pelo sinal: positivo no verde dos números, negativo no âmbar, sem sinal no texto.
    static func cor(_ sinal: SinalDaSimulacao?) -> Token {
        switch sinal {
        case .positivo: return .positivoNoVidro
        case .negativo: return .alertaNoVidro
        case nil: return .texto
        }
    }

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        BlocoDeVidro {
            Text("Relatório da simulação")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("simTituloDaTabela")
                .padding(.bottom, 8)
            if !grande {
                HStack(spacing: 12) {
                    ForEach(Self.colunas, id: \.self) { coluna in
                        Text(coluna)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 6)
                .accessibilityHidden(true)
                LinhaFina()
            }
            ForEach(Array(linhas.enumerated()), id: \.offset) { indice, linha in
                VStack(alignment: .leading, spacing: 0) {
                    Text(linha.rotulo)
                        .font(.subheadline)
                        .foregroundStyle(paleta.cor(vidro.secundario))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 9)
                    let par = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 12))
                    par {
                        valor(linha.bruto, linha.sinalBruto, coluna: grande ? Self.colunas[0] : nil, forte: linha.destaque)
                        valor(linha.corrigido, linha.sinalCorrigido, coluna: grande ? Self.colunas[1] : nil, forte: linha.destaque)
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                    if indice < linhas.count - 1 { LinhaFina() }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(linha.rotulo)
                .accessibilityValue("\(Self.colunas[0]) \(linha.bruto), \(Self.colunas[1].lowercased()) \(linha.corrigido)")
                .accessibilityIdentifier("simTabela-\(indice)")
            }
        }
    }

    private func valor(_ texto: String, _ sinal: SinalDaSimulacao?, coluna: String?, forte: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let coluna {
                Text(coluna).font(.footnote.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
            }
            ValorEmDinheiro(texto, mono: .miudo, cor: Self.cor(sinal)).fontWeight(forte ? .bold : nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Com obra e sem preço: a frase do site, num bloco de vidro.
struct SemPrecoDoValeAPena: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        BlocoDeVidro {
            Text("Digite o preço de venda pra ver a conta.")
                .font(.subheadline)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("simSemPreco")
        }
    }
}

/// Uma linha do bloco dos campos: 56 pt no mínimo, o rótulo no corpo do texto e o valor à direita; na letra de
/// acessibilidade, o valor embaixo do rótulo.
private struct LinhaDoCampo<Valor: View>: View {
    let rotulo: String
    @ViewBuilder let valor: Valor
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            Text(rotulo)
                .font(.body)
                .foregroundStyle(paleta.cor(.texto))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
                .accessibilityHidden(true)
            valor
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

/// O − e o + dos meses: um círculo chapado na Placa (não é vidro: está dentro do bloco de vidro), com o símbolo no texto;
/// desabilitado, a 40%.
private struct BotaoDoPasso: View {
    let simbolo: String
    let rotulo: String
    let identificador: String
    let lado: CGFloat
    let acao: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.isEnabled) private var habilitado

    var body: some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .font(.system(size: lado * 0.45, weight: .medium))
                .foregroundStyle(paleta.cor(.texto))
                .frame(width: lado, height: lado)
                .background(paleta.cor(.placa), in: .circle)
                .contentShape(.circle)
                .opacity(habilitado ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotulo)
        .accessibilityIdentifier(identificador)
    }
}
