# Custta com cara de app iOS — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No celular (app Capacitor e site), o Custta deixa de parecer site: sem zoom preso, barras translúcidas no padrão iOS, listas agrupadas, gestos de iPhone e rolagem lisa.

**Architecture:** CSS continua todo em `styles.css`, com as mudanças de celular dentro de `@media (max-width:899px)` (desktop ≥900px intacto). `nativo.js` marca o ambiente (`html.nativo`, `html.standalone`). Um arquivo novo, `gestos.js`, concentra os gestos: lógica pura exportada para `node --test` e ligação ao DOM por delegação, sem mexer nos renderizadores do `app.js`. `app.js` ganha só o título por tela e a direção da navegação.

**Tech Stack:** Vanilla JS (scripts clássicos com globais), CSS, Capacitor 8 (WKWebView), `node --test`, Playwright (suítes em `tests/browser/`), agent-browser.

**Spec:** `docs/specs/2026-09-25-ios-nativo-design.md`

## Global Constraints

- Desktop (≥900px, com `aside.side`) não muda. Mudanças de celular vivem em `@media (max-width:899px)` ou em regras que valem igual nos dois (ex.: fonte de campo 16px).
- CSP estrita: nada de `<style>`, atributo `style="..."` ou `onclick=` no HTML. Estilo por JS só via CSSOM (`el.style.setProperty`, `classList`).
- Vanilla, sem build, sem dependência de runtime no browser. Identificadores, comentários e UI em português.
- Arquivo JS novo na raiz: entra em `ASSETS` do `sw.js` **e** `CACHE` incrementa (`obras-v52` → `obras-v53`).
- Quatro combinações tema × cor (escuro/claro × esmeralda/azul) com contraste ≥4.5:1; `tests/browser/contraste.cjs` continua passando.
- Texto de corpo ≥16px; números-chave ≥24px; alvos de toque ≥44px; `prefers-reduced-motion` desliga animações e o globo anima parado.
- Todo `input`, `select` e `textarea` com `font-size` ≥16px (é o que impede o zoom do iOS).
- Material translúcido: `-webkit-backdrop-filter` **e** `backdrop-filter`; cor do material por variável `--barra` definida em cada bloco de tema (`:root`, `html[data-theme="light"]`, `html[data-skin="azul"]`, `html[data-skin="azul"][data-theme="light"]`). Sem `color-mix()` (WKWebView do iOS 15 não tem).
- Implementadores de subagente **não commitam**; o controlador commita após revisão. Ao editar `index.html` ou `package.json`, releia o arquivo imediatamente antes (outra tarefa pode estar editando em paralelo).
- Node: `export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$PATH"`. Servidor de teste: `node tests/browser/servidor.cjs` (porta 8123).

## Review Focus

1. Campo com fonte <16px em qualquer tela (Ajustes, login, cadastro, sheets, simulador) volta a causar zoom preso — coberto pela varredura de fontes em todas as telas (Task 5).
2. Gesto horizontal roubando a rolagem vertical da lista (dedo levemente torto) — `eixo()` exige predominância horizontal e só decide após 10px (Task 4, testes de `eixo`).
3. Linha aberta em "Apagar" esquecida aberta ao rolar ou abrir outra linha — fechamento em `touchstart` fora dela e em `scroll` (Task 4 e Task 5).
4. Voltar pela borda no Safari comum brigando com o voltar do navegador — só com `html.nativo`/`html.standalone` (Task 4, teste de `bordaAtiva`).
5. Tema claro com material translúcido ilegível — `--barra` por bloco de tema e `contraste.cjs` nos quatro combos (Task 2 e Task 5).

---

### Task 1: Fundação — zoom, ambiente, fundo e globo

**Files:**
- Modify: `index.html:5` (meta viewport)
- Modify: `nativo.js` (marcar ambiente)
- Modify: `styles.css` (fonte de campos, fundo sem attachment fixed, superfícies opacas no celular, capa da barra de status, seleção/toque)
- Modify: `globe.js` (pausa durante rolagem/toque e página oculta; resize só quando a largura muda)
- Create: `tests/ios.test.cjs`; Modify: `tests/nativo.test.cjs`; Modify: `package.json` (`test:unit` inclui `tests/ios.test.cjs`)

**Interfaces:**
- Produces: `OBRA_NATIVO.marcarAmbiente(doc)` — adiciona `nativo` e/ou `standalone` em `doc.documentElement.classList`; chamado no fim do próprio `nativo.js` no browser. Classes `html.nativo` e `html.standalone` (usadas pelas Tasks 2 e 4). `window.__globeEstado()` → `{ rodando: boolean }` (usado pela Task 5).

- [ ] **Step 1: Testes que falham** — `tests/ios.test.cjs`:

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const raiz = join(__dirname, '..');
const ler = p => readFileSync(join(raiz, p), 'utf8');
/* Regras "folha" (sem chaves internas): suficiente para o styles.css, que não aninha além de @media. */
const regras = css => [...css.replace(/\/\*[\s\S]*?\*\//g, '').matchAll(/([^{}]+)\{([^{}]*)\}/g)]
  .map(m => ({ sel: m[1].trim(), decl: m[2] }));

test('viewport não deixa o iOS dar zoom ao focar campo', ()=>{
  const meta = ler('index.html').match(/<meta name="viewport" content="([^"]+)"/)[1];
  assert.match(meta, /maximum-scale=1\b/);
  assert.match(meta, /viewport-fit=cover/);
});

test('nenhum campo de texto com fonte abaixo de 16px', ()=>{
  const culpados = regras(ler('styles.css'))
    .filter(r => /(^|[\s,>+~(])(input|select|textarea)\b/.test(r.sel))
    .flatMap(r => [...r.decl.matchAll(/font-size:\s*([\d.]+)px/g)].map(m => [r.sel, Number(m[1])]))
    .filter(([, px]) => px < 16);
  assert.deepEqual(culpados, [], 'fonte <16px em campo faz o iOS ampliar a página e não voltar');
});

test('fundo sem background-attachment fixed (o iOS repinta a cada quadro de rolagem)', ()=>{
  assert.doesNotMatch(ler('styles.css'), /background-attachment\s*:\s*fixed/);
});

test('capa da barra de status vale no app nativo e no PWA', ()=>{
  const css = ler('styles.css');
  assert.match(css, /html\.nativo body::after/);
  assert.match(css, /html\.standalone body::after/);
});
```

e em `tests/nativo.test.cjs`, no mesmo estilo dos testes existentes do arquivo (leia-o primeiro):

```js
test('marcarAmbiente: nativo e standalone viram classe no <html>', ()=>{
  const classes = new Set();
  const doc = { documentElement:{ classList:{ add:c=>classes.add(c) } } };
  const win = { Capacitor:{ isNativePlatform:()=>true, Plugins:{} }, matchMedia:()=>({ matches:false }), navigator:{} };
  criar(win).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['nativo']);
  classes.clear();
  const web = { matchMedia:q=>({ matches:q === '(display-mode: standalone)' }), navigator:{} };
  criar(web).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['standalone']);
  classes.clear();
  criar({ matchMedia:()=>({ matches:false }), navigator:{ standalone:true } }).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['standalone']);
});
```

(ajuste o nome do import de `criar` ao que o arquivo já usa).

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/ios.test.cjs tests/nativo.test.cjs` → FAIL (viewport sem maximum-scale; `.filter-row input` 14px e `.field input` 15px; `background-attachment:fixed` no body; sem `html.nativo body::after`; `marcarAmbiente` inexistente).

- [ ] **Step 3: Implementar**
  - `index.html:5`: `<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">`.
  - `nativo.js`: dentro de `criar(win)`, função `marcarAmbiente(doc)`:
    ```js
    function marcarAmbiente(doc){
      const cl = doc && doc.documentElement && doc.documentElement.classList;
      if(!cl) return;
      if(ehNativo()){ cl.add('nativo'); return; }
      const mm = q => { try{ return !!(win.matchMedia && win.matchMedia(q).matches); }catch(e){ return false; } };
      if(mm('(display-mode: standalone)') || (win.navigator && win.navigator.standalone === true)) cl.add('standalone');
    }
    ```
    exportar no objeto retornado e, no fim do arquivo, logo após `root.OBRA_NATIVO = criar(root)`: `if(root && root.document) root.OBRA_NATIVO.marcarAmbiente(root.document);`.
  - `styles.css`:
    - `.field input,.field select` 15px → 16px; `.filter-row input,.filter-row select` 14px → 16px; qualquer outra regra de campo <16px que o teste apontar → 16px.
    - `body`: remover `background-attachment:fixed` e os `radial-gradient` do `background` (fica `background:var(--bg)`); criar `body::before{content:"";position:fixed;inset:0;z-index:-1;pointer-events:none;background:radial-gradient(1100px 750px at 85% -5%, var(--glow-1), transparent 62%),radial-gradient(900px 700px at -10% 105%, var(--glow-2), transparent 60%)}`. Conferir no browser que o brilho continua aparecendo (o `html` não tem fundo próprio, então o fundo do body pinta o canvas e o `::before` fica por cima dele).
    - Trocar o `@media(display-mode:standalone){ body::after{...} }` por `html.nativo body::after, html.standalone body::after{content:"";position:fixed;top:0;left:0;right:0;height:env(safe-area-inset-top);background:var(--bg);z-index:90;pointer-events:none}`.
    - `@media (max-width:899px)`: `.card:not(.saldo),.panel{background:var(--surface-solid)}` (opaco: o globo não aparece através do conteúdo).
    - Chrome sem seleção: `button,nav.tabs,header.top,.back,ul.list li,.chip,.chip2{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}` (campos e `.li-main .t` continuam selecionáveis por herança? não: `ul.list li` desliga; aceite — linhas são alvos de toque, não texto a copiar).
  - `globe.js`: além do `running` existente, pausar quando `document.hidden` (`visibilitychange`) e durante rolagem/toque: `addEventListener('scroll', pausaTemporaria, {passive:true})`, idem `touchstart`/`touchmove`; `pausaTemporaria` marca pausado e agenda retomar 400ms após o último evento (clearTimeout/setTimeout). O `resize` só realoca o canvas quando `innerWidth` muda ou a altura nova é maior que a atual (a barra do Safari recolhendo não realoca). Expor `window.__globeEstado = () => ({ rodando: <laço ativo agora> })`. `prefers-reduced-motion` continua desenhando uma vez e parando.
  - `package.json`: acrescentar `tests/ios.test.cjs` à lista de `test:unit` (releia o arquivo antes).

- [ ] **Step 4: Rodar** — `node --test tests/ios.test.cjs tests/nativo.test.cjs` → PASS; `npm run test:unit` → tudo verde (falha só em arquivos de outra tarefa em andamento pode ser ignorada e relatada). Conferência visual rápida: `node tests/browser/servidor.cjs &` e um script Playwright 390×844 abrindo `http://localhost:8123` com `window.CLOUD` falso (copie o `addInitScript` de `tests/browser/mobile.cjs`) — tirar captura escura e clara e conferir que o brilho e o globo continuam.

- [ ] **Step 5: Commit (controlador)** — `fix: sem zoom preso nos campos e fundo que não trava a rolagem no iPhone`.

### Task 2: Barras no estilo iOS

**Files:**
- Modify: `index.html` (`header.top` vira barra de navegação no celular; título grande)
- Modify: `app.js` (`showView`/`renderObra`: título e direção da navegação; botão voltar da barra)
- Modify: `styles.css` (barra de navegação, título grande, barra de abas, `--barra` nos 4 blocos de tema, transições de tela)
- Test: `tests/ios.test.cjs`

**Interfaces:**
- Consumes: `html.nativo`/`html.standalone` (Task 1).
- Produces: `#navVoltar` — botão na barra que, ao clicar, faz `document.querySelector('section.view.active .back')?.click()`; visível só em `obra`, `relatorio`, `graficos` (atributo `hidden` nos demais). `#navTitulo` (título pequeno), `#tituloGrande` (h1 grande no topo do conteúdo), `header.top.colapsada` quando o título grande saiu da vista. `document.body.dataset.nav` = `'push' | 'pop' | 'aba'` a cada `showView`. A Task 4 usa `#navVoltar` e `section.view.active` para o voltar pela borda.

- [ ] **Step 1: Testes que falham** — acrescentar a `tests/ios.test.cjs`:

```js
test('barra de navegação iOS: voltar, título pequeno e título grande', ()=>{
  const html = ler('index.html');
  for(const id of ['navVoltar', 'navTitulo', 'tituloGrande']) assert.match(html, new RegExp(`id="${id}"`));
});

test('barras translúcidas com material por tema', ()=>{
  const css = ler('styles.css');
  const blocos = ['  :root{', '  html[data-theme="light"]{', '  html[data-skin="azul"]{', '  html[data-skin="azul"][data-theme="light"]{'];
  for(const b of blocos){
    const i = css.indexOf(b); assert.ok(i >= 0, `bloco ${b} sumiu`);
    const corpo = css.slice(i, css.indexOf('}', i));
    assert.match(corpo, /--barra:\s*rgba\(/, `${b} sem --barra`);
  }
  assert.match(css, /nav\.tabs\{[^}]*-webkit-backdrop-filter/);
  assert.match(css, /header\.top\.colapsada\{[^}]*-webkit-backdrop-filter/);
});

test('trocar de tela diz a direção da navegação', ()=>{
  const app = ler('app.js');
  assert.match(app, /document\.body\.dataset\.nav\s*=/);
});
```

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/ios.test.cjs` → FAIL nos 3 novos.

- [ ] **Step 3: Implementar**
  - `index.html`, dentro de `header.top`: antes do `h1`, `<button type="button" class="nav-voltar" id="navVoltar" hidden><span aria-hidden="true">‹</span> <span id="navVoltarTexto">Obras</span></button>`; depois do `h1`, `<span class="nav-titulo" id="navTitulo" aria-hidden="true"></span>`. Logo depois de `</header>`: `<h1 class="titulo-grande" id="tituloGrande">Obras</h1>`. No desktop (≥900px) `#navVoltar`, `#navTitulo` e `#tituloGrande` ficam `display:none` e o header continua como hoje.
  - `app.js`:
    - Mapa de títulos: `const TITULOS = { inicio:'Obras', simula:'Vale a pena?', ajustes:'Ajustes', relatorio:'Relatório', graficos:'Gráficos' };` e `function atualizaTitulo(){ const t = tab==='obra' ? (obraById(obraAberta)?.nome || 'Obra') : (TITULOS[tab] || ''); $('#tituloGrande').textContent = t; $('#navTitulo').textContent = t; const volta = ['obra','relatorio','graficos'].includes(tab); $('#navVoltar').hidden = !volta; $('#navVoltarTexto').textContent = tab==='obra' ? 'Obras' : 'Obra'; }` (usar `textContent`: nome de obra é texto do usuário).
    - Em `showView(v)`: antes de trocar `tab`, calcular a direção: `const nivel = x => x==='obra' ? 1 : (x==='relatorio'||x==='graficos') ? 2 : 0; document.body.dataset.nav = nivel(v) > nivel(tab) ? 'push' : nivel(v) < nivel(tab) ? 'pop' : 'aba';` e, no fim, `atualizaTitulo()`. Chamar `atualizaTitulo()` também no fim de `renderObra()` (nome editado).
    - `$('#navVoltar').onclick = ()=> document.querySelector('section.view.active .back')?.click();`
    - Colapso: `new IntersectionObserver(([e])=>$('header.top').classList.toggle('colapsada', !e.isIntersecting), { rootMargin: '-60px 0px 0px 0px' }).observe($('#tituloGrande'));` (guardar com `if('IntersectionObserver' in window)`).
  - `styles.css`:
    - Nos 4 blocos de tema: `--barra` — escuro esmeralda `rgba(4,16,12,.72)`, claro esmeralda `rgba(237,245,241,.78)`, escuro azul `rgba(7,12,24,.72)`, claro azul `rgba(238,242,249,.78)`.
    - `@media (max-width:899px)`:
      - `header.top{position:fixed;top:0;left:0;right:0;z-index:50;margin:0;display:grid;grid-template-columns:1fr auto 1fr;align-items:center;min-height:calc(44px + env(safe-area-inset-top));padding:env(safe-area-inset-top) 8px 0;background:transparent;border-bottom:.5px solid transparent;transition:background-color .2s,border-color .2s}`; `header.top h1{display:none}` (a logo sai no celular; o título grande assume); `.layout-22` (sync e sair) na coluna 3 alinhado à direita.
      - `header.top.colapsada{background:var(--barra);-webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px);border-bottom-color:var(--border)}`.
      - `.nav-titulo{grid-column:2;font-size:17px;font-weight:600;opacity:0;transition:opacity .2s;max-width:60vw;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}`; `header.top.colapsada .nav-titulo{opacity:1}`.
      - `.nav-voltar{grid-column:1;justify-self:start;border:0;background:transparent;color:var(--brand);font-size:17px;min-height:44px;padding:0 8px;display:flex;align-items:center;gap:2px}`; `.nav-voltar span:first-child{font-size:30px;line-height:1;margin-top:-3px}`; `.nav-voltar:active{opacity:.5}`.
      - `section.view > .back{display:none}` (o voltar mora na barra).
      - `.titulo-grande{font-size:34px;font-weight:700;letter-spacing:-.02em;margin:4px 4px 14px;line-height:1.15;overflow-wrap:anywhere}`; `.app{padding-top:calc(44px + env(safe-area-inset-top))}`.
      - Remover a capa `html.nativo body::after, html.standalone body::after` no celular (`display:none` dentro deste media query): a barra de navegação cobre a área do relógio.
      - `nav.tabs{background:var(--barra);-webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px);border-top:.5px solid var(--border);padding:0 0 env(safe-area-inset-bottom);min-height:calc(49px + env(safe-area-inset-bottom))}`; `nav.tabs button{border-radius:0;padding:6px 0 2px;font-size:11px;gap:3px;min-height:49px}`; `nav.tabs button .ti{font-size:25px}`; `nav.tabs button:active{opacity:.5}`. Ajustar o comentário antigo ("fundo sólido: transparência/blur deixava a barra flutuando") para dizer por que agora é translúcida.
      - `body{padding-bottom:calc(49px + 16px + env(safe-area-inset-bottom))}` e `body.com-fab{padding-bottom:calc(49px + 96px + env(safe-area-inset-bottom))}`; `.fab{bottom:calc(49px + 16px + env(safe-area-inset-bottom));box-shadow:0 4px 14px var(--fab-shadow)}`; `.toast-wrap{bottom:calc(49px + 90px + env(safe-area-inset-bottom))}`.
      - Transições: `body[data-nav="push"] section.view.active{animation:entra-direita .32s cubic-bezier(.2,.8,.2,1)}`, `body[data-nav="pop"] section.view.active{animation:entra-esquerda .32s cubic-bezier(.2,.8,.2,1)}`, `body[data-nav="aba"] section.view.active{animation:fade .18s ease}` com `@keyframes entra-direita{from{transform:translateX(30%);opacity:.6}to{transform:none;opacity:1}}` e `entra-esquerda` (from `-20%`). Em `@media (prefers-reduced-motion: reduce)`: `animation:none`.

- [ ] **Step 4: Rodar** — `node --test tests/ios.test.cjs` → PASS; `npm run test:unit` verde; captura Playwright 390×844 (escuro e claro) do início, da obra rolada para baixo (barra colapsada) e de Ajustes, conferindo: título grande visível no topo, barra transparente no topo e com material ao rolar, "‹ Obras" na obra, tab bar translúcida, FAB acima dela.

- [ ] **Step 5: Commit (controlador)** — `feat: barras de navegação e de abas no padrão iOS`.

### Task 3: Conteúdo no estilo iOS

**Files:**
- Modify: `styles.css` (grupos, listas, busca, botões, sheet com alça)
- Modify: `app.js` (chevron na lista de obras; lupa na busca dos lançamentos)
- Test: `tests/ios.test.cjs`

**Interfaces:**
- Consumes: estrutura existente (`.panel`, `.card`, `ul.list li`, `.filter-row`, `.btn`, `.sheet`).
- Produces: `.sheet::before` (alça visual, 36×5px, no topo do sheet). A Task 4 trata os primeiros 32px do `#sheet` como zona de arrasto.

- [ ] **Step 1: Testes que falham** — acrescentar a `tests/ios.test.cjs`:

```js
test('conteúdo no padrão iOS: alça no sheet, linha de lista alta, botão alto', ()=>{
  const css = ler('styles.css');
  assert.match(css, /\.sheet::before\{/);
  assert.match(css, /ul\.list li\{[^}]*min-height:\s*56px/);
  assert.match(css, /\.btn\{[^}]*min-height:\s*50px/);
});

test('lista de obras com chevron e busca com lupa', ()=>{
  const app = ler('app.js');
  assert.match(app, /class="chevron"/);
  assert.match(app, /class="busca-ic"/);
});
```

(os seletores exatos podem ficar dentro do `@media (max-width:899px)`; o teste só procura a regra).

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/ios.test.cjs`.

- [ ] **Step 3: Implementar** — `@media (max-width:899px)` salvo indicação:
  - `.panel,.card{border-radius:14px;border:0;box-shadow:none}` (o `.card.saldo` mantém o gradiente e ganha `box-shadow:none`); `.panel{padding:14px 16px}`; `.panel h2{font-size:17px;font-weight:600}`.
  - `ul.list li{min-height:56px;border-bottom:0;position:relative;padding:10px 4px}`; separador fino recuado: `ul.list li + li::before{content:"";position:absolute;top:0;left:54px;right:0;height:.5px;background:var(--border)}`; `ul.list li:active{background:var(--surface-2)}` com `border-radius:10px`.
  - Lista de obras (`renderInicio` em `app.js`, onde monta cada `li` de `#obrasList`): acrescentar ao fim da linha `<span class="chevron" aria-hidden="true">›</span>`; CSS `.chevron{color:var(--muted);font-size:22px;margin-left:4px;flex:none}`.
  - Busca dos lançamentos (`.filter-row` em `app.js:356` e `:383`): envolver o `input` de texto em `<label class="busca"><span class="busca-ic" aria-hidden="true">${ICON('lupa')}</span>…input…</label>` (se `ICON('lupa')` não existir em `icons.js`, acrescente o SVG no mesmo padrão dos outros e rode `tests/icons.test.cjs`); CSS: `.busca{position:relative;flex:1;min-width:0}`, `.busca-ic{position:absolute;left:10px;top:50%;transform:translateY(-50%);color:var(--muted);pointer-events:none}`, `.busca input{padding-left:34px;border-radius:10px;border:0;background:var(--surface-2);min-height:40px;width:100%}`; o `select` do mês com `border:0;border-radius:10px;min-height:40px;background:var(--surface-2)`.
  - Botões: `.btn{min-height:50px;border-radius:12px;font-size:17px;font-weight:600}`, `.btn:active{opacity:.6}`; `.btn.ghost` tingido: `background:var(--brand-soft);color:var(--brand);border:0`.
  - Sheet: `.sheet{border-radius:14px 14px 0 0;padding-top:22px;position:relative}`, `.sheet::before{content:"";position:absolute;top:7px;left:50%;width:36px;height:5px;margin-left:-18px;border-radius:3px;background:var(--muted);opacity:.45}`.
  - Toque: `.card,.panel li,.chip,.chip2,.back,.li-del{-webkit-tap-highlight-color:transparent}`; `.chip:active,.chip2:active{opacity:.6}`.
  - Conferir as quatro combinações com `node tests/browser/contraste.cjs` (servidor no ar) — se algum novo par cor/fundo cair abaixo de 4.5:1, ajustar a cor, não o teste.

- [ ] **Step 4: Rodar** — `node --test tests/ios.test.cjs tests/icons.test.cjs` → PASS; `npm run test:unit` verde; `node tests/browser/mobile.cjs` e `node tests/browser/contraste.cjs` com o servidor no ar → OK; capturas 390×844 escuro/claro de Obras, obra aberta e um sheet de gasto.

- [ ] **Step 5: Commit (controlador)** — `feat: listas, grupos, busca e sheets no padrão iOS`.

### Task 4: Gestos de iPhone (`gestos.js`)

**Files:**
- Create: `gestos.js`, `tests/gestos.test.cjs`
- Modify: `index.html` (script depois de `app.js`), `sw.js` (`ASSETS` + `CACHE` `obras-v53`), `package.json` (`test:unit` inclui `tests/gestos.test.cjs`), `styles.css` (apenas o bloco `/* gestos */` no fim do arquivo), `CLAUDE.md` (linha de `gestos.js` na tabela de arquitetura)

**Interfaces:**
- Consumes: `OBRA_NATIVO.vibrar()`; `closeSheet()` (global do `app.js`); `#sheet`, `#backdrop`; `html.nativo`/`html.standalone`; `#navVoltar` (Task 2) com recuo para `section.view.active .back` enquanto a Task 2 não existir.
- Produces: `window.OBRA_GESTOS` = `{ eixo, fimArrastoLinha, fimArrastoSheet, fimArrastoBorda, bordaAtiva, iniciar }`; `module.exports` com as mesmas funções puras.

- [ ] **Step 1: Testes que falham** — `tests/gestos.test.cjs`:

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const G = require('../gestos.js');

test('eixo: só decide depois de 10px e exige predominância horizontal', ()=>{
  assert.equal(G.eixo(5, 3), null);
  assert.equal(G.eixo(-30, 5), 'h');
  assert.equal(G.eixo(12, 11), 'v'); // diagonal fica com a rolagem
  assert.equal(G.eixo(2, 40), 'v');
});

test('linha: abre além da metade do botão ou com rapidez para a esquerda', ()=>{
  assert.equal(G.fimArrastoLinha(-50, 0), 'abrir');
  assert.equal(G.fimArrastoLinha(-30, 0), 'fechar');
  assert.equal(G.fimArrastoLinha(-15, -0.8), 'abrir');
  assert.equal(G.fimArrastoLinha(-70, 0.8), 'fechar');
});

test('sheet: fecha passando de 120px ou puxão rápido', ()=>{
  assert.equal(G.fimArrastoSheet(130, 0), 'fechar');
  assert.equal(G.fimArrastoSheet(60, 1.2), 'fechar');
  assert.equal(G.fimArrastoSheet(60, 0.2), 'voltar');
  assert.equal(G.fimArrastoSheet(20, 2), 'voltar'); // tremida curta não fecha
});

test('borda: volta além de 35% da largura ou com rapidez', ()=>{
  assert.equal(G.fimArrastoBorda(150, 0, 390), 'voltar');
  assert.equal(G.fimArrastoBorda(100, 0, 390), 'cancelar');
  assert.equal(G.fimArrastoBorda(60, 0.7, 390), 'voltar');
});

test('borda só no app nativo ou no PWA instalado, e só nos primeiros 24px', ()=>{
  const cl = (...c) => ({ contains: x => c.includes(x) });
  assert.equal(G.bordaAtiva(10, cl('nativo')), true);
  assert.equal(G.bordaAtiva(10, cl('standalone')), true);
  assert.equal(G.bordaAtiva(10, cl()), false);   // Safari comum: a borda é do navegador
  assert.equal(G.bordaAtiva(30, cl('nativo')), false);
});
```

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/gestos.test.cjs` → FAIL (`Cannot find module '../gestos.js'`).

- [ ] **Step 3: `gestos.js`** — lógica pura:

```js
/* Gestos de iPhone: arrastar a linha para apagar, puxar o sheet para fechar e
   voltar arrastando da borda. Lógica pura exportada para testes; a ligação ao
   DOM é por delegação, sem tocar nos renderizadores do app.js. */
'use strict';
(function(root){
  const LARGURA_APAGAR = 80;
  function eixo(dx, dy){
    const ax = Math.abs(dx), ay = Math.abs(dy);
    if(ax < 10 && ay < 10) return null;
    return ax > ay * 1.2 ? 'h' : 'v';
  }
  function fimArrastoLinha(dx, vx){
    if(vx < -0.5) return 'abrir';
    if(vx > 0.5) return 'fechar';
    return -dx > LARGURA_APAGAR / 2 ? 'abrir' : 'fechar';
  }
  function fimArrastoSheet(dy, vy){
    return dy > 120 || (vy > 0.8 && dy > 30) ? 'fechar' : 'voltar';
  }
  function fimArrastoBorda(dx, vx, largura){
    return dx > largura * 0.35 || (vx > 0.5 && dx > 40) ? 'voltar' : 'cancelar';
  }
  function bordaAtiva(x, classes){
    return x <= 24 && (classes.contains('nativo') || classes.contains('standalone'));
  }
  // iniciar(win) — ver passo seguinte
  const api = { eixo, fimArrastoLinha, fimArrastoSheet, fimArrastoBorda, bordaAtiva, LARGURA_APAGAR };
  if(typeof module !== 'undefined') module.exports = api;
  if(root && root.document){ api.iniciar = win => iniciar(win); root.OBRA_GESTOS = api; api.iniciar(root); }
})(typeof window !== 'undefined' ? window : null);
```

  e `iniciar(win)` (dentro do mesmo IIFE, antes de `api`), com velocidade em px/ms calculada entre os dois últimos `touchmove`:
  - **Linha:** `touchstart` (passivo) em `document`: se o alvo está dentro de um `li` que tem filho direto `.li-del`, guarda `{li, x0, y0, t0, aberta: li.classList.contains('aberta')}`; qualquer outra linha `.aberta` fecha. `touchmove` (passivo): decide `eixo`; se `'h'`, na primeira vez injeta (se não existir) `<button type="button" class="acao-apagar">Apagar</button>` como último filho do `li` e marca `li.classList.add('swipe','arrastando')`; atualiza `li.style.setProperty('--dx', clamp(dx + (aberta ? -80 : 0), -120, 0) + 'px')`; ao cruzar −40px pela primeira vez chama `OBRA_NATIVO?.vibrar()`. `touchend`: `fimArrastoLinha` → `'abrir'` fixa `--dx:-80px` e `.aberta`; `'fechar'` volta a `0` e remove `.aberta`. Clique em `.acao-apagar` → fecha a linha e chama `li.querySelector(':scope > .li-del').click()` (o diálogo de confirmação e o fluxo de parcelas continuam os de hoje). `scroll` em `window` fecha a linha aberta.
  - **Sheet:** `touchstart` em `#sheet` quando `sheet.scrollTop === 0` e o toque começa nos 32px de cima do sheet ou em qualquer ponto com `scrollTop === 0` movendo para baixo; `touchmove` **não passivo** no `#sheet`: com `eixo === 'v'` e `dy > 0`, `preventDefault()` e `sheet.style.setProperty('--dy', dy + 'px')` + classe `arrastando`; `touchend`: `fimArrastoSheet` → `'fechar'` chama `closeSheet()` e `vibrar()`; `'voltar'` anima de volta (remove `--dy`).
  - **Borda:** `touchstart` com `bordaAtiva(x, document.documentElement.classList)` e tela atual com voltar (`#navVoltar` sem `hidden`, ou `section.view.active .back` visível): acompanha com `--dx-tela` em `section.view.active` e classe `arrastando-borda` (removida no fim, sempre); `touchend`: `fimArrastoBorda(dx, vx, innerWidth)` → `'voltar'` dispara `($('#navVoltar:not([hidden])') || document.querySelector('section.view.active .back')).click()`; senão anima de volta.
  - **Vibração nas abas:** `click` delegado em `button[data-tab]` → `OBRA_NATIVO?.vibrar()`.
  - Tudo embrulhado em `try` com `win.OBRA_DIAG?.registra('gestos', ...)` em erro: gesto nunca derruba o app.

- [ ] **Step 4: CSS dos gestos** — no fim de `styles.css`, bloco `/* gestos (gestos.js) */`:

```css
  li.swipe{position:relative;overflow:hidden;touch-action:pan-y}
  li.swipe > :not(.acao-apagar){transform:translateX(var(--dx,0px));transition:transform .25s cubic-bezier(.2,.8,.2,1)}
  li.swipe.arrastando > :not(.acao-apagar){transition:none}
  .acao-apagar{position:absolute;top:0;right:0;bottom:0;width:80px;border:0;background:var(--red);color:#fff;font-size:15px;font-weight:600}
  .sheet{transform:translateY(var(--dy,0px));transition:transform .25s cubic-bezier(.2,.8,.2,1)}
  .sheet.arrastando{transition:none}
  /* transform só durante o arrasto: fora dele, transform na tela viraria bloco de contenção dos position:fixed internos */
  section.view.active.arrastando-borda{transform:translateX(var(--dx-tela,0px))}
  @media (pointer:coarse){
    ul.list li > .li-del{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
  }
  @media (prefers-reduced-motion: reduce){ li.swipe > :not(.acao-apagar),.sheet{transition:none} }
```

  (o "×" some da vista em tela de toque mas fica no DOM para VoiceOver e teclado; confirme o contraste do branco sobre `--red` nos quatro combos).

- [ ] **Step 5: Ligar** — `index.html`: `<script defer src="gestos.js"></script>` logo depois da linha do `app.js`; `sw.js`: `'./gestos.js'` em `ASSETS` e `CACHE = 'obras-v53'`; `package.json`: `tests/gestos.test.cjs` em `test:unit`; `CLAUDE.md`: linha `| [gestos.js](gestos.js) | OBRA_GESTOS + module.exports | gestos de iPhone: arrastar para apagar, puxar sheet, voltar pela borda |` na tabela de Arquitetura. Rodar `node --test tests/pwa.test.cjs tests/build-www.test.mjs` (conferem ASSETS/build).

- [ ] **Step 6: Rodar** — `node --test tests/gestos.test.cjs` PASS; `npm run test:unit` verde.

- [ ] **Step 7: Commit (controlador)** — `feat: arrastar para apagar, puxar o sheet e voltar pela borda`.

### Task 5: Validação de ponta a ponta (suíte `ios.cjs` + agent-browser)

**Files:**
- Create: `tests/browser/ios.cjs`; Modify: `tests/browser/rodar.cjs` (roda `ios.cjs` depois de `mobile.cjs`)

- [ ] **Step 1: Suíte** — `tests/browser/ios.cjs`, no padrão de `tests/browser/nativo.cjs` (copie a função `abrir` com `window.CLOUD` falso e `window.Capacitor` falso), contexto `{ viewport:{width:390,height:844}, isMobile:true, hasTouch:true, deviceScaleFactor:3 }`, dados com uma obra e 12 gastos. Asserções:
  1. Em cada tela (`inicio`, obra aberta, `simula`, `ajustes`, sheet de novo gasto aberto pelo FAB): todo `input`/`select`/`textarea` visível tem `parseFloat(getComputedStyle(el).fontSize) >= 16`.
  2. Em cada uma dessas telas: `document.documentElement.scrollWidth === 390`.
  3. Nativo: `document.documentElement.classList.contains('nativo')`.
  4. Rolar a obra até o fim → `header.top` tem `colapsada` e `#navTitulo` tem o nome da obra; voltar ao topo → sem `colapsada`.
  5. Globo: `__globeEstado().rodando === false` logo após disparar `scroll`; `true` 600ms depois.
  6. Arrastar para apagar: sintetizar `touchstart`/`touchmove`/`touchend` (via `page.evaluate` com `new Touch({identifier:1,target,clientX,clientY})` e `new TouchEvent(tipo,{touches,changedTouches,bubbles:true,cancelable:true})`) de `x=300` a `x=180` na primeira `.gasto-row` → linha com classe `aberta` e botão `.acao-apagar` visível; clicar em "Apagar" → abre o diálogo de confirmação (`OBRA_CONFIRM`) com "Excluir este gasto?"; confirmar → um gasto a menos. Abrir outra linha e disparar `scroll` → nenhuma `li.aberta` restante.
  7. Puxar sheet: abrir o sheet do FAB, arrastar do topo do `#sheet` 200px para baixo → `#backdrop` sem `show`.
  8. Voltar pela borda (nativo): na obra aberta, arrastar de `x=5` a `x=250` → `section.view.active` é `#v-inicio`. Sem `nativo`/`standalone` (contexto web comum): o mesmo gesto não volta.
  9. Nenhum erro de página nem violação de CSP (`errosPagina` vazio).
  Salvar capturas em `$TMPDIR/custta-ios-*.png` (escuro e claro).
- [ ] **Step 2: Rodar** — servidor no ar; `node tests/browser/ios.cjs`, `node tests/browser/mobile.cjs`, `node tests/browser/nativo.cjs`, `node tests/browser/contraste.cjs` → todos OK; `npm run test:unit` verde.
- [ ] **Step 3: Commit (controlador)** — `test: suíte de navegador do visual e dos gestos iOS`.
- [ ] **Step 4 (controlador):** push, PR em prosa, CI verde; agent-browser no preview da Vercel (`agent-browser set viewport 390 844`, `set device "iPhone 14"` se disponível) com capturas de Obras, obra aberta rolada, sheet e Ajustes, escuro e claro; `gh workflow run ios-testflight.yml --ref feat/ios-nativo` e acompanhar até o build aparecer no TestFlight.
