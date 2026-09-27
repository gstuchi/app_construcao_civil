# Orçamento previsto × real — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cada obra pode ter um orçamento previsto (total ou por tópico); o Custta compara com o gasto bruto na tela da obra, no Início e no push diário.

**Architecture:** Campo opcional `o.orcamento` dentro da obra no blob `dados/{uid}`, validado em `dados.js`. A conta é pura em `calc.js` (`OBRA_CALC.orcamentoObra`), usada pelo app e pelo push (Node). A UI vive em `app.js`/`styles.css` seguindo o visual iOS existente. O push guarda a memória dos avisos em `perfis/{uid}.avisosOrcamento` para avisar uma vez por subida de nível.

**Tech Stack:** Vanilla JS (scripts clássicos com globais), CSS com custom properties, Node `node --test`, Firebase Admin SDK (cron), `@firebase/rules-unit-testing`, Playwright.

**Spec:** `docs/specs/2026-09-26-orcamento-previsto-real-design.md`

## Global Constraints

- Verde-marca abaixo de 90%, âmbar (`--amber`, `--amber-soft`) de 90% em diante. Nunca vermelho em indicador de orçamento.
- Base de comparação = bruto (`OBRA_CALC.totalBruto`, inclui parcelas a vencer). Corrigido só nos KPIs.
- Obra sem orçamento: sem card, sem barra, sem número; `normaliza` não adiciona chave nova.
- CSP estrita: nada de `<style>`, `style="..."` em HTML ou `onclick=` em HTML. Largura de barra só via CSSOM (`el.style.width`).
- Cores só por variáveis de `styles.css` (quatro combos tema × skin). Contraste de texto ≥ 4,5:1.
- `input` com `font-size` ≥ 16px. Alvos de toque ≥ 44px.
- Identificadores, comentários e UI em português. Nada de dependência de runtime no browser. Nenhum arquivo novo na raiz (senão `sw.js` precisa de bump).
- Todo `value="${...}"` em template de `app.js` passa por `escapeHtml(` ou `OBRA_CALC.numParaCampo(` (checado por `tests/xss.test.cjs`).
- Implementadores **não commitam**; o controlador commita depois da revisão. Commits com autor Giovani Stuchi, sem Co-Authored-By.
- Node: `export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$PATH"`. Unit: `npm run test:unit`. Rules: `npm run test:rules` (Java em `~/.local`). Browser: `node tests/browser/servidor.cjs` em um terminal e a suíte em outro.
- NUNCA abrir `localhost:8123` com o `cloud.js` real (bate na produção). As suítes daqui trocam `cloud.js` por vazio e injetam `window.CLOUD` falso.

## Review Focus

1. Obra antiga sem orçamento passando por `normaliza` ganha `orcamento: null`/`undefined` e muda o documento de todo mundo — Task 2 testa que a chave não aparece e que `normaliza(normaliza(d))` é igual.
2. Campo digitado com máscara ("1.234,56"), apagado ou "0" na folha — Task 6 testa salvar vazio (tira o orçamento) e soma ao vivo com máscara.
3. Cron rodando 9h e 18h com o mesmo estouro — Task 4 testa que a segunda rodada não reenvia nem regrava.
4. Tópico próprio apagado com orçamento órfão — Task 3 testa que a frase do push cai no id e não quebra; Task 1 testa que a conta segue.
5. Cliente salvando o nome depois do cron gravar `avisosOrcamento` no perfil — Task 4 testa nas rules.

---

### Task 1: `TOPICOS` e `orcamentoObra` em `calc.js`

**Files:**
- Modify: `calc.js` (antes de `const api = {...}` e na própria `api`)
- Modify: `app.js:7-29` (literal `TOPICOS` vira `const TOPICOS = OBRA_CALC.TOPICOS;`)
- Test: `tests/calc.test.cjs` (acrescentar antes do `console.log` final)

**Interfaces:**
- Produces: `OBRA_CALC.TOPICOS` (array `{id, nm, ic}`, mesma lista e ordem do `app.js` atual); `OBRA_CALC.orcamentoObra(obra)` → `null` ou `{modo, previsto, gasto, pct, sobra, nivel, topicos:[{id, previsto, gasto, pct, sobra, nivel}], fora:[{id, gasto}], foraTotal}`; `nivel ∈ 'ok'|'perto'|'passou'`.

- [ ] **Step 1: Escrever os testes (falham)** — acrescentar em `tests/calc.test.cjs`, antes de `console.log(\`OK: ${n} testes\`)`:

```js
const obraOrc = (orcamento, gastos = []) => ({ id:'o', dataInicio:'2026-01-01', gastos, orcamento });
const gOrc = (topico, valor, data = '2026-02-01') => ({ id: topico + valor, topico, valor, data });

t('TOPICOS exportado com ids únicos e nomes', () => {
  assert.ok(Array.isArray(C.TOPICOS) && C.TOPICOS.length === 21);
  assert.strictEqual(new Set(C.TOPICOS.map(x => x.id)).size, C.TOPICOS.length);
  assert.strictEqual(C.TOPICOS.find(x => x.id === 'fundacao').nm, 'Fundação');
  assert.strictEqual(C.TOPICOS.find(x => x.id === 'hidraulica').nm, 'Encanamento');
});

t('orcamentoObra: sem orçamento ou inválido = null', () => {
  assert.strictEqual(C.orcamentoObra(obraOrc(undefined)), null);
  assert.strictEqual(C.orcamentoObra(obraOrc(null)), null);
  assert.strictEqual(C.orcamentoObra(obraOrc({ modo:'total', total:0 })), null);
  assert.strictEqual(C.orcamentoObra(obraOrc({ modo:'total', total:'800' })), null);
  assert.strictEqual(C.orcamentoObra(obraOrc({ modo:'topicos', topicos:{} })), null);
  assert.strictEqual(C.orcamentoObra(obraOrc({ modo:'topicos', topicos:{ fundacao:-5 } })), null);
});

t('orcamentoObra modo total: bruto inteiro, inclusive parcela a vencer', () => {
  const r = C.orcamentoObra(obraOrc({ modo:'total', total:800000 },
    [gOrc('terreno', 180000), gOrc('fundacao', 432400, '2027-12-01')]));
  assert.strictEqual(r.modo, 'total');
  assert.strictEqual(r.previsto, 800000);
  assert.strictEqual(r.gasto, 612400);
  assert.strictEqual(r.pct, 77);
  assert.strictEqual(r.sobra, 187600);
  assert.strictEqual(r.nivel, 'ok');
  assert.deepStrictEqual(r.topicos, []);
  assert.deepStrictEqual(r.fora, []);
  assert.strictEqual(r.foraTotal, 0);
});

t('orcamentoObra limiares: 89,4% ok, 89,6% perto, 100% perto, meio centavo acima passou', () => {
  const nivel = gasto => C.orcamentoObra(obraOrc({ modo:'total', total:1000 }, [gOrc('terreno', gasto)])).nivel;
  assert.strictEqual(nivel(894), 'ok');
  assert.strictEqual(nivel(896), 'perto');
  assert.strictEqual(nivel(1000), 'perto');
  assert.strictEqual(nivel(1000.004), 'perto');
  assert.strictEqual(nivel(1000.01), 'passou');
});

t('orcamentoObra modo topicos: compara só previstos, fora aparece separado', () => {
  const r = C.orcamentoObra(obraOrc({ modo:'topicos', topicos:{ fundacao:90000, estrutura:250000, c_apagado:1000 } },
    [gOrc('fundacao', 98000), gOrc('estrutura', 231000), gOrc('hidraulica', 12000), gOrc('pintura', 3000)]));
  assert.strictEqual(r.modo, 'topicos');
  assert.strictEqual(r.previsto, 341000);
  assert.strictEqual(r.gasto, 329000);
  assert.deepStrictEqual(r.topicos.map(x => [x.id, x.nivel, x.pct]),
    [['fundacao','passou',109], ['estrutura','perto',92], ['c_apagado','ok',0]]);
  assert.strictEqual(r.topicos[0].sobra, -8000);
  assert.deepStrictEqual(r.fora, [{ id:'hidraulica', gasto:12000 }, { id:'pintura', gasto:3000 }]);
  assert.strictEqual(r.foraTotal, 15000);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/calc.test.cjs`
Expected: FAIL em `TOPICOS exportado` (`C.TOPICOS` undefined).

- [ ] **Step 3: Implementar em `calc.js`** — antes de `const api = {`:

```js
  /* Tópicos fixos. Moram aqui, e não no app.js, porque o push diário (Node)
     precisa do nome do tópico para escrever o aviso de orçamento. */
  const TOPICOS = Object.freeze([
    {id:'terreno',    nm:'Terreno',           ic:'mapa'},
    {id:'projeto',    nm:'Documentação',      ic:'documento'},
    {id:'matbasicos', nm:'Materiais básicos', ic:'tijolos'},
    {id:'fundacao',   nm:'Fundação',          ic:'pa'},
    {id:'ferragem',   nm:'Ferragem',          ic:'vergalhao'},
    {id:'estrutura',  nm:'Estrutura',         ic:'guindaste'},
    {id:'alvenaria',  nm:'Alvenaria',         ic:'tijolos'},
    {id:'telhado',    nm:'Telhado',           ic:'casa'},
    {id:'eletrica',   nm:'Elétrica',          ic:'raio'},
    {id:'hidraulica', nm:'Encanamento',       ic:'gota'},
    {id:'esquadrias', nm:'Esq. de alumínio',  ic:'porta'},
    {id:'revest',     nm:'Cerâmica',          ic:'ladrilho'},
    {id:'pintura',    nm:'Pintura',           ic:'rolo'},
    {id:'acabamento', nm:'Acabamento',        ic:'rolo'},
    {id:'piscina',    nm:'Piscina',           ic:'piscina'},
    {id:'paisagismo', nm:'Jardim',            ic:'arvore'},
    {id:'maoobra',    nm:'Mão de obra',       ic:'capacete'},
    {id:'aluguelmaq', nm:'Aluguel de máquina',ic:'engrenagem'},
    {id:'matextra',   nm:'Materiais extra',   ic:'caixa'},
    {id:'extras',     nm:'Extras',            ic:'mais'},
    {id:'outros',     nm:'Outros',            ic:'caixa'},
  ]);

  /* Orçamento previsto × real. Base = bruto (inclui parcelas a vencer), nunca o
     corrigido. O pct arredondado é o que a tela mostra; o nível sai dele, então
     cor e número nunca discordam. Passou = mais de meio centavo acima. */
  const LIMIAR_PERTO = 90;
  function itemOrcamento(gasto, previsto){
    const pct = Math.round(gasto / previsto * 100);
    const nivel = gasto - previsto > 0.005 ? 'passou' : pct >= LIMIAR_PERTO ? 'perto' : 'ok';
    return { previsto, gasto, pct, sobra: previsto - gasto, nivel };
  }
  const positivoFinito = v => typeof v === 'number' && Number.isFinite(v) && v > 0;
  function orcamentoObra(obra){
    const orc = obra && obra.orcamento;
    if(!orc || typeof orc !== 'object') return null;
    const gastos = Array.isArray(obra.gastos) ? obra.gastos : [];
    if(orc.modo === 'topicos'){
      const prev = orc.topicos && typeof orc.topicos === 'object' ? orc.topicos : {};
      const ids = Object.keys(prev).filter(id => positivoFinito(prev[id]));
      if(!ids.length) return null;
      const porTop = Object.create(null);
      gastos.forEach(g => { porTop[g.topico] = (porTop[g.topico] || 0) + g.valor; });
      const topicos = ids.map(id => ({ id, ...itemOrcamento(porTop[id] || 0, prev[id]) }))
        .sort((a, b) => b.gasto / b.previsto - a.gasto / a.previsto || a.id.localeCompare(b.id));
      const fora = Object.keys(porTop).filter(id => !ids.includes(id) && porTop[id] > 0)
        .map(id => ({ id, gasto: porTop[id] }))
        .sort((a, b) => b.gasto - a.gasto || a.id.localeCompare(b.id));
      const previsto = topicos.reduce((s, x) => s + x.previsto, 0);
      const gasto = topicos.reduce((s, x) => s + x.gasto, 0);
      return { modo:'topicos', ...itemOrcamento(gasto, previsto), topicos, fora,
        foraTotal: fora.reduce((s, f) => s + f.gasto, 0) };
    }
    if(!positivoFinito(orc.total)) return null;
    return { modo:'total', ...itemOrcamento(totalBruto({ gastos }), orc.total), topicos:[], fora:[], foraTotal:0 };
  }
```

E acrescentar `TOPICOS, orcamentoObra` ao objeto `api`.

- [ ] **Step 4: `app.js` usa a lista do `calc.js`** — substituir o literal `const TOPICOS = [ ... ];` (linhas 7–29) por:

```js
const TOPICOS = OBRA_CALC.TOPICOS; // calc.js: o push (Node) usa a mesma lista
```

- [ ] **Step 5: Rodar**

Run: `node tests/calc.test.cjs && npm run test:unit`
Expected: PASS, todos os arquivos.

---

### Task 2: normalização de `o.orcamento` em `dados.js`

**Files:**
- Modify: `dados.js` (função nova `orcamento`, uso em `obra()`)
- Modify: `CLAUDE.md:68` e `docs/ARQUITETURA.md:43` (forma do objeto obra ganha `orcamento?`)
- Test: `tests/dados.test.cjs`

**Interfaces:**
- Produces: obra normalizada com `orcamento` = `{...v, modo:'total', total:number>0}` ou `{...v, modo:'topicos', topicos:{[id]:number>0}}`, ou **sem a chave** quando inválido/ausente.

- [ ] **Step 1: Testes (falham)** — acrescentar ao fim de `tests/dados.test.cjs`:

```js
const obraBase = extra => ({ id:'o', dataInicio:'2026-01-01', gastos:[], ...extra });
test('obra sem orçamento continua sem a chave e normaliza é idempotente', () => {
  const d = normaliza({ obras:[obraBase({})] });
  assert.equal('orcamento' in d.obras[0], false);
  assert.deepEqual(normaliza(d), d);
  for(const lixo of [null, 0, 'x', [], { modo:'total' }, { modo:'total', total:-1 }, { modo:'total', total:0 },
    { modo:'topicos', topicos:{} }, { modo:'topicos', topicos:{ fundacao:0, '':5 } }, { modo:'topicos', topicos:[] }]){
    assert.equal('orcamento' in normaliza({ obras:[obraBase({ orcamento:lixo })] }).obras[0], false, JSON.stringify(lixo));
  }
});
test('orçamento total válido: número positivo, texto numérico vira número, extras preservados', () => {
  const [o] = normaliza({ obras:[obraBase({ orcamento:{ modo:'total', total:'800000', futuro:1 } })] }).obras;
  assert.deepEqual(o.orcamento, { modo:'total', total:800000, futuro:1 });
  const [semModo] = normaliza({ obras:[obraBase({ orcamento:{ total:5 } })] }).obras;
  assert.deepEqual(semModo.orcamento, { modo:'total', total:5 });
});
test('orçamento por tópico: só ids de texto até 80 e valores positivos, no máximo 100', () => {
  const topicos = { fundacao:90000, estrutura:'250000', lixo:-3, zero:0, nan:'x', ['x'.repeat(81)]:10, c_1:5 };
  const [o] = normaliza({ obras:[obraBase({ orcamento:{ modo:'topicos', topicos, total:999 } })] }).obras;
  assert.deepEqual(o.orcamento.topicos, { fundacao:90000, estrutura:250000, c_1:5 });
  assert.equal(o.orcamento.modo, 'topicos');
  const muitos = Object.fromEntries(Array.from({ length:150 }, (_, i) => ['t' + i, i + 1]));
  const [m] = normaliza({ obras:[obraBase({ orcamento:{ modo:'topicos', topicos:muitos } })] }).obras;
  assert.equal(Object.keys(m.orcamento.topicos).length, 100);
  const d = normaliza({ obras:[obraBase({ orcamento:{ modo:'topicos', topicos } })] });
  assert.deepEqual(normaliza(d), d);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/dados.test.cjs`
Expected: FAIL (hoje `orcamento` passa cru).

- [ ] **Step 3: Implementar** — em `dados.js`, depois de `lista`:

```js
  /* Orçamento previsto (opcional): só o total, ou valor por tópico. Inválido ou
     vazio some — a obra sem orçamento fica exatamente como era, sem chave nova. */
  const MAX_TOPICOS_ORC = 100;
  function orcamento(v){
    if(!objeto(v)) return null;
    const maior = x => numero(x) !== null && numero(x) > 0 ? numero(x) : null;
    if(v.modo === 'topicos'){
      const origem = objeto(v.topicos) ? v.topicos : {};
      const topicos = {};
      for(const [id, valor] of Object.entries(origem)){
        if(Object.keys(topicos).length >= MAX_TOPICOS_ORC) break;
        if(id.trim() && id.length <= LIMITES.topico && maior(valor) !== null) topicos[id] = maior(valor);
      }
      if(!Object.keys(topicos).length) return null;
      const r = {...v, modo:'topicos', topicos};
      delete r.total;
      return r;
    }
    const total = maior(v.total);
    if(total === null) return null;
    const r = {...v, modo:'total', total};
    delete r.topicos;
    return r;
  }
```

E em `obra(o)` trocar o `return {...o, ...}` por montar em `r`:

```js
    const r = {...o, id:texto(o.id), nome:texto(o.nome)||'Obra sem nome',
      fase:['construcao','pronta','vendida'].includes(o.fase) && (o.fase!=='vendida'||venda) ? o.fase : 'construcao',
      venda, valorEstimadoVenda:positivo(o.valorEstimadoVenda), areaM2:positivo(o.areaM2),
      gastos:lista(o.gastos,gasto), afazeres:lista(o.afazeres,a=>texto(a.id)?{...a,id:texto(a.id),texto:texto(a.texto),feito:a.feito===true}:null)};
    const orc = orcamento(o.orcamento);
    if(orc) r.orcamento = orc; else delete r.orcamento;
    return r;
```

- [ ] **Step 4: Documentar a forma** — em `CLAUDE.md:68` e `docs/ARQUITETURA.md:43`, acrescentar ao objeto obra `orcamento?: {modo:'total', total} | {modo:'topicos', topicos:{idDoTópico: valor}}` (opcional; ver `docs/specs/2026-09-26-orcamento-previsto-real-design.md`).

- [ ] **Step 5: Rodar**

Run: `npm run test:unit`
Expected: PASS.

---

### Task 3: avisos de orçamento no resumo (`notificacoes/resumo.js`)

**Files:**
- Modify: `notificacoes/resumo.js`
- Test: `tests/resumo.test.cjs`

**Interfaces:**
- Consumes: `require('../calc.js').orcamentoObra`, `.TOPICOS`; `require('../dados.js').normaliza`.
- Produces: `estadoOrcamento(dados)` → `{ [chave]: 'perto'|'passou' }` com chaves `"<obraId>|total"` e `"<obraId>|t:<topicoId>"`; `avisosOrcamento(dados, anterior)` → `{ linhas: string[], obraIds: string[] }`; `montaResumo(dados, hojeISO, periodo, anterior)` (4º parâmetro novo; ausente/`null` = sem avisos de orçamento). Exporta `{ montaResumo, endpointPushValido, estadoOrcamento, avisosOrcamento }`.

- [ ] **Step 1: Testes (falham)** — acrescentar em `tests/resumo.test.cjs` antes do `console.log` final (troque o `require` do topo para também trazer `estadoOrcamento, avisosOrcamento`):

```js
const obraOrc = (id, nome, orcamento, gastos, extra) => ({ id, nome, fase:'construcao', dataInicio:'2026-01-01',
  orcamento, gastos: gastos.map(([topico, valor], i) => ({ id:id + i, topico, valor, data:'2026-07-10' })), ...extra });
const CASA = obraOrc('o1', 'Casa Alphaville', { modo:'topicos', topicos:{ fundacao:90000, estrutura:250000 } },
  [['fundacao', 98000], ['estrutura', 231000]]);

t('estadoOrcamento: só itens a partir de perto', () => {
  assert.deepStrictEqual(estadoOrcamento({ obras:[CASA] }),
    { 'o1|total':'perto', 'o1|t:fundacao':'passou', 'o1|t:estrutura':'perto' });
  assert.deepStrictEqual(estadoOrcamento({ obras:[] }), {});
  assert.deepStrictEqual(estadoOrcamento(null), {});
});

t('sem memória (anterior ausente ou null): nenhum aviso de orçamento', () => {
  assert.deepStrictEqual(avisosOrcamento({ obras:[CASA] }, null), { linhas:[], obraIds:[] });
  assert.strictEqual(montaResumo({ obras:[CASA] }, '2026-07-10', 'noite'), null);
});

t('primeira vez: frases de tópico e de total, passou antes de perto', () => {
  const r = avisosOrcamento({ obras:[CASA] }, {});
  assert.deepStrictEqual(r.linhas, [
    'Fundação passou R$ 8 mil do previsto',
    'Casa Alphaville chegou a 97% do orçamento',
    'Estrutura chegou a 92% do previsto',
  ]);
  assert.deepStrictEqual(r.obraIds, ['o1']);
});

t('mesmo nível: silêncio; subida perto → passou: avisa de novo', () => {
  const estado = estadoOrcamento({ obras:[CASA] });
  assert.deepStrictEqual(avisosOrcamento({ obras:[CASA] }, estado).linhas, []);
  const estourou = obraOrc('o1', 'Casa Alphaville', CASA.orcamento, [['fundacao', 98000], ['estrutura', 260000]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[estourou] }, estado).linhas,
    ['Casa Alphaville passou R$ 18 mil do orçamento', 'Estrutura passou R$ 10 mil do previsto']);
});

t('descida esquece: depois de baixar, nova subida avisa', () => {
  const folgada = obraOrc('o1', 'Casa Alphaville', { modo:'topicos', topicos:{ fundacao:200000, estrutura:250000 } },
    [['fundacao', 98000], ['estrutura', 100000]]);
  const estado = estadoOrcamento({ obras:[folgada] });
  assert.deepStrictEqual(estado, {});
  assert.strictEqual(avisosOrcamento({ obras:[CASA] }, estado).linhas.length, 3);
});

t('memória com lixo não quebra nem silencia', () => {
  const r = avisosOrcamento({ obras:[CASA] }, { 'o1|t:fundacao':'constructor', 'o1|total':42 });
  assert.strictEqual(r.linhas.length, 3);
});

t('obra vendida não avisa; várias obras ganham o nome entre parênteses', () => {
  const vendida = obraOrc('v', 'Vendida', { modo:'total', total:10 }, [['terreno', 100]], { fase:'vendida', venda:{ valor:1, data:'2026-07-01' } });
  const outra = obraOrc('o2', 'Sobrado', { modo:'total', total:1008000 }, [['estrutura', 1048000]]);
  const r = avisosOrcamento({ obras:[CASA, vendida, outra] }, {});
  assert.ok(r.linhas.includes('Fundação (Casa Alphaville) passou R$ 8 mil do previsto'), r.linhas.join(' | '));
  assert.ok(!r.linhas.some(l => l.includes('Vendida')));
  assert.deepStrictEqual(r.obraIds, ['o1', 'o2']);
});

t('no máximo 3 frases; o resto vira contagem', () => {
  const muitos = obraOrc('o1', 'Casa', { modo:'topicos', topicos:{ fundacao:10, estrutura:10, eletrica:10, pintura:10 } },
    [['fundacao', 20], ['estrutura', 20], ['eletrica', 20], ['pintura', 20]]);
  const r = avisosOrcamento({ obras:[muitos] }, {});
  assert.strictEqual(r.linhas.length, 4);
  assert.strictEqual(r.linhas[3], '+ 2 avisos de orçamento');
});

t('tópico próprio usa o nome dele; tópico apagado cai no id', () => {
  const dados = { config:{ taxaMensal:1, topicosCustom:[{ id:'c_portao', nm:'Portão', ic:'etiqueta' }] },
    obras:[obraOrc('o1', 'Casa', { modo:'topicos', topicos:{ c_portao:1000, c_sumiu:1000 } }, [['c_portao', 1500], ['c_sumiu', 1500]])] };
  const linhas = avisosOrcamento(dados, {}).linhas;
  assert.ok(linhas.includes('Portão passou R$ 500,00 do previsto'), linhas.join(' | '));
  assert.ok(linhas.includes('c_sumiu passou R$ 500,00 do previsto'), linhas.join(' | '));
});

t('montaResumo: avisos de orçamento vêm primeiro e viram atalho da obra', () => {
  const dados = { obras:[{ ...CASA, afazeres:[{ id:'a', texto:'x', feito:false }] }] };
  const r = montaResumo(dados, '2026-07-10', 'noite', {});
  assert.strictEqual(r.corpo.split('\n')[0], 'Fundação passou R$ 8 mil do previsto');
  assert.ok(r.corpo.includes('1 afazer pendente'));
  assert.strictEqual(r.obraId, 'o1');
});

t('valores grandes ficam curtos', () => {
  const grande = obraOrc('o1', 'Casa', { modo:'total', total:1000000 }, [['terreno', 2250000]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[grande] }, {}).linhas, ['Casa passou R$ 1,25 mi do orçamento']);
  const mil = obraOrc('o1', 'Casa', { modo:'total', total:1000 }, [['terreno', 2500]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[mil] }, {}).linhas, ['Casa passou R$ 1,5 mil do orçamento']);
});
```

Conferência das contas: CASA previsto 340.000, gasto 329.000 → 96,76% → 97. Estrutura 231/250 = 92,4% → 92. Fundação 98/90 → passou 8.000. Subida: estrutura 260.000 → passou 10.000; total 358.000 − 340.000 = 18.000. Ordem das frases: a ordem de `itensOrcamento` (total da obra, depois tópicos em pct decrescente) com sort estável por nível (passou antes de perto).

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/resumo.test.cjs`
Expected: FAIL (`estadoOrcamento is not a function`).

- [ ] **Step 3: Implementar** — em `notificacoes/resumo.js`, depois do `BRL`:

```js
const OBRA_CALC = require('../calc.js');
const { normaliza } = require('../dados.js');

/* ---- avisos de orçamento ----
   Regra de não repetir: cada item (obra × total, obra × tópico) tem nível
   ok < perto < passou. Só avisa quando o nível atual é MAIOR que o último
   avisado (memória em perfis/{uid}.avisosOrcamento, gravada pelo enviar.js).
   Mesmo nível → silêncio; descida → a memória desce e uma nova subida avisa. */
const NIVEL = { ok:0, perto:1, passou:2 };
const rank = v => typeof v === 'string' && Object.prototype.hasOwnProperty.call(NIVEL, v) ? NIVEL[v] : 0;
const MAX_FRASES_ORC = 3;

/* "R$ 8 mil", "R$ 1,5 mil", "R$ 1,25 mi" — cabe na notificação */
function curto(n){
  const a = Math.abs(n);
  const fmt = (v, casas) => {
    const s = v.toFixed(casas).replace('.', ',');
    return s.includes(',') ? s.replace(/0+$/, '').replace(/,$/, '') : s;
  };
  if(a >= 1e6) return 'R$ ' + fmt(a / 1e6, a >= 1e7 ? 1 : 2) + ' mi';
  if(a >= 1000) return 'R$ ' + fmt(a / 1000, a >= 10000 ? 0 : 1) + ' mil';
  return 'R$ ' + a.toFixed(2).replace('.', ','); // espaço comum: BRL.format usa NBSP
}

function itensOrcamento(dados){
  const d = normaliza(dados);
  const nomes = Object.fromEntries([...OBRA_CALC.TOPICOS, ...d.config.topicosCustom].map(t => [t.id, t.nm]));
  const comOrc = d.obras.filter(o => o.fase !== 'vendida')
    .map(o => [o, OBRA_CALC.orcamentoObra(o)]).filter(([, r]) => r);
  const variasObras = comOrc.length > 1;
  const itens = [];
  for(const [o, r] of comOrc){
    itens.push({ chave:o.id + '|total', obraId:o.id, nivel:r.nivel, pct:r.pct, sobra:r.sobra, sujeito:o.nome, alvo:'orçamento' });
    for(const t of r.topicos){
      const nome = nomes[t.id] || t.id;
      itens.push({ chave:o.id + '|t:' + t.id, obraId:o.id, nivel:t.nivel, pct:t.pct, sobra:t.sobra,
        sujeito: variasObras ? nome + ' (' + o.nome + ')' : nome, alvo:'previsto' });
    }
  }
  return itens;
}

function estadoOrcamento(dados){
  const estado = {};
  for(const i of itensOrcamento(dados)) if(i.nivel !== 'ok') estado[i.chave] = i.nivel;
  return estado;
}

function avisosOrcamento(dados, anterior){
  if(!anterior || typeof anterior !== 'object') return { linhas:[], obraIds:[] };
  const novos = itensOrcamento(dados).filter(i => NIVEL[i.nivel] > rank(anterior[i.chave]));
  novos.sort((a, b) => NIVEL[b.nivel] - NIVEL[a.nivel]); // passou primeiro, se o limite cortar
  const linhas = novos.slice(0, MAX_FRASES_ORC).map(i => i.nivel === 'passou'
    ? i.sujeito + ' passou ' + curto(-i.sobra) + ' do ' + i.alvo
    : i.sujeito + ' chegou a ' + i.pct + '% do ' + i.alvo);
  const resto = novos.length - linhas.length;
  if(resto > 0) linhas.push(resto === 1 ? '+ 1 aviso de orçamento' : '+ ' + resto + ' avisos de orçamento');
  return { linhas, obraIds:[...new Set(novos.map(i => i.obraId))] };
}
```

`fmt`: `'40'` fica `'40'`; `'8,0'` → `'8'`; `'1,5'` fica; `'1,20'` → `'1,2'`.

Em `montaResumo`: assinatura `function montaResumo(dados, hojeISO, periodo, anterior)`; logo depois de criar `linhas` e `origem`:

```js
  // avisos de orçamento primeiro: são a notícia mais importante do dia
  const orc = avisosOrcamento(dados, anterior);
  linhas.push(...orc.linhas);
  orc.obraIds.forEach(id => origem.add(id));
```

Atualizar o comentário do topo do arquivo (4º parâmetro) e o `module.exports`.

- [ ] **Step 4: Rodar**

Run: `node tests/resumo.test.cjs && node --test tests/enviar.test.cjs tests/cron.test.cjs`
Expected: PASS (chamadores atuais não passam `anterior` e continuam iguais).

---

### Task 4: memória do aviso no perfil (`enviar.js`), rules e README

**Files:**
- Modify: `notificacoes/enviar.js`
- Modify: `firestore.rules` (só comentário no bloco `perfis/{uid}`)
- Modify: `notificacoes/README.md` (seção "Avisos de orçamento")
- Test: `tests/enviar.test.cjs`, `tests/rules.test.mjs`

**Interfaces:**
- Consumes: `montaResumo(dados, hojeISO, periodo, anterior)`, `estadoOrcamento(dados)` da Task 3.
- Produces: `perfis/{uid}.avisosOrcamento` gravado com `perfil.ref.update({ avisosOrcamento })`, nunca criando perfil.

- [ ] **Step 1: Testes de envio (falham)** — acrescentar em `tests/enviar.test.cjs`:

```js
function bancoPerfil({ subs, dados, perfil }){
  const gravacoes = [];
  const db = {
    collection:()=>({ get:async()=>({ size:1, docs:[{ id:'ana', data:()=>({ subs }), ref:{ update:async()=>{} } }] }) }),
    doc:caminho=>({ get:async()=>caminho.startsWith('dados/')
      ? { exists:true, data:()=>dados }
      : { exists:!!perfil, data:()=>perfil || undefined, ref:{ update:async v=>gravacoes.push([caminho, v]) } } }),
  };
  return { db, gravacoes };
}
const SUB = { s1:{ endpoint:'https://fcm.googleapis.com/fcm/send/x', keys:{} } };
const DADOS_ORC = { obras:[{ id:'o1', nome:'Casa', fase:'construcao', dataInicio:'2026-01-01',
  orcamento:{ modo:'topicos', topicos:{ fundacao:90000 } },
  gastos:[{ id:'g1', topico:'fundacao', valor:98000, data:'2026-07-10' }] }] };
const ESTADO_ORC = { 'o1|total':'passou', 'o1|t:fundacao':'passou' };
const rodar = (db, sendNotification) => enviaTodos({ db, FieldPath, FieldValue, periodo:'noite',
  agora:new Date('2026-07-10T21:00:00Z'), log:silencioso, webpush:{ sendNotification }, messaging:{} });

test('orçamento: avisa uma vez e grava a memória no perfil depois de entregar', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{ tz:'America/Sao_Paulo' } });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(JSON.parse(payload)));
  assert.equal(web.length, 1);
  assert.deepEqual(web[0].corpo.split('\n'), ['Casa passou R$ 8 mil do orçamento', 'Fundação passou R$ 8 mil do previsto']);
  assert.equal('avisosOrcamento' in web[0], false, 'memória não vai no payload');
  assert.deepEqual(gravacoes, [['perfis/ana', { avisosOrcamento:ESTADO_ORC }]]);
});

test('orçamento: mesma memória não reenvia nem regrava', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{ avisosOrcamento:ESTADO_ORC } });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(payload));
  assert.deepEqual(web, []);
  assert.deepEqual(gravacoes, []);
});

test('orçamento: sem perfil não avisa e não cria perfil', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:null });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(payload));
  assert.deepEqual(web, []);
  assert.deepEqual(gravacoes, []);
});

test('orçamento: envio falhou em todos os aparelhos, memória fica como estava', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{} });
  await rodar(db, async()=>{ throw Object.assign(new Error('x'), { statusCode:500 }); });
  assert.deepEqual(gravacoes, []);
});

test('orçamento: descida grava a memória mesmo sem nada a dizer', async()=>{
  const folgado = structuredClone(DADOS_ORC);
  folgado.obras[0].orcamento.topicos.fundacao = 200000;
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:folgado, perfil:{ avisosOrcamento:ESTADO_ORC } });
  await rodar(db, async()=>{ throw new Error('não deveria enviar'); });
  assert.deepEqual(gravacoes, [['perfis/ana', { avisosOrcamento:{} }]]);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/enviar.test.cjs`
Expected: FAIL nos testes novos de orçamento.

- [ ] **Step 3: Implementar em `enviar.js`**

Importar `estadoOrcamento` junto de `montaResumo`. Dentro do laço, trocar a leitura do perfil e o `montaResumo` por:

```js
    const snap = await db.doc('dados/' + uid).get();
    const perfil = await db.doc('perfis/' + uid).get();
    const dados = snap.data();
    const pdados = perfil.data() || {};
    /* Memória dos avisos de orçamento (regra em resumo.js). Só com perfil
       existente: update nunca cria documento, e sem memória não há aviso
       (silêncio é melhor que repetir todo dia). */
    const temPerfil = perfil.exists === true;
    const memoria = pdados.avisosOrcamento;
    const anterior = temPerfil ? (memoria && typeof memoria === 'object' && !Array.isArray(memoria) ? memoria : {}) : null;
    const estado = temPerfil ? estadoOrcamento(dados) : null;
    const gravaMemoria = async()=>{
      if(!estado || mesmoEstado(estado, anterior)) return;
      try{ await perfil.ref.update({ avisosOrcamento: estado }); }
      catch(err){ log.error(uid + ': falha ao gravar avisos de orçamento ' + (err.code || err.message)); }
    };
    const resumo = montaResumo(dados, hojeNoFuso(pdados.tz, agora), periodo, anterior);
    if(!resumo){ await gravaMemoria(); log.info(uid + ': nada a dizer'); continue; }
```

Contar entregas: `let entregues = 0;` antes dos dois laços; `entregues++` junto de cada `r.enviados++`; depois dos dois laços: `if(entregues > 0) await gravaMemoria();`.

Função no topo do arquivo:

```js
/* Compara a memória de avisos sem depender da ordem das chaves. */
function mesmoEstado(a, b){
  const lista = o => Object.keys(o || {}).sort().map(k => k + '=' + o[k]).join('|');
  return lista(a) === lista(b);
}
```

- [ ] **Step 4: Rules — testes que provam que o campo do servidor convive com o cliente** — em `tests/rules.test.mjs`, dentro de `describe('perfis/{uid} — CPF e plano', ...)`:

```js
  test('avisosOrcamento gravado pelo servidor não impede o cliente de salvar nome e fuso', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z', avisosOrcamento: { 'o1|total': 'perto' },
    }));
    await assertSucceeds(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { email: ANA.email, nome: 'Ana' }));
    await assertSucceeds(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { tz: 'America/Manaus' }));
  });

  test('cliente NÃO grava avisosOrcamento', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { avisosOrcamento: {} }));
  });
```

No `firestore.rules`, no comentário do bloco `perfis/{uid}`, acrescentar uma linha (sem mudar regra):

```
       'avisosOrcamento' (memória do aviso de orçamento do push) também é só do Admin SDK:
       fica fora da lista do update, então o cliente não a grava e ela não atrapalha o update dele.
```

- [ ] **Step 5: README** — em `notificacoes/README.md`, seção nova "## Avisos de orçamento" antes de "## Avisos": quando avisa (tópico ou total a partir de 90% ou passou; obra vendida não), a regra de não repetir (uma vez por subida de nível, memória em `perfis/{uid}.avisosOrcamento`, descida esquece), por que não em `push/{uid}` (rules `hasOnly(['subs','tokens'])`), sem perfil = sem aviso, grava só depois de ao menos uma entrega, e que apagar a conta apaga a memória junto do perfil. Nenhum deploy de rules é necessário (mudança só de comentário).

- [ ] **Step 6: Rodar**

Run: `npm run test:unit && npm run test:rules`
Expected: PASS nos dois.

---

### Task 5: card, lista por tópico e Início (UI)

**Files:**
- Modify: `app.js` (helpers perto de `moneyShort`; `renderInicio`; `renderObra`)
- Modify: `styles.css` (bloco novo "orçamento previsto × real", antes de `/* ===== conteúdo no padrão iOS`)
- Create: `tests/browser/orcamento.cjs`
- Modify: `tests/browser/rodar.cjs` (rodar a suíte nova depois de `mobile.cjs`)

**Interfaces:**
- Consumes: `OBRA_CALC.orcamentoObra` (Task 1), `o.orcamento` normalizado (Task 2).
- Produces (usados pela Task 6): `moneyCurto(n)`, `nomeTopico(id)`, `pintaBarrasOrc(escopo)`, botões `#oOrcEditar` (com orçamento) e `#oOrcDefinir` (sem orçamento, obra não vendida), ambos ligados a `formOrcamento(o.id)` — que a Task 6 cria. Nesta task, deixe um stub no fim da seção de formulários: `function formOrcamento(obraId){ /* Task 6 */ }` (a Task 6 substitui).

- [ ] **Step 1: Suíte de browser (falha)** — criar `tests/browser/orcamento.cjs`:

```js
/* Orçamento previsto × real com dados sintéticos: sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
const assert=require('node:assert/strict');
const path=require('node:path');
const os=require('node:os');
const {chromium}=require('playwright');

const gasto=(topico,valor,i,data='2026-03-01')=>({id:'g'+topico+i,topico,valor,data,descricao:'x',pagamento:'pix'});
const OBRAS=[
  {id:'a',nome:'Casa Alphaville 12',dataInicio:'2026-02-03',
   orcamento:{modo:'topicos',topicos:{terreno:180000,fundacao:90000,estrutura:250000,eletrica:100000,acabamento:180000}},
   gastos:[['terreno',180000],['fundacao',98000],['estrutura',231000],['eletrica',58000],['acabamento',45000],['hidraulica',12000]].map(([t,v],i)=>gasto(t,v,i))},
  {id:'b',nome:'Sobrado Granja Viana',dataInicio:'2026-01-10',orcamento:{modo:'total',total:1008000},gastos:[gasto('estrutura',1048000,0)]},
  {id:'c',nome:'Casa Tamboré 5',dataInicio:'2025-05-01',gastos:[gasto('terreno',934200,0,'2025-06-01')]},
];
const contraste=(a,b)=>{const lum=c=>{const [r,g,bb]=c.map(v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);});return 0.2126*r+0.7152*g+0.0722*bb;};
  const [l1,l2]=[lum(a),lum(b)].sort((x,y)=>y-x);return (l1+0.05)/(l2+0.05);};

async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
  const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width,height:852}});
  await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
  await ctx.route('https://**/*',r=>r.abort());
  await ctx.addInitScript(({tema,skin})=>{
    sessionStorage.setItem('splashVista','1');
    localStorage.setItem('mo_tema',tema); if(skin==='azul') localStorage.setItem('mo_skin','azul');
    window.errosOrc=[];
    addEventListener('error',e=>errosOrc.push(e.message));
    addEventListener('securitypolicyviolation',e=>errosOrc.push(e.violatedDirective));
    window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=>'ocioso'};
  },{tema,skin});
  const page=await ctx.newPage();
  await page.goto('http://localhost:8123');
  await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
    db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});renderAll();},OBRAS);
  return {ctx,page};
}

(async()=>{
  const browser=await chromium.launch();
  try{
    const {ctx,page}=await abrir(browser);
    // Início
    const linha=nome=>page.locator('#obrasList li').filter({hasText:nome});
    assert.match(await linha('Casa Alphaville 12').locator('.orc-mini').textContent(),/77% do orçamento/);
    const sobrado=linha('Sobrado Granja Viana').locator('.orc-mini');
    assert.match(await sobrado.textContent(),/104% · passou R\$ 40 mil/);
    assert.equal(await sobrado.locator('.alerta').count(),1);
    assert.equal(await linha('Casa Tamboré 5').locator('.orc-mini').count(),0,'obra sem orçamento fica igual');

    // Obra com orçamento por tópico
    await page.evaluate(()=>openObra('a'));
    const card=page.locator('#oOrc');
    const txt=(await card.textContent()).replace(/\s+/g,' ');
    assert.match(txt,/R\$\s612\.000,00 de R\$\s800\.000,00/);
    assert.match(txt,/77% usado/);
    assert.match(txt,/sobra R\$\s188\.000,00/);
    assert.equal((await card.locator('.orc-pill').textContent()).trim(),'dentro do previsto');
    const largura=await card.locator('.orc-barra i').evaluate(i=>i.style.width);
    assert.equal(largura,'77%');
    const nomes=await page.locator('.orc-topicos .orc-item .orc-nome').allTextContents();
    assert.deepEqual(nomes,['Fundação','Terreno','Estrutura','Elétrica','Acabamento','Fora do orçamento']);
    const item=nome=>page.locator('.orc-topicos .orc-item').filter({has:page.locator('.orc-nome',{hasText:nome})});
    assert.equal((await item('Fundação').locator('.orc-frase').textContent()).trim(),'Passou R$ 8 mil do previsto');
    assert.equal(await item('Fundação').locator('.orc-frase.alerta').count(),1);
    assert.equal(await item('Fundação').locator('.orc-barra.alerta').count(),1);
    assert.equal((await item('Estrutura').locator('.orc-frase').textContent()).trim(),'Faltam R$ 19 mil — 92%');
    assert.equal((await item('Terreno').locator('.orc-frase').textContent()).trim(),'Chegou ao previsto — 100%');
    assert.equal(await item('Elétrica').locator('.orc-frase').count(),0);
    assert.equal(await item('Elétrica').locator('.orc-barra.alerta').count(),0);
    assert.match(await item('Fora do orçamento').textContent(),/R\$ 12 mil[\s\S]*Encanamento/);
    assert.equal(await page.locator('#oOrcEditar').count(),1);
    assert.equal(await page.locator('#oOrcDefinir').count(),0);
    assert.equal(await page.locator('.kpis .kpi').count(),4,'KPIs continuam');
    // tocar no tópico abre a folha do tópico que já existe
    await item('Fundação').click();
    assert.match(await page.locator('#sheet').textContent(),/Fundação/);
    await page.evaluate(()=>closeSheet());

    // Obra com orçamento total estourado
    await page.evaluate(()=>openObra('b'));
    assert.equal((await page.locator('#oOrc .orc-pill').textContent()).trim(),'passou do previsto');
    assert.match((await page.locator('#oOrc .orc-rodape').textContent()).replace(/\s+/g,' '),/104% usado passou R\$\s40\.000,00/);
    assert.equal(await page.locator('.orc-topicos').count(),0);

    // Obra sem orçamento: sem card, só a porta de entrada
    await page.evaluate(()=>openObra('c'));
    assert.equal(await page.locator('#oOrc').count(),0);
    assert.equal(await page.locator('#oOrcDefinir').count(),1);

    // Larguras e temas: sem rolagem horizontal
    for(const width of [320,393,430,768,1440]){
      await page.setViewportSize({width,height:852});
      for(const light of [false,true]){
        await page.evaluate(light=>{aplicaTema(light);showView('inicio');renderAll();},light);
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`início ${width}`);
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-orc-inicio-${light?'claro':'escuro'}.png`)});
        await page.evaluate(()=>openObra('a'));
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`obra ${width}`);
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-orc-obra-${light?'claro':'escuro'}.png`),fullPage:true});
      }
    }
    assert.deepEqual(await page.evaluate(()=>errosOrc),[]);
    await ctx.close();

    // Contraste do texto novo nos 4 combos tema × skin
    for(const tema of ['escuro','claro']) for(const skin of ['esmeralda','azul']){
      const {ctx,page}=await abrir(browser,{tema,skin});
      await page.evaluate(()=>openObra('a'));
      const medidas=await page.evaluate(()=>['.orc-frase.alerta','#oOrc .orc-pill','#oOrc .orc-rodape','.orc-val','.orc-fora .orc-frase'].map(sel=>{
        const el=document.querySelector(sel); const cs=getComputedStyle(el);
        let fundo=cs.backgroundColor,no=el;
        while(/rgba\(0, 0, 0, 0\)|transparent/.test(fundo)&&no.parentElement){no=no.parentElement;fundo=getComputedStyle(no).backgroundColor;}
        return {sel,cor:cs.color,fundo};
      }));
      const rgb=s=>s.match(/[\d.]+/g).slice(0,3).map(Number);
      const base=rgb(await page.evaluate(()=>getComputedStyle(document.body).backgroundColor));
      for(const m of medidas){
        const f=m.fundo.match(/[\d.]+/g).map(Number); const a=f[3]===undefined?1:f[3];
        const fundo=[0,1,2].map(i=>f[i]*a+base[i]*(1-a));
        const c=contraste(rgb(m.cor),fundo);
        assert.ok(c>=4.5,`${tema}/${skin} ${m.sel}: contraste ${c.toFixed(2)}`);
      }
      await ctx.close();
    }
    console.log('ok - orçamento: card, lista por tópico, início, 5 larguras, 2 temas e contraste nos 4 combos');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/browser/rodar.cjs`, depois de `await run('tests/browser/mobile.cjs');`: `await run('tests/browser/orcamento.cjs');`.

- [ ] **Step 2: Rodar e ver falhar**

Run (dois terminais): `node tests/browser/servidor.cjs` e `node tests/browser/orcamento.cjs`
Expected: FAIL em `.orc-mini` não encontrado.

- [ ] **Step 3: Helpers em `app.js`** — logo depois de `moneyShort`:

```js
/* "R$ 8,0 mil" → "R$ 8 mil": nas frases do orçamento o ",0" só ocupa espaço */
const moneyCurto = n => moneyShort(n).replace(/,0+ (mil|mi)$/, ' $1');
const semCifrao = s => s.replace(/^R\$\s/, '');
```

E perto de `TOP_MAP`:

```js
const nomeTopico = id => (TOP_MAP()[id] || {nm:id}).nm; // tópico próprio apagado cai no id
```

- [ ] **Step 4: Render do orçamento em `app.js`** — funções novas antes de `renderObra`:

```js
/* ===== ORÇAMENTO previsto × real =====
   Um número por vez: o card mostra gasto de previsto, barra e sobra; o detalhe
   fica na lista por tópico. Verde-marca abaixo de 90%, âmbar daí pra cima. */
const ORC_PILL = { ok:'dentro do previsto', perto:'perto do limite', passou:'passou do previsto' };
function barraOrcHtml(pct, nivel, extra){
  return `<div class="orc-barra${extra ? ' ' + extra : ''}${nivel === 'ok' ? '' : ' alerta'}" aria-hidden="true"><i data-pct="${Math.max(0, Math.min(100, pct))}"></i></div>`;
}
/* largura via CSSOM: a CSP proíbe style="" no HTML */
function pintaBarrasOrc(escopo){
  escopo.querySelectorAll('.orc-barra i[data-pct]').forEach(i => { i.style.width = i.dataset.pct + '%'; });
}
function fraseTopicoOrc(t){
  if(t.nivel === 'passou') return `<div class="orc-frase alerta">Passou ${moneyCurto(-t.sobra)} do previsto</div>`;
  if(t.nivel === 'perto') return `<div class="orc-frase">${t.sobra > 0.005 ? `Faltam ${moneyCurto(t.sobra)} — ${t.pct}%` : `Chegou ao previsto — ${t.pct}%`}</div>`;
  return '';
}
function orcamentoHtml(o, orc){
  const passou = orc.nivel === 'passou';
  const card = `
    <div class="panel orc-card" id="oOrc">
      <div class="orc-topo"><span class="orc-rotulo">Orçamento</span>
        <span class="orc-pill${orc.nivel === 'ok' ? '' : ' alerta'}">${ORC_PILL[orc.nivel]}</span></div>
      <div class="orc-num">${money(orc.gasto)} <small>de ${money(orc.previsto)}</small></div>
      ${barraOrcHtml(orc.pct, orc.nivel)}
      <div class="orc-rodape"><span><b>${orc.pct}%</b> usado</span>
        <span>${passou ? 'passou' : 'sobra'} <b>${money(Math.abs(orc.sobra))}</b></span></div>
    </div>`;
  let lista = '';
  if(orc.modo === 'topicos'){
    const comGasto = new Set(o.gastos.map(g => g.topico));
    const linhas = orc.topicos.map(t => `
      <li class="orc-item"${comGasto.has(t.id) ? ` data-top="${escapeHtml(t.id)}" role="button" tabindex="0"` : ''}>
        <div class="orc-linha"><span class="orc-nome">${escapeHtml(nomeTopico(t.id))}</span>
          <span class="orc-val"><b>${moneyCurto(t.gasto)}</b> / ${semCifrao(moneyCurto(t.previsto))}</span></div>
        ${barraOrcHtml(t.pct, t.nivel, 'fina')}${fraseTopicoOrc(t)}
      </li>`).join('');
    const fora = orc.fora.length ? `
      <li class="orc-item orc-fora">
        <div class="orc-linha"><span class="orc-nome">Fora do orçamento</span><span class="orc-val"><b>${moneyCurto(orc.foraTotal)}</b></span></div>
        <div class="orc-frase">${escapeHtml(orc.fora.map(f => nomeTopico(f.id)).join(', '))}</div>
      </li>` : '';
    lista = `<h2 class="orc-secao">Por tópico</h2><div class="panel orc-topicos"><ul class="orc-lista">${linhas}${fora}</ul></div>`;
  }
  return card + lista + `<button class="btn ghost orc-editar" id="oOrcEditar">${ICON('alvo')} Editar orçamento</button>`;
}
```

Em `renderObra`:
- depois de `const lucro = ...`: `const orc = OBRA_CALC.orcamentoObra(o);`
- em `acoes`, logo depois de `let acoes = '<div class="obra-actions">';` e dos botões de fase, antes de `if(o.gastos.length)`: `if(!orc && o.fase !== 'vendida') acoes += \`<button class="btn ghost" id="oOrcDefinir">${ICON('alvo')} Definir orçamento</button>\`;`
- `$('#obraBody').innerHTML = head + (orc ? orcamentoHtml(o, orc) : '') + resumo + acoes + afazeres + graficos + lanc;`
- depois de `fitNums(...)`: `pintaBarrasOrc($('#obraBody'));`
- junto dos `on(...)`: `on('#oOrcEditar', ()=>formOrcamento(o.id)); on('#oOrcDefinir', ()=>formOrcamento(o.id));` e o toque nos tópicos:

```js
  $('#obraBody').querySelectorAll('.orc-item[data-top]').forEach(li => {
    const abre = () => sheetTopico(o.id, li.dataset.top);
    li.onclick = abre;
    li.addEventListener('keydown', e => { if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); abre(); } });
  });
```

Em `renderInicio`, dentro do `forEach`, antes de `li.innerHTML`:

```js
    const orc = OBRA_CALC.orcamentoObra(o);
    const orcLinha = orc ? `<div class="orc-mini">${barraOrcHtml(orc.pct, orc.nivel, 'mini')}<span${orc.nivel === 'passou' ? ' class="alerta"' : ''}>${orc.nivel === 'passou' ? `${orc.pct}% · passou ${moneyCurto(-orc.sobra)}` : `${orc.pct}% do orçamento`}</span></div>` : '';
```

e `${orcLinha}` logo depois da `<div class="s">…</div>` dentro de `.li-main`. Depois do `forEach`: `pintaBarrasOrc(list);`.

Stub no fim da seção de formulários (perto de `formNovaObra`): `function formOrcamento(obraId){ /* folha na Task 6 */ }`.

- [ ] **Step 5: CSS** — em `styles.css`, antes de `/* ===== conteúdo no padrão iOS (celular) =====`:

```css
/* ===== orçamento previsto × real =====
   Verde-marca abaixo de 90%, âmbar daí pra cima. Nunca vermelho (PRODUCT.md). */
  .orc-card .orc-topo{display:flex;justify-content:space-between;align-items:center;gap:8px}
  .orc-rotulo{font-size:14px;color:var(--muted);font-weight:650}
  .orc-pill{font-size:12.5px;font-weight:650;padding:3px 10px;border-radius:999px;background:var(--green-soft);color:var(--green);white-space:nowrap}
  .orc-pill.alerta{background:var(--amber-soft);color:var(--amber)}
  .orc-num{font-size:28px;font-weight:750;letter-spacing:-.02em;line-height:1.15;margin-top:6px;font-variant-numeric:tabular-nums;overflow-wrap:anywhere}
  .orc-num small{font-size:16px;font-weight:600;letter-spacing:0;color:var(--muted);white-space:nowrap}
  .orc-barra{height:12px;border-radius:999px;background:var(--surface-2);overflow:hidden;margin:14px 0 10px}
  .orc-barra i{display:block;height:100%;width:0;border-radius:999px;background:linear-gradient(90deg,var(--brand),var(--accent))}
  .orc-barra.alerta i{background:var(--amber)}
  .orc-barra.fina{height:8px;margin:8px 0 0}
  .orc-barra.mini{height:6px;margin:0;flex:1;max-width:120px}
  .orc-rodape{display:flex;justify-content:space-between;flex-wrap:wrap;gap:4px 12px;font-size:15px;color:var(--muted);font-variant-numeric:tabular-nums}
  .orc-rodape b{color:var(--text);font-weight:650}
  .orc-secao{font-size:15px;font-weight:650;color:var(--muted);margin:4px 4px 8px}
  .orc-lista{list-style:none}
  .orc-item{padding:12px 0;border-top:1px solid var(--border)}
  .orc-item:first-child{border-top:0;padding-top:2px}
  .orc-item:last-child{padding-bottom:2px}
  .orc-item[role="button"]{cursor:pointer;-webkit-tap-highlight-color:transparent}
  .orc-item[role="button"]:active{opacity:.6}
  .orc-item[role="button"]:focus-visible{outline:2px solid var(--brand);outline-offset:2px;border-radius:8px}
  .orc-linha{display:flex;justify-content:space-between;align-items:baseline;gap:10px}
  .orc-nome{font-size:16px;font-weight:600;min-width:0;overflow-wrap:anywhere}
  .orc-val{font-size:15px;color:var(--muted);font-variant-numeric:tabular-nums;white-space:nowrap}
  .orc-val b{color:var(--text);font-weight:650}
  .orc-frase{font-size:14px;color:var(--muted);margin-top:6px}
  .orc-frase.alerta{color:var(--amber)}
  .btn.orc-editar{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;margin-bottom:14px}
  .orc-mini{display:flex;align-items:center;gap:8px;margin-top:6px;font-size:13.5px;color:var(--muted);font-variant-numeric:tabular-nums}
  .orc-mini .alerta{color:var(--amber)}
```

- [ ] **Step 6: Rodar**

Run: `node tests/browser/orcamento.cjs` (servidor no ar) e `npm run test:unit`
Expected: `ok - orçamento: ...` e unit PASS. Abrir os PNGs em `$TMPDIR/custta-orc-*.png` e conferir visualmente contra o mockup.

---

### Task 6: folha "Orçamento da obra" e campo na Nova obra

**Files:**
- Modify: `app.js` (substituir o stub `formOrcamento`; `formNovaObra`)
- Modify: `styles.css` (estilos da folha, no bloco do orçamento)
- Modify: `tests/browser/orcamento.cjs` (novos passos antes do teste de larguras)

**Interfaces:**
- Consumes: `formOrcamento` chamado por `#oOrcEditar`/`#oOrcDefinir` (Task 5), `topicos()`, `maskMoney`, `parseNum`, `OBRA_CALC.numParaCampo`, `OBRA_CONFIRM.perguntar(msg, {confirmar})`, `openSheet`, `closeSheet`, `save`, `renderAll`.
- Produces: `o.orcamento` gravado no formato da Task 2.

- [ ] **Step 1: Testes (falham)** — em `tests/browser/orcamento.cjs`, depois do bloco "Obra sem orçamento" e antes de "Larguras e temas":

```js
    // Folha: definir só o total numa obra sem orçamento
    await page.locator('#oOrcDefinir').click();
    assert.equal((await page.locator('#sheet .seg button.on').textContent()).trim(),'Só o total');
    assert.equal(await page.locator('#orcTopWrap').isHidden(),true);
    await page.locator('#orcTotal').fill('500000');
    assert.equal(await page.locator('#orcTotal').inputValue(),'500.000');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>obraById('c').orcamento),{modo:'total',total:500000});
    assert.equal(await page.locator('#oOrc').count(),1);

    // Folha por tópico: abre no modo salvo, soma ao vivo, salva só valores > 0
    await page.evaluate(()=>{db.config.topicosCustom=[{id:'c_portao',nm:'Portão',ic:'etiqueta'}];openObra('a');});
    await page.locator('#oOrcEditar').click();
    assert.equal((await page.locator('#sheet .seg button.on').textContent()).trim(),'Por tópico');
    assert.equal(await page.locator('#sheet .seg button.on').getAttribute('aria-pressed'),'true');
    const somaTxt=async()=>(await page.locator('#orcSoma').textContent()).replace(/\s/g,' ');
    assert.equal(await somaTxt(),'R$ 800.000,00');
    assert.match(await page.locator('#orcTopWrap').textContent(),/Tópico sem valor não entra na comparação\./);
    const campo=id=>page.locator(`#orcTopWrap input[data-top="${id}"]`);
    assert.equal(await campo('fundacao').inputValue(),'90.000,00');
    assert.equal(await campo('hidraulica').getAttribute('placeholder'),'sem valor');
    assert.equal(await campo('c_portao').count(),1,'tópico próprio também tem campo');
    await campo('fundacao').fill('100000');
    assert.equal(await somaTxt(),'R$ 810.000,00');
    await campo('eletrica').fill('');
    assert.equal(await somaTxt(),'R$ 710.000,00');
    await campo('c_portao').fill('5.000,50');
    for(const fonte of await page.locator('#sheet input').evaluateAll(els=>els.map(e=>parseFloat(getComputedStyle(e).fontSize))))
      assert.ok(fonte>=16,'campo com fonte < 16px dá zoom no iOS');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>obraById('a').orcamento),
      {modo:'topicos',topicos:{terreno:180000,fundacao:100000,estrutura:250000,acabamento:180000,c_portao:5000.5}});

    // Trocar pra "Só o total" e salvar vazio tira o orçamento
    await page.locator('#oOrcEditar').click();
    await page.locator('#sheet .seg button',{hasText:'Só o total'}).click();
    assert.equal(await page.locator('#orcTotal').isVisible(),true);
    await page.locator('#orcTotal').fill('');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>'orcamento' in obraById('a')),false);
    assert.equal(await page.locator('#oOrcDefinir').count(),1);

    // Tirar orçamento pede confirmação
    await page.evaluate(()=>openObra('b'));
    await page.locator('#oOrcEditar').click();
    await page.locator('#orcTirar').click();
    await page.locator('dialog[open] button',{hasText:'Tirar orçamento'}).click();
    await page.waitForFunction(()=>!('orcamento' in obraById('b')));
    assert.equal(await page.locator('#oOrc').count(),0);

    // Nova obra com orçamento total
    await page.evaluate(()=>formNovaObra());
    await page.locator('#fNome').fill('Casa Nova');
    await page.locator('#fArea').fill('200');
    await page.locator('#fOrc').fill('300000');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>db.obras.find(o=>o.nome==='Casa Nova').orcamento),{modo:'total',total:300000});
    assert.equal(await page.locator('#oOrc').count(),1);
    // Nova obra sem orçamento: nada muda
    await page.evaluate(()=>formNovaObra());
    await page.locator('#fNome').fill('Casa Sem');
    await page.locator('#fArea').fill('100');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>'orcamento' in db.obras.find(o=>o.nome==='Casa Sem')),false);

    // Folha a 320px: nada vaza na horizontal
    await page.setViewportSize({width:320,height:640});
    await page.evaluate(()=>{db=normaliza({obras:structuredClone(window.OBRAS_TESTE),config:{taxaMensal:1,topicosCustom:[]}});openObra('a');formOrcamento('a');});
    assert.ok(await page.locator('#sheet').evaluate(e=>e.scrollWidth<=e.clientWidth),'folha não rola na horizontal');
    await page.screenshot({path:path.join(os.tmpdir(),'custta-orc-folha-320.png')});
    await page.evaluate(()=>closeSheet());
    await page.setViewportSize({width:393,height:852});
    await page.evaluate(()=>{formOrcamento('a');});
    await page.screenshot({path:path.join(os.tmpdir(),'custta-orc-folha.png')});
    await page.evaluate(()=>{closeSheet();db=normaliza({obras:structuredClone(window.OBRAS_TESTE),config:{taxaMensal:1,topicosCustom:[]}});renderAll();});
```

E em `abrir(...)`, no `page.evaluate` que carrega os dados, guardar uma cópia: `window.OBRAS_TESTE=structuredClone(obras);` (antes do `normaliza`), para os blocos acima restaurarem o estado original antes do teste de larguras.

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/browser/orcamento.cjs`
Expected: FAIL em `#sheet .seg button.on` (stub vazio).

- [ ] **Step 3: Implementar `formOrcamento`** — substituir o stub:

```js
/* Folha do orçamento: só o total, ou valor por tópico (fixos e próprios).
   Grava só o modo ativo; salvar tudo vazio tira o orçamento da obra. */
function formOrcamento(obraId){
  const o = obraById(obraId);
  if(!o) return;
  const atual = o.orcamento || null;
  let modo = atual && atual.modo === 'topicos' ? 'topicos' : 'total';
  const valTop = (atual && atual.modo === 'topicos' && atual.topicos) || {};
  const campos = topicos().map(t => `
      <label class="orc-campo"><span>${escapeHtml(t.nm)}</span>
        <input data-top="${escapeHtml(t.id)}" inputmode="decimal" placeholder="sem valor" autocomplete="off" value="${valTop[t.id] ? OBRA_CALC.numParaCampo(valTop[t.id]) : ''}"></label>`).join('');
  openSheet(`
    <h3>Orçamento da obra</h3>
    <div class="seg" role="group" aria-label="Tipo de orçamento">
      <button type="button" data-modo="total">Só o total</button>
      <button type="button" data-modo="topicos">Por tópico</button>
    </div>
    <div class="field" id="orcTotalWrap"><label for="orcTotal">Orçamento total</label>
      <div class="money"><b>R$</b><input id="orcTotal" inputmode="decimal" placeholder="0,00" autocomplete="off" value="${atual && atual.modo === 'total' ? OBRA_CALC.numParaCampo(atual.total) : ''}"></div></div>
    <div id="orcTopWrap">
      <div class="orc-campos">${campos}</div>
      <div class="orc-soma"><span>Total</span><b id="orcSoma"></b></div>
      <p class="orc-dica">Tópico sem valor não entra na comparação.</p>
    </div>
    ${atual ? '<button type="button" class="btn ghost orc-tirar" id="orcTirar">Tirar orçamento</button>' : ''}
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  const entradas = [...sheet.querySelectorAll('#orcTopWrap input[data-top]')];
  const pintaSoma = () => {
    $('#orcSoma').textContent = money(entradas.reduce((s, i) => s + Math.max(0, parseNum(i.value)), 0));
  };
  const aplicaModo = m => {
    modo = m;
    sheet.querySelectorAll('.seg button').forEach(b => {
      const on = b.dataset.modo === m;
      b.classList.toggle('on', on);
      b.setAttribute('aria-pressed', String(on));
    });
    $('#orcTotalWrap').classList.toggle('hidden', m !== 'total');
    $('#orcTopWrap').classList.toggle('hidden', m !== 'topicos');
  };
  sheet.querySelectorAll('.seg button').forEach(b => { b.onclick = () => aplicaModo(b.dataset.modo); });
  maskMoney('#orcTotal');
  entradas.forEach(i => { maskMoney(i); i.addEventListener('input', pintaSoma); });
  aplicaModo(modo);
  pintaSoma();
  const aplica = novo => {
    const oo = obraById(obraId);
    if(oo){ if(novo) oo.orcamento = novo; else delete oo.orcamento; save(); }
    closeSheet(); renderAll();
  };
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = () => {
    if(modo === 'total'){
      const total = parseNum($('#orcTotal').value);
      aplica(total > 0 ? { modo:'total', total } : null);
      return;
    }
    const tops = {};
    entradas.forEach(i => { const v = parseNum(i.value); if(v > 0) tops[i.dataset.top] = v; });
    aplica(Object.keys(tops).length ? { modo:'topicos', topicos:tops } : null);
  };
  const tirar = $('#orcTirar');
  if(tirar) tirar.onclick = async () => {
    if(await OBRA_CONFIRM.perguntar('Tirar o orçamento desta obra? Os gastos continuam como estão.', { confirmar:'Tirar orçamento' })) aplica(null);
  };
}
```

- [ ] **Step 4: Nova obra** — em `formNovaObra`, depois do campo `fEst`:

```html
    <div class="field"><label for="fOrc">Orçamento total (opcional)</label><div class="money"><b>R$</b><input id="fOrc" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>
```

`maskMoney('#fOrc');` junto de `maskMoney('#fEst');`. No `cSave`, depois de montar `o`: `const orcTotal = parseNum($('#fOrc').value); if(orcTotal > 0) o.orcamento = { modo:'total', total:orcTotal };` (antes de `db.obras.push(o)`).

- [ ] **Step 5: CSS da folha** — no bloco do orçamento em `styles.css`:

```css
  .sheet .seg button{min-height:44px;font-size:15px}
  .orc-campos{background:var(--surface-2);border-radius:14px;padding:4px 14px}
  .orc-campo{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:8px 0;border-top:1px solid var(--border)}
  .orc-campo:first-child{border-top:0}
  .orc-campo>span{font-size:16px;min-width:0;overflow-wrap:anywhere}
  .orc-campo input{flex:0 1 150px;width:150px;min-width:0;text-align:right;background:var(--surface-solid);border:1px solid transparent;color:var(--text);border-radius:11px;padding:11px 12px;font-size:16px;font-family:inherit;font-variant-numeric:tabular-nums;outline:none}
  .orc-campo input:focus{border-color:var(--brand);box-shadow:0 0 0 3px var(--brand-soft)}
  .orc-campo input::placeholder{color:var(--muted);opacity:1}
  .orc-soma{display:flex;justify-content:space-between;align-items:baseline;gap:12px;padding:14px 16px;border-radius:14px;background:var(--brand-soft);margin-top:12px}
  .orc-soma span{font-size:15px;font-weight:650}
  .orc-soma b{font-size:24px;font-weight:750;font-variant-numeric:tabular-nums}
  .orc-dica{font-size:13.5px;color:var(--muted);text-align:center;margin:8px 0 12px}
  .btn.orc-tirar{width:100%;margin:4px 0 6px;color:var(--red)}
  @media screen and (max-width:899px){ html body .btn.ghost.orc-tirar{background:var(--surface-2);color:var(--red)} }
```

- [ ] **Step 6: Rodar tudo**

Run: `npm run test:unit` e `node tests/browser/orcamento.cjs` (servidor no ar), depois `npm run test:browser`.
Expected: PASS. Conferir `custta-orc-folha.png` e `custta-orc-folha-320.png`.

---

## Depois das tasks (controlador)

- Revisão do branch inteiro; `npm run test:unit`, `npm run test:rules`, `npm run test:browser`.
- WebKit headed (Playwright, `headless:false`, `serviceWorkers:'block'`, CSP sem `upgrade-insecure-requests` via route) abrindo a folha, focando campos de tópico e conferindo que a folha não sobe cortada.
- Push do branch, PR, checks, prévia da Vercel com `CLOUD` falso (`Object.defineProperty` não gravável via `--init-script`) no agent-browser (`set device "iPhone 16 Pro"`), temas claro/escuro e skin azul.
