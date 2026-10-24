import SwiftUI
import CusttaNucleo

/* As peças da tela Orçamento (mockup aprovado da etapa 3, parte 1, seção 3, e "Medidas"): o cartão no estilo do herói
   (16/18 de recuo, raio 24), as linhas dos tópicos com o ícone de 38, o nome em body semibold, o valor em subheadline e a
   frase em footnote, o cabeçalho do que está fora e a dica do modo total. Textos do site (rodapeOrc, linhaTopicoOrc,
   fraseTopicoOrc) e das regras novas do app (tituloDoCartao, previstoDoCartao, fraseDoForaNoCartao, gastoPorTopico). */

/// O que uma linha de tópico da tela Orçamento mostra.
struct LinhaDeTopicoDoOrcamento: Identifiable, Equatable {
    let id: String
    let nome: String
    let icone: String
    /// O gasto, em destaque ("R$ 91 mil").
    let gasto: String
    /// O previsto, sem o "R$", no "Por tópico" ("85 mil"); nil fora dele.
    let previsto: String?
    /// A barra, no "Por tópico".
    let item: ItemOrcamento?
    /// A frase do site ("Passou R$ 6,2 mil do previsto") ou, no gasto por tópico, "38% da obra".
    let frase: String?
    /// A linha abre o detalhe do tópico (a seta e o toque): o tópico tem gasto.
    let abre: Bool
    /// A frase do "passou", no âmbar.
    var fraseEmAlerta = false
}

/// O tópico pelo id; o que o app não conhece (tópico próprio apagado) aparece pelo id, com o ícone etiqueta, como no site.
private func topico(_ id: String, _ topicos: [String: Topico]) -> Topico {
    topicos[id] ?? Topico(id: id, nome: id, icone: "etiqueta")
}

/// O "Por tópico": os previstos, na ordem do site (quem gastou mais do previsto primeiro). Abre o detalhe o previsto com gasto:
/// a regra do site é ter gasto (o detalhe fecha sem nenhum), e não a soma.
func linhasPorTopico(_ r: ResumoOrcamento, topicos: [String: Topico], gastos: [Gasto]) -> [LinhaDeTopicoDoOrcamento] {
    let comGasto = Set(gastos.map(\.topico))
    return r.topicos.map { t in
        let id = t.id ?? "", nome = topico(id, topicos), linha = linhaTopicoOrc(t), frase = fraseTopicoOrc(t)
        return LinhaDeTopicoDoOrcamento(id: id, nome: nome.nome, icone: nome.icone, gasto: linha.gasto, previsto: linha.previsto,
                                        item: t, frase: frase?.texto, abre: comGasto.contains(id), fraseEmAlerta: frase?.alerta ?? false)
    }
}

/// Uma linha por tópico fora do orçamento (gasto sem previsto), do maior gasto para o menor; todas abrem o detalhe.
func linhasForaDoOrcamento(_ r: ResumoOrcamento, topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
    r.fora.map { f in
        let t = topico(f.id, topicos)
        return LinhaDeTopicoDoOrcamento(id: f.id, nome: t.nome, icone: t.icone, gasto: moedaCurtaSemZero(f.gasto), previsto: nil,
                                        item: nil, frase: nil, abre: true)
    }
}

/// O "Gasto por tópico" do modo total: o bruto e o "% da obra" de cada tópico com gasto; todas abrem o detalhe.
func linhasDoGastoPorTopico(_ gastos: [GastoDoTopico], topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
    gastos.map { g in
        let t = topico(g.id, topicos)
        return LinhaDeTopicoDoOrcamento(id: g.id, nome: t.nome, icone: t.icone, gasto: moedaCurtaSemZero(g.bruto), previsto: nil,
                                        item: nil, frase: textoDaParteDaObra(g.pct), abre: true)
    }
}

/// O "de R$ … previstos em N tópicos" do cartão partido em volta do dinheiro (previstoDoCartao do núcleo), para ele ir para a
/// própria linha na letra grande.
func partesDoPrevisto(_ r: ResumoOrcamento) -> (antes: String, valor: String, depois: String) {
    let n = r.topicos.count
    return ("de", moeda(r.geral.previsto), r.modo == "topicos" ? "previstos em \(n) tópico\(n == 1 ? "" : "s")" : "")
}

/// "Os R$ … fora do orçamento não entram nesta conta." partido em volta do dinheiro (fraseDoForaNoCartao do núcleo).
func partesDoFora(_ r: ResumoOrcamento) -> (antes: String, valor: String, depois: String)? {
    guard fraseDoForaNoCartao(r) != nil else { return nil }
    return ("Os", moeda(r.foraTotal), "fora do orçamento não entram nesta conta.")
}

/// O cartão da tela Orçamento: o título do modo e o nível, o gasto, "de {previsto} previstos em N tópicos", a barra,
/// "{pct}% usado" e quanto sobra (ou passou) e, por tópico com gasto fora, a frase de que ele não entra na conta.
struct CartaoDoOrcamento: View {
    let resumo: ResumoOrcamento
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let geral = resumo.geral, rodape = rodapeOrc(geral), previsto = partesDoPrevisto(resumo)
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { titulo; Spacer(minLength: 8); etiqueta }
                VStack(alignment: .leading, spacing: 6) { titulo; etiqueta }
            }
            ValorEmDinheiro(texto: moeda(geral.gasto), fonte: .title.weight(.bold))
                .padding(.top, 4)
            FraseComDinheiro(antes: previsto.antes, valor: previsto.valor, depois: previsto.depois, cor: vidro.secundario)
            BarraDoOrcamento(item: geral)
                .padding(.top, 12)
                .padding(.bottom, 8)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { usado(rodape.usado); Spacer(minLength: 12); sobra(rodape) }
                VStack(alignment: .leading, spacing: 2) { usado(rodape.usado); sobra(rodape) }
            }
            if let fora = partesDoFora(resumo) {
                LinhaFina().padding(.top, 10)
                FraseComDinheiro(antes: fora.antes, valor: fora.valor, depois: fora.depois, cor: vidro.secundario)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cartaoDoOrcamento")
    }

    private var titulo: some View {
        Text(tituloDoCartao(resumo)).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var etiqueta: some View {
        EtiquetaDoIndicador(texto: resumo.geral.nivel.pilula, cor: corDoNivel(resumo.geral.nivel))
    }

    /// "80% usado", o número em negrito na cor do texto.
    private func usado(_ pct: String) -> some View {
        Text("\(Text(pct).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))) usado")
            .font(.subheadline)
            .foregroundStyle(paleta.cor(vidro.secundario))
    }

    /// "sobra R$ 207.310,90", o valor em negrito na cor do texto; na letra grande, o valor na própria linha, encolhendo.
    private func sobra(_ rodape: RodapeDoOrcamento) -> some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                                                 : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 4))
        return layout {
            Text(rodape.rotulo).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
            ValorEmDinheiro(texto: rodape.valor, fonte: .subheadline.weight(.semibold))
        }
    }
}

/// Uma linha de tópico da tela Orçamento: o ícone, o nome, o gasto (e "/ previsto"), a barra fina e a frase. O valor não
/// quebra; o nome quebra antes, com o valor no meio da altura dele (o `.ot` do mockup). A linha fora do orçamento, só com o
/// nome e o gasto, fica no meio da altura do ícone. Na letra grande, sem o ícone, cada informação numa linha. A coluna da
/// seta fica reservada em toda linha. A que abre o detalhe do tópico (`abre`) é um botão inteiro, o do indicador A pagar,
/// com a seta no meio da altura; a do previsto sem gasto fica sem seta e é um elemento só para o VoiceOver, sem traço de
/// botão.
struct LinhaDeTopicoNoOrcamento: View {
    let linha: LinhaDeTopicoDoOrcamento
    let identificador: String
    /// O toque na linha que abre: o detalhe do tópico.
    let abrir: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        if linha.abre {
            // A linha inteira é o botão: o quadro e o contentShape dentro do rótulo, ou o toque e o foco do VoiceOver ficam
            // só no miolo.
            Button(action: abrir) {
                conteudo
                    .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identificador)
        } else {
            conteudo
                .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(identificador)
        }
    }

    private var conteudo: some View {
        let grande = tamanho.isAccessibilitySize
        return HStack(alignment: linha.item == nil && linha.frase == nil ? .center : .top, spacing: 11) {
            if !grande {
                Image(decorative: iconeDoCatalogo(linha.icone))
                    .resizable().frame(width: 20, height: 20)
                    .foregroundStyle(paleta.cor(.marca))
                    .frame(width: 38, height: 38)
                    .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
                    .padding(.top, 1)
            }
            VStack(alignment: .leading, spacing: 5) {
                if grande {
                    nome
                    valor
                } else {
                    HStack(spacing: 11) {
                        nome.frame(maxWidth: .infinity, alignment: .leading)
                        valor
                    }
                }
                if let item = linha.item { BarraDoOrcamento(item: item, fina: true) }
                if let frase = linha.frase { FraseDoTopicoNoOrcamento(texto: frase, alerta: linha.fraseEmAlerta) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // A coluna da seta (14 pt; 22 na letra grande), reservada em toda linha.
            Color.clear.frame(width: grande ? 22 : 14, height: 1)
        }
        // A seta, no meio da altura da linha, sobre a coluna (o .chev do mockup ocupa todas as linhas da grade).
        .overlay(alignment: .trailing) {
            if linha.abre {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    // O mesmo chevron da linha do Orçamento: para no AX2 e ocupa 18 pt na maior letra e 9 na padrão.
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .frame(width: tamanho.isAccessibilitySize ? 18 : 9)
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .accessibilityHidden(true)
                    .foraDoLaudo()
                    .frame(width: grande ? 22 : 14)
            }
        }
    }

    private var nome: some View {
        Text(linha.nome).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var valor: some View { ValorDoTopicoNoOrcamento(gasto: linha.gasto, previsto: linha.previsto) }
}

/// A frase do site embaixo da barra ("Faltam R$ 3,3 mil — 96%"; no modo total, "38% da obra"), no secundário; a do
/// "passou", em semibold, no âmbar sobre o vidro.
struct FraseDoTopicoNoOrcamento: View {
    let texto: String
    let alerta: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        Text(texto)
            .font(.footnote.weight(alerta ? .semibold : .regular))
            .foregroundStyle(paleta.cor(alerta ? .alertaNoVidro : vidro.secundario))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "R$ 91 mil / 85 mil": o gasto em negrito na cor do texto e "/ previsto" no secundário. Não quebra (o `white-space: nowrap`
/// do mockup); na letra grande, na própria linha, quebra se precisar.
struct ValorDoTopicoNoOrcamento: View {
    let gasto: String
    let previsto: String?
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let negrito = Text(gasto).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))
        let texto = previsto.map { Text("\(negrito) \(Text("/ \($0)").foregroundStyle(paleta.cor(vidro.secundario)))") } ?? negrito
        return texto.font(.subheadline).fixedSize(horizontal: !tamanho.isAccessibilitySize, vertical: true)
    }
}

/// "Fora do orçamento" e o total, no cabeçalho do grupo, como o cabeçalho de um mês.
struct CabecalhoDoForaDoOrcamento: View {
    let total: Double
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { titulo; Spacer(minLength: 8); valor }
            VStack(alignment: .leading, spacing: 2) { titulo; valor }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(paleta.cor(vidro.secundario))
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 2, trailing: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("foraDoOrcamento")
    }

    private var titulo: some View { Text("Fora do orçamento") }
    private var valor: some View { ValorEmDinheiro(texto: moeda(total), fonte: .footnote.weight(.semibold), cor: vidro.secundario) }
}

/// A dica do fim da tela no modo total, numa pílula de vidro.
struct DicaDoModoTotal: View {
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(dicaDoModoTotal)
            .font(.footnote)
            .foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .superficie(.conteudo, em: .rect(cornerRadius: 14))
            .padding(.horizontal, 14)
            .padding(.top, 2)
            .accessibilityIdentifier("dicaDoModoTotal")
    }
}
