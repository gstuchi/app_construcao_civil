# Login com Google (web) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** "Continuar com Google" na tela de entrada do Custta web, com tela "Falta pouco" para completar o perfil e conta só Google funcionando em Ajustes.

**Architecture:** `cloud.js` ganha a API do Google (popup/redirect, perfil pendente, completar perfil, reautenticação por popup). `auth.js` + `index.html` mostram o botão (escondido no app nativo) e o formulário "Falta pouco". A Vercel repassa `/__/auth/*` ao Firebase para o `authDomain` ser `custta.com.br`.

**Tech Stack:** Vanilla JS sem build, Firebase JS SDK 12 vendorizado (`vendor/firebase/firebase-auth.js` já exporta `GoogleAuthProvider`, `signInWithPopup`, `signInWithRedirect`, `getRedirectResult`, `reauthenticateWithPopup`), Firestore, Vercel, `node:test`, Playwright + emuladores do Firebase.

**Spec:** `docs/specs/2026-09-23-login-google-design.md`

## Global Constraints

- Tudo em português do Brasil: identificadores, comentários, UI, commits (`feat: ...`, minúsculas, sem acento no assunto).
- Autor único Giovani Stuchi. **Nunca** acrescentar `Co-Authored-By` nem outra linha de coautoria.
- Um commit por task. Nada de `git push` dentro das tasks (o controlador sobe).
- CSP estrita: nada de `<style>`, `style="..."` no HTML, `onclick=` ou JS inline. Cor só por custom property de `styles.css`.
- Não adicionar dependência de runtime ao browser. Nada de `confirm()`/`alert()`.
- Comportamento nativo só via `OBRA_NATIVO.ehNativo()`. O botão Google **não** aparece no app nativo.
- Em `cloud.js`, **não** quebrar as substrings que `tests/browser/*.cjs` substituem: `projectId: 'app-construcao-civil'`, `sendPasswordResetEmail, signOut,`, `deleteField, waitForPendingWrites,`, `const auth = getAuth(app);`, `const CHAVE_LIMPEZA`.
- `perfis/{uid}` não muda de formato; `firestore.rules` não muda.
- Arquivo novo na raiz entra em `sw.js` `ASSETS`.

## Review Focus

1. **Offline/erro ao ler o perfil de conta Google** → o app destrava (não prende a pessoa na tela de login). Teste na Task 3 (`perfilPendente` com falha → `false`).
2. **Conta criada por e-mail que depois entra com Google** (dois provedores) → não vê "Falta pouco", continua vendo "Trocar senha" e "Apagar conta" pede senha. Teste na Task 3 (`temSenha` com `password`+`google.com`) e na Task 6 (browser).
3. **Popup bloqueado ou PWA instalado** → cai no redirect em vez de mostrar erro. Teste na Task 3.
4. **Erro na volta do redirect some com o `locked(true)`** do `onAuth(null)` → a mensagem precisa sobreviver. Teste na Task 6 (evento `cloud-google-erro` → `#lMsg`).
5. **Handler do Firebase servido com a CSP do Custta** → quebraria o login em produção. Teste na Task 2 (regex da fonte dos headers não casa `/__/auth/handler`) e verificação por `curl` na Task 6.

---

## Ondas de execução

- Onda 1 (paralelo): Task 1, Task 2, Task 3 — arquivos disjuntos.
- Onda 2 (paralelo): Task 4, Task 5 — arquivos disjuntos (Task 4: `index.html`, `auth.js`, `styles.css`, `google-g.svg`, `sw.js` ASSETS; Task 5: `app.js`, `ui-confirm.js`).
- Onda 3: Task 6.

---

### Task 1: Regras puras do Google em `cadastro.js`

**Files:**
- Modify: `cadastro.js` (antes de `const api = ...`, e o próprio `api`)
- Test: `tests/cadastro.test.cjs` (acrescentar no fim)

**Interfaces:**
- Produces: `OBRA_CADASTRO.nomeDoGoogle(displayName: string|undefined) → {nome: string, sobrenome: string}`; `OBRA_CADASTRO.mensagemErroGoogle(code: string|undefined) → string` (`''` = não mostrar nada).

- [ ] **Step 1: Write the failing test** (fim de `tests/cadastro.test.cjs`)

```js
test('nomeDoGoogle separa primeira palavra e resto, com espaços limpos',()=>{
  assert.deepEqual(C.nomeDoGoogle('  Ana   Maria  Souza '),{nome:'Ana',sobrenome:'Maria Souza'});
  assert.deepEqual(C.nomeDoGoogle('Ana'),{nome:'Ana',sobrenome:''});
  assert.deepEqual(C.nomeDoGoogle(undefined),{nome:'',sobrenome:''});
  assert.deepEqual(C.nomeDoGoogle(42),{nome:'',sobrenome:''});
});
test('nomeDoGoogle corta nos limites do perfil',()=>{
  const r=C.nomeDoGoogle('A'.repeat(70)+' '+'B'.repeat(90));
  assert.equal(r.nome.length,60); assert.equal(r.sobrenome.length,80);
});
test('mensagemErroGoogle: desistência é silenciosa, o resto em português',()=>{
  for(const c of ['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled'])
    assert.equal(C.mensagemErroGoogle(c),'');
  assert.equal(C.mensagemErroGoogle('auth/account-exists-with-different-credential'),'Este e-mail já tem conta com senha. Entre com e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/unauthorized-domain'),'Login com Google indisponível neste endereço. Use custta.com.br.');
  assert.equal(C.mensagemErroGoogle('auth/operation-not-supported-in-this-environment'),'Seu navegador bloqueou o login com Google. Use e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/web-storage-unsupported'),'Seu navegador bloqueou o login com Google. Use e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/network-request-failed'),'Sem internet. Conecte pra entrar.');
  assert.equal(C.mensagemErroGoogle('auth/too-many-requests'),'Muitas tentativas. Espere um pouco.');
  assert.equal(C.mensagemErroGoogle('auth/qualquer-outro'),'Não deu certo entrar com o Google. Tente de novo.');
  assert.equal(C.mensagemErroGoogle(undefined),'Não deu certo entrar com o Google. Tente de novo.');
  assert.equal(C.mensagemErroGoogle('toString'),'Não deu certo entrar com o Google. Tente de novo.');
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `node --test tests/cadastro.test.cjs`
Expected: FAIL, `C.nomeDoGoogle is not a function`.

- [ ] **Step 3: Implement** (em `cadastro.js`, antes de `const api`)

```js
  /* displayName do Google → nome + sobrenome: primeira palavra é o nome, o resto
     o sobrenome, cortados nos limites. "Falta pouco" deixa a pessoa corrigir. */
  function nomeDoGoogle(displayName){
    const partes = limpa(displayName).split(' ').filter(Boolean);
    return {
      nome: (partes[0] || '').slice(0, LIMITES_PERFIL.nome),
      sobrenome: partes.slice(1).join(' ').slice(0, LIMITES_PERFIL.sobrenome),
    };
  }
  /* '' = a pessoa desistiu (fechou o popup): não é erro pra mostrar. */
  const SEM_GOOGLE = 'Seu navegador bloqueou o login com Google. Use e-mail e senha.';
  const ERROS_GOOGLE = Object.freeze({
    'auth/popup-closed-by-user':'', 'auth/cancelled-popup-request':'', 'auth/user-cancelled':'',
    'auth/account-exists-with-different-credential':'Este e-mail já tem conta com senha. Entre com e-mail e senha.',
    'auth/unauthorized-domain':'Login com Google indisponível neste endereço. Use custta.com.br.',
    'auth/operation-not-supported-in-this-environment':SEM_GOOGLE,
    'auth/web-storage-unsupported':SEM_GOOGLE,
    'auth/network-request-failed':'Sem internet. Conecte pra entrar.',
    'auth/too-many-requests':'Muitas tentativas. Espere um pouco.',
  });
  function mensagemErroGoogle(code){
    return Object.hasOwn(ERROS_GOOGLE, code) ? ERROS_GOOGLE[code] : 'Não deu certo entrar com o Google. Tente de novo.';
  }
```

E trocar a linha do `api` por:

```js
  const api = {REGRAS_SENHA, validaSenha, ORIGENS, LIMITES_PERFIL, normalizaPerfil, normalizaNome, nomeDoGoogle, mensagemErroGoogle};
```

- [ ] **Step 4: Run to verify it passes**

Run: `node --test tests/cadastro.test.cjs`
Expected: PASS (todos).

- [ ] **Step 5: Commit**

```bash
git add cadastro.js tests/cadastro.test.cjs
git commit -m "feat: regras de nome e erros do login com google"
```

---

### Task 2: Infra web — proxy `/__/auth`, CSP, SW e servidor de teste

**Files:**
- Modify: `vercel.json`
- Modify: `scripts/build-www.mjs` (`cspNativa`)
- Modify: `sw.js` (linha 3 `CACHE` e handler `fetch`)
- Modify: `tests/browser/servidor.cjs` (linha do `CUSTTA_EMULADORES`)
- Test: `tests/headers.test.cjs`, `tests/build-www.test.mjs`, `tests/pwa.test.cjs`

**Interfaces:**
- Produces: `vercel.json` com `headers[0].source === "/((?!__/).*)"` (continua sendo `headers[0]` — `build-www` e `servidor.cjs` leem esse índice), `rewrites` para `/__/auth/:path*` e `/__/firebase/:path*`; CSP da web com `https://apis.google.com` em `script-src` e diretiva `frame-src 'self' https://app-construcao-civil.firebaseapp.com`; `cspNativa` sem os dois; servidor de teste com `http://127.0.0.1:9099` em `frame-src` quando `CUSTTA_EMULADORES=1`.

- [ ] **Step 1: Write the failing tests**

Em `tests/headers.test.cjs`, antes do `console.log` final:

```js
const csp = headers['content-security-policy'];
assert.ok(/script-src 'self' https:\/\/apis\.google\.com(;|$)/.test(csp), 'script-src do login com Google');
assert.ok(csp.includes("frame-src 'self' https://app-construcao-civil.firebaseapp.com"), 'frame-src do login com Google');
const fonteApp = new RegExp('^' + vercel.headers[0].source + '$');
assert.ok(fonteApp.test('/') && fonteApp.test('/index.html') && fonteApp.test('/privacidade.html'), 'CSP precisa cobrir o app');
assert.ok(!fonteApp.test('/__/auth/handler') && !fonteApp.test('/__/firebase/init.json'), 'CSP do Custta não pode cobrir o handler do Firebase');
const destinos = Object.fromEntries((vercel.rewrites || []).map(r => [r.source, r.destination]));
assert.strictEqual(destinos['/__/auth/:path*'], 'https://app-construcao-civil.firebaseapp.com/__/auth/:path*');
assert.strictEqual(destinos['/__/firebase/:path*'], 'https://app-construcao-civil.firebaseapp.com/__/firebase/:path*');
```

Em `tests/build-www.test.mjs`, novo teste:

```js
test('cspNativa tira o que só o login com Google da web usa', ()=>{
  const nativa = cspNativa("default-src 'none'; script-src 'self' https://apis.google.com; frame-src 'self' https://app-construcao-civil.firebaseapp.com; connect-src 'self'");
  assert.ok(!nativa.includes('apis.google.com'));
  assert.ok(!nativa.includes('frame-src'));
  assert.ok(nativa.includes("script-src 'self'"));
});
```

Em `tests/pwa.test.cjs`, junto das outras asserções sobre `sw`:

```js
assert.ok(/pathname\.startsWith\('\/__\/'\)\)\s*return/.test(sw), 'service worker não pode interceptar o handler do login (/__/)');
```

- [ ] **Step 2: Run to verify they fail**

Run: `node --test tests/headers.test.cjs tests/build-www.test.mjs tests/pwa.test.cjs`
Expected: FAIL nas três asserções novas.

- [ ] **Step 3: Implement**

`vercel.json`: no primeiro bloco de `headers`, trocar `"source": "/(.*)"` por `"source": "/((?!__/).*)"`. Na CSP, trocar `script-src 'self';` por `script-src 'self' https://apis.google.com;` e inserir `frame-src 'self' https://app-construcao-civil.firebaseapp.com;` logo depois de `connect-src ...;`. Acrescentar no topo do objeto (antes de `"headers"`):

```json
  "rewrites": [
    { "source": "/__/auth/:path*", "destination": "https://app-construcao-civil.firebaseapp.com/__/auth/:path*" },
    { "source": "/__/firebase/:path*", "destination": "https://app-construcao-civil.firebaseapp.com/__/firebase/:path*" }
  ],
```

`scripts/build-www.mjs`, `cspNativa`:

```js
/* <meta> não aceita frame-ancestors, report-uri, sandbox nem upgrade-insecure-requests.
   Produção entra em connect-src para o aviso de versão do app nativo.
   O app nativo não tem login com Google: sai o script do Google e o frame-src. */
export function cspNativa(csp){
  return csp.split(';').map(d => d.trim()).filter(Boolean)
    .filter(d => !/^(frame-ancestors|upgrade-insecure-requests|report-uri|sandbox|frame-src)\b/.test(d))
    .map(d => d.startsWith('connect-src') ? `${d} ${PRODUCAO}` : d)
    .map(d => d.startsWith('script-src') ? d.replace(' https://apis.google.com', '') : d)
    .join('; ');
}
```

`sw.js`: `const CACHE = 'obras-v52';` e, no `fetch`, logo após a linha do `startsWith(self.location.origin)`:

```js
  // /__/auth e /__/firebase são do Firebase (proxy da Vercel): nunca cachear
  // nem responder com index.html no lugar do handler do login com Google.
  if (new URL(e.request.url).pathname.startsWith('/__/')) return;
```

`tests/browser/servidor.cjs`: na linha do `CUSTTA_EMULADORES`, encadear mais um `.replace("frame-src 'self'", "frame-src 'self' http://127.0.0.1:9099")` antes do `.replace('; upgrade-insecure-requests','')`.

- [ ] **Step 4: Run to verify they pass**

Run: `npm run test:unit`
Expected: PASS (toda a suíte, incluindo `docs.test.mjs` e `workflow.test.cjs`).

- [ ] **Step 5: Commit**

```bash
git add vercel.json scripts/build-www.mjs sw.js tests/browser/servidor.cjs tests/headers.test.cjs tests/build-www.test.mjs tests/pwa.test.cjs
git commit -m "chore: proxy do handler do firebase e csp do login com google"
```

---

### Task 3: API do Google em `cloud.js`

**Files:**
- Modify: `cloud.js` (imports, `firebaseConfig`, `onAuthStateChanged`, `reautenticar`, `window.CLOUD`)
- Modify: `tests/helpers/firebase-stub.mjs`
- Create: `tests/google-cloud.test.mjs`
- Modify: `package.json` (`test:unit` ganha `tests/google-cloud.test.mjs`)

**Interfaces:**
- Consumes: nada das outras tasks (grava o perfil que chega já normalizado).
- Produces:
  - `CLOUD.user()` passa a ter `provedores: string[]`, `temSenha: boolean` (`true` se não há `providerData` ou se inclui `'password'`), `nomeExibicao: string`.
  - `CLOUD.entrarGoogle(): Promise<void>` — popup; redirect se PWA instalado ou popup bloqueado; rejeita com `{code}` do Firebase ou `{code:'cache'}`.
  - `CLOUD.perfilPendente(): Promise<boolean>` — `true` só para conta com `'google.com'` cujo `perfis/{uid}` o **servidor** diz que não existe; qualquer falha → `false`.
  - `CLOUD.completarPerfil(perfil: {nome, sobrenome?, origem, origemDetalhe?}): Promise<void>` — cria `perfis/{uid}` com `email`, `criado`, `tz` + perfil; dispara `perfil-alterado`; offline rejeita `{code:'offline'}`.
  - `CLOUD.apagarConta(senha, 'APAGAR', opcoes)` — para `temSenha === false`, reautentica com `reauthenticateWithPopup` (ignora `senha`).
  - Evento `window` `cloud-google-erro` com `detail.code` quando `getRedirectResult` falha.

- [ ] **Step 1: Estender o duplê** (`tests/helpers/firebase-stub.mjs`)

Trocar `initializeApp` e acrescentar exports (o `getRedirectResult` **não** registra em `passos`, senão quebra as asserções exatas de `conta.test.mjs`):

```js
export function initializeApp(config){ __ctrl.config = config; return { nome: 'stub' }; }
export class GoogleAuthProvider{ setCustomParameters(p){ this.parametros = p; } }
export function signInWithPopup(){ return passo('popup'); }
export function signInWithRedirect(){ return passo('redirect'); }
export function reauthenticateWithPopup(){ return passo('reauthPopup'); }
export function getRedirectResult(){
  return __ctrl.falhas.redirectResult ? Promise.reject(__ctrl.falhas.redirectResult) : Promise.resolve(null);
}
export function getDocFromServer(ref){
  __ctrl.passos.push('getServer:'+ref.path);
  if(__ctrl.falhas.getServer) return Promise.reject(__ctrl.falhas.getServer);
  const dados = __ctrl.perfil;
  return Promise.resolve({ exists:()=>dados!==null, data:()=>dados });
}
```

- [ ] **Step 2: Write the failing test** (`tests/google-cloud.test.mjs`)

```js
import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require=createRequire(import.meta.url);
const { __ctrl:ctrl }=await import('./helpers/firebase-stub.mjs');
let cloud, eventos;
async function carregar(){
  await import('../cloud.js?google='+Math.random()); cloud=window.CLOUD; await cloud.ready;
}
const tique=()=>new Promise(r=>setTimeout(r,0));
async function entraComo(providerIds){
  await ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com', emailVerified:true, displayName:'Ana Souza',
    providerData:providerIds.map(providerId=>({providerId})) });
  await tique();
}
beforeEach(async()=>{
  const event=new EventTarget(); eventos=[];
  globalThis.window={ addEventListener:event.addEventListener.bind(event),
    dispatchEvent:e=>{ eventos.push(e); return event.dispatchEvent(e); },
    OBRA_CALC:require('../calc.js'), OBRA_CADASTRO:require('../cadastro.js'),
    location:{ reload:()=>ctrl.passos.push('reload') } };
  globalThis.CustomEvent=globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis,'navigator',{value:{onLine:true},configurable:true});
  ctrl.passos=[]; ctrl.falhas={}; ctrl.respostas=[]; ctrl.pendentesSDK=Promise.resolve();
  ctrl.perfil=null; ctrl.setDocChamadas=[];
  await carregar();
});
afterEach(()=>{ delete globalThis.matchMedia; delete globalThis.location; });

test('authDomain é o próprio host só em custta.com.br',async()=>{
  assert.equal(ctrl.config.authDomain,'app-construcao-civil.firebaseapp.com');
  globalThis.location={hostname:'custta.com.br'}; await carregar();
  assert.equal(ctrl.config.authDomain,'custta.com.br');
  globalThis.location={hostname:'app-construcao-civil.vercel.app'}; await carregar();
  assert.equal(ctrl.config.authDomain,'app-construcao-civil.firebaseapp.com');
});
test('user() expõe provedores, temSenha e nome do Google',async()=>{
  await entraComo(['google.com']);
  assert.deepEqual(cloud.user().provedores,['google.com']);
  assert.equal(cloud.user().temSenha,false);
  assert.equal(cloud.user().nomeExibicao,'Ana Souza');
  await entraComo(['password','google.com']);
  assert.equal(cloud.user().temSenha,true);
  await ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com' }); await tique();
  assert.equal(cloud.user().temSenha,true, 'sem providerData conta como senha');
  assert.deepEqual(cloud.user().provedores,[]);
});
test('entrarGoogle usa popup na aba e redirect no PWA instalado',async()=>{
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['popup']);
  ctrl.passos=[]; globalThis.matchMedia=q=>({matches:q==='(display-mode: standalone)'});
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['redirect']);
});
test('popup bloqueado cai no redirect; outro erro sobe',async()=>{
  ctrl.falhas.popup={code:'auth/popup-blocked'};
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['popup','redirect']);
  ctrl.passos=[]; ctrl.falhas.popup={code:'auth/popup-closed-by-user'};
  await assert.rejects(cloud.entrarGoogle(),{code:'auth/popup-closed-by-user'});
  assert.deepEqual(ctrl.passos,['popup']);
});
test('falha na volta do redirect vira evento cloud-google-erro',async()=>{
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-google-erro');
  assert.ok(ev); assert.equal(ev.detail.code,'auth/account-exists-with-different-credential');
});
test('perfilPendente: só conta Google, lendo do servidor, falha não trava',async()=>{
  assert.equal(await cloud.perfilPendente(),false);
  assert.ok(!ctrl.passos.some(p=>p.startsWith('getServer')), 'conta por e-mail nem consulta');
  await entraComo(['google.com']);
  assert.equal(await cloud.perfilPendente(),true);
  assert.ok(ctrl.passos.includes('getServer:perfis/u-teste'));
  ctrl.perfil={nome:'Ana'};
  assert.equal(await cloud.perfilPendente(),false);
  ctrl.perfil=null; ctrl.falhas.getServer={code:'unavailable'};
  assert.equal(await cloud.perfilPendente(),false);
});
test('completarPerfil grava perfil completo e avisa perfil-alterado',async()=>{
  await entraComo(['google.com']);
  await cloud.completarPerfil({nome:'Ana',sobrenome:'Souza',origem:'instagram'});
  const g=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(g.dados.email,'teste@exemplo.com');
  assert.equal(g.dados.nome,'Ana'); assert.equal(g.dados.sobrenome,'Souza'); assert.equal(g.dados.origem,'instagram');
  assert.ok(g.dados.tz); assert.ok(g.dados.criado);
  assert.ok(eventos.some(e=>e.type==='perfil-alterado'));
  navigator.onLine=false;
  await assert.rejects(cloud.completarPerfil({nome:'Ana',origem:'instagram'}),{code:'offline'});
});
test('apagar conta só Google reautentica por popup, não por senha',async()=>{
  await entraComo(['google.com']);
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthPopup');
  assert.ok(!ctrl.passos.includes('reauth'));
  assert.ok(ctrl.passos.includes('deleteUser'));
});
test('conta com senha e Google continua reautenticando por senha',async()=>{
  await entraComo(['password','google.com']);
  await cloud.apagarConta('senha','APAGAR');
  assert.equal(ctrl.passos[0],'reauth');
});
```

Acrescentar `tests/google-cloud.test.mjs` ao fim da lista de `test:unit` em `package.json`.

- [ ] **Step 3: Run to verify it fails**

Run: `node --test tests/google-cloud.test.mjs`
Expected: FAIL (`cloud.entrarGoogle is not a function`, `authDomain` errado etc.).

- [ ] **Step 4: Implement** (`cloud.js`)

Imports — acrescentar uma linha no bloco de `firebase-auth.js`, depois de `sendEmailVerification, reload,`:

```js
  GoogleAuthProvider, signInWithPopup, signInWithRedirect, getRedirectResult, reauthenticateWithPopup,
```

e no bloco do Firestore trocar `doc, setDoc, getDoc, updateDoc,` por `doc, setDoc, getDoc, getDocFromServer, updateDoc,`.

`firebaseConfig` — trocar a linha do `authDomain`:

```js
  /* Em custta.com.br o handler do login com Google vem do próprio domínio (a
     Vercel repassa /__/auth ao Firebase). Com firebaseapp.com o Safari, que
     isola armazenamento de terceiros, perde a volta do redirect. */
  authDomain: globalThis.location?.hostname === 'custta.com.br' ? 'custta.com.br' : 'app-construcao-civil.firebaseapp.com',
```

Depois de `const auth = getAuth(app);` (linha própria, sem alterar essa):

```js
/* Volta do signInWithRedirect (PWA instalado / popup bloqueado). O usuário
   chega pelo onAuthStateChanged; aqui só interessa o erro, pra tela de login. */
getRedirectResult(auth).catch(err=>{
  window.dispatchEvent(new CustomEvent('cloud-google-erro', { detail:{ code:(err && err.code) || 'desconhecido' } }));
});
function provedorGoogle(){
  const p = new GoogleAuthProvider();
  p.setCustomParameters({ prompt:'select_account' });
  return p;
}
/* PWA instalado no iPhone: o popup abre fora do app e não volta. */
function pwaInstalado(){
  try{ return !!(globalThis.matchMedia?.('(display-mode: standalone)').matches || globalThis.navigator?.standalone); }
  catch{ return false; }
}
```

No `onAuthStateChanged`, trocar a linha do `currentUser = ...` por:

```js
  const provedores = u ? (u.providerData || []).map(p=>p.providerId) : [];
  currentUser = u ? { uid: u.uid, email: u.email, emailVerificado:!!u.emailVerified, provedores,
    // sem providerData (conta antiga/duplê) vale o fluxo com senha de sempre
    temSenha: !provedores.length || provedores.includes('password'),
    nomeExibicao: u.displayName || '' } : null;
```

`reautenticar`:

```js
async function reautenticar(senha){
  const u = usuarioOnline();
  // Conta só Google não tem senha: confirma a identidade no próprio Google.
  if(currentUser?.temSenha === false) await reauthenticateWithPopup(u, provedorGoogle());
  else await reauthenticateWithCredential(u, EmailAuthProvider.credential(u.email, senha));
  if(auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Sessão alterada.'), { code:'cancelled' });
  return u;
}
```

Em `window.CLOUD`, depois de `login: ...`:

```js
  async entrarGoogle(){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    auth.languageCode = 'pt-BR';
    if(pwaInstalado()) return signInWithRedirect(auth, provedorGoogle());
    try{ await signInWithPopup(auth, provedorGoogle()); }
    catch(err){
      if(err?.code === 'auth/popup-blocked') return signInWithRedirect(auth, provedorGoogle());
      throw err;
    }
  },
  /* Só conta Google: o cadastro por e-mail já grava o perfil. Lê do servidor,
     porque cache vazio não prova que o documento não existe. Qualquer falha
     responde "não pendente": travar quem está sem rede é pior que perder a origem. */
  async perfilPendente(){
    const u = auth.currentUser;
    if(!u || !currentUser?.provedores.includes('google.com')) return false;
    try{ return !(await getDocFromServer(doc(db, 'perfis', u.uid))).exists(); }
    catch{ return false; }
  },
  async completarPerfil(perfil){
    const u = usuarioOnline();
    await setDoc(doc(db, 'perfis', u.uid), { email: u.email, criado: new Date().toISOString(), tz: fusoAtual(), ...perfil });
    window.dispatchEvent(new Event('perfil-alterado'));
  },
```

- [ ] **Step 5: Run to verify it passes**

Run: `npm run test:unit`
Expected: PASS em tudo (inclusive `conta.test.mjs`, `cloud-nativo.test.mjs`, `fila.test.mjs`, `push-cloud.test.mjs`).

- [ ] **Step 6: Commit**

```bash
git add cloud.js tests/helpers/firebase-stub.mjs tests/google-cloud.test.mjs package.json
git commit -m "feat(cloud): entrar com google, perfil pendente e reautenticacao por popup"
```

---

### Task 4: Botão "Continuar com Google" e tela "Falta pouco"

**Files:**
- Create: `google-g.svg` (logo "G" oficial, 4 cores, `viewBox="0 0 48 48"`)
- Modify: `index.html` (dentro de `.auth-inner`), `auth.js`, `styles.css` (perto de `.auth-msg`/`.linklike`, ~linha 461), `sw.js` (`ASSETS` ganha `'./google-g.svg'`)
- Test: coberto em browser na Task 6; aqui, verificação com `agent-browser`.

**Interfaces:**
- Consumes: `OBRA_CADASTRO.nomeDoGoogle`, `OBRA_CADASTRO.mensagemErroGoogle`, `OBRA_CADASTRO.normalizaPerfil`, `OBRA_CADASTRO.ORIGENS` (Task 1); `CLOUD.entrarGoogle`, `CLOUD.perfilPendente`, `CLOUD.completarPerfil`, `CLOUD.logout`, `CLOUD.user().provedores/nomeExibicao`, evento `cloud-google-erro` (Task 3).
- Produces (IDs usados pela Task 6): `#authGoogle`, `#btnGoogle`, `#btnGoogleTexto`, `#fPerfil`, `#pNome`, `#pSobrenome`, `#pOrigem`, `#pDetalheWrap`, `#pDetalheLabel`, `#pDetalhe`, `#pMsg`, `#pOutra`.

- [ ] **Step 1: `google-g.svg`** (raiz)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#FFC107" d="M43.6 20.1H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.6-.4-3.9z"/><path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2A11.9 11.9 0 0 1 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.1H42V20H24v8h11.3a12 12 0 0 1-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.6-.4-3.9z"/></svg>
```

Acrescentar `'./google-g.svg'` ao array `ASSETS` de `sw.js` (logo depois de `'./icon-512.png'`). Não mexer no `CACHE` (a Task 2 já subiu para v52 no mesmo deploy).

- [ ] **Step 2: Markup** (`index.html`)

Logo depois do `</div>` de `#authTabs`:

```html
          <div id="authGoogle" class="auth-google">
            <button type="button" class="btn google" id="btnGoogle"><img src="google-g.svg" alt="" width="18" height="18"><span id="btnGoogleTexto">Continuar com Google</span></button>
            <div class="auth-ou" aria-hidden="true"><span>ou</span></div>
          </div>
```

Logo depois do `</form>` de `#fCad`:

```html
          <form id="fPerfil" class="hidden" novalidate>
            <h2 class="auth-perfil-titulo">Falta pouco</h2>
            <p class="auth-perfil-texto">Confirme seu nome e conte como conheceu o Custta.</p>
            <div class="field"><label for="pNome">Nome</label>
              <input id="pNome" type="text" autocomplete="given-name" autocapitalize="words" maxlength="60" placeholder="Seu nome"></div>
            <div class="field"><label for="pSobrenome">Sobrenome <span class="opcional">(opcional)</span></label>
              <input id="pSobrenome" type="text" autocomplete="family-name" autocapitalize="words" maxlength="80" placeholder="Seu sobrenome"></div>
            <div class="field"><label for="pOrigem">Como conheceu o Custta?</label>
              <select id="pOrigem"><option value="">Escolha uma opção</option></select></div>
            <div class="field hidden" id="pDetalheWrap"><label for="pDetalhe" id="pDetalheLabel"></label>
              <input id="pDetalhe" type="text" maxlength="80" autocapitalize="words"></div>
            <div class="auth-msg" id="pMsg" role="alert"></div>
            <button class="layout-19 btn primary" type="submit">Começar a usar</button>
            <button class="linklike" type="button" id="pOutra">Usar outra conta</button>
          </form>
```

- [ ] **Step 3: `auth.js`**

1. `mostrarAba(k)` passa a restaurar o modo normal:

```js
  function mostrarAba(k){
    $('#authTabs').classList.remove('hidden');
    $('#authGoogle').classList.toggle('hidden', !!window.OBRA_NATIVO?.ehNativo());
    $('#fPerfil').classList.add('hidden');
    $('#authTabs').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x.dataset.k===k));
    $('#fLogin').classList.toggle('hidden',k!=='login');
    $('#fCad').classList.toggle('hidden',k!=='cad');
    $('#lMsg').textContent=''; $('#cMsg').textContent=''; $('#pMsg').textContent='';
  }
```

Como `locked(true)` roda antes da definição de `mostrarAba` (hoisting de function declaration resolve), confirmar que `#authGoogle` existe no DOM nesse ponto (o script fica no fim do `<body>`).

2. Trocar o bloco "como conheceu" por uma função reaproveitada nos dois formulários:

```js
  /* ---------- como conheceu (cadastro e "Falta pouco") ---------- */
  function montaOrigem(sel, wrap, label, detalhe){
    for(const o of OBRA_CADASTRO.ORIGENS){
      const op = document.createElement('option'); op.value = o.id; op.textContent = o.nome; sel.append(op);
    }
    sel.addEventListener('change', ()=>{
      const o = OBRA_CADASTRO.ORIGENS.find(x=>x.id===sel.value);
      wrap.classList.toggle('hidden', !o?.detalhe);
      label.textContent = o?.detalhe || '';
      if(!o?.detalhe) detalhe.value = '';
    });
  }
  montaOrigem($('#cOrigem'), $('#cDetalheWrap'), $('#cDetalheLabel'), $('#cDetalhe'));
  montaOrigem($('#pOrigem'), $('#pDetalheWrap'), $('#pDetalheLabel'), $('#pDetalhe'));
```

(apagar `selOrigem`/`mostraDetalhe` antigos; a suíte `tests/browser/cadastro.cjs` precisa continuar passando).

3. `marca` ganha o id da mensagem: `function marca(id, msg, msgId='cMsg'){ const msgEl=$('#'+msgId); ... }` (resto igual).

4. `aoTrocarUsuario` passa a checar o perfil de conta Google:

```js
  /* Conta Google entra sem perfil: fica na tela de entrada até completar.
     `checagem` descarta a resposta se o usuário trocou durante a leitura. */
  let checagem = 0, erroGoogle = '';
  async function aoTrocarUsuario(u){
    const minha = ++checagem;
    if(u){
      jaLogou = true;
      if(u.provedores?.includes('google.com') && await CLOUD.perfilPendente()){
        if(minha === checagem) mostrarPerfil(u);
        return;
      }
      if(minha === checagem) locked(false);
      return;
    }
    const expirou = jaLogou && !saindoDeProposito;
    jaLogou = false; saindoDeProposito = false;
    locked(true); // limpa #lMsg, então a mensagem vem depois
    if(expirou) $('#lMsg').textContent = 'Sua sessão expirou por segurança. Entre de novo pra continuar.';
    else if(erroGoogle){ $('#lMsg').textContent = erroGoogle; }
    erroGoogle = '';
  }
  function mostrarPerfil(u){
    $('#authTabs').classList.add('hidden'); $('#authGoogle').classList.add('hidden');
    $('#fLogin').classList.add('hidden'); $('#fCad').classList.add('hidden');
    $('#fPerfil').classList.remove('hidden');
    const {nome, sobrenome} = OBRA_CADASTRO.nomeDoGoogle(u.nomeExibicao);
    $('#pNome').value = nome; $('#pSobrenome').value = sobrenome; $('#pMsg').textContent = '';
    $('#pOrigem').focus();
  }
```

5. Botão e erro do redirect:

```js
  /* ---------- Google ---------- */
  const btnGoogle = $('#btnGoogle');
  btnGoogle.onclick = async()=>{
    const msg = $('#fCad').classList.contains('hidden') ? $('#lMsg') : $('#cMsg');
    msg.textContent = '';
    const texto = $('#btnGoogleTexto');
    btnGoogle.disabled = true; texto.textContent = 'Abrindo o Google…';
    try{ await CLOUD.entrarGoogle(); }
    catch(err){ msg.textContent = err?.code === 'cache' ? 'Limpe os dados locais antes de entrar.' : OBRA_CADASTRO.mensagemErroGoogle(err?.code); }
    finally{ btnGoogle.disabled = false; texto.textContent = 'Continuar com Google'; }
  };
  /* Erro na volta do redirect. Pode chegar antes do onAuth(null), que limpa
     #lMsg: guarda pra reescrever depois. */
  window.addEventListener('cloud-google-erro', e=>{
    erroGoogle = OBRA_CADASTRO.mensagemErroGoogle(e.detail?.code);
    $('#lMsg').textContent = erroGoogle;
  });
```

6. Formulário "Falta pouco":

```js
  /* ---------- Falta pouco (conta Google sem perfil) ---------- */
  const CAMPO_PERFIL = {nome:'pNome', sobrenome:'pSobrenome', origem:'pOrigem', origemDetalhe:'pDetalhe'};
  $('#fPerfil').addEventListener('input', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fPerfil').addEventListener('change', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fPerfil').addEventListener('submit', async e=>{
    e.preventDefault();
    const msg = $('#pMsg'); msg.textContent = '';
    const r = OBRA_CADASTRO.normalizaPerfil({
      nome:$('#pNome').value, sobrenome:$('#pSobrenome').value,
      origem:$('#pOrigem').value, origemDetalhe:$('#pDetalhe').value,
    });
    if(!r.ok) return marca(CAMPO_PERFIL[r.campo], r.erro, 'pMsg');
    await comLoading(e.target.querySelector('button[type=submit]'), 'Salvando…', async()=>{
      try{ await CLOUD.completarPerfil(r.perfil); locked(false); }
      catch(err){ msg.textContent = err?.code === 'offline' ? 'Conecte à internet para continuar.' : 'Não deu certo salvar. Tente de novo.'; }
    });
  });
  $('#pOutra').onclick = async()=>{
    saindoDeProposito = true;
    try{ await CLOUD.logout(); }
    catch{ saindoDeProposito = false; $('#pMsg').textContent = 'Não foi possível trocar de conta agora. Tente de novo.'; }
  };
```

- [ ] **Step 4: CSS** (`styles.css`, logo depois de `.linklike{...}`), só com variáveis existentes:

```css
  .auth-google{margin-bottom:6px}
  .btn.google{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;
    background:var(--surface-solid);color:var(--text);border:1px solid var(--line-strong)}
  .btn.google:hover{border-color:var(--brand)}
  .btn.google img{flex:none}
  .auth-ou{display:flex;align-items:center;gap:10px;margin:14px 0 10px;color:var(--muted);font-size:12px}
  .auth-ou::before,.auth-ou::after{content:"";flex:1;height:1px;background:var(--line)}
  .auth-perfil-titulo{font-size:20px;margin:0 0 4px;color:var(--text)}
  .auth-perfil-texto{font-size:13.5px;color:var(--muted);margin:0 0 14px}
```

Conferir que `.btn` não força `color`/`background` com especificidade maior (ajustar seletor se precisar). Atender achados do hook `impeccable`, se houver.

- [ ] **Step 5: Verificar**

Run: `npm run test:unit` → PASS.
Run: `node tests/browser/servidor.cjs &` e com `agent-browser` abrir `http://localhost:8123` (390×844 e 1280×800, tema escuro e claro — `localStorage.mo_tema='light'`): botão "Continuar com Google" visível nas duas abas, separador "ou", nenhum erro de console/CSP. Screenshot de cada combinação. Rodar também `node tests/browser/cadastro.cjs` com emuladores (`npx firebase emulators:exec --config firebase.test.json --project demo-custta-phase2 --only firestore,auth "node tests/browser/cadastro.cjs"` com o servidor em `CUSTTA_EMULADORES=1`) → PASS.

- [ ] **Step 6: Commit**

```bash
git add google-g.svg index.html auth.js styles.css sw.js
git commit -m "feat: botao continuar com google e tela falta pouco"
```

---

### Task 5: Conta só Google em Ajustes

**Files:**
- Modify: `app.js` (`renderAjustes`, ~linha 1416)
- Modify: `ui-confirm.js` (`mensagem`, `abrir`)
- Test: `tests/dialogos.test.cjs` (asserção de fonte) + browser na Task 6

**Interfaces:**
- Consumes: `CLOUD.user().temSenha` e `CLOUD.apagarConta(senha, 'APAGAR', opcoes)` que ignora `senha` quando `temSenha === false` (Task 3).
- Produces: `#ajSenha` com classe `hidden` para conta só Google; diálogo de apagar sem `#contaSenha` para conta só Google.

- [ ] **Step 1: Write the failing test** (`tests/dialogos.test.cjs`)

```js
test('conta só Google: sem trocar senha e apagar sem campo de senha', ()=>{
  const app = readFileSync(join(__dirname, '..', 'app.js'), 'utf8');
  assert.match(app, /\$\('#ajSenha'\)\.classList\.toggle\('hidden', conta\?\.temSenha === false\)/);
  const ui = readFileSync(join(__dirname, '..', 'ui-confirm.js'), 'utf8');
  assert.match(ui, /temSenha === false/);
  assert.match(ui, /auth\/popup-blocked/);
  assert.match(ui, /auth\/user-mismatch/);
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `node --test tests/dialogos.test.cjs` → FAIL.

- [ ] **Step 3: Implement**

`app.js`, em `renderAjustes`, depois de `$('#ajSenha').onclick = ...`:

```js
  // Conta só Google não tem senha pra trocar.
  $('#ajSenha').classList.toggle('hidden', conta?.temSenha === false);
```

`ui-confirm.js`, em `mensagem(err)`, antes do `return` final, e trocando a linha do `dadosApagados`:

```js
    if(err.dadosApagados) return CLOUD.user()?.temSenha === false
      ? 'Os dados foram apagados, mas a conta ainda existe. Tente apagar novamente.'
      : 'Os dados foram apagados, mas a conta ainda existe. Digite sua senha e tente apagar novamente.';
    ...
    if(['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled'].includes(err.code)) return 'Confirmação com o Google cancelada.';
    if(err.code === 'auth/popup-blocked') return 'O navegador bloqueou a janela do Google. Permita pop-ups e tente de novo.';
    if(err.code === 'auth/user-mismatch') return 'Entre com a mesma conta Google desta conta.';
```

Em `abrir(tipo)`, para `apagar`:

```js
    const semSenha = apagar && CLOUD.user()?.temSenha === false;
```

e no HTML: o `<p>` do apagar ganha, quando `semSenha`, a frase extra ` Para confirmar, você vai entrar com o Google de novo.`; o `<div class="field">` do `#contaSenha` só é emitido quando `!semSenha`. Em `montaDialogo(... )`: `foco: semSenha ? '#contaConfirmacao' : '#contaSenha'`; em `validar`, `const senha = dlg.querySelector('#contaSenha');` e `const atual = senha ? senha.value : ''; if(senha) senha.value = '';` (o resto igual).

- [ ] **Step 4: Run to verify it passes**

Run: `npm run test:unit` → PASS.

- [ ] **Step 5: Commit**

```bash
git add app.js ui-confirm.js tests/dialogos.test.cjs
git commit -m "feat: conta so google sem trocar senha e apagar com o google"
```

---

### Task 6: Suíte de browser do Google + validação ponta a ponta

**Files:**
- Create: `tests/browser/google.cjs`
- Modify: `tests/browser/rodar.cjs` (rodar `google.cjs` depois de `cadastro.cjs`)
- Modify: `CLAUDE.md` (parágrafo da CSP: `apis.google.com` e `frame-src` existem só para o login com Google da web; `/__/` é proxy do Firebase e fica fora da CSP e do SW)

**Interfaces:**
- Consumes: tudo das Tasks 1–5.

- [ ] **Step 1: Escrever a suíte** (`tests/browser/google.cjs`), no molde de `tests/browser/cadastro.cjs` (mesmo `cloudEmulado()` — copiar a função; mesmo `initializeTestEnvironment`; mesmo registro de violações de CSP; `sessionStorage.splashVista`). O Auth emulator responde ao `signInWithPopup` com uma página própria em `http://127.0.0.1:9099/emulator/auth/handler`: nela, "Add new account" abre um formulário (e-mail, nome de exibição) e "Sign in with Google.com" conclui. Antes de fixar seletores, abrir o popup uma vez e tirar `page.content()` para confirmar os IDs (`#add-account-button`, `#email-input`, `#display-name-input`, `#sign-in` nas versões recentes).

```js
async function entrarGooglePeloEmulador(page, email, nome){
  const [popup] = await Promise.all([page.waitForEvent('popup'), page.locator('#btnGoogle').click()]);
  await popup.waitForLoadState();
  await popup.locator('#add-account-button').click();
  await popup.locator('#email-input').fill(email);
  await popup.locator('#display-name-input').fill(nome);
  await popup.locator('#sign-in').click();
}
```

Casos (cada um com `console.log('ok - ...')`, `assert` estrito):

1. Botão visível nas abas Entrar e Criar conta; `#fPerfil` escondido.
2. Primeiro login Google (`ana.google@example.com`, nome `Ana Maria Souza`) → `#fPerfil` visível, `#pNome` = `Ana`, `#pSobrenome` = `Maria Souza`, `body.locked` ainda presente.
3. Enviar sem origem → `#pMsg` = `Conte como conheceu o Custta.`, foco em `#pOrigem`.
4. Escolher `indicacao`, detalhe `Seu João`, enviar → `body.locked` some; `perfis/{uid}` (lido com `withSecurityRulesDisabled`, gravando em variável externa como em `cadastro.cjs`) tem `nome:'Ana'`, `sobrenome:'Maria Souza'`, `origem:'indicacao'`, `origemDetalhe:'Seu João'`, `email:'ana.google@example.com'`, `tz` e `criado`.
5. Ajustes (`nav.tabs [data-tab="ajustes"]`): `#ajSenha` escondido, `#avisoEmail` escondido, `#ajVerificacao` escondido.
6. Sair e entrar de novo com a mesma conta Google (no popup do emulador, escolher a conta existente pelo e-mail) → destrava direto, sem `#fPerfil`.
7. Apagar conta: `#ajApagar` → diálogo sem `#contaSenha`; digitar `APAGAR`; enviar → popup do emulador de novo (escolher a conta) → documentos `dados`, `perfis`, `push` do uid não existem mais e a tela de login volta.
8. Conta com senha que entra com Google no mesmo e-mail: criar pelo formulário (`dupla@example.com`, `Obra2026x`, nome `Bia`, origem `instagram`), sair, entrar com Google usando `dupla@example.com` → sem `#fPerfil` (perfil já existe) e, em Ajustes, `#ajSenha` **visível** se o Firebase manteve o provedor `password`; se o emulador substituir a conta (e-mail não verificado), registrar no log qual comportamento ocorreu e afirmar apenas que não há `#fPerfil` e que o uid é o mesmo (`CLOUD.user().uid` antes e depois).
9. Erro do redirect: `page.evaluate(()=>window.dispatchEvent(new CustomEvent('cloud-google-erro',{detail:{code:'auth/account-exists-with-different-credential'}})))` com a tela de login aberta → `#lMsg` = `Este e-mail já tem conta com senha. Entre com e-mail e senha.`
10. Modo nativo: novo contexto com `addInitScript(()=>{ window.Capacitor={isNativePlatform:()=>true, getPlatform:()=>'ios'}; })` (conferir em `tests/browser/nativo.cjs` o stub exato que `OBRA_NATIVO.ehNativo()` reconhece e copiar) → `#authGoogle` escondido.
11. Nenhuma violação de CSP e nenhum `pageerror` em toda a suíte.

Adicionar `await run('tests/browser/google.cjs');` depois de `cadastro.cjs` em `tests/browser/rodar.cjs`.

- [ ] **Step 2: Rodar**

Run: `npm run test:browser`
Expected: todas as suítes PASS, incluindo `google.cjs`. Se o popup do emulador precisar de `apis.google.com` e a rede estiver indisponível, registrar e rodar no CI.

- [ ] **Step 3: `agent-browser` local**

Com `CUSTTA_EMULADORES=1 node tests/browser/servidor.cjs` e emuladores de pé, dirigir com `agent-browser` o fluxo 2→4 nos viewports 390×844 e 1280×800, tema escuro e claro; screenshots da tela de entrada e da "Falta pouco". (O app aberto à mão em :8123 fala com a **produção**; para emuladores, usar a rota de `cloud.js` como nas suítes — ver `tests/browser/cadastro.cjs` — ou só inspecionar visual sem logar.)

- [ ] **Step 4: Commit**

```bash
git add tests/browser/google.cjs tests/browser/rodar.cjs CLAUDE.md
git commit -m "test: login com google ponta a ponta no emulador"
```

---

## Depois das tasks (controlador)

1. `npm test` (unit + rules) e `npm run test:browser` verdes.
2. `git push -u origin feat/login-google`, um commit por vez conferindo a CI, abrir PR em português.
3. CI verde → merge → esperar deploy da Vercel.
4. Produção: `curl -sI https://custta.com.br/__/auth/handler` → 200 **sem** a CSP do Custta; `curl -sI https://custta.com.br/` → CSP com `apis.google.com`; `agent-browser` em `https://custta.com.br`: botão visível, clique abre `accounts.google.com` com "Custta" na tela de escolha de conta, sem erro de console/CSP. Não concluir login com conta real.
5. Atualizar a página do Notion "Custta — Estado do projeto" (entrega fechada).
