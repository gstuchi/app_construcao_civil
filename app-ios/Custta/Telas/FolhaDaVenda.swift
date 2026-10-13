import SwiftUI
import CusttaNucleo

/* A folha da venda (mockup da etapa 2, parte 3; formVenda do site), em dois passos como o gasto: o valor no teclado de
   valor e "Avançar" empurra a data, no calendário limitado entre o início da obra e hoje (no site, um erro depois), e
   "Confirmar venda". Grava `venda {valor, data}` e a fase vendida pela regra do núcleo; a folha desce e a obra mostra o
   lucro. */

enum PassoDaVenda: Hashable {
    case data
}

@MainActor @Observable
final class RascunhoDaVenda {
    var centavos = 0
    var data: String
    /// Passou do valor: fechar passa a perguntar.
    var passouDoValor = false

    init(hoje: String) { data = hoje }
}

struct FolhaDaVenda: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho = RascunhoDaVenda(hoje: dataLocalISO(.now, fuso: .current))
    @State private var caminho: [PassoDaVenda] = []

    private var obra: Obra? { modelo.sincronizador.estado.obras.first { $0.id == obraId } }

    var body: some View {
        NavigationStack(path: $caminho) {
            TecladoDeValor(centavos: $rascunho.centavos, acao: "Avançar") {
                rascunho.passouDoValor = true
                caminho = [.data]
            }
            .passoDaFolha("Valor da venda", subtitulo: obra?.nome, fechar: .esquerda, raiz: true)
            .navigationDestination(for: PassoDaVenda.self) { _ in
                PassoDaDataDaVenda(rascunho: rascunho, caminho: $caminho, obraId: obraId)
            }
        }
        .folhaDoApp(perguntar: rascunho.passouDoValor, pergunta: "Você já preencheu esta venda.", descartar: "Descartar venda") {
            folhas.fechar()
        }
        // A obra sumiu ou outro aparelho mudou a fase com a folha aberta: não há o que vender; a folha fecha.
        .onChange(of: obra?.fase == .pronta) { _, pronta in if !pronta { folhas.fechar() } }
        #if DEBUG
        // Testes de tela e laudo: a folha aberta já na data (`-custta.folha detalhes`), com o valor do mockup.
        .onAppear {
            guard UserDefaults.standard.string(forKey: "custta.folha") == "detalhes", caminho.isEmpty else { return }
            rascunho.centavos = 138_000_000
            rascunho.passouDoValor = true
            caminho = [.data]
        }
        #endif
    }
}

private struct PassoDaDataDaVenda: View {
    @Bindable var rascunho: RascunhoDaVenda
    @Binding var caminho: [PassoDaVenda]
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @State private var erro: String?
    @State private var naoCarregado = false

    var body: some View {
        let obra = modelo.sincronizador.estado.obras.first { $0.id == obraId }
        let hoje = dataLocalISO(.now, fuso: .current)
        let inicio = obra?.dataInicio ?? hoje
        ScrollView {
            VStack(spacing: 8) {
                GrupoDaFolha {
                    LinhaDeDinheiro(rotulo: "Valor da venda", centavos: rascunho.centavos, opcional: false, altura: 60,
                                    identificador: "linhaValorDaVenda") { caminho.removeAll() }
                    SeparadorDaFolha()
                    LinhaDaFolhaComRotulo(rotulo: "Data da venda") {
                        // O calendário só deixa escolher entre o início e hoje (obra que começa no futuro: só hoje, e o
                        // "Confirmar venda" explica com o texto do site).
                        CampoDeData(iso: $rascunho.data, minimo: min(inicio, hoje), maximo: hoje)
                    }
                }
                NotaDaFolha(texto: notaDaDataDaVenda(dataInicio: inicio))
                if let erro { NotaDaFolha(texto: erro, cor: .erroNoVidro, identificador: "erroDaVenda") }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Confirmar venda") { confirmar(inicio: inicio, hoje: hoje) }
                .buttonStyle(BotaoDaFolha())
                .accessibilityIdentifier("confirmarVenda")
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
        }
        .onChange(of: rascunho.data) { _, _ in erro = nil }
        .passoDaFolha("Registrar venda", subtitulo: obra?.nome, fechar: .direita)
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("A venda continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .pausaOFundo(enquanto: naoCarregado)
    }

    private func confirmar(inicio: String, hoje: String) {
        let valor = centavosParaReais(rascunho.centavos)
        if let e = conferirVenda(valor: valor, data: rascunho.data, dataInicio: inicio, hoje: hoje) {
            if e.campo == "valor" { caminho.removeAll(); return }       // sem mensagem, como o site: volta ao teclado
            erro = e.mensagem
            if let m = e.mensagem { AccessibilityNotification.Announcement(m).post() }
            return
        }
        switch modelo.gravar({ $0.registrandoVenda(obraId, valor: valor, data: rascunho.data) }) {
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        }
    }
}
