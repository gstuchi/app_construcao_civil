# Tela "Gráficos da obra" — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** View dedicada com donut grande + lista completa por tópico + evolução grande + botão de PDF; barra de abas sólida.

**Architecture:** Nova seção `#v-graficos` renderizada por `renderGraficos()` em `app.js`; `evoChartHtml`/`bindEvoChart` parametrizados por sufixo/altura pra reuso. Sem mudança em `calc.js`.

**Tech Stack:** Vanilla JS + SVG, e2e puppeteer.

## Global Constraints

- Lista de tópicos: nome completo sem truncar, bolinha na cor do donut (mesma ordem/cores `PIE`), % arredondado + `moneyShort`.
- Evolução grande: `H=300`, textos ~11px, toque no mês funciona (ids com sufixo `G`).
- `nav.tabs`: `background:var(--surface-solid)` sem `color-mix`/`backdrop-filter`.
- Print: controles com `no-print`; `window.print()`.
- `sw.js` `obras-v9` → `obras-v10`.

### Task 1: View + render

- [ ] `index.html`: após a seção do relatório, nova seção:

```html
  <!-- ============ GRÁFICOS DA OBRA ============ -->
  <section class="view" id="v-graficos">
    <button class="back no-print" id="btnGrafVoltar">‹ Voltar pra obra</button>
    <div id="grafBody"></div>
  </section>
```

CSS: `.graf-donut{display:grid;place-items:center;margin:10px 0}` `.graf-leg li .dot{width:12px;height:12px;border-radius:4px;flex:0 0 auto}` (lista reusa `ul.list`); `nav.tabs` sólida.

- [ ] `app.js`: `evoChartHtml(o, opts={})` → usa `const suf=opts.sufixo||''`, `H=opts.H||170`, classe extra `evo-big` quando `opts.H>200` (CSS `.evo-big text{font-size:11px}`), ids `evoSvg${suf}`/`evoVal${suf}`; `bindEvoChart(o, suf='')` idem. Chamadas existentes seguem sem opts.
- [ ] `renderGraficos()`: agrupa `byTop` (mesma lógica do `renderObra`), monta donut grande (SVG viewBox 36, `width="min(260px, 70vw)"`, stroke 4.4, geometria idêntica ao `drawDonutObra`) + `<ul class="list graf-leg">` com linha por tópico (`ICON(t.ic)` + nome + `% · valor`) + `evoChartHtml(o,{sufixo:'G',H:300})` + botão `btn primary no-print` "Imprimir / salvar PDF" (`window.print()`); `bindEvoChart(o,'G')`.
- [ ] Entradas: em `renderObra`, ações ganham `<button class="btn ghost" id="oGraf">${ICON('documento')} Ver gráficos</button>`… não — ícone melhor: usar `ICON('alvo')`? Usar `ICON('documento')` só no relatório; pro botão usar `ICON('calculadora')`. Decisão: `ICON('calculadora')`. Handler `on('#oGraf', ...)` + clique no painel do donut (`#oDonut` wrap cursor pointer) → `showView('graficos'); renderGraficos();`. `#btnGrafVoltar` → `showView('obra'); renderObra();`.

### Task 2: Verificar + entregar

- [ ] E2E novo (padrão smoke-evo): 2 gastos (Mão de obra + Terreno via chips? gasto default topico=primeiro… setar tópico clicando chip "Mão de obra" é frágil — usar 2 gastos com tópicos distintos clicando chips pelo texto), abrir "Ver gráficos", assert texto contém "Mão de obra" completo e "Evolução da obra", voltar funciona. Regressões (`smoke-fase2`, `smoke-evo`) verdes.
- [ ] Screenshot mobile 390×844 conferido no olho.
- [ ] `sw.js` v10, commit, merge `tela-graficos` na main, push, monitor `obras-v10`.
