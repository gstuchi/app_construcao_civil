# Banco na Nuvem (Firebase) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Login e dados na nuvem (Firebase Auth + Firestore), tempo real entre aparelhos, offline funcionando, migração dos dados locais antigos.

**Architecture:** `cloud.js` (ES module) encapsula todo o Firebase e expõe `window.CLOUD`; `auth.js` vira e-mail+senha usando essa API; `app.js` troca localStorage por `CLOUD.saveDados`/`CLOUD.watchDados` — um documento `dados/{uid}` com o blob inteiro, snapshot em tempo real re-renderiza. Spec: `docs/superpowers/specs/2026-07-05-banco-nuvem-firebase-design.md`.

**Tech Stack:** Firebase JS SDK v10 modular via CDN gstatic (ESM), vanilla JS, Playwright (Edge) pra e2e.

## Global Constraints

- Plano Spark (grátis). Sem bundler, sem npm no app — SDK via `https://www.gstatic.com/firebasejs/10.12.2/...`.
- Um documento por usuário: `dados/{uid}` (blob `{obras, config}`), `perfis/{uid}` (`{email, cpf, criado}`).
- Cada usuário só acessa o próprio documento (rules com `request.auth.uid == uid`).
- Textos de UI em português.
- `calc.js` e seus 18 testes intocados.
- Commits com `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Branch: `nuvem-firebase`.

---

### Task 0: Setup manual do Firebase (usuário, guiado)

**Files:** nenhum — console do Firebase.

**Interfaces:**
- Produces: objeto `firebaseConfig` (apiKey, authDomain, projectId, etc.) que a Task 1 cola em `cloud.js`.

- [ ] **Step 1:** Usuário cria projeto em https://console.firebase.google.com (nome sugerido: `minhas-obras`). Desativar Google Analytics (não precisa).
- [ ] **Step 2:** Build → Authentication → Get started → Sign-in method → ativar **Email/Password** (só a primeira chave; não ativar "email link").
- [ ] **Step 3:** Build → Firestore Database → Create database → modo **production** → região `southamerica-east1` (São Paulo).
- [ ] **Step 4:** Aba Rules do Firestore → colar e publicar:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /dados/{uid}  { allow read, write: if request.auth != null && request.auth.uid == uid; }
    match /perfis/{uid} { allow read, write: if request.auth != null && request.auth.uid == uid; }
    match /{document=**} { allow read, write: if false; }
  }
}
```

- [ ] **Step 5:** Engrenagem → Project settings → Your apps → ícone `</>` (Web) → registrar app `minhas-obras-web` (sem hosting) → copiar o objeto `firebaseConfig` e colar no chat.
- [ ] **Step 6:** Authentication → Settings → Authorized domains → adicionar o domínio da Vercel (ex: `seu-app.vercel.app`). `localhost` já vem liberado.

---

### Task 1: `cloud.js` + carregamento no HTML + service worker

**Files:**
- Create: `cloud.js`
- Modify: `index.html` (bloco de scripts, ~linha 394)
- Modify: `sw.js`

**Interfaces:**
- Produces: `window.CLOUD` com:
  - `ready: Promise<void>`
  - `user(): {uid,email}|null`
  - `onAuth(cb)` — cb(user|null) no login/logout e no boot
  - `signup(email, senha, cpf): Promise<void>` (erros: throw com `.code` do Firebase)
  - `login(email, senha): Promise<void>`
  - `logout(): Promise<void>`
  - `resetSenha(email): Promise<void>`
  - `watchDados(cb): unsubscribe` — cb(blob|null, {fromCache, pendingWrites}) em cada snapshot do doc do usuário logado
  - `saveDados(blob): void` — grava com debounce 300 ms
  - `importarSeVazio(blob): Promise<boolean>` — grava só se doc na nuvem não existe/está vazio; true se importou

- [ ] **Step 1: Criar `cloud.js`** (colar o `firebaseConfig` real da Task 0 no topo):

```js
/* Nuvem (Firebase): auth + Firestore. Único arquivo que fala com o Firebase.
   Expõe window.CLOUD pros scripts clássicos (auth.js, app.js). */
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js';
import {
  getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, sendPasswordResetEmail, signOut,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager,
  doc, setDoc, getDoc, onSnapshot, serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';

const firebaseConfig = {
  /* COLE AQUI o objeto do console (Task 0, Step 5) */
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = initializeFirestore(app, {
  localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
});

let currentUser = null;
const authCbs = [];
let readyResolve;
const ready = new Promise(r => { readyResolve = r; });

onAuthStateChanged(auth, u => {
  currentUser = u ? { uid: u.uid, email: u.email } : null;
  readyResolve();
  authCbs.forEach(cb => cb(currentUser));
});

let saveTimer = null, pendingBlob = null;
function flushSave(){
  if(!pendingBlob || !currentUser) return;
  const blob = pendingBlob; pendingBlob = null;
  setDoc(doc(db, 'dados', currentUser.uid),
    { ...blob, _atualizado: serverTimestamp() }).catch(()=>{ pendingBlob = pendingBlob || blob; });
}

window.CLOUD = {
  ready,
  user: () => currentUser,
  onAuth(cb){ authCbs.push(cb); ready.then(()=>cb(currentUser)); },

  async signup(email, senha, cpf){
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email, cpf, criado: new Date().toISOString() });
  },
  login: (email, senha) => signInWithEmailAndPassword(auth, email, senha).then(()=>{}),
  logout: () => { pendingBlob = null; return signOut(auth); },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  watchDados(cb){
    if(!currentUser) return () => {};
    return onSnapshot(doc(db, 'dados', currentUser.uid),
      { includeMetadataChanges: false },
      snap => {
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites });
      });
  },
  saveDados(blob){
    pendingBlob = JSON.parse(JSON.stringify(blob));
    clearTimeout(saveTimer);
    saveTimer = setTimeout(flushSave, 300);
  },
  async importarSeVazio(blob){
    if(!currentUser) return false;
    const snap = await getDoc(doc(db, 'dados', currentUser.uid));
    const d = snap.data();
    if(d && d.obras && d.obras.length) return false;
    await setDoc(doc(db, 'dados', currentUser.uid),
      { ...blob, _atualizado: serverTimestamp() });
    return true;
  },
};
window.dispatchEvent(new Event('cloud-pronto'));
```

- [ ] **Step 2: Carregar como módulo no `index.html`** — trocar o bloco de scripts:

```html
<script src="globe.js"></script>
<script type="module" src="cloud.js"></script>
<script defer src="auth.js"></script>
<script defer src="calc.js"></script>
<script defer src="app.js"></script>
```

(`defer` garante ordem e que rodem depois do parse; o módulo `cloud.js` também é deferred e roda antes dos `defer` seguintes por vir primeiro na lista.)

**Atenção:** essa garantia de ordem entre module e defer não é assegurada por spec em todos os browsers antigos — por isso auth.js/app.js só usam `CLOUD` dentro de handlers/`cloud-pronto` (ver Tasks 2-3), nunca no topo do arquivo.

- [ ] **Step 3: Service worker** — em `sw.js`, não interceptar chamadas externas (CDN/Firestore) e bumpar cache:

```js
/* Service worker — cache offline. Bump CACHE ao mudar arquivos. */
const CACHE = 'obras-v4';
const ASSETS = ['./', './index.html', './app.js', './auth.js', './globe.js', './calc.js', './cloud.js', './manifest.json', './icon.svg'];
```

e no handler de fetch, primeira linha do listener:

```js
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (!e.request.url.startsWith(self.location.origin)) return; // Firebase/CDN direto na rede
  ...resto igual...
});
```

- [ ] **Step 4: Verificar** — servir local (`npx serve` ou `python -m http.server`) e abrir no browser: console sem erro, `window.CLOUD` definido, `CLOUD.user()` null.

- [ ] **Step 5: Commit**

```bash
git add cloud.js index.html sw.js
git commit -m "feat: modulo cloud.js com Firebase auth+firestore"
```

---

### Task 2: `auth.js` — e-mail + senha + esqueci minha senha

**Files:**
- Modify: `index.html` (form de login, ~linhas 248-258)
- Rewrite: `auth.js`

**Interfaces:**
- Consumes: `window.CLOUD` (Task 1): `onAuth`, `login`, `signup`, `resetSenha`, `logout`.
- Produces: tela destravada/travada via `body.locked` + `#auth.hidden` (mesmo contrato visual de hoje). `app.js` NÃO depende de auth.js — escuta `CLOUD.onAuth` direto.

- [ ] **Step 1: Form de login no `index.html`** — trocar campo CPF por e-mail e adicionar link de reset:

```html
          <form id="fLogin" novalidate>
            <div class="field"><label for="lEmail">E-mail</label>
              <input id="lEmail" type="email" autocomplete="username" placeholder="voce@email.com"></div>
            <div class="field"><label for="lSenha">Senha</label>
              <div class="pw-wrap">
                <input id="lSenha" type="password" autocomplete="current-password" placeholder="Sua senha">
                <button type="button" class="pw-eye" data-eye="lSenha" aria-label="Mostrar senha">👁</button>
              </div></div>
            <div class="auth-msg" id="lMsg" role="alert"></div>
            <button class="btn primary" style="width:100%" type="submit">Entrar</button>
            <button class="linklike" type="button" id="lEsqueci">Esqueci minha senha</button>
          </form>
```

e no CSS do index.html (junto dos estilos de auth):

```css
.linklike{background:none;border:none;color:var(--brand);font-size:13px;cursor:pointer;width:100%;margin-top:10px;text-decoration:underline}
```

- [ ] **Step 2: Reescrever `auth.js`** (mantém máscara de CPF, validação de CPF, olho de senha e efeito 3D — copiar do arquivo atual; muda login/cadastro/sair):

```js
/* Tela de entrada — agora com Firebase (e-mail + senha via window.CLOUD).
   CPF vira dado de perfil (validado no cadastro).
   Efeito visual: card 3D que desentorta ao rolar. */
'use strict';
(function(){
  const $ = s => document.querySelector(s);

  /* ---------- CPF (máscara + validação, iguais a antes) ---------- */
  const onlyDigits = s => (s||'').replace(/\D/g,'');
  function maskCPF(v){
    v = onlyDigits(v).slice(0,11);
    if(v.length>9) return v.replace(/(\d{3})(\d{3})(\d{3})(\d{0,2})/,'$1.$2.$3-$4');
    if(v.length>6) return v.replace(/(\d{3})(\d{3})(\d{0,3})/,'$1.$2.$3');
    if(v.length>3) return v.replace(/(\d{3})(\d{0,3})/,'$1.$2');
    return v;
  }
  function validCPF(cpf){
    cpf = onlyDigits(cpf);
    if(cpf.length!==11 || /^(\d)\1{10}$/.test(cpf)) return false;
    for(const n of [9,10]){
      let s=0;
      for(let i=0;i<n;i++) s += +cpf[i]*(n+1-i);
      if(((s*10)%11)%10 !== +cpf[n]) return false;
    }
    return true;
  }

  /* ---------- trava/destrava ---------- */
  const auth=$('#auth'), sair=$('#btnSair');
  function locked(on){
    auth.classList.toggle('hidden',!on);
    document.body.classList.toggle('locked',on);
    sair.classList.toggle('hidden',on);
  }
  locked(true); // começa travado até o CLOUD dizer quem é

  const doSair=()=>{ if(confirm('Sair da conta?')) CLOUD.logout(); };
  sair.onclick=doSair;
  const sairSide=$('#btnSairSide'); if(sairSide) sairSide.onclick=doSair;

  window.addEventListener('cloud-pronto', ()=>{
    CLOUD.onAuth(u => locked(!u));
  });
  if(window.CLOUD) CLOUD.onAuth(u => locked(!u));

  /* ---------- efeito scroll 3D (igual a antes) ---------- */
  const scroller=$('#authScroll'), card=$('#authCard'), title=$('#authTitle');
  let boost=false;
  const isMobile=()=>window.innerWidth<=768;
  function apply(){
    const vh=scroller.clientHeight||window.innerHeight;
    let p=Math.min(1,scroller.scrollTop/(vh*0.5));
    if(boost)p=1;
    const rot=20*(1-p);
    const [s0,s1]=isMobile()?[0.85,1]:[1.05,1];
    card.style.transform=`rotateX(${rot}deg) scale(${s0+(s1-s0)*p})`;
    title.style.transform=`translateY(${-80*p}px)`;
    title.style.opacity=String(1-0.35*p);
    $('#authHint').style.opacity=String(1-p*1.6);
  }
  scroller.addEventListener('scroll',apply,{passive:true});
  window.addEventListener('resize',apply);
  card.addEventListener('focusin',()=>{ if(!boost){ boost=true; card.classList.add('boost'); title.classList.add('boost'); apply(); } });
  apply();

  /* ---------- tabs ---------- */
  $('#authTabs').querySelectorAll('button').forEach(b=>b.onclick=()=>{
    $('#authTabs').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));
    $('#fLogin').classList.toggle('hidden',b.dataset.k!=='login');
    $('#fCad').classList.toggle('hidden',b.dataset.k!=='cad');
    $('#lMsg').textContent=''; $('#cMsg').textContent='';
  });

  /* ---------- máscara CPF (cadastro) e olho ---------- */
  const cCpf=document.getElementById('cCpf');
  cCpf.addEventListener('input',()=>{ cCpf.value=maskCPF(cCpf.value); });
  document.querySelectorAll('.pw-eye').forEach(b=>b.onclick=()=>{
    const i=document.getElementById(b.dataset.eye);
    i.type = i.type==='password' ? 'text' : 'password';
    b.textContent = i.type==='password' ? '👁' : '🙈';
  });

  /* ---------- erros do Firebase em português ---------- */
  function msgErro(e){
    const c = (e && e.code) || '';
    if(c.includes('invalid-credential') || c.includes('wrong-password') || c.includes('user-not-found'))
      return 'E-mail ou senha incorretos.';
    if(c.includes('email-already-in-use')) return 'Este e-mail já tem conta. Use "Entrar".';
    if(c.includes('invalid-email'))        return 'E-mail inválido.';
    if(c.includes('weak-password'))        return 'Senha fraca: use pelo menos 6 caracteres.';
    if(c.includes('too-many-requests'))    return 'Muitas tentativas. Espere um pouco.';
    if(c.includes('network-request-failed')) return 'Sem internet. Conecte pra entrar.';
    return 'Não deu certo. Tente de novo.';
  }

  /* ---------- login ---------- */
  $('#fLogin').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#lMsg'); msg.textContent='';
    const email=$('#lEmail').value.trim(), senha=$('#lSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='Digite seu e-mail.'; return; }
    if(!senha){ msg.textContent='Digite a senha.'; return; }
    try{ await CLOUD.login(email, senha); }
    catch(err){ msg.textContent=msgErro(err); }
  });

  /* ---------- esqueci minha senha ---------- */
  $('#lEsqueci').onclick=async()=>{
    const msg=$('#lMsg'); msg.textContent='';
    const email=$('#lEmail').value.trim();
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='Digite seu e-mail no campo acima primeiro.'; return; }
    try{ await CLOUD.resetSenha(email); msg.textContent='Enviamos um link de redefinição pro seu e-mail.'; }
    catch(err){ msg.textContent=msgErro(err); }
  };

  /* ---------- cadastro ---------- */
  $('#fCad').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#cMsg'); msg.textContent='';
    const email=$('#cEmail').value.trim(), cpf=onlyDigits($('#cCpf').value), senha=$('#cSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='E-mail inválido.'; return; }
    if(!validCPF(cpf)){ msg.textContent='CPF inválido. Confira os números.'; return; }
    if(senha.length<6){ msg.textContent='Senha precisa de pelo menos 6 caracteres.'; return; }
    try{ await CLOUD.signup(email, senha, cpf); }
    catch(err){ msg.textContent=msgErro(err); }
  });
})();
```

(Nota: senha mínima sobe de 4 pra 6 — exigência do Firebase.)

- [ ] **Step 3: Verificar** — servir local, criar conta de teste, ver usuário aparecer em Authentication no console Firebase, sair, entrar de novo, reset de senha chega no e-mail.

- [ ] **Step 4: Commit**

```bash
git add auth.js index.html
git commit -m "feat: login por e-mail com Firebase Auth e reset de senha"
```

---

### Task 3: `app.js` na nuvem — watchDados/saveDados + tempo real

**Files:**
- Modify: `app.js` (topo, ~linhas 4-49, e rodapé `/* go */`)

**Interfaces:**
- Consumes: `CLOUD.onAuth`, `CLOUD.watchDados`, `CLOUD.saveDados` (Task 1).
- Produces: comportamento — `db` alimentado pela nuvem; `save()` continua sendo a única porta de escrita (nenhuma outra linha do app muda).

- [ ] **Step 1: Trocar estado/boot no topo do `app.js`** — substituir as linhas do `SESSION_CPF`/`KEY`/`load`/`save`:

```js
/* ---------- estado ---------- */
const empty = () => ({obras:[], config:{taxaMensal:1, topicosCustom:[]}});
let db = empty();
let obraAberta = null;   // id da obra no detalhe
let tab = 'inicio';
let unwatch = null;

function normaliza(d){
  return d && typeof d==='object'
    ? {...empty(), ...d, config:{...empty().config, ...(d.config||{})}}
    : empty();
}
function save(){ CLOUD.saveDados(db); renderAll(); }
```

(`save()` agora também re-renderiza; remover os `renderAll()` duplicados logo após `save()` é opcional — chamadas repetidas são inofensivas.)

- [ ] **Step 2: Boot pela nuvem** — substituir o `renderAll();` final (`/* ---------- go ---------- */`):

```js
/* ---------- go: espera auth e liga o tempo real ---------- */
function bootCloud(){
  CLOUD.onAuth(user=>{
    if(unwatch){ unwatch(); unwatch=null; }
    if(!user){ db = empty(); renderAll(); return; }
    unwatch = CLOUD.watchDados((blob, meta)=>{
      if(meta.pendingWrites) return;      // eco da própria escrita
      db = normaliza(blob);
      renderAll();
    });
  });
}
if(window.CLOUD) bootCloud();
else window.addEventListener('cloud-pronto', bootCloud);
renderAll(); // primeiro paint (vazio) enquanto a nuvem responde
```

- [ ] **Step 3: Verificar tempo real** — duas janelas logadas na mesma conta: gasto lançado numa aparece na outra em ~1 s sem recarregar.

- [ ] **Step 4: Commit**

```bash
git add app.js
git commit -m "feat: dados na nuvem com tempo real no app"
```

---

### Task 4: Migração dos dados locais antigos

**Files:**
- Modify: `app.js` (dentro de `bootCloud`, após login)

**Interfaces:**
- Consumes: `CLOUD.importarSeVazio(blob)` (Task 1); chaves legadas `obras_data_v1*` do localStorage.

- [ ] **Step 1: Detectar blob legado e oferecer importação** — em `bootCloud`, logo depois de `if(!user){...}`, antes do `watchDados`:

```js
    // dados antigos deste aparelho (era localStorage por CPF)
    const flagKey = 'obras_migrado_v1::' + user.uid;
    if(!localStorage.getItem(flagKey)){
      const legada = Object.keys(localStorage).filter(k=>k.startsWith('obras_data_v1'))
        .map(k=>{ try{ return JSON.parse(localStorage.getItem(k)); }catch{ return null; } })
        .find(d=>d && d.obras && d.obras.length);
      if(legada){
        CLOUD.importarSeVazio(normaliza(legada)).then(ok=>{
          localStorage.setItem(flagKey,'1');
          if(ok) alert('Encontramos obras salvas neste aparelho e importamos pra sua conta na nuvem. ✅');
        });
      } else {
        localStorage.setItem(flagKey,'1');
      }
    }
```

(Importa sozinho e avisa — só quando a nuvem está vazia; nunca sobrescreve conta que já tem obras. Chaves antigas ficam no aparelho como backup.)

- [ ] **Step 2: Verificar** — semear `localStorage['obras_data_v1::123']` com obra fake, logar com conta nova: alerta de importação aparece e obra surge; logar de novo: não repete; conta com dados na nuvem: não sobrescreve.

- [ ] **Step 3: Commit**

```bash
git add app.js
git commit -m "feat: importa dados locais antigos pra nuvem no primeiro login"
```

---

### Task 5: Verificação end-to-end e deploy

**Files:**
- Create: script Playwright no scratchpad (fora do repo).

- [ ] **Step 1: E2E com Edge headless** contra servidor local (`npx serve .` — Firebase Auth exige http, não file://):
  1. Cadastro com e-mail de teste (`teste+<timestamp>@example.com` — Firebase aceita) → app destrava.
  2. Criar obra, lançar gasto parcelado 3x no cartão → 3 lançamentos.
  3. Segundo contexto de browser, mesma conta → mesmos dados aparecem; lançar gasto no contexto A → aparece no B sem reload (tempo real).
  4. Logout → tela de entrada volta; login → dados persistem.
  5. Migração: semear chave legada, conta nova, ver importação.
  6. Limpar: deletar usuário de teste no console (ou via `CLOUD` deleteUser não exposto — manual, ok).
- [ ] **Step 2: Rodar `node tests/calc.test.cjs`** — Expected: `OK: 18 testes`.
- [ ] **Step 3: Merge na `main` e push** (deploy automático da Vercel). Conferir domínio da Vercel nos Authorized domains (Task 0 Step 6).
- [ ] **Step 4: Teste real no celular + PC**: mesma conta, gasto no celular aparece no PC.
