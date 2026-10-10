import SwiftUI

/* Ajustes da etapa 1: só a conta (nome, e-mail, confirmação pendente e sair) e a versão. Aparência,
   notificações, exportar, trocar senha e apagar conta chegam na etapa 5. */
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
                        .accessibilityIdentifier("versao")
                }
                .padding(.horizontal, 16)
                // O painel começa 18 pt abaixo de onde começa a lista de Obras, como no mockup.
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
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
