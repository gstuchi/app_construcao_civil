import SwiftUI
import CusttaNucleo

/* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site) e o veredito no bloco sólido;
   a faixa e a tabela chegam nos próximos commits. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
   enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
   as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
struct ValeAPenaView: View {
    @Binding var campos: CamposDoSimulador
    @Environment(ModeloApp.self) private var modelo
    @State private var confirmarSaida = false
    @State private var barra = BarraDaObra()

    var body: some View {
        let estado = modelo.sincronizador.estado
        let tela = simulacaoNaTela(campos, obras: estado.obras, hoje: dataLocalISO(.now, fuso: .current),
                                   taxa: estado.config.taxaMensal)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                    TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
                        .padding(.bottom, 2)
                    CamposDoValeAPena(campos: $campos, tela: tela)
                    // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
                    if let veredito = tela.veredito {
                        VereditoDoValeAPena(veredito: veredito)
                    } else if tela.obra != nil {
                        SemPrecoDoValeAPena()
                    }
                }
                .padding(.horizontal, Grade.externa)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .tituloPequenoAoRolar(barra)
            .background { LeitorDaLetra(barra: barra) }
            .pausaOFundoAoRolar()
            .bordaDeRolagem(abas: true)
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

/// O bloco dos campos: a obra, o preço e os meses, uma linha cada (o rótulo à esquerda e o valor à direita; na letra de
/// acessibilidade, um embaixo do outro, como o mockup), e a nota do site. Para o VoiceOver, cada linha é o controle dela,
/// com o rótulo da linha e o valor: o texto do rótulo sai da leitura, para não ser lido duas vezes.
struct CamposDoValeAPena: View {
    @Binding var campos: CamposDoSimulador
    let tela: SimulacaoNaTela
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        BlocoDeVidro(recuoVertical: 4) {
            LinhaDoCampo(rotulo: "Obra") { obra }
            LinhaFina()
            LinhaDoCampo(rotulo: "Se eu vender por") { preco }
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

    /// O preço: o digitado ou, sem digitar, a venda estimada da obra; vazio, "R$ 0,00" apagado, como o campo do site.
    private var preco: some View {
        Group {
            if let valor = tela.preco {
                ValorEmDinheiro(moeda(valor), mono: .linha)
            } else {
                ValorEmDinheiro(moeda(0), mono: .linha, cor: vidro.secundario)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Se eu vender por")
        .accessibilityValue(tela.preco.map { moeda($0) } ?? "sem preço")
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
