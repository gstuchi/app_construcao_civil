# Dashboard da tela inicial + área m² — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tela inicial vira dashboard (4 KPIs, evolução geral agregada, donut por categoria, lançamentos recentes) + campo área m² com preço/m² na obra e no simulador.

**Architecture:** Funções puras novas em `calc.js`; `evoChartHtml/bindEvoChart` aceitam `opts.serie` pra série agregada; donut+legenda vira helper `donutComLegendaHtml` reusado pela tela Gráficos e pelo início; `renderInicio` reescrito montando os painéis; markup estático do `#v-inicio` vira containers preenchidos por JS.

**Tech Stack:** Vanilla JS + SVG, CSS do tema (sem Tailwind/fonte nova), testes Node, e2e puppeteer.

## Global Constraints

- KPIs: Total gasto (chip `N obras`), Corrigido (sub juros), A pagar 30 dias (chip âmbar `N vencimentos` / "nada a vencer"), Venda estimada (chip verde `N obras avaliadas` / "sem estimativas", "—" sem dado).
- Grid 2×2 mobile, 4 colunas ≥900px. Brilho radial no canto do cartão, cores do tema.
- Nada de dado inventado. Sem linha "previsto".
- `areaM2` número opcional no blob; obra antiga sem campo funciona igual.
- SW `obras-v10` → `obras-v11`.

### Task 1: calc.js — 4 funções (TDD)

Testes em `tests/calc.test.cjs` (append antes do log final):

```js
const obrasAgg = [
  { dataInicio:'2026-01-10', gastos:[{ valor:100000, data:'2026-01-15', topico:'terreno' }] },
  { dataInicio:'2026-02-01', venda:{ data:'2026-03-10', valor:1 },
    gastos:[{ valor:50000, data:'2026-02-05', topico:'pintura' }] },
];

t('serieEvolucaoAgregada: união de meses e soma', () => {
  const s = C.serieEvolucaoAgregada(obrasAgg, 1, '2026-04-20');
  assert.deepStrictEqual(s.map(p=>p.mes), ['2026-01','2026-02','2026-03','2026-04']);
  assert.strictEqual(s[0].bruto, 100000);
  assert.strictEqual(s[1].bruto, 150000);
  assert.ok(s[3].corrigido > s[3].bruto);
  // obra 2 vendida em mar: corrigido dela congela, mas o da obra 1 segue subindo
  assert.ok(s[3].corrigido > s[2].corrigido);
});

t('aPagar: janela de 30 dias', () => {
  const os = [{ dataInicio:'2026-07-01', gastos:[
    { valor:100, data:'2026-07-10' },  // +4d: dentro
    { valor:200, data:'2026-08-04' },  // +29d: dentro
    { valor:400, data:'2026-08-10' },  // +35d: fora
    { valor:800, data:'2026-07-01' },  // passado: fora
  ]}];
  assert.deepStrictEqual(C.aPagar(os, '2026-07-06'), { total:300, qtd:2 });
});

t('gastosRecentes: ordena e limita', () => {
  const os = [
    { id:'a', nome:'A', dataInicio:'2026-01-01', gastos:[{ id:'g1', valor:1, data:'2026-01-02' },{ id:'g3', valor:3, data:'2026-03-01' }] },
    { id:'b', nome:'B', dataInicio:'2026-01-01', gastos:[{ id:'g2', valor:2, data:'2026-02-01' }] },
  ];
  const r = C.gastosRecentes(os, 2);
  assert.deepStrictEqual(r.map(x=>x.gasto.id), ['g3','g2']);
  assert.strictEqual(r[0].obraNome, 'A');
});

t('precoPorM2', () => {
  assert.strictEqual(C.precoPorM2(3000000, 300), 10000);
  assert.strictEqual(C.precoPorM2(3000000, 0), null);
  assert.strictEqual(C.precoPorM2(3000000, null), null);
  assert.strictEqual(C.precoPorM2(0, 300), null);
});
```

Implementação (em `calc.js`, após `serieEvolucao`; exportar as 4):

```js
function serieEvolucaoAgregada(obras, taxaPct, hojeISO){
  const series = obras.map(o => serieEvolucao(o, taxaPct, hojeISO)).filter(s => s.length);
  if(!series.length) return [];
  const meses = [...new Set(series.flat().map(p => p.mes))].sort();
  return meses.map(mes => {
    let bruto = 0, corr = 0;
    series.forEach(s => {
      // acumulado da obra no mês: último ponto <= mes (antes do 1º ponto, 0)
      let p = null;
      for(const q of s){ if(q.mes <= mes) p = q; else break; }
      if(p){ bruto += p.bruto; corr += p.corrigido; }
    });
    return { mes, bruto, corrigido: corr };
  }).slice(-24);
}
function aPagar(obras, hojeISO, dias = 30){
  const fim = new Date(hojeISO + 'T00:00:00');
  fim.setDate(fim.getDate() + dias);
  const limISO = fim.toISOString().slice(0, 10);
  let total = 0, qtd = 0;
  obras.forEach(o => o.gastos.forEach(g => {
    if(g.data > hojeISO && g.data <= limISO){ total += g.valor; qtd++; }
  }));
  return { total, qtd };
}
function gastosRecentes(obras, n = 5){
  return obras
    .flatMap(o => o.gastos.map(g => ({ obraId: o.id, obraNome: o.nome, gasto: g })))
    .sort((a, b) => (b.gasto.data + b.gasto.id).localeCompare(a.gasto.data + a.gasto.id))
    .slice(0, n);
}
function precoPorM2(valor, areaM2){
  return (valor > 0 && areaM2 > 0) ? valor / areaM2 : null;
}
```

Nota fiel à obra vendida: `serieEvolucao` da obra vendida termina no mês da
venda; na agregada, o "último ponto ≤ mês" mantém o valor congelado dela nos
meses seguintes — comportamento desejado.

- [ ] Teste falha → implementa → `node tests/calc.test.cjs` verde → commit `feat: funcoes agregadas pro dashboard em calc.js`.

### Task 2: gráfico/donut reusáveis + markup/CSS do início

- `evoChartHtml(o, opts)`: trocar a linha da série por `const serie = opts.serie || OBRA_CALC.serieEvolucao(o, taxa(), todayISO());` e o título por `opts.titulo || 'Evolução da obra'`. `bindEvoChart(o, suf, rerender, serieOpt)`: usar `serieOpt || OBRA_CALC.serieEvolucao(...)`.
- Extrair de `renderGraficos` o helper `donutComLegendaHtml(entries, total, size)` (donut SVG + `<ul class="list graf-leg">`; `renderGraficos` passa 240, início passa 200). Sem `id` fixo dentro do helper.
- `index.html` `#v-inicio`: substituir o cartão "Total gasto nas obras" por `<div class="kpis" id="kpiRow"></div>`; após o painel "Minhas obras", containers `<div id="iniEvo"></div><div id="iniCat"></div><div id="iniRec"></div>` antes do `#panelComp`.
- CSS:

```css
.kpis{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:14px}
@media (min-width:900px){.kpis{grid-template-columns:repeat(4,1fr)}}
.kpi{position:relative;overflow:hidden;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:14px;box-shadow:var(--shadow)}
.kpi::after{content:"";position:absolute;right:-28px;top:-28px;width:110px;height:110px;border-radius:50%;background:radial-gradient(circle,rgba(91,140,255,.16),transparent 70%);pointer-events:none}
.kpi.amber::after{background:radial-gradient(circle,rgba(251,191,36,.14),transparent 70%)}
.kpi.green::after{background:radial-gradient(circle,rgba(74,222,128,.13),transparent 70%)}
.kpi .k-top{display:flex;justify-content:space-between;align-items:center;gap:6px}
.kpi .k-nome{font-size:12px;color:var(--muted);font-weight:600}
.kpi .k-num{font-size:20px;font-weight:750;font-variant-numeric:tabular-nums;margin-top:6px}
.kpi .k-obs{font-size:11px;color:var(--muted);margin-top:3px}
.chip2{font-size:10.5px;font-weight:650;padding:3px 8px;border-radius:999px;border:1px solid var(--border);color:var(--muted);white-space:nowrap}
.chip2.amber{color:var(--amber);border-color:rgba(251,191,36,.35);background:var(--amber-soft)}
.chip2.green{color:var(--green);border-color:rgba(74,222,128,.35);background:var(--green-soft)}
.chip2.brand{color:#9db9ff;border-color:rgba(91,140,255,.35);background:var(--brand-soft)}
```

- `sw.js` → `obras-v11`.
- [ ] Commit `feat: kpis, containers e helpers reusaveis do dashboard`.

### Task 3: renderInicio + área m² + preço/m²

- `renderInicio()` (substituir o miolo atual de KPI): montar `#kpiRow` com os 4 cartões (valores de `totalBruto/totalCorrigido` somados, `OBRA_CALC.aPagar(db.obras, todayISO())`, soma de `valorEstimadoVenda`); `#iniEvo` = `evoChartHtml(null,{sufixo:'A',serie:OBRA_CALC.serieEvolucaoAgregada(db.obras,taxa(),todayISO()),titulo:'Evolução geral'})` + `bindEvoChart(null,'A',renderInicio,serieAgg)`; `#iniCat` = painel "Gastos por categoria" com `donutComLegendaHtml(entriesAgregadas, totalBruto, 200)` (some quando sem gastos); `#iniRec` = painel "Lançamentos recentes" com `OBRA_CALC.gastosRecentes(db.obras,5)` (linha: `ICON(t.ic)` no `.av`, descrição/tópico, `obraNome · fmtData`, `-money`; `li.onclick=()=>openObra(obraId)`); vazio: painel some.
- `formNovaObra`/`formEditarObra`: campo `<div class="field"><label>Área construída (m²) (opcional)</label><input id="fArea" inputmode="decimal" value="${o?.areaM2||''}" autocomplete="off"></div>`; salvar `areaM2 = parseNum(...) > 0 ? ... : null`.
- Detalhe da obra, cartão "Venda estimada": sub `R$ X/m² · Y m²` quando `precoPorM2(o.valorEstimadoVenda, o.areaM2)` não-nulo (usar `moneyShort`).
- Simulador: no relatório da simulação, após "Rendimento ao mês", se `o.areaM2>0`: `<tr><td>Preço por m²</td><td>${money(venda/o.areaM2)}</td><td>${money(venda/o.areaM2)}</td></tr>`.
- [ ] Unit verdes → commit `feat: dashboard no inicio + area m2 e preco por m2`.

### Task 4: E2E + entrega

- [ ] E2E novo (padrão dos anteriores, viewport 390×844): conta nova → criar 2 obras (uma com área 300 e estimativa via editar) → gastos em ambas → início: 4 KPIs presentes (`A pagar`, `Venda estimada`), `Evolução geral`, donut agregado, recentes ≤5, toque em recente abre obra certa; obra com área: detalhe mostra `/m²`; simulador: digitar venda → linha "Preço por m²". Zero emoji.
- [ ] Regressões `smoke-fase2/evo/graf` verdes. Screenshots 390×844 e 1280×900 conferidos.
- [ ] Merge `dashboard-inicio` na main, push, monitor `obras-v11`. Avisar celular 2×.
