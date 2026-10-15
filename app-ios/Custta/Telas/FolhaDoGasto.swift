import SwiftUI
import CusttaNucleo

/* A folha do gasto (mockup da etapa 2, parte 2; formGasto do site). Gasto novo: o valor no teclado de valor e
   "Avançar" empurra os detalhes, na ordem do site (valor, tópico, pagamento, descrição e data), com "Salvar" fixo
   embaixo. Editar: direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); numa parcela, o aviso do site no lugar
   do pagamento; "Apagar gasto" no fim. O que vira gasto e as mensagens vêm do núcleo (as regras do dados.js); a tela só
   guarda o rascunho e decide para onde ir. */

enum PassoDoGasto: Hashable {
    case detalhes
    case valor
    case topicos
}

/// O formulário enquanto a folha está aberta: começa do gasto em edição, ou do vazio do gasto novo, e só vira gasto no
/// "Salvar".
@MainActor @Observable
final class RascunhoDoGasto {
    let obraId: String
    let editado: Gasto?
    let topicos: [Topico]
    let usados: [Topico]
    let indice: IndiceDeSugestoes
    var centavos: Int
    var topico: String
    var pagamento: String
    var parcelas = 1
    var juros = "0"
    var descricao: String
    /// Cada forma de pagamento guarda a sua data no gasto novo (app.js:996, 1022-1026): o Pix começa hoje; o cartão, um
    /// mês à frente. Na edição a data é uma só.
    private var datas: [String: String]
    /// Repetido: a assinatura do primeiro toque no "Salvar". O segundo toque com a mesma salva; mexer em qualquer campo
    /// muda a assinatura e o aviso some.
    var assinaturaAvisada: String?
    /// Gasto novo: passou do valor, e fechar passa a perguntar.
    var passouDoValor = false
    private var inicial: [String] = []

    init(obra: Obra, editado: Gasto?, todas: [Obra], proprios: [TopicoProprio], hoje: String) {
        obraId = obra.id
        self.editado = editado
        topicos = topicosDoFormulario(proprios)
        usados = usadosNestaObra(obra, topicos: topicos)
        indice = IndiceDeSugestoes(todas, obraId: obra.id, ignorarId: editado?.id)
        if let g = editado {
            centavos = reaisParaCentavos(g.valor)
            topico = g.topico
            // Pagamento fora de Pix e Cartão fica como veio até a pessoa escolher (o site regrava o que estava).
            pagamento = g.pagamento.isEmpty ? "pix" : g.pagamento
            descricao = g.descricao
            datas = ["pix": g.data, "cartao": g.data]
        } else {
            centavos = 0
            topico = topicoInicial(obra, topicos: topicos)
            pagamento = "pix"
            descricao = ""
            datas = ["pix": hoje, "cartao": addMesesClampado(hoje, 1)]
        }
        inicial = foto
    }

    var data: String {
        // Na edição as duas formas guardam a mesma data, e o pagamento pode ser um que o app não oferece ("boleto").
        get { datas[editado == nil ? pagamento : "pix"] ?? "" }
        set {
            if editado == nil { datas[pagamento] = newValue } else { datas = ["pix": newValue, "cartao": newValue] }
        }
    }

    /// Parcela de uma compra no cartão: a edição vale só para ela, e o pagamento não muda.
    var parcela: Parcela? { editado?.grupoId != nil ? editado?.parcela : nil }

    /// O cartão parcelado só existe no gasto novo (no site, o bloco fica escondido na edição).
    var cartaoNovo: Bool { editado == nil && pagamento == "cartao" }

    /// "Todos" na lista de tópicos, sem os de "Usados nesta obra" (o mockup não repete).
    var topicosSemOsUsados: [Topico] { topicos.filter { t in !usados.contains { $0.id == t.id } } }

    var entrada: EntradaDoGasto {
        EntradaDoGasto(valor: centavosParaReais(centavos), topico: topico, descricao: aparadoJS(descricao), data: data,
                       pagamento: pagamento, parcelas: parcelas, juros: lerTaxaCartao(juros))
    }

    /// O resumo ao vivo do cartão (app.js:1007-1008).
    var resumoDoCartao: String {
        let e = entrada
        return CusttaNucleo.resumoDoCartao(parcelamentoCartao(e.valor, e.parcelas, e.juros, e.data))
    }

    /// Fechar pergunta antes: no gasto novo, depois de passar do valor; na edição, se algo mudou.
    var temOQuePerder: Bool { editado == nil ? passouDoValor : foto != inicial }

    private var foto: [String] {
        [String(centavos), topico, pagamento, String(parcelas), juros, descricao, datas["pix"] ?? "", datas["cartao"] ?? ""]
    }

    /// A descrição tem até 500 unidades UTF-16, como o `maxlength` do site.
    func limitarDescricao() {
        guard descricao.utf16.count > Limites.descricao else { return }
        var r = ""
        // Corta no primeiro caractere que não cabe, como o maxlength: nada depois dele entra.
        for c in descricao {
            guard r.utf16.count + c.utf16.count <= Limites.descricao else { break }
            r.append(c)
        }
        descricao = r
    }
}

struct FolhaDoGasto: View {
    let obraId: String
    let gastoId: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDoGasto?
    @State private var caminho: [PassoDoGasto] = []

    var body: some View {
        Group {
            if let rascunho {
                FolhaDoGastoAberta(rascunho: rascunho, caminho: $caminho)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra ou o gasto sumiram (apagados em outro aparelho) com a folha aberta: não há onde gravar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool {
        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == obraId }) else { return false }
        return gastoId.map { id in obra.gastos.contains { $0.id == id } } ?? true
    }

    private func montar() {
        guard rascunho == nil else { return }
        let estado = modelo.sincronizador.estado
        guard let obra = estado.obras.first(where: { $0.id == obraId }) else { folhas.fechar(); return }
        let editado = gastoId.flatMap { id in obra.gastos.first { $0.id == id } }
        if gastoId != nil && editado == nil { folhas.fechar(); return }
        rascunho = RascunhoDoGasto(obra: obra, editado: editado, todas: estado.obras, proprios: estado.config.topicosProprios,
                                   hoje: dataLocalISO(.now, fuso: .current))
        #if DEBUG
        if editado == nil, let r = rascunho { abrirNoPassoDeTeste(r, obra: obra) }
        #endif
    }
}

#if DEBUG
extension FolhaDoGasto {
    /// Laudo e conferência visual (`-custta.folha <passo>`, com o PrincipalView): a folha do gasto novo já preenchida.
    private func abrirNoPassoDeTeste(_ r: RascunhoDoGasto, obra: Obra) {
        switch UserDefaults.standard.string(forKey: "custta.folha") {
        case "valor":
            r.centavos = 138_000
        case "detalhes", "topicos":
            r.centavos = 138_000
            r.passouDoValor = true
            caminho = UserDefaults.standard.string(forKey: "custta.folha") == "topicos" ? [.detalhes, .topicos] : [.detalhes]
        case "cartao":
            r.centavos = 498_000
            r.pagamento = "cartao"
            r.parcelas = 10
            r.passouDoValor = true
            caminho = [.detalhes]
        case "repetido":
            // O mesmo gasto que já existe na obra (a regra do site avisa) e o aviso já mostrado.
            guard let g = obra.gastos.first(where: { !$0.descricao.isEmpty && $0.grupoId == nil }) else { return }
            r.centavos = reaisParaCentavos(g.valor)
            r.topico = g.topico
            r.descricao = g.descricao
            r.data = g.data
            r.passouDoValor = true
            if case .success(let c) = conferirGasto(r.entrada, editado: nil, hoje: dataLocalISO(.now, fuso: .current)) {
                r.assinaturaAvisada = assinaturaDoGasto(obraId: obra.id, entrada: r.entrada, conferido: c)
            }
            caminho = [.detalhes]
        default:
            break
        }
    }
}
#endif

private struct FolhaDoGastoAberta: View {
    @Bindable var rascunho: RascunhoDoGasto
    @Binding var caminho: [PassoDoGasto]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    private var nomeDaObra: String {
        modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? ""
    }

    var body: some View {
        NavigationStack(path: $caminho) {
            Group {
                if rascunho.editado == nil {
                    PassoDoValor(rascunho: rascunho, titulo: "Valor do gasto", subtitulo: nomeDaObra, acao: "Avançar", raiz: true) {
                        rascunho.passouDoValor = true
                        caminho = [.detalhes]
                    }
                } else {
                    PassoDosDetalhes(rascunho: rascunho, caminho: $caminho, subtitulo: nomeDaObra, raiz: true)
                }
            }
            .navigationDestination(for: PassoDoGasto.self) { passo in
                switch passo {
                case .detalhes:
                    PassoDosDetalhes(rascunho: rascunho, caminho: $caminho, subtitulo: nomeDaObra, raiz: false)
                case .valor:
                    PassoDoValor(rascunho: rascunho, titulo: "Valor", subtitulo: nomeDaObra, acao: "Pronto", raiz: false) {
                        caminho.removeLast()
                    }
                case .topicos:
                    ListaDeTopicos(rascunho: rascunho) { caminho.removeLast() }
                }
            }
        }
        .folhaDoApp(perguntar: rascunho.temOQuePerder, pergunta: "Você já preencheu este gasto.", descartar: "Descartar gasto") {
            folhas.fechar()
        }
    }
}

/// O passo do valor: o teclado de valor ocupando a folha.
private struct PassoDoValor: View {
    @Bindable var rascunho: RascunhoDoGasto
    let titulo: String
    let subtitulo: String
    let acao: String
    let raiz: Bool
    let confirmar: () -> Void

    var body: some View {
        TecladoDeValor(centavos: $rascunho.centavos, acao: acao, confirmar: confirmar)
            .passoDaFolha(titulo, subtitulo: subtitulo, fechar: raiz ? .esquerda : nil, raiz: raiz)
    }
}

/// Os detalhes: valor, tópico, pagamento (com o cartão), descrição e data; "Salvar" fixo embaixo.
private struct PassoDosDetalhes: View {
    @Bindable var rascunho: RascunhoDoGasto
    @Binding var caminho: [PassoDoGasto]
    let subtitulo: String
    let raiz: Bool
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @FocusState private var foco: Campo?
    @State private var erroDoCartao: String?
    @State private var erroDaDescricao: String?
    @State private var naoCarregado = false
    @State private var contaReal = false
    @State private var apagando = false
    @State private var sugestaoEscolhida: String?

    enum Campo: Hashable { case juros, descricao }

    var body: some View {
        ScrollViewReader { leitor in
            ScrollView {
                VStack(spacing: 20) {
                    GrupoDaFolha {
                        linhaDoValor
                        SeparadorDaFolha()
                        linhaDoTopico
                    }
                    pagamento
                    if let c = rascunho.editado.flatMap(condicoesOriginais) { NotaDaFolha(texto: c) }
                    descricao.id("descricao")
                    VStack(spacing: 8) {
                        GrupoDaFolha {
                            let rotulo = rascunho.cartaoNovo ? "Primeiro vencimento" : "Data"
                            LinhaDaFolhaComRotulo(rotulo: rotulo) {
                                CampoDeData(iso: $rascunho.data, rotulo: rotulo)
                            }
                        }
                        if avisoDeRepetido { NotaDaFolha(texto: CusttaNucleo.avisoDeRepetido, cor: .alerta, identificador: "avisoRepetido") }
                    }
                    if rascunho.editado != nil {
                        GrupoDaFolha {
                            Button("Apagar gasto") { apagando = true }
                                .foregroundStyle(paleta.cor(.erroNoVidro))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .accessibilityIdentifier("apagarGasto")
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            // O teclado decimal dos juros não tem tecla de fechar.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if foco == .juros {
                        Spacer()
                        Button("OK") { foco = nil }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // O identificador no próprio botão: depois do fundo (que desce até a borda da tela, atrás do teclado), o
                // quadro de acessibilidade ia junto, e o toque do VoiceOver e do XCUITest caía no teclado.
                Button(avisoDeRepetido ? "Salvar mesmo assim" : "Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha(ambar: avisoDeRepetido))
                    .accessibilityIdentifier("salvarGasto")
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 0)
                    .background {
                        LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                       startPoint: .bottom, endPoint: .top)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
            }
            // Com o teclado do sistema, a descrição sobe para as sugestões caberem acima dele.
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                guard foco == .descricao else { return }
                withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.25)) { leitor.scrollTo("descricao", anchor: .top) }
            }
        }
        .passoDaFolha(rascunho.editado == nil ? "Novo gasto" : "Editar gasto", subtitulo: subtitulo,
                      fechar: raiz ? .esquerda : .direita, raiz: raiz)
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("O gasto continua aqui; nada foi salvo ainda.")
        }
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ContaDeTeste.mensagem)
        }
        .modifier(PerguntaDeApagar(apresentada: $apagando, obraId: rascunho.obraId, gasto: rascunho.editado) { pedido in
            folhas.fechar { folhas.apagar(pedido) }
        })
    }

    private var avisoDeRepetido: Bool {
        guard let a = rascunho.assinaturaAvisada, case .success(let c) = conferirGasto(rascunho.entrada, editado: rascunho.editado,
                                                                                        hoje: dataLocalISO(.now, fuso: .current)) else { return false }
        return a == assinaturaDoGasto(obraId: rascunho.obraId, entrada: rascunho.entrada, conferido: c)
    }

    private var linhaDoValor: some View {
        Button {
            if rascunho.editado == nil { caminho.removeAll() } else { caminho.append(.valor) }
        } label: {
            LinhaDaFolhaComRotulo(rotulo: "Valor", altura: 60) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("R$").font(.callout.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioTransparente))
                    ValorEmDinheiro(texto: fmtCentavos(rascunho.centavos), fonte: .title2.weight(.bold))
                        .foregroundStyle(paleta.cor(.texto))
                    SetaDaLinha()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Valor")
        .accessibilityValue(moeda(centavosParaReais(rascunho.centavos)))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("linhaValor")
    }

    private var linhaDoTopico: some View {
        let t = mapaDeTopicos(modelo.sincronizador.estado.config.topicosProprios)[rascunho.topico]
        return Button { caminho.append(.topicos) } label: {
            LinhaDaFolhaComRotulo(rotulo: "Tópico") {
                HStack(spacing: 10) {
                    IconeDoTopico(icone: t?.icone ?? "etiqueta")
                    Text(t?.nome ?? rascunho.topico).foregroundStyle(paleta.cor(.texto)).multilineTextAlignment(.trailing)
                    SetaDaLinha()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tópico")
        .accessibilityValue(t?.nome ?? rascunho.topico)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("linhaTopico")
    }

    @ViewBuilder private var pagamento: some View {
        if let p = rascunho.parcela {
            GrupoDaFolha {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(decorative: "Icones/cartao").resizable().frame(width: 20, height: 20)
                        .foregroundStyle(paleta.cor(.linkNoVidro))
                    Text(avisoDaParcela(p)).font(.subheadline).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("avisoParcela")
            }
        } else {
            VStack(spacing: 8) {
                GrupoDaFolha {
                    LinhaDaFolhaComRotulo(rotulo: "Pagamento") {
                        SegmentadoDaFolha(opcoes: [("pix", "Pix", "Icones/raio"), ("cartao", "Cartão", "Icones/cartao")],
                                          escolhida: $rascunho.pagamento, identificador: "pagamento")
                    }
                    if rascunho.cartaoNovo {
                        SeparadorDaFolha()
                        LinhaDaFolhaComRotulo(rotulo: "Parcelas") {
                            Picker("Parcelas", selection: $rascunho.parcelas) {
                                ForEach(1...36, id: \.self) { Text("\($0)x").tag($0) }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .tint(paleta.cor(.linkNoVidro))
                            .padding(.horizontal, 4)
                            .frame(minHeight: 34)
                            .background(paleta.cor(.segmentadoFundo), in: .rect(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("parcelas")
                        }
                        SeparadorDaFolha()
                        LinhaDaFolhaComRotulo(rotulo: "Juros ao mês") {
                            HStack(spacing: 4) {
                                TextField("0", text: $rascunho.juros)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($foco, equals: .juros)
                                    .frame(minWidth: 44, maxWidth: 44)
                                    .accessibilityLabel("Juros ao mês, em porcentagem")
                                    .accessibilityIdentifier("juros")
                                Text("%").foregroundStyle(paleta.cor(.secundarioTransparente)).accessibilityHidden(true)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 34)
                            .background(paleta.cor(.segmentadoFundo), in: .rect(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                if rascunho.cartaoNovo {
                    NotaDaFolha(texto: rascunho.resumoDoCartao, cor: .texto, identificador: "resumoDoCartao")
                        .accessibilityAddTraits(.updatesFrequently)
                    if let erroDoCartao { NotaDaFolha(texto: erroDoCartao, cor: .erroNoVidro, identificador: "erroDoCartao") }
                    NotaDaFolha(texto: ajudaDoCartao)
                }
            }
        }
    }

    private var descricao: some View {
        let termo = rascunho.descricao
        let sugestoes = foco == .descricao && termo != sugestaoEscolhida
            ? rascunho.indice.sugestoes(topicoId: rascunho.topico, termo: termo) : []
        return VStack(spacing: 8) {
            GrupoDaFolha {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Descrição (opcional)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(paleta.cor(.secundarioTransparente))
                        .accessibilityHidden(true)
                    TextField("Descrição (opcional)", text: $rascunho.descricao,
                              prompt: Text("Ex: 50 sacos de cimento").foregroundStyle(paleta.cor(.textoTerciario)))
                        .foregroundStyle(paleta.cor(.texto))
                        .focused($foco, equals: .descricao)
                        .submitLabel(.done)
                        .onChange(of: rascunho.descricao) { _, _ in rascunho.limitarDescricao(); erroDaDescricao = nil }
                        .accessibilityIdentifier("descricao")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                ForEach(sugestoes, id: \.chave) { s in
                    SeparadorDaFolha()
                    Button {
                        rascunho.descricao = s.texto
                        sugestaoEscolhida = s.texto
                    } label: {
                        LinhaDeSugestao(sugestao: s, termo: termo)
                    }
                    .buttonStyle(.plain)
                }
            }
            if let erroDaDescricao { NotaDaFolha(texto: erroDaDescricao, cor: .erroNoVidro) }
        }
    }

    private func salvar() {
        // A folha já está descendo (o primeiro toque gravou): o segundo toque de um toque duplo não lança de novo.
        guard folhas.aberta != nil else { return }
        foco = nil
        let entrada = rascunho.entrada
        switch conferirGasto(entrada, editado: rascunho.editado, hoje: dataLocalISO(.now, fuso: .current)) {
        case .failure(let erro):
            switch erro.campo {
            case "valor":
                // Sem mensagem, como o site: volta ao teclado.
                if rascunho.editado == nil { caminho.removeAll() } else { caminho.append(.valor) }
            case "descricao":
                erroDaDescricao = erro.mensagem
                foco = .descricao
            default:
                erroDoCartao = erro.mensagem
                foco = .juros
                if let m = erro.mensagem { AccessibilityNotification.Announcement(m).post() }
            }
        case .success(let conferido):
            erroDoCartao = nil
            guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == rascunho.obraId }) else { folhas.fechar(); return }
            if gastoRepetido(obra, descricao: entrada.descricao, valor: conferido.valor, data: conferido.data, ignorarId: rascunho.editado?.id) {
                let assinatura = assinaturaDoGasto(obraId: obra.id, entrada: entrada, conferido: conferido)
                if rascunho.assinaturaAvisada != assinatura {
                    rascunho.assinaturaAvisada = assinatura
                    AccessibilityNotification.Announcement(CusttaNucleo.avisoDeRepetido).post()
                    return
                }
            }
            gravar(entrada, conferido)
        }
    }

    private func gravar(_ entrada: EntradaDoGasto, _ conferido: GastoConferido) {
        let obraId = rascunho.obraId
        let novos: [Gasto]
        let resultado: ModeloApp.ResultadoDaGravacao
        if let editado = rascunho.editado {
            // A edição parte do gasto que está no estado agora (outro aparelho pode tê-lo mudado com a folha aberta).
            novos = [editado]
            resultado = modelo.gravar { $0.editandoGasto(editado.id, entrada, conferido, naObra: obraId) }
        } else {
            novos = gastosLancados(entrada, conferido) { gerarId() }
            resultado = modelo.gravar { $0.lancandoGastos(novos, naObra: obraId) }
        }
        switch resultado {
        case .gravou:
            let ids = novos.map(\.id)
            let novo = rascunho.editado == nil
            folhas.fechar { folhas.destacar(ids, novo: novo) }
        case .naoCarregado:
            naoCarregado = true
        case .contaReal:
            contaReal = true
        case .sumiu, .semConta:
            folhas.fechar()
        }
    }
}

/// O ícone de um tópico: 32 pt, raio 9, no fundo fantasma.
struct IconeDoTopico: View {
    let icone: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Image(decorative: iconeDoCatalogo(icone))
            .resizable()
            .frame(width: 18, height: 18)
            .foregroundStyle(paleta.cor(.fantasmaTexto))
            .frame(width: 32, height: 32)
            .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Uma sugestão de descrição: o relógio, o texto com o começo igual ao digitado em destaque e de onde ela vem.
private struct LinhaDeSugestao: View {
    let sugestao: SugestaoDeDescricao
    let termo: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock").imageScale(.small).foregroundStyle(paleta.cor(.secundarioTransparente)).accessibilityHidden(true)
            let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(spacing: 12))
            layout {
                texto.frame(maxWidth: .infinity, alignment: .leading)
                Text(sugestao.contexto).font(.footnote).foregroundStyle(paleta.cor(.secundarioTransparente))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sugestao.texto)
        .accessibilityValue(sugestao.contexto)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("sugestao-\(sugestao.texto)")
    }

    private var texto: Text {
        let t = sugestao.texto
        let busca = aparadoJS(termo)
        guard !busca.isEmpty, let r = t.range(of: busca, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) else {
            return Text(t).foregroundStyle(paleta.cor(.texto))
        }
        return Text("\(Text(t[r]).foregroundStyle(paleta.cor(.linkNoVidro)))\(Text(t[r.upperBound...]).foregroundStyle(paleta.cor(.texto)))")
    }
}

/// A data no calendário do iPhone (DatePicker compacto, que abre o calendário gráfico), em português.
struct CampoDeData: View {
    @Binding var iso: String
    /// O rótulo da linha, que o VoiceOver lê junto da data ("Primeiro vencimento", "Data da venda").
    var rotulo = "Data"
    var minimo: String?
    var maximo: String?

    var body: some View {
        DatePicker(rotulo, selection: data, in: intervalo, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            // A pílula da data não quebra linha: no AX5 passava da largura da folha e empurrava os grupos para fora.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(\.locale, Locale(identifier: "pt_BR"))
            .accessibilityIdentifier("data")
    }

    private var data: Binding<Date> {
        Binding(get: { Self.dia(iso) ?? .now }, set: { iso = dataLocalISO($0, fuso: .current) })
    }

    /// Mínimo depois do máximo (a obra que começa no futuro, na venda) vira só o máximo: o ClosedRange invertido derruba o app.
    private var intervalo: ClosedRange<Date> {
        let fim = maximo.flatMap(Self.dia) ?? .distantFuture
        return min(minimo.flatMap(Self.dia) ?? .distantPast, fim)...fim
    }

    /// AAAA-MM-DD ao meio-dia local (longe das mudanças de horário).
    static func dia(_ iso: String) -> Date? {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        var c = DateComponents()
        c.year = p[0]; c.month = p[1]; c.day = p[2]; c.hour = 12
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        return calendario.date(from: c)
    }
}

/// A lista de tópicos dentro da folha: "Usados nesta obra" no alto (três) e "Todos"; tocar escolhe e volta.
private struct ListaDeTopicos: View {
    @Bindable var rascunho: RascunhoDoGasto
    let voltar: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !rascunho.usados.isEmpty {
                    cabecalho("Usados nesta obra")
                    grupo(rascunho.usados, prefixo: "usado")
                    Color.clear.frame(height: 12)
                }
                cabecalho("Todos")
                grupo(rascunho.topicosSemOsUsados, prefixo: "topico")
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .passoDaFolha("Tópico", fechar: nil)
    }

    private func cabecalho(_ texto: String) -> some View {
        Text(texto)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(paleta.cor(.secundarioTransparente))
            .padding(.horizontal, 34)
            .accessibilityAddTraits(.isHeader)
    }

    private func grupo(_ topicos: [Topico], prefixo: String) -> some View {
        GrupoDaFolha {
            ForEach(Array(topicos.enumerated()), id: \.element.id) { i, t in
                if i > 0 { SeparadorDaFolha(recuo: 60) }
                Button {
                    rascunho.topico = t.id
                    voltar()
                } label: {
                    HStack(spacing: 12) {
                        IconeDoTopico(icone: t.icone)
                        Text(t.nome).foregroundStyle(paleta.cor(.texto)).frame(maxWidth: .infinity, alignment: .leading)
                        if t.id == rascunho.topico {
                            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.linkNoVidro))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 54)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(t.id == rascunho.topico ? [.isSelected] : [])
                .accessibilityIdentifier("\(prefixo)-\(t.id)")
            }
        }
    }
}

/// "Apagar este gasto?" (gasto simples) ou "só esta parcela / a compra toda" (parcela), pelo alerta do sistema, com os
/// textos do mockup ("Apagar" em tudo). Os dois alertas ficam sempre presos (cada um num fundo vazio, com os botões na
/// cor do texto, como o "Sair da conta?"); `gasto` diz qual aparece. Quem usa decide o que fazer com a confirmação: a
/// lista apaga na hora; a folha de edição fecha antes, para a animação aparecer.
struct PerguntaDeApagar: ViewModifier {
    @Binding var apresentada: Bool
    let obraId: String
    let gasto: Gasto?
    let confirmar: (Folhas.PedidoDeApagar) -> Void
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let estado = modelo.sincronizador.estado
        let obra = estado.obras.first { $0.id == obraId }
        let linha = gasto.map { linhaDeGasto($0, topicos: mapaDeTopicos(estado.config.topicosProprios)) }
        let parcela = gasto.flatMap { g in g.grupoId != nil ? g.parcela : nil }
        let simples = linha.map(textoDeApagarGasto)
        let compra = linha.flatMap { l in parcela.map { textoDeApagarParcela(l, parcela: $0, restantes: obra.map { o in parcelasDaCompra(gasto!, naObra: o) } ?? 1) } }
        content
            .background {
                Color.clear
                    .alert(simples?.titulo ?? "", isPresented: Binding(get: { apresentada && parcela == nil }, set: { apresentada = $0 })) {
                        Button("Cancelar", role: .cancel) {}
                        Button("Apagar", role: .destructive) { pedir(compraToda: false) }
                    } message: { Text(simples?.mensagem ?? "") }
                    .tint(paleta.cor(.texto))
            }
            .background {
                Color.clear
                    .alert(compra?.titulo ?? "", isPresented: Binding(get: { apresentada && parcela != nil }, set: { apresentada = $0 })) {
                        Button(compra?.soEsta ?? "", role: .destructive) { pedir(compraToda: false) }
                        Button(compra?.compraToda ?? "", role: .destructive) { pedir(compraToda: true) }
                        Button("Cancelar", role: .cancel) {}
                    } message: { Text(compra?.mensagem ?? "") }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: apresentada)
    }

    private func pedir(compraToda: Bool) {
        guard let gasto else { return }
        confirmar(Folhas.PedidoDeApagar(obraId: obraId, gastoId: gasto.id, grupoId: compraToda ? gasto.grupoId : nil))
    }
}
