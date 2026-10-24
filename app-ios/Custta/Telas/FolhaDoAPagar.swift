import SwiftUI
import CusttaNucleo

/* A folha "A pagar · 30 dias" (mockup da etapa 3, parte 2, seção 1; o sheetAPagar do site), aberta pela seta do indicador:
   o mesmo total e os mesmos vencimentos do indicador, a partir de amanhã, num grupo de resumo; os vencimentos por mês,
   como no "A vencer", com a linha de gasto da etapa 2 e sem a etiqueta "a vencer" em cada linha (aqui tudo vence); no fim,
   a frase do que vem depois dos 30 dias, que está no "A vencer" da obra. Vazia, abre com "Nenhum gasto previsto para esse
   período." e não fecha quando fica vazia (site); fecham o × e o puxar (o "Fechar" do site sai). Tocar num vencimento
   empurra a edição na mesma folha (a volta à folha de origem, FolhaDeOrigem.swift). Dentro da folha tudo é sólido. */
struct FolhaDoAPagar: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var origem = OrigemDaEdicao(titulo: "A pagar · 30 dias", nome: "A pagar")
    @State private var alertas = AlertasNaFolha()

    private var obra: Obra? { modelo.sincronizador.estado.obras.first { $0.id == obraId } }

    var body: some View {
        NavigationStack(path: $origem.caminho) {
            ListaDoAPagar(obraId: obraId, origem: origem)
                .passoDaFolha(origem.titulo, subtitulo: obra?.nome, fechar: .esquerda, escape: .fechar)
                .navigationDestination(for: PassoDaOrigem.self) { passo in
                    DestinoNaOrigem(passo: passo, origem: origem)
                }
        }
        // O "Não salvou" de uma edição salva aqui: a folha de origem não desce, e o da raiz só aparece com a folha fechada.
        .alertaDeNaoSalvou(quando: alertas.nenhum)
        // A trava do puxar fica fora da pilha: dentro do passo, ela não chega à folha (medido em 19/10). Quem lê a mudança é
        // o próprio FolhaDoApp, e não este corpo, para cada tecla da descrição não refazer a lista.
        .folhaDoApp(perguntar: { origem.temOQuePerder }, pergunta: "Você mudou este gasto.",
                    mensagem: "As mudanças ainda não foram salvas.", descartar: "Descartar mudanças") { folhas.fechar() }
        .environment(\.alertasNaFolha, alertas)
        // A obra apagada em outro aparelho com a folha aberta: não há o que mostrar; a folha fecha.
        .onChange(of: obra == nil) { _, sumiu in if sumiu { folhas.fechar() } }
    }
}

/// O resumo, os vencimentos por mês e a frase do fim, sobre a lista das folhas de origem (ListaDaOrigem.swift, com o
/// tocar, o arrastar, a volta da edição e o apagar): aqui, só o que é do A pagar.
private struct ListaDoAPagar: View {
    let obraId: String
    @Bindable var origem: OrigemDaEdicao
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == obraId }) {
            let aPagar = aPagarDaObra(obra, hoje: dataLocalISO(.now, fuso: .current))
            let topicos = mapaDeTopicos(estado.config.topicosProprios)
            ListaDaOrigem(obra: obra, origem: origem, pecas: pecasDaOrigem(aPagar.meses),
                          pecasDepois: { pecasDaOrigem(aPagarDaObra($0, hoje: dataLocalISO(.now, fuso: .current)).meses) },
                          linha: { linhaDeGasto($0, topicos: topicos) }) {
                ResumoDoAPagar(total: aPagar.total, qtd: aPagar.qtd)
            } vazio: {
                VazioDoAPagar()
            } rodape: {
                if let ponte = aPagar.ponte {
                    NotaDaFolha(texto: ponte, identificador: "ponteDoAPagar").padding(.top, 14)
                }
            }
        } else {
            Color.clear
        }
    }
}

/// O total e "{N} vencimentos · a partir de amanhã" (o texto do site, também no zero), num grupo sólido: o valor em 28
/// bold, como o resumo do detalhe do tópico (mockup).
private struct ResumoDoAPagar: View {
    let total: Double
    let qtd: Int
    @Environment(\.paleta) private var paleta

    var body: some View {
        GrupoDaFolha {
            VStack(alignment: .leading, spacing: 2) {
                ValorEmDinheiro(texto: moeda(total), fonte: .title.weight(.bold))
                Text(textoVencimentos(qtd))
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("resumoDoAPagar")
        }
    }
}

/// "Nenhum gasto previsto para esse período." (o texto do site), com o calendário no quadrado de raio 14; o ícone sai na
/// letra grande, como no cartão de estado da lista.
private struct VazioDoAPagar: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        GrupoDaFolha {
            VStack(spacing: 10) {
                if !tamanho.isAccessibilitySize {
                    Image(decorative: "Icones/calendario")
                        .resizable().frame(width: 26, height: 26)
                        .foregroundStyle(paleta.cor(.linkNoVidro))
                        .frame(width: 48, height: 48)
                        .background(paleta.cor(.tecla), in: .rect(cornerRadius: 14, style: .continuous))
                }
                Text("Nenhum gasto previsto para esse período.")
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("aPagarVazio")
        }
    }
}

/// Uma peça da lista de uma folha de origem, filha direta da LazyVStack: o cabeçalho de um mês ou um gasto, com o lugar
/// dele no grupo do mês.
struct PecaDaOrigem: Identifiable, Equatable {
    enum Tipo: Equatable {
        case mes(MesDeGastos)
        case gasto(Gasto)
    }

    let tipo: Tipo
    /// O primeiro gasto do grupo: sem a linha fina em cima.
    let primeiro: Bool
    /// O último gasto do grupo: com os cantos de baixo do grupo.
    let ultimo: Bool

    var id: String {
        switch tipo {
        case .mes(let mes): "mes-\(mes.id)"
        case .gasto(let gasto): gasto.id
        }
    }
}

/// As peças da lista, na ordem: cada mês, o cabeçalho e os gastos dele.
func pecasDaOrigem(_ meses: [MesDeGastos]) -> [PecaDaOrigem] {
    meses.flatMap { mes in
        [PecaDaOrigem(tipo: .mes(mes), primeiro: false, ultimo: false)]
            + mes.gastos.enumerated().map { i, g in
                PecaDaOrigem(tipo: .gasto(g), primeiro: i == 0, ultimo: i == mes.gastos.count - 1)
            }
    }
}

/// O fundo sólido do grupo, desenhado por peça (as peças são filhas diretas da LazyVStack): os cantos de cima no
/// cabeçalho, os de baixo no último gasto, e o recorte nos mesmos cantos.
struct FundoDoGrupo: ViewModifier {
    let cima: Bool
    let baixo: Bool
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let forma = UnevenRoundedRectangle(topLeadingRadius: cima ? 24 : 0, bottomLeadingRadius: baixo ? 24 : 0,
                                           bottomTrailingRadius: baixo ? 24 : 0, topTrailingRadius: cima ? 24 : 0, style: .continuous)
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(paleta.cor(.linhaDaFolha), in: forma)
            .clipShape(forma)
            .padding(.horizontal, 16)
    }
}
