import SwiftUI
import AuthenticationServices
import CusttaNucleo

/* Entrar, criar conta e falta pouco: a entrada do PWA, com o título escrito à mão sobre a aurora de
   hoje e o cartão de vidro Fosco. Ao rolar, o título sobe e esmaece, como no site (parado com Reduzir
   movimento). O cartão fica reto: o vidro do iOS não acompanha a inclinação 3D do cartão do PWA (decisão
   do Giovani em 08/10). Entrar e criar conta dividem o cartão, trocados pelo segmentado, que
   é vidro próprio fora do cartão; o falta pouco usa o mesmo cartão. */

enum AbaDaEntrada: String, CaseIterable, Identifiable {
    case entrar
    case criarConta

    var id: String { rawValue }
    var titulo: String { self == .entrar ? "Entrar" : "Criar conta" }
    var identificador: String { self == .entrar ? "irParaEntrar" : "irParaCriarConta" }
}

/// Quanto a entrada rolou. Mora fora da EntradaView para a rolagem refazer só o título, não a tela toda.
@MainActor @Observable
final class RolagemDaEntrada {
    var deslocamento: CGFloat = 0
}

struct EntradaView: View {
    /// A conta Google ou Apple sem perfil (falta pouco); nil em entrar e criar conta.
    let faltaPouco: Usuario?
    @State private var aba = AbaDaEntrada.entrar
    @State private var rolagem = RolagemDaEntrada()
    @FocusState private var foco: String?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    // Meia tela de rolagem leva o título até o fim do movimento, como o auth.js.
                    TituloDaEntrada(rolagem: rolagem, meiaTela: geo.size.height * 0.5)
                        .padding(.bottom, 32)
                    VStack(spacing: 14) {
                        if faltaPouco == nil { SegmentadoDaEntrada(aba: $aba) }
                        VStack(spacing: 0) {
                            if let usuario = faltaPouco { FormFaltaPouco(usuario: usuario, foco: $foco) }
                            else if aba == .entrar { FormEntrar(foco: $foco) }
                            else { FormCriarConta(foco: $foco) }
                        }
                        .padding(EdgeInsets(top: 26, leading: 22, bottom: 20, trailing: 22))
                        .superficie(.cartaoEntrada, em: .rect(cornerRadius: 32))
                    }
                    Color.clear.frame(height: geo.size.height * 0.52)
                }
                .frame(maxWidth: 440)
                .padding(.horizontal, 18)
                .padding(.top, geo.size.height * 0.11)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
                rolagem.deslocamento = y
            }
            .pausaOFundoAoRolar()
            .bordaDeRolagem(abas: false)
        }
    }
}

/// "Controle os custos das suas obras com custta." e a dica de rolar, com o halo no escuro. Ao rolar meia
/// tela, o título sobe 80 pt e esmaece (parado com Reduzir movimento).
struct TituloDaEntrada: View {
    let rolagem: RolagemDaEntrada
    let meiaTela: CGFloat
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho
    /// Largura que quebra o título como no mockup ("Controle os custos / das suas obras com").
    @ScaledMetric(relativeTo: .title2) private var larguraDoTitulo = 212
    /// A seta da dica tem 1em, como no mockup: cresce com a letra.
    @ScaledMetric(relativeTo: .footnote) private var seta: CGFloat = 13

    var body: some View {
        let progresso = opcoes.reduzirMovimento ? 0 : min(1, max(0, rolagem.deslocamento / meiaTela))
        VStack(spacing: 0) {
            Text("Controle os custos das suas obras com")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                // Quebra equilibrada como a do mockup ("Controle os custos / das suas obras com"); na letra
                // grande o texto usa a largura toda.
                .frame(maxWidth: tamanho.isAccessibilitySize ? .infinity : larguraDoTitulo)
                .foregroundStyle(paleta.cor(.texto))
                .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
            LogoEscrito(animado: opcoes.animaFundo)
                .padding(.top, 15)
                .padding(.bottom, 9)
            HStack(spacing: 4) {
                Text("Role para entrar")
                Image(decorative: "Icones/setaBaixo").resizable().frame(width: seta, height: seta)
            }
            .font(.footnote)
            .foregroundStyle(paleta.cor(.texto))
            .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
            // 23 pt da caixa do logo, como no mockup aprovado: os 9 do logo mais os 14 da dica (no site as duas
            // margens colapsam e ficam 14).
            .padding(.top, 14)
            .opacity(max(0, 1 - 1.6 * progresso))
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .background { HaloDoTitulo(grande: tamanho.isAccessibilitySize) }
        .offset(y: -80 * progresso)
        .opacity(1 - 0.35 * progresso)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Controle os custos das suas obras com Custta")
        .accessibilityAddTraits(.isHeader)
    }
}

/// "Entrar | Criar conta": cápsula de vidro própria, fora do cartão.
struct SegmentadoDaEntrada: View {
    @Binding var aba: AbaDaEntrada
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AbaDaEntrada.allCases) { item in
                let ativa = item == aba
                Button { aba = item } label: {
                    Text(item.titulo)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(paleta.cor(ativa ? .sobreTinta : .texto))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        // Sólido: a 90% do mockup, o branco sobre a tinta fica em 4,4:1 no claro.
                        .background { if ativa { Capsule().fill(paleta.cor(.tinta)) } }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier(item.identificador)
            }
        }
        .padding(4)
        .superficie(.segmentado, em: .capsule)
    }
}

/// Apple acima do Google (Guideline 4.8), um login por vez.
struct BotoesSociais: View {
    let ocupado: Bool
    /// Mensagem de erro do login social (vazia quando a pessoa desistiu).
    let aoFalhar: (String?) -> Void
    let rodar: (@escaping @MainActor () async -> String?) async -> Void
    @Environment(ModeloApp.self) private var modelo
    @State private var nonce = ""

    var body: some View {
        VStack(spacing: 10) {
            BotaoApple { pedido in
                nonce = Nonce.gerar()
                pedido.requestedScopes = [.fullName, .email]
                pedido.nonce = Nonce.sha256(nonce)
            } concluir: { resultado in
                Task { await terminarApple(resultado) }
            }
            BotaoGoogle { Task { await rodar { await modelo.entrarComGoogle() } } }
        }
        .disabled(ocupado)
    }

    private func terminarApple(_ resultado: Result<ASAuthorization, Error>) async {
        switch resultado {
        case .success(let autorizacao):
            guard let c = autorizacao.credential as? ASAuthorizationAppleIDCredential,
                  let dados = c.identityToken, let token = String(data: dados, encoding: .utf8) else {
                aoFalhar(mensagemErroSocial(codigo: "auth/invalid-credential", provedor: "apple.com"))
                return
            }
            let credencial = CredencialApple(idToken: token, nonce: nonce, nomeCompleto: c.fullName)
            await rodar { await modelo.entrarComApple(credencial) }
        case .failure(let erro):
            let n = erro as NSError
            let texto = mensagemErroSocial(codigo: codigoDeErroDeConta(dominio: n.domain, codigo: n.code), provedor: "apple.com")
            aoFalhar(texto.isEmpty ? nil : texto)
        }
    }
}

/// Entrar com e-mail e senha; "Esqueci minha senha" usa o e-mail do próprio cartão, como no site.
struct FormEntrar: View {
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @State private var email = ""
    @State private var senha = ""
    @State private var mensagem: (texto: String, tipo: Mensagem.Tipo)?
    @State private var invalido: String?
    @State private var entrando = false

    var body: some View {
        VStack(spacing: 0) {
            BotoesSociais(ocupado: entrando, aoFalhar: { texto in mensagem = texto.map { ($0, .erro) } }, rodar: rodar)
            DivisorOu().padding(.top, 14).padding(.bottom, 10)
            CampoDeEntrada(rotulo: "E-mail", exemplo: "voce@email.com", texto: $email, identificador: "email",
                           invalido: invalido == "email", tipo: .username, teclado: .emailAddress, maiusculas: .never,
                           foco: foco, chave: "email", proximo: "senha")
                .padding(.bottom, 13)
            CampoDeEntrada(rotulo: "Senha", exemplo: "Sua senha", texto: $senha, identificador: "senha", senha: true,
                           invalido: invalido == "senha", tipo: .password, foco: foco, chave: "senha")
                .onSubmit { Task { await entrar() } }
                .padding(.bottom, 12)
            if let mensagem {
                Mensagem(tipo: mensagem.tipo, texto: mensagem.texto, identificador: "mensagemEntrada").padding(.bottom, 12)
            }
            Button { Task { await entrar() } } label: {
                HStack(spacing: 8) {
                    if entrando { ProgressView().controlSize(.small) }
                    Text(entrando ? "Entrando…" : "Entrar")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(entrando)
            .accessibilityIdentifier("entrar")
            Button("Esqueci minha senha") { Task { await esqueci() } }
                .buttonStyle(LinkSublinhado())
                .disabled(entrando)
                .padding(.top, 6)
                .accessibilityIdentifier("esqueciSenha")
            LinkDaPolitica()
        }
        .onAppear {
            if let texto = modelo.mensagemEntrada { mensagem = (texto, texto == ModeloApp.sessaoExpirada ? .cadeado : .erro) }
            modelo.mensagemEntrada = nil            // mostrada uma vez: trocar de aba e voltar não a traz de novo
        }
    }

    /// Um login por vez: os botões travam até o atual voltar.
    private func rodar(_ acao: @escaping @MainActor () async -> String?) async {
        entrando = true
        mensagem = nil
        invalido = nil
        if let erro = await acao() { mensagem = (erro, .erro) }
        entrando = false
    }

    private func entrar() async {
        if let erro = validarEntrada(email: email, senha: senha) {
            invalido = emailParece(aparadoJS(email)) ? "senha" : "email"
            foco.wrappedValue = invalido
            mensagem = (erro, .erro)
            return
        }
        await rodar { await modelo.entrar(email: email, senha: senha) }
    }

    private func esqueci() async {
        invalido = nil
        let texto = await modelo.redefinirSenha(email: email)
        let enviado = texto == ModeloApp.linkEnviado
        mensagem = (texto, enviado ? .ok : .erro)
        if !enviado && !emailParece(aparadoJS(email)) {
            invalido = "email"
            foco.wrappedValue = "email"
        }
    }
}

/// Criar conta: nome, sobrenome, e-mail, senha com o checklist, confirmação e "como conheceu o Custta".
struct FormCriarConta: View {
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var email = ""
    @State private var senha = ""
    @State private var confirmacao = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var erro: (campo: String, texto: String)?
    @State private var criando = false

    var body: some View {
        VStack(spacing: 0) {
            BotoesSociais(ocupado: criando, aoFalhar: { texto in erro = texto.map { ("", $0) } }, rodar: rodar)
            DivisorOu().padding(.top, 14).padding(.bottom, 10)
            VStack(spacing: 13) {
                CampoDeEntrada(rotulo: "Nome", exemplo: "Seu nome", texto: $nome, identificador: "nome",
                               invalido: erro?.campo == "nome", tipo: .givenName, maiusculas: .words, foco: foco, chave: "nome",
                               proximo: "sobrenome")
                CampoDeEntrada(rotulo: "Sobrenome", opcional: true, exemplo: "Seu sobrenome", texto: $sobrenome, identificador: "sobrenome",
                               invalido: erro?.campo == "sobrenome", tipo: .familyName, maiusculas: .words, foco: foco, chave: "sobrenome",
                               proximo: "email")
                CampoDeEntrada(rotulo: "E-mail", exemplo: "voce@email.com", texto: $email, identificador: "emailCadastro",
                               invalido: erro?.campo == "email", tipo: .emailAddress, teclado: .emailAddress, maiusculas: .never,
                               foco: foco, chave: "email", proximo: "senha")
                VStack(alignment: .leading, spacing: 8) {
                    CampoDeEntrada(rotulo: "Senha", exemplo: "Crie uma senha", texto: $senha, identificador: "senhaCadastro", senha: true,
                                   invalido: erro?.campo == "senha", tipo: .newPassword, foco: foco, chave: "senha")
                    ChecklistSenha(senha: senha, email: email)
                }
                CampoDeEntrada(rotulo: "Confirmar senha", exemplo: "Repita a senha", texto: $confirmacao, identificador: "confirmacao",
                               senha: true, invalido: erro?.campo == "confirmacao", tipo: .newPassword, foco: foco, chave: "confirmacao")
                CampoOrigem(origem: $origem, detalhe: $detalhe, invalido: erro?.campo, foco: foco)
            }
            .padding(.bottom, 12)
            if let erro { Mensagem(tipo: .erro, texto: erro.texto, identificador: "mensagemCadastro").padding(.bottom, 12) }
            Button { Task { await criar() } } label: {
                HStack(spacing: 8) {
                    if criando { ProgressView().controlSize(.small) }
                    Text(criando ? "Criando conta…" : "Criar conta")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(criando)
            .accessibilityIdentifier("criarConta")
            LinkDaPolitica()
        }
    }

    private func rodar(_ acao: @escaping @MainActor () async -> String?) async {
        criando = true
        erro = nil
        if let texto = await acao() { erro = ("", texto) }
        criando = false
    }

    private func criar() async {
        erro = nil
        switch validarCadastro(nome: nome, sobrenome: sobrenome, email: email, senha: senha, confirmacao: confirmacao,
                               origem: origem, origemDetalhe: detalhe) {
        case .falhou(let campo, let texto):
            erro = (campo, texto)
            foco.wrappedValue = campo
        case .ok(let perfil):
            await rodar { await modelo.criarConta(email: email, senha: senha, perfil: perfil) }
        }
    }
}

/// "Falta pouco": conta Google ou Apple sem perfil. A Apple manda o nome, então só pede a origem (a
/// revisão reprova pedir de novo); o Google confirma o nome.
struct FormFaltaPouco: View {
    let usuario: Usuario
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var mensagem: String?
    @State private var invalido: String?
    @State private var salvando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Falta pouco")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 4)
            Text(usuario.contaApple ? "Só falta contar como você conheceu o Custta." : "Confirme seu nome e conte como conheceu o Custta.")
                .font(.subheadline)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .padding(.bottom, 14)
                .accessibilityIdentifier("textoFaltaPouco")
            HStack(spacing: 10) {
                Group {
                    if usuario.contaApple { Image(systemName: "apple.logo").font(.body).foregroundStyle(paleta.cor(.texto)) }
                    else { Image(decorative: "LogoGoogle").resizable().frame(width: 18, height: 18) }
                }
                .frame(width: 32, height: 32)
                .background(paleta.cor(.campo), in: .circle)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(usuario.contaApple ? "Você entrou com a Apple." : "Você entrou com o Google")
                        .foregroundStyle(paleta.cor(vidro.secundario))
                    if !usuario.contaApple && !usuario.email.isEmpty {
                        Text(usuario.email).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))
                    }
                }
                .font(.footnote)
            }
            .padding(.bottom, 14)
            .accessibilityElement(children: .combine)
            VStack(spacing: 13) {
                if !usuario.contaApple {
                    CampoDeEntrada(rotulo: "Nome", exemplo: "Seu nome", texto: $nome, identificador: "nome",
                                   invalido: invalido == "nome", tipo: .givenName, maiusculas: .words, foco: foco, chave: "nome",
                                   proximo: "sobrenome")
                    CampoDeEntrada(rotulo: "Sobrenome", opcional: true, exemplo: "Seu sobrenome", texto: $sobrenome, identificador: "sobrenome",
                                   invalido: invalido == "sobrenome", tipo: .familyName, maiusculas: .words, foco: foco, chave: "sobrenome")
                }
                CampoOrigem(origem: $origem, detalhe: $detalhe, invalido: invalido, foco: foco)
            }
            .padding(.bottom, 12)
            if let mensagem { Mensagem(tipo: .erro, texto: mensagem, identificador: "mensagemFaltaPouco").padding(.bottom, 12) }
            Button { Task { await salvar() } } label: {
                HStack(spacing: 8) {
                    if salvando { ProgressView().controlSize(.small) }
                    Text(salvando ? "Salvando…" : "Começar a usar")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(salvando)
            .accessibilityIdentifier("comecarAUsar")
            Button("Usar outra conta") {
                Task { mensagem = await modelo.sair() == nil ? nil : "Não foi possível trocar de conta agora. Tente de novo." }
            }
            .buttonStyle(LinkSublinhado())
            .padding(.top, 6)
            .accessibilityIdentifier("usarOutraConta")
            LinkDaPolitica()
        }
        .onAppear {
            let n = nomeDoGoogle(usuario.nomeExibicao)
            nome = n.nome
            sobrenome = n.sobrenome
        }
    }

    private func salvar() async {
        mensagem = nil
        invalido = nil
        let nomes = usuario.contaApple ? nomeDoGoogle(usuario.nomeExibicao) : (nome, sobrenome)
        let r = normalizaPerfil(nome: nomes.0, sobrenome: nomes.1, origem: origem, origemDetalhe: detalhe, nomeOpcional: usuario.contaApple)
        guard r.ok, let perfil = r.perfil else {
            mensagem = r.erro
            invalido = r.campo
            foco.wrappedValue = r.campo
            return
        }
        salvando = true
        mensagem = await modelo.completarPerfil(perfil)
        salvando = false
    }
}

/// O checklist de senha do site, com as cinco regras do cadastro.js; uma coluna na letra grande.
struct ChecklistSenha: View {
    let senha: String
    let email: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho
    /// Ícones de 16 pt (1,25em do mockup), crescendo com a letra.
    @ScaledMetric(relativeTo: .footnote) private var icone: CGFloat = 16

    var body: some View {
        let colunas = tamanho.isAccessibilitySize ? [GridItem(.flexible(), alignment: .leading)]
                                                  : [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)]
        LazyVGrid(columns: colunas, alignment: .leading, spacing: 4) {
            ForEach(validaSenha(senha, email: email).regras, id: \.id) { regra in
                Label {
                    Text(regra.texto).foregroundStyle(paleta.cor(regra.ok ? .texto : vidro.secundario))
                } icon: {
                    Image(systemName: regra.ok ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: icone))
                        .foregroundStyle(paleta.cor(regra.ok ? .linkNoVidro : .textoTerciario))
                }
                .font(.footnote)
                .accessibilityLabel("\(regra.texto): \(regra.ok ? "ok" : "falta")")
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("checklistSenha")
    }
}

/// "Como conheceu o Custta?": abre o menu do sistema; indicação e outro pedem o detalhe (opcional).
struct CampoOrigem: View {
    @Binding var origem: String?
    @Binding var detalhe: String
    let invalido: String?
    var foco: FocusState<String?>.Binding
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        let escolhida = origens.first { $0.id == origem }
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Como conheceu o Custta?")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .accessibilityHidden(true)
                    .padding(.vertical, 1)          // linha de 18 pt, como o rótulo do CampoDeEntrada
                Menu {
                    Picker("Como conheceu o Custta?", selection: $origem) {
                        ForEach(origens, id: \.id) { o in Text(o.nome).tag(Optional(o.id)) }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(escolhida?.nome ?? "Escolha uma opção")
                            .foregroundStyle(paleta.cor(escolhida == nil ? vidro.secundario : .texto))
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(paleta.cor(vidro.secundario))
                    }
                    .font(.body)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .frame(minHeight: 48)
                    .background(paleta.cor(.campo), in: .rect(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(paleta.cor(invalido == "origem" ? .alerta : .campoBorda), lineWidth: 1))
                }
                .accessibilityLabel("Como conheceu o Custta?")
                .accessibilityValue(escolhida?.nome ?? "Escolha uma opção")
                .accessibilityIdentifier("origem")
            }
            if let rotulo = escolhida?.detalhe {
                CampoDeEntrada(rotulo: rotulo, exemplo: "", texto: $detalhe, identificador: "origemDetalhe",
                               invalido: invalido == "origemDetalhe", maiusculas: .words, foco: foco, chave: "origemDetalhe")
            }
        }
        .onChange(of: origem) { _, nova in
            if origens.first(where: { $0.id == nova })?.detalhe == nil { detalhe = "" }
        }
    }
}

/// "Política de Privacidade", o link neutro do fim do cartão.
struct LinkDaPolitica: View {
    var body: some View {
        Link("Política de Privacidade", destination: URL(string: "https://custta.com.br/privacidade.html")!)
            .buttonStyle(LinkSublinhado(neutro: true))
    }
}
