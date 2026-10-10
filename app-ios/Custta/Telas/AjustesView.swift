import SwiftUI

/* Ajustes da etapa 1: só a conta (nome, e-mail, confirmação pendente e sair) e a versão. Aparência,
   notificações, exportar, trocar senha e apagar conta chegam na etapa 5. */
struct AjustesView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var confirmarSaida = false
    @State private var mensagemVerificacao: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Conta")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(paleta.cor(.texto))
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, 10)
                        if let nome = modelo.nome {
                            Text(nome)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(paleta.cor(.texto))
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
                                Task { mensagemVerificacao = await modelo.reenviarVerificacao() }
                            }
                            .buttonStyle(BotaoSecundario())
                            if let mensagemVerificacao {
                                Mensagem(tipo: .ok, texto: mensagemVerificacao).padding(.top, 10)
                            }
                            Spacer().frame(height: 10)
                        }
                        Button { confirmarSaida = true } label: {
                            Label { Text("Sair da conta") } icon: { Image(decorative: "Icones/sair").resizable().frame(width: 18, height: 18) }
                        }
                        .buttonStyle(BotaoSecundario())
                        .accessibilityIdentifier("sair")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .superficie(.conteudo, em: .rect(cornerRadius: 24))
                    Text(Self.versao)
                        .font(.footnote)
                        .foregroundStyle(paleta.cor(.texto))
                        .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
                        .accessibilityIdentifier("versao")
                }
                .padding(.horizontal, 16)
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
