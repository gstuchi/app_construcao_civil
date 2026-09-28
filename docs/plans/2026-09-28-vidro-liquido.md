# Custta no padrão Apple com Liquid Glass — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vestir a interface inteira do Custta (celular, desktop, login, sheets, diálogos) com o material Liquid Glass na camada de navegação e com molas no padrão da Apple, sem tocar em regra de negócio.

**Architecture:** CSS puro em `styles.css` com tokens de material (`--vidro*`) por combo tema×cor e tokens de mola (`--mola*`) gerados por `scripts/molas.mjs`; JS mínimo em `app.js` (botão +, lente das abas, saída e forma da sheet), `gestos.js` (física de projeção e elástico) e `globe.js` (pausa sob vidro). Testes: guardas de CSS em `node --test` e a suíte Playwright nova `tests/browser/vidro.cjs`.

**Tech Stack:** Vanilla JS (scripts clássicos com globais), CSS com custom properties, `node:test`, Playwright (Chromium), agent-browser para a conferência visual.

**Spec:** `docs/specs/2026-09-28-vidro-liquido-design.md` — leia antes de qualquer tarefa.

## Global Constraints

- Vanilla, sem dependência nova de runtime, sem etapa de build; `scripts/molas.mjs` é ferramenta de manutenção, não é servido.
- CSP estrita: nada de `<style>`, `style="..."` no HTML nem `onclick=`; em JS, só `el.style.setProperty(...)` (CSSOM), que a CSP permite.
- Todo CSS em `styles.css`. Cor só por custom property definida nos quatro blocos tema×cor (`:root`, `html[data-theme="light"]`, `html[data-skin="azul"]`, `html[data-skin="azul"][data-theme="light"]`); `rgba(0,0,0,x)` só para sombra e véu.
- Sem `color-mix()` (WKWebView do iOS 15). Todo `backdrop-filter` vem acompanhado de `-webkit-backdrop-filter` com o mesmo valor.
- **Raiz de fundo:** nenhum ancestral de um elemento de vidro pode ter `opacity` < 1, `filter`, `mask`/`mask-image`, `clip-path` ou `backdrop-filter`. Véu escurece por `background-color`; efeito de borda mora em `::before`.
- Vidro só nos seletores da lista fechada do spec (abas, +, itens da barra, esfumado da barra, lateral, sheet, diálogos, toasts, tela de valor, cartão do login, bolinha da chave de tema apertada). Conteúdo (`.panel`, `.card`, `.kpi`, `ul.list`, campos, chips, avisos) nunca.
- Breakpoints: celular `max-width:899px`, desktop `min-width:900px`. Campos com fonte ≥16px; alvos de toque ≥44px; corpo ≥16px.
- `prefers-reduced-motion` zera as durações das molas; `prefers-reduced-transparency` e `prefers-contrast: more` deixam o vidro sólido.
- Contraste ≥4,5:1 para texto normal nos quatro combos (mínimo 3:1 só para texto ≥24px ou negrito ≥18,66px).
- Português em identificadores, comentários e textos. Comentários explicam o porquê, no estilo do arquivo.
- Commits: autor único `Giovani Stuchi <stuchigiovani@gmail.com>`, **sem** `Co-Authored-By`; título `tipo: descrição` em português **com acentos**; um commit por mudança lógica; corpo em prosa curta quando não for trivial. Conferir com `git log -1 --format='%an <%ae>'`. Não dar push (o coordenador faz).
- Diretório de trabalho: `/Users/giovanistuchi/Documents/app_construcao_civil/.claude/worktrees/vidro-liquido` (branch `feat/vidro-liquido`). Nunca `cd` para a raiz do repositório principal. Nunca `git stash` puro.
- Testes: `npm run test:unit`; uma suíte de navegador: `node tests/browser/servidor.cjs &` (porta 8123) e depois `node tests/browser/<suite>.cjs`; mate o servidor ao fim (`pkill -f tests/browser/servidor.cjs`). Suíte inteira: `npm run test:browser` (sobe servidor e emuladores sozinho; não deixe outro servidor na 8123).

## Review Focus

1. **Vidro dentro de raiz de fundo** — se o `.backdrop` (ou qualquer ancestral) ganhar `opacity`/`filter`/`backdrop-filter`, a sheet mostra só o véu e não a página; esperado: a sheet desfoca a tela de trás. Teste na Tarefa 6 (`#backdrop` com `backdropFilter` `none` e `opacity` `1` com a sheet aberta).
2. **Fechar e abrir sheet no mesmo instante** (formulário que troca de sheet, valor → formulário) — se a classe `saindo` sobreviver, a nova sheet fica sem clique; esperado: a nova sheet aparece e responde. Teste na Tarefa 6.
3. **Teclado do iPhone aberto com sheet flutuante** — `--vvh` encolhe; esperado: a sheet continua inteira dentro da área visível (8px acima do teclado). Teste na Tarefa 6 simulando `--vvh:500px`.
4. **Movimento reduzido** — com durações `0s`, `transitionend` não dispara; esperado: fechar some na hora, sem `saindo` preso. Teste na Tarefa 6 com `reducedMotion:'reduce'`.
5. **Fim da página sob a cápsula flutuante** — o último item (último gasto, botão de ação) não pode ficar atrás das abas; esperado: rolando até o fim, o último elemento termina acima da cápsula. Teste na Tarefa 4.

## Mapa de arquivos

| Arquivo | Muda em | Responsabilidade |
| --- | --- | --- |
| `scripts/molas.mjs` (novo) | T1 | gera as curvas `linear()` das molas a partir de amortecimento e resposta |
| `tests/molas.test.mjs` (novo) | T1 | gerador correto e CSS igual à saída dele |
| `gestos.js`, `tests/gestos.test.cjs` | T2, T6 | projeção de impulso, elástico; fechar sheet pelo `closeSheet()` |
| `styles.css` | T1, T3–T10 | tokens e todos os componentes |
| `tests/vidro.test.cjs` (novo) | T3, T5, T8, T10, T11 | guardas de CSS do material |
| `tests/ios.test.cjs` | T3, T5 | guardas antigas que citavam `--barra` e `header.top.colapsada` |
| `index.html` | T4 | esfumado das abas, `data-aba`, rótulo do + |
| `app.js` | T4, T6 | botão + contextual, lente, saída e forma da sheet |
| `globe.js` | T7 | pausa sob sheet, diálogo e tela de valor |
| `tests/browser/vidro.cjs` (novo) | T3–T10 | ponta a ponta do vidro |
| `tests/browser/contraste.cjs` | T4, T5 | contraste da cápsula e da pílula sobre vidro |
| `tests/browser/ios.cjs`, `fase2.cjs` | T4, T5, T6 | suítes que dependiam do desenho antigo |
| `tests/browser/rodar.cjs` | T3, T4 | inclui `vidro.cjs` e `contraste.cjs` na CI |
| `sw.js`, `CLAUDE.md`, `package.json` | T1, T3, T11 | cache, documentação, registro de testes |

Ordem e paralelismo: **T1 ∥ T2** (arquivos disjuntos, podem rodar juntas). Depois T3 → T4 → T5 → T6 → T7 → T8 → T9 → T10 → T11 → T12 em sequência (todas mexem em `styles.css`).

---

### Task 1: Molas no padrão da Apple (gerador + tokens)

**Files:**
- Create: `scripts/molas.mjs`
- Create: `tests/molas.test.mjs`
- Modify: `styles.css` (bloco novo logo depois do bloco `html[data-skin="azul"][data-theme="light"]{...}`, antes de `*{box-sizing:border-box;...}`)
- Modify: `package.json` (`test:unit`: acrescentar `tests/molas.test.mjs`)

**Interfaces:**
- Produces: tokens CSS `--mola`, `--mola-dur`, `--mola-quique`, `--mola-quique-dur` em `:root` (padrão `cubic-bezier(.2,.8,.2,1)`/`.35s`/`.3s`; `linear()` e duração calculada dentro de `@supports`; `0s` com movimento reduzido). Módulo `scripts/molas.mjs` exporta `MOLAS`, `posicao(t, mola)`, `acomodacao(mola)`, `curva(mola, pontos=32) → {duracao, linear}`, `tokensCss() → string[]`.

- [ ] **Step 1: Escrever o teste que falha**

`tests/molas.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { MOLAS, curva, acomodacao, tokensCss } from '../scripts/molas.mjs';

const valores = linear => linear.slice('linear('.length, -1).split(',').map(Number);

test('curvas começam em 0 e terminam em 1', ()=>{
  for(const m of Object.values(MOLAS)){
    const v = valores(curva(m).linear);
    assert.equal(v[0], 0);
    assert.equal(v.at(-1), 1);
  }
});

test('mola padrão (amortecimento 1) nunca passa do destino; a de quique passa', ()=>{
  assert.ok(valores(curva(MOLAS.mola).linear).every(x => x <= 1));
  assert.ok(valores(curva(MOLAS['mola-quique']).linear).some(x => x > 1.005));
});

test('acomodação coerente com a resposta', ()=>{
  const d = acomodacao(MOLAS.mola), q = acomodacao(MOLAS['mola-quique']);
  assert.ok(d > 0.45 && d < 0.6, `mola: ${d}s`);
  assert.ok(q > 0.35 && q < 0.5, `quique: ${q}s`);
});

test('styles.css traz exatamente os tokens do gerador dentro do @supports de linear()', ()=>{
  const css = readFileSync(new URL('../styles.css', import.meta.url), 'utf8');
  const i = css.indexOf('@supports (transition-timing-function:linear(0, 1))');
  assert.ok(i >= 0, 'bloco @supports das molas sumiu');
  const bloco = css.slice(i, css.indexOf('}', css.indexOf('{', css.indexOf('{', i) + 1)));
  for(const linha of tokensCss()) assert.ok(bloco.includes(linha), `falta no CSS: ${linha.slice(0, 60)}…`);
});

test('movimento reduzido zera a duração das molas', ()=>{
  const css = readFileSync(new URL('../styles.css', import.meta.url), 'utf8');
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)\{\s*:root\{--mola-dur:0s;--mola-quique-dur:0s\}\s*\}/);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/molas.test.mjs`
Expected: FAIL — `Cannot find module '../scripts/molas.mjs'`.

- [ ] **Step 3: Escrever o gerador**

`scripts/molas.mjs`:

```js
/* Molas no padrão da Apple (amortecimento + resposta, WWDC "Designing Fluid Interfaces")
   viradas curvas CSS linear(). É a fonte dos tokens --mola* do styles.css: rode
   `node scripts/molas.mjs` e cole a saída no bloco @supports das molas;
   tests/molas.test.mjs falha se o CSS divergir do que sai daqui. */
export const MOLAS = {
  'mola':        { amortecimento: 1,   resposta: 0.35 }, // padrão: sem quique
  'mola-quique': { amortecimento: 0.8, resposta: 0.3 },  // só depois de gesto com impulso
};

/* posição de 0 a 1 no instante t (s), partindo do repouso */
export function posicao(t, { amortecimento: z, resposta }){
  const w0 = 2 * Math.PI / resposta;
  if(z >= 1) return 1 - (1 + w0 * t) * Math.exp(-w0 * t);
  const wd = w0 * Math.sqrt(1 - z * z);
  return 1 - Math.exp(-z * w0 * t) * (Math.cos(wd * t) + (z * w0 / wd) * Math.sin(wd * t));
}

/* primeiro instante (arredondado para cima em centésimos) a partir do qual a mola
   fica a menos de 0,1% do destino para sempre — vira a duração da transição */
export function acomodacao(m, tolerancia = 0.001){
  let ultimoFora = 0;
  for(let i = 0; i <= 5000; i++){
    const t = i / 1000;
    if(Math.abs(1 - posicao(t, m)) >= tolerancia) ultimoFora = t;
  }
  return Math.ceil((ultimoFora + 0.001) * 100) / 100;
}

export function curva(m, pontos = 32){
  const duracao = acomodacao(m);
  const vals = [];
  for(let i = 0; i <= pontos; i++) vals.push(i === pontos ? 1 : Number(posicao(duracao * i / pontos, m).toFixed(4)));
  return { duracao, linear: `linear(${vals.join(', ')})` };
}

export function tokensCss(){
  return Object.entries(MOLAS).map(([nome, m]) => {
    const { duracao, linear } = curva(m);
    return `--${nome}:${linear}; --${nome}-dur:${duracao}s;`;
  });
}

if(import.meta.url === `file://${process.argv[1]}`) console.log(tokensCss().join('\n'));
```

- [ ] **Step 4: Colar os tokens no CSS**

Run: `node scripts/molas.mjs` (saída esperada: duas linhas, `--mola:linear(0, 0.0351, …, 1); --mola-dur:0.52s;` e `--mola-quique:linear(0, 0.0312, …, 1); --mola-quique-dur:0.41s;`).

Em `styles.css`, logo depois do fechamento do bloco `html[data-skin="azul"][data-theme="light"]{...}` e antes de `  *{box-sizing:border-box;margin:0;padding:0}`, inserir (substituindo `<LINHA 1>`/`<LINHA 2>` pelas duas linhas exatas da saída, cada uma numa linha própria com 4 espaços de recuo):

```css
  /* Molas no padrão da Apple (scripts/molas.mjs): amortecimento 1 é o padrão, sem quique;
     a de quique (0,8) só entra depois de gesto com impulso. Recuo via @supports porque
     declaração de recuo não funciona através de var(): sem linear(), fica a curva suave. */
  :root{--mola:cubic-bezier(.2,.8,.2,1);--mola-dur:.35s;--mola-quique:cubic-bezier(.2,.8,.2,1);--mola-quique-dur:.3s}
  @supports (transition-timing-function:linear(0, 1)){
    :root{
    <LINHA 1>
    <LINHA 2>
    }
  }
  @media (prefers-reduced-motion: reduce){ :root{--mola-dur:0s;--mola-quique-dur:0s} }
```

Atenção ao regex do último teste: `@media (prefers-reduced-motion: reduce){` seguido de espaço opcional, `:root{--mola-dur:0s;--mola-quique-dur:0s}`, espaço opcional e `}`.

- [ ] **Step 5: Registrar o teste e rodar**

Em `package.json`, no script `test:unit`, acrescentar ` tests/molas.test.mjs` logo depois de `tests/gestos.test.cjs`.

Run: `node --test tests/molas.test.mjs && npm run test:unit`
Expected: PASS em tudo.

- [ ] **Step 6: Commit**

```bash
git add scripts/molas.mjs tests/molas.test.mjs styles.css package.json
git commit -m "feat: molas no padrão da Apple como tokens de CSS" -m "As curvas saem de scripts/molas.mjs a partir dos dois parâmetros que a Apple usa (amortecimento e resposta) e viram linear() dentro de um @supports, com curva suave de recuo para WebKit antigo. Com movimento reduzido as durações zeram. Nenhuma tela usa os tokens ainda."
```

---

### Task 2: Física dos gestos — projeção de impulso e elástico

**Files:**
- Modify: `gestos.js` (funções puras do topo; `moverLinha`; `movimento` no trecho da puxada; `api`)
- Test: `tests/gestos.test.cjs`

**Interfaces:**
- Produces (em `OBRA_GESTOS` e `module.exports`): `projeta(v, taxa = TAXA_DESACELERACAO) → px` (v em px/ms), `elastico(excesso, dimensao, c = 0.55) → px` (preserva sinal), `TAXA_DESACELERACAO = 0.995`. `fimArrastoLinha(dx, vx)`, `fimArrastoSheet(dy, vy)` e `fimArrastoBorda(dx, vx, largura)` mantêm assinatura e retornos (`'abrir'|'fechar'`, `'fechar'|'voltar'`, `'voltar'|'cancelar'`).

- [ ] **Step 1: Escrever os testes que falham**

Acrescentar ao fim de `tests/gestos.test.cjs`:

```js
test('projeta: impulso vira distância (Apple, desaceleração 0,995 por ms)', ()=>{
  assert.equal(G.projeta(0), 0);
  assert.ok(Math.abs(G.projeta(1) - 199) < 0.5);    // 1px/ms ≈ 199px adiante
  assert.ok(Math.abs(G.projeta(-1) + 199) < 0.5);   // sinal preservado
  assert.ok(Math.abs(G.projeta(1, 0.99) - 99) < 0.5);
});

test('elástico: resiste cada vez mais e nunca passa da dimensão', ()=>{
  assert.equal(G.elastico(0, 100), 0);
  const a = G.elastico(50, 100), b = G.elastico(100, 100), c = G.elastico(1000, 100);
  assert.ok(a > 0 && a < 50);
  assert.ok(b > a && c > b && c < 100);
  assert.equal(G.elastico(-50, 100), -a);
});

test('sheet: o destino projetado decide, não só onde soltou', ()=>{
  assert.equal(G.fimArrastoSheet(200, -1.5), 'voltar'); // desceu muito mas jogou para cima
  assert.equal(G.fimArrastoSheet(40, 0.5), 'fechar');   // curto e rápido para baixo
  assert.equal(G.fimArrastoSheet(100, 0), 'voltar');
});

test('linha: arrasto longo devolvido para a direita fecha', ()=>{
  assert.equal(G.fimArrastoLinha(-100, 1), 'fechar');
  assert.equal(G.fimArrastoLinha(-10, -0.3), 'abrir');
});

test('borda: peteleco curto não volta, lento e longo sim', ()=>{
  assert.equal(G.fimArrastoBorda(30, 2, 390), 'cancelar'); // menos de 40px: toque acidental
  assert.equal(G.fimArrastoBorda(140, 0, 390), 'voltar');
  assert.equal(G.fimArrastoBorda(200, -1, 390), 'cancelar'); // arrastou e devolveu
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/gestos.test.cjs`
Expected: FAIL — `G.projeta is not a function`.

- [ ] **Step 3: Implementar as funções puras**

Em `gestos.js`, logo depois de `const ARRASTO_MAXIMO = 120; ...`, inserir:

```js
  /* Projeção de impulso da Apple ("Designing Fluid Interfaces"): onde o dedo iria parar se o
     movimento continuasse desacelerando. v em px/ms; a taxa é por ms. 0,995 fica entre o 0,998
     da rolagem e o 0,99 "rápido" da Apple: um peteleco de 1px/ms projeta ~200px. */
  const TAXA_DESACELERACAO = 0.995;
  function projeta(v, taxa = TAXA_DESACELERACAO){
    return v * taxa / (1 - taxa);
  }
  /* Elástico nos limites: quanto mais passa, menos acompanha — nunca além da dimensão. */
  function elastico(excesso, dimensao, c = 0.55){
    const r = (Math.abs(excesso) * dimensao * c) / (dimensao + c * Math.abs(excesso));
    return excesso < 0 ? -r : r;
  }
```

Substituir as três funções de decisão por:

```js
  /* dx: posição final da linha (negativa = aberta para a esquerda); vx em px/ms.
     Decide pelo ponto projetado: arrasto curto e rápido abre, longo e devolvido fecha. */
  function fimArrastoLinha(dx, vx){
    return -(dx + projeta(vx)) > LARGURA_APAGAR / 2 ? 'abrir' : 'fechar';
  }
  /* 30px de piso: tremida curta não fecha mesmo com velocidade. */
  function fimArrastoSheet(dy, vy){
    return dy > 30 && dy + projeta(vy) > 120 ? 'fechar' : 'voltar';
  }
  /* 40px de piso: peteleco acidental na borda não volta de tela. */
  function fimArrastoBorda(dx, vx, largura){
    return dx > 40 && dx + projeta(vx) > largura * 0.35 ? 'voltar' : 'cancelar';
  }
```

Conferência dos testes antigos com a regra nova (não altere os antigos): linha `(-50,0)` abre, `(-30,0)` fecha, `(-15,-0.8)` → −15−159 abre, `(-70,0.8)` → −70+159 fecha; sheet `(130,0)` fecha, `(60,1.2)` fecha, `(60,0.2)` → 99,8 volta, `(20,2)` volta pelo piso; borda `(150,0)` volta, `(100,0)` cancela, `(60,0.7)` → 199 > 136,5 volta.

Na linha `const api = { ... }`, acrescentar `projeta, elastico, TAXA_DESACELERACAO`.

- [ ] **Step 4: Usar o elástico no arrasto**

Em `moverLinha(dx)`, trocar a linha

```js
        const pos = Math.min(0, Math.max(-ARRASTO_MAXIMO, dx + (l.aberta ? -LARGURA_APAGAR : 0)));
```

por

```js
        /* além dos limites (fechada para a direita, aberta além do máximo) a linha resiste
           em vez de parar seco */
        const bruto = dx + (l.aberta ? -LARGURA_APAGAR : 0);
        const pos = bruto > 0 ? elastico(bruto, 60)
          : bruto < -ARRASTO_MAXIMO ? -ARRASTO_MAXIMO + elastico(bruto + ARRASTO_MAXIMO, 60)
          : bruto;
```

Em `movimento(e)`, no bloco `if(puxada){ ... }`, trocar

```js
          sheet.style.setProperty('--dy', Math.max(0, dy) + 'px');
```

por

```js
          // voltando acima do ponto de partida, a sheet resiste (elástico) em vez de travar
          sheet.style.setProperty('--dy', (dy >= 0 ? dy : elastico(dy, sheet.offsetHeight)) + 'px');
```

- [ ] **Step 5: Rodar**

Run: `node --test tests/gestos.test.cjs && npm run test:unit`
Expected: PASS.

Depois, com `node tests/browser/servidor.cjs &` no ar: `node tests/browser/ios.cjs` → Expected: PASS (gestos de arrastar para apagar, puxar sheet e voltar pela borda seguem funcionando). Mate o servidor.

- [ ] **Step 6: Commit**

```bash
git add gestos.js tests/gestos.test.cjs
git commit -m "feat: gestos decidem pelo impulso projetado e resistem nos limites" -m "Soltar a sheet, a linha de apagar e o voltar pela borda passa a decidir pelo ponto onde o movimento pararia (projeção de impulso da Apple), não pela posição em que o dedo saiu. Um arrasto longo devolvido para trás desiste; um peteleco curto na direção certa completa. Além dos limites, a linha e a sheet resistem com elástico em vez de parar seco."
```

---

### Task 3: Material de vidro — tokens, recuos e guardas

**Files:**
- Modify: `styles.css` (os quatro blocos de tema; `nav.tabs` e `header.top.colapsada` do bloco "barras no padrão iOS"; `:root` das molas; bloco novo de recuos ao fim do arquivo)
- Create: `tests/vidro.test.cjs`
- Modify: `tests/ios.test.cjs` (teste "barras translúcidas com material por tema")
- Create: `tests/browser/vidro.cjs`
- Modify: `tests/browser/rodar.cjs`, `package.json`

**Interfaces:**
- Consumes: nada.
- Produces: tokens por combo `--vidro`, `--vidro-folha`, `--vidro-tinta`, `--vidro-tinta-ink`, `--vidro-brilho`, `--vidro-sombra`; tokens globais `--vidro-filtro` (`saturate(180%) blur(24px)`) e `--vidro-filtro-forte` (`saturate(180%) blur(40px)`). `--barra` deixa de existir. Suíte `tests/browser/vidro.cjs` com os helpers `abrir(browser, opcoes)`, `caixa(page, sel)`, `estilo(page, sel, prop)`, `teste(nome, fn)` — as tarefas seguintes acrescentam testes nela.

- [ ] **Step 1: Escrever as guardas que falham**

`tests/vidro.test.cjs`:

```js
'use strict';
/* Guardas do Liquid Glass (docs/specs/2026-09-28-vidro-liquido-design.md). */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const css = readFileSync(join(__dirname, '..', 'styles.css'), 'utf8');
const semComentario = css.replace(/\/\*[\s\S]*?\*\//g, '');
const regras = [...semComentario.matchAll(/([^{}]+)\{([^{}]*)\}/g)].map(m => ({ sel: m[1].trim(), decl: m[2] }));
const BLOCOS = ['  :root{', '  html[data-theme="light"]{', '  html[data-skin="azul"]{', '  html[data-skin="azul"][data-theme="light"]{'];
const corpoDoBloco = b => { const i = css.indexOf(b); assert.ok(i >= 0, `bloco ${b} sumiu`); return css.slice(i, css.indexOf('}', i)); };

test('material de vidro definido nos quatro combos tema×cor', ()=>{
  for(const b of BLOCOS){
    const corpo = corpoDoBloco(b);
    for(const t of ['--vidro', '--vidro-folha', '--vidro-tinta', '--vidro-tinta-ink', '--vidro-brilho', '--vidro-sombra'])
      assert.match(corpo, new RegExp(`${t}:`), `${b} sem ${t}`);
  }
  assert.doesNotMatch(css, /--barra\b/, '--barra foi substituído por --vidro');
});

test('filtros do vidro são tokens globais', ()=>{
  assert.match(semComentario, /--vidro-filtro:saturate\(180%\) blur\(24px\)/);
  assert.match(semComentario, /--vidro-filtro-forte:saturate\(180%\) blur\(40px\)/);
});

test('recuos: sem backdrop-filter, transparência reduzida e contraste alto deixam o vidro sólido', ()=>{
  for(const cab of ['@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px)))',
                    '@media (prefers-reduced-transparency: reduce)', '@media (prefers-contrast: more)']){
    const i = semComentario.indexOf(cab);
    assert.ok(i >= 0, `falta ${cab}`);
    const trecho = semComentario.slice(i, i + 700);
    assert.match(trecho, /--vidro:var\(--surface-solid\)/, `${cab} não deixa --vidro sólido`);
    assert.match(trecho, /--vidro-folha:var\(--surface-solid\)/, `${cab} não deixa --vidro-folha sólido`);
  }
  assert.match(semComentario.slice(semComentario.indexOf('@media (prefers-reduced-transparency: reduce)')), /--vidro-filtro:none/);
});

test('todo backdrop-filter vem com -webkit-backdrop-filter (Safari)', ()=>{
  const sem = regras.filter(r => /(^|;|\s)backdrop-filter:/.test(r.decl) && !/-webkit-backdrop-filter:/.test(r.decl)).map(r => r.sel);
  assert.deepEqual(sem, []);
});

test('sem color-mix (WKWebView do iOS 15)', ()=>{
  assert.doesNotMatch(semComentario, /color-mix\(/);
});
```

No `package.json`, acrescentar ` tests/vidro.test.cjs` depois de ` tests/molas.test.mjs` em `test:unit`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/vidro.test.cjs`
Expected: FAIL — `:root{ sem --vidro`.

- [ ] **Step 3: Tokens nos quatro blocos**

Em cada bloco, **substituir** a linha do `--barra` (e o comentário `/* material das barras do celular ... */` do `:root`) pelas linhas abaixo. Os valores de `--vidro` são o ponto de partida; a Tarefa 4 pode subir o alfa para passar no contraste.

`:root` (escuro esmeralda):

```css
    /* Liquid Glass: material da camada de navegação (abas, +, itens da barra, sheets, diálogos).
       --vidro é o comum; --vidro-folha, mais denso, leva formulário por cima; --vidro-tinta é o
       vidro da marca (botão +). --vidro-brilho desenha a luz na borda; a sombra afasta do conteúdo. */
    --vidro:rgba(8,26,20,.62); --vidro-folha:rgba(10,30,24,.86);
    --vidro-tinta:rgba(20,179,154,.82); --vidro-tinta-ink:#04100C;
    --vidro-brilho:inset 0 1px 0 rgba(255,255,255,.14),inset 0 0 0 .5px rgba(255,255,255,.10);
    --vidro-sombra:0 10px 30px rgba(0,0,0,.35);
```

`html[data-theme="light"]`:

```css
    --vidro:rgba(246,250,248,.78); --vidro-folha:rgba(250,253,251,.90);
    --vidro-tinta:rgba(11,122,104,.88); --vidro-tinta-ink:#fff;
    --vidro-brilho:inset 0 1px 0 rgba(255,255,255,.95),inset 0 0 0 .5px rgba(20,43,35,.10);
    --vidro-sombra:0 8px 26px rgba(20,43,35,.16);
```

`html[data-skin="azul"]`:

```css
    --vidro:rgba(10,16,32,.62); --vidro-folha:rgba(14,22,40,.86);
    --vidro-tinta:rgba(59,108,240,.85); --vidro-tinta-ink:#fff;
    --vidro-brilho:inset 0 1px 0 rgba(255,255,255,.14),inset 0 0 0 .5px rgba(255,255,255,.10);
    --vidro-sombra:0 10px 30px rgba(0,0,0,.4);
```

`html[data-skin="azul"][data-theme="light"]`:

```css
    --vidro:rgba(247,249,253,.80); --vidro-folha:rgba(251,252,255,.90);
    --vidro-tinta:rgba(53,96,207,.88); --vidro-tinta-ink:#fff;
    --vidro-brilho:inset 0 1px 0 rgba(255,255,255,.95),inset 0 0 0 .5px rgba(23,43,77,.10);
    --vidro-sombra:0 8px 26px rgba(23,43,77,.16);
```

No `:root` das molas (Tarefa 1, a linha `:root{--mola:cubic-bezier...}`), acrescentar ao fim, antes do `}`: `;--vidro-filtro:saturate(180%) blur(24px);--vidro-filtro-forte:saturate(180%) blur(40px)`.

- [ ] **Step 4: Trocar os dois usos do `--barra`**

No bloco `@media screen and (max-width:899px)` das "barras no padrão iOS":

- em `header.top.colapsada{...}`: `background:var(--barra);-webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px)` → `background:var(--vidro);-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro)`;
- em `nav.tabs{background:var(--barra);...}`: a mesma troca.

Atualizar o comentário do bloco `/* bottom nav */` que cita `--barra` para citar `--vidro`.

- [ ] **Step 5: Recuos do material**

Ao fim de `styles.css`, acrescentar:

```css
/* ===== Liquid Glass: recuos =====
   Sem backdrop-filter (WebKit muito antigo), com transparência reduzida (Ajustes › Acessibilidade)
   ou com contraste aumentado, o vidro vira superfície sólida. Os quatro seletores repetem os
   dos blocos de tema para empatar a especificidade — vale o que vem por último. */
@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){
  :root,html[data-theme="light"],html[data-skin="azul"],html[data-skin="azul"][data-theme="light"]{--vidro:var(--surface-solid);--vidro-folha:var(--surface-solid)}
}
@media (prefers-reduced-transparency: reduce){
  :root,html[data-theme="light"],html[data-skin="azul"],html[data-skin="azul"][data-theme="light"]{--vidro:var(--surface-solid);--vidro-folha:var(--surface-solid);--vidro-filtro:none;--vidro-filtro-forte:none}
}
@media (prefers-contrast: more){
  :root,html[data-theme="light"],html[data-skin="azul"],html[data-skin="azul"][data-theme="light"]{--vidro:var(--surface-solid);--vidro-folha:var(--surface-solid);--vidro-brilho:inset 0 0 0 1px var(--line-strong)}
}
```

- [ ] **Step 6: Atualizar a guarda antiga**

Em `tests/ios.test.cjs`, no teste `'barras translúcidas com material por tema'`, trocar `/--barra:\s*rgba\(/` por `/--vidro:\s*rgba\(/` e a mensagem `sem --barra` por `sem --vidro`.

- [ ] **Step 7: Rodar as guardas**

Run: `node --test tests/vidro.test.cjs tests/ios.test.cjs && npm run test:unit`
Expected: PASS.

- [ ] **Step 8: Criar a suíte de navegador `tests/browser/vidro.cjs`**

```js
/* Liquid Glass ponta a ponta: cápsula de abas, botão +, barra de navegação, sheets, diálogos,
   lateral do desktop e login. Dados sintéticos (CLOUD falso), sem rede.
   Rode com node tests/browser/servidor.cjs no ar. */
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

const OBRAS = { config:{ taxaMensal:1, topicosCustom:[] }, obras:[
  { id:'o1', nome:'Casa Azul', fase:'construcao', dataInicio:'2026-01-01', areaM2:80, valorEstimadoVenda:500000,
    gastos:Array.from({ length:14 }, (_, i) => ({ id:'g' + i, valor:1000 + i, topico:'estrutura', descricao:'Item ' + i, data:'2026-02-10', pagamento:'pix' })) },
] };

let falhas = 0;
async function teste(nome, fn){
  try{ await fn(); console.log('ok - ' + nome); }
  catch(e){ falhas++; console.log('FALHA - ' + nome + '\n  ' + e.message); }
}

async function abrir(browser, { viewport = { width:390, height:844 }, movimento = 'no-preference', logado = true, tema = 'escuro' } = {}){
  const movel = viewport.width < 900;
  const ctx = await browser.newContext({ viewport, isMobile:movel, hasTouch:movel, deviceScaleFactor:2, reducedMotion:movimento });
  await ctx.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
  await ctx.route('https://**/*', r => r.abort());
  await ctx.addInitScript(([obras, logado, tema]) => {
    sessionStorage.setItem('splashVista', '1');
    localStorage.setItem('mo_tema', tema);
    window.errosPagina = [];
    addEventListener('error', e => errosPagina.push(e.message));
    addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
    const user = logado ? { uid:'teste', email:'t@t.com', emailVerificado:true } : null;
    window.CLOUD = { user:()=>user, onAuth:cb=>cb(user),
      watchDados:cb=>{ setTimeout(()=>cb(JSON.parse(JSON.stringify(obras)), { fromCache:false, pendingWrites:false, localDirty:false })); return ()=>{}; },
      saveDados:()=>Promise.resolve(), estado:()=>'ocioso', ready:Promise.resolve(), tentarDeNovo:()=>Promise.resolve(),
      savePushSub:()=>Promise.resolve(), removePushSub:()=>Promise.resolve() };
  }, [OBRAS, logado, tema]);
  const page = await ctx.newPage();
  await page.goto('http://localhost:8123');
  if(logado) await page.waitForFunction(() => typeof db !== 'undefined' && db.obras.length === 1);
  else await page.waitForSelector('#auth:not(.hidden)');
  return { ctx, page };
}
const caixa = (page, sel) => page.evaluate(s => {
  const r = document.querySelector(s).getBoundingClientRect();
  return { top:r.top, bottom:r.bottom, left:r.left, right:r.right, width:r.width, height:r.height };
}, sel);
const estilo = (page, sel, prop, pseudo = null) => page.evaluate(([s, p, ps]) => getComputedStyle(document.querySelector(s), ps)[p], [sel, prop, pseudo]);
const perto = (a, b, tol = 1.5) => Math.abs(a - b) <= tol;

(async () => {
  const browser = await chromium.launch();
  try{
    /* ---- recuos do material ---- */
    await teste('transparência reduzida deixa a barra de abas sólida e sem desfoque', async ()=>{
      const { ctx, page } = await abrir(browser);
      const cdp = await ctx.newCDPSession(page);
      await cdp.send('Emulation.setEmulatedMedia', { features:[{ name:'prefers-reduced-transparency', value:'reduce' }] });
      assert.equal(await estilo(page, 'nav.tabs', 'backdropFilter'), 'none');
      assert.match(await estilo(page, 'nav.tabs', 'backgroundColor'), /^rgb\(/, 'fundo deveria ser opaco');
      await ctx.close();
    });
    await teste('contraste alto deixa a barra de abas sólida', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.emulateMedia({ contrast:'more' });
      assert.match(await estilo(page, 'nav.tabs', 'backgroundColor'), /^rgb\(/);
      await ctx.close();
    });

    /* (as tarefas seguintes acrescentam blocos aqui, antes do fechamento do try) */
  }finally{
    await browser.close();
  }
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nVidro ok');
  process.exit(falhas ? 1 : 0);
})();
```

Em `tests/browser/rodar.cjs`, depois de `await run('tests/browser/ios.cjs');`, acrescentar `await run('tests/browser/vidro.cjs');`.

- [ ] **Step 9: Rodar a suíte**

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/vidro.cjs; node tests/browser/contraste.cjs /tmp; pkill -f tests/browser/servidor.cjs`
Expected: `vidro.cjs` com 2 `ok`; `contraste.cjs` termina com "Todos os combos legíveis".

- [ ] **Step 10: Commit**

```bash
git add styles.css tests/vidro.test.cjs tests/ios.test.cjs tests/browser/vidro.cjs tests/browser/rodar.cjs package.json
git commit -m "feat: material Liquid Glass por tema com recuo sólido" -m "Cada combinação de tema e cor passa a definir o vidro inteiro (preenchimento comum, de folha e da marca, brilho da borda e sombra) no lugar do --barra. Sem backdrop-filter, com transparência reduzida ou com contraste aumentado, o vidro vira superfície sólida. Guardas novas impedem color-mix e backdrop-filter sem o prefixo do Safari."
```

---

### Task 4: Cápsula de abas flutuante e botão + de vidro

**Files:**
- Modify: `index.html` (antes de `<nav class="tabs">`; o próprio `<nav>`; `#fab`)
- Modify: `app.js` (`showView`; handler `$('#fab').onclick`; texto da lista vazia em `renderObras`/linha ~265)
- Modify: `styles.css` (`.fab` base; `body.locked ...`; bloco das barras iOS no celular — regras de `nav.tabs`, `body`, `.fab`, `.toast-wrap`; bloco do desktop)
- Modify: `tests/browser/vidro.cjs`, `tests/browser/contraste.cjs`, `tests/browser/rodar.cjs`, `tests/browser/ios.cjs`, `tests/browser/fase2.cjs`

**Interfaces:**
- Consumes: `--vidro`, `--vidro-tinta`, `--vidro-tinta-ink`, `--vidro-brilho`, `--vidro-sombra`, `--vidro-filtro`, `--mola`, `--mola-dur` (T1, T3).
- Produces: `nav.tabs[data-aba]` (`"0"` Obras e pilha da obra, `"1"` Vale a pena?, `"2"` Ajustes); `#fab[data-acao]` (`"obra"` em Obras, `"gasto"` na obra, `""` no resto) com `aria-label` "Nova obra"/"Lançar gasto"; `.esfumado-abas`; variáveis de layout do celular `--abas-h:62px`, `--abas-base`, `--abas-margem:12px`, `--fab-vao:10px`.

- [ ] **Step 1: Escrever os testes que falham (em `tests/browser/vidro.cjs`)**

Acrescentar dentro do `try`, depois do bloco de recuos:

```js
    /* ---- cápsula de abas e botão + (celular) ---- */
    await teste('cápsula de abas flutua descolada das bordas, em vidro', async ()=>{
      const { ctx, page } = await abrir(browser);
      const n = await caixa(page, 'nav.tabs');
      assert.ok(perto(n.left, 12), `esquerda ${n.left}`);
      assert.ok(perto(n.bottom, 844 - 12), `base ${n.bottom}`);
      assert.ok(perto(n.height, 62), `altura ${n.height}`);
      assert.ok(parseFloat(await estilo(page, 'nav.tabs', 'borderTopLeftRadius')) >= 30);
      assert.match(await estilo(page, 'nav.tabs', 'backdropFilter'), /blur\(24px\)/);
      await ctx.close();
    });
    await teste('+ em Obras é "Nova obra", fica à direita da cápsula e abre o formulário', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.waitForTimeout(700);
      assert.equal(await page.getAttribute('#fab', 'aria-label'), 'Nova obra');
      const f = await caixa(page, '#fab'), n = await caixa(page, 'nav.tabs');
      assert.ok(perto(f.right, 390 - 12) && perto(f.bottom, n.bottom), `+ em ${JSON.stringify(f)}`);
      assert.ok(perto(n.right, 390 - 12 - 62 - 10), `cápsula termina em ${n.right}`);
      await page.locator('#fab').click();
      await page.waitForFunction(() => /Nova obra/.test(document.querySelector('#sheet h3')?.textContent || ''));
      await ctx.close();
    });
    await teste('+ na obra é "Lançar gasto" e abre o teclado de valor', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      assert.equal(await page.getAttribute('#fab', 'aria-label'), 'Lançar gasto');
      await page.locator('#fab').click();
      await page.waitForFunction(() => document.body.classList.contains('teclado-open'));
      await ctx.close();
    });
    await teste('em Vale a pena? e Ajustes o + some e a cápsula ocupa a largura', async ()=>{
      const { ctx, page } = await abrir(browser);
      for(const v of ['simula', 'ajustes']){
        await page.evaluate(x => showView(x), v);
        await page.waitForTimeout(700);
        assert.equal(await page.isVisible('#fab'), false, `+ visível em ${v}`);
        assert.ok(perto((await caixa(page, 'nav.tabs')).right, 390 - 12), `cápsula estreita em ${v}`);
      }
      await ctx.close();
    });
    await teste('lente da aba desliza para a aba da tela', async ()=>{
      const { ctx, page } = await abrir(browser);
      for(const [v, i] of [['ajustes', 2], ['simula', 1], ['inicio', 0]]){
        await page.evaluate(x => showView(x), v);
        await page.waitForTimeout(700);
        assert.equal(await page.getAttribute('nav.tabs', 'data-aba'), String(i));
        const { tx, w } = await page.evaluate(() => {
          const cs = getComputedStyle(document.querySelector('nav.tabs'), '::before');
          const m = cs.transform === 'none' ? [1,0,0,1,0,0] : cs.transform.match(/-?[\d.]+/g).map(Number);
          return { tx:m[4], w:parseFloat(cs.width) };
        });
        assert.ok(perto(tx, i * w), `lente em ${tx}, esperado ${i * w}`);
      }
      await page.evaluate(() => openObra('o1'));
      assert.equal(await page.getAttribute('nav.tabs', 'data-aba'), '0', 'dentro da obra a aba Obras segue selecionada');
      await ctx.close();
    });
    await teste('fim da obra rola até acima da cápsula (nada preso atrás das abas)', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      await page.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight));
      await page.waitForTimeout(300);
      const { fim, topoAbas } = await page.evaluate(() => {
        const vis = [...document.querySelectorAll('section.view.active *')].filter(e => e.getClientRects().length && e.children.length === 0);
        return { fim:Math.max(...vis.map(e => e.getBoundingClientRect().bottom)), topoAbas:document.querySelector('nav.tabs').getBoundingClientRect().top };
      });
      assert.ok(fim <= topoAbas, `último conteúdo termina em ${fim}, cápsula começa em ${topoAbas}`);
      await ctx.close();
    });
    await teste('conteúdo nunca é vidro', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      const vidrados = await page.evaluate(() => [...document.querySelectorAll('.panel,.card,.kpi,ul.list,ul.list li')]
        .filter(e => getComputedStyle(e).backdropFilter !== 'none').map(e => e.className));
      assert.deepEqual(vidrados, []);
      await ctx.close();
    });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/vidro.cjs; pkill -f tests/browser/servidor.cjs`
Expected: FALHA em "cápsula de abas flutua…", "+ em Obras…", "lente…" (e possivelmente "fim da obra…").

- [ ] **Step 3: Markup**

Em `index.html`, trocar

```html
<button class="fab hidden" id="fab" aria-label="Adicionar">+</button>

<nav class="tabs">
```

por

```html
<button class="fab hidden" id="fab" aria-label="Nova obra">+</button>

<!-- conteúdo some num esfumado sob a cápsula de abas, em vez de cortar sob o vidro -->
<div class="esfumado-abas" aria-hidden="true"></div>
<nav class="tabs" data-aba="0">
```

- [ ] **Step 4: `showView` e o botão +**

Em `app.js`, em `showView(v)`, trocar as duas linhas

```js
  $('#fab').classList.toggle('hidden', v!=='obra'); // lançar gasto só dentro da obra
  document.body.classList.toggle('com-fab', v==='obra'); // respiro extra: FAB não cobre o fim da página
```

por

```js
  /* botão +: ao lado da cápsula de abas no celular, cria obra (Obras) ou lança gasto (obra);
     no desktop só aparece na obra — lá o "+ Nova obra" do conteúdo continua (styles.css) */
  const acao = v==='obra' ? 'gasto' : v==='inicio' ? 'obra' : '';
  const fab = $('#fab');
  fab.dataset.acao = acao;
  fab.classList.toggle('hidden', !acao);
  fab.setAttribute('aria-label', acao==='obra' ? 'Nova obra' : 'Lançar gasto');
  document.body.classList.toggle('com-fab', !!acao); // respiro: o + não cobre o fim da página
```

e, logo depois da linha que acende `nav.tabs button[data-tab]` (`...toggle('on',x.dataset.tab===aba));`), acrescentar

```js
  $('nav.tabs').dataset.aba = String(['inicio','simula','ajustes'].indexOf(aba)); // lente desliza até a aba
```

No handler `$('#fab').onclick = ()=>{`, como primeira linha do corpo:

```js
  if($('#fab').dataset.acao==='obra'){ formNovaObra(); return; }
```

No texto da lista vazia (linha com `'Nenhuma obra ainda.<br>Toque em “+ Nova obra” pra começar.'`), trocar para `'Nenhuma obra ainda.<br>Toque no + pra criar a primeira obra.'`.

- [ ] **Step 5: CSS — botão + de vidro em qualquer largura**

Na regra base `.fab{...}` (seção `/* FAB */`), trocar `background:linear-gradient(140deg,var(--fab-a),var(--fab-b));color:var(--fab-ink);font-size:28px;box-shadow:0 6px 24px var(--fab-shadow);` por
`background:var(--vidro-tinta);color:var(--vidro-tinta-ink);font-size:30px;-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro);box-shadow:var(--vidro-brilho),var(--vidro-sombra);transition:transform var(--mola-dur) var(--mola);`,
trocar `.fab:active{transform:scale(.94)}` por `.fab:active{transform:scale(.94);transition:transform .1s ease-out}` (encolhe na hora, volta com a mola)
e acrescentar depois dela:

```css
  /* materializa ao aparecer (display none → grid dispara a animação); o toque encolhe na hora */
  .fab:not(.hidden){animation:materializa var(--mola-dur) var(--mola)}
  @keyframes materializa{from{opacity:0;transform:scale(.6)}}
```

Em `body.locked .app,body.locked nav.tabs,body.locked .fab{visibility:hidden}`, acrescentar `,body.locked .esfumado-abas`.

No bloco do desktop (`@media (min-width:900px){` da "sidebar desktop"), acrescentar `#fab[data-acao="obra"]{display:none} .esfumado-abas{display:none}`. Fora de qualquer media query, perto da regra `.fab`, acrescentar `.esfumado-abas{display:none}` (só o celular mostra).

- [ ] **Step 6: CSS — cápsula no celular**

No bloco `@media screen and (max-width:899px)` das "barras no padrão iOS", **substituir** as linhas de `nav.tabs{background:var(--vidro)...` até `.toast-wrap{bottom:calc(49px + 90px + env(safe-area-inset-bottom))}` (inclusive: regras de `nav.tabs`, `nav.tabs button`, `nav.tabs button .ti`, `nav.tabs button:active`, `body`, `body.com-fab`, `.fab`, `.toast-wrap`) por:

```css
    /* ===== Liquid Glass: cápsula de abas + botão + (iOS 26) =====
       A barra de abas vira uma cápsula de vidro que flutua sobre o conteúdo; o + é um círculo
       de vidro da marca ao lado dela. --abas-base: no iPhone com barra de início, a área segura
       (34px) já afasta do pé; o −10px aproxima a cápsula do indicador, como no iOS 26. */
    :root{--abas-h:62px;--abas-base:max(12px,calc(env(safe-area-inset-bottom) - 10px));--abas-margem:12px;--fab-vao:10px}
    nav.tabs{left:var(--abas-margem);right:var(--abas-margem);bottom:var(--abas-base);height:var(--abas-h);min-height:0;padding:4px;border:0;
      border-radius:calc(var(--abas-h) / 2);background:var(--vidro);-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro);
      box-shadow:var(--vidro-brilho),var(--vidro-sombra);transition:right var(--mola-dur) var(--mola)}
    /* com o + à vista a cápsula recua para dar lugar a ele — a borda direita desliza com mola */
    body.com-fab nav.tabs{right:calc(var(--abas-margem) + var(--abas-h) + var(--fab-vao))}
    /* lente da aba selecionada: desliza entre as abas (data-aba vem do showView) */
    nav.tabs::before{content:"";position:absolute;top:4px;bottom:4px;left:4px;width:calc((100% - 8px) / 3);border-radius:calc((var(--abas-h) - 8px) / 2);
      background:var(--brand-soft);transform:translateX(calc(var(--aba-i,0) * 100%));transition:transform var(--mola-dur) var(--mola);pointer-events:none}
    nav.tabs[data-aba="1"]{--aba-i:1}
    nav.tabs[data-aba="2"]{--aba-i:2}
    nav.tabs[data-aba="-1"]::before{opacity:0}
    nav.tabs button{position:relative;z-index:1;border-radius:calc((var(--abas-h) - 8px) / 2);padding:4px 0 2px;min-height:0;font-size:11px;font-weight:600;gap:2px;
      transition:transform var(--mola-dur) var(--mola)}
    nav.tabs button .ti{font-size:24px}
    /* resposta no toque, não no soltar: encolhe em 0,1s e volta com a mola */
    nav.tabs button:active{opacity:1;transform:scale(.94);transition:transform .1s ease-out}
    /* tinta da aba sobre a lente: a --brand sobre a --brand-soft dá 4,4:1 no escuro; a do chip ligado passa */
    nav.tabs button.on{color:var(--chip-on-ink)}
    html[data-theme="light"] nav.tabs button.on{color:var(--brand-600)}
    .fab{right:var(--abas-margem);bottom:var(--abas-base);width:var(--abas-h);height:var(--abas-h)}
    .esfumado-abas{display:block;position:fixed;left:0;right:0;bottom:0;height:calc(var(--abas-h) + var(--abas-base) + 28px);z-index:39;pointer-events:none;
      background:linear-gradient(to top,var(--bg) 0%,transparent 100%)}
    body,body.com-fab{padding-bottom:calc(var(--abas-h) + var(--abas-base) + 24px)}
    .toast-wrap{bottom:calc(var(--abas-h) + var(--abas-base) + 14px)}
    /* o "+ Nova obra" do conteúdo repetia o + da cápsula */
    #btnNovaObra{display:none}
```

Remova também a regra antiga `nav.tabs button.on .ti{transform:translateY(-1px)}` do bloco `/* bottom nav */` se ela ainda existir fora do desktop (a lente substitui o realce).

- [ ] **Step 7: Rodar a suíte do vidro**

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/vidro.cjs; pkill -f tests/browser/servidor.cjs`
Expected: todos `ok`. Se "fim da obra…" falhar, aumente o `+ 24px` do `padding-bottom` do `body` até passar.

- [ ] **Step 8: Contraste da cápsula e ajuste do alfa**

Em `tests/browser/contraste.cjs`, perto dos helpers, acrescentar:

```js
const hex = h => { h = h.trim().replace('#', ''); return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)); };
```

No laço dos 4 combos, **remover** a entrada `['nav.tabs button.on', 'aba ativa'],` da lista `alvos` e, logo depois do `for` que mede os `alvos` (antes de `await page.close();`), acrescentar:

```js
      /* cápsula de abas (Liquid Glass): o rótulo inativo fica sobre o --vidro, translúcido, que
         passa por cima do fundo do app, dos grupos e do card de saldo (pior caso); a aba ativa
         fica sobre a lente opaca (--brand-soft). */
      const abas = await page.evaluate(() => {
        const raiz = getComputedStyle(document.documentElement);
        return {
          vidro: getComputedStyle(document.querySelector('nav.tabs')).backgroundColor,
          inativa: getComputedStyle(document.querySelector('nav.tabs button:not(.on)')).color,
          ativa: getComputedStyle(document.querySelector('nav.tabs button.on')).color,
          lente: raiz.getPropertyValue('--brand-soft'),
          luz: raiz.getPropertyValue('--vidro-luz'),
          fundos: ['--bg', '--surface-solid', '--saldo-a', '--saldo-b'].map(v => [v, raiz.getPropertyValue(v)]),
        };
      });
      // o brightness() do filtro (--vidro-luz) age sobre o que passa por baixo, antes do preenchimento
      const luz = parseFloat(abas.luz) || 1;
      const sob = cor => hex(cor).map(v => Math.min(255, v * luz));
      for(const [nomeFundo, cor] of abas.fundos){
        const c = contraste(rgba(abas.inativa).slice(0, 3), misturar(rgba(abas.vidro), sob(cor)));
        const ok = c >= 4.5; if(!ok) falhas++;
        console.log(`${ok?'ok   ':'FALHA'} - 390x844/${tema}/${skin}/aba inativa sobre ${nomeFundo}: contraste ${c.toFixed(2)} (min 4.5)`);
      }
      const cAtiva = contraste(rgba(abas.ativa).slice(0, 3), hex(abas.lente));
      if(cAtiva < 4.5) falhas++;
      console.log(`${cAtiva >= 4.5 ? 'ok   ' : 'FALHA'} - 390x844/${tema}/${skin}/aba ativa sobre a lente: contraste ${cAtiva.toFixed(2)} (min 4.5)`);
```

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/contraste.cjs /tmp; pkill -f tests/browser/servidor.cjs`

Se algum "aba inativa sobre …" falhar num combo, primeiro ajuste o `--vidro-luz` daquele bloco (escuro: descer em passos de .04 até no mínimo .66; claro: subir em passos de .04 até no máximo 1.22); se ainda falhar, suba o alfa do `--vidro` daquele bloco em passos de .02 — o Giovani pediu o vidro o mais transparente possível, então pare no primeiro valor que passa; se "aba ativa" falhar, ajuste a tinta ativa daquele combo usando uma cor já existente nos tokens (ex.: `--side-on-ink`) — nunca cor solta. Ao final, deixe um comentário curto junto do `--vidro` de cada bloco com o menor contraste medido (padrão do `--barra` antigo, ex.: `/* .70: rótulo inativo ≥4,5:1 até sobre o card de saldo (4,62) */`).

Em `tests/browser/rodar.cjs`, depois de `await run('tests/browser/vidro.cjs');`, acrescentar `await run('tests/browser/contraste.cjs',[os.tmpdir()]);`.

- [ ] **Step 9: Suítes que dependiam do desenho antigo**

- `tests/browser/ios.cjs` e `tests/browser/fase2.cjs`: no celular (<900px) o `#btnNovaObra` agora está escondido — onde a suíte clica nele num viewport de celular, trocar por `page.locator('#fab').click()` (em Obras o + abre Nova obra). No desktop, manter `#btnNovaObra`.
- `ios.cjs`: qualquer asserção que cite a barra de abas cheia (altura 49px, encostada no pé) passa a esperar a cápsula (62px, a 12px das bordas).

Run: `npm run test:browser`
Expected: exit 0. Corrija as suítes (não o app) quando a falha for só expectativa do desenho antigo; corrija o app quando for regressão de comportamento.

- [ ] **Step 10: Commit**

```bash
git add index.html app.js styles.css tests/browser/vidro.cjs tests/browser/contraste.cjs tests/browser/rodar.cjs tests/browser/ios.cjs tests/browser/fase2.cjs
git commit -m "feat: barra de abas em cápsula de vidro com o botão + ao lado" -m "No celular, as abas viram uma cápsula de vidro flutuante, com uma lente que desliza até a aba da tela, e o + vira um círculo de vidro da marca ao lado dela, como a busca nos apps do iOS 26. Em Obras o + cria obra; dentro da obra, lança gasto; nas outras telas ele some e a cápsula ocupa a largura. O conteúdo some num esfumado sob a cápsula, e o contraste dos rótulos foi medido sobre o pior fundo que passa por baixo."
```

---

### Task 5: Barra de navegação — itens de vidro e efeito de borda de rolagem (celular e desktop)

**Files:**
- Modify: `styles.css` (bloco "barras no padrão iOS" do celular; bloco "sidebar desktop"; bloco novo `@media screen{...}` antes do bloco do celular)
- Modify: `tests/ios.test.cjs`, `tests/vidro.test.cjs`, `tests/browser/vidro.cjs`, `tests/browser/ios.cjs` (asserções de desktop), `tests/browser/contraste.cjs` (laço da pílula)

**Interfaces:**
- Consumes: tokens de vidro (T3); classe `colapsada` do `header.top` (já existente, `app.js`).
- Produces: `header.top::before` (esfumado de borda, opacidade 1 com `colapsada`); `.nav-voltar`, `header.top .sair`, `header.top .sync-pill` de vidro; no desktop, título grande e voltar na barra (a logo do cabeçalho some); variável `--lateral` (largura reservada à lateral no desktop, `248px` aqui, a T9 muda).

- [ ] **Step 1: Testes que falham**

Em `tests/vidro.test.cjs`, acrescentar:

```js
test('efeito de borda da barra mora no ::before, não no header (raiz de fundo)', ()=>{
  const antes = regras.find(r => r.sel === 'header.top::before');
  assert.ok(antes, 'falta header.top::before');
  assert.match(antes.decl, /-webkit-backdrop-filter:/);
  assert.match(antes.decl, /mask-image:/);
  const noHeader = regras.filter(r => /^header\.top(\.colapsada)?$/.test(r.sel) && /backdrop-filter:/.test(r.decl));
  assert.deepEqual(noHeader.map(r => r.sel), []);
});
```

Em `tests/ios.test.cjs`, no teste `'barras translúcidas com material por tema'`, trocar a linha `assert.match(css, /header\.top\.colapsada\{[^}]*-webkit-backdrop-filter/);` por `assert.match(css, /header\.top::before\{[^}]*-webkit-backdrop-filter/);`.

Em `tests/browser/vidro.cjs`, acrescentar:

```js
    /* ---- barra de navegação ---- */
    await teste('voltar, sair e sincronização são vidro; a barra em si não', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      assert.match(await estilo(page, '#navVoltar', 'backdropFilter'), /blur\(24px\)/);
      assert.equal(await estilo(page, '#navVoltar', 'borderTopLeftRadius'), '22px');
      assert.equal(await estilo(page, 'header.top', 'backdropFilter'), 'none');
      await ctx.close();
    });
    await teste('rolar mostra o esfumado de borda; voltar ao topo esconde', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      await page.evaluate(() => window.scrollTo(0, 500));
      await page.waitForFunction(() => document.querySelector('header.top').classList.contains('colapsada'));
      await page.waitForTimeout(300);
      assert.equal(await estilo(page, 'header.top', 'opacity', '::before'), '1');
      await page.evaluate(() => window.scrollTo(0, 0));
      await page.waitForFunction(() => !document.querySelector('header.top').classList.contains('colapsada'));
      await page.waitForTimeout(300);
      assert.equal(await estilo(page, 'header.top', 'opacity', '::before'), '0');
      await ctx.close();
    });
    await teste('desktop: título grande e voltar de vidro na barra, sem a logo repetida', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      await page.evaluate(() => openObra('o1'));
      assert.equal(await page.isVisible('#tituloGrande'), true);
      assert.equal(await page.textContent('#tituloGrande'), 'Casa Azul');
      assert.equal(await page.isVisible('#navVoltar'), true);
      assert.equal(await page.isVisible('header.top h1'), false);
      assert.equal(await page.isVisible('section.view.active > .back'), false);
      assert.ok((await caixa(page, 'header.top')).left >= 224, 'barra não pode ficar sob a lateral');
      await page.locator('#navVoltar').click();
      await page.waitForFunction(() => document.querySelector('#v-inicio').classList.contains('active'));
      await ctx.close();
    });
```

Run: `node --test tests/vidro.test.cjs tests/ios.test.cjs` → Expected: FAIL.

- [ ] **Step 2: Bloco compartilhado da barra**

Antes da linha de comentário `/* ===== barras no padrão iOS (celular) =====`, inserir:

```css
  /* ===== Liquid Glass: barra de navegação (todas as larguras) =====
     A barra não tem material: os itens é que são vidro (voltar, sair, sincronização), como no
     iOS 26 e no macOS Tahoe. Ao rolar, o conteúdo some num esfumado com desfoque progressivo
     em vez de ganhar fundo e linha. O esfumado mora no ::before porque um backdrop-filter no
     próprio header viraria raiz de fundo e os botões de vidro dentro dele deixariam de
     enxergar a página. */
  @media screen{
    header.top{position:fixed;top:0;right:0;z-index:50;margin:0;display:grid;grid-template-columns:1fr auto 1fr;align-items:center;background:transparent;border:0}
    header.top::before{content:"";position:absolute;left:0;right:0;top:0;bottom:-28px;z-index:-1;pointer-events:none;opacity:0;transition:opacity .2s;
      background:linear-gradient(to bottom,var(--bg) 0%,var(--bg) 40%,transparent 100%);
      -webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);
      -webkit-mask-image:linear-gradient(to bottom,#000 50%,transparent);mask-image:linear-gradient(to bottom,#000 50%,transparent)}
    header.top.colapsada::before{opacity:1}
    header.top h1{display:none}
    header.top > .layout-22{grid-column:3;grid-row:1;justify-self:end;display:flex;align-items:center;gap:8px}
    .nav-titulo{display:block;grid-column:2;grid-row:1;font-size:17px;font-weight:600;opacity:0;transition:opacity .2s;max-width:min(60vw,calc(100vw - 192px));overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    header.top.colapsada .nav-titulo{opacity:1}
    .nav-voltar,header.top .sair,header.top .sync-pill{background:var(--vidro);-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro);box-shadow:var(--vidro-brilho),var(--vidro-sombra);border:0}
    .nav-voltar{grid-column:1;grid-row:1;justify-self:start;color:var(--brand);font-family:inherit;font-size:17px;font-weight:500;height:44px;padding:0 16px 0 10px;border-radius:22px;display:flex;align-items:center;gap:2px;cursor:pointer;transition:transform var(--mola-dur) var(--mola)}
    .nav-voltar[hidden]{display:none} /* sem isto o display:flex da classe venceria o do atributo */
    .nav-voltar span:first-child{font-size:30px;line-height:1;margin-top:-3px}
    header.top .sair{width:44px;height:44px;margin-left:0;border-radius:50%;color:var(--brand);font-size:20px;transition:transform var(--mola-dur) var(--mola)}
    .nav-voltar:active,header.top .sair:active{transform:scale(.94);transition:transform .1s ease-out}
    header.top .sync-pill{position:relative}
    header.top .sync-pill::before{content:"";position:absolute;inset:-8px -4px} /* 28px de pílula, 44px de toque */
    section.view > .back{display:none} /* o voltar mora na barra */
    .titulo-grande{display:block;font-size:34px;font-weight:700;letter-spacing:-.02em;margin:4px 4px 14px;line-height:1.15;overflow-wrap:anywhere}
  }
```

- [ ] **Step 3: Enxugar o bloco do celular**

No bloco `@media screen and (max-width:899px)` das barras, **remover** as regras que agora estão no bloco compartilhado: `header.top{...}` (as três linhas), `header.top h1{display:none}`, `header.top > .layout-22{...}`, `header.top.colapsada{...}`, `.nav-titulo{...}`, `header.top.colapsada .nav-titulo{...}`, `.nav-voltar{...}`, `.nav-voltar[hidden]{...}`, `.nav-voltar span:first-child{...}`, `.nav-voltar:active{...}`, `header.top .sair{...}`, `header.top .sair:active{...}`, `header.top .sync-pill{...}`, `header.top .sync-pill::before{...}`, `section.view > .back{...}`, `.titulo-grande{...}`. No lugar, deixar só:

```css
    .app{padding-top:calc(52px + env(safe-area-inset-top));overflow-x:hidden;overflow-x:clip}
    header.top{left:0;min-height:calc(52px + env(safe-area-inset-top));padding:env(safe-area-inset-top) max(8px,env(safe-area-inset-right)) 0 max(8px,env(safe-area-inset-left))}
```

(mantendo o comentário existente sobre `clip`/`hidden` e a regra `html.nativo body::after, html.standalone body::after{display:none}`). A regra `.nav-voltar,.nav-titulo,.titulo-grande{display:none}` do topo do arquivo continua (vale para a impressão).

- [ ] **Step 4: Desktop**

No bloco `@media (min-width:900px){` da "sidebar desktop": trocar `.app{margin:0 auto 0 248px;max-width:880px}` por `.app{margin:0 auto 0 var(--lateral);max-width:880px;padding-top:64px}` e acrescentar `:root{--lateral:248px} header.top{left:var(--lateral);min-height:60px;padding:8px 24px 0 16px}`. A regra `header.top .sair{display:none}` que já existe continua.

- [ ] **Step 5: Ajustar suítes**

- `tests/browser/ios.cjs`, bloco do desktop: `tituloGrandeVisivel` passa a ser `true` (a asserção vira `assert.equal(r.tituloGrandeVisivel, true, 'no desktop o título grande também aparece (padrão macOS)')`); `navVoltarVisivel` continua `false` em Obras.
- `tests/browser/contraste.cjs`, primeiro laço (pílula): a pílula agora tem fundo de vidro translúcido; compor o fundo sobre o `--bg` do body antes de medir, como o segundo laço faz: trocar `const c = contraste(rgb(m.cor), rgb(m.fundo));` por
  `const corBody = rgba(await page.evaluate(() => getComputedStyle(document.body).backgroundColor)); const f = rgba(m.fundo); const c = contraste(rgb(m.cor), f[3] < 1 ? misturar(f, corBody) : f.slice(0,3));`
  (declare `corBody` uma vez por página, fora do `for` dos estados). Se a pílula falhar em algum estado, use `--vidro-folha` no fundo dela (`header.top .sync-pill{background:var(--vidro-folha)}`) em vez de mexer na cor do texto.

- [ ] **Step 6: Rodar**

Run: `npm run test:unit && npm run test:browser`
Expected: tudo verde. Rode também `node tests/browser/contraste.cjs /tmp` com o servidor no ar.

- [ ] **Step 7: Commit**

```bash
git add styles.css tests/ios.test.cjs tests/vidro.test.cjs tests/browser/vidro.cjs tests/browser/ios.cjs tests/browser/contraste.cjs
git commit -m "feat: barra de navegação com itens de vidro e esfumado ao rolar" -m "O voltar, o sair e a pílula de sincronização viram cápsulas e círculos de vidro, e a barra deixa de ganhar fundo e linha ao rolar: o conteúdo some num esfumado com desfoque progressivo, como no iOS 26. O desktop passa a usar a mesma barra, com título grande e voltar de vidro no lugar da logo repetida e do link solto."
```

---

### Task 6: Sheets flutuantes, folha cheia e saída pelo mesmo caminho

**Files:**
- Modify: `app.js` (`openSheet`, `closeSheet`, ouvinte de `resize`)
- Modify: `gestos.js` (`fecharSheet`)
- Modify: `styles.css` (bloco `/* modal */`, `.sheet .sheet-actions`, bloco "sheet com alça" do celular, bloco dos gestos `.sheet{transform...}`, desktop)
- Modify: `tests/browser/vidro.cjs`, `tests/browser/ios.cjs`

**Interfaces:**
- Consumes: `--vidro-folha`, `--vidro-filtro-forte`, `--vidro-brilho`, `--vidro-sombra`, `--mola`, `--mola-dur`, `--mola-quique*`; `OBRA_GESTOS` (T2).
- Produces: classes `#backdrop.saindo` (pintura da saída, sem cliques) e `#backdrop.cheia` (folha cheia); `closeSheet()` continua síncrona no estado (`show`/`sheet-open`/rolagem mudam na hora); `openSheet()` cancela saída em curso.

- [ ] **Step 1: Testes que falham (em `tests/browser/vidro.cjs`)**

```js
    /* ---- sheets ---- */
    const CURTA = '<h3>Teste</h3><p>linha</p><div class="sheet-actions"><button class="btn primary" id="bOk">Ok</button></div>';
    await teste('sheet flutua em vidro no celular, e o véu não vira raiz de fundo', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(h => openSheet(h), CURTA);
      await page.waitForTimeout(700);
      const s = await caixa(page, '#sheet');
      assert.ok(perto(s.left, 8) && perto(s.right, 390 - 8) && perto(s.bottom, 844 - 8), `sheet em ${JSON.stringify(s)}`);
      assert.equal(await estilo(page, '#sheet', 'borderTopLeftRadius'), '32px');
      assert.match(await estilo(page, '#sheet', 'backdropFilter'), /blur\(40px\)/);
      assert.equal(await estilo(page, '#backdrop', 'backdropFilter'), 'none');
      assert.equal(await estilo(page, '#backdrop', 'opacity'), '1');
      await ctx.close();
    });
    await teste('fechar muda o estado na hora e a pintura sai pelo mesmo caminho', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(h => openSheet(h), CURTA);
      await page.waitForTimeout(700);
      const agora = await page.evaluate(() => { closeSheet(); const b = document.getElementById('backdrop');
        return { show:b.classList.contains('show'), saindo:b.classList.contains('saindo'), aberto:document.body.classList.contains('sheet-open') }; });
      assert.deepEqual(agora, { show:false, saindo:true, aberto:false });
      await page.waitForTimeout(700);
      assert.equal(await page.evaluate(() => document.getElementById('backdrop').classList.contains('saindo')), false);
      assert.equal(await estilo(page, '#backdrop', 'display'), 'none');
      await ctx.close();
    });
    await teste('fechar e abrir no mesmo instante mostra a nova sheet clicável', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(h => openSheet(h), CURTA);
      await page.waitForTimeout(700);
      await page.evaluate(() => { closeSheet(); openSheet('<h3>B</h3><button class="btn primary" id="bNovo">Novo</button>'); });
      assert.equal(await page.evaluate(() => document.getElementById('backdrop').classList.contains('saindo')), false);
      await page.waitForTimeout(700);
      await page.locator('#bNovo').click({ timeout:1000 });
      await ctx.close();
    });
    await teste('sheet alta vira folha cheia, encostada nas bordas', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openSheet('<h3>Longa</h3>' + '<p>linha de texto</p>'.repeat(80)));
      await page.waitForTimeout(700);
      assert.equal(await page.evaluate(() => document.getElementById('backdrop').classList.contains('cheia')), true);
      const s = await caixa(page, '#sheet');
      assert.ok(perto(s.left, 0) && perto(s.right, 390) && perto(s.bottom, 844), `folha cheia em ${JSON.stringify(s)}`);
      assert.equal(await estilo(page, '#sheet', 'borderBottomLeftRadius'), '0px');
      await ctx.close();
    });
    await teste('com o teclado aberto a sheet cabe na área visível', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(h => openSheet(h), CURTA);
      await page.evaluate(() => document.documentElement.style.setProperty('--vvh', '500px'));
      await page.waitForTimeout(700);
      const s = await caixa(page, '#sheet');
      assert.ok(s.bottom <= 500 - 8 + 1.5, `sheet termina em ${s.bottom} com área visível de 500`);
      await ctx.close();
    });
    await teste('movimento reduzido: fechar some na hora, sem saída presa', async ()=>{
      const { ctx, page } = await abrir(browser, { movimento:'reduce' });
      await page.evaluate(h => openSheet(h), CURTA);
      const r = await page.evaluate(() => { closeSheet(); const b = document.getElementById('backdrop');
        return { saindo:b.classList.contains('saindo'), display:getComputedStyle(b).display }; });
      assert.deepEqual(r, { saindo:false, display:'none' });
      await ctx.close();
    });
    await teste('desktop: sheet centralizada, sem alça', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      await page.evaluate(h => openSheet(h), CURTA);
      await page.waitForTimeout(700);
      const s = await caixa(page, '#sheet');
      assert.ok(perto((s.top + s.bottom) / 2, 450, 2), `centro vertical ${(s.top + s.bottom) / 2}`);
      assert.ok(s.width <= 560 + 1);
      assert.equal(await estilo(page, '#sheet', 'content', '::before'), 'none');
      await ctx.close();
    });
```

Run → Expected: FALHA nesses testes.

- [ ] **Step 2: `openSheet` / `closeSheet` em `app.js`**

Substituir as funções `openSheet(html)` e `closeSheet()` por:

```js
/* Saída da sheet pelo mesmo caminho da entrada: o estado (show, sheet-open, rolagem) muda na
   hora; só a pintura dura a mola (classe .saindo, sem cliques). Abrir outra sheet no meio
   cancela a saída — a nova assume a partir de onde a velha estava. */
let saidaTimer = null;
function terminaSaida(){
  clearTimeout(saidaTimer); saidaTimer = null;
  backdrop.classList.remove('saindo');
}
/* Sheet que passa de 88% da altura da janela vira folha cheia (encosta nas bordas, fundo
   sólido), como o detent grande do iOS; volta a flutuar só abaixo de 84%, para não oscilar
   quando a própria troca de forma muda a altura. Mede pela janela, não pelo visualViewport:
   o teclado abrindo não pode trocar a forma da sheet enquanto se digita. */
function medeSheet(){
  if(!backdrop.classList.contains('show')) return;
  const r = sheet.scrollHeight / window.innerHeight;
  if(r > 0.88) backdrop.classList.add('cheia');
  else if(r < 0.84) backdrop.classList.remove('cheia');
}
const observaSheet = 'ResizeObserver' in window ? new ResizeObserver(medeSheet) : null;
addEventListener('resize', medeSheet);

function openSheet(html){
  terminaSaida();
  if(sheetScrollY===null){
    sheetScrollY=window.scrollY;
    document.documentElement.style.setProperty('--sheet-scroll-top',`${-sheetScrollY}px`);
  }
  sheet.innerHTML = html;
  backdrop.classList.remove('cheia');
  backdrop.classList.add('show');
  document.body.classList.add('sheet-open');
  sheet.scrollTop = 0;
  syncViewport();
  medeSheet();
  if(observaSheet){ observaSheet.disconnect(); for(const filho of sheet.children) observaSheet.observe(filho); }
}
function closeSheet(){
  clearTimeout(focusSheetTimer);
  if(sheet.contains(document.activeElement)) document.activeElement.blur();
  const estavaAberta = backdrop.classList.contains('show');
  backdrop.classList.remove('show');
  document.body.classList.remove('sheet-open');
  if(observaSheet) observaSheet.disconnect();
  if(estavaAberta){
    const dur = (parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--mola-dur')) || 0) * 1000;
    terminaSaida();
    if(dur > 0){ backdrop.classList.add('saindo'); saidaTimer = setTimeout(terminaSaida, dur + 50); }
  }
  if(sheetScrollY!==null){
    const posicao=sheetScrollY; sheetScrollY=null;
    document.documentElement.style.removeProperty('--sheet-scroll-top');
    window.scrollTo(0,posicao);
  }
}
```

(`backdrop`, `sheet`, `sheetScrollY`, `focusSheetTimer`, `syncViewport` já existem no arquivo; se `backdrop`/`sheet` forem declarados depois dessas funções, mova só as declarações `let saidaTimer`/`const observaSheet`/`addEventListener('resize', medeSheet)` para depois delas.)

- [ ] **Step 3: `gestos.js` — fechar pelo `closeSheet()`**

Substituir a função `fecharSheet()` inteira por:

```js
      /* a saída do closeSheet (.saindo) parte de onde o dedo soltou: a transição do CSS
         começa na posição atual, então o movimento continua sem emenda */
      function fecharSheet(){
        try{ win.closeSheet(); }
        finally{ sheet.style.removeProperty('--dy'); }
      }
```

(a variável `semMovimento` continua usada em `soltarBorda`.)

Fluidez do puxão (achado da revisão da Tarefa 2): o ramo elástico de `movimento` lê `sheet.offsetHeight` a cada `touchmove`, logo depois de escrever `--dy` — leitura de layout forçada no meio do gesto. Guardar a altura uma vez no começo: em `inicio(e)`, trocar `puxada = { ativa:false };` por `puxada = { ativa:false, altura:sheet.offsetHeight };` e, em `movimento`, trocar `elastico(dy, sheet.offsetHeight)` por `elastico(dy, puxada.altura)`.

Em `soltarBorda`, a limpeza depois da volta usa hoje um tempo fixo (`}, 260);`). Com a mola de quique a volta dura `--mola-quique-dur` (0,41s); limpar antes cortaria a animação no meio. Trocar a linha

```js
        win.setTimeout(() => { if(!borda || borda.tela !== b.tela) els.forEach(limparTela); }, 260);
```

por

```js
        // espera a mola de quique terminar (a duração vem do CSS; zero com movimento reduzido)
        const dur = (parseFloat(win.getComputedStyle(html).getPropertyValue('--mola-quique-dur')) || 0) * 1000;
        win.setTimeout(() => { if(!borda || borda.tela !== b.tela) els.forEach(limparTela); }, dur + 40);
```

- [ ] **Step 4: CSS das sheets**

No bloco `/* modal */`:
- na regra `.backdrop{position:fixed;...;background:rgba(8,15,20,.5);backdrop-filter:blur(2px);display:none;...}`, trocar `background:rgba(8,15,20,.5);backdrop-filter:blur(2px);` por `background:rgba(0,0,0,0);transition:background-color var(--mola-dur) var(--mola);`.
- na regra `.sheet{background:var(--surface-solid);...;box-shadow:0 -8px 40px rgba(0,0,0,.3);animation:up .28s cubic-bezier(.2,.8,.2,1)}`, trocar `background:var(--surface-solid);` por `background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro-forte);backdrop-filter:var(--vidro-filtro-forte);`, `box-shadow:0 -8px 40px rgba(0,0,0,.3);` por `box-shadow:var(--vidro-brilho),var(--vidro-sombra);` e `animation:up .28s cubic-bezier(.2,.8,.2,1)` por `animation:sobe var(--mola-dur) var(--mola)`.
- em `.sheet .sheet-actions{...;background:var(--surface-solid);...}`, trocar `background:var(--surface-solid)` por `background:linear-gradient(to bottom,transparent 0,var(--vidro-folha) 18px)` (esfumado em vez de bloco sólido).
- logo depois da regra `.backdrop.show{display:flex}`, acrescentar:

```css
  /* Liquid Glass: o véu escurece por background-color — opacity ou backdrop-filter aqui virariam
     raiz de fundo e a sheet de vidro deixaria de enxergar a página. Entra com a mola; na saída
     (.saindo, app.js) o véu clareia e a sheet desce pelo mesmo caminho por onde subiu. */
  .backdrop.show{background:rgba(0,0,0,.4);animation:escurece var(--mola-dur) var(--mola)}
  html[data-theme="light"] .backdrop.show{background:rgba(0,0,0,.2)}
  .backdrop.saindo{display:flex;pointer-events:none}
  .backdrop.saindo .sheet{transform:translateY(calc(100% + 24px));transition:transform var(--mola-dur) var(--mola)}
  @keyframes escurece{from{background-color:rgba(0,0,0,0)}}
  @keyframes sobe{from{transform:translateY(calc(100% + 24px))}}
```

No bloco dos gestos (`/* gestos (gestos.js) */`), as três transições que acontecem depois de um gesto com impulso passam para a mola de quique:
- `li.swipe > *{transform:translateX(var(--dx,0px));transition:transform .25s cubic-bezier(.2,.8,.2,1)}` → `transition:transform var(--mola-quique-dur) var(--mola-quique)`;
- `.sheet{transform:translateY(var(--dy,0px));transition:transform .25s cubic-bezier(.2,.8,.2,1)}` → `transition:transform var(--mola-quique-dur) var(--mola-quique)`;
- `section.view.active.soltando-borda,.titulo-grande.soltando-borda{...;transition:transform .25s cubic-bezier(.2,.8,.2,1)}` → `transition:transform var(--mola-quique-dur) var(--mola-quique)`.

O `@media (prefers-reduced-motion: reduce)` final desse bloco pode ficar como está (as durações já zeram pelo token).

No bloco "conteúdo no padrão iOS (celular)", trocar `.sheet{border-radius:14px 14px 0 0;padding-top:22px;position:relative}` por:

```css
    /* sheet flutuante do iOS 26: 8px das bordas, cantos de 32px concêntricos com a tela */
    .backdrop{padding:max(12px,env(safe-area-inset-top)) 8px calc(8px + env(safe-area-inset-bottom))}
    .sheet{border-radius:32px;padding:26px 20px 20px;position:relative}
    .sheet .sheet-actions{bottom:-20px;padding-bottom:20px}
    /* folha cheia (app.js, medeSheet): encosta nas bordas, fundo sólido, cantos só em cima */
    .backdrop.cheia{padding:max(12px,env(safe-area-inset-top)) 0 0}
    .backdrop.cheia .sheet{border-radius:32px 32px 0 0;background:var(--surface-solid);-webkit-backdrop-filter:none;backdrop-filter:none;padding-bottom:calc(20px + env(safe-area-inset-bottom))}
    .backdrop.cheia .sheet .sheet-actions{bottom:calc(-20px - env(safe-area-inset-bottom));padding-bottom:calc(20px + env(safe-area-inset-bottom));background:var(--surface-solid)}
```

No bloco do desktop (`@media (min-width:900px){` da sidebar), acrescentar:

```css
    /* form sheet do iPad/Mac: centralizada, materializa crescendo junto com a opacidade */
    .backdrop{align-items:center;padding:24px}
    .sheet{max-width:560px;border-radius:28px;max-height:min(84dvh,100%);animation:materializa var(--mola-dur) var(--mola)}
    .sheet::before{content:none}
    .backdrop.saindo .sheet{transform:scale(.96);opacity:0;transition:transform var(--mola-dur) var(--mola),opacity .18s ease}
```

(`@keyframes materializa` já existe desde a Tarefa 4.)

- [ ] **Step 5: Ajustar `ios.cjs`**

As asserções do PR #22 sobre o sheet de Nova obra: "deve encostar no fundo" passa a esperar a base flutuante — `Math.abs(caixa.bottom - (caixa.vh - 8)) < 1` quando `#backdrop` não tem `cheia`, ou `Math.abs(caixa.bottom - caixa.vh) < 1` quando tem. "Nova obra deve caber inteira sem rolar" continua valendo; se passar a falhar, reduza o respiro (`padding` da sheet no celular) em vez de apagar a asserção. Qualquer espera fixa de 200ms depois do puxão para fechar vira espera pela condição `!#backdrop.classList.contains('saindo')`.

- [ ] **Step 6: Rodar**

Run: `npm run test:unit && npm run test:browser`
Expected: verde. Confira em especial o puxar-para-fechar do `ios.cjs`.

- [ ] **Step 7: Commit**

```bash
git add app.js gestos.js styles.css tests/browser/vidro.cjs tests/browser/ios.cjs
git commit -m "feat: sheets flutuantes de vidro que saem pelo mesmo caminho" -m "No celular a sheet flutua a 8px das bordas, com cantos de 32px e vidro denso; quando o conteúdo passa de 88% da tela, ela vira folha cheia com fundo sólido, como o detent grande do iOS. Fechar agora desce a sheet e clareia o véu em vez de sumir de uma vez, sem atrasar o estado: closeSheet continua síncrona e abrir outra sheet no meio cancela a saída. No desktop a sheet é centralizada, como a form sheet do iPad e do Mac."
```

---

### Task 7: Diálogos, tela de valor, toasts e globo pausado sob vidro

**Files:**
- Modify: `styles.css` (regras `.conta-dialog`, `.conta-dialog::backdrop`; `.valor-tela`; `.toast`, `.toast-wrap`)
- Modify: `globe.js` (pausa sob vidro)
- Modify: `tests/browser/vidro.cjs`

**Interfaces:**
- Consumes: tokens de vidro e mola.
- Produces: `window.__globeEstado()` continua `{ rodando }`; o laço do globo não roda com `body.sheet-open`, `body.teclado-open` ou `dialog[open]`.

- [ ] **Step 1: Testes que falham**

```js
    /* ---- diálogos, tela de valor, toasts, globo ---- */
    await teste('diálogo de confirmação é vidro com cantos de 28px', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => { window.__resp = OBRA_CONFIRM.perguntar('Excluir este gasto?', { confirmar:'Excluir' }); });
      await page.waitForSelector('dialog.confirma-dialog[open]');
      assert.match(await estilo(page, 'dialog.confirma-dialog', 'backdropFilter'), /blur\(40px\)/);
      assert.equal(await estilo(page, 'dialog.confirma-dialog', 'borderTopLeftRadius'), '28px');
      await ctx.close();
    });
    await teste('tela de valor é vidro denso', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      await page.locator('#fab').click();
      await page.waitForFunction(() => document.body.classList.contains('teclado-open'));
      assert.match(await estilo(page, '.valor-tela', 'backdropFilter'), /blur\(40px\)/);
      await ctx.close();
    });
    await teste('toast é cápsula de vidro acima da cápsula de abas', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => toast('Gasto lançado'));
      await page.waitForTimeout(300);
      const t = await caixa(page, '.toast'), n = await caixa(page, 'nav.tabs');
      assert.ok(t.bottom <= n.top - 8, `toast termina em ${t.bottom}, cápsula começa em ${n.top}`);
      assert.match(await estilo(page, '.toast', 'backdropFilter'), /blur/);
      assert.ok(parseFloat(await estilo(page, '.toast', 'borderTopLeftRadius')) >= t.height / 2 - 1);
      await ctx.close();
    });
    await teste('globo pausa sob sheet e diálogo e volta depois', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(h => openSheet(h), '<h3>x</h3>');
      await page.waitForTimeout(150);
      assert.equal(await page.evaluate(() => __globeEstado().rodando), false, 'globo rodando sob a sheet');
      await page.evaluate(() => closeSheet());
      await page.waitForFunction(() => __globeEstado().rodando, null, { timeout:2000 });
      await page.evaluate(() => { OBRA_CONFIRM.perguntar('x?'); });
      await page.waitForTimeout(150);
      assert.equal(await page.evaluate(() => __globeEstado().rodando), false, 'globo rodando sob o diálogo');
      await ctx.close();
    });
```

Run → Expected: FALHA.

- [ ] **Step 2: CSS**

- `.conta-dialog{background:var(--surface-solid);color:var(--text);border:1px solid var(--border);border-radius:22px;...}` → trocar `background:var(--surface-solid)` por `background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro-forte);backdrop-filter:var(--vidro-filtro-forte);box-shadow:var(--vidro-brilho),var(--vidro-sombra)`, `border:1px solid var(--border)` por `border:0` e `border-radius:22px` por `border-radius:28px`. Acrescentar ao fim da regra `;animation:materializa var(--mola-dur) var(--mola)`.
- `.conta-dialog::backdrop{background:rgba(0,0,0,.65)` → `rgba(0,0,0,.4)`.
- `.valor-tela{...;background:var(--surface-solid);...;animation:up .24s cubic-bezier(.2,.8,.2,1)}` → `background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro-forte);backdrop-filter:var(--vidro-filtro-forte);` e `animation:sobe var(--mola-dur) var(--mola)`.
- `.toast{...;background:var(--surface-solid);...;border:1px solid var(--border);border-radius:13px;...;box-shadow:var(--shadow);...}` → `background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro);border:0;border-radius:999px;box-shadow:var(--vidro-brilho),var(--vidro-sombra)`, e a entrada `animation:toastIn .22s ease-out forwards` → `animation:toastIn var(--mola-dur) var(--mola) forwards` (a saída `toastOut` fica curta, .18s: sumir não precisa de mola). Em `.toast.erro{border-color:var(--red);color:var(--red)}` → `.toast.erro{color:var(--red);box-shadow:var(--vidro-brilho),inset 0 0 0 1px var(--red),var(--vidro-sombra)}`.

- [ ] **Step 3: `globe.js`**

Logo depois de `function retomar(){`, a primeira linha passa a ser

```js
    if(document.hidden || running || sobVidro()) return;
```

e, antes de `function retomar(){`, acrescentar:

```js
  /* sheet, diálogo ou tela de valor por cima: o vidro grande teria de recompor o desfoque a
     cada quadro do globo — pausa enquanto houver algo por cima e retoma quando sair */
  const sobVidro = () => document.body.classList.contains('sheet-open') ||
    document.body.classList.contains('teclado-open') || !!document.querySelector('dialog[open]');
```

e, antes de `window.__globeEstado=()=>({ rodando:running });`, acrescentar:

```js
  new MutationObserver(()=>{ if(sobVidro()) paraQuadro(); else retomar(); })
    .observe(document.body, { attributes:true, attributeFilter:['class'], childList:true });
```

- [ ] **Step 4: Rodar**

Run: `npm run test:unit && npm run test:browser`
Expected: verde.

- [ ] **Step 5: Commit**

```bash
git add styles.css globe.js tests/browser/vidro.cjs
git commit -m "feat: diálogos, tela de valor e avisos em vidro" -m "Os diálogos de conta e de confirmação, a tela de digitar valor e os avisos rápidos passam a usar o vidro denso, com cantos maiores e entrada com mola. O globo pausa enquanto há sheet, diálogo ou teclado por cima, para o desfoque não ser recomposto a cada quadro."
```

---

### Task 8: Botões em cápsula, busca em cápsula, chave de tema e grupos no desktop

**Files:**
- Modify: `styles.css` (`.btn` base e do celular; `.filter-row`/`.busca` do celular; `.tgl-tema`; regras de superfície dos grupos)
- Modify: `tests/vidro.test.cjs`, `tests/browser/vidro.cjs`

**Interfaces:**
- Consumes: tokens de vidro e mola.
- Produces: `.btn` com `border-radius:999px`; `.tgl-tema:active .bola` de vidro; `.panel,.card,.kpi` sem borda/sombra e opacos também no desktop.

- [ ] **Step 1: Testes que falham**

Em `tests/vidro.test.cjs`:

```js
test('botões de ação em cápsula (iOS 26)', ()=>{
  assert.ok(regras.some(r => r.sel === '.btn' && /border-radius:999px/.test(r.decl)), '.btn base sem cápsula');
});

test('toque encolhe na hora e volta com mola; troca de tela com mola', ()=>{
  assert.ok(regras.some(r => r.sel === '.btn' && /transition:transform var\(--mola-dur\) var\(--mola\)/.test(r.decl)), '.btn sem mola de volta');
  assert.ok(regras.some(r => r.sel === '.btn:active' && /scale\(\.97\)/.test(r.decl) && /\.1s ease-out/.test(r.decl)), '.btn:active sem resposta imediata');
  for(const k of ['entra-direita', 'entra-esquerda']){
    assert.ok(regras.some(r => new RegExp(`animation:${k} var\\(--mola-dur\\) var\\(--mola\\)`).test(r.decl)), `${k} sem mola`);
  }
});
```

Em `tests/browser/vidro.cjs`:

```js
    /* ---- controles e conteúdo ---- */
    await teste('botões e busca em cápsula', async ()=>{
      const { ctx, page } = await abrir(browser);
      await page.evaluate(() => openObra('o1'));
      for(const sel of ['.obra-actions .btn', '.busca input']){
        const h = (await caixa(page, sel)).height;
        assert.ok(parseFloat(await estilo(page, sel, 'borderTopLeftRadius')) >= h / 2 - 1, `${sel} não é cápsula`);
      }
      await ctx.close();
    });
    await teste('chave de tema vira lente de vidro enquanto é apertada', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      await page.evaluate(() => { showView('ajustes'); renderAjustes(); });
      const b = await caixa(page, '#ajTema');
      await page.mouse.move(b.left + b.width / 2, b.top + b.height / 2);
      await page.mouse.down();
      await page.waitForTimeout(100);
      assert.match(await estilo(page, '#ajTema .bola', 'backdropFilter'), /blur/);
      await page.mouse.up();
      await ctx.close();
    });
    await teste('desktop: grupos sem borda nem sombra, opacos', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      await page.evaluate(() => openObra('o1'));
      assert.equal(await estilo(page, '.panel', 'borderTopWidth'), '0px');
      assert.equal(await estilo(page, '.panel', 'boxShadow'), 'none');
      assert.match(await estilo(page, '.panel', 'backgroundColor'), /^rgb\(/);
      await ctx.close();
    });
```

Run → Expected: FALHA.

- [ ] **Step 2: CSS**

- Regra base `.btn{flex:1;border:0;border-radius:12px;...}` → `border-radius:999px`. No bloco do celular, `.btn,.sheet .btn{min-height:50px;border-radius:12px;...}` → `border-radius:999px`.
- No bloco do celular, busca: em `.filter-row input,.filter-row select{border:0;border-radius:10px;...}`, `.busca input{...;border-radius:10px;...}` e `.filter-row .afz-add{min-height:44px;border-radius:10px}` → `border-radius:999px` nos três.
- `.notif-invite-actions .btn` e `.install-hint button`: `border-radius:999px`.
- Toque dos botões com mola (pedido de animações fluidas): na regra base `.btn`, acrescentar `transition:transform var(--mola-dur) var(--mola)` e, logo depois, `.btn:active{transform:scale(.97);transition:transform .1s ease-out}`; no bloco do celular, trocar `.btn:active{opacity:.6;transform:none}` por `.btn:active{opacity:1;transform:scale(.97);transition:transform .1s ease-out}`.
- Troca de tela com mola: no bloco das barras iOS do celular, as três animações `body[data-nav="push"] ... {animation:entra-direita .32s cubic-bezier(.2,.8,.2,1)}`, `body[data-nav="pop"] ... {animation:entra-esquerda .32s cubic-bezier(.2,.8,.2,1)}` e `body[data-nav="aba"] ... {animation:fade .18s ease}` passam a `var(--mola-dur) var(--mola)` (a de aba também); a regra base `section.view{display:none;animation:fade .25s ease}` passa a `animation:fade var(--mola-dur) var(--mola)`.
- Grupos em qualquer largura: **mover** para fora do `@media screen and (max-width:899px)` do "conteúdo no padrão iOS" as regras `.panel,.card,.kpi{border-radius:14px;border:0;box-shadow:none}` e `.card.saldo,.card.saldo.saldo-abaixo{box-shadow:none}`; e mover para fora do `@media (max-width:899px)` "superfícies opacas" a regra `.card:not(.saldo),.panel,.notif-invite{background:var(--surface-solid)}` (e `.kpi{background:var(--surface-solid)}`), atualizando o comentário: "conteúdo é opaco em qualquer largura: vidro só na navegação".
- Chave de tema, perto das regras `.tgl-tema`:

```css
  /* no toque a bolinha vira uma lente de vidro que cresce (o controle "vira vidro enquanto você
     mexe", iOS 26) e volta com mola ao soltar */
  .tgl-tema .bola{transition:transform var(--mola-dur) var(--mola)}
  .tgl-tema:active .bola{transform:scale(1.2);background:var(--vidro);-webkit-backdrop-filter:var(--vidro-filtro);backdrop-filter:var(--vidro-filtro);box-shadow:var(--vidro-brilho),var(--vidro-sombra)}
  .tgl-tema.on:active .bola,html[data-theme="light"] #ajTema:active .bola{transform:translateX(32px) scale(1.2)}
```

  e remover `.tgl-tema .bola{...transition:transform .3s ease...}` duplicado (fica a transição nova) — o `@media (prefers-reduced-motion)` que zera essa transição pode sair, pois a duração já zera pelo token.

- [ ] **Step 3: Rodar**

Run: `npm run test:unit && npm run test:browser && (node tests/browser/servidor.cjs & sleep 1; node tests/browser/contraste.cjs /tmp; pkill -f tests/browser/servidor.cjs)`
Expected: verde.

- [ ] **Step 4: Commit**

```bash
git add styles.css tests/vidro.test.cjs tests/browser/vidro.cjs
git commit -m "feat: botões e busca em cápsula, toque com mola e chave de tema que vira vidro" -m "Os botões de ação e a busca ganham o formato de cápsula do iOS 26; todo botão encolhe na hora do toque e volta com mola, e a troca de tela passa a usar as molas. A bolinha da chave de tema vira uma lente de vidro enquanto é apertada. Os grupos de conteúdo do desktop perdem borda e sombra de site e ficam opacos como no celular, porque vidro é só da navegação."
```

---

### Task 9: Lateral do desktop flutuante no estilo macOS Tahoe

**Files:**
- Modify: `styles.css` (bloco "sidebar desktop")
- Modify: `tests/browser/vidro.cjs`

**Interfaces:**
- Consumes: `--vidro-folha`, `--vidro-filtro-forte`, `--vidro-brilho`, `--vidro-sombra`, `--lateral` (T5).
- Produces: `.side` flutuante; `--lateral:258px`.

- [ ] **Step 1: Teste que falha**

```js
    /* ---- desktop ---- */
    await teste('desktop: lateral flutua em vidro, a 10px das bordas', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      const s = await caixa(page, '.side');
      assert.ok(perto(s.left, 10) && perto(s.top, 10) && perto(s.bottom, 890), `lateral em ${JSON.stringify(s)}`);
      assert.equal(await estilo(page, '.side', 'borderTopLeftRadius'), '22px');
      assert.match(await estilo(page, '.side', 'backdropFilter'), /blur\(40px\)/);
      assert.ok((await caixa(page, '.app')).left >= s.right + 20, 'conteúdo encostado na lateral');
      assert.ok(parseFloat(await estilo(page, '.side button.on', 'borderTopLeftRadius')) >= 18, 'item selecionado não é cápsula');
      await ctx.close();
    });
```

Run → Expected: FALHA.

- [ ] **Step 2: CSS**

No bloco `@media (min-width:900px){` da sidebar:
- `:root{--lateral:248px}` → `:root{--lateral:258px}`.
- `.side{display:flex;position:fixed;left:0;top:0;bottom:0;width:224px;...;background:var(--side-bg);border-right:1px solid var(--border);backdrop-filter:blur(12px);z-index:30}` → trocar `left:0;top:0;bottom:0;` por `left:10px;top:10px;bottom:10px;`, `background:var(--side-bg);border-right:1px solid var(--border);backdrop-filter:blur(12px);` por `background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro-forte);backdrop-filter:var(--vidro-filtro-forte);box-shadow:var(--vidro-brilho),var(--vidro-sombra);border:0;border-radius:22px;` e acrescentar um comentário: `/* barra lateral do macOS Tahoe: painel de vidro flutuante; o material mais denso (--vidro-folha) marca a região estrutural */`.
- `.side button[data-tab]{...border-radius:11px...}` → `border-radius:999px`; `.side .s-sair{...border:1px solid var(--border);...border-radius:11px...}` → `border:0;...border-radius:999px` (sem vidro: já está dentro do vidro da lateral).

- [ ] **Step 3: Rodar**

Run: `npm run test:browser && (node tests/browser/servidor.cjs & sleep 1; node tests/browser/contraste.cjs /tmp; pkill -f tests/browser/servidor.cjs)`
Expected: verde.

- [ ] **Step 4: Commit**

```bash
git add styles.css tests/browser/vidro.cjs
git commit -m "feat: lateral do desktop flutuante em vidro, no estilo macOS Tahoe" -m "A barra lateral deixa de ser uma faixa colada na borda e vira um painel de vidro denso a 10px das bordas da janela, com o globo aparecendo desfocado através dela. Os itens viram cápsulas e o conteúdo se afasta para dar respiro."
```

---

### Task 10: Login e cadastro em vidro

**Files:**
- Modify: `styles.css` (`.auth-card`, `.auth-card.boost`, `.auth-inner`)
- Modify: `tests/vidro.test.cjs`, `tests/browser/vidro.cjs`

**Interfaces:**
- Consumes: tokens de vidro e mola.
- Produces: `.auth-card` de vidro, `.auth-inner` transparente.

- [ ] **Step 1: Testes que falham**

Em `tests/vidro.test.cjs`:

```js
test('login sem cores soltas: a moldura cinza fixa saiu', ()=>{
  const card = regras.find(r => r.sel === '.auth-card');
  assert.ok(card);
  assert.doesNotMatch(card.decl, /#6C6C6C|#222\b/i);
  assert.match(card.decl, /var\(--vidro-folha\)/);
});
```

Em `tests/browser/vidro.cjs`:

```js
    /* ---- login ---- */
    await teste('cartão do login é vidro sobre o globo', async ()=>{
      const { ctx, page } = await abrir(browser, { logado:false });
      assert.match(await estilo(page, '.auth-card', 'backdropFilter'), /blur\(40px\)/);
      assert.equal(await estilo(page, '.auth-card', 'borderTopWidth'), '0px');
      assert.equal(await estilo(page, '.auth-inner', 'backgroundColor'), 'rgba(0, 0, 0, 0)');
      await ctx.close();
    });
```

Run → Expected: FALHA.

- [ ] **Step 2: CSS**

- `.auth-card{width:100%;max-width:440px;border:4px solid #6C6C6C;background:#222;border-radius:30px;padding:9px;transform-origin:center top;will-change:transform;` + a linha do `box-shadow` com cinco sombras → substituir por:

```css
  /* cartão de entrada em vidro denso sobre o globo e o brilho (antes: moldura cinza fixa,
     fora das variáveis de tema) */
  .auth-card{width:100%;max-width:440px;border:0;border-radius:32px;padding:0;transform-origin:center top;will-change:transform;
    background:var(--vidro-folha);-webkit-backdrop-filter:var(--vidro-filtro-forte);backdrop-filter:var(--vidro-filtro-forte);
    box-shadow:var(--vidro-brilho),var(--vidro-sombra)}
```

- `.auth-card.boost,.auth-title.boost{transition:transform .45s cubic-bezier(.2,.8,.2,1),opacity .45s ease}` → `transition:transform var(--mola-dur) var(--mola),opacity .3s ease`.
- `.auth-inner{background:var(--surface-solid);border-radius:21px;padding:22px 20px 18px}` → `.auth-inner{background:transparent;border-radius:32px;padding:26px 22px 20px}`.

- [ ] **Step 3: Rodar**

Run: `npm run test:unit && npm run test:browser`
Expected: verde (inclui `cadastro.cjs` e `google.cjs`).

- [ ] **Step 4: Commit**

```bash
git add styles.css tests/vidro.test.cjs tests/browser/vidro.cjs
git commit -m "feat: login e cadastro em cartão de vidro" -m "O cartão da tela de entrada troca a moldura cinza de cor fixa pelo vidro denso do tema, com o globo e o brilho aparecendo desfocados atrás, e a animação de entrada passa a usar a mola padrão."
```

---

### Task 11: Guarda final do vidro, cache e documentação

**Files:**
- Modify: `tests/vidro.test.cjs`
- Modify: `sw.js` (`CACHE`)
- Modify: `CLAUDE.md` (seção UI)

**Interfaces:**
- Consumes: tudo das tarefas anteriores.

- [ ] **Step 1: Guarda da lista fechada**

Em `tests/vidro.test.cjs`:

```js
/* Vidro só na camada de navegação (spec, "Onde há vidro"): qualquer backdrop-filter que não
   seja "none" precisa estar num destes seletores. */
const PERMITIDOS = [
  /^nav\.tabs$/, /^\.fab$/, /^header\.top::before$/, /^\.nav-voltar$/, /^header\.top \.sair$/, /^header\.top \.sync-pill$/,
  /^\.sheet$/, /^\.conta-dialog$/, /^\.toast$/, /^\.valor-tela$/, /^\.auth-card$/, /^\.side$/, /^\.tgl-tema:active \.bola$/,
];
test('backdrop-filter só nos seletores da camada de navegação', ()=>{
  const fora = regras
    .filter(r => /(^|;|\s)backdrop-filter:\s*(?!none)/.test(r.decl))
    .flatMap(r => r.sel.split(',').map(s => s.trim()))
    .filter(s => !PERMITIDOS.some(p => p.test(s)));
  assert.deepEqual(fora, [], 'vidro em conteúdo ou vidro sobre vidro');
});
```

Run: `node --test tests/vidro.test.cjs`
Expected: PASS. Se falhar, o seletor listado ou é conteúdo (tire o vidro dele) ou é uma superfície do spec escrita com outro seletor (normalize o CSS para o seletor da lista, não afrouxe a lista).

- [ ] **Step 2: Cache offline**

Em `sw.js`, `const CACHE = 'obras-v54';` → `'obras-v55'` (ou o número seguinte ao atual). Run: `node --test tests/pwa.test.cjs` → PASS.

- [ ] **Step 3: CLAUDE.md**

Na seção `## UI`, depois do item sobre `styles.css`, acrescentar:

```markdown
- **Liquid Glass** (spec `docs/specs/2026-09-28-vidro-liquido-design.md`): vidro só na camada de navegação — cápsula de abas e botão +, itens da barra, lateral do desktop, sheets, diálogos, toasts, tela de valor e cartão do login. Conteúdo é opaco. Use os tokens `--vidro`, `--vidro-folha`, `--vidro-tinta`, `--vidro-brilho`, `--vidro-sombra` e `--vidro-filtro(-forte)`, definidos nos quatro combos; `tests/vidro.test.cjs` barra vidro fora da lista. Nenhum ancestral de um vidro pode ter `opacity` < 1, `filter`, `mask` ou `backdrop-filter` (vira raiz de fundo e o vidro deixa de ver a página).
- **Molas**: transições usam `var(--mola-dur) var(--mola)` (padrão, sem quique) ou `--mola-quique` (só depois de gesto com impulso). As curvas saem de `node scripts/molas.mjs`; mudar os parâmetros exige colar a saída nova no `@supports` das molas (`tests/molas.test.mjs` confere).
```

Na seção `## Fluxo de trabalho`, trocar "Commits em português, estilo `feat: `/`fix: `/`docs: `, minúsculas, sem acento no assunto." por "Commits em português, estilo `feat: `/`fix: `/`docs: `, minúsculas, com acentos no assunto e corpo em prosa quando a mudança não é trivial." (preferência atual do Giovani; `AGENTS.md` recebe a mesma troca na seção "Commits").

Run: `npm run test:unit` → PASS (`tests/docs.test.mjs` incluso).

- [ ] **Step 4: Commit**

```bash
git add tests/vidro.test.cjs sw.js CLAUDE.md AGENTS.md
git commit -m "docs: regras do Liquid Glass e das molas para quem mexer na interface" -m "A guarda nova barra vidro fora da camada de navegação, o cache offline sobe de versão para os aparelhos instalados pegarem o visual novo, e o CLAUDE.md passa a explicar onde o vidro pode entrar, a armadilha da raiz de fundo e como regenerar as molas."
```

---

### Task 12: Validação visual e de ponta a ponta

**Files:** nenhum arquivo de produto, salvo correções que a conferência revelar (cada correção em commit `fix:` próprio, com teste quando der).

- [ ] **Step 1: Suítes inteiras**

Run: `npm test && npm run test:browser`
Expected: exit 0 nos dois.

- [ ] **Step 2: Capturas locais com agent-browser**

Com `node tests/browser/servidor.cjs &` no ar e o init script de dados sintéticos (`/private/tmp/claude-501/-Users-giovanistuchi/c470fdcf-636f-4416-8d56-e4d9558e53ae/scratchpad/stub.js`), para cada combo (`mo_tema` escuro/claro × `mo_skin` esmeralda/azul) e para `set device "iPhone 16 Pro"` e `set viewport 1440 900`: capturar Obras, obra aberta rolada até o meio (esfumado de borda à vista), sheet de novo gasto, diálogo "Excluir este gasto?", Vale a pena?, Ajustes e login. Sessão própria: `export AGENT_BROWSER_SESSION=custta-vidro`.

- [ ] **Step 3: Conferência com a skill `apple-design`**

Olhar cada captura contra o spec e a skill: vidro só na navegação; nada de vidro sobre vidro; texto legível sobre o vidro; cápsula e + alinhados na base; lente na aba certa; sheet flutuante com 8px; lateral a 10px; nenhuma cor fora de tema; nada cortado a 390px. Toda falha vira `fix:` com teste e nova captura.

- [ ] **Step 4: Fechar**

`git log --format='%an <%ae>' main..HEAD | sort -u` → só `Giovani Stuchi <stuchigiovani@gmail.com>`. Nenhum `Co-Authored-By` em `git log main..HEAD`.
