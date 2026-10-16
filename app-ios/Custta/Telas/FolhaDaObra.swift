import SwiftUI
import CusttaNucleo

/* A folha da obra (mockup da etapa 2, parte 3; formNovaObra e formEditarObra do site). Nova: o + da lista abre com o
   cursor no nome e o teclado aberto; os campos do site, agrupados como no mockup (nome e início; a área, obrigatória;
   valor estimado e orçamento, opcionais, no teclado de valor); "Criar obra" entra direto na obra nova. Editar: o lápis da
   barra da obra; os mesmos campos menos o orçamento, a área opcional e "Apagar obra" no fim (o alerta com o nome e os
   lançamentos; depois, a lista, e a linha sai com a animação). O que vai para o documento e as mensagens vêm do núcleo. */

enum PassoDaObra: Hashable {
    case estimado
    case orcamento
}

/// O formulário enquanto a folha está aberta; só vira obra no "Criar obra" ou no "Salvar".
@MainActor @Observable
final class RascunhoDaObra {
    /// nil: obra nova.
    let obraId: String?
    var nome: String
    var dataInicio: String
    var area: String
    var estimado: Int
    var orcamento = 0
    private var inicial: [String] = []

    init(obra: Obra?, hoje: String) {
        obraId = obra?.id
        nome = obra?.nome ?? ""
        dataInicio = obra?.dataInicio ?? hoje
        area = areaParaCampo(obra?.areaM2)
        estimado = obra?.valorEstimadoVenda.map(reaisParaCentavos) ?? 0
        inicial = foto
    }

    var nova: Bool { obraId == nil }

    /// O que a pessoa respondeu, lido como o site lê (nome aparado, área pelo parseNum, dinheiro em reais).
    var campos: CamposDaObra {
        CamposDaObra(nome: aparadoJS(nome), dataInicio: dataInicio, valorEstimadoVenda: centavosParaReais(estimado),
                     areaM2: lerNumero(area), orcamento: centavosParaReais(orcamento))
    }

    /// Fechar pergunta antes quando algo mudou desde que a folha abriu.
    var temOQuePerder: Bool { foto != inicial }

    private var foto: [String] { [nome, dataInicio, area, String(estimado), String(orcamento)] }

    /// O nome tem até 120 unidades UTF-16, como o `maxlength` do site.
    func limitarNome() {
        guard nome.utf16.count > Limites.nome else { return }
        var r = ""
        for c in nome where r.utf16.count + String(c).utf16.count <= Limites.nome { r.append(c) }
        nome = r
    }
}

struct FolhaDaObra: View {
    /// nil: obra nova.
    let obraId: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDaObra?
    @State private var caminho: [PassoDaObra] = []

    var body: some View {
        Group {
            if let rascunho {
                FolhaDaObraAberta(rascunho: rascunho, caminho: $caminho)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra sumiu (apagada em outro aparelho) com a folha de edição aberta: não há o que editar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool { obraId.map { id in modelo.sincronizador.estado.obras.contains { $0.id == id } } ?? true }

    private func montar() {
        guard rascunho == nil else { return }
        let obra = obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id } }
        if obraId != nil && obra == nil { folhas.fechar(); return }
        rascunho = RascunhoDaObra(obra: obra, hoje: dataLocalISO(.now, fuso: .current))
        #if DEBUG
        // Conferência visual e laudo: a obra nova já preenchida (`-custta.folha preenchida`), como o nova-1 do mockup.
        if obra == nil, UserDefaults.standard.string(forKey: "custta.folha") == "preenchida" {
            rascunho?.nome = "Casa Granja Viana 2"
            rascunho?.dataInicio = "2026-10-01"
            rascunho?.area = "280"
            rascunho?.estimado = 160_000_000
        }
        #endif
    }
}

private struct FolhaDaObraAberta: View {
    @Bindable var rascunho: RascunhoDaObra
    @Binding var caminho: [PassoDaObra]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    private var nome: String {
        rascunho.obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id }?.nome } ?? ""
    }

    var body: some View {
        NavigationStack(path: $caminho) {
            FormularioDaObra(rascunho: rascunho, caminho: $caminho, subtitulo: rascunho.nova ? nil : nome)
                .navigationDestination(for: PassoDaObra.self) { passo in
                    switch passo {
                    case .estimado:
                        TecladoDeValor(centavos: $rascunho.estimado, acao: "Pronto", permiteZero: true) { caminho.removeLast() }
                            .passoDaFolha("Valor estimado de venda", subtitulo: rascunho.nova ? "Nova obra" : nome, fechar: nil)
                    case .orcamento:
                        TecladoDeValor(centavos: $rascunho.orcamento, acao: "Pronto", permiteZero: true) { caminho.removeLast() }
                            .passoDaFolha("Orçamento total", subtitulo: "Nova obra", fechar: nil)
                    }
                }
        }
        .folhaDoApp(perguntar: rascunho.temOQuePerder,
                    pergunta: rascunho.nova ? "Você já preencheu esta obra." : "Você mudou esta obra.",
                    descartar: rascunho.nova ? "Descartar obra" : "Descartar alterações") {
            folhas.fechar()
        }
    }
}

/// Os campos da obra e o botão fixo embaixo.
private struct FormularioDaObra: View {
    @Bindable var rascunho: RascunhoDaObra
    @Binding var caminho: [PassoDaObra]
    let subtitulo: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @FocusState private var foco: Campo?
    @State private var erroDoNome: String?
    @State private var erroDaArea: String?
    @State private var naoCarregado = false
    @State private var contaReal = false
    @State private var limite = false
    @State private var apagando = false
    /// O foco no nome vale só ao abrir: a raiz da pilha reaparece ao voltar do teclado de valor.
    @State private var abriu = false

    enum Campo: Hashable { case nome, area }

    var body: some View {
        ScrollViewReader { rolagem in
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        GrupoDaFolha {
                            CampoComRotuloEmCima(rotulo: "Nome da obra") {
                                // O exemplo é desenhado aqui, e não pelo prompt do campo, para quebrar linha na letra grande como os
                                // campos da entrada ("nada corta"): o prompt do TextField fica numa linha só e corta com reticências.
                                // O prompt continua no campo, transparente, para o VoiceOver.
                                ZStack(alignment: .topLeading) {
                                    if rascunho.nome.isEmpty {
                                        Text("Ex: Casa Alphaville")
                                            .foregroundStyle(paleta.cor(.textoTerciario))
                                            .accessibilityHidden(true)
                                            .onTapGesture { foco = .nome }
                                    }
                                    // O Return, que aqui viraria "\n", vai para a área.
                                    TextField("Nome da obra", text: $rascunho.nome,
                                              prompt: Text("Ex: Casa Alphaville").foregroundStyle(.clear), axis: .vertical)
                                        .foregroundStyle(paleta.cor(.texto))
                                        .focused($foco, equals: .nome)
                                        .submitLabel(.next)
                                        .onChange(of: rascunho.nome) { _, novo in
                                            if novo.contains("\n") {
                                                rascunho.nome = novo.replacingOccurrences(of: "\n", with: "")
                                                foco = .area
                                            }
                                            rascunho.limitarNome()
                                            erroDoNome = nil
                                        }
                                        .accessibilityIdentifier("nomeDaObra")
                                }
                            }
                            SeparadorDaFolha()
                            LinhaDaFolhaComRotulo(rotulo: "Começou em") { CampoDeData(iso: $rascunho.dataInicio) }
                        }
                        if let erroDoNome { NotaDaFolha(texto: erroDoNome, cor: .erroNoVidro, identificador: "erroDoNome") }
                    }
                    VStack(spacing: 8) {
                        GrupoDaFolha {
                            CampoComRotuloEmCima(rotulo: rascunho.nova ? "Área construída em m²" : "Área construída em m² (opcional)",
                                                 erro: erroDaArea != nil) {
                                TextField(rascunho.nova ? "Área construída em m²" : "Área construída em m², opcional", text: $rascunho.area,
                                          prompt: Text("Ex: 320").foregroundStyle(paleta.cor(.textoTerciario)))
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(paleta.cor(.texto))
                                    .focused($foco, equals: .area)
                                    .onChange(of: rascunho.area) { _, _ in erroDaArea = nil }
                                    .accessibilityIdentifier("areaDaObra")
                                    // "280 m²": a unidade logo depois do número (um texto invisível igual ao digitado mede onde
                                    // ele termina), sem tirar a largura do campo, que continua todo tocável.
                                    .overlay(alignment: .leading) {
                                        if !rascunho.area.isEmpty {
                                            HStack(spacing: 4) {
                                                Text(rascunho.area).hidden()
                                                Text("m²").foregroundStyle(paleta.cor(.secundarioTransparente))
                                            }
                                            .allowsHitTesting(false)
                                            .accessibilityHidden(true)
                                        }
                                    }
                            }
                        }
                        if let erroDaArea { NotaDaFolha(texto: erroDaArea, cor: .erroNoVidro, identificador: "erroDaArea") }
                    }
                    .id(Campo.area)
                    VStack(spacing: 8) {
                        GrupoDaFolha {
                            LinhaDeDinheiro(rotulo: "Valor estimado de venda", centavos: rascunho.estimado, identificador: "linhaEstimado") {
                                foco = nil
                                caminho.append(.estimado)
                            }
                            if rascunho.nova {
                                SeparadorDaFolha()
                                LinhaDeDinheiro(rotulo: "Orçamento total", centavos: rascunho.orcamento, identificador: "linhaOrcamento") {
                                    foco = nil
                                    caminho.append(.orcamento)
                                }
                            }
                        }
                        if rascunho.nova { NotaDaFolha(texto: "Os dois são opcionais e podem ser informados depois.") }
                    }
                    if !rascunho.nova {
                        GrupoDaFolha {
                            Button("Apagar obra") { foco = nil; apagando = true }
                                .foregroundStyle(paleta.cor(.erroNoVidro))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .accessibilityIdentifier("apagarObra")
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            // Na letra grande, o teclado que sobe com o foco na área e o botão em cima dele cobrem a nota do erro, embaixo do
            // campo: quando o teclado termina de subir, rola até ela.
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                guard foco == .area, erroDaArea != nil else { return }
                withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.25)) { rolagem.scrollTo(Campo.area, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // O identificador no próprio botão (o fundo desce até a borda, atrás do teclado; ver a folha do gasto).
            Button(rascunho.nova ? "Criar obra" : "Salvar", action: salvar)
                .buttonStyle(BotaoDaFolha())
                .accessibilityIdentifier("salvarObra")
                .padding(.horizontal, 20)
                .padding(.top, 14)
                // Com o teclado aberto, 10 acima dele (o .f-pe.sobe do mockup); sem ele, 0, na altura das outras folhas.
                .padding(.bottom, foco == nil ? 0 : 10)
                .background {
                    LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                   startPoint: .bottom, endPoint: .top)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                }
        }
        .passoDaFolha(rascunho.nova ? "Nova obra" : "Editar obra", subtitulo: subtitulo, fechar: .esquerda, raiz: true)
        // Obra nova: o cursor no nome e o teclado aberto (sugestão aprovada; o site só faz isso no computador).
        .onAppear {
            guard !abriu else { return }
            abriu = true
            if rascunho.nova && rascunho.nome.isEmpty { foco = .nome }
        }
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("A obra continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .background {
            Color.clear
                .alert(avisoLimiteDeObras(limiteDeObras)?.titulo ?? "", isPresented: $limite) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(avisoLimiteDeObras(limiteDeObras)?.texto ?? "")
                }
                .tint(paleta.cor(.texto))
        }
        .modifier(PerguntaDeApagarObra(apresentada: $apagando, obraId: rascunho.obraId) {
            guard let id = rascunho.obraId else { return }
            folhas.fechar { folhas.navegar(.apagar(id)) }
        })
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
        .pausaOFundo(enquanto: naoCarregado || limite || contaReal)
    }

    private func salvar() {
        // A folha já está descendo (o primeiro toque gravou): o segundo toque de um toque duplo não grava de novo (na obra
        // nova, criaria outra obra, com outro id).
        guard folhas.aberta != nil else { return }
        foco = nil
        let campos = rascunho.campos
        if let erro = conferirObra(campos, nova: rascunho.nova) {
            // Nome vazio volta ao nome sem mensagem, como o site; a área, com o erro do site embaixo e o rótulo em vermelho.
            if erro.campo == "area" { erroDaArea = erro.mensagem; foco = .area } else { erroDoNome = erro.mensagem; foco = .nome }
            if let m = erro.mensagem { AccessibilityNotification.Announcement(m).post() }
            return
        }
        guard let id = rascunho.obraId else { criar(campos); return }
        switch modelo.gravar({ $0.editandoObra(id, campos) }) {
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        case .contaReal: contaReal = true
        }
    }

    private func criar(_ campos: CamposDaObra) {
        // O teto pode ter enchido com a folha aberta (outro aparelho): avisa em vez de criar a 301ª.
        if avisoLimiteDeObras(modelo.sincronizador.estado.obras.count) != nil { limite = true; return }
        let id = gerarId()
        switch modelo.gravar({ $0.criandoObra(obraNova(campos, id: id, hoje: dataLocalISO(.now, fuso: .current))) }) {
        case .gravou: folhas.fechar { folhas.navegar(.entrar(id)) }
        case .naoCarregado: naoCarregado = true
        case .contaReal: contaReal = true
        case .sumiu: limite = true
        case .semConta: folhas.fechar()
        }
    }
}

/// "Apagar “Casa Alphaville”?" com os lançamentos que se perdem, pelo alerta do sistema (num fundo vazio, com os botões
/// na cor do texto, como o apagar gasto).
struct PerguntaDeApagarObra: ViewModifier {
    @Binding var apresentada: Bool
    let obraId: String?
    let confirmar: () -> Void
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let obra = obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id } }
        let texto = textoDeApagarObra(nome: obra?.nome ?? "", lancamentos: obra?.gastos.count ?? 0)
        content
            .background {
                Color.clear
                    .alert(texto.titulo, isPresented: $apresentada) {
                        Button("Cancelar", role: .cancel) {}
                        Button("Apagar obra", role: .destructive, action: confirmar)
                    } message: { Text(texto.mensagem) }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: apresentada)
    }
}
