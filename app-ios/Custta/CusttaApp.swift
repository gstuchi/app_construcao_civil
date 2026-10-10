import SwiftUI

@main
struct CusttaApp: App {
    /// Nos testes de unidade o app só hospeda o pacote de testes: não monta serviço nenhum.
    private static let hospedandoTestes = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    @State private var modelo: ModeloApp? = CusttaApp.hospedandoTestes ? nil : Composicao.montar()
    @Environment(\.scenePhase) private var fase

    init() {
        // Os pontos do globo (uns 10 mil, com o teste de continente) saem da thread principal, antes do 1º quadro.
        Task.detached(priority: .userInitiated) { _ = PontosDoGlobo.todos.terra.count }
    }

    var body: some Scene {
        WindowGroup {
            if let modelo {
                RaizView()
                    .environment(modelo)
                    .onChange(of: fase) { _, nova in
                        if nova == .active { Task { await modelo.voltouParaFrente() } }
                    }
            } else {
                // Sem serviço (Release antes da camada Firebase, ou hospedando os testes de unidade).
                AberturaView()
            }
        }
    }
}

/// A abertura: o fundo do Custta e o título se escrevendo, para quando o app ainda não tem serviço. Para
/// como o resto do app: Reduzir movimento, Pouca Energia, calor e app fora de ativo.
struct AberturaView: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @Environment(\.scenePhase) private var fase
    @State private var poucaEnergia = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var calor = OpcoesDoAparelho.quente(ProcessInfo.processInfo.thermalState)
    @State private var relogio = RelogioDoFundo()

    var body: some View {
        let opcoes = OpcoesDoAparelho(reduzirMovimento: reduzirMovimento, poucaEnergia: poucaEnergia, calor: calor)
        let anda = opcoes.fundoAnda(ativo: fase == .active, rolando: false, teclado: false, coberto: false)
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true), relogio: relogio)
            Globo(relogio: relogio)
            LogoEscrito(animado: opcoes.animaFundo)
        }
        .preferredColorScheme(.dark)
        .onChange(of: anda, initial: true) { _, novo in relogio.rodando = novo }
        .acompanhaEnergia(poucaEnergia: $poucaEnergia, calor: $calor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Custta")
        .accessibilityIdentifier("abertura")
    }
}
