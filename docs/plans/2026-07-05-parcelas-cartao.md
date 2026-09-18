# Parcelas de Cartão Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ao lançar gasto, escolher forma de pagamento (Pix/Cartão); no cartão, parcelar em até 36x — cada parcela vira um gasto real no mês correspondente, igual fatura de cartão.

**Architecture:** Parcelas são gastos comuns em `obra.gastos`, ligados por `grupoId` e anotados com `parcela:{n,de}` e `pagamento:'pix'|'cartao'`. Toda matemática existente (corrigido, donut, mês a mês, relatório) funciona sem alteração: parcela futura tem data futura e `diasEntre` já clampa em 0 → juros zero até vencer. Geração de parcelas (divisão de centavos + datas mensais clampadas no fim do mês) é função pura em `calc.js`, testada em Node.

**Tech Stack:** Vanilla JS, localStorage, testes Node com `assert` (`node tests/calc.test.cjs`).

## Global Constraints

- Gastos antigos sem `pagamento`/`grupoId`/`parcela` continuam funcionando (campos opcionais).
- Valor digitado = total da compra; centavos de arredondamento vão na última parcela (soma exata).
- Data escolhida = 1ª parcela; seguintes no mesmo dia dos meses seguintes; dia inexistente clampa no último dia do mês.
- Correção 1% a.m. por parcela a partir da data dela (automático — não mexer em `corrigido`).
- "Total gasto" bruto inclui parcelas futuras (compromisso assumido).
- Parcela com `data > hoje` mostra tag "a vencer" (classe CSS existente `tag pend`).
- UI em português, estilo do app (chips, sheet, `.field`).
- Commits com `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

### Task 1: `gerarParcelas` em calc.js

**Files:**
- Modify: `calc.js` (adicionar `addMesesClampado` e `gerarParcelas` antes do `const api`)
- Test: `tests/calc.test.cjs`

**Interfaces:**
- Produces: `OBRA_CALC.gerarParcelas(total:number, n:int, dataISO:string) => [{valor:number, data:string}]` (length n, soma exata = total). `OBRA_CALC.addMesesClampado(dataISO:string, meses:int) => string ISO`.

- [ ] **Step 1: Write the failing tests** — append em `tests/calc.test.cjs` antes do `console.log` final:

```js
t('addMesesClampado: mês normal e clamp no fim do mês', () => {
  assert.strictEqual(C.addMesesClampado('2026-07-17', 0), '2026-07-17');
  assert.strictEqual(C.addMesesClampado('2026-07-17', 1), '2026-08-17');
  assert.strictEqual(C.addMesesClampado('2026-07-17', 6), '2027-01-17'); // vira o ano
  assert.strictEqual(C.addMesesClampado('2026-01-31', 1), '2026-02-28'); // fev clampa
  assert.strictEqual(C.addMesesClampado('2028-01-31', 1), '2028-02-29'); // bissexto
  assert.strictEqual(C.addMesesClampado('2026-08-31', 1), '2026-09-30'); // 31 → 30
});

t('gerarParcelas: 10.000 em 10x = 10 de 1.000, dia 17 todo mês', () => {
  const ps = C.gerarParcelas(10000, 10, '2026-07-17');
  assert.strictEqual(ps.length, 10);
  ps.forEach(p => assert.strictEqual(p.valor, 1000));
  assert.strictEqual(ps[0].data, '2026-07-17');
  assert.strictEqual(ps[1].data, '2026-08-17');
  assert.strictEqual(ps[9].data, '2027-04-17');
});

t('gerarParcelas: centavos de arredondamento vão na última', () => {
  const ps = C.gerarParcelas(1000, 3, '2026-07-05');
  assert.strictEqual(ps[0].valor, 333.33);
  assert.strictEqual(ps[1].valor, 333.33);
  assert.strictEqual(ps[2].valor, 333.34);
  const soma = ps.reduce((s, p) => s + p.valor, 0);
  perto(soma, 1000, 1e-9);
});

t('gerarParcelas: 1x = um item com o total na data', () => {
  const ps = C.gerarParcelas(500.5, 1, '2026-07-05');
  assert.deepStrictEqual(ps, [{ valor: 500.5, data: '2026-07-05' }]);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tests/calc.test.cjs`
Expected: FAIL — `TypeError: C.addMesesClampado is not a function`

- [ ] **Step 3: Write minimal implementation** — em `calc.js`, antes de `const api = {...}`:

```js
  /* Soma meses a uma data ISO; dia inexistente clampa no último dia do mês
     (31/01 + 1 mês = 28 ou 29/02). */
  function addMesesClampado(dataISO, meses){
    const [y, m, d] = dataISO.split('-').map(Number);
    const tot = (m - 1) + meses;
    const ano = y + Math.floor(tot / 12);
    const mes = tot % 12; // 0-based
    const ultimo = new Date(ano, mes + 1, 0).getDate();
    const dia = Math.min(d, ultimo);
    return ano + '-' + String(mes + 1).padStart(2, '0') + '-' + String(dia).padStart(2, '0');
  }
  /* Divide total em n parcelas mensais a partir de dataISO.
     Conta em centavos; a diferença de arredondamento fica na última. */
  function gerarParcelas(total, n, dataISO){
    const cents = Math.round(total * 100);
    const base = Math.floor(cents / n);
    return Array.from({length: n}, (_, i) => ({
      valor: (i === n - 1 ? cents - base * (n - 1) : base) / 100,
      data: addMesesClampado(dataISO, i),
    }));
  }
```

E adicionar os dois nomes ao `const api = { ... }`.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tests/calc.test.cjs`
Expected: `OK: 18 testes` (14 atuais + 4 novos), todos `ok -`.

- [ ] **Step 5: Commit**

```bash
git add calc.js tests/calc.test.cjs
git commit -m "feat: gerarParcelas e addMesesClampado em calc"
```

---

### Task 2: Formulário de gasto — pagamento e parcelas

**Files:**
- Modify: `app.js` função `formGasto` (~linha 376)

**Interfaces:**
- Consumes: `OBRA_CALC.gerarParcelas(total, n, dataISO)` da Task 1.
- Produces: gastos salvos com `pagamento:'pix'|'cartao'`; parcelados também com `grupoId:string` e `parcela:{n:int, de:int}`.

- [ ] **Step 1: Adicionar campos ao HTML do sheet** — em `formGasto`, no template do `openSheet`, entre o campo Tópico e o campo Descrição, inserir (só na criação e na edição de gasto sem `grupoId`; na edição de parcela de grupo, omitir o bloco inteiro):

```js
  const isParcela = isEdit && gasto.grupoId;
  const pagtoHtml = isParcela ? '' : `
    <div class="field"><label>Pagamento</label><div class="chips" id="fPagto"></div></div>
    <div class="field hidden" id="fParcWrap"><label>Parcelas</label>
      <select id="fParc">${Array.from({length:36},(_,i)=>`<option value="${i+1}">${i+1}x</option>`).join('')}</select>
    </div>`;
```

e interpolar `${pagtoHtml}` no template. Na edição de parcela, mostrar aviso no lugar:

```js
  const parcelaInfo = isParcela
    ? `<p class="muted-note">💳 Parcela ${gasto.parcela.n}/${gasto.parcela.de} — edita só esta parcela.</p>`
    : '';
```

(interpolar `${parcelaInfo}` no mesmo ponto).

- [ ] **Step 2: Lógica dos chips de pagamento** — depois do `paint()` dos tópicos:

```js
  let pagto = isEdit ? (gasto.pagamento || 'pix') : 'pix';
  if(!isParcela){
    const pchips = $('#fPagto');
    const paintPagto = ()=>{
      pchips.innerHTML = '';
      [['pix','⚡ Pix'],['cartao','💳 Cartão']].forEach(([id,nm])=>{
        const ch = el('button','chip'+(id===pagto?' on':''),nm);
        ch.type = 'button';
        ch.onclick = ()=>{ pagto=id; paintPagto(); };
        pchips.appendChild(ch);
      });
      // parcelas só fazem sentido no cartão e na criação
      $('#fParcWrap').classList.toggle('hidden', pagto!=='cartao' || isEdit);
    };
    paintPagto();
  }
```

- [ ] **Step 3: Salvar criando N gastos** — substituir o bloco `else` do `#cSave` (o `o.gastos.push({...})` atual):

```js
    } else {
      const nParc = pagto==='cartao' ? parseInt($('#fParc').value,10)||1 : 1;
      const data0 = $('#fData').value || todayISO();
      const desc = $('#fDesc').value.trim();
      if(nParc > 1){
        const grupoId = uid();
        OBRA_CALC.gerarParcelas(valor, nParc, data0).forEach((p,i)=>{
          o.gastos.push({ id:uid(), valor:p.valor, topico:top, descricao:desc,
            data:p.data, pagamento:'cartao', grupoId, parcela:{n:i+1, de:nParc} });
        });
      } else {
        o.gastos.push({ id:uid(), valor, topico:top, descricao:desc,
          data:data0, pagamento:pagto });
      }
    }
```

No ramo `isEdit`, acrescentar `if(!isParcela) gasto.pagamento = pagto;` junto das atribuições existentes.

- [ ] **Step 4: Verificar manualmente**

Run: `node tests/calc.test.cjs` (garante que nada quebrou) e abrir `index.html` no browser: lançar gasto R$ 10.000, Cartão, 10x, dia 17.
Expected: 10 lançamentos de R$ 1.000, um por mês. Pix continua criando gasto único.

- [ ] **Step 5: Commit**

```bash
git add app.js
git commit -m "feat: pagamento pix/cartao e parcelas no formulario de gasto"
```

---

### Task 3: Exibição — (n/de), tag "a vencer", ícone de pagamento

**Files:**
- Modify: `app.js` função `gastoRow` (~linha 304)

**Interfaces:**
- Consumes: campos `pagamento`, `parcela`, `grupoId` da Task 2; classe CSS existente `.tag.pend`.

- [ ] **Step 1: Atualizar `gastoRow`** — substituir a montagem do `li.innerHTML`:

```js
function gastoRow(o, g){
  const t = TOP_MAP()[g.topico] || {nm:g.topico||'Outros', ic:'🏷️'};
  const li = el('li');
  const suf = g.parcela ? ` (${g.parcela.n}/${g.parcela.de})` : '';
  const futura = g.data > todayISO();
  const pIc = g.pagamento==='cartao' ? '💳 ' : g.pagamento==='pix' ? '⚡ ' : '';
  li.innerHTML = `
    <div class="av ic-brand">${t.ic}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(g.descricao || t.nm)}${suf}</div>
      <div class="s">${pIc}${t.nm} · ${fmtData(g.data)}${futura?' <span class="tag pend">a vencer</span>':''}</div>
    </div>
    <div class="li-val neg">−${money(g.valor)}</div>`;
  ...resto igual (onclick edição, botão del — del muda na Task 4)...
}
```

(Comparação `g.data > todayISO()` funciona: strings ISO ordenam lexicograficamente.)

- [ ] **Step 2: Verificar manualmente**

Abrir app: compra parcelada mostra "(1/10)…(10/10)", parcelas futuras com tag âmbar "a vencer", ⚡/💳 no subtítulo. Corrigido do card: parcelas futuras sem juros (bruto == corrigido nelas).

- [ ] **Step 3: Commit**

```bash
git add app.js
git commit -m "feat: parcela n/de, tag a vencer e icone de pagamento na lista"
```

---

### Task 4: Excluir — só esta parcela ou compra toda

**Files:**
- Modify: `app.js` função `gastoRow` (handler do botão `del`)

**Interfaces:**
- Consumes: `grupoId` da Task 2; `openSheet`/`closeSheet` existentes.

- [ ] **Step 1: Substituir o `del.onclick`**:

```js
  const del = el('button','li-del','×');
  del.onclick = ()=>{
    if(!g.grupoId){
      if(confirm('Excluir este gasto?')){ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); renderAll(); }
      return;
    }
    const irmas = o.gastos.filter(x=>x.grupoId===g.grupoId);
    openSheet(`
      <h3>Excluir parcela ${g.parcela.n}/${g.parcela.de}</h3>
      <p class="muted-note">Esta parcela faz parte de uma compra em ${g.parcela.de}x no cartão.</p>
      <div class="sheet-actions" style="flex-direction:column">
        <button class="btn primary" id="dUma" style="width:100%">Excluir só esta parcela</button>
        <button class="btn ghost" id="dTodas" style="width:100%;color:var(--red)">Excluir a compra toda (${irmas.length} parcelas)</button>
        <button class="btn ghost" id="dCancel" style="width:100%">Cancelar</button>
      </div>`);
    $('#dCancel').onclick = closeSheet;
    $('#dUma').onclick = ()=>{ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); closeSheet(); renderAll(); };
    $('#dTodas').onclick = ()=>{ o.gastos = o.gastos.filter(x=>x.grupoId!==g.grupoId); save(); closeSheet(); renderAll(); };
  };
```

- [ ] **Step 2: Verificar manualmente**

Excluir parcela do meio: sheet com 3 opções; "só esta" remove 1; "compra toda" remove todas. Gasto avulso mantém `confirm` simples.

- [ ] **Step 3: Rodar testes e commit**

Run: `node tests/calc.test.cjs` — Expected: `OK: 18 testes`.

```bash
git add app.js
git commit -m "feat: excluir parcela unica ou compra toda"
```
