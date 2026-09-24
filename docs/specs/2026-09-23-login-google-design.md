# Login com Google (só web)

Entrar e criar conta com "Continuar com Google" no PWA e no navegador. O app
iOS (Capacitor) fica de fora: lá o Google exige plugin nativo e a Apple exige
Sign in with Apple junto (Guideline 4.8) — os dois dependem da matrícula na
Apple e ficam para a Fase 5.

## Decisões

- **Só web.** O botão some no app nativo (`OBRA_NATIVO.ehNativo()`). Nada muda no
  fluxo da revisão da Apple.
- **Perfil completo também para quem vem do Google.** No primeiro login o app
  pede nome e sobrenome (já preenchidos com o do Google) e "como conheceu"
  (obrigatório), com as mesmas regras do cadastro (`OBRA_CADASTRO.normalizaPerfil`).
- **Popup no navegador, redirect no PWA instalado.** `signInWithPopup` em aba
  comum; `signInWithRedirect` quando `display-mode: standalone` (o popup costuma
  falhar no PWA do iPhone) e como plano B quando o popup é bloqueado.
- **`authDomain` próprio.** O Safari particiona armazenamento de terceiros, o que
  quebra o redirect com `authDomain` em `firebaseapp.com`. Em `custta.com.br` o
  `authDomain` passa a ser o próprio host, e a Vercel repassa `/__/auth/*` e
  `/__/firebase/*` para `app-construcao-civil.firebaseapp.com` (opção de proxy
  reverso da documentação do Firebase). Fora de `custta.com.br` (localhost,
  `*.vercel.app`, app nativo) continua `firebaseapp.com`.
- **Sem mudança nas rules.** `perfis/{uid}` já aceita `nome`, `sobrenome`,
  `origem`, `origemDetalhe` na criação e exige `email == token.email`, que o
  Google preenche.

Configuração externa (feita em 23/09/2026): provedor Google ativo no Firebase
com nome público "Custta"; `https://custta.com.br/__/auth/handler` autorizado
no cliente OAuth web. `custta.com.br` já estava nos domínios autorizados.

## Fluxos

### Entrar com Google
1. Botão "Continuar com Google" no topo das abas Entrar e Criar conta, com
   separador "ou" antes do formulário.
2. `CLOUD.entrarGoogle()`: popup (ou redirect no PWA). Na volta do redirect,
   `getRedirectResult` roda na inicialização do `cloud.js`; erro dele vira
   evento `cloud-google-erro` para a tela de login mostrar.
3. `onAuthStateChanged` segue como hoje. `currentUser` ganha `provedores`
   (lista de `providerId`) e `temSenha`.
4. Conta que já existia com e-mail e senha no mesmo endereço: o Firebase liga
   o Google à mesma conta (mesmo uid, dados preservados). Se ele recusar
   (`auth/account-exists-with-different-credential`), a mensagem manda entrar
   com e-mail e senha. Exceção: conta com senha cujo e-mail **não foi
   verificado** perde o provedor de senha ao entrar com Google no mesmo
   e-mail (política anti-sequestro do Firebase: quem prova o e-mail pelo
   Google fica com a conta). O uid e os dados ficam; dali em diante a pessoa
   entra só pelo Google.

### Completar perfil
1. Só para conta com provedor `google.com`. Ao entrar, `auth.js` chama
   `CLOUD.perfilPendente()`, que lê `perfis/{uid}` primeiro do cache local
   (achou → não pendente, sem esperar a rede) e, se não estiver no cache,
   **do servidor** — cache vazio não prova que o documento não existe.
2. Documento inexistente → a tela de login continua travada e mostra o
   formulário "Falta pouco" (`#fPerfil`): nome, sobrenome (opcional), como
   conheceu (+ detalhe). Nome/sobrenome vêm de `displayName` do Google
   (primeira palavra = nome, resto = sobrenome, cortados nos limites).
3. `CLOUD.completarPerfil(perfil)` cria o documento com `email`, `criado`, `tz`
   e o perfil normalizado; dispara `perfil-alterado` e destrava.
4. Leitura falhou (offline, erro) → não trava: destrava e tenta de novo no
   próximo login. Travar o app de quem está sem rede é pior que perder a origem.
5. "Usar outra conta" sai sem confirmação (não há dado local ainda).
6. Duas abas no "Falta pouco": a segunda a salvar recebe `permission-denied`
   (o `setDoc` vira update e as rules recusam). Se `perfilPendente()` disser
   que o perfil já existe, ela destrava em vez de mostrar erro.

### Conta só Google (sem senha)
- Ajustes esconde "Trocar senha" quando `temSenha` é falso.
- "Apagar conta" não pede senha: o diálogo pede só APAGAR e a reautenticação é
  `reauthenticateWithPopup` com o Google. Popup bloqueado/fechado → mensagem.
  O popup abre antes da trava entre abas (`navigator.locks`), ainda dentro do
  gesto do usuário; depois dos awaits da trava o Safari o bloquearia.
- O aviso de confirmar e-mail não aparece: conta Google já vem verificada.
- Conta com os dois provedores continua pedindo senha como hoje.

## Erros (português)

| Código | Mensagem |
| --- | --- |
| `popup-closed-by-user`, `cancelled-popup-request`, `user-cancelled` | nenhuma (a pessoa desistiu) |
| `popup-blocked` | cai no redirect automaticamente |
| `account-exists-with-different-credential` | Este e-mail já tem conta com senha. Entre com e-mail e senha. |
| `unauthorized-domain` | Login com Google indisponível neste endereço. Use custta.com.br. |
| `operation-not-supported-in-this-environment`, `web-storage-unsupported` | Seu navegador bloqueou o login com Google. Use e-mail e senha. |
| `network-request-failed` | Sem internet. Conecte pra entrar. |

## Infra

- `vercel.json`: `rewrites` de `/__/auth/:path*` e `/__/firebase/:path*`.
  O bloco de headers do app passa a valer para `/((?!__/).*)`, para a CSP do
  Custta não quebrar a página do handler do Firebase.
- CSP do app: `script-src 'self' https://apis.google.com` e
  `frame-src 'self' https://app-construcao-civil.firebaseapp.com`.
- `build-www` (CSP do app nativo) retira `apis.google.com` e `frame-src`.
- `sw.js`: ignora `/__/` (nunca cachear nem servir `index.html` no lugar do
  handler) e bump de `CACHE`.

## Testes

- Unit: separação de nome do Google, mensagens de erro, CSP da web e da
  nativa, rewrites e fonte dos headers, `sw.js` ignorando `/__/`.
- Browser (emuladores; o Auth emulator simula o popup do Google):
  primeiro login Google → "Falta pouco" com nome preenchido → origem
  obrigatória → app destravado e `perfis/{uid}` gravado; segundo login entra
  direto; conta só Google não vê "Trocar senha" nem aviso de e-mail; apagar
  conta Google apaga documentos e usuário; botão ausente no modo nativo.
- `agent-browser` no servidor local (390×844 e 1280×800, tema escuro e claro)
  e em `custta.com.br` após o deploy: botão visível, popup abre o Google com
  o nome Custta, handler do proxy responde 200.
