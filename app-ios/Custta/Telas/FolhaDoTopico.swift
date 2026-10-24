import SwiftUI
import CusttaNucleo

/* O detalhe do tópico (mockup da etapa 3, parte 1, a folha do tópico; o sheetTopico do site), aberto por uma linha da tela
   Orçamento: o resumo do tópico num grupo sólido (quantos gastos e o "% da obra", o bruto, o corrigido e, no orçamento por
   tópico, a linha do orçamento dele) e os gastos em "A vencer" (o próximo primeiro, como na obra) e "Pagos" (o mais novo
   primeiro, como no site), cada seção só com gasto, com a linha de gasto da etapa 2 sem o tópico: o título da folha já o
   diz. Fecham o × e o puxar (o "Fechar" do site sai); e, quando o tópico fica sem gasto, a folha desce, como no site. Tocar
   num gasto empurra a edição na mesma folha, e arrastar uma linha mostra "Apagar", pela lista das folhas de origem, a mesma
   do A pagar (ListaDaOrigem.swift). Dentro da folha tudo é sólido. */
struct FolhaDoTopico: View {
    let obraId: String
    let topicoId: String
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        // O nome vem dos dados (um tópico próprio também abre): a origem da edição nasce com ele, que o voltar da edição e o
        // subtítulo dela dizem.
        PilhaDoTopico(obraId: obraId, topico: topicoDoDetalhe(topicoId, proprios: modelo.sincronizador.estado.config.topicosProprios))
    }
}

/// A pilha da folha, montada como a do A pagar (FolhaDoAPagar.swift): a edição empurrada, o "Não salvou" dentro da folha, a
/// trava do puxar com mudança e a folha que fecha quando a obra some; e, só aqui, a que desce quando o tópico fica sem gasto.
private struct PilhaDoTopico: View {
    let obraId: String
    let topico: Topico
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var origem: OrigemDaEdicao
    @State private var alertas = AlertasNaFolha()

    init(obraId: String, topico: Topico) {
        self.obraId = obraId
        self.topico = topico
        _origem = State(initialValue: OrigemDaEdicao(titulo: topico.nome, nome: topico.nome))
    }

    private var obra: Obra? { modelo.sincronizador.estado.obras.first { $0.id == obraId } }
    /// Nenhum gasto do tópico na obra gravada (o filtro do detalheDoTopico); a obra que some é o outro onChange.
    private var semGasto: Bool { obra.map { o in !o.gastos.contains { $0.topico == topico.id } } ?? false }

    var body: some View {
        NavigationStack(path: $origem.caminho) {
            ListaDoTopico(obraId: obraId, topico: topico, origem: origem)
                .passoDaFolha(topico.nome, subtitulo: obra?.nome, fechar: .esquerda, escape: .fechar)
                .navigationDestination(for: PassoDaOrigem.self) { passo in
                    DestinoNaOrigem(passo: passo, origem: origem)
                }
        }
        // O "Não salvou" de uma edição salva aqui: a folha de origem não desce, e o da raiz só aparece com a folha fechada.
        .alertaDeNaoSalvou(quando: alertas.nenhum)
        // A trava do puxar fica fora da pilha, lida pelo próprio FolhaDoApp, como no A pagar.
        .folhaDoApp(perguntar: { origem.temOQuePerder }, pergunta: "Você mudou este gasto.",
                    mensagem: "As mudanças ainda não foram salvas.", descartar: "Descartar mudanças") { folhas.fechar() }
        .environment(\.alertasNaFolha, alertas)
        // A obra apagada em outro aparelho com a folha aberta: não há o que mostrar; a folha fecha.
        .onChange(of: obra == nil) { _, sumiu in if sumiu { folhas.fechar() } }
        // O último gasto do tópico saiu, por qualquer caminho (apagado aqui, da edição ou arrastando; trocado de tópico; apagado
        // ou mudado em outro aparelho): a folha desce, como o sheetTopico do site. Lido da obra gravada, depois de gravar: a
        // recusa não muda nada e não fecha. O que se vê é a folha descendo, sem esperar a linha sair.
        .onChange(of: semGasto) { _, vazio in if vazio { folhas.fechar() } }
    }
}

/// O resumo e as seções do tópico, sobre a lista das folhas de origem (ListaDaOrigem.swift, com o tocar, o arrastar, a volta
/// da edição e o apagar): aqui, só o que é do detalhe.
private struct ListaDoTopico: View {
    let obraId: String
    let topico: Topico
    @Bindable var origem: OrigemDaEdicao
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == obraId }) {
            let id = topico.id, taxa = estado.config.taxaMensal
            let detalhe = detalheDoTopico(obra, topico: id, hoje: dataLocalISO(.now, fuso: .current), taxaMensal: taxa)
            let topicos = mapaDeTopicos(estado.config.topicosProprios)
            ListaDaOrigem(obra: obra, origem: origem, pecas: pecasDoDetalhe(detalhe),
                          pecasDepois: { pecasDoDetalhe(detalheDoTopico($0, topico: id, hoje: dataLocalISO(.now, fuso: .current), taxaMensal: taxa)) },
                          linha: { linhaDeGasto($0, topicos: topicos, comTopico: false) }, desceSemGasto: true) {
                ResumoDoDetalhe(detalhe: detalhe, icone: topico.icone)
            } vazio: {
                EmptyView()
            } rodape: {
                EmptyView()
            }
        } else {
            Color.clear
        }
    }
}

/// O tópico do detalhe: um do catálogo ou um próprio; o que o app não conhece (apagado em Ajustes) aparece pelo id, com o
/// ícone etiqueta, como na linha de gasto e no site.
func topicoDoDetalhe(_ id: String, proprios: [TopicoProprio]) -> Topico {
    mapaDeTopicos(proprios)[id] ?? Topico(id: id, nome: id.isEmpty ? "Outros" : id, icone: "etiqueta")
}

/// As peças do detalhe, na ordem: "A vencer · N" e os gastos dele, depois "Pagos · N" e os dele, cada seção só com gasto. O
/// cabeçalho fica fora do grupo: o primeiro gasto da seção leva os cantos de cima, e o último, os de baixo.
func pecasDoDetalhe(_ d: DetalheDoTopico) -> [PecaDaOrigem] {
    [("A vencer", d.aVencer), ("Pagos", d.pagos)].flatMap { titulo, gastos -> [PecaDaOrigem] in
        guard !gastos.isEmpty else { return [] }
        return [PecaDaOrigem(tipo: .secao(titulo: titulo, quantidade: gastos.count), primeiro: false, ultimo: false)]
            + gastos.enumerated().map { i, g in
                PecaDaOrigem(tipo: .gasto(g), primeiro: i == 0, ultimo: i == gastos.count - 1, cima: i == 0)
            }
    }
}

/// "corrigido:" e o valor: o `corrigido` do núcleo partido, para o dinheiro ir para a própria linha na letra grande.
func partesDoCorrigido(_ d: DetalheDoTopico) -> (antes: String, valor: String) {
    ("corrigido:", moeda(d.resumo.corrigido))
}

/// O cabeçalho de uma seção do detalhe ("A vencer · 6"), fora do grupo (o .f-cab do mockup): 13 semibold no secundário, o
/// "· N" em peso médio, a 34 pt da borda (16 do grupo + 18; na letra grande, 22), 22 acima e 7 abaixo.
struct CabecalhoDaSecao: View {
    let titulo: String
    let quantidade: Int
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let lado: CGFloat = tamanho.isAccessibilitySize ? 22 : 34
        Text("\(Text(titulo + " ").font(.footnote.weight(.semibold)))\(Text("· " + String(quantidade)).font(.footnote.weight(.medium)))")
            .foregroundStyle(paleta.cor(.secundarioTransparente))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 22, leading: lado, bottom: 7, trailing: lado))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("secao-\(titulo)")
    }
}

/// O resumo do tópico num grupo sólido (o .td-res do mockup, 16 de padding e 14 embaixo): o ícone de 34 e "11 gastos · 9% da
/// obra", o bruto em 28 bold numa linha só (como o resumo do A pagar), o corrigido e a linha do orçamento do tópico. Na letra
/// grande, sem o ícone, com o dinheiro do corrigido na própria linha.
private struct ResumoDoDetalhe: View {
    let detalhe: DetalheDoTopico
    let icone: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let corrigido = partesDoCorrigido(detalhe)
        GrupoDaFolha {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        if !tamanho.isAccessibilitySize {
                            Image(decorative: iconeDoCatalogo(icone))
                                .resizable().frame(width: 19, height: 19)
                                .foregroundStyle(paleta.cor(.marca))
                                .frame(width: 34, height: 34)
                                .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 10))
                        }
                        Text(detalhe.linha)
                            .font(.subheadline)
                            .foregroundStyle(paleta.cor(.secundarioTransparente))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ValorEmDinheiro(texto: moeda(detalhe.resumo.bruto), fonte: .title.weight(.bold))
                        .padding(.top, 8)
                    FraseComDinheiro(antes: corrigido.antes, valor: corrigido.valor, cor: .secundarioTransparente)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("resumoDoTopico")
                OrcamentoNoDetalhe(orcamento: detalhe.orcamento)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A linha do orçamento do tópico, embaixo do corrigido, com um fio em cima (o .td-orc do mockup): "No orçamento" e o
/// previsto em semibold na cor do texto, a barra de 8 e a frase do site (a do "passou" no âmbar e em semibold; no nível ok,
/// "{pct}% usado"); fora do orçamento, "Sem valor no orçamento: não entra na comparação." no lugar de tudo; com só o total
/// (ou sem orçamento), nada. O previsto quebra para a linha de baixo quando não cabe; na letra grande, a frase vai em
/// subheadline.
private struct OrcamentoNoDetalhe: View {
    let orcamento: OrcamentoDoTopico
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        switch orcamento {
        case .nenhum:
            EmptyView()
        case .previsto(let item):
            let frase = fraseDoOrcamentoNoDetalhe(item)
            comFio {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 0) { rotulo; Spacer(minLength: 12); previsto(item) }
                    VStack(alignment: .leading, spacing: 4) { rotulo; previsto(item) }
                }
                BarraDoOrcamento(item: item)
                    .padding(.top, 8)
                texto(frase.texto, alerta: frase.alerta)
                    .padding(.top, 7)
            }
        case .semValor:
            comFio { texto(semValorNoOrcamento, alerta: false) }
        }
    }

    private var rotulo: some View {
        Text(rotuloNoOrcamento)
            .font(.subheadline)
            .foregroundStyle(paleta.cor(.secundarioTransparente))
    }

    private func previsto(_ item: ItemOrcamento) -> some View {
        ValorEmDinheiro(texto: moeda(item.previsto), fonte: .subheadline.weight(.semibold))
    }

    private func texto(_ t: String, alerta: Bool) -> some View {
        Text(t)
            .font(tamanho.isAccessibilitySize ? .subheadline : .footnote)
            .fontWeight(alerta ? .semibold : nil)
            .foregroundStyle(paleta.cor(alerta ? .alerta : .secundarioTransparente))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// O fio em cima, a 12 do corrigido, e o conteúdo 12 abaixo dele; um elemento só para o VoiceOver.
    private func comFio(@ViewBuilder _ conteudo: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SeparadorDaFolha(recuo: 0)
            VStack(alignment: .leading, spacing: 0, content: conteudo)
                .padding(.top, 12)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("orcamentoDoTopico")
    }
}
