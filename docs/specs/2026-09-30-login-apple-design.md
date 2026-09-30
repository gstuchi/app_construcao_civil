# Login com Apple

Entrar e criar conta com "Continuar com a Apple" no app iOS, no site
(custta.com.br) e no PWA. Continuação do login com Google (PR #14, spec
`2026-09-23-login-google-design.md`), que ficou só na web porque o app nativo
dependia da matrícula na Apple. A matrícula saiu, o TestFlight está no ar e o
Giovani quer que a pessoa entre com o Apple ID dela.

## Decisões (com o Giovani, 30/09/2026)

- **Apple no app iOS e na web.** Quem cria conta com Apple no iPhone precisa
  conseguir entrar no site e no PWA (o pai do Giovani usa o PWA). Na web o
  login passa pelo Firebase com um Services ID; no app, pela tela nativa da
  Apple.
- **Google no iPhone fica para outro PR.** Com a Apple no app, a Guideline 4.8
  passa a permitir o Google no nativo, mas isso exige cliente OAuth iOS e
  plugin próprio. Aqui o botão do Google continua escondido no nativo.
- **Nome vem da Apple; "Falta pouco" pergunta só "como conheceu".** A revisão
  da Apple reprova app que pede nome ou e-mail depois do Sign in with Apple
  (Guideline 4.0). O nome que a Apple manda no primeiro login vai direto para o
  perfil. Se não vier nome, o perfil fica sem nome e a pessoa edita em Ajustes
  (as rules já aceitam `perfis/{uid}` sem `nome`).
- **Plugin nativo `@capawesome/capacitor-apple-sign-in`.** Capacitor 8, Swift
  Package Manager, MIT, ~230 linhas de Swift sobre `AuthenticationServices`,
  aceita nonce e devolve `idToken` e `authorizationCode`. Descartados:
  `@capacitor-community/apple-sign-in` (o `Package.swift` fixa
  capacitor-swift-pm 7, incompatível com o Capacitor 8 daqui) e
  `@capacitor-firebase/authentication` (traz o SDK nativo do Firebase Auth e,
  por padrão, os SDKs do Google e do Facebook — peso sem uso, já que o login
  continua no SDK JavaScript).
- **O SDK JavaScript continua sendo o único dono da sessão.** No nativo o
  plugin só devolve a credencial da Apple; `cloud.js` entra com
  `signInWithCredential(OAuthProvider('apple.com').credential({ idToken,
  rawNonce }))`. Nada muda em `onAuthStateChanged`, fila de escrita, travas ou
  logout.
- **Apagar conta revoga o token da Apple** (Guideline 5.1.1(v)). Falha na
  revogação não impede apagar a conta: registra em `OBRA_DIAG` e segue. Travar a
  exclusão por um erro do lado da Apple deixaria a pessoa sem conseguir sair do
  app, que é pior.
- **E-mail que já tem conta com senha:** mensagem para entrar do jeito de antes
  (igual ao Google). Ligar a Apple a uma conta existente fica fora.
- **Sem mudança nas rules nem no formato do estado.**

## Configuração externa (Giovani, no portal, 30/09/2026)

Nada disso passa pelo repositório nem pela conversa.

- **App ID `br.com.custta.app`:** capability *Sign In with Apple* ("Enable as a
  primary App ID"). Isso invalida o perfil "Custta App Store", que é refeito com
  o mesmo certificado e volta ao secret `PERFIL_APP_STORE`.
- **Services ID `br.com.custta.web`** (login na web): domínios `custta.com.br` e
  `app-construcao-civil.firebaseapp.com`; return URLs
  `https://custta.com.br/__/auth/handler` e
  `https://app-construcao-civil.firebaseapp.com/__/auth/handler`. O proxy da
  Vercel (`/__/auth/*`) já repassa POST — conferido: `POST
  https://custta.com.br/__/auth/handler` responde 200. A Apple devolve o login
  por `form_post`, então isso importa.
- **Chave "Custta Sign in with Apple" (.p8):** vai para o Firebase (fluxo de
  código OAuth: Team ID `4S7JKDKN27`, Key ID, chave privada). É o que permite
  ao Firebase revogar o token quando a conta é apagada. Cópia em
  `~/Documents/custta-chaves/`.
- **Firebase → Authentication → Apple:** ativo, com o Services ID acima.

Até o perfil novo estar no secret, build de TestFlight com a entitlement nova
falha na assinatura. O `ios-build.yml` (sem assinatura) não depende disso.

## Fluxos

### Entrar com Apple — web (navegador e PWA)

1. Botão "Continuar com a Apple" acima do "Continuar com Google", no mesmo
   bloco, nas abas Entrar e Criar conta.
2. `CLOUD.entrarApple()` usa `OAuthProvider('apple.com')` com escopos `email` e
   `name` e `locale: 'pt_BR'`: popup em aba comum; redirect no PWA instalado e
   como plano B do popup bloqueado — o mesmo caminho do Google.
3. Antes do redirect, `cloud.js` anota o provedor em `sessionStorage`
   (`custta-redirect`) para que o erro que volta do `getRedirectResult` seja
   mostrado com o nome certo ("Apple" ou "Google").
4. O Firebase guarda o `displayName` que a Apple manda no primeiro login. Se o
   resultado vier sem `displayName` mas com `firstName`/`lastName` na resposta
   do Firebase, `cloud.js` grava com `updateProfile` (melhor esforço).

### Entrar com Apple — app iOS

1. Só o botão da Apple aparece (Google continua escondido no nativo).
2. `cloud.js` gera um nonce aleatório (32 bytes, `crypto.getRandomValues`),
   manda o SHA-256 dele (hex) para `OBRA_NATIVO.entrarApple({ nonce })`, que
   chama o plugin `AppleSignIn.signIn({ scopes: ['EMAIL', 'FULL_NAME'], nonce })`.
3. Com o `idToken` devolvido, `signInWithCredential(auth,
   OAuthProvider('apple.com').credential({ idToken, rawNonce }))`.
4. `givenName`/`familyName` só chegam no primeiro login: se vierem e a conta
   estiver sem `displayName`, `updateProfile` grava o nome completo.
5. `nativo.js` é o único arquivo que toca o plugin. Diferente dos outros
   wrappers, `entrarApple` **propaga** o erro (o chamador precisa distinguir
   cancelamento de falha). Cancelamento do plugin (`SIGN_IN_CANCELED`, ou código
   1001 do `ASAuthorizationError`) vira `auth/user-cancelled`.

### Completar perfil (conta Apple sem perfil)

1. `perfilPendente()` passa a valer para `google.com` **ou** `apple.com`.
2. Conta Apple: o "Falta pouco" esconde nome e sobrenome e mostra só "como
   conheceu" (+ detalhe). O nome vem de `nomeExibicao`, separado pela mesma
   regra do Google (primeira palavra = nome, resto = sobrenome, cortados nos
   limites).
3. Sem nome da Apple: o perfil é gravado sem `nome`/`sobrenome`.
   `OBRA_CADASTRO.normalizaPerfil` ganha a opção `{ nomeOpcional: true }`.
4. O resto é igual ao do Google: `completarPerfil`, `perfil-alterado`, "Usar
   outra conta", tratamento de duas abas.

### Conta só Apple (sem senha)

- `currentUser.temSenha` continua falso quando não há `password`.
  `reautenticar()` escolhe pelo provedor: `password` → senha; senão `apple.com`
  (se presente) → Apple; senão `google.com` → Google.
- Reautenticar com Apple: na web, `reauthenticateWithPopup` com o provedor
  Apple; no nativo, plugin de novo (nonce novo) +
  `reauthenticateWithCredential`.
- "Apagar conta" não pede senha. O texto diz "você vai entrar com a Apple de
  novo" (ou "com o Google", pelo provedor). Como no Google, a reautenticação
  roda antes da trava entre abas, ainda dentro do gesto do usuário.
- **Revogação**, depois do batch que apaga os documentos e antes do
  `deleteUser`:
  - web: `OAuthProvider.credentialFromResult(resultado).accessToken` →
    `revokeAccessToken(auth, token)`;
  - nativo: o SDK JavaScript só revoga `ACCESS_TOKEN`, e o nativo tem
    `authorizationCode`. `cloud.js` chama direto
    `POST https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key=<apiKey>`
    com `{ providerId: 'apple.com', tokenType: 'CODE', token: authorizationCode,
    idToken }` (mesmo pedido que o SDK nativo do Firebase faz).
  - Qualquer falha: `OBRA_DIAG.registra('apple-revogar', …)` e segue.
- "Trocar senha" continua escondido e o aviso de confirmar e-mail não aparece
  (a Apple manda o e-mail já verificado, inclusive o de retransmissão
  `@privaterelay.appleid.com`).

## Erros (português)

`OBRA_CADASTRO.mensagemErroSocial(code, 'Apple' | 'Google')` substitui
`mensagemErroGoogle` (que continua existindo como atalho para 'Google'). Os
textos do Google passam a ser os desta tabela — só o de
`account-exists-with-different-credential` muda de fato, porque "entre com
e-mail e senha" deixa de ser o único caminho certo.

| Código | Mensagem |
| --- | --- |
| `popup-closed-by-user`, `cancelled-popup-request`, `user-cancelled` | nenhuma (a pessoa desistiu) |
| `popup-blocked` | cai no redirect automaticamente |
| `account-exists-with-different-credential` | Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez. |
| `unauthorized-domain` | Login com a {Apple/o Google} indisponível neste endereço. Use custta.com.br. |
| `operation-not-allowed` | Login com a Apple ainda não está disponível. Use e-mail e senha. |
| `operation-not-supported-in-this-environment`, `web-storage-unsupported` | Seu navegador bloqueou o login com a {Apple/o Google}. Use e-mail e senha. |
| `network-request-failed` | Sem internet. Conecte pra entrar. |
| outro | Não deu certo entrar com a {Apple/o Google}. Tente de novo. |

No diálogo de conta (`ui-confirm.js`) as mensagens de cancelamento e de
`user-mismatch` passam a citar o provedor da conta.

## Visual

- Botão pelas regras da Apple (HIG, Sign in with Apple): logo da Apple + "Continuar
  com a Apple", mesma altura (50px) e raio dos outros botões, nunca menor que o
  do Google. Tema escuro: fundo branco, texto e logo pretos; tema claro: fundo
  preto, texto e logo brancos. Botão sólido, sem vidro (a Apple exige as cores
  dela), com o mesmo toque de mola dos outros botões.
- Logo em SVG inline pelo `icons.js` (`data-ico="apple"`, `fill: currentColor`),
  para herdar a cor do tema sem arquivo novo.
- O bloco social (`#authGoogle`) vira `#authSocial` com os dois botões e o
  separador "ou". No nativo só o Google some; o bloco fica.

## Arquivos

| Arquivo | Muda |
| --- | --- |
| `cloud.js` | `entrarApple`, nonce/SHA-256, `provedorApple`, `reautenticar` por provedor, revogação, `perfilPendente` com Apple, erro de redirect com provedor |
| `nativo.js` | `entrarApple({ nonce })`, propaga erro, normaliza cancelamento |
| `cadastro.js` | `mensagemErroSocial`, `normalizaPerfil(d, { nomeOpcional })` |
| `auth.js` | botão Apple, estado de carregando, erro por provedor, "Falta pouco" sem nome para Apple |
| `ui-confirm.js` | textos do "Apagar conta" e erros pelo provedor |
| `index.html` | bloco `#authSocial` com o botão Apple |
| `icons.js` | ícone `apple` |
| `styles.css` | `.btn.apple` nos quatro combos tema×skin |
| `sw.js` | bump de `CACHE` |
| `package.json` / `ios/App/CapApp-SPM/Package.swift` | plugin `@capawesome/capacitor-apple-sign-in` (via `cap sync`) |
| `ios/App/App/App.entitlements` | `com.apple.developer.applesignin` = `Default` |
| `privacidade.html` | login com Apple entre os provedores; e-mail de retransmissão da Apple |
| `docs/app-store-metadados.md` | nota de revisão citando Sign in with Apple |
| `CLAUDE.md` | uma linha sobre o plugin e o fluxo Apple |

## Testes

- **Unidade:** `mensagemErroSocial` (Apple e Google, desconhecido, cancelado);
  `normalizaPerfil` com `nomeOpcional`; `nativo.entrarApple` (repasse de
  escopos e nonce, cancelamento normalizado, erro propagado, nulo fora do
  nativo); SHA-256 do nonce contra vetor conhecido; entitlement presente;
  plugin no `package.json` e no `Package.swift` do CapApp-SPM; ícone `apple`
  registrado; `sw.js` com cache novo; CSP nativa inalterada.
- **Navegador (emuladores), suíte nova `tests/browser/apple.cjs`:**
  - web: popup do emulador para `apple.com` → "Falta pouco" **sem** campos de
    nome, só origem → app destravado e `perfis/{uid}` com o nome vindo da
    Apple; segundo login entra direto;
  - web sem nome da Apple: perfil gravado sem `nome`;
  - nativo simulado (stub de `window.Capacitor` com plugin `AppleSignIn` que
    devolve id_token falso aceito pelo emulador): botão Apple visível, Google
    escondido, login entra, cancelamento não mostra erro;
  - conta só Apple: Ajustes sem "Trocar senha"; apagar conta pede só APAGAR,
    reautentica, **tenta revogar** (pedido `accounts:revokeToken` interceptado)
    e apaga documentos e usuário mesmo se a revogação falhar.
- **Suítes existentes** que olham `#authGoogle` passam a usar `#authSocial`.
- **agent-browser na prévia da Vercel:** tela de login em iPhone 16 Pro e
  desktop 1440, escuro/claro × esmeralda/azul: botão Apple com contraste e
  tamanho certos, acima do Google; clique mostra a mensagem de domínio não
  autorizado (esperado na prévia).
- **iOS:** `ios-build.yml` verde; build do TestFlight da branch (depois do
  perfil novo no secret). O teste com Apple ID de verdade é do Giovani, no
  TestFlight (app) e em custta.com.br (web, depois do merge).

## Fora de escopo

- Google no app iOS (PR próprio).
- Ligar Apple a uma conta existente em Ajustes.
- Configurar o envio de e-mail para endereços de retransmissão da Apple (o
  Custta não manda e-mail para conta Apple: ela já vem verificada e não tem
  senha para redefinir).
