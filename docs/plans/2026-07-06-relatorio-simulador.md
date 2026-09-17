# Relatório bruto × corrigido no simulador — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Na aba "Vale a pena?", tabela-relatório na tela comparando a conta pelo custo bruto e pelo corrigido, com R$ e % em todas as linhas.

**Architecture:** Função pura `resumoVenda` em `calc.js` (testável em Node), chamada 2× no `simulaCompute` de `app.js`; os 3 cards menores viram uma tabela reusando as classes `rep-scroll`/`rep-table` do relatório de impressão. Card grande do veredito intocado.

**Tech Stack:** Vanilla JS, globais `OBRA_CALC`/`ICON`, testes `node tests/calc.test.cjs`, e2e puppeteer-core + Edge headless.

## Global Constraints

- Formatação: dinheiro `money()`; % sobre custo/venda 1 casa com vírgula (`50,0%`); rendimento 2 casas (`2,93% a.m.`); base inválida → `—`.
- Lucro/percentuais negativos em vermelho (classe `neg`; positivos do lucro usam `pos`).
- Sem download; só tela. Sem mudança em dados salvos.
- SW: bump `obras-v5` → `obras-v6` (celular pegar rápido).

---

### Task 1: `calc.js` — `resumoVenda` (TDD)

**Files:**
- Modify: `calc.js` (nova função + export no `api`)
- Test: `tests/calc.test.cjs` (append antes do `console.log` final)

**Interfaces:**
- Consumes: `taxaEquivalenteMensal(venda, custo, meses)` (já existe em `calc.js`).
- Produces: `OBRA_CALC.resumoVenda(venda, custo, meses)` → `{ lucro, pctCusto, pctVenda, taxaMes }`; percentuais em % (50 = 50%); tudo `null` quando `venda<=0` ou `custo<=0` (taxaMes também `null` se `meses<=0`).

- [ ] **Step 1: Teste que falha** — append em `tests/calc.test.cjs` (antes da linha final `console.log('OK: ...')`; ajustar o contador se for fixo):

```js
t('resumoVenda: exemplo canônico (3mi/2mi em 24 meses)', () => {
  const r = C.resumoVenda(3000000, 2000000, 24);
  assert.strictEqual(r.lucro, 1000000);
  perto(r.pctCusto, 50, 0.001);
  perto(r.pctVenda, 33.333, 0.001);
  perto(r.taxaMes, 1.7037, 0.001); // 1.5^(1/24)-1
});

t('resumoVenda: prejuízo fica negativo', () => {
  const r = C.resumoVenda(1500000, 2000000, 12);
  assert.strictEqual(r.lucro, -500000);
  assert.ok(r.pctCusto < 0 && r.pctVenda < 0 && r.taxaMes < 0);
});

t('resumoVenda: base inválida vira null', () => {
  const z = C.resumoVenda(0, 2000000, 12);
  assert.deepStrictEqual(z, { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null });
  const c = C.resumoVenda(3000000, 0, 12);
  assert.deepStrictEqual(c, { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null });
  assert.strictEqual(C.resumoVenda(3000000, 2000000, 0).taxaMes, null);
});
```

- [ ] **Step 2:** `node tests/calc.test.cjs` → FALHA (`C.resumoVenda is not a function`).

- [ ] **Step 3: Implementar** — em `calc.js`, logo após `taxaEquivalenteMensal`:

```js
/* Conta da venda numa base de custo (bruto OU corrigido):
   lucro em R$, % sobre o custo, % sobre a venda, % ao mês composto. */
function resumoVenda(venda, custo, meses){
  if(venda <= 0 || custo <= 0)
    return { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null };
  return {
    lucro: venda - custo,
    pctCusto: (venda / custo - 1) * 100,
    pctVenda: (venda - custo) / venda * 100,
    taxaMes: taxaEquivalenteMensal(venda, custo, meses),
  };
}
```

E adicionar `resumoVenda` ao objeto `api`.

- [ ] **Step 4:** `node tests/calc.test.cjs` → todos verdes (18+3).

- [ ] **Step 5:** Commit: `git add calc.js tests/calc.test.cjs && git commit -m "feat: resumoVenda em calc.js (lucro, % custo, % venda, % a.m.)"`.

---

### Task 2: `app.js` — tabela no simulador + SW bump

**Files:**
- Modify: `app.js` (função `simulaCompute`, bloco `out.innerHTML` final — os 3 cards menores)
- Modify: `sw.js:2` (`obras-v6`)

**Interfaces:**
- Consumes: `OBRA_CALC.resumoVenda` (Task 1), `ICON('documento')`, `money()`, classes CSS `rep-scroll`/`rep-table`/`rep-total`/`pos`/`neg` (já existem).

- [ ] **Step 1:** Em `simulaCompute`, antes do `out.innerHTML`, calcular:

```js
const rb = OBRA_CALC.resumoVenda(venda, bruto, mesesTot);
const rc = OBRA_CALC.resumoVenda(venda, corr,  mesesTot);
const pct1  = v => v==null ? '—' : v.toFixed(1).replace('.',',')+'%';
const taxa2 = v => v==null ? '—' : v.toFixed(2).replace('.',',')+'% a.m.';
const din   = v => v==null ? '—' : money(v);
const sinal = v => v==null ? '' : (v>=0 ? 'pos' : 'neg');
```

- [ ] **Step 2:** Substituir o bloco `<div class="cards">…</div>` (os 3 cards: Lucro bruto / Acima do banco / Custo até lá) por:

```js
    <div class="panel">
      <h2 style="justify-content:flex-start;gap:8px">${ICON('documento')} Relatório da simulação</h2>
      <div class="rep-scroll"><table class="rep-table">
        <thead><tr><th></th><th>Pelo bruto</th><th>Pelo corrigido</th></tr></thead>
        <tbody>
          <tr><td>Custo até a venda</td><td>${money(bruto)}</td><td>${money(corr)}</td></tr>
          <tr><td>Venda</td><td>${money(venda)}</td><td>${money(venda)}</td></tr>
          <tr class="rep-total"><td>Lucro</td><td class="${sinal(rb.lucro)}">${din(rb.lucro)}</td><td class="${sinal(rc.lucro)}">${din(rc.lucro)}</td></tr>
          <tr><td>% sobre o custo</td><td class="${sinal(rb.pctCusto)}">${pct1(rb.pctCusto)}</td><td class="${sinal(rc.pctCusto)}">${pct1(rc.pctCusto)}</td></tr>
          <tr><td>% sobre a venda</td><td class="${sinal(rb.pctVenda)}">${pct1(rb.pctVenda)}</td><td class="${sinal(rc.pctVenda)}">${pct1(rc.pctVenda)}</td></tr>
          <tr><td>Rendimento ao mês</td><td>${taxa2(rb.taxaMes)}</td><td>${taxa2(rc.taxaMes)}</td></tr>
        </tbody>
      </table></div>
    </div>`;
```

(O card grande do veredito que abre o template fica exatamente como está.)

- [ ] **Step 3:** `sw.js`: `const CACHE = 'obras-v6';`

- [ ] **Step 4: Conferir no navegador** — `npx -y http-server -p 8123 . -s` + Edge headless: simulador com venda digitada mostra a tabela, duas colunas, lucro verde/vermelho conforme sinal, `—` nunca aparece com obra válida. Screenshot pra conferência visual.

- [ ] **Step 5:** Commit: `git add app.js sw.js && git commit -m "feat: relatorio bruto x corrigido na aba Vale a pena"`.

---

### Task 3: E2E + entrega

- [ ] **Step 1:** Adaptar o smoke: depois de digitar venda no simulador, `assert` de que `#simOut` contém `% sobre o custo`, `Pelo bruto`, `Pelo corrigido` e um `% a.m.`. Varredura de emoji continua.
- [ ] **Step 2:** Rodar → `TUDO PASSOU`.
- [ ] **Step 3:** `git checkout main && git merge --no-ff relatorio-simulador -m "merge: relatorio bruto x corrigido no simulador" && git push`. Conferir `sw.js` em produção com `obras-v6`.
