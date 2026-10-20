import SwiftUI
import CusttaNucleo

/* A busca e o filtro por mês da lista de lançamentos (mockup aprovado da etapa 3, parte 2, seção 3, opção A): dois botões
   redondos de vidro ao lado da pílula "Lançamentos", a lupa e o mês. A lupa abre o campo "Buscar gasto ou tópico" e o
   teclado; o × fecha a busca e limpa o texto. O mês sai de um Menu do sistema, com "Todos os meses" e os meses que têm
   gasto, por extenso, com quantos gastos cada um tem, e vira um chip com × embaixo da pílula: o filtro de mês nunca fica
   escondido (o mês escolhido continua no chip e no menu mesmo sem gasto, o conserto do achado 1). Com filtro, a pílula conta
   "achados/total", "Soma dos achados" dá o total, e a lista vazia diz por quê, com o botão que limpa. Na maior letra, a
   pílula e os botões ocupam duas linhas, o campo fica com a largura toda e a própria lupa vira × para fechar. */

/// O filtro da lista de lançamentos. Mora na tela da obra, e não no modelo: zera ao trocar de obra (site), não vai para a
/// nuvem, e o que está sendo digitado não depende do estado que chega do Sincronizador (achado 3).
@MainActor @Observable
final class BuscaDaObra {
    /// O campo à vista (a lupa tocada).
    var aberta = false
    var texto = ""
    /// AAAA-MM; vazio é "Todos os meses".
    var mes = ""

    var filtro: FiltroGastos { FiltroGastos(texto: texto, mes: mes) }

    /// Busca ou mês valendo, pela mesma conta do `contadorLancamentos`: o texto aparado e sem acento (espaço sozinho não
    /// filtra) ou um mês escolhido.
    var filtrando: Bool { !aparadoJS(semAcento(texto)).isEmpty || !mes.isEmpty }

    /// O × do campo: fecha a busca e limpa o texto; o mês fica.
    func fechar() {
        aberta = false
        texto = ""
    }

    /// O botão do "Nada encontrado com esse filtro." ("Limpar a busca", "Limpar o mês" ou "Limpar busca e mês"): limpa os
    /// dois, o que vale para os três (o botão só nomeia a busca quando não há mês, e só o mês quando a busca está vazia).
    func limpar() {
        texto = ""
        mes = ""
    }
}

extension Obra {
    /// A mesma obra com só os gastos dados: a lista filtrada agrupa e soma só os achados (cada mês com a soma dos seus, o
    /// "A vencer" com os seus).
    func comOsGastos(_ gastos: [Gasto]) -> Obra {
        var o = self
        o.gastos = gastos
        return o
    }
}

/// A pílula "Lançamentos" e, ao lado, a lupa e o mês (na maior letra, os botões descem para a linha de baixo, maiores).
/// Sem gasto e sem filtro, só a pílula: não há o que buscar.
struct CabecalhoDosLancamentos: View {
    let contador: String
    let busca: BuscaDaObra
    let meses: [MesDoFiltro]
    let comBotoes: Bool
    let foco: AccessibilityFocusState<AlvoDoFoco?>.Binding
    let abrir: () -> Void
    let fechar: () -> Void
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let falado = contador.isEmpty ? "Lançamentos" : "Lançamentos, \(contador.replacingOccurrences(of: "/", with: " de "))"
        let pilula = PilulaDaLista(titulo: "Lançamentos", numero: contador, falado: falado, identificador: "lancamentos")
            .accessibilityFocused(foco, equals: .lancamentos)
        if !comBotoes {
            pilula
        } else if tamanho.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) { pilula; botoes }
        } else {
            HStack(spacing: 10) { pilula; Spacer(minLength: 0); botoes }
        }
    }

    /// A lupa abre a busca (ou devolve o foco ao campo já aberto); na maior letra, com o campo aberto, ela vira o × que
    /// fecha, e o × ao lado do campo sai (o campo fica com a largura toda).
    private var botoes: some View {
        let fecha = tamanho.isAccessibilitySize && busca.aberta
        return HStack(spacing: 10) {
            Button { fecha ? fechar() : abrir() } label: {
                CirculoDaLista(icone: fecha ? .sistema("xmark") : .catalogo("Icones/lupa"), aceso: busca.aberta)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(fecha ? "Fechar a busca" : "Buscar gasto ou tópico")
            .accessibilityIdentifier("buscar")
            MenuDoMes(busca: busca, meses: meses)
        }
    }
}

/// O ícone de um botão redondo: do catálogo do site (a lupa, o calendário) ou do sistema (o ×).
enum IconeDoCirculo {
    case catalogo(String)
    case sistema(String)
}

/// O botão redondo ao lado da pílula: vidro do conteúdo, 44 pt (64 na maior letra), ícone de 21 (32); aceso, sólido na
/// marca, com o ícone na cor de sobre a marca (a lupa com a busca aberta, o mês com um mês escolhido).
struct CirculoDaLista: View {
    let icone: IconeDoCirculo
    let aceso: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let lado: CGFloat = grande ? 64 : 44
        let desenho = Group {
            switch icone {
            case .catalogo(let nome):
                Image(decorative: nome).resizable().frame(width: grande ? 32 : 21, height: grande ? 32 : 21)
            case .sistema(let nome):
                Image(systemName: nome).font(.system(size: grande ? 26 : 17, weight: .semibold)).accessibilityHidden(true)
            }
        }
        .foregroundStyle(paleta.cor(aceso ? .sobreMarca : .texto))
        .frame(width: lado, height: lado)
        Group {
            if aceso { desenho.background(paleta.cor(.marca), in: .circle) } else { desenho.superficie(.conteudo, em: .circle) }
        }
        .contentShape(.circle)
    }
}

/// O mês, num Menu do sistema preso ao botão: "Todos os meses" e os meses com gasto, do mais novo ao mais antigo, com os
/// futuros, por extenso como nos cartões da lista, e quantos gastos cada um tem. A marca fica no escolhido, que continua no
/// menu mesmo sem gasto. Cada mês é um item que marca (a marca do sistema) com o subtítulo: o menu do sistema não tem a
/// coluna à direita do mockup para a contagem, e o VoiceOver lê "Outubro de 2026, 6 gastos".
struct MenuDoMes: View {
    let busca: BuscaDaObra
    let meses: [MesDoFiltro]

    var body: some View {
        Menu {
            item("", titulo: "Todos os meses", subtitulo: nil)
            Section {
                ForEach(meses, id: \.mes) { m in
                    item(m.mes, titulo: tituloDoMes(m.mes), subtitulo: m.qtd == 1 ? "1 gasto" : "\(m.qtd) gastos")
                }
            }
        } label: {
            CirculoDaLista(icone: .catalogo("Icones/calendario"), aceso: !busca.mes.isEmpty)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filtrar por mês")
        .accessibilityValue(busca.mes.isEmpty ? "Todos os meses" : tituloDoMes(busca.mes))
        .accessibilityIdentifier("filtrarPorMes")
    }

    /// Tocar no escolhido não o tira: escolhe de novo o mesmo (tirar é o × do chip ou "Todos os meses").
    private func item(_ mes: String, titulo: String, subtitulo: String?) -> some View {
        Toggle(isOn: Binding(get: { busca.mes == mes }, set: { _ in busca.mes = mes })) {
            Text(titulo)
            if let subtitulo { Text(subtitulo) }
        }
    }
}

/// O campo da busca, embaixo da pílula: vidro do conteúdo em cápsula, a lupa, o texto e o × que apaga o texto; ao lado, o
/// × que fecha a busca. Na maior letra o texto quebra linha, a lupa do campo sai e o × de fechar também (a lupa de cima
/// vira ×). O exemplo é desenhado num Text, que quebra, e o prompt fica no campo, transparente, para o VoiceOver.
struct CampoDaBusca: View {
    @Binding var texto: String
    var foco: FocusState<Bool>.Binding
    let fechar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                if !grande {
                    Image(decorative: "Icones/lupa").resizable().frame(width: 18, height: 18)
                        .foregroundStyle(paleta.cor(vidro.secundario))
                }
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
                    if texto.isEmpty {
                        Text("Buscar gasto ou tópico")
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .accessibilityHidden(true)
                            .onTapGesture { foco.wrappedValue = true }
                    }
                    TextField("Buscar gasto ou tópico", text: $texto, prompt: Text("Buscar gasto ou tópico").foregroundStyle(.clear),
                              axis: .vertical)
                        .foregroundStyle(paleta.cor(.texto))
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .focused(foco)
                        // Com prompt, o título do TextField não vira o rótulo do VoiceOver (o CampoDeEntrada também o põe).
                        .accessibilityLabel("Buscar gasto ou tópico")
                        .accessibilityIdentifier("campoDaBusca")
                        // No campo que quebra linha, o "buscar" do teclado chega como "\n": sai do texto e fecha o teclado.
                        .onChange(of: texto) { _, novo in
                            guard novo.contains("\n") else { return }
                            texto = novo.replacingOccurrences(of: "\n", with: "")
                            foco.wrappedValue = false
                        }
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                if !texto.isEmpty {
                    Button { texto = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: grande ? 30 : 18))
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .frame(width: grande ? 52 : 36, height: grande ? 52 : 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Apagar o texto")
                    .accessibilityIdentifier("apagarTextoDaBusca")
                }
            }
            .padding(EdgeInsets(top: grande ? 8 : 0, leading: grande ? 18 : 14, bottom: grande ? 8 : 0, trailing: grande ? 6 : 4))
            .frame(minHeight: grande ? 64 : 44)
            .superficie(.conteudo, em: .rect(cornerRadius: grande ? 32 : 22, style: .continuous))
            if !grande {
                Button(action: fechar) { CirculoDaLista(icone: .sistema("xmark"), aceso: false) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fechar a busca")
                    .accessibilityIdentifier("fecharBusca")
            }
        }
    }
}

/// O mês escolhido, num chip de vidro com o calendário, o nome por extenso e o × que tira o filtro (alvo de 44 pt; na
/// maior letra o nome quebra e o × cresce).
struct ChipDoMes: View {
    let mes: String
    let tirar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        HStack(spacing: 8) {
            Image(decorative: "Icones/calendario").resizable().frame(width: grande ? 28 : 18, height: grande ? 28 : 18)
                .foregroundStyle(paleta.cor(.linkNoVidro))
            Text(tituloDoMes(mes))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityIdentifier("chipDoMes")
            Button(action: tirar) {
                Image(systemName: "xmark")
                    .font(.system(size: grande ? 22 : 14, weight: .semibold))
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .frame(width: grande ? 52 : 36, height: grande ? 52 : 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tirar o filtro do mês")
            .accessibilityIdentifier("tirarOMes")
        }
        .padding(EdgeInsets(top: grande ? 8 : 0, leading: grande ? 16 : 14, bottom: grande ? 8 : 0, trailing: 4))
        .frame(minHeight: 44)
        .superficie(.conteudo, em: .rect(cornerRadius: grande ? 26 : 22, style: .continuous))
    }
}

/// "Soma dos achados: R$ …" numa pílula de vidro embaixo do filtro; sem espaço, o valor vai para a linha de baixo, numa
/// linha só, e encolhe para caber. Na letra de acessibilidade, o valor vai para baixo e pode quebrar ("R$" numa linha e o
/// número na outra): com ele numa linha só (`lineLimit(1)`, encolhendo ou não), escolher o mês parava a thread principal de
/// 45 a 70 s no iOS 26 na maior letra; com ele livre, não (sondas dos runs 40429944214 e 40435271147).
struct SomaDosAchadosView: View {
    let soma: SomaDosAchados
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        Group {
            if tamanho.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    rotulo
                    Text(soma.valor).font(.subheadline.weight(.semibold)).monospacedDigit().foregroundStyle(paleta.cor(.texto))
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) { rotulo; valor }
                    VStack(alignment: .leading, spacing: 2) { rotulo; valor }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .superficie(.conteudo, em: .rect(cornerRadius: tamanho.isAccessibilitySize ? 22 : 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(soma.falado)
        .accessibilityIdentifier("somaDosAchados")
    }

    private var rotulo: some View {
        Text(soma.rotulo).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario)).fixedSize(horizontal: false, vertical: true)
    }

    private var valor: some View { ValorEmDinheiro(texto: soma.valor, fonte: .subheadline.weight(.semibold)) }
}

/// A lista vazia com filtro: o mês que ficou sem gasto ("Ver todos os meses" tira o mês) ou nada achado (o botão limpa o
/// que filtra).
struct VazioDaBuscaView: View {
    let vazio: VazioDaBusca
    let limpar: () -> Void
    let verTodos: () -> Void

    var body: some View {
        switch vazio {
        case .mesSemGasto(let titulo, let botao):
            CartaoDeEstado(titulo: titulo, texto: nil, icone: "Icones/calendario", identificador: "buscaMesSemGasto") {
                Button(botao, action: verTodos).buttonStyle(LinkDaLista()).accessibilityIdentifier("verTodosOsMeses")
            }
        case .nadaEncontrado(let titulo, let frase, let botao):
            CartaoDeEstado(titulo: titulo, texto: frase, icone: "Icones/lupa", identificador: "buscaNadaEncontrado") {
                Button(botao, action: limpar).buttonStyle(LinkDaLista()).accessibilityIdentifier("limparFiltro")
            }
        }
    }
}

/// O botão em texto dentro de um cartão de vidro ("Limpar a busca", "Ver todos os meses"): body semibold na cor do link
/// sobre o vidro, sem sublinhado, com 44 pt de altura (o .lnk do mockup).
struct LinkDaLista: ButtonStyle {
    @Environment(\.paleta) private var paleta

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(paleta.cor(.linkNoVidro))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
