import SwiftUI
import CusttaNucleo

/* Obras, só leitura na etapa 1: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra
   (fase, meses, orçamento e total gasto, na ordem e com os totais do site) e o comparativo entre obras.
   Antes de carregar: carregando, ou o erro de leitura explicando que nada foi alterado. */
struct ObrasView: View {
    @Environment(ModeloApp.self) private var modelo
    @State private var confirmarSaida = false
    #if DEBUG
    /// Laudo de leitura (Tarefa 11): a lista parada numa rolagem dada, em pt, para dois prints iguais.
    @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
    @State private var posicao = ScrollPosition(edge: .top)
    #endif

    var body: some View {
        let sinc = modelo.sincronizador
        let obras = obrasOrdenadas(sinc.estado.obras)
        let hoje = dataLocalISO(.now, fuso: .current)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let usuario = modelo.usuario, usuario.precisaConfirmarEmail {
                        AvisoDeEmail(email: usuario.email).padding(.bottom, 4)
                    }
                    if !sinc.dadosCarregados, case .erro(let codigo, .leitura) = sinc.estadoSinc {
                        // Nada de carregando para sempre: diz o que houve e que nada foi alterado.
                        CartaoDeEstado(titulo: "Não deu para ler suas obras", texto: textoErroDeLeitura(codigo),
                                       identificador: "obrasErroLeitura") {
                            Button("Tentar de novo") { modelo.tentarDeNovo() }
                                .buttonStyle(BotaoSecundario())
                                .accessibilityIdentifier("tentarLerDeNovo")
                        }
                    } else if !sinc.dadosCarregados {
                        CartaoDeEstado(titulo: "Carregando suas obras…", texto: nil, identificador: "obrasCarregando") {
                            ProgressView()
                        }
                    } else if obras.isEmpty {
                        CartaoDeEstado(titulo: "Nenhuma obra ainda.",
                                       texto: "Nesta versão de teste, crie as obras pelo site. Elas aparecem aqui sozinhas.",
                                       identificador: "obrasVazio") { EmptyView() }
                    } else {
                        ContagemDeObras(quantidade: obras.count)
                        ForEach(obras, id: \.id) { obra in CartaoDeObra(obra: obra, hoje: hoje) }
                        let comparativo = comparativoEntreObras(obras, taxa: sinc.estado.config.taxaMensal, hoje: hoje)
                        if !comparativo.isEmpty { PainelComparativo(linhas: comparativo).padding(.top, 2) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            #if DEBUG
            .scrollPosition($posicao)
            .task(id: obras.count) {
                guard rolagemFixa >= 0, !obras.isEmpty else { return }
                try? await Task.sleep(for: .milliseconds(300))
                posicao.scrollTo(y: rolagemFixa)
            }
            #endif
            .pausaOFundoAoRolar()
            .bordaDeRolagem(abas: true)
            .containerBackground(.clear, for: .navigation)
            .navigationTitle("Obras")
            .toolbar { BarraDoApp(confirmarSaida: $confirmarSaida) }
            .confirmaSaida($confirmarSaida)
        }
    }
}

/// "3 obras": pílula de vidro no Transparente e sólida com Reduzir transparência; texto no Fosco e com
/// Aumentar contraste (mockup aprovado).
struct ContagemDeObras: View {
    let quantidade: Int
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        let texto = Text(quantidade == 1 ? "1 obra" : "\(quantidade) obras")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(paleta.cor(.texto))
        if vidro.contagemEmPilula {
            texto.padding(.horizontal, 14).padding(.vertical, 6).superficie(.conteudo, em: .capsule)
        } else {
            texto.shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1).padding(.horizontal, 4)
        }
    }
}

/// Uma obra: ícone da fase, nome, etiqueta, meses, orçamento e total gasto. O valor de acessibilidade
/// ("Em construção · 14 meses, total gasto R$ …, 70% do orçamento") é contrato com a conferência cruzada.
/// Sem a seta ">" do mockup até a etapa 2 (decisão do Giovani em 08/10): tocar na obra ainda não abre
/// nada. A seta volta com a tela da obra, no fim da linha e, na letra grande, ao lado do nome
/// (`chevron.right` na cor secundária do vidro), e a margem da direita volta a 14 pt.
struct CartaoDeObra: View {
    let obra: Obra
    let hoje: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let total = totalBruto(obra)
        let orcamento = orcamentoObra(obra)
        let meses = fmtMeses(mesesDeObra(obra, hoje: hoje))
        let fase = "\(obra.fase.rotulo) · \(meses)"
        Group {
            if tamanho.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    nome
                    EtiquetaDeFase(fase: obra.fase)
                    tempo(meses)
                    if let orcamento { linhaDoOrcamento(orcamento) }
                    Text(moedaCurta(total)).font(.title.weight(.bold)).foregroundStyle(paleta.cor(.texto))
                }
            } else {
                HStack(alignment: .center, spacing: 11) {
                    Image(decorative: icone)
                        .resizable().frame(width: 20, height: 20)
                        .foregroundStyle(paleta.cor(.marca))
                        .frame(width: 38, height: 38)
                        .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 2) {
                        nome
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 4) { EtiquetaDeFase(fase: obra.fase); tempo(meses) }
                            VStack(alignment: .leading, spacing: 2) { EtiquetaDeFase(fase: obra.fase); tempo(meses) }
                        }
                        if let orcamento { linhaDoOrcamento(orcamento).padding(.top, 4) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(moedaCurta(total))
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(paleta.cor(.texto))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(obra.nome)
        .accessibilityValue([fase, "total gasto \(moeda(total))", orcamento.map(textoOrcamentoNaLista)].compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("obra-\(obra.id)")
    }

    private var nome: some View {
        Text(obra.nome).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
    }

    private func tempo(_ meses: String) -> some View {
        Text("· \(meses)").font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }

    private func linhaDoOrcamento(_ r: ResumoOrcamento) -> some View {
        HStack(spacing: 8) {
            BarraDeProgresso(fracao: r.geral.pct / 100, atencao: r.geral.nivel != .ok).frame(width: 56)
            Text(textoOrcamentoNaLista(r))
                .font(.footnote)
                .foregroundStyle(paleta.cor(r.geral.nivel == .passou ? .alerta : vidro.secundario))
        }
    }

    private var icone: String {
        switch obra.fase {
        case .construcao: return "Icones/guindaste"
        case .pronta: return "Icones/casa"
        case .vendida: return "Icones/check"
        }
    }
}

/// "Comparativo entre obras": gasto e corrigido pela taxa, em barras do maior corrigido.
struct PainelComparativo: View {
    let linhas: [LinhaComparativo]
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comparativo entre obras")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityAddTraits(.isHeader)
            ForEach(linhas) { linha in
                VStack(alignment: .leading, spacing: 6) {
                    Text(linha.nome).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(paleta.cor(.texto).opacity(0.10))
                            Capsule().fill(paleta.cor(.marca).opacity(0.34)).frame(width: geo.size.width * linha.fracaoCorrigido)
                            Capsule().fill(paleta.cor(.marca)).frame(width: geo.size.width * linha.fracaoBruto)
                        }
                    }
                    .frame(height: 14)
                    Text("\(moedaCurta(linha.bruto)) gasto · \(moedaCurta(linha.corrigido)) corrigido")
                        .font(.footnote)
                        .foregroundStyle(paleta.cor(vidro.secundario))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(linha.nome)
                .accessibilityValue("\(moedaCurta(linha.bruto)) gasto, \(moedaCurta(linha.corrigido)) corrigido")
            }
            HStack(spacing: 18) {
                Label { Text("Gasto") } icon: { RoundedRectangle(cornerRadius: 3).fill(paleta.cor(.marca)).frame(width: 10, height: 10) }
                Label { Text("Corrigido") } icon: { RoundedRectangle(cornerRadius: 3).fill(paleta.cor(.marca).opacity(0.34)).frame(width: 10, height: 10) }
            }
            .font(.footnote)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("comparativo")
    }
}

/// Aviso de e-mail não confirmado: o uso não é bloqueado.
struct AvisoDeEmail: View {
    let email: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var mensagem: (texto: String, tipo: Mensagem.Tipo)?
    @State private var ocupado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Confirme seu e-mail").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            Text("Enviamos um link para \(email). Abra o e-mail e toque no link para proteger sua conta.")
                .font(.footnote)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .padding(.top, 6)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { reenviar; jaConfirmei }
                VStack(spacing: 10) { reenviar; jaConfirmei }
            }
            .padding(.top, 12)
            if let mensagem {
                Mensagem(tipo: mensagem.tipo, texto: mensagem.texto, identificador: "mensagemAvisoEmail").padding(.top, 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("avisoEmail")
    }

    private var reenviar: some View {
        Button("Reenviar link") {
            Task {
                ocupado = true
                let texto = await modelo.reenviarVerificacao()
                mensagem = (texto, texto == ModeloApp.linkReenviado || texto == ModeloApp.emailJaConfirmado ? .ok : .atencao)
                ocupado = false
            }
        }
        .buttonStyle(BotaoSecundario(pequeno: true))
        .disabled(ocupado)
        .accessibilityIdentifier("reenviarLink")
    }

    private var jaConfirmei: some View {
        Button("Já confirmei") {
            Task {
                ocupado = true
                mensagem = await modelo.conferirVerificacao().map { ($0, .atencao) }
                ocupado = false
            }
        }
        .buttonStyle(BotaoPrincipal(pequeno: true))
        .disabled(ocupado)
        .accessibilityIdentifier("jaConfirmei")
    }
}

/// Cartão de estado da lista (vazia, carregando, erro de leitura): ícone, título, texto e ação.
struct CartaoDeEstado<Acao: View>: View {
    let titulo: String
    let texto: String?
    let identificador: String
    @ViewBuilder let acao: () -> Acao
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        VStack(spacing: 8) {
            Image(decorative: "Icones/guindaste")
                .resizable().frame(width: 36, height: 36)
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityHidden(true)
            Text(titulo)
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityIdentifier(identificador)
            if let texto {
                Text(texto).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
            }
            acao().padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
    }
}
