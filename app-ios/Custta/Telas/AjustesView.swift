import SwiftUI

/* Ajustes: o tema e o vidro (Ajustes › Aparência, adiantada da etapa 5 para o Giovani comparar as duas doses pelo
   TestFlight), a conta (nome, e-mail, confirmação pendente e sair) e a versão. Notificações, exportar, trocar senha e
   apagar conta chegam na etapa 5; a cor saiu com a pele azul (21/10). */
struct AjustesView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var confirmarSaida = false
    @State private var mensagemVerificacao: String?
    @State private var enviando = false
    /// O ícone do "Sair da conta" cresce com a letra do botão.
    @ScaledMetric(relativeTo: .body) private var iconeDoSair: CGFloat = 18

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PainelDeAparencia()
                    // Painel do mockup, como o "Comparativo entre obras": título de 20 pt e 18 pt de margem em cima.
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Conta")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(paleta.cor(.texto))
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, 14)
                        if let nome = modelo.nome {
                            Text(nome)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(paleta.cor(.texto))
                                .padding(.bottom, 2)
                                .accessibilityIdentifier("nomeConta")
                        }
                        Text(modelo.usuario?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .padding(.bottom, 14)
                            .accessibilityLabel("E-mail")
                            .accessibilityValue(modelo.usuario?.email ?? "")
                            .accessibilityIdentifier("emailConta")
                        if modelo.usuario?.precisaConfirmarEmail == true {
                            Text("Confirme seu e-mail para manter acesso à conta. Você pode continuar usando o app.")
                                .font(.footnote)
                                .foregroundStyle(paleta.cor(vidro.secundario))
                                .padding(.bottom, 10)
                            Button("Enviar confirmação de e-mail") {
                                Task {
                                    enviando = true
                                    mensagemVerificacao = await modelo.enviarConfirmacao()
                                    enviando = false
                                }
                            }
                            .buttonStyle(BotaoSecundario(pequeno: true))
                            .disabled(enviando)                 // como o b.disabled do site: um envio por vez
                            if let mensagemVerificacao {
                                // ✓ só quando foi (ou já estava confirmado); erro e falta de rede em âmbar, como no aviso.
                                let ok = mensagemVerificacao == ModeloApp.confirmacaoEnviada || mensagemVerificacao == ModeloApp.emailJaConfirmado
                                Mensagem(tipo: ok ? .ok : .atencao, texto: mensagemVerificacao).padding(.top, 10)
                            }
                            Spacer().frame(height: 10)
                        }
                        Button { confirmarSaida = true } label: {
                            Label { Text("Sair da conta") } icon: { Image(decorative: "Icones/sair").resizable().frame(width: iconeDoSair, height: iconeDoSair) }
                        }
                        .buttonStyle(BotaoSecundario())
                        .accessibilityIdentifier("sair")
                    }
                    .padding(EdgeInsets(top: 18, leading: 16, bottom: 16, trailing: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .superficie(.conteudo, em: .rect(cornerRadius: 24))
                    Text(Self.versao)
                        .font(.footnote)
                        .foregroundStyle(paleta.cor(.texto))
                        .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
                        // Texto solto sobre a aurora: o halo leve do título grande, só no escuro.
                        .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naBarra) }
                        // O halo sobe além do texto: atrás do painel, como o do título fica atrás de todo o conteúdo
                        // (por cima, escurecia a base do painel do "Sair da conta").
                        .zIndex(-1)
                        .accessibilityIdentifier("versao")
                }
                .padding(.horizontal, 16)
                // O painel começa 18 pt abaixo de onde começa a lista de Obras, como no mockup.
                .padding(.top, 18)
                .padding(.bottom, 24)
                .haloDoTituloDaBarra()
            }
            .scrollIndicators(.hidden)
            #if DEBUG
            // O laudo de leitura mede a Conta e a versão na maior letra, abaixo da Aparência.
            .modifier(RolagemFixaDoTeste())
            #endif
            .pausaOFundoAoRolar()
            .bordaDeRolagem(abas: true)
            .containerBackground(.clear, for: .navigation)
            .navigationTitle("Ajustes")
            .toolbar { BarraDoApp(confirmarSaida: $confirmarSaida) }
            .confirmaSaida($confirmarSaida)
        }
    }

    /// "Versão 2.0 (1)": a versão e o build do pacote.
    static var versao: String {
        let info = Bundle.main.infoDictionary
        return "Versão \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }
}

/// Ajustes › Aparência, o tema e o vidro (mockup aprovado, etapa 1, "Aparência · Transparente (padrão)" e "Aparência ·
/// Fosco escolhido"; sem a cor, que saiu com a pele azul). O tema é o segmentado das folhas. O vidro: dois cartões lado a lado, cada um com a miniatura da dose e o nome com o círculo; o escolhido leva o
/// anel e o círculo marcado. As duas escolhas valem só neste aparelho (`Aparencia.chaveTema` e `chaveVidro`, lidas pela RaizView). Com
/// "Reduzir transparência" no iPhone, as opções ficam esmaecidas e desligadas e o aviso diz por quê; com "Aumentar
/// contraste", o aviso diz que o Fosco com contorno vale por cima da escolha.
struct PainelDeAparencia: View {
    @AppStorage(Aparencia.chaveVidro) private var escolha = "transparente"
    @AppStorage(Aparencia.chaveTema) private var tema = "escuro"
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.vidro) private var vidro
    @Environment(\.opcoes) private var opcoes
    /// O círculo do nome (20 pt no mockup) e o ícone do aviso (18 pt) crescem com a letra, em ponto inteiro (um irmão
    /// fracionário ao lado do texto passa 1 pixel da largura).
    @ScaledMetric(relativeTo: .subheadline) private var circulo: CGFloat = 20
    @ScaledMetric(relativeTo: .footnote) private var iconeDoAviso: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Aparência")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 14)
            linhaDoTema
            Text("Vidro")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .padding(.top, 14)
                .padding(.bottom, 8)
            // O círculo ao lado do nome; na maior letra, quando um dos nomes não cabe ao lado dele, em cima, nas duas opções
            // (o "Transparente" não se parte no meio da palavra).
            ViewThatFits(in: .horizontal) {
                opcoesDoVidro(marcaAoLado: true)
                opcoesDoVidro(marcaAoLado: false)
            }
            .disabled(opcoes.reduzirTransparencia)
            nota.padding(.top, 12)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .sensoryFeedback(.selection, trigger: escolha)
    }

    /// "Tema" à esquerda e o segmentado "Escuro | Claro" à direita, numa linha de 48 pt (o `.ap-linha` do mockup); na letra
    /// grande, o segmentado embaixo do rótulo, na largura toda, com as opções uma em cima da outra.
    @ViewBuilder private var linhaDoTema: some View {
        let rotulo = Text("Tema").font(.body).foregroundStyle(paleta.cor(.texto))
        let segmentado = SegmentadoDaFolha(opcoes: [("escuro", "Escuro", nil), ("claro", "Claro", nil)],
                                           escolhida: Binding(get: { tema == "claro" ? "claro" : "escuro" }, set: { tema = $0 }),
                                           identificador: "tema", larguraToda: tamanho.isAccessibilitySize)
        if tamanho.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                rotulo
                segmentado
            }
        } else {
            HStack(spacing: 12) {
                rotulo
                Spacer(minLength: 0)
                segmentado
            }
            .frame(minHeight: 48)
        }
    }

    private func opcoesDoVidro(marcaAoLado: Bool) -> some View {
        ColunasOuPilha(espaco: 12) {
            ForEach(Array(EscolhaDeVidro.allCases.enumerated()), id: \.element) { i, opcao in
                botao(opcao, posicao: i, marcaAoLado: marcaAoLado)
            }
        }
    }

    private func botao(_ opcao: EscolhaDeVidro, posicao: Int, marcaAoLado: Bool) -> some View {
        let ativa = Aparencia.vidro(escolha) == opcao
        // Com "Reduzir transparência", desligadas: a miniatura e o círculo esmaecem como no mockup (45%), e o nome vai para o
        // secundário, que fecha 4,5:1 (esmaecido a 45%, ficava abaixo disso na superfície sólida).
        let desligada = opcoes.reduzirTransparencia
        let nome = opcao == .transparente ? "Transparente" : "Fosco"
        return Button { escolha = opcao.rawValue } label: {
            VStack(spacing: 8) {
                MiniaturaDoVidro(escolha: opcao)
                    .overlay {
                        if ativa {
                            // O anel do mockup (0 0 0 2px fundo, 0 0 0 4,5px marca): 2 pt do fundo e 2,5 pt da marca, por fora.
                            RoundedRectangle(cornerRadius: 18).strokeBorder(paleta.cor(.fundo), lineWidth: 2).padding(-2)
                            RoundedRectangle(cornerRadius: 20.5).strokeBorder(paleta.cor(.linkNoVidro), lineWidth: 2.5).padding(-4.5)
                        }
                    }
                    .opacity(desligada ? 0.45 : 1)
                if marcaAoLado {
                    HStack(spacing: 6) { marca(ativa).opacity(desligada ? 0.45 : 1); rotulo(nome, desligada) }
                } else {
                    VStack(spacing: 6) { marca(ativa).opacity(desligada ? 0.45 : 1); rotulo(nome, desligada) }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(EstiloDaOpcao())
        .accessibilityLabel(nome)
        .accessibilityValue("\(posicao + 1) de \(EscolhaDeVidro.allCases.count)")
        .accessibilityAddTraits(ativa ? [.isSelected] : [])
        .accessibilityIdentifier("vidro-\(opcao.rawValue)")
    }

    private func marca(_ ativa: Bool) -> some View {
        Image(systemName: ativa ? "checkmark.circle.fill" : "circle")
            .font(.system(size: circulo.rounded()))
            .foregroundStyle(paleta.cor(ativa ? .linkNoVidro : vidro.secundario))
    }

    private func rotulo(_ nome: String, _ desligada: Bool) -> some View {
        Text(nome)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(paleta.cor(desligada ? vidro.secundario : .texto))
            .multilineTextAlignment(.center)
    }

    @ViewBuilder private var nota: some View {
        if opcoes.reduzirTransparencia {
            aviso("lock.fill", "O iPhone está com \u{201C}Reduzir transparência\u{201D} ligado. Enquanto isso, o Custta usa cartões sólidos.")
        } else if opcoes.aumentarContraste {
            aviso("checkmark.circle.fill", "Com \u{201C}Aumentar contraste\u{201D} ligado no iPhone, o Custta usa o vidro fosco com contorno.")
        } else {
            Text("Transparente mostra mais a aurora atrás dos cartões. Fosco deixa os cartões mais firmes. Vale só neste aparelho.")
                .font(.footnote)
                .foregroundStyle(paleta.cor(vidro.secundario))
        }
    }

    private func aviso(_ icone: String, _ texto: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icone)
                .font(.system(size: iconeDoAviso.rounded()))
                .foregroundStyle(paleta.cor(.linkNoVidro))
                .accessibilityHidden(true)
            Text(texto).foregroundStyle(paleta.cor(.texto))
        }
        .font(.footnote)
        .accessibilityIdentifier("avisoDoVidro")
    }
}

/// O toque numa opção do vidro: encolhe um pouco, como os botões do app. Sem o esmaecido do `.plain` quando desligada (com
/// "Reduzir transparência"), que levava o nome abaixo de 4,5:1: quem esmaece é a miniatura e o círculo.
private struct EstiloDaOpcao: ButtonStyle {
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// A miniatura de uma dose: a aurora do mockup (dois brilhos e a base) com duas barrinhas de vidro, desenhadas sólidas
/// na tinta e no aro daquela dose (nunca vidro dentro de vidro: o painel já é vidro). Decorativa: o nome diz a opção.
struct MiniaturaDoVidro: View {
    let escolha: EscolhaDeVidro
    @Environment(\.paleta) private var paleta

    var body: some View {
        let transparente = escolha == .transparente
        ZStack(alignment: .top) {
            // linear-gradient(160deg, aurora-3 90%, fundo 85%) embaixo e os dois radial-gradient por cima.
            LinearGradient(stops: [.init(color: paleta.cor(.aurora3).opacity(0.9), location: 0),
                                   .init(color: paleta.cor(.fundo), location: 0.85)],
                           startPoint: UnitPoint(x: 0.33, y: 0.03), endPoint: UnitPoint(x: 0.67, y: 0.97))
            EllipticalGradient(colors: [paleta.cor(.aurora2).opacity(0.95), paleta.cor(.aurora2).opacity(0)],
                               center: UnitPoint(x: 0.85, y: 0.1), endRadiusFraction: 0.9)
            EllipticalGradient(colors: [paleta.cor(.aurora1).opacity(0.95), paleta.cor(.aurora1).opacity(0)],
                               center: UnitPoint(x: 0.2, y: 0.2), endRadiusFraction: 1.05)
            VStack(spacing: 8) {
                barra(transparente)
                barra(transparente)
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityHidden(true)
    }

    private func barra(_ transparente: Bool) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(paleta.cor(.tintaConteudo).opacity(transparente ? 0.10 : 0.62))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(paleta.cor(.aroDaMiniatura).opacity(transparente ? 0.7 : 0.3), lineWidth: transparente ? 1.2 : 1)
            }
            .overlay(alignment: .topLeading) {
                // O "texto" da barrinha: 46% da largura, 8 pt de altura, a 10 pt da borda e 9 pt do alto.
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(paleta.cor(.texto).opacity(0.9))
                        .frame(width: geo.size.width * 0.46, height: 8)
                        .offset(x: 10, y: 9)
                }
            }
            .frame(height: 26)
    }
}

/// Duas colunas iguais quando o maior filho cabe na metade (o mockup: os dois cartões do vidro lado a lado); senão, um
/// embaixo do outro, na largura toda (a partir do xxxLarge num iPhone de 402 pt). Decide pela largura ideal de cada
/// filho, a do nome numa linha só: assim nenhum nome quebra no meio da palavra. A largura ideal é a do maior filho (a
/// pilha), para o ViewThatFits de fora saber se o nome cabe ao lado do círculo.
struct ColunasOuPilha: Layout {
    var espaco: CGFloat

    private func colunas(_ largura: CGFloat, _ filhos: Subviews) -> CGFloat? {
        guard filhos.count > 1 else { return largura }
        let coluna = (largura - espaco * CGFloat(filhos.count - 1)) / CGFloat(filhos.count)
        let maior = filhos.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return maior <= coluna ? coluna : nil
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let largura = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        if let coluna = colunas(largura, subviews) {
            let altura = subviews.map { $0.sizeThatFits(ProposedViewSize(width: coluna, height: nil)).height }.max() ?? 0
            return CGSize(width: largura, height: altura)
        }
        let alturas = subviews.map { $0.sizeThatFits(ProposedViewSize(width: largura, height: nil)).height }
        return CGSize(width: largura, height: alturas.reduce(0, +) + espaco * CGFloat(max(0, subviews.count - 1)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        if let coluna = colunas(bounds.width, subviews) {
            for (i, filho) in subviews.enumerated() {
                filho.place(at: CGPoint(x: bounds.minX + CGFloat(i) * (coluna + espaco), y: bounds.minY),
                            proposal: ProposedViewSize(width: coluna, height: nil))
            }
            return
        }
        var y = bounds.minY
        for filho in subviews {
            let proposta = ProposedViewSize(width: bounds.width, height: nil)
            filho.place(at: CGPoint(x: bounds.minX, y: y), proposal: proposta)
            y += filho.sizeThatFits(proposta).height + espaco
        }
    }
}
