import SwiftUI
import CusttaNucleo

/* O alto da obra na identidade nova (etapa 4, PR 1c; mockup aprovado, parte1.js:254-287 e parte1-obra-topo.png): o bloco
   sólido protagonista e um bloco de vidro por assunto, na ordem da etapa 3 (Orçamento, Corrigido pelo banco, A pagar ·
   30 dias, Venda). Na vendida com lucro (decisão 4: A), o sólido é o lucro e o Total gasto desce para um bloco de vidro
   logo depois do Orçamento; com prejuízo (B), o sólido volta a ser o Total gasto e o lucro fica no bloco da venda, em
   âmbar, nunca vermelho. Os textos e as contas são os do site (indicadoresDaObra, orcamentoObra, lucroVenda). Cada bloco é
   um elemento só para o VoiceOver: o número solto reprova a descrição suficiente da auditoria. */

/// O que o sólido da obra mostra: o Total gasto ou, na vendida com lucro, o lucro da venda.
enum SolidoDaObra: Equatable {
    case total
    /// "+R$ 537.682,55", "Vendida em 20/06/26" e "+R$ 482.871,47 acima do banco" (o acima do banco negativo leva o "−").
    case lucro(valor: String, etiqueta: String, nota: String)
}

/// A vendida com lucro bruto (zero conta como lucro, como o `>= 0` do mockup) põe o lucro no sólido; o resto, o Total gasto.
func solidoDaObra(_ obra: Obra, taxa: Double) -> SolidoDaObra {
    guard obra.fase == .vendida, let venda = obra.venda, let lucro = lucroVenda(obra, taxa: taxa), lucro.bruto >= 0 else {
        return .total
    }
    return .lucro(valor: comSinal(lucro.bruto), etiqueta: "Vendida em \(dataCurta(venda.data))",
                  nota: "\(comSinal(lucro.vsBanco)) acima do banco")
}

/// A nota do Total gasto: sem gastos, o convite para lançar o primeiro pelo +; na vendida, não (o + de lá não lança nela:
/// abre a folha com a linha "Obra", para escolher outra), e fica o "bruto, sem correção".
func notaDoTotal(_ obra: Obra) -> String {
    obra.gastos.isEmpty && obra.fase != .vendida ? "Toque no + para lançar o primeiro gasto." : "bruto, sem correção"
}

/// O valor com o sinal na frente: "+R$ …" ou "−R$ …" (o menos tipográfico, o do gasto).
func comSinal(_ valor: Double) -> String {
    valor < 0 ? "\u{2212}" + moeda(-valor) : "+" + moeda(valor)
}

/// O sólido e os blocos de vidro do alto da obra, 12 pt um do outro.
struct BlocosDaObra: View {
    let obra: Obra
    let taxa: Double
    let hoje: String
    /// O bloco "A pagar · 30 dias": a folha dele.
    let abrirAPagar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let indicadores = indicadoresDaObra(obra, taxa: taxa, hoje: hoje)
        let solido = solidoDaObra(obra, taxa: taxa)
        VStack(spacing: Grade.entreBlocos) {
            switch solido {
            case .total: total(indicadores, solido: true)
            case let .lucro(valor, etiqueta, nota): lucro(valor: valor, etiqueta: etiqueta, nota: nota)
            }
            if let orcamento = orcamentoObra(obra) {
                NavigationLink(value: RotaDeObras.orcamento(obra.id)) { LinhaDoOrcamento(resumo: orcamento, comSeta: true) }
                    .buttonStyle(.plain)
                    // O Controle por Voz chama pelo nome do bloco ("Tocar Orçamento"), não pelo rótulo inteiro.
                    .accessibilityInputLabels(["Orçamento"])
            }
            if solido != .total { total(indicadores, solido: false) }
            blocoDeVidro(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido)
                .accessibilityIdentifier("indicadorCorrigido")
            aPagar(indicadores)
            venda(indicadores.venda)
        }
    }

    /// O Total gasto: no sólido, ou no vidro logo depois do Orçamento quando o sólido é o lucro. Sem gastos, o R$ 0,00 com o
    /// convite para lançar o primeiro.
    private func total(_ indicadores: IndicadoresDaObra, solido: Bool) -> some View {
        let nota = notaDoTotal(obra)
        return Group {
            if solido {
                BlocoSolido {
                    CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal)
                    NotaDoBloco(texto: nota)
                }
            } else {
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Total gasto") {
                        EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: obra.gastos.isEmpty ? .neutro : .marca)
                    }
                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal)
                    NotaDoBloco(texto: nota)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorTotal")
    }

    private func lucro(valor: String, etiqueta: String, nota: String) -> some View {
        BlocoSolido {
            CabecalhoDoBloco(rotulo: "Lucro da venda") { EtiquetaDoSolido(texto: etiqueta) }
            ValorEmDinheiro(valor, mono: .principal)
            NotaDoBloco(texto: nota)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorLucro")
    }

    /// Um bloco de vidro com o rótulo, a etiqueta, o número e a nota, num elemento só.
    private func blocoDeVidro(rotulo: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       corDaNota: Token? = nil) -> some View {
        BlocoDeVidro { miolo(rotulo: rotulo, etiqueta: etiqueta, valor: valor, nota: nota, corDaNota: corDaNota) }
            .accessibilityElement(children: .combine)
    }

    private func miolo(rotulo: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       corDaNota: Token? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CabecalhoDoBloco(rotulo: rotulo) {
                if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
            }
            // O "—" de valor nenhum (venda sem estimativa) vai no secundário, como no mockup.
            ValorEmDinheiro(valor, mono: .bloco, cor: valor == "—" ? vidro.secundario : .texto)
            NotaDoBloco(texto: nota, cor: corDaNota)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "A pagar · 30 dias": o bloco inteiro é o botão da folha dele, com a seta das linhas tocáveis no meio da altura.
    private func aPagar(_ indicadores: IndicadoresDaObra) -> some View {
        Button(action: abrirAPagar) {
            HStack(spacing: 10) {
                miolo(rotulo: "A pagar · 30 dias", etiqueta: (indicadores.etiquetaDoAPagar, .alerta), valor: indicadores.aPagar,
                      nota: "Parcelas e gastos futuros")
                SetaDoBloco()
            }
            .padding(.vertical, Grade.recuoVertical(letra))
            .padding(.horizontal, Grade.recuo)
            .contentShape(.rect)
            .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(letra)))
        }
        .buttonStyle(.plain)
        // O Controle por Voz chama pelo nome do bloco ("Tocar A pagar"), não pelo rótulo inteiro.
        .accessibilityInputLabels(["A pagar"])
        .accessibilityIdentifier("indicadorAPagar")
    }

    @ViewBuilder private func venda(_ venda: VendaNaTela) -> some View {
        switch venda {
        case .vendida(let valor, let etiqueta, let nota, let lucroPositivo):
            blocoDeVidro(rotulo: "Venda", etiqueta: (etiqueta, .positivo), valor: valor, nota: nota,
                       corDaNota: lucroPositivo ? .positivoNoVidro : .alertaNoVidro)
                .accessibilityIdentifier("indicadorVenda")
        case .estimada(let valor, let nota):
            blocoDeVidro(rotulo: "Venda estimada", etiqueta: ("estimativa", .positivo), valor: valor, nota: nota)
                .accessibilityIdentifier("indicadorVenda")
        case .semEstimativa:
            blocoDeVidro(rotulo: "Venda estimada", etiqueta: nil, valor: "—", nota: "Toque no lápis para informar o valor")
                .accessibilityIdentifier("indicadorVenda")
        }
    }
}

/// A seta dos blocos tocáveis (Orçamento, A pagar, Afazeres): 14 pt de largura, no secundário do vidro (o .chev do
/// mockup); para no AX2 e ocupa 20 pt na letra de acessibilidade. Figura, fora do VoiceOver e do laudo.
struct SetaDoBloco: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.body.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .frame(width: letra.isAccessibilitySize ? 20 : 14)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .accessibilityHidden(true)
            .foraDoLaudo()
    }
}
