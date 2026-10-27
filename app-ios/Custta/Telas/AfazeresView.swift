import SwiftUI
import CusttaNucleo

/* Os afazeres da obra (mockup aprovado da etapa 3, parte 2, seção 4, opção A): uma linha na tela da obra, entre as ações e
   os lançamentos, que empurra a tela "Afazeres". Na tela, o campo "Novo afazer" no alto (até 500 caracteres; o novo entra no
   alto dos pendentes, aceso um instante, e o cursor fica no campo para anotar vários seguidos); os pendentes com o texto
   inteiro, quebrando linha; o círculo de 44 pt que marca (o toque no texto também, como no site); "Feitos · N" fechado. Marcar
   leva o afazer ao alto dos Feitos e desmarcar, ao alto dos pendentes: a ordem do array, que o site mostra igual. O feito fica
   riscado, na cor secundária (a opacidade 0,5 do site não passa de 4,5:1). Arrastar mostra "Apagar", que apaga sem pergunta
   (o × fixo do site sai). Grava pelo `modelo.gravar`, com o alerta do site antes de ver os dados. */

/// A linha dos afazeres na tela da obra, num grupo de vidro: com pendentes, "N pendentes" e o primeiro deles; tudo feito,
/// "tudo feito" e quantos; sem nenhum, a frase do site. O VoiceOver lê o texto inteiro do primeiro pendente.
struct LinhaDosAfazeresView: View {
    let linha: LinhaDosAfazeres
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        HStack(spacing: 11) {
            if !grande {
                Image(decorative: "Icones/check")
                    .resizable().frame(width: 20, height: 20)
                    .foregroundStyle(paleta.cor(.marca))
                    .frame(width: 38, height: 38)
                    .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            VStack(alignment: .leading, spacing: 3) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) { titulo; Spacer(minLength: 10); etiqueta }
                    VStack(alignment: .leading, spacing: 4) { titulo; etiqueta }
                }
                PrimeiroPendente(texto: textoDeBaixo, cortado: pendente)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(vidro.secundario))
                // A seta das linhas do Orçamento e do A pagar: para no AX2 e ocupa 18 pt na maior letra (sem o teto, ~27 × 46 pt
                // na AX5, mais larga que o quadro).
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .frame(width: grande ? 18 : 14)
                .accessibilityHidden(true)
                .foraDoLaudo()
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Afazeres")
        .accessibilityValue(falado)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("linhaDosAfazeres")
    }

    private var titulo: some View {
        Text("Afazeres").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var etiqueta: some View {
        switch linha {
        case .pendentes(let e, _): EtiquetaDoIndicador(texto: e, cor: .marca)
        case .tudoFeito(let e, _): EtiquetaDoIndicador(texto: e, cor: .positivo)
        case .vazia: EmptyView()
        }
    }

    private var pendente: Bool { if case .pendentes = linha { return true } else { return false } }

    private var textoDeBaixo: String {
        switch linha {
        case .pendentes(_, let primeiro): return primeiro
        case .tudoFeito(_, let feitos): return feitos
        case .vazia(let frase): return frase
        }
    }

    private var falado: String {
        switch linha {
        case .pendentes(let e, let primeiro): return "\(e), \(primeiro)"
        case .tudoFeito(let e, let feitos): return "\(e), \(feitos)"
        case .vazia(let frase): return frase
        }
    }
}

/// O texto de baixo da linha dos afazeres. O primeiro pendente para em duas linhas (quatro na maior letra), como no mockup:
/// o texto inteiro está na tela Afazeres, e o VoiceOver o lê inteiro pela linha.
struct PrimeiroPendente: View {
    let texto: String
    let cortado: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        Text(texto)
            .font(.subheadline)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .lineLimit(cortado ? (tamanho.isAccessibilitySize ? 4 : 2) : nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// O texto de um afazer até 500 unidades UTF-16, como o `maxlength` do site: corta no primeiro caractere que não cabe
/// (nada depois dele entra, e um emoji não parte ao meio).
func limitadoAoAfazer(_ texto: String) -> String {
    guard texto.utf16.count > Limites.afazer else { return texto }
    var r = ""
    for c in texto {
        guard r.utf16.count + c.utf16.count <= Limites.afazer else { break }
        r.append(c)
    }
    return r
}

/// O que o campo do afazer guarda do texto que o teclado deixou nele: sem o "\n" do "OK" do teclado, que adiciona, e até 500
/// unidades UTF-16.
func textoDoCampoDoAfazer(_ novo: String) -> (texto: String, adiciona: Bool) {
    let adiciona = novo.contains("\n")
    return (limitadoAoAfazer(adiciona ? novo.replacingOccurrences(of: "\n", with: "") : novo), adiciona)
}

/// O estado de um afazer à vista: o círculo troca na hora do toque, e o afazer muda de lugar meio segundo depois.
func feitoAVista(_ afazer: Afazer, trocando: Set<String>) -> Bool { afazer.feito != trocando.contains(afazer.id) }

/// Os afazeres tocados há menos de meio segundo: o círculo já mostra o estado novo e a linha ainda não mudou de lugar.
struct TrocasPendentes {
    private(set) var ids: Set<String> = []

    /// O toque no afazer: o primeiro pede a troca (true: grave daqui a meio segundo); o segundo, no meio do caminho, desiste
    /// (dois toques seguidos marcam e desmarcam, como no site, e nada é gravado).
    mutating func tocar(_ id: String) -> Bool {
        if ids.remove(id) != nil { return false }
        ids.insert(id)
        return true
    }

    /// Meio segundo depois do toque: grava se a troca continua pedida.
    mutating func confirmar(_ id: String) -> Bool { ids.remove(id) != nil }
}

struct AfazeresView: View {
    let obraId: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.opcoes) private var opcoes
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    /// O texto em digitação e o foco moram aqui, e não no modelo: o redesenho que chega do Sincronizador (uma mudança vinda
    /// de outro aparelho) não os recria (achado 3).
    @State private var texto = ""
    @FocusState private var noCampo: Bool
    @State private var feitosAbertos = false
    /// A linha arrastada que mostra "Apagar" (uma por vez).
    @State private var linhaAberta: String?
    /// Os tocados há menos de meio segundo: o círculo já mostra o estado novo, e a linha ainda não mudou de lugar.
    @State private var trocando = TrocasPendentes()
    /// O afazer que acabou de entrar, aceso por 2 s.
    @State private var aceso: String?
    @State private var naoCarregado = false
    #if DEBUG
    /// Testes de tela: a espera entre o toque e a mudança de lugar, em ms (`-custta.esperaDoAfazer 3000`), para o teste ver o
    /// círculo trocado (e o VoiceOver ouvir o estado novo) antes de a linha sair, e tocar de novo nesse meio-tempo.
    @AppStorage("custta.esperaDoAfazer") private var esperaDeTeste = 500
    #endif

    /// Meio segundo entre o círculo trocar e a linha mudar de lugar (mockup: "o círculo enche na hora; meio segundo depois…").
    private var espera: Duration {
        #if DEBUG
        return .milliseconds(esperaDeTeste)
        #else
        return .milliseconds(500)
        #endif
    }

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == obraId }) {
            conteudo(obra)
        } else if !modelo.sincronizador.dadosCarregados {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear                                  // a obra sumiu (apagada em outro aparelho): volta para Obras
                .onAppear { caminho.removeAll { $0.obraId == obraId } }
        }
    }

    private func conteudo(_ obra: Obra) -> some View {
        let pendentes = obra.afazeres.filter { !$0.feito }
        let feitos = obra.afazeres.filter(\.feito)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                CampoDoAfazer(texto: $texto, foco: $noCampo) { adicionar() }
                    .padding(.top, 16)
                if !pendentes.isEmpty {
                    PilulaDaLista(titulo: "Pendentes", quantidade: pendentes.count, identificador: "pendentes")
                        .padding(.top, 24)
                        .padding(.bottom, 10)
                    CartaoDaLista {
                        ForEach(Array(pendentes.enumerated()), id: \.element.id) { i, afazer in
                            if i > 0 { separador }
                            linha(afazer)
                        }
                    }
                } else if feitos.isEmpty {
                    CartaoDeEstado(titulo: "Nenhum afazer.", texto: "Anote o que falta na obra.", icone: "Icones/check",
                                   identificador: "afazeresVazio") { EmptyView() }
                        .padding(.top, 16)
                }
                if !feitos.isEmpty {
                    CartaoDaLista {
                        CabecalhoDosFeitos(quantidade: feitos.count, aberto: feitosAbertos, alternar: alternarFeitos)
                        if feitosAbertos {
                            ForEach(feitos, id: \.id) { afazer in
                                separador
                                linha(afazer)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
            // O fim da lista fica à vista acima da cápsula de abas, como na tela da obra.
            .padding(.bottom, 98)
            .haloDoTituloDaBarra()
            // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
            .contentShape(.rect)
            .onTapGesture { if linhaAberta != nil { fecharLinha() } }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
        .onDisappear { linhaAberta = nil }
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Afazeres")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                .sharedBackgroundVisibility(.hidden)
        }
    }

    /// A linha fina entre dois afazeres, alinhada ao texto (na maior letra, ao recuo da linha).
    private var separador: some View { LinhaFina().padding(.leading, tamanho.isAccessibilitySize ? 18 : 62) }

    private func linha(_ afazer: Afazer) -> some View {
        let feito = feitoAVista(afazer, trocando: trocando.ids)
        return LinhaArrastavel(id: afazer.id, aberta: $linhaAberta, apagar: { apagar(afazer) }) {
            LinhaDoAfazer(afazer: afazer, feito: feito, riscado: afazer.feito && !trocando.ids.contains(afazer.id),
                          aceso: aceso == afazer.id) { alternar(afazer) }
        }
        .id(afazer.id)
        .transition(opcoes.reduzirMovimento ? .opacity
                    : .asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
    }

    private func fecharLinha() {
        guard linhaAberta != nil else { return }
        if opcoes.reduzirMovimento { linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { linhaAberta = nil } }
    }

    private func alternarFeitos() {
        if linhaAberta != nil { fecharLinha(); return }
        if opcoes.reduzirMovimento { feitosAbertos.toggle() } else { withAnimation(.snappy) { feitosAbertos.toggle() } }
    }

    /// O + ou o "OK" do teclado: o texto aparado entra no alto dos pendentes, o campo limpa e o cursor fica nele. Vazio não
    /// faz nada (site). O campo guarda no máximo 500, então o longo não deveria chegar aqui; se chegar, vai ao aviso do topo
    /// (o toast do site), e o + nunca fica calado.
    private func adicionar() {
        noCampo = true
        let t: String
        switch conferirAfazer(texto) {
        case .ok(let aparado): t = aparado
        case .vazio: return
        case .longo(let mensagem): modelo.avisar(mensagem); return
        }
        let id = gerarId()
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
            modelo.gravar { $0.adicionandoAfazer(t, id: id, naObra: obraId) }
        }
        if resultado == .naoCarregado { naoCarregado = true; return }
        guard resultado == .gravou else { return }
        texto = ""
        aceso = id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard aceso == id else { return }
            withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.4)) { aceso = nil }
        }
    }

    /// Marcar ou desmarcar, pelo círculo ou pelo texto: o círculo troca na hora; meio segundo depois o afazer vai para o alto
    /// dos Feitos (ou dos pendentes), com a mola (sem ela, com Reduzir movimento). Tocar de novo nesse meio segundo desiste.
    private func alternar(_ afazer: Afazer) {
        if linhaAberta != nil { fecharLinha(); return }
        guard trocando.tocar(afazer.id) else { return }
        Task { @MainActor in
            try? await Task.sleep(for: espera)
            let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.4, bounce: 0)) { () -> ModeloApp.ResultadoDaGravacao? in
                guard trocando.confirmar(afazer.id) else { return nil }
                return modelo.gravar { $0.alternandoAfazer(afazer.id, naObra: obraId) }
            }
            if resultado == .naoCarregado { naoCarregado = true }
        }
    }

    /// "Apagar" da linha arrastada: apaga na hora, sem pergunta (são dois gestos de propósito).
    private func apagar(_ afazer: Afazer) {
        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
            linhaAberta = nil
            return modelo.gravar { $0.apagandoAfazer(afazer.id, daObra: obraId) }
        }
        if resultado == .naoCarregado { naoCarregado = true }
    }
}

/// O campo do afazer novo, num grupo de vidro de 56 pt: o texto, que quebra linha e para em 500 caracteres, e o + de 44 pt
/// (cinza sem texto, na marca com texto). O "OK" do teclado também adiciona, e o teclado fica. O exemplo é desenhado num
/// Text, que quebra na maior letra, e o prompt fica no campo, transparente, com o rótulo "Novo afazer" para o VoiceOver.
struct CampoDoAfazer: View {
    @Binding var texto: String
    var foco: FocusState<Bool>.Binding
    let adicionar: () -> Void
    /// O texto cru que a tela tem quando o guardado é outro (sem o "\n" do "OK", ou cortado em 500), por uma volta. A troca
    /// redesenha o campo, e o redesenho já leva o guardado à tela; na volta seguinte, o campo passa do cru ao guardado, uma
    /// segunda garantia.
    @State private var naTela: String?
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let comTexto = !aparadoJS(texto).isEmpty
        HStack(spacing: 10) {
            // Pelo alto, como o nome da obra (FolhaDaObra): o TextField que quebra linha não dá a linha de base, e por ela o
            // exemplo subia ~10 pt e o cursor ficava embaixo dele.
            ZStack(alignment: .topLeading) {
                if texto.isEmpty {
                    Text("Ex: pagar pedreiro, buscar tinta")
                        .foregroundStyle(paleta.cor(vidro.secundario))
                        .accessibilityHidden(true)
                        .onTapGesture { foco.wrappedValue = true }
                }
                // O "OK" do teclado chega como "\n" no campo que quebra linha: sai do texto e adiciona, com o teclado aberto.
                // O "\n" e o corte em 500 vão pelo set, que vê toda tecla (um onChange do texto perde tecla numa rajada), e o
                // texto guardado nunca passa de 500. Numa rajada, tecla que chega enquanto o SwiftUI empurra o texto não
                // passa pelo set: a tela mostra mais por um instante, e a tecla seguinte corrige.
                TextField("Novo afazer",
                          text: Binding(get: { naTela ?? texto },
                                        set: { novo in
                                            let (guardado, adiciona) = textoDoCampoDoAfazer(novo)
                                            naTela = guardado == novo ? nil : novo
                                            texto = guardado
                                            // Na volta seguinte: dentro do set, a gravação redesenha a tela no meio da
                                            // tecla, e o campo manda o mesmo texto de novo (o "OK" adicionava duas vezes).
                                            if adiciona { Task { @MainActor in adicionar() } }
                                        }),
                          prompt: Text("Ex: pagar pedreiro, buscar tinta").foregroundStyle(.clear),
                          axis: .vertical)
                    .foregroundStyle(paleta.cor(.texto))
                    .submitLabel(.done)
                    .focused(foco)
                    // Com prompt, o título do TextField não vira o rótulo do VoiceOver (o CampoDeEntrada também o põe).
                    .accessibilityLabel("Novo afazer")
                    .accessibilityIdentifier("novoAfazer")
                    .onChange(of: naTela) { _, novo in if novo != nil { naTela = nil } }
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Sem o naTela, que um onChange perdido numa rajada deixaria na tela depois do +.
            Button(action: { naTela = nil; adicionar() }) {
                Image(systemName: "plus")
                    .font(.system(size: grande ? 30 : 20, weight: .medium))
                    .foregroundStyle(paleta.cor(comTexto ? .sobreMarca : vidro.secundario))
                    .frame(width: grande ? 64 : 44, height: grande ? 64 : 44)
                    .background(comTexto ? paleta.cor(.marca) : paleta.cor(.texto).opacity(0.12), in: .circle)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Adicionar afazer")
            .accessibilityIdentifier("adicionarAfazer")
        }
        .padding(EdgeInsets(top: grande ? 12 : 6, leading: 18, bottom: grande ? 12 : 6, trailing: grande ? 12 : 6))
        .frame(minHeight: 56)
        .superficie(.conteudo, em: .rect(cornerRadius: 24, style: .continuous))
    }
}

/// O cabeçalho do grupo dos feitos, fechado no começo, como o "A vencer" da obra: "Feitos", quantos e o chevron.
struct CabecalhoDosFeitos: View {
    let quantidade: Int
    let aberto: Bool
    let alternar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        HStack(spacing: 8) {
            Text("Feitos").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(quantidade)").font(.body.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
            Image(systemName: aberto ? "chevron.down" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(vidro.secundario))
                // A seta das linhas que abrem: para no AX2 e ocupa 18 pt na maior letra (sem o teto, 27 × 46 pt na AX5, mais
                // larga que o quadro, contra 20 × 30 no mockup).
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .frame(width: tamanho.isAccessibilitySize ? 18 : 14)
                .accessibilityHidden(true)
                .foraDoLaudo()
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 14))
        .frame(minHeight: 44)
        .contentShape(.rect)
        .onTapGesture(perform: alternar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Feitos, \(quantidade)")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(aberto ? "aberto" : "fechado")
        .accessibilityHint(aberto ? "Fecha os afazeres feitos" : "Mostra os afazeres feitos")
        .accessibilityAction { alternar() }
        .accessibilityIdentifier("feitos")
    }
}

/// Um afazer: o círculo que marca (alvo de 44 pt; 56 na maior letra) e o texto inteiro, quebrando linha. Feito, o círculo
/// fica cheio no verde, com a marca, e o texto riscado na cor secundária. Para o VoiceOver, um botão de alternar com o
/// texto como rótulo; a linha toda marca, como no site.
struct LinhaDoAfazer: View {
    let afazer: Afazer
    let feito: Bool
    let riscado: Bool
    let aceso: Bool
    let tocar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        HStack(alignment: .top, spacing: 12) {
            circulo(grande ? 38 : 26)
                .frame(width: grande ? 56 : 44, height: grande ? 56 : 44)
                .padding(.vertical, -4)
            Text(afazer.texto)
                .font(.body)
                .foregroundStyle(paleta.cor(riscado ? vidro.secundario : .texto))
                .strikethrough(riscado, color: paleta.cor(vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, grande ? 6 : 7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 18))
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(aceso ? paleta.cor(.aceso) : .clear)
        .contentShape(.rect)
        .onTapGesture(perform: tocar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(afazer.texto)
        .accessibilityValue(feito ? "feito" : "pendente")
        .accessibilityAddTraits(.isToggle)
        .accessibilityAction { tocar() }
        .accessibilityIdentifier("afazer-\(afazer.id)")
    }

    @ViewBuilder private func circulo(_ lado: CGFloat) -> some View {
        if feito {
            Circle().fill(paleta.cor(.positivo)).frame(width: lado, height: lado)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: lado * 0.5, weight: .bold))
                        .foregroundStyle(paleta.cor(.fundo))
                }
        } else {
            Circle().strokeBorder(paleta.cor(vidro.secundario), lineWidth: 2).frame(width: lado, height: lado)
        }
    }
}
