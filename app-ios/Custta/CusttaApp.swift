import SwiftUI

@main
struct CusttaApp: App {
    init() {
        // Os pontos do globo (uns 10 mil, com o teste de continente) saem da thread principal, antes do 1º quadro.
        Task.detached(priority: .userInitiated) { _ = PontosDoGlobo.todos.terra.count }
    }

    var body: some Scene {
        WindowGroup { AberturaView() }
    }
}

/// A abertura: o fundo do Custta, a aurora e o globo, enquanto o app não tem a tela de entrar. Para como o resto
/// do app: Reduzir movimento, Pouca Energia, calor e app fora de ativo.
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
        }
        .preferredColorScheme(.dark)
        .onChange(of: anda, initial: true) { _, novo in relogio.rodando = novo }
        .acompanhaEnergia(poucaEnergia: $poucaEnergia, calor: $calor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Custta")
        .accessibilityIdentifier("abertura")
    }
}
