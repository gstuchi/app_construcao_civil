# Ícones minimalistas + máscara de moeda — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir todos os emojis da UI por ícones SVG de linha embutidos e formatar os campos de dinheiro ao digitar (`2000000` → `R$ 2.000.000,00`).

**Architecture:** Novo `icons.js` (registro de paths SVG + helper global `ICON()` + auto-substituição de `[data-ico]`). Funções puras de formatação entram em `calc.js` (testáveis em Node); `app.js` só aplica. Nada muda no formato dos dados salvos na nuvem.

**Tech Stack:** Vanilla JS (scripts clássicos, globais `OBRA_CALC`/`ICON`), PWA offline (sw.js cache-first), testes Node puros (`node tests/*.cjs`), e2e com puppeteer-core + Edge headless.

## Global Constraints

- Sem CDN / sem dependência externa em runtime — tudo embutido (PWA offline, spec).
- Estética dark atual (cores, globo) intocável — decisão do pai.
- Ícones: traço `stroke="currentColor"`, `fill="none"`, `stroke-width="2"`, viewBox `0 0 24 24` (estilo Lucide).
- Máscara: dígitos = reais inteiros; vírgula abre centavos; blur completa `,00`; prefixo `R$` fixo fora do input.
- `#ajTaxa`, `#simMeses`, `#cCpf` NÃO recebem máscara.
- Zero emoji sobrando na UI ao final (verificação e2e com regex de faixas Unicode).
- Bump do cache do SW (`obras-v4` → `obras-v5`) e `icons.js` na lista `ASSETS`.

---

### Task 0: Branch

- [ ] **Step 1:** `git checkout -b design-icones-moeda` (a partir de `main` limpa).

---

### Task 1: `icons.js` — registro de ícones + helper `ICON()`

**Files:**
- Create: `icons.js`
- Create: `tests/icons.test.cjs`
- Modify: `index.html` (adicionar `<script src="icons.js"></script>` ANTES dos scripts `auth.js` e `app.js`, no fim do body)
- Modify: `sw.js:2-3` (cache `obras-v5`, `'./icons.js'` em `ASSETS`)

**Interfaces:**
- Produces: global `ICON(nome, cls) -> string` (SVG completo; `cls` opcional vira classe extra). Nome desconhecido cai no ícone `etiqueta`. Também processa automaticamente todo elemento com `data-ico="nome"` no carregamento (define `innerHTML`). Em Node (`require`), exporta `{ICON, ICONES}`.

- [ ] **Step 1: Teste que falha** — criar `tests/icons.test.cjs`:

```js
'use strict';
const assert = require('assert');
const { ICON, ICONES } = require('../icons.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

t('ICON devolve svg com viewBox e stroke', () => {
  const s = ICON('casa');
  assert.ok(s.startsWith('<svg'));
  assert.ok(s.includes('viewBox="0 0 24 24"'));
  assert.ok(s.includes('stroke="currentColor"'));
});

t('ICON aceita classe extra', () => {
  assert.ok(ICON('casa','k-ic').includes('class="ico k-ic"'));
});

t('nome desconhecido cai na etiqueta', () => {
  assert.strictEqual(ICON('naoexiste'), ICON('etiqueta'));
});

t('todos os ícones necessários existem', () => {
  const precisa = ['guindaste','predio','casa','check','balanca','engrenagem','sair',
    'moedas','notas','banco','alvo','acordo','setaCima','setaBaixo','calculadora',
    'mapa','regua','pa','tijolos','raio','gota','porta','camadas','rolo','arvore',
    'capacete','caixa','etiqueta','cartao','lapis','documento','impressora','voltar',
    'recibo','calendario','alerta','instalar','olho','olhoFechado'];
  precisa.forEach(k => assert.ok(ICONES[k], 'falta ícone: ' + k));
});

console.log(`\n${n} testes passaram ✔`);
```

- [ ] **Step 2:** `node tests/icons.test.cjs` → FALHA (`Cannot find module '../icons.js'`).

- [ ] **Step 3: Implementar `icons.js`** (padrão UMD igual ao `calc.js:68-69`):

```js
/* Ícones SVG de linha (estilo Lucide) embutidos — sem CDN, funciona offline.
   Browser: globais ICON() e ICONES + auto-substituição de [data-ico].
   Node (testes): module.exports. */
'use strict';
(function(root){
  const ICONES = {
    guindaste:  '<path d="M3 21h18M6 21V4m0 0H3m3 0h13m-3 0v6"/><circle cx="16" cy="12" r="2"/>',
    predio:     '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18"/><path d="M2 22h20"/><path d="M10 6h1M13 6h1M10 10h1M13 10h1M10 14h1M13 14h1"/>',
    casa:       '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/>',
    check:      '<path d="m4 12 5 5L20 7"/>',
    balanca:    '<path d="M12 3v18M7 21h10"/><path d="m5 7 7-2 7 2"/><path d="M5 7l-2.5 6a3 3 0 0 0 5 0L5 7Z"/><path d="M19 7l-2.5 6a3 3 0 0 0 5 0L19 7Z"/>',
    engrenagem: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    sair:       '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>',
    moedas:     '<circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/>',
    notas:      '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 12h.01M18 12h.01"/>',
    banco:      '<path d="M3 21h18M4 18h16M6 18v-7M10 18v-7M14 18v-7M18 18v-7M3 8l9-5 9 5H3Z"/>',
    alvo:       '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
    acordo:     '<path d="m11 17 2 2a1.5 1.5 0 0 0 2.12-2.12"/><path d="m14 14 2.5 2.5a1.5 1.5 0 0 0 2.12-2.12L13.5 9.27a3 3 0 0 0-4.24 0L8 10.5"/><path d="m21 12 1-1-6.5-6.5-2 2"/><path d="M3 11l-1 1 6.5 6.5 1.5-1.5"/><path d="M2 10 8.5 3.5 10.5 5.5"/>',
    setaCima:   '<path d="M12 19V5m-6 6 6-6 6 6"/>',
    setaBaixo:  '<path d="M12 5v14m-6-6 6 6 6-6"/>',
    calculadora:'<rect x="4" y="2" width="16" height="20" rx="2"/><path d="M8 6h8M8 11h.01M12 11h.01M16 11h.01M8 15h.01M12 15h.01M16 15h.01M8 19h.01M12 19h.01M16 19h.01"/>',
    mapa:       '<path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Z"/><path d="M9 4v14M15 6v14"/>',
    regua:      '<path d="M21 8 16 3 3 16l5 5L21 8Z"/><path d="m10 9 1 1M13 6l1 1M7 12l1 1"/>',
    pa:         '<path d="M12 3v9M10 3h4"/><path d="M8 12h8l-1 5a3 3 0 0 1-6 0z"/>',
    tijolos:    '<rect x="3" y="8" width="18" height="12" rx="1"/><path d="M3 14h18M9 8v6M15 8v6M6 14v6M12 14v6M18 14v6"/>',
    raio:       '<path d="M13 2 4 14h6l-1 8 9-12h-6l1-8Z"/>',
    gota:       '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11Z"/>',
    porta:      '<path d="M4 21h16M6 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16"/><circle cx="15" cy="12" r="1"/>',
    camadas:    '<path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="m3 13 9 5 9-5"/>',
    rolo:       '<rect x="3" y="4" width="14" height="5" rx="1"/><path d="M17 6h3a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-8v3"/><rect x="10" y="14" width="4" height="7" rx="1"/>',
    arvore:     '<path d="m12 3 5 7h-3l4 6H6l4-6H7l5-7Z"/><path d="M12 16v5"/>',
    capacete:   '<path d="M2 18a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1Z"/><path d="M10 10V5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v5"/><path d="M4 15v-3a6 6 0 0 1 6-6"/><path d="M14 6a6 6 0 0 1 6 6v3"/>',
    caixa:      '<path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5M12 22V12"/>',
    etiqueta:   '<path d="M2 12V4a2 2 0 0 1 2-2h8l10 10-10 10L2 12Z"/><circle cx="7" cy="7" r="1"/>',
    cartao:     '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/>',
    lapis:      '<path d="M17 3a2.85 2.85 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
    documento:  '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v5h6"/>',
    impressora: '<path d="M6 9V2h12v7"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/>',
    voltar:     '<path d="M9 14 4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
    recibo:     '<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M8 7h8M8 11h8M8 15h5"/>',
    calendario: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    alerta:     '<path d="m10.3 3.7-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.7-3l-8-14a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/>',
    instalar:   '<rect x="6" y="2" width="12" height="20" rx="2"/><path d="M12 7v6m-3-3 3 3 3-3"/>',
    olho:       '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
    olhoFechado:'<path d="M2 12s3.5-7 10-7c2 0 3.8.7 5.3 1.6M22 12s-3.5 7-10 7c-2 0-3.8-.7-5.3-1.6"/><path d="m3 3 18 18"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
  };

  function ICON(nome, cls){
    const p = ICONES[nome] || ICONES.etiqueta;
    return `<svg class="ico${cls ? ' '+cls : ''}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ICON, ICONES };
  } else {
    root.ICON = ICON; root.ICONES = ICONES;
    const aplica = () => document.querySelectorAll('[data-ico]').forEach(e => { e.innerHTML = ICON(e.dataset.ico); });
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', aplica);
    else aplica();
  }
})(typeof self !== 'undefined' ? self : this);
```

- [ ] **Step 4:** `node tests/icons.test.cjs` → `4 testes passaram ✔` (e `node tests/calc.test.cjs` continua verde).

- [ ] **Step 5: Ligar no app** — em `index.html`, junto dos outros `<script>` no fim do body, adicionar `<script src="icons.js"></script>` na frente de `auth.js`/`app.js`. Em `sw.js`:

```js
const CACHE = 'obras-v5';
const ASSETS = ['./', './index.html', './app.js', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './manifest.json', './icon.svg'];
```

- [ ] **Step 6:** Commit: `git add icons.js tests/icons.test.cjs index.html sw.js && git commit -m "feat: icons.js com icones SVG de linha embutidos"`.

---

### Task 2: `index.html` — emojis estáticos viram `data-ico` + CSS

**Files:**
- Modify: `index.html` (markup ~linhas 241-388 + bloco `<style>`)

**Interfaces:**
- Consumes: `ICON()`/auto `[data-ico]` da Task 1.
- Produces: classes CSS `.ico` (tamanho/alinhamento) e `.money` (prefixo R$) usadas pelas Tasks 3 e 5.

- [ ] **Step 1: CSS** — no `<style>` de `index.html`, junto das utilidades:

```css
.ico{width:1.15em;height:1.15em;display:inline-block;vertical-align:-0.2em;flex-shrink:0}
.money{display:flex;align-items:center;gap:8px}
.money>b{font-weight:600;color:var(--muted);font-size:.95em}
.money>input{flex:1;min-width:0}
```

- [ ] **Step 2: Trocar os emojis estáticos** (mapa exato, emoji some e o span ganha `data-ico`):

| Linha (hoje) | De | Para |
| --- | --- | --- |
| 241 | `Role para entrar ↓` | `Role para entrar <span data-ico="setaBaixo"></span>` |
| 255, 269 | `>👁<` | `data-ico="olho"` no botão (`<button ... data-eye="lSenha" data-ico="olho"></button>`) |
| 282, 291 | `<span class="logo">🏗️</span>` | `<span class="logo" data-ico="guindaste"></span>` |
| 283, 386 | `<span class="ti">🏗️</span>` | `<span class="ti" data-ico="predio"></span>` |
| 284, 387 | `<span class="ti">🤔</span>` | `<span class="ti" data-ico="balanca"></span>` |
| 285, 388 | `<span class="ti">⚙️</span>` | `<span class="ti" data-ico="engrenagem"></span>` |
| 286 | `<span class="ti">🚪</span>` | `<span class="ti" data-ico="sair"></span>` |
| 293 | `>🚪<` | `data-ico="sair"` no `#btnSair` (esvaziar texto) |
| 298 | `<span>📲</span>` | `<span data-ico="instalar"></span>` |
| 306 | `<span class="k-ic">💰</span>` | `<span class="k-ic" data-ico="moedas"></span>` |
| 344 | `<h2>🤔 Será que...` | `<h2><span data-ico="balanca"></span> Será que...` |
| 378 | `>🚪 Sair da conta<` | `><span data-ico="sair"></span> Sair da conta<` |

- [ ] **Step 3: Máscara no simulador** — linha 348, embrulhar:

```html
<div class="field"><label for="simValor">Se eu vender por</label>
  <div class="money"><b>R$</b><input id="simValor" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>
```

- [ ] **Step 4: Conferir no navegador** — `npx -y http-server -p 8123 .` e abrir `http://localhost:8123`: tela de login e cascas das abas sem emoji, ícones alinhados com o texto. Ajustar `.ico` se desalinhado.

- [ ] **Step 5:** Commit: `git add index.html && git commit -m "feat: emojis estaticos viram icones data-ico + css .ico/.money"`.

---

### Task 3: `app.js` + `auth.js` — emojis dinâmicos viram `ICON()`

**Files:**
- Modify: `app.js` (TOPICOS/FASES linhas 6-27; templates 119-627; renderAjustes 645-666)
- Modify: `auth.js:77-81` (olho da senha)

**Interfaces:**
- Consumes: `ICON(nome, cls)` global (Task 1).
- Produces: convenção `ic` agora guarda NOME de ícone (`'mapa'`), não emoji. Tópicos custom novos salvam `ic:'etiqueta'`; antigos com emoji `🏷️` no banco caem no fallback do `ICON()` (nome desconhecido → etiqueta) — nada quebra e não precisa migrar dado.

- [ ] **Step 1: Tabelas** — `TOPICOS` (app.js:6-21): `ic:` vira `'mapa','regua','pa','guindaste','tijolos','casa','raio','gota','porta','camadas','rolo','arvore','capacete','caixa'` (ordem atual). `FASES` (23-27): `construcao:'guindaste'`, `pronta:'casa'`, `vendida:'check'`.

- [ ] **Step 2: Onde `ic` é interpolado, embrulhar com `ICON()`** — todas as ocorrências:
  - `app.js:125` `>${f.ic}<` → `>${ICON(f.ic)}<`
  - `app.js:281` e `:526` `t.ic` usado no `.av`/relatório → `ICON(t.ic)`
  - `app.js:306-310` linha do gasto: `t.ic` → `ICON(t.ic)`; `pIc` vira `g.pagamento==='cartao' ? ICON('cartao')+' ' : g.pagamento==='pix' ? ICON('raio')+' ' : ''`
  - `app.js:444` chip de tópico: `` `${t.ic} ${t.nm}` `` → `` `${ICON(t.ic)} ${t.nm}` ``
  - `app.js:457` chips pagamento: `[['pix','⚡ Pix'],['cartao','💳 Cartão']]` → `` [['pix',ICON('raio')+' Pix'],['cartao',ICON('cartao')+' Cartão']] ``
  - `app.js:645,648` `🏷️` → `ICON('etiqueta')`
  - `app.js:666` novo tópico custom: `ic:'🏷️'` → `ic:'etiqueta'`
  - `app.js:281,306` fallback `ic:'🏷️'` → `ic:'etiqueta'`

- [ ] **Step 3: Emojis literais nos templates** — substituição direta:
  - `:119` `emptyBlock('🏗️',...)` → `emptyBlock(ICON('guindaste'),...)`; `:250` `'🧾'` → `ICON('recibo')`; `:294` `'📅'` → `ICON('calendario')`
  - `:172` `✏️` → `${ICON('lapis')}`; `:182` `💸` → `${ICON('notas')}`; `:192,615` `↑` → `${ICON('setaCima')}`; `:196,619` `🏦` → `${ICON('banco')}`; `:200` `🤝` → `${ICON('acordo')}`; `:206` `🎯` → `${ICON('alvo')}`
  - `:217` `🏠 Marcar` → `${ICON('casa')} Marcar`; `:219` `🤝 Registrar` → `${ICON('acordo')} Registrar`; `:220,221` `↩` → `${ICON('voltar')}`; `:222` `📄` → `${ICON('documento')}`
  - `:418` `💳 Parcela` → `${ICON('cartao')} Parcela`
  - `:539` `🤝 Venda` → `${ICON('acordo')} Venda`; `:544` `🎯 Venda estimada` → `${ICON('alvo')} Venda estimada`; `:550` `📄 Relatório` → `${ICON('documento')} Relatório`; `:565` `🖨️` → `${ICON('impressora')}`
  - `:609` `${bate?'✅':'⚠️'}` → `${bate?ICON('check'):ICON('alerta')}`; `:623` `🧮` → `${ICON('calculadora')}`
  - `auth.js:80` `b.textContent = i.type==='password' ? '👁' : '🙈'` → `b.innerHTML = ICON(i.type==='password' ? 'olho' : 'olhoFechado')`

- [ ] **Step 4: Varredura** — `grep -nP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}]' index.html app.js auth.js` → zero resultado (a faixa `\x{2190}-\x{21FF}` das setas ↑↓↩ também deve sumir dos templates; `‹ Voltar` fica).

- [ ] **Step 5: Conferir no navegador** — servidor da Task 2, logar com conta de teste, abrir: lista de obras, detalhe, novo gasto (chips), relatório, simulador, ajustes. Nenhum emoji, ícones herdando cor certa (`ic-green` verde etc.).

- [ ] **Step 6:** Commit: `git add app.js auth.js && git commit -m "feat: emojis dinamicos viram ICON() em app.js e auth.js"`.

---

### Task 4: `calc.js` — formatação de moeda pura + `parseNum` endurecido

**Files:**
- Modify: `calc.js` (adicionar 4 funções no objeto `api`)
- Create: `tests/moeda.test.cjs`
- Modify: `app.js:59-64` (`parseNum` local passa a delegar)

**Interfaces:**
- Produces: `OBRA_CALC.fmtDigitado(str)->str` (formata enquanto digita), `OBRA_CALC.fmtCompleto(str)->str` (blur: completa centavos), `OBRA_CALC.numParaCampo(num)->str` (número salvo → campo formatado), `OBRA_CALC.parseNum(any)->number`. Task 5 consome as quatro.

- [ ] **Step 1: Teste que falha** — `tests/moeda.test.cjs`:

```js
'use strict';
const assert = require('assert');
const C = require('../calc.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

t('fmtDigitado: milhar ao vivo', () => {
  assert.strictEqual(C.fmtDigitado('2000000'), '2.000.000');
  assert.strictEqual(C.fmtDigitado('2'), '2');
  assert.strictEqual(C.fmtDigitado(''), '');
});
t('fmtDigitado: vírgula abre centavos (máx 2)', () => {
  assert.strictEqual(C.fmtDigitado('2500,5'), '2.500,5');
  assert.strictEqual(C.fmtDigitado('2500,567'), '2.500,56');
  assert.strictEqual(C.fmtDigitado(','), '0,');
});
t('fmtDigitado: lixo colado é limpo', () => {
  assert.strictEqual(C.fmtDigitado('R$ 1.2a3,4,5'), '123,45');
  assert.strictEqual(C.fmtDigitado('007'), '7');
});
t('fmtCompleto: completa ,00', () => {
  assert.strictEqual(C.fmtCompleto('2.000.000'), '2.000.000,00');
  assert.strictEqual(C.fmtCompleto('2500,5'), '2.500,50');
  assert.strictEqual(C.fmtCompleto(''), '');
});
t('numParaCampo', () => {
  assert.strictEqual(C.numParaCampo(2000000), '2.000.000,00');
  assert.strictEqual(C.numParaCampo(1234.5), '1.234,50');
  assert.strictEqual(C.numParaCampo(null), '');
});
t('parseNum: ida e volta com a máscara', () => {
  assert.strictEqual(C.parseNum('2.000.000,00'), 2000000);
  assert.strictEqual(C.parseNum('2.000.000'), 2000000); // sem blur (simulador ao vivo)
  assert.strictEqual(C.parseNum('2.500,50'), 2500.5);
});
t('parseNum: taxa com ponto decimal continua funcionando', () => {
  assert.strictEqual(C.parseNum('1.5'), 1.5);   // #ajTaxa digitado com ponto
  assert.strictEqual(C.parseNum('1,5'), 1.5);
  assert.strictEqual(C.parseNum(''), 0);
  assert.strictEqual(C.parseNum(7), 7);
});

console.log(`\n${n} testes passaram ✔`);
```

- [ ] **Step 2:** `node tests/moeda.test.cjs` → FALHA (`C.fmtDigitado is not a function`).

- [ ] **Step 3: Implementar em `calc.js`** (dentro do objeto `api`, sem `this`):

```js
function fmtDigitado(v){
  v = (v==null?'':String(v)).replace(/[^\d,]/g,'');
  const i = v.indexOf(',');
  let int = (i<0 ? v : v.slice(0,i)).replace(/^0+(?=\d)/,'');
  const cent = i<0 ? null : v.slice(i+1).replace(/,/g,'').slice(0,2);
  if(!int && cent===null) return '';
  int = (int||'0').replace(/\B(?=(\d{3})+(?!\d))/g,'.');
  return cent===null ? int : int+','+cent;
}
function fmtCompleto(v){
  v = fmtDigitado(v);
  if(!v) return '';
  const [int, cent=''] = v.split(',');
  return int+','+(cent+'00').slice(0,2);
}
function numParaCampo(n){
  return (n==null || n==='') ? '' : fmtCompleto(String(n).replace('.',','));
}
function parseNum(v){
  if(typeof v==='number') return v;
  v = (v||'').toString().trim().replace(/[^\d,.-]/g,'');
  if(v.includes(',')) v = v.replace(/\./g,'').replace(',','.');
  else v = v.replace(/\.(?=\d{3}(\.|$))/g,''); // pontos de milhar sem vírgula (campo ao vivo)
  const n = parseFloat(v); return isNaN(n) ? 0 : n;
}
```

E expor no `api`: `fmtDigitado, fmtCompleto, numParaCampo, parseNum`.

- [ ] **Step 4: `app.js` delega** — apagar o corpo de `parseNum` (linhas 59-64) e trocar por `const parseNum = OBRA_CALC.parseNum;`.

- [ ] **Step 5:** `node tests/moeda.test.cjs && node tests/calc.test.cjs && node tests/icons.test.cjs` → tudo verde.

- [ ] **Step 6:** Commit: `git add calc.js app.js tests/moeda.test.cjs && git commit -m "feat: formatacao de moeda pura em calc.js + parseNum endurecido"`.

---

### Task 5: `app.js` — aplicar máscara e prefixo R$ nos campos

**Files:**
- Modify: `app.js` (helper novo perto do parseNum; formVenda:352; formEditarObra:375-376; formGasto:426-427; formNovaObra:685; bloco simulador:629)

**Interfaces:**
- Consumes: `OBRA_CALC.fmtDigitado/fmtCompleto/numParaCampo` (Task 4); CSS `.money` (Task 2).

- [ ] **Step 1: Helper** — logo após `parseNum` em `app.js`:

```js
function maskMoney(sel){
  const inp = typeof sel==='string' ? $(sel) : sel;
  if(!inp) return;
  inp.addEventListener('input', ()=>{ inp.value = OBRA_CALC.fmtDigitado(inp.value); });
  inp.addEventListener('blur',  ()=>{ inp.value = OBRA_CALC.fmtCompleto(inp.value); });
}
```

- [ ] **Step 2: Modais** — em cada template, embrulhar o input e aplicar a máscara após o `openSheet`:
  - `formVenda` (352): `<div class="field big"><div class="money"><b>R$</b><input id="fVal" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>` e, depois do `openSheet`, `maskMoney('#fVal');`
  - `formGasto` (426-427): mesmo embrulho; o `value` de edição vira `value="${isEdit?OBRA_CALC.numParaCampo(gasto.valor):''}"`; `maskMoney('#fVal');` após `openSheet`.
  - `formEditarObra` (375-376): `<div class="money"><b>R$</b><input id="fEst" inputmode="decimal" placeholder="0,00" value="${o.valorEstimadoVenda?OBRA_CALC.numParaCampo(o.valorEstimadoVenda):''}" autocomplete="off"></div>` e `maskMoney('#fEst');`
  - `formNovaObra` (685): mesmo embrulho no `#fEst` + `maskMoney('#fEst');`
  - Placeholders mudam de `R$ 0,00` pra `0,00` (o `R$` agora é o `<b>` fixo).

- [ ] **Step 3: Simulador** — antes da linha `$('#simValor').addEventListener('input', ...)` (629), chamar `maskMoney('#simValor');` (a máscara reformata primeiro; o listener existente lê depois e `parseNum` endurecido entende `2.000.000` sem vírgula).

- [ ] **Step 4: Conferir no navegador** — novo gasto: digitar `2000000` → campo mostra `2.000.000`; clicar fora → `2.000.000,00`; salvar → lista mostra `R$ 2.000.000,00`; editar o gasto → campo abre `2.000.000,00`. Simulador calcula ao vivo enquanto digita. Taxa em Ajustes segue aceitando `1,5`.

- [ ] **Step 5:** `node tests/calc.test.cjs && node tests/moeda.test.cjs && node tests/icons.test.cjs` → verde. Commit: `git add app.js index.html && git commit -m "feat: mascara de moeda com prefixo R$ nos campos de valor"`.

---

### Task 6: Verificação e2e + entrega

**Files:**
- Create: script descartável `%TEMP%\smoke-obras\smoke-fase2.mjs` (puppeteer-core já instalado lá; Edge em `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`)

- [ ] **Step 1: Servir local** — `npx -y http-server -p 8123 .` (background).

- [ ] **Step 2: Script e2e** — cria conta `teste.e2e.fase2.<timestamp>@example.com` (senha `Teste123!`, CPF `529.982.247-25`), e em seguida:
  1. Cadastro pela tela → app destrava.
  2. Criar obra "Obra E2E" → abrir → novo gasto → digitar `2000000` no `#fVal` → `assert` valor do campo `=== '2.000.000'` → blur → `=== '2.000.000,00'` → salvar.
  3. `assert` texto da tela contém `R$ 2.000.000,00` (normalizar U+00A0 antes de comparar — pegadinha conhecida do `Intl`).
  4. Varrer emoji em cada view (`inicio`, detalhe, formulário de gasto aberto, relatório, `simula`, `ajustes`): `document.body.innerText` + `innerHTML` sem match pra `/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}]/u` (exceto `‹`, U+2039, permitido).
  5. Limpeza: apagar docs `dados/{uid}` e `perfis/{uid}` + conta via REST (padrão do smoke de 2026-07-06 — Auth REST `accounts:delete` com `idToken`).

- [ ] **Step 3:** Rodar → `TUDO PASSOU`. Se falhar, corrigir e repetir (superpowers:systematic-debugging se não for óbvio).

- [ ] **Step 4: Merge e deploy** — `git checkout main && git merge --no-ff design-icones-moeda -m "merge: icones minimalistas + mascara de moeda (branch design-icones-moeda)" && git push`. Vercel publica sozinho. Conferir produção: abrir `https://app-construcao-civil.vercel.app` e ver ícones na tela de login.

- [ ] **Step 5:** Avisar o Giovani: atualizar o celular (fechar/abrir 2×, cache novo `obras-v5`).
