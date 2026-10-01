# Login com Google no iPhone — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** "Continuar com Google" funcionando no app iOS (Capacitor), com a mesma conta da web, reautenticação e saída pelo plugin nativo.

**Architecture:** O plugin `@capawesome/capacitor-google-sign-in` abre a folha nativa do Google e devolve só o `idToken`; `nativo.js` é o único arquivo que toca o plugin (`entrarGoogle`, `sairGoogle`); `cloud.js` transforma o token em `GoogleAuthProvider.credential(idToken)` e entra/reautentica pelo SDK JavaScript do Firebase, que continua dono da sessão. A web não muda.

**Tech Stack:** JavaScript sem build (scripts clássicos + `cloud.js` módulo), Firebase JS SDK 12.18 vendorizado, Capacitor 8 com Swift Package Manager, `node:test`, Playwright + emuladores do Firebase.

**Spec:** `docs/specs/2026-10-01-google-no-iphone-design.md`

## Global Constraints

- Worktree: `/Users/giovanistuchi/Documents/app_construcao_civil/.claude/worktrees/google-iphone`, branch `feat/google-no-iphone`. Node, Java e gh em `~/.local` — comece todo comando com `export PATH=~/.local/bin:~/.local/opt/node/bin:~/.local/opt/jdk21/Contents/Home/bin:$PATH`.
- Commits: autor único `Giovani Stuchi <stuchigiovani@gmail.com>` (já configurado no worktree), **sem** `Co-Authored-By` nem rodapé do Claude. Título `tipo: descrição` em português com acentos; corpo em prosa (1–2 parágrafos) quando não for trivial. Um commit por mudança lógica. Não fazer push.
- Código, comentários e identificadores em português, no estilo do arquivo vizinho (comentário curto explicando o porquê, não o quê).
- Plugin: `@capawesome/capacitor-google-sign-in` `^0.1.4` em **devDependencies** (como o da Apple).
- Client web (público): `111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com`.
- Client iOS (do `GoogleService-Info.plist`): `CLIENT_ID` = `111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h.apps.googleusercontent.com`, `REVERSED_CLIENT_ID` = `com.googleusercontent.apps.111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h`.
- Cancelamento do plugin: `code === 'SIGN_IN_CANCELED'` → erro com `code:'auth/user-cancelled'`, sem diagnóstico. Outra falha: `OBRA_DIAG.registra('nativo-google', …)` e o erro sobe.
- Nada de rules, formato do estado, `privacidade.html`, entitlements ou pbxproj.
- `sw.js`: `CACHE` vai de `'obras-v59'` para `'obras-v60'`.
- Outros agentes podem estar commitando no mesmo worktree ao mesmo tempo: `git add` só dos seus arquivos; se o commit falhar por `index.lock`, espere 2 s e tente de novo.

## Review Focus

- `OBRA_NATIVO` sem `sairGoogle` (stubs antigos de teste, ou web) — sair e apagar conta não podem quebrar: `cloud.js` chama `window.OBRA_NATIVO?.sairGoogle?.()`. Os testes existentes de `conta.test.mjs` e `cloud-nativo.test.mjs` (stubs sem `sairGoogle`) pinam isso; Task 3 roda os dois.
- `initialize` falhando uma vez (ex.: `GIDClientID` ausente) não pode envenenar o login para sempre: a próxima tentativa chama `initialize` de novo (teste na Task 2).
- `GoogleSignIn.signOut` falhando ou travando não segura a saída: `chama` engole e registra, e `cloud.js` não espera o resultado (testes nas Tasks 2 e 3).
- `Info.plist` sem o esquema `REVERSED_CLIENT_ID` derruba o app (exceção do SDK do Google): teste estático compara com o `GoogleService-Info.plist` (Task 1).
- Conta só Google apagada no app: reautentica pelo plugin, **não** chama `accounts:revokeToken` (isso é só Apple) e apaga dados e usuário (testes na Task 3, unidade e navegador).

---

### Task 1: Plugin nativo e configuração iOS

**Files:**
- Modify: `package.json`, `package-lock.json` (via `npm install`)
- Modify: `ios/App/CapApp-SPM/Package.swift` (via `npm run cap:sync`)
- Modify: `ios/App/App/Info.plist`
- Modify: `docs/sdks-fase4.md`
- Test: `tests/capacitor.test.cjs`

**Interfaces:**
- Consumes: nada.
- Produces: plugin Capacitor `GoogleSignIn` disponível no app (`Capacitor.Plugins.GoogleSignIn` com `initialize({ clientId })`, `signIn()` → `{ idToken, userId, email, displayName, givenName, familyName, imageUrl, accessToken, serverAuthCode }`, `signOut()`); erro de cancelamento com `code: 'SIGN_IN_CANCELED'`.

- [ ] **Step 1: Escrever o teste que falha** — acrescentar ao fim de `tests/capacitor.test.cjs`:

```js
test('Google Sign-In: plugin no SPM e Info.plist com o client iOS do GoogleService-Info.plist', ()=>{
  const pkg = JSON.parse(ler('package.json'));
  assert.ok(pkg.devDependencies['@capawesome/capacitor-google-sign-in'], 'plugin no package.json');
  const spm = ler('ios/App/CapApp-SPM/Package.swift');
  assert.match(spm, /\.package\(name: "CapawesomeCapacitorGoogleSignIn", path: "\.\.\/\.\.\/\.\.\/node_modules\/@capawesome\/capacitor-google-sign-in"\)/);
  assert.match(spm, /\.product\(name: "CapawesomeCapacitorGoogleSignIn", package: "CapawesomeCapacitorGoogleSignIn"\)/);
  const google = ler('ios/App/App/GoogleService-Info.plist');
  const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
  const plist = ler('ios/App/App/Info.plist');
  assert.equal(plist.match(/<key>GIDClientID<\/key>\s*<string>([^<]+)<\/string>/)?.[1], valor('CLIENT_ID'));
  // Sem o esquema de URL o SDK do Google lança exceção ao abrir o login e o app fecha.
  const esquemas = plist.match(/<key>CFBundleURLSchemes<\/key>\s*<array>([\s\S]*?)<\/array>/)?.[1] || '';
  assert.ok(esquemas.includes(`<string>${valor('REVERSED_CLIENT_ID')}</string>`), 'esquema REVERSED_CLIENT_ID no Info.plist');
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test --test-name-pattern="Google Sign-In" tests/capacitor.test.cjs`
Expected: FAIL em `plugin no package.json`.

- [ ] **Step 3: Instalar o plugin e sincronizar o SPM**

```bash
npm install --save-dev @capawesome/capacitor-google-sign-in@^0.1.4 --no-audit --no-fund
npm run cap:sync
git status --short
```

Expected: `package.json`/`package-lock.json` e `ios/App/CapApp-SPM/Package.swift` modificados; o `Package.swift` ganha, depois das linhas do `CapawesomeCapacitorAppleSignIn`:

```swift
        .package(name: "CapawesomeCapacitorGoogleSignIn", path: "../../../node_modules/@capawesome/capacitor-google-sign-in")
```
e
```swift
                .product(name: "CapawesomeCapacitorGoogleSignIn", package: "CapawesomeCapacitorGoogleSignIn")
```

O `cap sync` também regenera `www/` e `ios/App/App/public` (ignorados pelo git). Se ele modificar qualquer outro arquivo versionado em `ios/` além do `Package.swift`, confira o diff: a CI roda `npm run cap:sync` + `git diff --exit-code -- ios`, então o que o sync escreve é o que deve ser commitado. Se o `cap sync` falhar nesta máquina (só Command Line Tools, sem Xcode), edite o `Package.swift` à mão com exatamente as duas linhas acima (vírgula na linha anterior) — a CI confere.

- [ ] **Step 4: Info.plist** — em `ios/App/App/Info.plist`, inserir logo depois do par `CFBundleShortVersionString`/`<string>$(MARKETING_VERSION)</string>`:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.googleusercontent.apps.111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h</string>
			</array>
		</dict>
	</array>
```

e logo depois do par `CFBundleVersion`/`<string>$(CURRENT_PROJECT_VERSION)</string>`:

```xml
	<key>GIDClientID</key>
	<string>111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h.apps.googleusercontent.com</string>
```

Conferir que continua XML válido: `plutil -lint ios/App/App/Info.plist` (Expected: `OK`).

- [ ] **Step 5: Registro do SDK** — em `docs/sdks-fase4.md`, na tabela, logo abaixo da linha do `@capawesome/capacitor-apple-sign-in`:

```markdown
| @capawesome/capacitor-google-sign-in | 0.1.4 | iOS (nativo) | token de identidade do Google; e-mail e nome da conta Google (repassados ao Firebase Auth) | conta |
```

(Use a versão que o `npm install` gravou no `package-lock.json`, se não for 0.1.4.)

- [ ] **Step 6: Rodar os testes**

Run: `node --test tests/capacitor.test.cjs tests/privacidade.test.cjs`
Expected: PASS (o `privacidade.test.cjs` exige todo `@capawesome/*` do `package.json` listado em `docs/sdks-fase4.md`).

- [ ] **Step 7: Commit**

```bash
git add package.json package-lock.json ios/App/CapApp-SPM/Package.swift ios/App/App/Info.plist docs/sdks-fase4.md tests/capacitor.test.cjs
git commit -F - <<'EOF'
feat: plugin nativo do Google e client iOS no Info.plist

Prepara o login com Google no app iOS. O @capawesome/capacitor-google-sign-in é
do mesmo autor do plugin da Apple e roda sobre o SDK oficial GoogleSignIn-iOS,
via Swift Package Manager.

O GIDClientID e o esquema de URL vêm do GoogleService-Info.plist, que já traz o
cliente OAuth iOS. Sem o esquema o SDK do Google derruba o app ao abrir o login,
por isso o teste compara os dois arquivos.
EOF
```

---

### Task 2: `OBRA_NATIVO.entrarGoogle` e `sairGoogle`

**Files:**
- Modify: `nativo.js` (dentro de `criar(win)`, perto de `entrarApple`, e no objeto devolvido)
- Test: `tests/nativo.test.cjs`

**Interfaces:**
- Consumes: plugin `GoogleSignIn` (Task 1) via `plugin('GoogleSignIn')` — nos testes, objeto falso.
- Produces:
  - `OBRA_NATIVO.entrarGoogle({ clientId }) → Promise<null | { idToken: string, … }>` — `null` fora do app; rejeita com `{ code:'auth/user-cancelled' }` na desistência; outras falhas sobem como vieram (e vão para `nativo-google` no diagnóstico).
  - `OBRA_NATIVO.sairGoogle() → Promise<true | null>` — nunca rejeita.

- [ ] **Step 1: Escrever os testes que falham** — acrescentar ao fim de `tests/nativo.test.cjs`:

```js
test('entrarGoogle e sairGoogle: fora do app devolvem null', async()=>{
  const n = criar({});
  assert.equal(await n.entrarGoogle({ clientId:'web' }), null);
  assert.equal(await n.sairGoogle(), null);
});

test('entrarGoogle: initialize com o client web uma vez só, depois signIn', async()=>{
  const chamadas = [];
  const resposta = { idToken:'id-google', email:'bia@gmail.com', displayName:'Bia Lima' };
  const { win } = janelaNativa({ GoogleSignIn:{
    initialize:async a=>{ chamadas.push(['initialize', a]); },
    signIn:async()=>{ chamadas.push(['signIn']); return resposta; } } });
  const n = criar(win);
  assert.deepEqual(await n.entrarGoogle({ clientId:'web-id' }), resposta);
  assert.deepEqual(await n.entrarGoogle({ clientId:'web-id' }), resposta);
  assert.deepEqual(chamadas, [['initialize', { clientId:'web-id' }], ['signIn'], ['signIn']]);
});

test('entrarGoogle: initialize que falha é tentado de novo no login seguinte', async()=>{
  let falhar = true;
  const chamadas = [];
  const { win, erros } = janelaNativa({ GoogleSignIn:{
    initialize:async()=>{ chamadas.push('initialize'); if(falhar) throw new Error('GIDClientID is missing from Info.plist.'); },
    signIn:async()=>{ chamadas.push('signIn'); return { idToken:'id' }; } } });
  const n = criar(win);
  await assert.rejects(n.entrarGoogle({ clientId:'web' }), { message:/GIDClientID/ });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-google');
  falhar = false;
  assert.deepEqual(await n.entrarGoogle({ clientId:'web' }), { idToken:'id' });
  assert.deepEqual(chamadas, ['initialize', 'initialize', 'signIn']);
});

test('entrarGoogle: desistência vira auth/user-cancelled sem registrar erro', async()=>{
  const { win, erros } = janelaNativa({ GoogleSignIn:{ initialize:async()=>{},
    signIn:async()=>{ throw Object.assign(new Error('The user canceled the sign-in flow.'), { code:'SIGN_IN_CANCELED' }); } } });
  await assert.rejects(criar(win).entrarGoogle({ clientId:'web' }), { code:'auth/user-cancelled' });
  assert.deepEqual(erros, []);
});

test('entrarGoogle: outra falha sobe e fica no diagnóstico', async()=>{
  const { win, erros } = janelaNativa({ GoogleSignIn:{ initialize:async()=>{},
    signIn:async()=>{ throw new Error('The Internet connection appears to be offline.'); } } });
  await assert.rejects(criar(win).entrarGoogle({ clientId:'web' }), { message:/offline/ });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-google');
});

test('sairGoogle: chama signOut no app e nunca propaga erro', async()=>{
  let saiu = 0;
  const { win } = janelaNativa({ GoogleSignIn:{ signOut:async()=>{ saiu++; } } });
  assert.equal(await criar(win).sairGoogle(), true);
  assert.equal(saiu, 1);
  const falha = janelaNativa({ GoogleSignIn:{ signOut:async()=>{ throw new Error('keychain'); } } });
  assert.equal(await criar(falha.win).sairGoogle(), null);
  assert.equal(falha.erros.length, 1);
  assert.equal(falha.erros[0][0], 'nativo-google');
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/nativo.test.cjs`
Expected: FAIL com `n.entrarGoogle is not a function`.

- [ ] **Step 3: Implementar** — em `nativo.js`, logo depois da função `entrarApple` (antes de `aoSegundoPlano`):

```js
    /* Google Sign-In nativo: o WKWebView não abre o popup do Google. O plugin exige
       initialize (com o client web) antes do signIn; vale uma vez por abertura, e
       se falhar a próxima tentativa chama de novo. Propaga o erro como entrarApple. */
    let googlePronto = null;
    async function entrarGoogle({ clientId } = {}){
      const p = plugin('GoogleSignIn');
      if(!p) return null;
      try{
        if(!googlePronto) googlePronto = Promise.resolve().then(() => p.initialize({ clientId }))
          .catch(err => { googlePronto = null; throw err; });
        await googlePronto;
        return await p.signIn();
      }catch(err){
        if(err && err.code === 'SIGN_IN_CANCELED')
          throw Object.assign(new Error('Login com o Google cancelado.'), { code:'auth/user-cancelled' });
        registra('google', err);
        throw err;
      }
    }
```

e no objeto devolvido por `criar`, trocar a linha

```js
      ehNativo, plugin, compartilharArquivo, aoSegundoPlano, marcarAmbiente, entrarApple,
```
por
```js
      ehNativo, plugin, compartilharArquivo, aoSegundoPlano, marcarAmbiente, entrarApple, entrarGoogle,
      // Esquece a sessão que o SDK do Google guarda no keychain; nunca segura a saída.
      sairGoogle: () => chama('GoogleSignIn', 'signOut', undefined, 'google'),
```

- [ ] **Step 4: Rodar os testes**

Run: `node --test tests/nativo.test.cjs`
Expected: PASS (todos, inclusive os antigos).

- [ ] **Step 5: Commit**

```bash
git add nativo.js tests/nativo.test.cjs
git commit -F - <<'EOF'
feat: ponte nativa do login com Google

OBRA_NATIVO.entrarGoogle chama o plugin do Google (initialize com o client web
uma vez por abertura, depois signIn) e devolve o idToken. Como no entrarApple, o
erro sobe para quem chamou separar desistência de falha; initialize que falha é
tentado de novo no login seguinte, para um erro passageiro não travar o botão até
fechar o app.

sairGoogle esquece a sessão que o SDK do Google guarda no aparelho e, como os
outros wrappers, nunca propaga erro.
EOF
```

---

### Task 3: Google no app pelo `cloud.js` e pela tela de login

Depende das Tasks 1 e 2 (a suíte de navegador usa `OBRA_NATIVO.entrarGoogle`/`sairGoogle` reais com o plugin falso).

**Files:**
- Modify: `cloud.js` (constante do client web perto do `firebaseConfig`; `credencialGoogleNativa` perto de `credencialAppleNativa`; `reautenticar`; `entrarGoogle`; `apagarConta`; `logout`)
- Modify: `auth.js:110` (remove a linha que esconde `#btnGoogle` no nativo)
- Modify: `sw.js:3`
- Modify: `tests/helpers/firebase-stub.mjs` (`GoogleAuthProvider.credential`, passo `reauthGoogle`)
- Test: `tests/google-cloud.test.mjs`, `tests/browser/google.cjs`, `tests/browser/apple.cjs`
- Docs: `CLAUDE.md`, `docs/app-store-metadados.md`

**Interfaces:**
- Consumes: `window.OBRA_NATIVO.entrarGoogle({ clientId }) → { idToken }`, `window.OBRA_NATIVO.sairGoogle()` (Task 2).
- Produces: `CLOUD.entrarGoogle()` funcionando no nativo; `reautenticar` de conta só Google no nativo pelo plugin.

- [ ] **Step 1: Duplê do Firebase** — em `tests/helpers/firebase-stub.mjs`, trocar

```js
export function reauthenticateWithCredential(_u, cred){
  __ctrl.credenciais.push(cred);
  return passo(cred && cred.providerId === 'apple.com' ? 'reauthApple' : 'reauth');
}
export class GoogleAuthProvider{ constructor(){ this.providerId = 'google.com'; } setCustomParameters(p){ this.parametros = p; } }
```
por
```js
export function reauthenticateWithCredential(_u, cred){
  __ctrl.credenciais.push(cred);
  const p = cred && cred.providerId;
  return passo(p === 'apple.com' ? 'reauthApple' : p === 'google.com' ? 'reauthGoogle' : 'reauth');
}
export class GoogleAuthProvider{
  constructor(){ this.providerId = 'google.com'; }
  setCustomParameters(p){ this.parametros = p; }
  static credential(idToken){ return { providerId:'google.com', idToken }; }
}
```

- [ ] **Step 2: Testes de unidade que falham** — em `tests/google-cloud.test.mjs`, acrescentar ao fim (o `beforeEach` do arquivo carrega o `cloud.js` em modo web; estes testes recarregam em modo app):

```js
/* App iOS: OBRA_NATIVO falso com o plugin do Google. ehNativo é lido na importação. */
let pedidosGoogle, respostaGoogle, falhaGoogle;
async function carregarNativo(){
  pedidosGoogle=[]; respostaGoogle={ idToken:'id-google' }; falhaGoogle=null;
  window.OBRA_NATIVO={ ehNativo:()=>true,
    entrarGoogle:async a=>{ pedidosGoogle.push(a); if(falhaGoogle) throw falhaGoogle; return respostaGoogle; },
    sairGoogle:()=>{ ctrl.passos.push('sairGoogle'); return Promise.resolve(true); } };
  Object.assign(ctrl,{ credenciais:[], popups:[], resultadoLogin:{ user:{ uid:'u-teste' } } });
  await carregar();
}
test('app: entrarGoogle usa o plugin com o client web do projeto e entra com a credencial do Google',async()=>{
  await carregarNativo();
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.popups,[]);
  assert.equal(pedidosGoogle.length,1);
  const { clientId }=pedidosGoogle[0];
  // client web do mesmo projeto do Firebase: senão o Firebase recusa o idToken
  assert.match(clientId,/^(\d+)-[a-z0-9]+\.apps\.googleusercontent\.com$/);
  assert.equal(clientId.split('-')[0],ctrl.config.messagingSenderId);
  assert.deepEqual(ctrl.credenciais,[{ providerId:'google.com', idToken:'id-google' }]);
});
test('app: desistir do Google sobe sem tentar entrar',async()=>{
  await carregarNativo();
  falhaGoogle={ code:'auth/user-cancelled' };
  await assert.rejects(cloud.entrarGoogle(),{ code:'auth/user-cancelled' });
  assert.deepEqual(ctrl.credenciais,[]);
});
test('app: Google sem idToken é erro, não login',async()=>{
  await carregarNativo();
  respostaGoogle={ idToken:'' };
  await assert.rejects(cloud.entrarGoogle(),{ code:'auth/invalid-credential' });
  assert.deepEqual(ctrl.credenciais,[]);
});
test('app: apagar conta só Google reautentica pelo plugin, não revoga e esquece o Google',async()=>{
  await carregarNativo();
  let fetchs=0; globalThis.fetch=async()=>{ fetchs++; return { ok:true, status:200 }; };
  await entraComo(['google.com']); ctrl.passos=[]; ctrl.revogados=[];
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthGoogle');
  assert.deepEqual(ctrl.popups,[]);
  assert.equal(fetchs,0,'revogação é só da Apple');
  assert.deepEqual(ctrl.revogados,[]);
  const i=n=>ctrl.passos.indexOf(n);
  assert.ok(i('deleteUser')>=0 && i('deleteUser')<i('sairGoogle'),'esquece o Google depois de apagar o usuário: '+ctrl.passos);
});
test('app: sair esquece o Google depois do signOut do Firebase',async()=>{
  await carregarNativo();
  await entraComo(['google.com']); ctrl.passos=[];
  await cloud.logout();
  const i=n=>ctrl.passos.indexOf(n);
  assert.ok(i('signOut')>=0 && i('signOut')<i('sairGoogle'),'ordem: '+ctrl.passos);
});
test('app: sairGoogle que nunca responde não segura a saída',async()=>{
  await carregarNativo();
  window.OBRA_NATIVO.sairGoogle=()=>new Promise(()=>{});
  await entraComo(['google.com']); ctrl.passos=[];
  await cloud.logout();
  assert.ok(ctrl.passos.includes('signOut'));
});
```

Antes de rodar, confira no arquivo: (a) se `afterEach` precisa limpar `globalThis.fetch` — se outro teste do arquivo depender de `fetch`, salve e restaure; (b) se `cloud.logout()` no duplê precisa de algo que o `beforeEach` já não monte (o `tests/conta.test.mjs:101` mostra o logout rodando no mesmo duplê com passos `['signOut','terminate','clear']`). Ajuste só a preparação do teste, nunca a asserção de ordem.

- [ ] **Step 3: Rodar e ver falhar**

Run: `node --test tests/google-cloud.test.mjs`
Expected: FAIL — o primeiro teste novo abre popup (`ctrl.popups` com 1 item) em vez de chamar o plugin.

- [ ] **Step 4: Implementar no `cloud.js`**

4a. Logo depois do fechamento do objeto `firebaseConfig` (antes de `const app = initializeApp(firebaseConfig);`):

```js
/* Client OAuth web do projeto. É público: vai na URL de todo login do Google na
   web. O plugin nativo do Google exige o client web, e o Firebase aceita o
   idToken porque o client é do mesmo projeto (111188093030). */
const GOOGLE_CLIENT_ID_WEB = '111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com';
```

4b. Logo depois da função `credencialAppleNativa`:

```js
/* Google no app: a folha nativa devolve o idToken e o SDK JavaScript entra com
   ele. O Firebase reconhece a conta pelo sub, o mesmo da web: mesmo uid. */
async function credencialGoogleNativa(){
  const r = await window.OBRA_NATIVO.entrarGoogle({ clientId: GOOGLE_CLIENT_ID_WEB });
  if(!r || !r.idToken) throw Object.assign(new Error('O Google não devolveu a credencial.'), { code:'auth/invalid-credential' });
  return GoogleAuthProvider.credential(r.idToken);
}
```

4c. Em `reautenticar`, trocar

```js
  else if(provedor === 'google.com') await reauthenticateWithPopup(u, provedorGoogle());
```
por
```js
  else if(provedor === 'google.com'){
    if(nativo) await reauthenticateWithCredential(u, await credencialGoogleNativa());
    else await reauthenticateWithPopup(u, provedorGoogle());
  }
```

4d. Em `entrarGoogle`, logo depois de `auth.languageCode = 'pt-BR';`:

```js
    if(nativo){ await signInWithCredential(auth, await credencialGoogleNativa()); return; }
```

4e. Em `apagarConta`, trocar

```js
        try{ await deleteUser(u); }catch(err){ marcaCache(false); throw err; }
        await limparCache();
```
por
```js
        try{ await deleteUser(u); }catch(err){ marcaCache(false); throw err; }
        esquecerGoogle();
        await limparCache();
```

4f. Em `logout`, trocar

```js
        try{ await signOut(auth); }catch(err){ marcaCache(false); throw err; }
        clearTimeout(retryTimer); retryTimer = null;
```
por
```js
        try{ await signOut(auth); }catch(err){ marcaCache(false); throw err; }
        esquecerGoogle();
        clearTimeout(retryTimer); retryTimer = null;
```

4g. Logo depois da função `revogarApple` (antes de `aguardarFila`):

```js
/* Depois de sair (ou apagar a conta) no app, o SDK do Google esquece a sessão que
   guarda no aparelho. Sem await: a limpeza recarrega a página e não pode esperar
   o SDK; sairGoogle nunca rejeita. Na web e em OBRA_NATIVO antigo não faz nada. */
function esquecerGoogle(){
  if(nativo) window.OBRA_NATIVO?.sairGoogle?.();
}
```

- [ ] **Step 5: Rodar os testes de unidade**

Run: `node --test tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/conta.test.mjs tests/cloud-nativo.test.mjs tests/fila.test.mjs`
Expected: PASS.

- [ ] **Step 6: Tela de login** — em `auth.js`, dentro de `mostrarAba`, apagar a linha

```js
    $('#btnGoogle').classList.toggle('hidden', !!window.OBRA_NATIVO?.ehNativo());
```

Em `sw.js`, trocar `const CACHE = 'obras-v59';` por `const CACHE = 'obras-v60';`.

Run: `npm run test:unit`
Expected: PASS.

- [ ] **Step 7: Suíte de navegador do Google — parte do app** — em `tests/browser/google.cjs`:

7a. Trocar `const browser=await chromium.launch();` por

```js
  /* No contexto nativo o documento sai de um route (CSP da <meta> do www/) e o Chromium o trata
     como espaço público: nega (Local Network Access) as chamadas aos emuladores em 127.0.0.1,
     que em produção não existem. A flag desliga só essa checagem, neste navegador de teste. */
  const browser=await chromium.launch({args:['--disable-features=LocalNetworkAccessChecks']});
```

7b. Acrescentar, depois da função `sair` (antes do `(async()=>{`):

```js
/* App nativo: CSP da <meta> do www/ (libera a checagem de versão) e plugin GoogleSignIn
   falso. O id_token em JSON é aceito pelo Auth emulator sem assinatura. Pedidos ficam
   espelhados no sessionStorage porque sair e apagar recarregam a página. */
async function contextoNativo(novoContexto){
  const ctx=await novoContexto();
  await ctx.route(BASE+'/',async r=>{
    const resp=await r.fetch(); const h=resp.headers();
    h['content-security-policy']=h['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://app-construcao-civil.vercel.app");
    await r.fulfill({response:resp,headers:h});
  });
  await ctx.route('https://app-construcao-civil.vercel.app/versao.json',r=>r.fulfill({contentType:'application/json',headers:{'access-control-allow-origin':'*'},body:fs.readFileSync(path.join(ROOT,'versao.json'),'utf8')}));
  await ctx.addInitScript(()=>{
    const registra=p=>{ const l=JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]'); l.push(p); sessionStorage.setItem('__pedidosGoogle',JSON.stringify(l)); };
    window.Capacitor={ isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:{
      GoogleSignIn:{
        initialize:async a=>{ registra(['initialize',a]); },
        signIn:async()=>{ registra(['signIn']); const r=JSON.parse(sessionStorage.getItem('__respostaGoogle')||'null');
          if(r && r.erro) throw Object.assign(new Error(r.erro.message),{code:r.erro.code}); return r; },
        signOut:async()=>{ registra(['signOut']); } } } };
  });
  return ctx;
}
const idTokenGoogle=(sub,email,name)=>JSON.stringify({sub,email,email_verified:true,name});
const pedidosGoogle=page=>page.evaluate(()=>JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]'));
const respostaGoogle=(page,r)=>page.evaluate(r=>sessionStorage.setItem('__respostaGoogle',JSON.stringify(r)),r);
```

7c. Substituir o bloco inteiro `// 10. app nativo (WKWebView) não mostra o Google` (de `{` até o `}` que fecha depois de `await ctxNativo.close();`) por:

```js
    // 10-14. app nativo (WKWebView) com o plugin GoogleSignIn falso
    {
      const ctxNativo=await contextoNativo(novoContexto);
      const pNativo=await abrirApp(ctxNativo);
      assert.equal(await pNativo.evaluate(()=>OBRA_NATIVO.ehNativo()),true);

      // 10. Apple e Google nas duas abas, Apple em cima, mesmo tamanho
      for(const aba of ['cad','login']){
        await pNativo.locator(`#authTabs button[data-k="${aba}"]`).click();
        assert.equal(await pNativo.locator('#btnGoogle').isVisible(),true);
        assert.equal(await pNativo.locator('#btnApple').isVisible(),true);
        const a=await pNativo.locator('#btnApple').boundingBox(), g=await pNativo.locator('#btnGoogle').boundingBox();
        assert.ok(a.y<g.y,`Apple deve ficar acima do Google (${a.y} vs ${g.y})`);
        assert.equal(Math.round(a.width),Math.round(g.width)); assert.equal(Math.round(a.height),Math.round(g.height));
      }
      console.log('ok - app: Google aparece abaixo da Apple, do mesmo tamanho, nas abas Entrar e Criar conta');

      // 11. desistência: nenhum erro na tela, botões voltam
      await respostaGoogle(pNativo,{erro:{code:'SIGN_IN_CANCELED',message:'The user canceled the sign-in flow.'}});
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForFunction(()=>!document.querySelector('#btnGoogle').disabled && JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]').some(p=>p[0]==='signIn'));
      assert.equal(await pNativo.textContent('#lMsg'),'');
      assert.equal(await travado(pNativo),true);
      assert.deepEqual((await pedidosGoogle(pNativo))[0],['initialize',{clientId:'111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com'}]);
      console.log('ok - app: desistir da folha do Google não mostra erro; initialize com o client web');

      // 12. primeiro login no app: "Falta pouco" com o nome do Google
      await respostaGoogle(pNativo,{idToken:idTokenGoogle('google-gabi','gabi.app@example.com','Gabi Souza Lima')});
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForSelector('#fPerfil',{state:'visible'});
      assert.equal(await pNativo.inputValue('#pNome'),'Gabi');
      assert.equal(await pNativo.inputValue('#pSobrenome'),'Souza Lima');
      assert.deepEqual(await pNativo.evaluate(()=>CLOUD.user().provedores),['google.com']);
      await pNativo.selectOption('#pOrigem','instagram');
      await pNativo.locator('#fPerfil button[type=submit]').click();
      await pNativo.waitForFunction(()=>!document.body.classList.contains('locked'));
      const uidGabi=await pNativo.evaluate(()=>CLOUD.user().uid);
      const perfilGabi=(await leDoc('perfis',uidGabi)).data();
      assert.equal(perfilGabi.nome,'Gabi'); assert.equal(perfilGabi.sobrenome,'Souza Lima');
      assert.equal(perfilGabi.email,'gabi.app@example.com');
      console.log('ok - app: primeiro login Google abre "Falta pouco" com o nome do Google e grava o perfil');

      // 13. sair esquece o Google; entrar de novo com a mesma conta cai no mesmo uid, direto
      await sair(pNativo);
      assert.ok((await pedidosGoogle(pNativo)).some(p=>p[0]==='signOut'),'sair deveria chamar GoogleSignIn.signOut');
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForFunction(()=>!document.body.classList.contains('locked'));
      assert.equal(await pNativo.evaluate(()=>CLOUD.user().uid),uidGabi);
      assert.equal(await pNativo.locator('#fPerfil').isVisible(),false);
      console.log('ok - app: sair esquece o Google e voltar com a mesma conta entra direto no mesmo uid');

      // 14. apagar conta só Google no app: reautentica pelo plugin, não revoga, remove tudo
      const revogacoes=[];
      await ctxNativo.route(/accounts:revokeToken/,r=>{ revogacoes.push(r.request().url()); return r.fulfill({status:200,contentType:'application/json',body:'{}'}); });
      const signInsAntes=(await pedidosGoogle(pNativo)).filter(p=>p[0]==='signIn').length;
      await pNativo.locator('nav.tabs [data-tab="ajustes"]').click();
      await pNativo.locator('#ajApagar').click();
      await pNativo.waitForSelector('#contaConfirmacao',{state:'visible'});
      await pNativo.locator('#contaConfirmacao').fill('APAGAR');
      await pNativo.locator('#contaEnviar').click();
      await pNativo.waitForFunction(()=>document.body.classList.contains('locked') && window.CLOUD && !CLOUD.user(),null,{timeout:20000});
      await pNativo.locator('#fLogin').waitFor({state:'visible',timeout:20000});
      for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uidGabi)).exists(),false,`${colecao}/${uidGabi} sobrou`);
      assert.equal((await pedidosGoogle(pNativo)).filter(p=>p[0]==='signIn').length,signInsAntes+1,'reautenticação pelo plugin');
      assert.deepEqual(revogacoes,[],'conta Google não revoga token (isso é só da Apple)');
      console.log('ok - app: apagar conta só Google reautentica pelo plugin, não revoga e remove os dados');
      await ctxNativo.close();
    }
```

Se o Auth emulator não preencher o `displayName` a partir de `name` no `id_token` em JSON, confira na doc do emulador qual claim ele lê (ex.: `name` vs `displayName`/`screen_name`) e ajuste **só** o `idTokenGoogle` — o "Falta pouco" com nome pré-preenchido é o comportamento esperado.

7d. Em `tests/browser/apple.cjs`, no bloco `// 8. desistência`, trocar

```js
      assert.equal(await pNativo.locator('#btnGoogle').isVisible(),false);
```
por
```js
      assert.equal(await pNativo.locator('#btnGoogle').isVisible(),true);
```

- [ ] **Step 8: Rodar as suítes de navegador do login social**

```bash
export PATH=~/.local/bin:~/.local/opt/node/bin:~/.local/opt/jdk21/Contents/Home/bin:$PATH
node tests/browser/servidor.cjs & SERVIDOR=$!
npx firebase emulators:exec --config firebase.test.json --project demo-custta-phase2 --only firestore,auth "node tests/browser/google.cjs && node tests/browser/apple.cjs"
kill $SERVIDOR
```

(O `servidor.cjs` precisa de `CUSTTA_EMULADORES=1` no ambiente se as suítes reclamarem de produção — o `tests/browser/rodar.cjs` sobe ele assim: `CUSTTA_EMULADORES=1 node tests/browser/servidor.cjs &`.)

Expected: todas as linhas `ok - …`, terminando em `ok - nenhuma violação de CSP nem erro de página`, nas duas suítes. Rode duas vezes; se uma falha só aparecer de vez em quando, investigue antes de seguir (a regra do projeto: espera por condição, nunca por tempo fixo).

- [ ] **Step 9: Docs** — em `CLAUDE.md`, na seção "App iOS (Capacitor)", depois da frase que termina em "Services ID da web: `br.com.custta.web`.", acrescentar no mesmo parágrafo:

```markdown
 Login com Google no app: plugin `@capawesome/capacitor-google-sign-in` via `OBRA_NATIVO.entrarGoogle({ clientId })` (client **web** em `GOOGLE_CLIENT_ID_WEB`, no `cloud.js`) + `signInWithCredential`; `GIDClientID` e o esquema `REVERSED_CLIENT_ID` do `Info.plist` vêm do `GoogleService-Info.plist` — sem o esquema o SDK do Google derruba o app. Sair e apagar conta chamam `sairGoogle` (spec `docs/specs/2026-10-01-google-no-iphone-design.md`).
```

Em `docs/app-store-metadados.md`, nas notas de revisão:

- trocar `Sign-in is email and password, or Sign in with Apple, through Firebase Authentication. Sign in with Apple is offered on the login screen. The demo account above uses email and password. Google sign-in exists only on the web version, not in the iOS app.` por `Sign-in is email and password, Sign in with Apple, or Sign in with Google, through Firebase Authentication. Sign in with Apple is offered on the login screen, above Google, as the equivalent login option (Guideline 4.8). The demo account above uses email and password.`
- trocar `It asks for the current password (or, for Apple accounts, a fresh Sign in with Apple)` por `It asks for the current password (or, for Apple or Google accounts, a fresh sign-in with that provider)` e `revokes the Sign in with Apple token and then deletes the authentication account` por `revokes the Sign in with Apple token for Apple accounts and then deletes the authentication account`.

Run: `node --test tests/docs.test.mjs tests/privacidade.test.cjs`
Expected: PASS.

- [ ] **Step 10: Commits** (dois, por mudança lógica)

```bash
git add tests/helpers/firebase-stub.mjs tests/google-cloud.test.mjs cloud.js auth.js sw.js tests/browser/google.cjs tests/browser/apple.cjs
git commit -F - <<'EOF'
feat: login com Google no app do iPhone

Continuação do login com Apple (#27), que deixou o Google escondido no app: o
WKWebView não abre o popup do Google. Agora o botão aparece abaixo da Apple e,
no nativo, o cloud.js pega o idToken pela folha nativa do Google e entra com
signInWithCredential. O Firebase reconhece a conta pelo mesmo sub da web, então
quem criou conta com Google no site entra no app com os mesmos dados.

Conta só Google reautentica pelo plugin para apagar a conta (sem revogação, que
é exigência só do Sign in with Apple), e sair ou apagar a conta faz o SDK do
Google esquecer a sessão guardada no aparelho, sem segurar a saída.
EOF
git add CLAUDE.md docs/app-store-metadados.md
git commit -m "docs: Google no app nas notas de revisão e no guia do projeto"
```

---

## Depois das tasks (controlador)

1. Revisão final da branch inteira (subagente revisor) contra o spec.
2. `npm run test:unit`, `npm run test:rules` e `npm run test:browser` completos no worktree.
3. Push, PR em prosa (sem rodapé do Claude), CI verde (`verificar`, `compilar` iOS — é aqui que o SPM resolve o `GoogleSignIn-iOS` com o `firebase-ios-sdk`).
4. `gh workflow run ios-testflight.yml --ref feat/google-no-iphone` (o `Info.plist` não está no filtro de caminhos) e acompanhar até o upload.
5. agent-browser na prévia da Vercel: tela de login em iPhone 16 Pro, escuro e claro, com stub de `window.Capacitor` (app simulado: Apple e Google visíveis, Apple em cima, mesmo tamanho) e sem stub (web, igual a antes); desktop 1440.
6. Atualizar a nota do Custta no Obsidian e a memória.
