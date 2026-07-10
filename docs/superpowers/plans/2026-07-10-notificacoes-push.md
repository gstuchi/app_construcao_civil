# Notificações Push — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resumo diário às 18h (Brasília) por notificação push no celular, app fechado: afazeres pendentes, parcelas do mês (dia 1) e lembrete de lançar gastos.

**Architecture:** Web Push padrão (VAPID), sem FCM. Cliente vanilla assina via `pushManager.subscribe` e guarda a inscrição em `push/{uid}` no Firestore (doc separado — `saveDados` reescreve `dados/{uid}` inteiro e apagaria a inscrição do outro aparelho). Cron no GitHub Actions roda script Node (`firebase-admin` + `web-push`) que monta o resumo e envia.

**Tech Stack:** Vanilla JS (PWA, sem build), Firebase Firestore (web SDK 10.12.2 via CDN no cliente; `firebase-admin` no cron), `web-push`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-07-10-notificacoes-push-design.md`

## Global Constraints

- Vanilla only: nenhum framework/build no app; `notificacoes/` é ferramenta de CI, fora do app.
- Copy em PT-BR simples (usuário final: pai do Giovani, não técnico).
- Alvos de toque ≥44px; texto corpo ≥16px.
- Service worker: bump de `obras-v20` pra `obras-v21` (senão celular serve versão velha).
- Título da notificação: `Minhas Obras`. Máximo 1 notificação/dia; nada a dizer = não envia.
- Testes unit: padrão dos existentes — arquivo `.cjs` em `tests/`, rodar com `node tests/<arquivo>.cjs`, helper `t(nome, fn)` + `assert`.
- Convenção de commit: minúsculo, PT-BR, prefixo `feat:`/`fix:`/`docs:`/`test:` (ver `git log`).

---

### Task 1: `montaResumo` (função pura) + unit tests

**Files:**
- Create: `notificacoes/resumo.js`
- Test: `tests/resumo.test.cjs`

**Interfaces:**
- Consumes: nada (função pura).
- Produces: `montaResumo(dados, hojeISO) -> { titulo: string, corpo: string } | null`, exportada via `module.exports = { montaResumo }`. `dados` = blob do Firestore (`{ obras: [...] }`); `hojeISO` = `'YYYY-MM-DD'` no fuso America/Sao_Paulo. Task 2 consome exatamente essa assinatura.

- [ ] **Step 1: Write the failing tests**

Criar `tests/resumo.test.cjs`:

```js
'use strict';
const assert = require('assert');
const { montaResumo } = require('../notificacoes/resumo.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

const obraCom = (extra) => ({ nome: 'Casa 1', fase: 'construcao', gastos: [], ...extra });

t('sem obras: null (nada a dizer, nem lembrete)', () => {
  assert.strictEqual(montaResumo({ obras: [] }, '2026-07-10'), null);
  assert.strictEqual(montaResumo(null, '2026-07-10'), null);
});

t('afazeres pendentes somam entre obras e plural correto', () => {
  const dados = { obras: [
    obraCom({ afazeres: [{ id:'a', texto:'x', feito:false }, { id:'b', texto:'y', feito:true }],
              gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }),
    obraCom({ afazeres: [{ id:'c', texto:'z', feito:false }] }),
  ]};
  const r = montaResumo(dados, '2026-07-10');
  assert.ok(r.corpo.includes('2 afazeres pendentes'), r.corpo);
  assert.strictEqual(r.titulo, 'Minhas Obras');
});

t('1 afazer pendente no singular', () => {
  const dados = { obras: [ obraCom({ afazeres: [{ id:'a', texto:'x', feito:false }],
    gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  const r = montaResumo(dados, '2026-07-10');
  assert.ok(r.corpo.includes('1 afazer pendente'), r.corpo);
  assert.ok(!r.corpo.includes('afazeres'), r.corpo);
});

t('obra antiga sem campo afazeres não quebra', () => {
  const dados = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  assert.strictEqual(montaResumo(dados, '2026-07-10'), null);
});

t('parcelas: só no dia 1, gastos do mês com data >= hoje', () => {
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-15' }, // parcela deste mês
    { id:'g2', valor: 500,  data: '2026-08-01' }, // hoje conta
    { id:'g3', valor: 900,  data: '2026-09-15' }, // mês que vem: fora
    { id:'g4', valor: 100,  data: '2026-07-20' }, // passado: fora
  ]}) ]};
  const r = montaResumo(dados, '2026-08-01');
  assert.ok(r.corpo.includes('2 parcelas vencem este mês (' + BRL.format(1500) + ')'), r.corpo);
});

t('parcelas não aparecem fora do dia 1', () => {
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-15' },
    { id:'g2', valor: 10,   data: '2026-08-02' }, // lançou hoje
  ]}) ]};
  const r = montaResumo(dados, '2026-08-02');
  assert.strictEqual(r, null);
});

t('parcela única no singular', () => {
  // gasto com data == hoje (dia 1): conta como parcela do mês E como "lançou hoje"
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-01' },
  ]}) ]};
  const r = montaResumo(dados, '2026-08-01');
  assert.ok(r.corpo.includes('1 parcela vence este mês (' + BRL.format(1000) + ')'), r.corpo);
  assert.ok(!r.corpo.includes('parcelas'), r.corpo);
});

t('lembrete só quando nenhum gasto com data de hoje', () => {
  const sem = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-09' }] }) ]};
  const com = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  assert.ok(montaResumo(sem, '2026-07-10').corpo.includes('Lançou os gastos de hoje?'));
  assert.strictEqual(montaResumo(com, '2026-07-10'), null);
});

t('lembrete só se existe obra em construção', () => {
  const dados = { obras: [ obraCom({ fase: 'vendida', gastos: [{ id:'g1', valor: 10, data: '2026-07-01' }] }) ]};
  assert.strictEqual(montaResumo(dados, '2026-07-10'), null);
});

t('linhas na ordem: afazeres, parcelas, lembrete', () => {
  const dados = { obras: [ obraCom({
    afazeres: [{ id:'a', texto:'x', feito:false }],
    gastos: [{ id:'g1', valor: 1000, data: '2026-08-15' }],
  }) ]};
  const r = montaResumo(dados, '2026-08-01');
  const linhas = r.corpo.split('\n');
  assert.strictEqual(linhas.length, 3);
  assert.ok(linhas[0].includes('afazer'));
  assert.ok(linhas[1].includes('parcela'));
  assert.ok(linhas[2].includes('Lançou'));
});

console.log(`\n${n} testes ok`);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `node tests/resumo.test.cjs`
Expected: FAIL — `Cannot find module '../notificacoes/resumo.js'`

- [ ] **Step 3: Write the implementation**

Criar `notificacoes/resumo.js`:

```js
'use strict';
/* Resumo diário das notificações push. Função pura: recebe o blob `dados`
   do Firestore e a data ISO de hoje (fuso America/Sao_Paulo) e devolve
   { titulo, corpo } ou null quando não há nada a dizer (aí não se envia). */

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function montaResumo(dados, hojeISO){
  if(!dados || !Array.isArray(dados.obras) || !dados.obras.length) return null;
  const obras = dados.obras;
  const linhas = [];

  // afazeres não riscados, somando todas as obras (campo é opcional por obra)
  const pend = obras.reduce((s, o) => s + (o.afazeres || []).filter(a => !a.feito).length, 0);
  if(pend > 0) linhas.push(pend === 1 ? '1 afazer pendente' : pend + ' afazeres pendentes');

  // parcelas: só dia 1 — gastos com data dentro do mês corrente ainda não vencidos
  if(hojeISO.slice(8) === '01'){
    const mes = hojeISO.slice(0, 7);
    let qtd = 0, total = 0;
    for(const o of obras) for(const g of (o.gastos || [])){
      if(g.data.slice(0, 7) === mes && g.data >= hojeISO){ qtd++; total += g.valor; }
    }
    if(qtd > 0) linhas.push((qtd === 1 ? '1 parcela vence' : qtd + ' parcelas vencem')
      + ' este mês (' + BRL.format(total) + ')');
  }

  // lembrete de lançar: só se há obra em andamento e nada foi lançado com data de hoje
  const emObra = obras.some(o => o.fase === 'construcao');
  const lancouHoje = obras.some(o => (o.gastos || []).some(g => g.data === hojeISO));
  if(emObra && !lancouHoje) linhas.push('Lançou os gastos de hoje?');

  if(!linhas.length) return null;
  return { titulo: 'Minhas Obras', corpo: linhas.join('\n') };
}

module.exports = { montaResumo };
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node tests/resumo.test.cjs`
Expected: PASS — `10 testes ok`

- [ ] **Step 5: Rodar os testes existentes (regressão)**

Run: `node tests/calc.test.cjs; node tests/icons.test.cjs; node tests/moeda.test.cjs`
Expected: todos `ok`.

- [ ] **Step 6: Commit**

```bash
git add notificacoes/resumo.js tests/resumo.test.cjs
git commit -m "feat: montaResumo do push diario (afazeres, parcelas, lembrete)"
```

---

### Task 2: Script de envio + package.json + workflow do cron

**Files:**
- Create: `notificacoes/envia.js`
- Create: `notificacoes/package.json` (e `package-lock.json` via npm install)
- Create: `.github/workflows/push-diario.yml`

**Interfaces:**
- Consumes: `montaResumo(dados, hojeISO)` de `./resumo.js` (Task 1).
- Consumes (runtime): env vars `FIREBASE_SERVICE_ACCOUNT` (JSON da service account), `VAPID_PUBLIC`, `VAPID_PRIVATE`, `VAPID_SUBJECT` — chegam como secrets do GitHub (Task 6).
- Consumes (dados): docs `push/{uid}` no formato `{ subs: { <chave>: { endpoint, keys:{p256dh,auth}, criado } } }` — escritos pelo app (Task 4/5).
- Produces: nada consumido por outras tasks (ponta final).

- [ ] **Step 1: Criar `notificacoes/package.json`**

```json
{
  "name": "notificacoes",
  "private": true,
  "description": "Cron do resumo diario (GitHub Actions). Ferramenta de CI - nao faz parte do app.",
  "dependencies": {
    "firebase-admin": "^12.7.0",
    "web-push": "^3.6.7"
  }
}
```

- [ ] **Step 2: Instalar deps (gera o lockfile que o `npm ci` do workflow exige)**

Run: `cd notificacoes; npm install`
Expected: `package-lock.json` criado, sem erros.

- [ ] **Step 3: Ignorar node_modules**

Adicionar ao `.gitignore` (raiz):

```text
notificacoes/node_modules/
```

- [ ] **Step 4: Criar `notificacoes/envia.js`**

```js
'use strict';
/* Cron diário (GitHub Actions): pra cada usuário com inscrição em push/{uid},
   lê dados/{uid}, monta o resumo e envia via Web Push. Inscrição morta
   (404/410) é removida. Falha num aparelho não derruba o resto. */

const admin = require('firebase-admin');
const webpush = require('web-push');
const { montaResumo } = require('./resumo.js');

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
});
const db = admin.firestore();

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT,
  process.env.VAPID_PUBLIC,
  process.env.VAPID_PRIVATE
);

// data de hoje no fuso do usuário (cron roda em UTC; en-CA formata YYYY-MM-DD)
const hojeISO = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' })
  .format(new Date());

async function main(){
  const pushDocs = await db.collection('push').get();
  console.log(pushDocs.size + ' usuario(s) com push; hoje = ' + hojeISO);

  for(const pdoc of pushDocs.docs){
    const uid = pdoc.id;
    const subs = (pdoc.data() || {}).subs || {};
    const chaves = Object.keys(subs);
    if(!chaves.length) continue;

    const snap = await db.doc('dados/' + uid).get();
    const resumo = montaResumo(snap.data(), hojeISO);
    if(!resumo){ console.log(uid + ': nada a dizer'); continue; }

    const payload = JSON.stringify(resumo);
    for(const k of chaves){
      const s = subs[k];
      try{
        await webpush.sendNotification({ endpoint: s.endpoint, keys: s.keys }, payload);
        console.log(uid + '/' + k + ': enviado');
      }catch(err){
        if(err.statusCode === 404 || err.statusCode === 410){
          await pdoc.ref.update({ ['subs.' + k]: admin.firestore.FieldValue.delete() });
          console.log(uid + '/' + k + ': inscricao morta, removida');
        }else{
          console.error(uid + '/' + k + ': falha ' + (err.statusCode || err.message));
        }
      }
    }
  }
}

main().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
```

- [ ] **Step 5: Checar sintaxe (sem rede não dá pra rodar de verdade)**

Run: `node --check notificacoes/envia.js`
Expected: sem saída (sintaxe ok).

- [ ] **Step 6: Criar `.github/workflows/push-diario.yml`**

```yaml
name: push-diario
# Resumo diário por Web Push. 21:00 UTC = 18:00 Brasília.
# workflow_dispatch = botão de teste manual na aba Actions.
on:
  schedule:
    - cron: '0 21 * * *'
  workflow_dispatch:

jobs:
  envia:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
        working-directory: notificacoes
      - run: node envia.js
        working-directory: notificacoes
        env:
          FIREBASE_SERVICE_ACCOUNT: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          VAPID_PUBLIC: ${{ secrets.VAPID_PUBLIC }}
          VAPID_PRIVATE: ${{ secrets.VAPID_PRIVATE }}
          VAPID_SUBJECT: ${{ secrets.VAPID_SUBJECT }}
```

- [ ] **Step 7: Rodar testes (regressão)**

Run: `node tests/resumo.test.cjs`
Expected: `10 testes ok`

- [ ] **Step 8: Commit**

```bash
git add notificacoes/envia.js notificacoes/package.json notificacoes/package-lock.json .github/workflows/push-diario.yml .gitignore
git commit -m "feat: cron de envio do push diario via github actions"
```

---

### Task 3: Service worker — handlers de push e clique

**Files:**
- Modify: `sw.js` (bump linha 3 + handlers no fim)

**Interfaces:**
- Consumes: payload JSON `{ titulo, corpo }` enviado pela Task 2.
- Produces: notificação de sistema; clique foca/abre o app.

- [ ] **Step 1: Bump do cache**

Em `sw.js` linha 3, trocar:

```js
const CACHE = 'obras-v20';
```

por:

```js
const CACHE = 'obras-v21';
```

- [ ] **Step 2: Handlers no fim de `sw.js`**

```js
/* Push: o cron diário (GitHub Actions) manda { titulo, corpo } via Web Push. */
self.addEventListener('push', e => {
  let d = {};
  try{ d = e.data.json(); }catch(err){}
  e.waitUntil(self.registration.showNotification(d.titulo || 'Minhas Obras', {
    body: d.corpo || '',
    icon: './icon-192.png',
    badge: './icon-192.png',
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ws => {
      for(const w of ws){ if('focus' in w) return w.focus(); }
      return clients.openWindow('./');
    })
  );
});
```

- [ ] **Step 3: Checar sintaxe**

Run: `node --check sw.js`
Expected: sem saída.

- [ ] **Step 4: Commit**

```bash
git add sw.js
git commit -m "feat: sw mostra notificacao push e abre o app no toque; bump v21"
```

---

### Task 4: `cloud.js` — salvar/remover inscrição no Firestore

**Files:**
- Modify: `cloud.js` (import linha 9-12 + dois métodos no objeto `window.CLOUD`)

**Interfaces:**
- Consumes: Firestore web SDK já importado no arquivo.
- Produces: `CLOUD.savePushSub(chave, sub) -> Promise` e `CLOUD.removePushSub(chave) -> Promise`. `chave` = hash do endpoint (string curta, sem `.` nem `/` — vira nome de campo no Firestore). `sub` = `{ endpoint, keys:{p256dh,auth}, criado }`. Task 5 consome.

- [ ] **Step 1: Adicionar `deleteField` ao import do Firestore**

Trocar (linhas 9-12):

```js
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager,
  doc, setDoc, getDoc, onSnapshot, serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';
```

por:

```js
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager,
  doc, setDoc, getDoc, onSnapshot, serverTimestamp, deleteField,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';
```

- [ ] **Step 2: Métodos novos em `window.CLOUD`**

Depois de `importarSeVazio` (antes do `};` que fecha `window.CLOUD`), adicionar:

```js
  /* Inscrição de push por aparelho. Doc separado de dados/{uid} de propósito:
     saveDados reescreve o blob inteiro e apagaria a inscrição do outro aparelho. */
  savePushSub(chave, sub){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { subs: { [chave]: sub } }, { merge: true });
  },
  removePushSub(chave){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { subs: { [chave]: deleteField() } }, { merge: true });
  },
```

- [ ] **Step 3: Checar sintaxe**

`cloud.js` é ES module com import de URL — `node --check` não serve. A sintaxe é
verificada no browser real na Task 7 (console sem erro). Aqui, só releitura do diff:
import com `deleteField` e os dois métodos antes do `};` que fecha `window.CLOUD`.

- [ ] **Step 4: Commit**

```bash
git add cloud.js
git commit -m "feat: cloud salva e remove inscricao de push em push/{uid}"
```

---

### Task 5: Chaves VAPID + toggle nos Ajustes (UI)

**Files:**
- Modify: `index.html` (CSS do toggle ~linha 118; painel novo antes do painel "Conta" ~linha 615)
- Modify: `app.js` (bloco novo depois do bloco TEMA ~linha 883; bind em `renderAjustes` ~linha 894)

**Interfaces:**
- Consumes: `CLOUD.savePushSub` / `CLOUD.removePushSub` (Task 4); SW registrado em `index.html:651`.
- Produces: constante `VAPID_PUBLICA` (chave real gerada aqui); doc `push/{uid}` no formato que a Task 2 lê.

- [ ] **Step 1: Gerar as chaves VAPID**

Run: `npx web-push generate-vapid-keys`
Expected: imprime `Public Key:` e `Private Key:`.
**Guardar as duas.** A pública entra no código no Step 3. A privada NUNCA entra em arquivo do repo — ela vai pro secret `VAPID_PRIVATE` do GitHub (Task 6). Colar a saída do comando na resposta final pro Giovani configurar os secrets.

- [ ] **Step 2: CSS do estado ligado + painel no `index.html`**

Depois da linha `.tgl-tema:focus-visible{...}` (~linha 118), adicionar:

```css
  .tgl-tema.on .bola{transform:translateX(32px)}
  .tgl-tema.on{border-color:var(--brand)}
```

Antes do painel `<h2>Conta</h2>` (~linha 615), adicionar:

```html
    <div class="panel" id="painelNotif">
      <h2>Notificações</h2>
      <div class="tema-linha">
        <span>Resumo diário (18h)</span>
        <button class="tgl-tema" id="ajNotif" role="switch" aria-checked="false" aria-label="Notificações diárias">
          <span class="bola"></span>
        </button>
      </div>
      <p class="muted-note" id="ajNotifNota">Afazeres pendentes, parcelas do mês e lembrete
      de lançar gastos. Chega mesmo com o app fechado. Vale neste aparelho.</p>
    </div>
```

- [ ] **Step 3: Lógica no `app.js`**

Depois do bloco TEMA (após a função `aplicaTema`, antes de `/* ===== AJUSTES ===== */`), adicionar (trocar `COLE_AQUI_A_CHAVE_PUBLICA` pela chave do Step 1):

```js
/* ===== NOTIFICAÇÕES PUSH — inscrição por aparelho, resumo diário via cron ===== */
const VAPID_PUBLICA = 'COLE_AQUI_A_CHAVE_PUBLICA';
const NOTIF_NOTA_PADRAO = 'Afazeres pendentes, parcelas do mês e lembrete de lançar gastos. '
  + 'Chega mesmo com o app fechado. Vale neste aparelho.';

const pushSuportado = () =>
  'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;

function b64ToU8(b64){
  const pad = '='.repeat((4 - b64.length % 4) % 4);
  const raw = atob((b64 + pad).replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(raw, c => c.charCodeAt(0));
}
/* hash curto do endpoint — vira nome de campo no Firestore (sem . nem /) */
function hashEndpoint(s){
  let h = 5381;
  for(let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) >>> 0;
  return h.toString(36);
}
async function pushAtual(){
  const reg = await navigator.serviceWorker.ready;
  return reg.pushManager.getSubscription();
}
async function ativaPush(){
  const perm = await Notification.requestPermission();
  if(perm !== 'granted') return false;
  const reg = await navigator.serviceWorker.ready;
  const sub = await reg.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: b64ToU8(VAPID_PUBLICA),
  });
  const j = sub.toJSON();
  await CLOUD.savePushSub(hashEndpoint(sub.endpoint),
    { endpoint: j.endpoint, keys: j.keys, criado: new Date().toISOString() });
  return true;
}
async function desativaPush(){
  const sub = await pushAtual();
  if(!sub) return;
  const chave = hashEndpoint(sub.endpoint);
  await sub.unsubscribe();
  await CLOUD.removePushSub(chave);
}
```

Dentro de `renderAjustes()`, logo depois do bloco do `#ajTema` (após o `}` que fecha `if(tg){...}`), adicionar:

```js
  const tgN = $('#ajNotif');
  if(tgN){
    if(!pushSuportado()){
      $('#painelNotif').style.display = 'none';
    }else{
      pushAtual().then(sub => {
        const on = !!sub && Notification.permission === 'granted';
        tgN.classList.toggle('on', on);
        tgN.setAttribute('aria-checked', String(on));
      });
      tgN.onclick = async () => {
        const nota = $('#ajNotifNota');
        nota.textContent = NOTIF_NOTA_PADRAO;
        try{
          const sub = await pushAtual();
          if(sub){
            await desativaPush();
          }else{
            const ok = await ativaPush();
            if(!ok) nota.textContent = 'Permissão negada. Libere as notificações nas configurações do navegador e tente de novo.';
          }
        }catch(err){
          nota.textContent = 'Não deu pra ativar agora. Tente de novo.';
        }
        renderAjustes();
      };
    }
  }
```

- [ ] **Step 4: Checar sintaxe**

Run: `node --check app.js`
Expected: sem saída.

- [ ] **Step 5: Rodar todos os testes (regressão)**

Run: `node tests/resumo.test.cjs; node tests/calc.test.cjs; node tests/icons.test.cjs; node tests/moeda.test.cjs`
Expected: todos `ok`.

- [ ] **Step 6: Commit**

```bash
git add index.html app.js
git commit -m "feat: toggle de notificacoes nos ajustes com inscricao web push"
```

---

### Task 6: README de setup + regras do Firestore (documentação)

**Files:**
- Create: `notificacoes/README.md`

**Interfaces:**
- Consumes: nomes dos secrets usados no workflow (Task 2): `FIREBASE_SERVICE_ACCOUNT`, `VAPID_PUBLIC`, `VAPID_PRIVATE`, `VAPID_SUBJECT`.
- Produces: checklist manual pro Giovani (única pessoa com acesso ao console Firebase e aos secrets do GitHub).

- [ ] **Step 1: Criar `notificacoes/README.md`**

```markdown
# Notificações push — setup manual (uma vez)

O código já está pronto; falta o que só dá pra fazer no console do Firebase
e nas configurações do GitHub. Checklist:

## 1. Secrets no GitHub

Em github.com/gstuchi/app_construcao_civil → Settings → Secrets and
variables → Actions → New repository secret. Criar 4:

| Secret | Valor |
|---|---|
| `VAPID_PUBLIC` | chave pública gerada no `npx web-push generate-vapid-keys` (a mesma da constante `VAPID_PUBLICA` no app.js) |
| `VAPID_PRIVATE` | chave privada do mesmo comando (nunca commitar) |
| `VAPID_SUBJECT` | `mailto:stuchigiovani@gmail.com` |
| `FIREBASE_SERVICE_ACCOUNT` | JSON inteiro da service account (passo 2) |

## 2. Service account do Firebase

Console Firebase → projeto app-construcao-civil → ⚙ Configurações do
projeto → Contas de serviço → Gerar nova chave privada. Baixa um JSON.
Colar o conteúdo inteiro no secret `FIREBASE_SERVICE_ACCOUNT`. Apagar o
arquivo baixado depois.

## 3. Regras do Firestore

Console Firebase → Firestore → Regras. Adicionar junto das regras
existentes (dentro de `match /databases/{database}/documents`):

    match /push/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

Publicar.

## 4. Testar

1. Fazer deploy (push pro main) e abrir o app no celular (PWA instalado).
2. Ajustes → Notificações → ligar o toggle → aceitar a permissão.
3. GitHub → aba Actions → workflow "push-diario" → Run workflow.
4. Notificação "Minhas Obras" chega no celular, mesmo com o app fechado.
   (Se não houver afazer pendente, parcela nem lembrete, o log do workflow
   mostra "nada a dizer" — criar um afazer antes de testar.)

## Avisos

- Cron roda 21:00 UTC = 18h Brasília, com variação de alguns minutos.
- GitHub desativa o cron após 60 dias sem atividade no repo (qualquer
  commit reativa).
- iPhone: só iOS 16.4+ com o PWA instalado na tela inicial.
```

- [ ] **Step 2: Commit**

```bash
git add notificacoes/README.md
git commit -m "docs: setup manual das notificacoes (secrets, service account, rules)"
```

---

### Task 7: Verificação no browser real

**Files:** nenhum (verificação).

- [ ] **Step 1: Servir e abrir o app** — usar a skill `verify` do projeto (Playwright) ou servidor local + browser. Conferir no console: sem erro de sintaxe em `app.js`/`cloud.js`/`sw.js`.

- [ ] **Step 2: Conferir a tela Ajustes** — painel "Notificações" aparece entre "Aparência" e "Conta", pílula desligada, nota legível nos dois temas.

- [ ] **Step 3: Ligar o toggle em localhost** — `localhost` conta como origem segura: permissão pedida, pílula liga (bola desliza), doc `push/{uid}` aparece no Firestore (conferir no console Firebase ou via log). Desligar → entrada some.
Nota: push só funciona com as rules do passo 3 do README publicadas — sem elas o `savePushSub` falha com permission-denied e a nota de erro aparece. Se o Giovani ainda não publicou as rules, validar só até o pedido de permissão e registrar isso na resposta final.

- [ ] **Step 4: Regressão e2e existente** (se houver script no repo) e testes unit todos verdes.

- [ ] **Step 5: Commit final se algo foi ajustado; senão nada.**
