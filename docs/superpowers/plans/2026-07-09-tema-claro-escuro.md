# Tema claro/escuro Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modo claro opcional com toggle pílula animado (lua/sol) na tela Ajustes; escuro continua padrão.

**Architecture:** Todas as cores já vivem em CSS variables no `:root` de `index.html`; o tema claro é um bloco `html[data-theme="light"]` que as sobrescreve. Script inline no `<head>` aplica o tema salvo antes da pintura. Gráficos leem cores via `getComputedStyle`, então basta `renderAll()` após a troca.

**Tech Stack:** HTML/CSS/JS vanilla, sem build, sem dependência nova. Spec: `docs/superpowers/specs/2026-07-09-tema-claro-escuro-design.md`.

## Global Constraints

- Offline é sagrado: nenhum framework, CDN ou build (PRODUCT.md princípio 5).
- Chave localStorage: `mo_tema`, valores `claro`/`escuro`; ausente/ inválido = escuro. NÃO sincroniza com Firebase.
- Contraste AA: texto normal ≥4.5:1, números grandes/ícones ≥3:1, nos dois temas.
- Alvo de toque ≥44px; `prefers-reduced-motion` desliga animação da bolinha.
- Copy em PT-BR: painel "Aparência", label "Tema".

---

### Task 1: Paleta clara + script anti-flash

**Files:**
- Modify: `index.html:6` (meta theme-color — só referência, muda via JS na Task 4)
- Modify: `index.html:19-21` (script inline antes do `<style>`)
- Modify: `index.html:33` (bloco light após o `:root`)
- Modify: `index.html:36-47` (override do gradiente do body e opacidade do globo)

**Interfaces:**
- Produces: atributo `data-theme="light"` no `<html>` ativa o tema claro inteiro; ausência = escuro. Tasks 3 e 4 dependem desse contrato.

- [ ] **Step 1: Script anti-flash no head**

Em `index.html`, logo ANTES da linha `<style>` (linha 20), inserir:

```html
<script>
/* aplica tema salvo antes da pintura — evita flash do tema errado */
try{ if(localStorage.getItem('mo_tema')==='claro') document.documentElement.setAttribute('data-theme','light'); }catch(e){}
</script>
```

- [ ] **Step 2: Bloco de variáveis do tema claro**

Logo após o fechamento do `:root{...}` (linha 33), inserir:

```css
  /* Tema claro — mesmo esqueleto de variáveis, valores validados p/ contraste AA */
  html[data-theme="light"]{
    --bg:#eef2f9;
    --surface:rgba(255,255,255,.92); --surface-solid:#ffffff; --surface-2:#e7edf7; --border:#cdd8e8;
    --text:#16233c; --muted:#556685; --brand:#3560cf; --brand-soft:#dde7fb;
    --green:#0e7a41; --green-soft:#d7f2e2; --red:#c22e55; --red-soft:#fadde5;
    --amber:#8a5a06; --amber-soft:#f8ecc9; --blue:#2a63c4; --blue-soft:#dce9fa;
    --shadow:0 1px 2px rgba(23,43,77,.08),0 8px 24px rgba(23,43,77,.12);
    --c1:#3560cf; --c2:#0d7f95; --c3:#6d4fc9; --c4:#c23d82; --c5:#8a5a06; --c6:#0e7a41; --c7:#b04e0c; --c8:#5c6b80;
    --chart-rec:#187a44; --chart-desp:#c22759;
  }
```

Atualizar o comentário da linha 21 de `/* Tema único: dark premium (decisão de identidade — PRODUCT.md) */` para `/* Dark é o padrão; claro é opção (PRODUCT.md) — variáveis do claro em html[data-theme=light] */`.

- [ ] **Step 3: Override do fundo do body e do globo**

Após a regra `#globe{...}` (linha 47), inserir:

```css
  html[data-theme="light"] body{
    background:
      radial-gradient(1100px 750px at 85% -5%, rgba(91,140,255,.14), transparent 62%),
      radial-gradient(900px 700px at -10% 105%, rgba(140,90,220,.09), transparent 60%),
      var(--bg);
    background-attachment:fixed;
  }
  html[data-theme="light"] #globe{opacity:.4} /* globo é azul fixo (globe.js); no claro vira marca-d'água */
```

- [ ] **Step 4: Validar contraste com script**

Criar `C:\Users\User\AppData\Local\Temp\claude\...\scratchpad\contraste.js` (scratchpad, não commitar):

```js
// WCAG contrast checker — pares críticos do tema claro
const lin = c => { c/=255; return c<=0.03928 ? c/12.92 : ((c+0.055)/1.055)**2.4; };
const lum = hex => { const n=parseInt(hex.slice(1),16);
  return 0.2126*lin(n>>16&255)+0.7152*lin(n>>8&255)+0.0722*lin(n&255); };
const ratio = (a,b)=>{const[l1,l2]=[lum(a),lum(b)].sort((x,y)=>y-x);return (l1+0.05)/(l2+0.05);};
const pares = [ // [fg, bg, mínimo, descrição]
  ['#16233c','#eef2f9',4.5,'text/bg'], ['#16233c','#ffffff',4.5,'text/surface'],
  ['#556685','#eef2f9',4.5,'muted/bg'], ['#556685','#ffffff',4.5,'muted/surface'],
  ['#0e7a41','#eef2f9',3,'green num/bg'], ['#c22e55','#eef2f9',3,'red num/bg'],
  ['#0e7a41','#d7f2e2',3,'green/green-soft'], ['#c22e55','#fadde5',3,'red/red-soft'],
  ['#8a5a06','#f8ecc9',3,'amber/amber-soft'], ['#2a63c4','#dce9fa',3,'blue/blue-soft'],
  ['#3560cf','#dde7fb',3,'brand/brand-soft'],
  ['#187a44','#ffffff',3,'chart-rec/surface'], ['#c22759','#ffffff',3,'chart-desp/surface'],
];
let falhou = false;
for(const [fg,bg,min,nome] of pares){
  const r = ratio(fg,bg);
  const ok = r >= min;
  if(!ok) falhou = true;
  console.log(`${ok?'OK  ':'FAIL'} ${nome}: ${r.toFixed(2)} (min ${min})`);
}
process.exit(falhou?1:0);
```

Run: `node <scratchpad>\contraste.js`
Expected: todas as linhas `OK`, exit 0. Se alguma falhar, escurecer o foreground do par até passar e atualizar o mesmo valor no bloco light do `index.html`.

- [ ] **Step 5: Checagem visual rápida**

Abrir `index.html` no browser, no console: `document.documentElement.setAttribute('data-theme','light')`.
Expected: fundo claro, cards brancos, texto escuro legível, sem área ilegível. (Gráficos ainda com cores antigas até re-render — esperado, resolve na Task 4.)

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "feat: paleta do tema claro + script anti-flash no head"
```

---

### Task 2: Ícones lua e sol

**Files:**
- Modify: `icons.js:6-46` (objeto `ICONES`)

**Interfaces:**
- Produces: `ICON('lua')` e `ICON('sol')` retornam SVG string (mesmo contrato dos demais ícones). Task 4 usa.

- [ ] **Step 1: Adicionar os dois paths**

No objeto `ICONES` (após `olhoFechado`, linha 45), adicionar:

```js
    lua:        '<path d="M12 3a6.5 6.5 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
    sol:        '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/>',
```

- [ ] **Step 2: Verificar no Node (icons.js exporta p/ testes)**

Run: `node -e "const {ICON}=require('./icons.js'); console.log(ICON('lua').includes('path')&&ICON('sol').includes('circle')?'OK':'FAIL')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add icons.js
git commit -m "feat: icones lua e sol para o toggle de tema"
```

---

### Task 3: Painel Aparência + CSS do toggle pílula

**Files:**
- Modify: `index.html:554-555` (novo painel antes do painel "Conta")
- Modify: `index.html` seção `<style>` (CSS do toggle, junto das regras de `.panel`)

**Interfaces:**
- Consumes: variáveis dos dois temas (Task 1).
- Produces: botão `#ajTema` com `role="switch"`, filho `.bola` (recebe ícone via JS). Task 4 liga o comportamento.

- [ ] **Step 1: HTML do painel**

Em `index.html`, entre o painel "Meus tópicos" (fecha na linha 554) e o painel "Conta" (linha 555), inserir:

```html
    <div class="panel">
      <h2>Aparência</h2>
      <div class="tema-linha">
        <span>Tema do app</span>
        <button class="tgl-tema" id="ajTema" role="switch" aria-checked="false" aria-label="Modo claro">
          <span class="slot esq" data-ico="lua"></span>
          <span class="slot dir" data-ico="sol"></span>
          <span class="bola"></span>
        </button>
      </div>
      <p class="muted-note">Escuro é o padrão. A escolha vale só neste aparelho.</p>
    </div>
```

- [ ] **Step 2: CSS do toggle**

No `<style>`, após as regras de `.panel h2 .muted` (linha 77), inserir:

```css
  /* toggle de tema — pílula lua/sol */
  .tema-linha{display:flex;align-items:center;justify-content:space-between;min-height:44px;font-size:15px}
  .tgl-tema{position:relative;width:64px;height:32px;border-radius:999px;border:1px solid var(--border);
    background:var(--surface-2);cursor:pointer;padding:0;flex:none}
  .tgl-tema::before{content:"";position:absolute;inset:-8px} /* alvo de toque ≥44px */
  .tgl-tema .slot{position:absolute;top:3px;width:24px;height:24px;display:grid;place-items:center;
    color:var(--muted);opacity:.5}
  .tgl-tema .slot.esq{left:4px} .tgl-tema .slot.dir{right:4px}
  .tgl-tema .bola{position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;
    background:var(--surface-solid);border:1px solid var(--border);display:grid;place-items:center;
    color:var(--text);transition:transform .3s ease;z-index:1}
  html[data-theme="light"] .tgl-tema .bola{transform:translateX(32px)}
  .tgl-tema svg.ico{width:15px;height:15px}
  .tgl-tema:focus-visible{outline:2px solid var(--brand);outline-offset:2px}
  @media (prefers-reduced-motion: reduce){ .tgl-tema .bola{transition:none} }
```

- [ ] **Step 3: Checagem visual**

Abrir no browser, aba Ajustes: pílula com lua/sol esmaecidos e bolinha à esquerda (ícone da bolinha só aparece na Task 4). Alternar `data-theme` no console: bolinha desliza pra direita.

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: painel Aparencia com toggle pilula na tela Ajustes"
```

---

### Task 4: Lógica de troca (app.js)

**Files:**
- Modify: `app.js:873+` (`renderAjustes`) e nova seção TEMA logo acima dela

**Interfaces:**
- Consumes: `#ajTema`/`.bola` (Task 3), `ICON('lua'|'sol')` (Task 2), `data-theme` (Task 1), `renderAll()` existente (`app.js:114`).
- Produces: `aplicaTema(claro:boolean)` — aplica atributo, persiste `mo_tema`, atualiza `<meta theme-color>` e chama `renderAll()`.

- [ ] **Step 1: Funções de tema**

Em `app.js`, imediatamente antes de `/* ===== AJUSTES ===== */` (linha 873), inserir:

```js
/* ===== TEMA (claro/escuro) — preferência por aparelho, não sincroniza ===== */
const TEMA_KEY = 'mo_tema';
const temaClaro = () => document.documentElement.getAttribute('data-theme') === 'light';
function aplicaTema(claro){
  if(claro) document.documentElement.setAttribute('data-theme','light');
  else document.documentElement.removeAttribute('data-theme');
  try{ localStorage.setItem(TEMA_KEY, claro ? 'claro' : 'escuro'); }catch(e){}
  const meta = document.querySelector('meta[name="theme-color"]');
  if(meta) meta.content = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim();
  renderAll(); // gráficos leem cor via getComputedStyle — precisam redesenhar
}
```

- [ ] **Step 2: Estado + clique dentro de renderAjustes**

No início do corpo de `renderAjustes()` (linha 874), inserir:

```js
  const tg = $('#ajTema');
  if(tg){
    const claro = temaClaro();
    tg.setAttribute('aria-checked', String(claro));
    tg.setAttribute('aria-label', claro ? 'Modo escuro' : 'Modo claro');
    tg.querySelector('.bola').innerHTML = ICON(claro ? 'sol' : 'lua');
    tg.onclick = () => aplicaTema(!temaClaro());
  }
```

(`onclick` é idempotente em re-render; `<button>` já dá Enter/Espaço de graça.)

- [ ] **Step 3: Verificar no browser**

Abrir app, Ajustes, clicar no toggle. Expected:
- bolinha desliza, ícone vira sol, página inteira clareia;
- donuts e gráfico de evolução redesenham com as cores do bloco light;
- reload mantém claro, sem flash escuro no load;
- `document.querySelector('meta[name=theme-color]').content` → `#eef2f9`;
- clicar de novo volta pro escuro e persiste.

- [ ] **Step 4: Commit**

```bash
git add app.js
git commit -m "feat: troca de tema com persistencia local e re-render dos graficos"
```

---

### Task 5: PRODUCT.md + bump do service worker

**Files:**
- Modify: `PRODUCT.md:29` (princípio 4)
- Modify: `sw.js:3` (versão do cache)

- [ ] **Step 1: Atualizar princípio 4**

Trocar a linha 29 de `PRODUCT.md`:

```markdown
4. **Dark é o padrão** — dark premium é a assinatura e o tema inicial; modo claro existe como opção nos Ajustes, com o mesmo rigor de contraste e hierarquia.
```

- [ ] **Step 2: Bump do cache**

Em `sw.js:3`: `const CACHE = 'obras-v19';` → `const CACHE = 'obras-v20';`

- [ ] **Step 3: Commit**

```bash
git add PRODUCT.md sw.js
git commit -m "docs: dark vira padrao (nao mais unico); bump sw v20"
```

---

### Task 6: Verificação final

- [ ] **Step 1: Fluxo completo no browser**

Servir localmente (`npx serve .` ou abrir direto) e conferir:
1. Primeira visita (localStorage limpo): abre escuro, idêntico a antes.
2. Toggle → claro: todas as telas (Obras, detalhe da obra, Gráficos, Vale a pena?, Ajustes) legíveis; chips soft, tags e donut com contraste.
3. Reload em claro: sem flash escuro.
4. Splash e login respeitam o tema salvo (se splash tiver cor hardcoded escura, ok — momento de marca; anotar no spec se for o caso).
5. `prefers-reduced-motion` (emular no devtools): bolinha troca sem animar.
6. Modal/sheet e FAB no tema claro: legíveis.

- [ ] **Step 2: Rodar /verify se aplicável e fechar branch**

Merge/finalização conforme fluxo do repo (branch curta + merge em main, padrão dos commits anteriores).
