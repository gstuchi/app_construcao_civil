# Minhas Obras — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pivotar o app de finanças pessoais para controle de custos por obra com valor corrigido (custo de oportunidade) e lucro na venda, conforme `docs/superpowers/specs/2026-07-04-obras-design.md`.

**Architecture:** Mantém a casca aprovada (globo, auth, tokens CSS, PWA). Novo módulo puro `calc.js` (correção composta, totais, lucro) testável em Node. `app.js` reescrito: 3 views (Início, Detalhe da obra, Ajustes) renderizadas por JS em containers do `index.html`.

**Tech Stack:** Vanilla JS (sem build), localStorage, SVG/CSS para gráficos, Node só para rodar testes do `calc.js`.

## Global Constraints

- Vanilla only: zero framework, zero build, zero rede em runtime.
- Copy 100% PT-BR, linguagem simples (usuário não técnico).
- Texto corpo ≥16px, números-chave ≥24px, toque ≥44px, `font-variant-numeric: tabular-nums` em valores.
- Dados por usuário: chave `obras_data_v1::<CPF>` (sessão de `finance_session_v1`, inalterada). Dados antigos `finance_data_v1*` ficam órfãos — não apagar, não migrar.
- Taxa de correção guardada como **percentual** (`1` = 1% a.m.), padrão 1.
- Correção composta pró-rata dia: `valor × (1 + taxa/100)^(dias/30.44)`; congela na data da venda.
- `auth.js` e `globe.js`: não modificar.
- Service worker: bump de cache a cada task que muda arquivos servidos (feito de uma vez na Task 6).

---

### Task 1: `calc.js` — cálculos puros com testes em Node

**Files:**
- Create: `calc.js`
- Test: `tests/calc.test.cjs`

**Interfaces:**
- Produces: global `OBRA_CALC` (browser) e `module.exports` (Node) com:
  - `diasEntre(deISO, ateISO) -> number` (≥0)
  - `corrigido(valor, dataISO, ateISO, taxaPct) -> number`
  - `totalBruto(obra) -> number`
  - `totalCorrigido(obra, taxaPct, hojeISO) -> number` (usa `obra.venda?.data` como fim se existir)
  - `lucroVenda(obra, taxaPct) -> {bruto, vsBanco} | null`
  - `mesesDeObra(obra, hojeISO) -> number`
  - Formato de `obra`: `{dataInicio, venda?:{data,valor}, gastos:[{valor,data}]}`

- [ ] **Step 1: Escrever testes que falham** — criar `tests/calc.test.cjs`:

```js
'use strict';
const assert = require('assert');
const C = require('../calc.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }
const perto = (a, b, tol) => assert.ok(Math.abs(a - b) <= tol, `esperado ~${b}, veio ${a}`);

t('diasEntre básico', () => {
  assert.strictEqual(C.diasEntre('2026-07-04', '2026-07-04'), 0);
  assert.strictEqual(C.diasEntre('2026-07-04', '2026-07-05'), 1);
  assert.strictEqual(C.diasEntre('2026-07-05', '2026-07-04'), 0); // nunca negativo
});

t('corrigido: mesmo dia = valor bruto', () => {
  assert.strictEqual(C.corrigido(10000, '2026-07-04', '2026-07-04', 1), 10000);
});

t('corrigido: taxa zero = valor bruto', () => {
  assert.strictEqual(C.corrigido(10000, '2026-07-04', '2027-07-04', 0), 10000);
});

t('corrigido: 30 dias a 1% ≈ +0,986%', () => {
  // 1.01^(30/30.44) = 1.0098551
  perto(C.corrigido(10000, '2026-07-04', '2026-08-03', 1), 10098.55, 0.05);
});

t('corrigido: exemplo canônico da spec (~6 meses)', () => {
  // 04/07/2026 → 04/01/2027 = 184 dias = 6.0447 meses → 1.01^6.0447
  perto(C.corrigido(10000, '2026-07-04', '2027-01-04', 1), 10619.93, 0.5);
});

t('corrigido cresce com o tempo', () => {
  const a = C.corrigido(5000, '2026-01-01', '2026-06-01', 1);
  const b = C.corrigido(5000, '2026-01-01', '2026-12-01', 1);
  assert.ok(b > a && a > 5000);
});

const obraAberta = {
  dataInicio: '2026-01-01',
  gastos: [
    { valor: 100000, data: '2026-01-01' },
    { valor:  50000, data: '2026-06-01' },
  ],
};

t('totalBruto soma gastos', () => {
  assert.strictEqual(C.totalBruto(obraAberta), 150000);
});

t('totalCorrigido > totalBruto quando há tempo passado', () => {
  const tc = C.totalCorrigido(obraAberta, 1, '2026-07-04');
  assert.ok(tc > 150000);
});

t('totalCorrigido congela na venda', () => {
  const vendida = { ...obraAberta, venda: { data: '2026-07-01', valor: 300000 } };
  const noDiaDaVenda = C.totalCorrigido(vendida, 1, '2026-07-01');
  const muitoDepois  = C.totalCorrigido(vendida, 1, '2027-07-01'); // hoje não importa
  perto(muitoDepois, noDiaDaVenda, 0.001);
});

t('lucroVenda: null sem venda, bruto e vsBanco com venda', () => {
  assert.strictEqual(C.lucroVenda(obraAberta, 1), null);
  const vendida = { ...obraAberta, venda: { data: '2026-07-01', valor: 300000 } };
  const l = C.lucroVenda(vendida, 1);
  assert.strictEqual(l.bruto, 150000);
  assert.ok(l.vsBanco < l.bruto && l.vsBanco > 0);
});

t('mesesDeObra usa venda como fim quando vendida', () => {
  perto(C.mesesDeObra(obraAberta, '2026-07-04'), 184 / 30.44, 0.01);
  const vendida = { ...obraAberta, venda: { data: '2026-04-01', valor: 1 } };
  perto(C.mesesDeObra(vendida, '2027-01-01'), 90 / 30.44, 0.01);
});

console.log(`OK: ${n} testes`);
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/calc.test.cjs`
Expected: FAIL — `Cannot find module '../calc.js'`

- [ ] **Step 3: Implementar `calc.js`**

```js
/* Cálculos puros de obra — sem DOM. Carregado no browser (global OBRA_CALC)
   e nos testes em Node (module.exports). */
'use strict';
(function(root){
  const DIAS_MES = 30.44;
  const MS_DIA = 86400000;

  function diasEntre(deISO, ateISO){
    const de = new Date(deISO + 'T00:00:00');
    const ate = new Date(ateISO + 'T00:00:00');
    return Math.max(0, Math.round((ate - de) / MS_DIA));
  }
  function corrigido(valor, dataISO, ateISO, taxaPct){
    return valor * Math.pow(1 + taxaPct / 100, diasEntre(dataISO, ateISO) / DIAS_MES);
  }
  function fimCorrecao(obra, hojeISO){
    return (obra.venda && obra.venda.data) || hojeISO;
  }
  function totalBruto(obra){
    return obra.gastos.reduce((s, g) => s + g.valor, 0);
  }
  function totalCorrigido(obra, taxaPct, hojeISO){
    const fim = fimCorrecao(obra, hojeISO);
    return obra.gastos.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0);
  }
  function lucroVenda(obra, taxaPct){
    if(!obra.venda) return null;
    return {
      bruto:   obra.venda.valor - totalBruto(obra),
      vsBanco: obra.venda.valor - totalCorrigido(obra, taxaPct, obra.venda.data),
    };
  }
  function mesesDeObra(obra, hojeISO){
    return diasEntre(obra.dataInicio, fimCorrecao(obra, hojeISO)) / DIAS_MES;
  }

  const api = { DIAS_MES, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CALC = api;
})(this);
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node tests/calc.test.cjs`
Expected: `OK: 11 testes`

- [ ] **Step 5: Commit**

```bash
git add calc.js tests/calc.test.cjs
git commit -m "feat: calc.js com correcao composta, totais e lucro (testado em Node)"
```

---

### Task 2: `index.html` — casca nova (título, header, views, nav, CSS)

**Files:**
- Modify: `index.html`

**Interfaces:**
- Produces (IDs que o `app.js` novo usa): `#kTotal`, `#kTotalSub`, `#obraCount`, `#obrasList`, `#btnNovaObra`, `#panelComp`, `#compBars`, `#btnVoltar`, `#obraBody`, `#ajTaxa`, `#ajTopicos`, `#ajNovoTopico`, `#ajAddTopico`, `#ajSair`. Mantidos: `#backdrop`, `#sheet`, `#fab`, `#installHint`, `#installBtn`, `#btnSair`, `#btnSairSide`, `#globe`, todo o bloco `#auth`.
- Consumes: nada de tasks anteriores (CSS/estrutura pura).

- [ ] **Step 1: Título, script e textos de marca**

No `<head>`: `<title>Minhas Obras</title>`. Antes de `<script src="app.js">` adicionar `<script src="calc.js"></script>`.
No bloco `#auth`, trocar o h1:

```html
<h1>Controle os custos das suas obras com<br><span>Minhas Obras</span></h1>
```

- [ ] **Step 2: Header sem month-pill**

Substituir o `<header class="top">` inteiro por:

```html
<header class="top">
  <h1><span class="logo">🏗️</span> Minhas Obras</h1>
  <div style="display:flex;align-items:center">
    <button id="btnSair" class="sair hidden" title="Sair da conta" aria-label="Sair da conta">🚪</button>
  </div>
</header>
```

- [ ] **Step 3: Sidebar e bottom nav com 2 abas**

Substituir `<aside class="side">` por:

```html
<aside class="side">
  <div class="s-logo"><span class="logo">🏗️</span> Minhas Obras</div>
  <button data-tab="inicio" class="on"><span class="ti">🏗️</span>Obras</button>
  <button data-tab="ajustes"><span class="ti">⚙️</span>Ajustes</button>
  <button id="btnSairSide" class="s-sair"><span class="ti">🚪</span>Sair da conta</button>
</aside>
```

Substituir `<nav class="tabs">` por:

```html
<nav class="tabs">
  <button data-tab="inicio" class="on"><span class="ti">🏗️</span>Obras</button>
  <button data-tab="ajustes"><span class="ti">⚙️</span>Ajustes</button>
</nav>
```

- [ ] **Step 4: Substituir as 5 sections antigas pelas 3 novas**

Apagar `#v-inicio`, `#v-lancamentos`, `#v-contas`, `#v-negocio`, `#v-invest` e colocar no lugar:

```html
<!-- ============ INÍCIO ============ -->
<section class="view active" id="v-inicio">
  <div class="cards">
    <div class="card saldo big">
      <div class="k-label"><span class="k-ic">💰</span> Total gasto nas obras</div>
      <div class="k-val" id="kTotal">R$ 0,00</div>
      <div class="k-sub" id="kTotalSub">—</div>
    </div>
  </div>
  <div class="panel">
    <h2>Minhas obras <span class="muted" id="obraCount"></span></h2>
    <ul class="list" id="obrasList"></ul>
    <button class="btn primary" id="btnNovaObra" style="width:100%;margin-top:12px">+ Nova obra</button>
  </div>
  <div class="panel hidden" id="panelComp">
    <h2>Comparativo entre obras</h2>
    <div id="compBars"></div>
    <div style="display:flex;gap:16px;justify-content:center;margin-top:10px;font-size:12.5px;color:var(--muted)">
      <span style="display:flex;align-items:center;gap:6px"><i style="width:10px;height:10px;border-radius:3px;background:var(--brand);display:inline-block"></i>Gasto</span>
      <span style="display:flex;align-items:center;gap:6px"><i style="width:10px;height:10px;border-radius:3px;background:var(--brand-soft);border:1px solid #3a56a0;display:inline-block"></i>Corrigido</span>
    </div>
  </div>
</section>

<!-- ============ DETALHE DA OBRA ============ -->
<section class="view" id="v-obra">
  <button class="back" id="btnVoltar">‹ Voltar</button>
  <div id="obraBody"></div>
</section>

<!-- ============ AJUSTES ============ -->
<section class="view" id="v-ajustes">
  <div class="panel">
    <h2>Correção pelo banco</h2>
    <div class="field">
      <label for="ajTaxa">Taxa ao mês (%)</label>
      <input id="ajTaxa" inputmode="decimal" autocomplete="off">
    </div>
    <p class="muted-note">Quanto seu dinheiro renderia por mês se estivesse no banco.
    Usada pra calcular o valor corrigido de cada gasto. Padrão: 1% ao mês.</p>
  </div>
  <div class="panel">
    <h2>Meus tópicos</h2>
    <ul class="list" id="ajTopicos"></ul>
    <div class="field" style="margin-top:10px"><label for="ajNovoTopico">Novo tópico</label>
      <input id="ajNovoTopico" placeholder="Ex: Piscina, Automação" autocomplete="off"></div>
    <button class="btn primary" id="ajAddTopico" style="width:100%">Adicionar tópico</button>
  </div>
  <div class="panel">
    <h2>Conta</h2>
    <button class="btn ghost" id="ajSair" style="width:100%">🚪 Sair da conta</button>
  </div>
</section>
```

- [ ] **Step 5: CSS novo (colar no fim do `<style>`, antes do bloco `@media (min-width:900px)`) e limpar CSS morto**

Remover as regras `.month-pill`, `.month-pill button`, `.month-pill span`, `.k-delta*`, `.seg.mini*`, `.area-*` (gráfico de área sai). Adicionar:

```css
/* ===== obras ===== */
.tag.blue{background:var(--blue-soft);color:var(--blue)}
.back{border:0;background:transparent;color:var(--brand);font-size:15.5px;font-weight:650;cursor:pointer;padding:8px 4px;margin-bottom:8px;display:flex;align-items:center;gap:4px;min-height:44px}
.obra-actions{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap}
.obra-actions .btn{flex:1;min-width:150px}
.muted-note{font-size:12.5px;color:var(--muted);margin-top:8px;line-height:1.45}
/* barras horizontais (comparativo) */
.hbar{margin-bottom:13px}
.hbar-nm{font-size:13.5px;font-weight:600;margin-bottom:4px}
.hbar-track{position:relative;height:14px;border-radius:7px;background:var(--surface-2);overflow:hidden}
.hbar-track i{position:absolute;left:0;top:0;bottom:0;border-radius:7px}
.hb-corr{background:var(--brand-soft);border:1px solid #3a56a0}
.hb-bruto{background:var(--brand)}
.hbar-vl{font-size:12.5px;color:var(--muted);margin-top:4px;font-variant-numeric:tabular-nums}
/* barras verticais (gasto mês a mês) */
.mbars{display:flex;align-items:flex-end;gap:6px;height:150px;padding-top:16px}
.mb{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%;gap:3px;min-width:0}
.mb i{width:100%;max-width:34px;background:var(--brand);border-radius:5px 5px 2px 2px;min-height:3px}
.mb b{font-size:9.5px;color:var(--muted);font-weight:600;white-space:nowrap}
.mb span{font-size:10.5px;color:var(--muted)}
```

No bloco `@media (min-width:900px)`: remover a linha `header.top .sair{display:none}`? **Não** — manter, sair fica na sidebar no desktop. Nada mais muda no media query.

- [ ] **Step 6: Conferir no browser**

Abrir `index.html` no navegador (duplo clique). Esperado: tela de login com novo título; após login, header "Minhas Obras", card total zerado, lista vazia com botão "+ Nova obra", 2 abas embaixo. Console vai acusar erros de `app.js` antigo (IDs removidos) — esperado até a Task 3; o commit desta task registra só a casca.

- [ ] **Step 7: Commit**

```bash
git add index.html
git commit -m "feat: casca Minhas Obras - views, nav 2 abas, CSS de graficos de obra"
```

---

### Task 3: `app.js` — núcleo: estado, helpers, Início, nova obra, navegação

**Files:**
- Modify: `app.js` (substituição total do conteúdo)

**Interfaces:**
- Consumes: `OBRA_CALC` (Task 1), IDs do `index.html` (Task 2).
- Produces (usadas pelas tasks 4–6, todas no mesmo arquivo): `db`, `save()`, `uid()`, `money`, `moneyShort`, `todayISO()`, `fmtData`, `parseNum`, `$`, `el`, `escapeHtml`, `emptyBlock`, `topicos()`, `TOP_MAP()`, `taxa()`, `FASES`, `PIE`, `MESAB`, `fmtMeses`, `openSheet(html)`, `closeSheet()`, `renderAll()`, `showView(v)`, `openObra(id)`, `formNovaObra()`, stubs `renderObra()`, `renderAjustes()`, `formGasto(obraId, gasto)`.

- [ ] **Step 1: Reescrever `app.js` inteiro com este conteúdo**

```js
/* Minhas Obras — controle de custos por obra. PWA offline, localStorage, vanilla JS. */
'use strict';

/* ---------- estado ---------- */
const SESSION_CPF = localStorage.getItem('finance_session_v1');
const KEY = SESSION_CPF ? 'obras_data_v1::' + SESSION_CPF : 'obras_data_v1';

const TOPICOS = [
  {id:'terreno',    nm:'Terreno',       ic:'🗺️'},
  {id:'projeto',    nm:'Projeto/Docs',  ic:'📐'},
  {id:'fundacao',   nm:'Fundação',      ic:'⛏️'},
  {id:'estrutura',  nm:'Estrutura',     ic:'🏗️'},
  {id:'alvenaria',  nm:'Alvenaria',     ic:'🧱'},
  {id:'telhado',    nm:'Telhado',       ic:'🏠'},
  {id:'eletrica',   nm:'Elétrica',      ic:'⚡'},
  {id:'hidraulica', nm:'Hidráulica',    ic:'🚿'},
  {id:'esquadrias', nm:'Esquadrias',    ic:'🚪'},
  {id:'revest',     nm:'Revestimentos', ic:'🪨'},
  {id:'pintura',    nm:'Pintura',       ic:'🎨'},
  {id:'paisagismo', nm:'Paisagismo',    ic:'🌳'},
  {id:'maoobra',    nm:'Mão de obra',   ic:'👷'},
  {id:'outros',     nm:'Outros',        ic:'📦'},
];
const PIE = ['--c1','--c2','--c3','--c4','--c5','--c6','--c7','--c8'];
const FASES = {
  construcao: {nm:'Em construção',    ic:'🏗️', cls:'pend'},
  pronta:     {nm:'Pronta · à venda', ic:'🏠', cls:'blue'},
  vendida:    {nm:'Vendida',          ic:'✅', cls:'ok'},
};

const empty = () => ({obras:[], config:{taxaMensal:1, topicosCustom:[]}});
let db = load();
let obraAberta = null;   // id da obra no detalhe
let tab = 'inicio';

function load(){
  try{
    const d = JSON.parse(localStorage.getItem(KEY));
    return d && typeof d==='object'
      ? {...empty(), ...d, config:{...empty().config, ...(d.config||{})}}
      : empty();
  }catch{ return empty(); }
}
function save(){ localStorage.setItem(KEY, JSON.stringify(db)); }
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2,6);

const topicos = () => [...TOPICOS, ...db.config.topicosCustom];
const TOP_MAP = () => Object.fromEntries(topicos().map(t=>[t.id,t]));
const taxa = () => db.config.taxaMensal;

/* ---------- helpers ---------- */
const BRL = new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'});
const money = n => BRL.format(n||0);
const moneyShort = n => {
  const a = Math.abs(n), s = n<0 ? '-' : '';
  if(a>=1e6)  return s+'R$ '+(a/1e6).toFixed(a>=1e7?1:2).replace('.',',')+' mi';
  if(a>=1000) return s+'R$ '+(a/1000).toFixed(a>=10000?0:1).replace('.',',')+' mil';
  return money(n);
};
const MESAB = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];
const todayISO = () => new Date().toISOString().slice(0,10);
const fmtData = iso => { const [y,m,d] = iso.split('-'); return `${d}/${m}/${y.slice(2)}`; };
const parseNum = v => {
  if(typeof v==='number') return v;
  v = (v||'').toString().trim().replace(/[^\d,.-]/g,'');
  if(v.includes(',')) v = v.replace(/\./g,'').replace(',','.');
  const n = parseFloat(v); return isNaN(n) ? 0 : n;
};
const $ = s => document.querySelector(s);
const el = (tag,cls,html)=>{ const e=document.createElement(tag); if(cls)e.className=cls; if(html!=null)e.innerHTML=html; return e; };
function escapeHtml(s){ return (s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function emptyBlock(icon,msg){ return `<div class="empty"><div class="big">${icon}</div><p>${msg}</p></div>`; }
function fmtMeses(m){
  if(m < 1) return 'começando';
  const r = Math.round(m);
  return r + (r===1 ? ' mês' : ' meses');
}
const obraById = id => db.obras.find(o=>o.id===id);

/* ---------- navegação ---------- */
function showView(v){
  tab = v;
  document.querySelectorAll('section.view').forEach(s=>s.classList.remove('active'));
  $('#v-'+v).classList.add('active');
  document.querySelectorAll('button[data-tab]').forEach(x=>x.classList.toggle('on',x.dataset.tab===v));
  window.scrollTo({top:0});
}
document.querySelectorAll('button[data-tab]').forEach(b=>{
  b.onclick = ()=>{ obraAberta=null; showView(b.dataset.tab); renderAll(); };
});
$('#btnVoltar').onclick = ()=>{ obraAberta=null; showView('inicio'); renderAll(); };
function openObra(id){ obraAberta=id; showView('obra'); renderObra(); }

/* ---------- render ---------- */
function renderAll(){
  renderInicio();
  renderAjustes();
  if(obraAberta) renderObra();
}

/* ===== INÍCIO ===== */
function renderInicio(){
  const hoje = todayISO();
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  const bruto = abertas.reduce((s,o)=>s+OBRA_CALC.totalBruto(o),0);
  const corr  = abertas.reduce((s,o)=>s+OBRA_CALC.totalCorrigido(o,taxa(),hoje),0);
  $('#kTotal').textContent = money(bruto);
  $('#kTotalSub').textContent = abertas.length
    ? `Corrigido: ${money(corr)} · ${abertas.length} obra${abertas.length>1?'s':''} em andamento`
    : 'Nenhuma obra em andamento';

  const arr = [...db.obras].sort((a,b)=>
    ((a.fase==='vendida')-(b.fase==='vendida')) || b.dataInicio.localeCompare(a.dataInicio));
  $('#obraCount').textContent = arr.length ? `${arr.length} obra${arr.length>1?'s':''}` : '';
  const list = $('#obrasList');
  list.innerHTML = arr.length ? '' : emptyBlock('🏗️','Nenhuma obra ainda.<br>Toque em “+ Nova obra” pra começar.');
  arr.forEach(o=>{
    const f = FASES[o.fase];
    const li = el('li');
    li.style.cursor = 'pointer';
    li.innerHTML = `
      <div class="av ic-brand">${f.ic}</div>
      <div class="li-main">
        <div class="t">${escapeHtml(o.nome)}</div>
        <div class="s"><span class="tag ${f.cls}">${f.nm}</span> · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}</div>
      </div>
      <div class="li-val">${moneyShort(OBRA_CALC.totalBruto(o))}</div>`;
    li.onclick = ()=>openObra(o.id);
    list.appendChild(li);
  });

  drawComp(arr.filter(o=>OBRA_CALC.totalBruto(o)>0), hoje);
}

function drawComp(arr, hoje){
  const panel = $('#panelComp');
  if(arr.length < 2){ panel.classList.add('hidden'); return; }
  panel.classList.remove('hidden');
  const rows = arr.map(o=>({
    nm: o.nome,
    b: OBRA_CALC.totalBruto(o),
    c: OBRA_CALC.totalCorrigido(o, taxa(), hoje),
  }));
  const max = Math.max(...rows.map(r=>r.c), 1);
  $('#compBars').innerHTML = rows.map(r=>`
    <div class="hbar">
      <div class="hbar-nm">${escapeHtml(r.nm)}</div>
      <div class="hbar-track">
        <i class="hb-corr"  style="width:${(r.c/max*100).toFixed(1)}%"></i>
        <i class="hb-bruto" style="width:${(r.b/max*100).toFixed(1)}%"></i>
      </div>
      <div class="hbar-vl">${moneyShort(r.b)} gasto · ${moneyShort(r.c)} corrigido</div>
    </div>`).join('');
}

/* stubs preenchidos nas próximas tasks */
function renderObra(){}
function renderAjustes(){}
function formGasto(obraId, gasto){}

/* ---------- modal / formulários ---------- */
const backdrop = $('#backdrop'), sheet = $('#sheet');
function openSheet(html){ sheet.innerHTML = html; backdrop.classList.add('show'); }
function closeSheet(){ backdrop.classList.remove('show'); }
backdrop.onclick = e=>{ if(e.target===backdrop) closeSheet(); };

function formNovaObra(){
  openSheet(`
    <h3>Nova obra</h3>
    <div class="field"><label>Nome da obra</label><input id="fNome" placeholder="Ex: Casa Alphaville" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label><input id="fEst" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Criar obra</button>
    </div>`);
  $('#fNome').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const nome = $('#fNome').value.trim();
    if(!nome){ $('#fNome').focus(); return; }
    const est = parseNum($('#fEst').value);
    const o = {
      id: uid(), nome, fase: 'construcao',
      dataInicio: $('#fData').value || todayISO(),
      valorEstimadoVenda: est > 0 ? est : null,
      gastos: [],
    };
    db.obras.push(o); save(); closeSheet(); renderAll(); openObra(o.id);
  };
}
$('#btnNovaObra').onclick = formNovaObra;

/* FAB: lançar gasto (ou criar 1ª obra) */
$('#fab').onclick = ()=>{
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length){ formNovaObra(); return; }
  const atual = obraAberta && obraById(obraAberta);
  formGasto(atual && atual.fase!=='vendida' ? obraAberta : null, null);
};

/* ---------- instalar PWA ---------- */
let deferredPrompt = null;
window.addEventListener('beforeinstallprompt',e=>{ e.preventDefault(); deferredPrompt=e; $('#installHint').classList.remove('hidden'); });
$('#installBtn').onclick = async()=>{
  if(!deferredPrompt) return;
  deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt=null;
  $('#installHint').classList.add('hidden');
};
window.addEventListener('appinstalled',()=>$('#installHint').classList.add('hidden'));

/* ---------- go ---------- */
renderAll();
```

- [ ] **Step 2: Testar no browser**

Abrir `index.html`, logar. Esperado: sem erros no console; criar obra pelo botão "+ Nova obra" abre sheet; salvar cria obra, abre detalhe vazio (stub), voltar mostra card na lista com fase "Em construção". Recarregar página: obra persiste.

- [ ] **Step 3: Commit**

```bash
git add app.js
git commit -m "feat: nucleo de obras - estado, inicio, nova obra, navegacao"
```

---

### Task 4: Detalhe da obra — resumo, donut por tópico, barras mensais, lançamentos

**Files:**
- Modify: `app.js` (substituir o stub `function renderObra(){}` e adicionar funções auxiliares logo abaixo dele)

**Interfaces:**
- Consumes: helpers da Task 3, `OBRA_CALC`.
- Produces: `renderObra()` completo; `drawDonutObra(entries,total)`; `mbarsHtml(o)`; `gastoRow(o,g)`. Botões de fase/venda chamam `formVenda(o)`, `mudarFase(o,fase)`, `formEditarObra(o)` — definidos na Task 5 (declarar aqui como stubs `function formVenda(o){}`, `function mudarFase(o,f){}`, `function formEditarObra(o){}` para o arquivo não quebrar).

- [ ] **Step 1: Substituir `function renderObra(){}` por:**

```js
function renderObra(){
  const o = obraById(obraAberta);
  if(!o){ obraAberta=null; showView('inicio'); return; }
  const hoje = todayISO();
  const f = FASES[o.fase];
  const bruto = OBRA_CALC.totalBruto(o);
  const corr  = OBRA_CALC.totalCorrigido(o, taxa(), hoje);
  const lucro = OBRA_CALC.lucroVenda(o, taxa());

  let head = `
    <div class="panel">
      <h2 style="font-size:19px">${f.ic} ${escapeHtml(o.nome)}
        <button class="li-del" id="oEdit" title="Editar obra" style="font-size:15px">✏️</button></h2>
      <div style="font-size:13.5px;color:var(--muted)">
        <span class="tag ${f.cls}">${f.nm}</span> ·
        começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}
      </div>
    </div>`;

  let resumo = `
    <div class="cards">
      <div class="card saldo big">
        <div class="k-label"><span class="k-ic">💸</span> Total gasto</div>
        <div class="k-val">${money(bruto)}</div>
        <div class="k-sub">Corrigido pelo banco: ${money(corr)}</div>
      </div>`;
  if(o.fase==='vendida' && lucro){
    resumo += `
      <div class="card">
        <div class="k-label"><span class="k-ic ic-green">↑</span> Lucro da venda</div>
        <div class="k-val sm ${lucro.bruto>=0?'pos':'neg'}">${money(lucro.bruto)}</div>
      </div>
      <div class="card">
        <div class="k-label"><span class="k-ic ic-blue">🏦</span> Acima do banco</div>
        <div class="k-val sm ${lucro.vsBanco>=0?'pos':'neg'}">${money(lucro.vsBanco)}</div>
      </div>
      <div class="card big">
        <div class="k-label"><span class="k-ic ic-brand">🤝</span> Vendida em ${fmtData(o.venda.data)}</div>
        <div class="k-val sm">${money(o.venda.valor)}</div>
      </div>`;
  } else if(o.valorEstimadoVenda){
    resumo += `
      <div class="card">
        <div class="k-label"><span class="k-ic ic-brand">🎯</span> Venda estimada</div>
        <div class="k-val sm">${moneyShort(o.valorEstimadoVenda)}</div>
      </div>
      <div class="card">
        <div class="k-label"><span class="k-ic ic-green">↑</span> Margem estimada</div>
        <div class="k-val sm ${o.valorEstimadoVenda-corr>=0?'pos':'neg'}">${moneyShort(o.valorEstimadoVenda-corr)}</div>
      </div>`;
  }
  resumo += `</div>`;

  let acoes = '<div class="obra-actions">';
  if(o.fase==='construcao') acoes += `<button class="btn primary" id="oPronta">🏠 Marcar como pronta</button>`;
  if(o.fase==='pronta') acoes += `
    <button class="btn primary" id="oVender">🤝 Registrar venda</button>
    <button class="btn ghost" id="oVoltarConstr">↩ Voltar pra construção</button>`;
  if(o.fase==='vendida') acoes += `<button class="btn ghost" id="oDesfazer">↩ Desfazer venda</button>`;
  acoes += '</div>';

  const byTop = {};
  o.gastos.forEach(g=>{ byTop[g.topico]=(byTop[g.topico]||0)+g.valor; });
  const entries = Object.entries(byTop).sort((a,b)=>b[1]-a[1]);

  const graficos = `
    <div class="panel"><h2>Gastos por tópico</h2>
      <div class="donut-wrap">
        <div class="donut">
          <svg viewBox="0 0 36 36" width="132" height="132" id="oDonut"></svg>
          <div class="center"><small>Total</small><b id="oDonutTotal"></b></div>
        </div>
        <div class="legend" id="oDonutLeg"></div>
      </div>
    </div>
    <div class="panel"><h2>Gasto mês a mês</h2>${mbarsHtml(o)}</div>`;

  const lanc = `
    <div class="panel"><h2>Lançamentos <span class="muted">${o.gastos.length||''}</span></h2>
      <ul class="list" id="oGastos"></ul>
    </div>`;

  $('#obraBody').innerHTML = head + resumo + acoes + graficos + lanc;

  drawDonutObra(entries, bruto);
  const list = $('#oGastos');
  list.innerHTML = o.gastos.length ? '' : emptyBlock('🧾','Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro.');
  [...o.gastos].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id))
    .forEach(g=>list.appendChild(gastoRow(o,g)));

  $('#oEdit').onclick = ()=>formEditarObra(o);
  const on = (id,fn)=>{ const b=$(id); if(b) b.onclick=fn; };
  on('#oPronta',       ()=>mudarFase(o,'pronta'));
  on('#oVender',       ()=>formVenda(o));
  on('#oVoltarConstr', ()=>mudarFase(o,'construcao'));
  on('#oDesfazer',     ()=>{ if(confirm('Desfazer a venda? A obra volta pra “Pronta”.')){ delete o.venda; o.fase='pronta'; save(); renderAll(); } });
}

function drawDonutObra(entries, total){
  const svg = $('#oDonut'), leg = $('#oDonutLeg');
  $('#oDonutTotal').textContent = moneyShort(total);
  if(!total){ svg.innerHTML=''; leg.innerHTML = `<div class="empty" style="padding:10px"><p>Sem gastos ainda</p></div>`; return; }
  const cs = getComputedStyle(document.documentElement);
  const R = 15.915, C = 2*Math.PI*R;
  let off = 0, paths = '';
  entries.forEach(([id,val],i)=>{
    const len = val/total*C;
    const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
    paths += `<circle cx="18" cy="18" r="${R}" fill="none" stroke="${color}" stroke-width="4.4"
      stroke-dasharray="${len} ${C-len}" stroke-dashoffset="${-off}" transform="rotate(-90 18 18)"></circle>`;
    off += len;
  });
  svg.innerHTML = paths;
  leg.innerHTML = '';
  const map = TOP_MAP();
  entries.slice(0,7).forEach(([id,val],i)=>{
    const t = map[id] || {nm:id, ic:'🏷️'};
    const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
    leg.appendChild(el('div','row',
      `<span class="dot" style="background:${color}"></span>
       <span class="nm">${t.ic} ${t.nm}</span>
       <span class="vl">${Math.round(val/total*100)}% · ${moneyShort(val)}</span>`));
  });
}

function mbarsHtml(o){
  const by = {};
  o.gastos.forEach(g=>{ const k=g.data.slice(0,7); by[k]=(by[k]||0)+g.valor; });
  const keys = Object.keys(by).sort().slice(-12);
  if(!keys.length) return emptyBlock('📅','Sem gastos ainda.');
  const max = Math.max(...keys.map(k=>by[k]));
  return '<div class="mbars">' + keys.map(k=>{
    const m = +k.split('-')[1];
    return `<div class="mb">
      <b>${moneyShort(by[k])}</b>
      <i style="height:${Math.max(3, by[k]/max*100).toFixed(0)}%"></i>
      <span>${MESAB[m-1]}</span></div>`;
  }).join('') + '</div>';
}

function gastoRow(o, g){
  const t = TOP_MAP()[g.topico] || {nm:g.topico||'Outros', ic:'🏷️'};
  const li = el('li');
  li.innerHTML = `
    <div class="av ic-brand">${t.ic}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(g.descricao || t.nm)}</div>
      <div class="s">${t.nm} · ${fmtData(g.data)}</div>
    </div>
    <div class="li-val neg">−${money(g.valor)}</div>`;
  li.querySelector('.li-main').style.cursor = 'pointer';
  li.querySelector('.li-main').onclick = ()=>formGasto(o.id, g);
  const del = el('button','li-del','×');
  del.onclick = ()=>{ if(confirm('Excluir este gasto?')){ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); renderAll(); } };
  li.appendChild(del);
  return li;
}

/* stubs preenchidos na Task 5 */
function formVenda(o){}
function mudarFase(o,f){}
function formEditarObra(o){}
```

Nota: a ordem dos elementos em `.mb` mudou em relação ao CSS da Task 2 (valor acima da barra) — o CSS flex-column já cobre.

- [ ] **Step 2: Testar no browser**

Criar obra, abrir detalhe. Esperado: cabeçalho com fase, card de total zerado, painéis de gráficos com estados vazios, lista de lançamentos vazia. Sem erros no console.

- [ ] **Step 3: Commit**

```bash
git add app.js
git commit -m "feat: detalhe da obra - resumo, donut por topico, barras mensais, lancamentos"
```

---

### Task 5: Fases, venda e formulários de obra/gasto

**Files:**
- Modify: `app.js` (substituir stubs `formVenda`, `mudarFase`, `formEditarObra`, `formGasto`)

**Interfaces:**
- Consumes: tudo das Tasks 3–4.
- Produces: fluxo completo criar→gastar→pronta→vender.

- [ ] **Step 1: Substituir os 3 stubs do fim da Task 4 por:**

```js
function mudarFase(o, f){ o.fase = f; save(); renderAll(); }

function formVenda(o){
  openSheet(`
    <h3>Registrar venda — ${escapeHtml(o.nome)}</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="field"><label>Data da venda</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Confirmar venda</button>
    </div>`);
  $('#fVal').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const valor = parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    o.venda = { valor, data: $('#fData').value || todayISO() };
    o.fase = 'vendida';
    save(); closeSheet(); renderAll();
  };
}

function formEditarObra(o){
  openSheet(`
    <h3>Editar obra</h3>
    <div class="field"><label>Nome</label><input id="fNome" value="${escapeHtml(o.nome)}" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${o.dataInicio}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label>
      <input id="fEst" inputmode="decimal" value="${o.valorEstimadoVenda||''}" autocomplete="off"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cDel" style="color:var(--red)">Apagar obra</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  $('#cSave').onclick = ()=>{
    const nome = $('#fNome').value.trim();
    if(!nome){ $('#fNome').focus(); return; }
    o.nome = nome;
    o.dataInicio = $('#fData').value || o.dataInicio;
    const est = parseNum($('#fEst').value);
    o.valorEstimadoVenda = est>0 ? est : null;
    save(); closeSheet(); renderAll();
  };
  $('#cDel').onclick = ()=>{
    const n = o.gastos.length;
    if(confirm(`Apagar “${o.nome}”?` + (n?` Os ${n} lançamento(s) dela serão perdidos.`:''))){
      db.obras = db.obras.filter(x=>x.id!==o.id);
      obraAberta = null;
      save(); closeSheet(); showView('inicio'); renderAll();
    }
  };
}
```

- [ ] **Step 2: Substituir o stub `function formGasto(obraId, gasto){}` (Task 3) por:**

```js
function formGasto(obraId, gasto){
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length && !gasto){ formNovaObra(); return; }
  const isEdit = !!gasto;
  // na edição a obra é fixa (a que está aberta); na criação pode escolher
  const oFix = isEdit ? obraById(obraAberta) : (obraId ? obraById(obraId) : null);

  const selObra = oFix
    ? `<div class="field"><label>Obra</label><input value="${escapeHtml(oFix.nome)}" disabled></div>`
    : `<div class="field"><label>Obra</label><select id="fObra">
        ${abertas.map(o=>`<option value="${o.id}">${escapeHtml(o.nome)}</option>`).join('')}
       </select></div>`;

  openSheet(`
    <h3>${isEdit?'Editar gasto':'Novo gasto'}</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00"
      value="${isEdit?String(gasto.valor).replace('.',','):''}" autocomplete="off"></div>
    ${selObra}
    <div class="field"><label>Tópico</label><div class="chips" id="fChips"></div></div>
    <div class="field"><label>Descrição (opcional)</label>
      <input id="fDesc" placeholder="Ex: 50 sacos de cimento" value="${isEdit?escapeHtml(gasto.descricao||''):''}" autocomplete="off"></div>
    <div class="field"><label>Data</label><input id="fData" type="date" value="${isEdit?gasto.data:todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);

  let top = isEdit ? gasto.topico : topicos()[0].id;
  const chips = $('#fChips');
  const paint = ()=>{
    chips.innerHTML = '';
    topicos().forEach(t=>{
      const ch = el('button','chip'+(t.id===top?' on':''),`${t.ic} ${t.nm}`);
      ch.type = 'button';
      ch.onclick = ()=>{ top=t.id; paint(); };
      chips.appendChild(ch);
    });
  };
  paint();
  $('#fVal').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const valor = parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    const o = oFix || obraById($('#fObra').value);
    if(!o) return;
    if(isEdit){
      gasto.valor = valor; gasto.topico = top;
      gasto.descricao = $('#fDesc').value.trim();
      gasto.data = $('#fData').value || gasto.data;
    } else {
      o.gastos.push({ id:uid(), valor, topico:top,
        descricao:$('#fDesc').value.trim(), data:$('#fData').value || todayISO() });
    }
    save(); closeSheet(); renderAll();
  };
}
```

- [ ] **Step 3: Testar fluxo completo no browser**

Criar obra → lançar 3 gastos em tópicos diferentes (um com data de 6 meses atrás) → conferir donut, barras e corrigido > bruto → editar um gasto → marcar pronta → lançar gasto de IPTU → registrar venda → conferir lucro bruto e "acima do banco" → desfazer venda → apagar gasto → apagar obra. Sem erros no console em nenhum passo.

- [ ] **Step 4: Commit**

```bash
git add app.js
git commit -m "feat: fases, registrar venda com lucro, formularios de obra e gasto"
```

---

### Task 6: Ajustes (taxa, tópicos custom, sair) + branding PWA

**Files:**
- Modify: `app.js` (substituir stub `renderAjustes`)
- Modify: `manifest.json`
- Modify: `sw.js`
- Modify: `PRODUCT.md`

**Interfaces:**
- Consumes: `db.config`, helpers.
- Produces: app completo e instalável como "Minhas Obras".

- [ ] **Step 1: Substituir `function renderAjustes(){}` por:**

```js
function renderAjustes(){
  const inp = $('#ajTaxa');
  if(document.activeElement !== inp)
    inp.value = String(db.config.taxaMensal).replace('.',',');
  inp.onchange = ()=>{
    const v = parseNum(inp.value);
    db.config.taxaMensal = (v>0 && v<=20) ? v : 1;
    inp.value = String(db.config.taxaMensal).replace('.',',');
    save(); renderAll();
  };

  const ul = $('#ajTopicos');
  ul.innerHTML = db.config.topicosCustom.length ? '' : emptyBlock('🏷️','Nenhum tópico próprio ainda.');
  db.config.topicosCustom.forEach(t=>{
    const li = el('li');
    li.innerHTML = `<div class="av ic-brand">🏷️</div>
      <div class="li-main"><div class="t">${escapeHtml(t.nm)}</div></div>`;
    const del = el('button','li-del','×');
    del.onclick = ()=>{
      const emUso = db.obras.some(o=>o.gastos.some(g=>g.topico===t.id));
      if(emUso){ alert('Este tópico tem gastos lançados. Mova ou apague os gastos antes.'); return; }
      if(confirm(`Remover o tópico “${t.nm}”?`)){
        db.config.topicosCustom = db.config.topicosCustom.filter(x=>x.id!==t.id);
        save(); renderAll();
      }
    };
    li.appendChild(del);
    ul.appendChild(li);
  });

  $('#ajAddTopico').onclick = ()=>{
    const nm = $('#ajNovoTopico').value.trim();
    if(!nm){ $('#ajNovoTopico').focus(); return; }
    db.config.topicosCustom.push({ id:'c_'+uid(), nm, ic:'🏷️' });
    $('#ajNovoTopico').value = '';
    save(); renderAll();
  };

  $('#ajSair').onclick = ()=>$('#btnSair').click();
}
```

- [ ] **Step 2: `manifest.json`**

```json
{
  "name": "Minhas Obras",
  "short_name": "Obras",
  "description": "Controle de custos e lucro por obra, na ponta do lápis.",
  "start_url": "./index.html",
  "scope": "./",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#070c18",
  "theme_color": "#070c18",
  "lang": "pt-BR",
  "icons": [
    { "src": "icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any maskable" }
  ]
}
```

- [ ] **Step 3: `sw.js` — bump de cache e novo asset**

```js
const CACHE = 'obras-v1';
const ASSETS = ['./', './index.html', './app.js', './auth.js', './globe.js', './calc.js', './manifest.json', './icon.svg'];
```

(Resto do arquivo inalterado.)

- [ ] **Step 4: `PRODUCT.md` — atualizar Users e Product Purpose**

Substituir a seção `## Users` por:

```markdown
## Users

Pai do Giovani — construtor de casas de alto padrão, não técnico, meia-idade, usa principalmente no celular (Android, PWA instalado). Prefere letra maior (óculos de leitura). Contexto: lançar gastos da obra no dia a dia (ao pagar fornecedor, fechar compra) e conferir o total gasto e a margem. Giovani (filho) mantém o app.
```

Substituir a seção `## Product Purpose` por:

```markdown
## Product Purpose

Controle de custos de obras offline-first: gastos por obra separados por tópico (terreno, fundação, acabamento...), valor bruto e valor corrigido (quanto renderia no banco, taxa configurável, padrão 1% a.m.) e lucro real na venda — bruto e acima do banco. Obras têm 3 fases: em construção → pronta (à venda) → vendida. Tudo digitado manualmente, salvo no aparelho (localStorage), por usuário (login local CPF+senha). Sucesso = o pai abre o app, entende em 5 segundos quanto cada obra custou e, ao vender, confia no número do lucro.
```

- [ ] **Step 5: Testar Ajustes no browser**

Mudar taxa pra 1,2 → corrigidos aumentam em todas as telas. Criar tópico "Piscina" → aparece nos chips do gasto. Tentar remover tópico em uso → bloqueia com aviso. Sair da conta → volta pro login.

- [ ] **Step 6: Commit**

```bash
git add app.js manifest.json sw.js PRODUCT.md
git commit -m "feat: ajustes (taxa, topicos custom, sair) e branding Minhas Obras"
```

---

### Task 7: Verificação final

**Files:** nenhum (só execução).

- [ ] **Step 1: Testes de cálculo**

Run: `node tests/calc.test.cjs`
Expected: `OK: 11 testes`

- [ ] **Step 2: Fluxo completo manual (checklist da spec)**

No browser, com dados limpos (`localStorage.clear()` no console e recarregar):
1. Criar conta nova (CPF de teste válido) e logar.
2. Criar obra "Casa Teste" com início 12 meses atrás e estimativa R$ 2.000.000.
3. Lançar: Terreno R$ 500.000 (12 meses atrás), Fundação R$ 200.000 (8 meses atrás), Pintura R$ 50.000 (hoje).
4. Conferir: total bruto R$ 750.000; corrigido maior que bruto; margem estimada = estimado − corrigido; donut com 3 fatias; barras nos meses certos.
5. Marcar pronta → lançar "IPTU" R$ 5.000 em Outros → registrar venda R$ 2.000.000 hoje.
6. Conferir lucro bruto = 2.000.000 − 755.000 = R$ 1.245.000 e "acima do banco" menor que isso, porém positivo.
7. Criar segunda obra com 1 gasto → comparativo aparece no Início com 2 barras.
8. Ajustes: taxa 2% → corrigido da obra vendida NÃO muda de data-base (continua congelado na venda) mas recalcula com taxa nova; taxa de volta pra 1.
9. Recarregar página → tudo persiste. Aba anônima → login pede conta (dados por usuário).
10. Reduced motion (DevTools → Rendering → prefers-reduced-motion) → globo estático.

- [ ] **Step 3: Commit final (se houver ajuste de bug) e tag**

```bash
git add -A
git commit -m "fix: ajustes do teste de fluxo completo" # somente se algo mudou
git tag obras-v1
```

## Self-review (feito na escrita)

- Cobertura da spec: telas 1–4 ✔ (Tasks 2–6), correção ✔ (Task 1), fases/venda ✔ (Task 5), tópicos padrão+custom ✔ (Tasks 3/6), gráficos 3× ✔ (Tasks 3/4), bordas (gasto ≤0, obra vendida sem gasto novo — FAB e formGasto filtram `fase!=='vendida'`, apagar com aviso) ✔, PWA/branding ✔ (Task 6).
- Sem placeholders; stubs são explícitos e cada um é substituído em task nomeada.
- Tipos consistentes: `gasto.topico` (não `categoria`), `config.taxaMensal` em %, `OBRA_CALC.*` assinaturas iguais em calc/app/testes.
