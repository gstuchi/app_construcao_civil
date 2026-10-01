# Login com Google no iPhone

"Continuar com Google" também no app iOS. Continuação do login com Apple (PR
#27, spec `2026-09-30-login-apple-design.md`), que deixou o Google escondido no
nativo porque o WKWebView não abre o popup do Google (o Google bloqueia login
em webview embutido, `disallowed_useragent`) e porque a Guideline 4.8 só
libera login de terceiros quando o Sign in with Apple também existe. A Apple
entrou e o Giovani aprovou o teste em 01/10/2026.

## Objetivo

Quem criou conta com Google no site (custta.com.br ou PWA) entra no app do
iPhone com a mesma conta, e quem chega pelo app pode escolher Google. Sucesso:
tocar "Continuar com Google" no app abre a folha do Google, a pessoa escolhe a
conta e cai no mesmo `uid` da web — com "Falta pouco" só se ainda não tiver
perfil. Apagar conta Google no app funciona sem senha.

## Decisões

- **Plugin nativo `@capawesome/capacitor-google-sign-in` (0.1.4, MIT).** Mesmo
  autor do plugin da Apple e do de push já usados; Capacitor 8 com Swift
  Package Manager; ~180 linhas de Swift sobre o SDK oficial `GoogleSignIn-iOS`
  8.x. Devolve `idToken` e perfil. Descartados: `@capgo/capacitor-social-login`
  (MPL e traz o SDK do Facebook) e `@capacitor-firebase/authentication` (SDK
  nativo do Firebase Auth inteiro, o mesmo motivo do PR da Apple).
- **Nenhuma configuração nova fora do repositório.** O cliente OAuth iOS já
  existe (o `GoogleService-Info.plist` de 25/09 traz `CLIENT_ID` e
  `REVERSED_CLIENT_ID`, porque o Google já estava ligado no Firebase). O ID do
  cliente web, que o plugin exige em `initialize`, é público (vai na URL de
  todo login do Google na web) e foi lido do `accounts:createAuthUri`:
  `111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com`.
  Mesmo número de projeto (`111188093030`) do `messagingSenderId`: o Firebase
  aceita o `idToken` sem lista de clientes externos.
- **O SDK JavaScript continua dono da sessão**, como na Apple: o plugin só
  devolve o `idToken`; `cloud.js` entra com
  `signInWithCredential(GoogleAuthProvider.credential(idToken))`. Mesmo `uid`
  da web, porque o Firebase identifica a conta Google pelo `sub`, que é o mesmo
  em qualquer cliente do projeto.
- **Sem nonce.** O plugin não aceita nonce e o Firebase não exige no Google.
- **Sem escopos extras** em `initialize`: `openid email profile` (padrão do
  SDK) bastam; nada de access token guardado.
- **Ordem dos botões no app:** Apple em cima, Google embaixo (a Apple pede o
  dela com destaque igual ou maior). É a mesma ordem da web; só deixa de
  esconder o Google no nativo.
- **"Falta pouco" igual ao da web para Google:** nome e sobrenome
  pré-preenchidos com o nome do Google + "como conheceu". A regra de não pedir
  nome vale só para Apple.
- **Sair esquece o Google no aparelho:** depois do `signOut` do Firebase (sair
  e apagar conta), `GoogleSignIn.signOut()` limpa o estado que o SDK do Google
  guarda no keychain. Melhor esforço: falha vai pro diagnóstico e não segura a
  saída.
- **Sem revogação do Google ao apagar a conta.** A Guideline 5.1.1(v) exige
  revogar só o token do Sign in with Apple; o plugin nem expõe `disconnect`.
- **Sem mudança nas rules nem no formato do estado.**

## Fluxos

### Entrar com Google — app iOS

1. Botões Apple e Google visíveis nas abas Entrar e Criar conta.
2. `CLOUD.entrarGoogle()` no nativo chama
   `OBRA_NATIVO.entrarGoogle({ clientId: GOOGLE_CLIENT_ID_WEB })`.
3. `nativo.js` chama `GoogleSignIn.initialize({ clientId })` uma vez por
   abertura do app (a promessa fica guardada; se falhar, a próxima tentativa
   chama de novo) e então `GoogleSignIn.signIn()`.
4. Com o `idToken`, `signInWithCredential(auth,
   GoogleAuthProvider.credential(idToken))`. O resto (perfil pendente, "Falta
   pouco", travas, fila) é o caminho de sempre do `onAuthStateChanged`.
5. Como no `entrarApple`, `entrarGoogle` **propaga** o erro.
   `SIGN_IN_CANCELED` vira `auth/user-cancelled` (sem mensagem e sem
   diagnóstico); outra falha vai para `OBRA_DIAG` (`nativo-google`) e sobe.
   Resposta sem `idToken` vira `auth/invalid-credential`.

A web (navegador e PWA) não muda: popup, ou redirect no PWA instalado.

### Conta só Google no app

- `reautenticar()` com provedor `google.com` no nativo: plugin de novo +
  `reauthenticateWithCredential`. Escolher outra conta na folha do Google dá
  `auth/user-mismatch`, que o diálogo de conta já trata. Na web segue
  `reauthenticateWithPopup`.
- Conta com Apple **e** Google continua confirmando pela Apple (regra atual de
  `provedorDaConta`).
- "Apagar conta" não pede senha; texto "você vai entrar com o Google de novo"
  (já existe em `ui-confirm.js`).

### Sair

`logout` e `apagarConta`, depois do `signOut`/`deleteUser` do Firebase, chamam
`OBRA_NATIVO.sairGoogle()` (só no nativo; `chama` já engole e registra erro).
Vale para qualquer conta: o SDK do Google sem sessão ignora o `signOut`.

## Configuração iOS

`ios/App/App/Info.plist`:

- `GIDClientID` = `CLIENT_ID` do `GoogleService-Info.plist`
  (`111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h.apps.googleusercontent.com`).
- `CFBundleURLTypes` com o esquema `REVERSED_CLIENT_ID`
  (`com.googleusercontent.apps.111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h`).
  Sem ele o SDK do Google lança exceção Objective-C ao abrir o login e o app
  fecha — por isso tem teste de unidade conferindo os dois valores contra o
  `GoogleService-Info.plist`.

O `Package.swift` do CapApp-SPM ganha o pacote pelo `npm run cap:sync` (a CI
falha se o arquivo versionado divergir). O SPM resolve `GoogleSignIn-iOS` 8.x
junto do `firebase-ios-sdk` 12 do plugin de push (dependências comuns:
`AppCheckCore` 11, `GTMSessionFetcher` 3+, `GoogleUtilities` 8); quem confere é
o `ios-build.yml`. O SDK do Google traz o próprio `PrivacyInfo.xcprivacy`, que declara mais tipos de dado que os
labels atuais (telefone, localização aproximada, IDs e dados de uso); a decisão sobre os
labels fica para antes da submissão, registrada em `docs/app-store-metadados.md`.
Entitlements e perfil de assinatura não mudam.

## Erros

`OBRA_CADASTRO.mensagemErroSocial(code, 'google.com')` já cobre: cancelado
(nada), `network-request-failed`, `account-exists-with-different-credential`
e o genérico "Não deu certo entrar com o Google. Tente de novo."; o
`user-mismatch` da reautenticação é do diálogo de conta (`ui-confirm.js`), que
já cita o provedor. Erros do SDK do Google chegam sem código conhecido e caem no genérico
(o detalhe fica no diagnóstico). Nenhum texto novo.

## Arquivos

| Arquivo | Muda |
| --- | --- |
| `nativo.js` | `entrarGoogle({ clientId })` (initialize uma vez, signIn, cancelamento normalizado, erro propagado) e `sairGoogle()` |
| `cloud.js` | `GOOGLE_CLIENT_ID_WEB`, `credencialGoogleNativa()`, ramo nativo em `entrarGoogle` e em `reautenticar`, `sairGoogle` depois de sair/apagar |
| `auth.js` | deixa de esconder `#btnGoogle` no nativo |
| `sw.js` | `CACHE` → `obras-v60` |
| `package.json` / `package-lock.json` | `@capawesome/capacitor-google-sign-in` ^0.1.4 em devDependencies |
| `ios/App/CapApp-SPM/Package.swift` | pacote e produto `CapawesomeCapacitorGoogleSignIn` (via `cap sync`) |
| `ios/App/App/Info.plist` | `GIDClientID` e `CFBundleURLTypes` |
| `docs/sdks-fase4.md` | linha do plugin |
| `docs/app-store-metadados.md` | nota de revisão: Google também no app, Apple como opção equivalente (4.8), apagar conta Google |
| `CLAUDE.md` | uma linha sobre o plugin e o fluxo Google no nativo |

`privacidade.html` não muda: já diz que dá para entrar "com sua conta Google",
e o app recebe do Google o mesmo que a web (identificador, e-mail, nome).

## Testes

- **Unidade (`tests/nativo.test.cjs`):** `entrarGoogle` fora do app devolve
  `null`; no app chama `initialize` com o client web uma vez só em dois logins
  e depois `signIn`; `initialize` que falha é tentado de novo no login
  seguinte; `SIGN_IN_CANCELED` vira `auth/user-cancelled` sem diagnóstico;
  outra falha sobe e registra `nativo-google`; `sairGoogle` chama `signOut` e
  não propaga erro.
- **Unidade (`tests/capacitor.test.cjs`):** plugin no `package.json` e no
  `Package.swift`; `GIDClientID` e o esquema de URL do `Info.plist` iguais a
  `CLIENT_ID`/`REVERSED_CLIENT_ID` do `GoogleService-Info.plist`; client web
  do `cloud.js` no formato `NNN-xxx.apps.googleusercontent.com` com o mesmo
  número de projeto do `messagingSenderId`.
- **Unidade existente:** `privacidade.test.cjs` exige o SDK listado em
  `sdks-fase4.md`.
- **Navegador (emuladores), `tests/browser/google.cjs` ganha a parte do app**
  (stub de `window.Capacitor` com plugin `GoogleSignIn` falso; `id_token` em
  JSON aceito pelo Auth emulator, como em `apple.cjs`):
  - Apple e Google visíveis, Apple em cima;
  - desistir não mostra erro e não registra diagnóstico;
  - primeiro login: `initialize` com o client web, "Falta pouco" com nome do
    Google pré-preenchido, perfil gravado;
  - sair chama `GoogleSignIn.signOut`; entrar de novo com o mesmo `sub` cai
    no mesmo `uid`, direto, sem "Falta pouco";
  - apagar conta só Google: reautentica pelo plugin (segundo `signIn`), não
    chama `accounts:revokeToken`, remove documentos e usuário.
- **`tests/browser/apple.cjs`:** no app o Google passa a estar visível.
- **agent-browser na prévia da Vercel:** tela de login com stub de
  `window.Capacitor` (app simulado) em iPhone 16 Pro, escuro e claro — Apple e
  Google visíveis, mesma largura e altura, Apple em cima; sem stub (web) igual
  a antes; desktop 1440 sem mudança.
- **iOS:** `ios-build.yml` verde (SPM resolve o SDK do Google com o Firebase);
  build do TestFlight da branch disparado à mão (`workflow_dispatch` — o
  `Info.plist` não está no filtro de caminhos do workflow). O login com conta
  Google de verdade só dá para testar no iPhone, pelo TestFlight: é do Giovani.

## Fora de escopo

- Ligar Google a uma conta existente (Apple ou senha) em Ajustes.
- Login com Google no Android (não há app Android).
- Verificação da marca no Google Cloud (só muda o nome mostrado na folha de
  consentimento; não bloqueia o login).
