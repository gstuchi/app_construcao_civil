# Gráfico de evolução + respiro mobile + busca — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar as barras "Gasto mês a mês" por um gráfico de área suave (bruto × corrigido acumulados) com toque pra ver valor, dar respiro ao layout mobile e adicionar busca por texto/mês nos lançamentos.

**Architecture:** Dados do gráfico e filtro são funções puras em `calc.js` (Node-testáveis). `app.js` gera o SVG (curvas Catmull-Rom→Bézier, gradiente, grade tracejada) e liga os filtros re-renderizando só a lista. CSS de respiro é aditivo numa media query mobile.

**Tech Stack:** Vanilla JS + SVG inline, testes `node tests/calc.test.cjs`, e2e puppeteer-core + Edge headless.

## Global Constraints

- Sem lib de gráfico; SVG gerado à mão. LER a skill `dataviz` ANTES de escrever o código do gráfico (Task 2 Step 1).
- Curvas suaves, gradiente sob a série corrigida, 4 linhas de grade tracejadas com `moneyShort` à esquerda, meses `MESAB` embaixo, legenda pequena.
- Interação por toque (destaca mês, valor aparece acima do gráfico) — sem tooltip flutuante.
- Busca: sem acento/maiúscula (`normalize('NFD')` + strip), campo texto casa descrição OU nome do tópico; seletor de mês; filtros combinam em E; contador `achados/total`; filtro só em memória.
- Respiro: só CSS mobile (<768px); cores/fontes/identidade intocáveis.
- SW bump `obras-v6` → `obras-v7`.
- Janela do gráfico: máx. 24 meses mais recentes; gastos futuros (a vencer) ficam fora (série vai até hoje/venda).

---

### Task 0: Branch

- [ ] **Step 1:** `git checkout main && git checkout -b grafico-evolucao`

---

### Task 1: `calc.js` — `serieEvolucao` + `filtraGastos` (TDD)

**Files:**
- Modify: `calc.js` (2 funções novas + helper `semAcento`, exports no `api`)
- Test: `tests/calc.test.cjs` (append antes do `console.log` final)

**Interfaces:**
- Consumes: `corrigido(valor, dataISO, ateISO, taxaPct)`, `fimCorrecao(obra, hojeISO)` (já existem).
- Produces:
  - `OBRA_CALC.serieEvolucao(obra, taxaPct, hojeISO)` → `[{mes:'2026-06', bruto:Number, corrigido:Number}]`, um ponto por mês-calendário do 1º gasto até `fimCorrecao`, corte no fim de cada mês (ou em `fim` no último), meses sem gasto repetem acumulado; `[]` sem gastos; máx 24 últimos.
  - `OBRA_CALC.filtraGastos(gastos, topicosMap, {texto, mes})` → subarray; `topicosMap` é `{id:{nm}}`; `mes` formato `'2026-06'`.

- [ ] **Step 1: Testes que falham** — append em `tests/calc.test.cjs` antes do `console.log` final:

```js
const obraEvo = {
  dataInicio: '2026-01-10',
  gastos: [
    { valor: 100000, data: '2026-01-15', topico: 'terreno',  descricao: 'Sinal do terreno' },
    { valor:  50000, data: '2026-03-10', topico: 'pintura',  descricao: 'Tinta acrílica' },
  ],
};

t('serieEvolucao: um ponto por mês, acumulado certo', () => {
  const s = C.serieEvolucao(obraEvo, 1, '2026-04-20');
  assert.deepStrictEqual(s.map(p => p.mes), ['2026-01','2026-02','2026-03','2026-04']);
  assert.strictEqual(s[0].bruto, 100000);
  assert.strictEqual(s[1].bruto, 100000);          // fev sem gasto repete
  assert.strictEqual(s[2].bruto, 150000);
  assert.ok(s[1].corrigido > s[0].corrigido);      // corrigido segue rendendo
  s.forEach(p => assert.ok(p.corrigido >= p.bruto));
});

t('serieEvolucao: vendida congela no mês da venda', () => {
  const vend = { ...obraEvo, venda: { data: '2026-03-20', valor: 1 } };
  const s = C.serieEvolucao(vend, 1, '2026-12-25');
  assert.strictEqual(s[s.length-1].mes, '2026-03');
});

t('serieEvolucao: sem gastos = vazio; janela máx 24 meses', () => {
  assert.deepStrictEqual(C.serieEvolucao({ dataInicio:'2026-01-01', gastos:[] }, 1, '2026-06-01'), []);
  const antiga = { dataInicio:'2020-01-01', gastos:[{ valor:1000, data:'2020-01-05' }] };
  const s = C.serieEvolucao(antiga, 1, '2026-07-06');
  assert.strictEqual(s.length, 24);
  assert.strictEqual(s[s.length-1].mes, '2026-07');
});

const mapaTop = { terreno:{nm:'Terreno'}, pintura:{nm:'Pintura'} };

t('filtraGastos: texto acha descrição e tópico, sem acento', () => {
  const g = obraEvo.gastos;
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'tinta' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'PINTURA' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'acrilica' }).length, 1); // sem acento
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'piscina' }).length, 0);
});

t('filtraGastos: mês, combinado e vazio', () => {
  const g = obraEvo.gastos;
  assert.strictEqual(C.filtraGastos(g, mapaTop, { mes:'2026-01' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'terreno', mes:'2026-03' }).length, 0);
  assert.strictEqual(C.filtraGastos(g, mapaTop, {}).length, 2);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto:'' }).length, 2);
});
```

- [ ] **Step 2:** `node tests/calc.test.cjs` → FALHA (`C.serieEvolucao is not a function`).

- [ ] **Step 3: Implementar** — em `calc.js`, após `resumoVenda`:

```js
/* Série mensal acumulada da obra (pro gráfico de evolução):
   um ponto por mês-calendário, do 1º gasto até o fim da correção
   (hoje ou a venda), cortando no fim de cada mês. Máx 24 últimos. */
function serieEvolucao(obra, taxaPct, hojeISO){
  if(!obra.gastos.length) return [];
  const fim = fimCorrecao(obra, hojeISO);
  const gs = [...obra.gastos].sort((a, b) => a.data.localeCompare(b.data));
  const ini = gs[0].data.slice(0, 7);
  const ultimo = fim.slice(0, 7) > ini ? fim.slice(0, 7) : ini;
  const meses = [];
  let [y, m] = ini.split('-').map(Number);
  for(let guard = 0; guard < 600; guard++){
    const key = y + '-' + String(m).padStart(2, '0');
    meses.push(key);
    if(key === ultimo) break;
    m++; if(m > 12){ m = 1; y++; }
  }
  return meses.map(mes => {
    const ultimoDia = new Date(Number(mes.slice(0, 4)), Number(mes.slice(5, 7)), 0).getDate();
    let corte = mes + '-' + String(ultimoDia).padStart(2, '0');
    if(corte > fim) corte = fim;
    const ate = gs.filter(g => g.data <= corte);
    return {
      mes,
      bruto: ate.reduce((s, g) => s + g.valor, 0),
      corrigido: ate.reduce((s, g) => s + corrigido(g.valor, g.data, corte, taxaPct), 0),
    };
  }).slice(-24);
}

/* Busca dos lançamentos: texto (descrição OU nome do tópico, sem acento)
   e/ou mês ('2026-06'). Filtros combinam em E. */
function semAcento(s){
  return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}
function filtraGastos(gastos, topicosMap, f){
  const texto = semAcento(f && f.texto);
  const mes = (f && f.mes) || '';
  return gastos.filter(g => {
    if(mes && g.data.slice(0, 7) !== mes) return false;
    if(!texto) return true;
    const top = topicosMap[g.topico];
    return semAcento(g.descricao).includes(texto)
        || semAcento(top ? top.nm : g.topico).includes(texto);
  });
}
```

E no `api`, adicionar: `serieEvolucao, filtraGastos, semAcento`.

- [ ] **Step 4:** `node tests/calc.test.cjs` → verde (21+5 testes).

- [ ] **Step 5:** Commit: `git add calc.js tests/calc.test.cjs && git commit -m "feat: serieEvolucao e filtraGastos em calc.js"`.

---

### Task 2: Gráfico de evolução em `app.js`

**Files:**
- Modify: `app.js` — substituir `mbarsHtml` (linhas ~290-303) e o painel "Gasto mês a mês" em `renderObra` (~linha 239); handlers pós-`innerHTML` (~246-252)
- Modify: `index.html` — CSS do gráfico no `<style>`

**Interfaces:**
- Consumes: `OBRA_CALC.serieEvolucao(o, taxa(), todayISO())` (Task 1), `moneyShort`, `MESAB`, `emptyBlock`, `ICON('calendario')`.
- Produces: `evoChartHtml(o)` → string do painel; `bindEvoChart(o)` → liga cliques (chamado depois do `innerHTML` em `renderObra`).

- [ ] **Step 1: LER a skill `dataviz`** (obrigatório antes do código do gráfico) e conferir as duas cores de série contra as regras dela. Ponto de partida: corrigido = `--brand` #5b8cff (área+linha), bruto = `--c2` #22d3ee (linha). Ajustar se a skill mandar.

- [ ] **Step 2: CSS** — em `index.html`, junto do CSS de gráficos:

```css
.evo-head{display:flex;justify-content:space-between;align-items:baseline;gap:8px;min-height:22px}
.evo-val{font-size:13px;color:var(--text);font-variant-numeric:tabular-nums}
.evo-leg{display:flex;gap:14px;margin-top:6px;font-size:12px;color:var(--muted)}
.evo-leg i{width:10px;height:3px;border-radius:2px;display:inline-block;vertical-align:middle;margin-right:5px}
.evo-svg text{font-size:9px;fill:var(--muted)}
.evo-col{cursor:pointer}
```

- [ ] **Step 3: Substituir `mbarsHtml` por `evoChartHtml` + `bindEvoChart`** em `app.js` (remover `mbarsHtml` inteiro):

```js
/* Gráfico de evolução: área suave do acumulado corrigido + linha do bruto.
   Toque num mês mostra os valores no topo (sem tooltip flutuante). */
let evoSel = -1; // mês selecionado (índice); -1 = último
function smoothPath(pts){
  if(pts.length < 2) return pts.length ? `M${pts[0].x} ${pts[0].y} L${pts[0].x+1} ${pts[0].y}` : '';
  let d = `M${pts[0].x} ${pts[0].y}`;
  for(let i = 0; i < pts.length - 1; i++){
    const p0 = pts[i-1] || pts[i], p1 = pts[i], p2 = pts[i+1], p3 = pts[i+2] || p2;
    d += ` C${(p1.x+(p2.x-p0.x)/6).toFixed(1)} ${(p1.y+(p2.y-p0.y)/6).toFixed(1)}`
       + ` ${(p2.x-(p3.x-p1.x)/6).toFixed(1)} ${(p2.y-(p3.y-p1.y)/6).toFixed(1)}`
       + ` ${p2.x} ${p2.y}`;
  }
  return d;
}
function evoChartHtml(o){
  const serie = OBRA_CALC.serieEvolucao(o, taxa(), todayISO());
  if(!serie.length) return `<div class="panel"><h2>Evolução da obra</h2>${emptyBlock(ICON('calendario'),'Sem gastos ainda.')}</div>`;
  const W = 360, H = 170, L = 44, R = 6, T = 12, B = 22;
  const max = Math.max(...serie.map(p => p.corrigido)) * 1.08 || 1;
  const x = i => serie.length === 1 ? (L+W-R)/2 : L + (W-L-R) * i / (serie.length-1);
  const y = v => T + (H-T-B) * (1 - v/max);
  const pc = serie.map((p,i) => ({x:+x(i).toFixed(1), y:+y(p.corrigido).toFixed(1)}));
  const pb = serie.map((p,i) => ({x:+x(i).toFixed(1), y:+y(p.bruto).toFixed(1)}));
  const grade = [0.25,0.5,0.75,1].map(f => {
    const gy = y(max*f).toFixed(1);
    return `<line x1="${L}" y1="${gy}" x2="${W-R}" y2="${gy}" stroke="var(--border)" stroke-dasharray="3 4"/>
            <text x="${L-4}" y="${+gy+3}" text-anchor="end">${moneyShort(max*f)}</text>`;
  }).join('');
  const passo = Math.ceil(serie.length / 8); // no máx ~8 rótulos de mês
  const rotulos = serie.map((p,i) => (i % passo && i !== serie.length-1) ? '' :
    `<text x="${x(i).toFixed(1)}" y="${H-6}" text-anchor="middle">${MESAB[+p.mes.slice(5)-1]}</text>`).join('');
  const cols = serie.map((p,i) => {
    const x0 = i ? (x(i-1)+x(i))/2 : L, x1 = i < serie.length-1 ? (x(i)+x(i+1))/2 : W-R;
    return `<rect class="evo-col" data-i="${i}" x="${x0.toFixed(1)}" y="${T}" width="${(x1-x0).toFixed(1)}" height="${H-T-B}" fill="transparent"/>`;
  }).join('');
  const sel = evoSel >= 0 && evoSel < serie.length ? evoSel : serie.length-1;
  const marca = `<circle cx="${pc[sel].x}" cy="${pc[sel].y}" r="3.5" fill="var(--brand)"/>
                 <circle cx="${pb[sel].x}" cy="${pb[sel].y}" r="3" fill="var(--c2)"/>`;
  return `
    <div class="panel"><h2>Evolução da obra</h2>
      <div class="evo-head"><span class="evo-val" id="evoVal"></span></div>
      <svg class="evo-svg" viewBox="0 0 ${W} ${H}" width="100%" id="evoSvg" role="img" aria-label="Evolução do gasto bruto e corrigido por mês">
        <defs><linearGradient id="evoGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="var(--brand)" stop-opacity=".38"/>
          <stop offset="100%" stop-color="var(--brand)" stop-opacity=".02"/>
        </linearGradient></defs>
        ${grade}
        <path d="${smoothPath(pc)} L ${W-R} ${H-B} L ${L} ${H-B} Z" fill="url(#evoGrad)" stroke="none"/>
        <path d="${smoothPath(pc)}" fill="none" stroke="var(--brand)" stroke-width="2.4" stroke-linecap="round"/>
        <path d="${smoothPath(pb)}" fill="none" stroke="var(--c2)" stroke-width="2" stroke-linecap="round"/>
        ${marca}${rotulos}${cols}
      </svg>
      <div class="evo-leg">
        <span><i style="background:var(--c2)"></i>Gasto</span>
        <span><i style="background:var(--brand)"></i>Corrigido pelo banco</span>
      </div>
    </div>`;
}
function bindEvoChart(o){
  const svg = $('#evoSvg');
  if(!svg) return;
  const serie = OBRA_CALC.serieEvolucao(o, taxa(), todayISO());
  const mostra = i => {
    const p = serie[i]; if(!p) return;
    const [yy, mm] = p.mes.split('-');
    $('#evoVal').textContent =
      `${MESAB[+mm-1]}/${yy.slice(2)} · gasto ${moneyShort(p.bruto)} · corrigido ${moneyShort(p.corrigido)}`;
  };
  svg.querySelectorAll('.evo-col').forEach(r => r.onclick = () => {
    evoSel = +r.dataset.i;
    renderObra(); // re-render marca o ponto; evoVal preenchido abaixo
  });
  mostra(evoSel >= 0 && evoSel < serie.length ? evoSel : serie.length-1);
}
```

- [ ] **Step 4: Ligar em `renderObra`** — trocar a linha do painel antigo:

```js
// antes:
    <div class="panel"><h2>Gasto mês a mês</h2>${mbarsHtml(o)}</div>`;
// depois:
    ${evoChartHtml(o)}`;
```

E depois do `$('#obraBody').innerHTML = ...` (junto de `drawDonutObra`), chamar `bindEvoChart(o);`. Em `openObra(id)`, resetar `evoSel = -1;`.

- [ ] **Step 5: Conferir no navegador** — `npx -y http-server -p 8123 . -s` + Edge headless, obra com gastos em 2+ meses: curvas suaves, gradiente, grade legível, toque muda o valor no topo. Screenshots **390×844 (mobile)** e 1280×900. Ajustar T/B/L se cortar texto.

- [ ] **Step 6:** `node tests/calc.test.cjs` verde. Commit: `git add app.js index.html && git commit -m "feat: grafico de evolucao bruto x corrigido com area suave"`.

---

### Task 3: Respiro mobile + busca nos lançamentos

**Files:**
- Modify: `index.html` — CSS (media query mobile + `.filter-row`)
- Modify: `app.js` — bloco `lanc` em `renderObra` (~241-244), listagem (~249-252), estado do filtro, `openObra`
- Modify: `sw.js:2` — `obras-v7`

**Interfaces:**
- Consumes: `OBRA_CALC.filtraGastos(gastos, TOP_MAP(), {texto, mes})` (Task 1), `gastoRow(o, g)`, `MESAB`.
- Produces: `renderGastosFiltrados(o)` — repinta só a lista + contador (não perde foco do teclado).

- [ ] **Step 1: CSS** — em `index.html`:

```css
.filter-row{display:flex;gap:8px;margin-bottom:12px}
.filter-row input,.filter-row select{background:var(--surface-2);border:1px solid var(--border);color:var(--text);border-radius:10px;padding:9px 11px;font-size:14px}
.filter-row input{flex:1;min-width:0}
.filter-row select{flex:0 0 auto;max-width:44%}
@media (max-width:768px){
  ul.list li{padding:14px 4px;gap:13px}
  .li-del{padding:10px 12px;font-size:18px}
  .panel{margin-bottom:14px}
  .cards{gap:12px}
}
```

(Se `.panel`/`.cards` já tiverem margens/gaps definidos, os valores acima só valem no mobile e podem precisar de ajuste fino no screenshot do Step 4.)

- [ ] **Step 2: Estado + template** — em `app.js`, perto de `obraAberta`: `let filtroTexto = '', filtroMes = '';`. Em `openObra(id)`: `filtroTexto = ''; filtroMes = '';`. No `renderObra`, trocar o bloco `lanc`:

```js
  const mesesComGasto = [...new Set(o.gastos.map(g => g.data.slice(0,7)))].sort().reverse();
  const lanc = `
    <div class="panel"><h2>Lançamentos <span class="muted" id="lanCount"></span></h2>
      <div class="filter-row">
        <input id="fBusca" placeholder="Pesquisar gasto ou tópico" autocomplete="off" value="${escapeHtml(filtroTexto)}">
        <select id="fMes"><option value="">Todos os meses</option>
          ${mesesComGasto.map(m => `<option value="${m}"${m===filtroMes?' selected':''}>${MESAB[+m.slice(5)-1]}/${m.slice(2,4)}</option>`).join('')}
        </select>
      </div>
      <ul class="list" id="oGastos"></ul>
    </div>`;
```

- [ ] **Step 3: Listagem filtrada** — substituir o trecho que enche `#oGastos` em `renderObra` por chamada a:

```js
function renderGastosFiltrados(o){
  const list = $('#oGastos');
  const filtrados = OBRA_CALC.filtraGastos(o.gastos, TOP_MAP(), { texto: filtroTexto, mes: filtroMes });
  const filtrando = !!(filtroTexto || filtroMes);
  $('#lanCount').textContent = o.gastos.length ? (filtrando ? `${filtrados.length}/${o.gastos.length}` : o.gastos.length) : '';
  list.innerHTML = '';
  if(!o.gastos.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro.'); return; }
  if(!filtrados.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nada encontrado com esse filtro.'); return; }
  [...filtrados].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id))
    .forEach(g => list.appendChild(gastoRow(o, g)));
}
```

E os listeners depois do `innerHTML` de `renderObra`:

```js
  $('#fBusca').addEventListener('input', ()=>{ filtroTexto = $('#fBusca').value; renderGastosFiltrados(obraById(obraAberta)); });
  $('#fMes').onchange = ()=>{ filtroMes = $('#fMes').value; renderGastosFiltrados(obraById(obraAberta)); };
  renderGastosFiltrados(o);
```

(Remover as linhas antigas `list.innerHTML = o.gastos.length ? ...` e o `forEach` que vinha depois.)

- [ ] **Step 4: `sw.js`** — `const CACHE = 'obras-v7';`. Conferir no navegador (mobile 390×844): busca digitando "tinta" filtra na hora sem perder o foco, seletor de mês filtra, contador `n/total`, respiro visível. Screenshot.

- [ ] **Step 5:** Commit: `git add app.js index.html sw.js && git commit -m "feat: busca nos lancamentos + respiro mobile"`.

---

### Task 4: E2E + entrega

- [ ] **Step 1: E2E** (script no `%TEMP%\smoke-obras`, padrão dos anteriores — viewport 390×844, cliques via `$eval(el=>el.click())`, `waitForSelector('#v-*.active')` antes de ler texto): criar conta+obra, lançar 2 gastos com datas em meses diferentes (editar a data no formulário), então:
  - `#evoSvg` existe e tem 3 `path` (área + 2 linhas); `#evoVal` contém "corrigido";
  - clicar numa `.evo-col` muda `#evoVal`;
  - digitar "xyz" em `#fBusca` → lista mostra "Nada encontrado"; digitar descrição real → 1 item e contador `1/2`;
  - `#fMes` com opção de 2 meses; escolher um → filtra;
  - varredura de emoji continua zero;
  - limpeza da conta via REST.
- [ ] **Step 2:** Rodar → `TUDO PASSOU`. Unit: `node tests/calc.test.cjs && node tests/moeda.test.cjs && node tests/icons.test.cjs` verdes.
- [ ] **Step 3:** `git checkout main && git merge --no-ff grafico-evolucao -m "merge: grafico de evolucao + busca nos lancamentos (branch grafico-evolucao)" && git push`. Conferir `obras-v7` em produção (curl no `sw.js`). Avisar: celular fecha/abre 2×.
