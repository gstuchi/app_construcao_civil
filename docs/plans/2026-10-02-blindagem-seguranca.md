# Blindagem de segurança — plano de implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para implementar este plano tarefa por tarefa. Os passos usam checkbox (`- [ ]`).

**Objetivo:** provar com teste que dado do usuário nunca vira HTML no Custta, fechar os últimos pontos de escape que dependiam de validação em outro arquivo e tirar de produção os arquivos de desenvolvimento que a Vercel serve hoje.

**Arquitetura:** três mudanças independentes, cada uma com teste próprio: uma suíte de navegador que injeta um blob hostil pelo caminho real de leitura e percorre todas as telas; escape nos cinco trechos de template que ainda interpolam dado do blob cru; `.vercelignore` + redirecionamento para que o deploy leve só o app.

**Tecnologias:** JavaScript puro (sem build), Playwright (Chromium), `node:test`/`assert`, Vercel (`.vercelignore`, `vercel.json`).

**Design:** aprovado na conversa (caminho bounded, sem arquivo de spec). O contexto que importa está na seção "Contexto" abaixo.

## Contexto (o que a auditoria de 02/10/2026 encontrou)

- **XSS:** `app.js` escapa todo texto do usuário com `escapeHtml`, `dados.js` (`normaliza`) valida o blob antes de qualquer render (datas `AAAA-MM-DD`, números, fase, parcela inteira) e a CSP não tem `unsafe-inline` (header na web, `<meta>` no app nativo via `scripts/build-www.mjs`). O teste atual (`tests/xss.test.cjs`) é só estático. Sobram cinco trechos que interpolam dado do blob sem escape: hoje são seguros **só** porque `normaliza` garante o tipo — `fmtData`, `String(o.areaM2)` (2×), `m.slice(2,4)` no filtro de mês e `g.parcela.n/de` (3×).
- **Rotas:** `/api/push-diario` responde 503 sem `CRON_SECRET` e compara o segredo em tempo constante; Firestore nega leitura sem login; não há RTDB nem Storage; o cron só faz POST para hosts de push conhecidos. **Achado:** a Vercel serve a raiz inteira — `CLAUDE.md`, `AGENTS.md`, `PRODUCT.md`, `tests/`, `scripts/`, `notificacoes/`, `.github/`, `firestore.rules`, `firebase.json`, `.firebaserc`, `capacitor.config.json` respondem 200 em `custta.com.br`.
- **Chaves:** nenhum segredo no código nem no histórico (389 commits). Só as `apiKey` do Firebase (web e iOS), públicas por design, ambas bloqueadas para APIs pagas; proteção contra enumeração de e-mail ligada.
- **Fora deste plano, de propósito:** `npm audit fix` nas dependências do cron (sobe `gaxios` 6→7 por baixo do `firebase-admin`, sem teste ponta a ponta do push; os alertas não são exploráveis neste uso) e ajustes de console (restrição de app na chave iOS, domínios permitidos no Sentry). Vão como recomendação na entrega.

## Restrições globais

- Repositório **público**: nada de segredo, e nada de passo a passo de exploração em commit, PR ou comentário.
- Commits com autor `Giovani Stuchi <stuchigiovani@gmail.com>` (já é o `user.name`/`user.email` do repo), **sem** `Co-Authored-By` e sem rodapé. Título conventional em português, minúsculo, com acento (`test: ...`, `fix: ...`, `docs: ...`); corpo em prosa quando a mudança não é trivial.
- **Nunca** `git add -A` nem `git add .`: `node_modules` (e `notificacoes/node_modules`) são symlinks para o checkout principal e entrariam no commit. Adicione arquivo por nome.
- **Nunca** rode `npm install`, `npm ci` ou `npm audit fix` no worktree: o `node_modules` é do checkout principal.
- Código, comentários e mensagens em português, no estilo do arquivo (o `app.js` é compacto; os testes de navegador também).
- Nada de `eval`/`new Function` em código que roda na página (a CSP bloqueia e gera violação).
- Sem dependência nova.

## Foco de revisão

1. Texto legítimo com `&`, `<` e aspas tem de aparecer exatamente como digitado, sem escape duplo — a Tarefa 1 confere por `textContent` (escape duplo mostraria `&lt;` no texto).
2. Datas válidas continuam `dd/mm/aa` depois do escape no `fmtData` — a Tarefa 1 confere `01/02/25` no relatório.
3. Nenhum arquivo usado pelo app web, pelo app nativo ou pela função `api/` pode cair no `.vercelignore` — a Tarefa 3 confere os `ASSETS` do `sw.js`, as referências do `index.html`/`privacidade.html`, o `url()` do CSS, `api/` e as dependências de `notificacoes/`.
4. A função `/api/push-diario` continua publicada (503 sem segredo, não 404) — conferido na prévia (Tarefa 4).
5. Dado hostil não pode derrubar a tela com exceção não tratada — a Tarefa 1 falha em `pageerror`.

## Execução

As Tarefas 1, 2 e 3 mexem em arquivos disjuntos e rodam em paralelo, cada uma no seu worktree criado a partir do commit deste plano. A Tarefa 4 (controlador) junta os três na branch `fix/blindagem-seguranca` por cherry-pick, roda tudo de novo e entrega.

Preparação de cada worktree (feita pelo controlador antes de despachar):

```bash
cd /Users/giovanistuchi/Documents/app_construcao_civil
git worktree add -b blindagem/<nome> .claude/worktrees/blindagem-<nome> fix/blindagem-seguranca
cd .claude/worktrees/blindagem-<nome>
ln -s /Users/giovanistuchi/Documents/app_construcao_civil/node_modules node_modules
ln -s /Users/giovanistuchi/Documents/app_construcao_civil/notificacoes/node_modules notificacoes/node_modules
```

---

### Tarefa 1: suíte de navegador com dados hostis

**Arquivos:**
- Criar: `tests/browser/xss.cjs`
- Modificar: `tests/browser/rodar.cjs` (registrar a suíte logo depois de `mobile.cjs`)

**Interfaces:**
- Consome: globais do `app.js` acessíveis em `page.evaluate` (`openObra`, `renderObra`, `formEditarObra`, `formGasto`, `formOrcamento`, `sheetTopico`, `sheetAPagar`, `gastoRow`, `formVenda`, `showView`, `renderGraficos`, `renderRelatorio`, `renderSimula`, `simulaCompute`, `renderAjustes`, `toast`, `closeSheet`, `obraById`, `$`, `filtroTexto`), o servidor `tests/browser/servidor.cjs` (porta 8123) e o padrão de stub de `window.CLOUD` de `tests/browser/mobile.cjs`.
- Produz: `tests/browser/xss.cjs`, que sai com código ≠ 0 se qualquer tela gerar elemento/atributo a partir de dado do usuário. Nada de código de app.

- [ ] **Passo 1: escrever a suíte**

Crie `tests/browser/xss.cjs` com exatamente este conteúdo:

```js
/* XSS com dados hostis: o blob entra pelo caminho real (watchDados → normaliza → renderAll)
   e percorre todas as telas, folhas e diálogos. Nenhum elemento, atributo ou handler pode
   nascer de texto do usuário — com a CSP ligada e com ela desligada (bypassCSP), o que
   prova que o escape segura sozinho. Sem contas ou serviços externos. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

// Fecha aspas simples e duplas, injeta atributo com handler e cria elementos com handler.
const P=`'" data-xss="1" autofocus onfocus="window.__xss=1"><img data-xss src=x onerror="window.__xss=1"><svg data-xss onload="window.__xss=1"></svg>`;
// Curto: ids e chaves do orçamento (dados.js descarta tópico de orçamento com mais de 80 caracteres).
const C=`'" data-xss="1"><img data-xss src=x>`;
const ID1='o1'+C;
const isoLocal=d=>new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,10);
const emDias=n=>{const d=new Date();d.setDate(d.getDate()+n);return isoLocal(d);};
const HOSTIL={
  obras:[
    {id:ID1,nome:'Obra '+P,fase:'construcao',dataInicio:'2025-01-10',valorEstimadoVenda:900000,areaM2:120,
      orcamento:{modo:'topicos',topicos:{[C]:50000,c_hostil:20000,fundacao:10000}},
      afazeres:[{id:'a1'+C,texto:'Afazer '+P,feito:false},{id:'a2',texto:P,feito:true}],
      gastos:[
        {id:'g1'+C,valor:1000,topico:C,descricao:'Desc '+P,data:'2025-02-01',pagamento:P},
        {id:'g2',valor:2000,topico:'c_hostil',descricao:P,data:'2025-03-01',pagamento:'pix'},
        {id:'g3',valor:300,topico:'fundacao',descricao:P,data:emDias(1),pagamento:'cartao',grupoId:'gr'+C,parcela:{n:1,de:2},
          jurosCartao:{taxaMensal:P,nParcelas:P,jurosCompra:P,totalCompra:P,valorCompra:P}},
        {id:'g4',valor:300,topico:'fundacao',descricao:P,data:emDias(31),pagamento:'cartao',grupoId:'gr'+C,parcela:{n:2,de:2}},
      ]},
    {id:'o2',nome:P,fase:'pronta',dataInicio:'2025-01-01',valorEstimadoVenda:null,areaM2:80,
      gastos:[{id:'h1',valor:5000,topico:'fundacao',descricao:P,data:'2025-01-15',pagamento:'pix'}]},
  ],
  config:{taxaMensal:1,topicosCustom:[{id:'c_hostil',nm:'Tópico '+P,ic:P},{id:'c_livre'+C,nm:P,ic:'etiqueta'}]},
};
const USUARIO={uid:'teste',email:P+'@example.com',emailVerificado:false,temSenha:true,provedores:['password']};
const PERFIL={nome:P,sobrenome:P};
// Qualquer um destes no DOM = texto do usuário virou HTML. O app não usa handler inline (CSP).
const INJETADO='[data-xss],[onerror],[onload],[onfocus],[onclick],[onmouseover]';

async function percorre(browser,semCSP){
  const modo=semCSP?'sem CSP':'com CSP';
  const ctx=await browser.newContext({serviceWorkers:'block',bypassCSP:semCSP});
  try{
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(({hostil,usuario,perfil})=>{
      sessionStorage.setItem('splashVista','1');
      window.violacoes=[];
      addEventListener('securitypolicyviolation',e=>violacoes.push(e.violatedDirective));
      window.temHostil=sel=>[...document.querySelectorAll(sel)].some(e=>e.textContent.includes('<img data-xss'));
      window.CLOUD={user:()=>usuario,onAuth:cb=>cb(usuario),
        watchDados:cb=>{setTimeout(()=>cb(hostil,{}),0);return()=>{};},
        saveDados:()=>Promise.resolve(),estado:()=>'ocioso',lerPerfil:()=>Promise.resolve(perfil)};
    },{hostil:HOSTIL,usuario:USUARIO,perfil:PERFIL});
    const page=await ctx.newPage();
    const errosPagina=[];
    page.on('pageerror',e=>errosPagina.push(e.message));
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>document.querySelectorAll('#obrasList li').length===2);

    const confere=async(passo,chegou,arg)=>{
      assert.ok(await page.evaluate(chegou,arg),`${modo} · ${passo}: o dado hostil não chegou à tela — o teste não provaria nada`);
      const r=await page.evaluate(sel=>({
        injetados:[...document.querySelectorAll(sel)].map(e=>e.outerHTML.slice(0,120)),
        xss:window.__xss,
        violacoes:window.violacoes.slice(),
      }),INJETADO);
      assert.deepEqual(r.injetados,[],`${modo} · ${passo}: HTML injetado`);
      assert.equal(r.xss,undefined,`${modo} · ${passo}: script injetado rodou`);
      assert.deepEqual(r.violacoes,[],`${modo} · ${passo}: violação de CSP`);
    };
    const fechaDialogo=()=>page.evaluate(()=>document.querySelector('dialog.confirma-dialog')?.close());

    await confere('início',()=>temHostil('#obrasList')&&temHostil('#compBars'));
    await page.evaluate(id=>openObra(id),ID1);
    await confere('obra',()=>temHostil('#obraBody .obra-head')&&temHostil('#obraBody .orc-lista')&&temHostil('#oAfazeres')&&temHostil('#oDonutLeg')&&temHostil('#oGastos'));
    await page.evaluate(p=>{filtroTexto=p;renderObra();},P);
    await confere('busca',p=>$('#fBusca').value===p,P);
    await page.evaluate(()=>{filtroTexto='';renderObra();});
    await page.evaluate(id=>formEditarObra(obraById(id)),ID1);
    await confere('editar obra',p=>$('#fNome').value==='Obra '+p,P);
    await page.evaluate(()=>$('#cDel').click());
    await page.waitForSelector('dialog.confirma-dialog');
    await confere('confirmar apagar obra',()=>temHostil('dialog.confirma-dialog'));
    await fechaDialogo();
    await page.evaluate(id=>{closeSheet();formGasto(id,obraById(id).gastos.find(g=>g.id==='g3'));},ID1);
    await confere('editar parcela com juros',p=>$('#fDesc').value===p&&temHostil('#sheet .muted-note'),P);
    await page.evaluate(()=>{closeSheet();formGasto(null,null,100);});
    await confere('novo gasto',()=>temHostil('#fObra'));
    await page.evaluate(id=>{closeSheet();formOrcamento(id);},ID1);
    await confere('orçamento',()=>temHostil('#sheet .orc-campos'));
    await page.evaluate(([id,top])=>{closeSheet();sheetTopico(id,top);},[ID1,C]);
    await confere('tópico',()=>temHostil('#sheet .top-head'));
    await page.evaluate(id=>{closeSheet();sheetAPagar(id);},ID1);
    await confere('a pagar',()=>temHostil('#aPagarGastos'));
    await page.evaluate(id=>{closeSheet();const o=obraById(id);gastoRow(o,o.gastos.find(g=>g.id==='g3')).querySelector('.li-del').click();},ID1);
    await confere('excluir parcela',()=>/Excluir parcela 1\/2/.test($('#sheet h3').textContent));
    await page.evaluate(()=>{closeSheet();formVenda(obraById('o2'));});
    await confere('registrar venda',()=>temHostil('#sheet h3'));
    await page.evaluate(id=>{closeSheet();openObra(id);showView('graficos');renderGraficos();},ID1);
    await confere('gráficos',()=>temHostil('#grafBody'));
    await page.evaluate(()=>{showView('relatorio');renderRelatorio();});
    await confere('relatório',()=>temHostil('#relBody')&&$('#relBody').textContent.includes('01/02/25'));
    await page.evaluate(id=>{showView('simula');renderSimula();$('#simObra').value=id;const v=$('#simValor');v.value='900.000,00';v.dataset.touched='1';simulaCompute();},ID1);
    await confere('simulação',id=>temHostil('#simObra')&&$('#simObra').value===id&&!!$('#simOut table'),ID1);
    await page.evaluate(()=>{showView('ajustes');renderAjustes();});
    await page.waitForFunction(()=>temHostil('#ajNome'));
    await confere('ajustes',()=>temHostil('#ajTopicos')&&temHostil('#ajEmail')&&temHostil('#avisoEmailTexto'));
    await page.evaluate(()=>document.querySelectorAll('#ajTopicos .li-del')[1].click());
    await page.waitForSelector('dialog.confirma-dialog');
    await confere('remover tópico',()=>temHostil('dialog.confirma-dialog'));
    await fechaDialogo();
    await page.evaluate(p=>toast(p,'erro'),P);
    await confere('aviso (toast)',()=>temHostil('#toastWrap'));
    assert.deepEqual(errosPagina,[],`${modo}: exceção na página com dado hostil`);
  }finally{await ctx.close();}
}

(async()=>{
  const browser=await chromium.launch();
  try{
    for(const semCSP of [false,true]) await percorre(browser,semCSP);
    console.log('ok - dados hostis em todas as telas, folhas e diálogos não viram HTML, com e sem CSP');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Passo 2: rodar a suíte contra o código atual**

Rode (sobe o servidor do mesmo jeito que o `rodar.cjs`, roda só esta suíte e derruba o servidor):

```bash
node -e "const {spawn}=require('child_process');const s=spawn(process.execPath,['tests/browser/servidor.cjs'],{stdio:'ignore',env:{...process.env,CUSTTA_EMULADORES:'1'}});(async()=>{for(let n=0;n<50;n++){try{if((await fetch('http://localhost:8123')).ok)break;}catch{}await new Promise(r=>setTimeout(r,100));}const c=spawn(process.execPath,['tests/browser/xss.cjs'],{stdio:'inherit'});c.on('exit',code=>{s.kill();process.exit(code);});})()"
```

Esperado: `ok - dados hostis em todas as telas, folhas e diálogos não viram HTML, com e sem CSP`. A auditoria leu o código e não achou injeção, então a suíte deve passar de primeira. Se falhar:
- falha de **"o dado hostil não chegou à tela"** = o seletor ou o fluxo do passo está errado — corrija a suíte (é a suíte que está errada, não o app) e documente no relatório;
- falha de **"HTML injetado"**, **"script injetado rodou"**, **"violação de CSP"** ou **"exceção na página"** = achado real de segurança. **Não corrija o app nesta tarefa**: pare e reporte com a mensagem completa (status `DONE_WITH_CONCERNS`).

- [ ] **Passo 3: provar que a suíte pega injeção (mutação temporária)**

Tire o escape do nome da obra na lista do Início e rode de novo:

```bash
sed -i '' 's|<div class="t">${escapeHtml(o.nome)}</div>|<div class="t">${o.nome}</div>|' app.js
grep -c '<div class="t">${o.nome}</div>' app.js   # tem de imprimir 1
```

Rode o mesmo comando do Passo 2. Esperado: FALHA com `com CSP · início: HTML injetado`. Depois desfaça e confira que o `app.js` voltou:

```bash
git checkout -- app.js
git diff --stat   # não pode listar app.js
```

- [ ] **Passo 4: registrar a suíte no orquestrador**

Em `tests/browser/rodar.cjs`, logo depois da linha `    await run('tests/browser/mobile.cjs');`, acrescente:

```js
    await run('tests/browser/xss.cjs');
```

- [ ] **Passo 5: commit**

```bash
git add tests/browser/xss.cjs tests/browser/rodar.cjs
git commit -m "test: dados hostis em todas as telas não viram HTML" -m "Suíte de navegador que entrega um blob hostil pelo caminho real de leitura (watchDados, normaliza, renderAll) e percorre início, obra, busca, folhas de edição, orçamento, tópico, a pagar, parcela, venda, gráficos, relatório, simulação, ajustes, diálogos e toast. Falha se qualquer texto do usuário virar elemento, atributo ou handler, se um script injetado rodar ou se a página lançar exceção. Roda duas vezes: com a CSP e com ela desligada, para provar que o escape segura sozinho. O teste estático em tests/xss.test.cjs só barrava trechos conhecidos; este cobre o que ainda não foi escrito."
```

---

### Tarefa 2: escape nos últimos trechos crus do app

**Arquivos:**
- Modificar: `tests/xss.test.cjs`
- Modificar: `app.js` (linhas ~77, ~412, ~491, ~806-807, ~911, ~1403)

**Interfaces:**
- Consome: `escapeHtml(s)` (declaração de função em `app.js:90`, içada — pode ser usada no `fmtData` da linha 77).
- Produz: `fmtData(iso)` continua devolvendo `dd/mm/aa`, agora escapado. Nenhuma assinatura muda.

- [ ] **Passo 1: escrever o teste que falha**

Em `tests/xss.test.cjs`, acrescente ao fim do array `perigos` (antes do `];`):

```js
  // números e datas do blob também: dados.js valida o tipo hoje, mas o escape não pode depender disso
  'Excluir parcela ${g.parcela.n}/${g.parcela.de}',
  'compra em ${g.parcela.de}x',
  'Parcela ${gasto.parcela.n}/${gasto.parcela.de}',
  "${String(o.areaM2).replace('.',',')}",
  '/${m.slice(2,4)}',
```

Logo depois do `for(const trecho of perigos){ ... }`, acrescente:

```js
/* fmtData monta dd/mm/aa com pedaços crus da data e entra em vários templates. */
assert.match(fonte, /const fmtData = iso => \{[^\n]*return escapeHtml\(`/, 'fmtData precisa devolver o texto escapado');
```

E troque o comentário desatualizado (o app nativo tem CSP por `<meta>`, injetada pelo `scripts/build-www.mjs`):

```js
/* Atributo cru é tão explorável quanto texto cru — e no app nativo não há CSP pra segurar.
```

por:

```js
/* Atributo cru é tão explorável quanto texto cru: a CSP (header na web, <meta> no app nativo)
   barra script inline, mas não barra HTML injetado (link, formulário, botão falso).
```

(a linha seguinte do comentário, `Todo value="${...}" precisa passar por escapeHtml ou por um formatador que só devolve dígito. */`, fica como está.)

- [ ] **Passo 2: rodar e ver falhar**

Run: `node tests/xss.test.cjs`
Esperado: FALHA com `AssertionError [ERR_ASSERTION]: interpolação sem escape em innerHTML: Excluir parcela ${g.parcela.n}/${g.parcela.de}`

- [ ] **Passo 3: commit do teste**

```bash
git add tests/xss.test.cjs
git commit -m "test: barra parcela, área, mês e data crus nos templates" -m "Estes trechos interpolam dado do blob sem escape. Hoje são seguros só porque dados.js valida o tipo antes do render; o teste passa a exigir o escape no próprio template, para a segurança não depender de um arquivo só. Também corrige o comentário que dizia que o app nativo não tem CSP: o build-www injeta a mesma CSP por <meta>."
```

- [ ] **Passo 4: aplicar o escape no `app.js`**

Faça exatamente estas trocas (cada trecho antigo aparece uma vez, exceto o da área, que aparece duas):

1. `fmtData` (linha ~77):
   - de: ``const fmtData = iso => { const [y,m,d] = iso.split('-'); return `${d}/${m}/${y.slice(2)}`; };``
   - para: ``const fmtData = iso => { const [y,m,d] = iso.split('-'); return escapeHtml(`${d}/${m}/${y.slice(2)}`); };``
2. Área no KPI de venda (linha ~412) **e** na tabela da simulação (linha ~1403) — as duas ocorrências:
   - de: `${String(o.areaM2).replace('.',',')}`
   - para: `${escapeHtml(String(o.areaM2).replace('.',','))}`
3. Rótulo do filtro de mês (linha ~491):
   - de: `${MESAB[+m.slice(5)-1]}/${m.slice(2,4)}</option>`
   - para: `${MESAB[+m.slice(5)-1]}/${escapeHtml(m.slice(2,4))}</option>`
4. Folha de excluir parcela (linhas ~806-807):
   - de: `<h3>Excluir parcela ${g.parcela.n}/${g.parcela.de}</h3>`
   - para: `<h3>Excluir parcela ${escapeHtml(g.parcela.n)}/${escapeHtml(g.parcela.de)}</h3>`
   - de: `compra em ${g.parcela.de}x no cartão.`
   - para: `compra em ${escapeHtml(g.parcela.de)}x no cartão.`
5. Aviso de parcela no editar gasto (linha ~911):
   - de: `Parcela ${gasto.parcela.n}/${gasto.parcela.de} de uma compra no cartão`
   - para: `Parcela ${escapeHtml(gasto.parcela.n)}/${escapeHtml(gasto.parcela.de)} de uma compra no cartão`

Confira que não sobrou nenhum:

```bash
grep -nF '${String(o.areaM2)' app.js        # as 2 linhas têm de estar dentro de escapeHtml(
grep -nF '${g.parcela.' app.js              # todas dentro de escapeHtml( — a linha ~779 já estava
grep -nF '${gasto.parcela.' app.js
```

- [ ] **Passo 5: rodar e ver passar**

Run: `node tests/xss.test.cjs`
Esperado: `ok - dados persistidos não entram crus em innerHTML nem em atributo`

Run: `npm run test:unit`
Esperado: todos os arquivos `ok`, sem falha (só `node --test`, sem rede).

- [ ] **Passo 6: commit**

```bash
git add app.js
git commit -m "fix: escapa parcela, área, mês e data nos templates" -m "Os últimos trechos que interpolavam dado do blob sem escape passam por escapeHtml: o fmtData (usado em seis templates), a área da obra no KPI de venda e na simulação, o ano do filtro de mês e o número da parcela na folha de excluir e no editar gasto. Para dado válido a saída é idêntica; a diferença é que a tela deixa de depender da validação de dados.js para não virar HTML."
```

---

### Tarefa 3: produção deixa de servir arquivos de desenvolvimento

**Arquivos:**
- Criar: `tests/vercel.test.cjs`
- Modificar: `.vercelignore`
- Modificar: `vercel.json` (chave nova `redirects`)
- Modificar: `package.json` (script `test:unit` ganha `tests/vercel.test.cjs`)
- Modificar: `CLAUDE.md` (linha 7)

**Interfaces:**
- Consome: `sw.js` (`const ASSETS = [...]` numa linha só, o mesmo formato que `scripts/build-www.mjs` lê), `index.html`, `privacidade.html`, `styles.css`.
- Produz: `.vercelignore` com regras só nos formatos `pasta/`, `*.ext` ou caminho exato (o teste recusa outro formato) e `vercel.json` com `redirects: [{ source:'/notificacoes/:path*', destination:'/', permanent:false }]`. Não mexe em `headers`, `rewrites` nem `crons`.

- [ ] **Passo 1: escrever o teste que falha**

Crie `tests/vercel.test.cjs`:

```js
'use strict';
/* A Vercel serve a raiz do repositório como está: o que não é do app sai pelo .vercelignore.
   Este teste trava os dois lados — arquivo de desenvolvimento fora do ar, e nada que o app
   web, o app nativo ou a função api/ usam fora do deploy. */
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const ler = f => readFileSync(join(raiz, f), 'utf8');
const regras = ler('.vercelignore').split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));
assert.ok(regras.every(r => r.endsWith('/') || r.startsWith('*.') || !/[*?[!]/.test(r)),
  'padrão novo no .vercelignore: ensine o casamento deste teste antes de usar');
// Mesma semântica do .gitignore para os três formatos usados: pasta/ (em qualquer nível), *.ext e caminho exato.
const ignorado = caminho => regras.some(r =>
  r.endsWith('/') ? `/${caminho}`.includes(`/${r}`)
  : r.startsWith('*.') ? caminho.endsWith(r.slice(1))
  : caminho === r);

const foraDoAr = ['CLAUDE.md', 'AGENTS.md', 'PRODUCT.md', 'README.md', 'notificacoes/README.md',
  'tests/rules.test.mjs', 'tests/browser/servidor.cjs', 'scripts/conta-demo.mjs', '.github/workflows/testes.yml',
  'firebase.json', 'firebase.test.json', '.firebaserc', 'firestore.rules', 'capacitor.config.json',
  'docs/plans/2026-10-02-blindagem-seguranca.md', 'ios/App/App/Info.plist', 'www/index.html'];
for(const f of foraDoAr) assert.ok(ignorado(f), `${f} não pode ir para produção`);

const assets = JSON.parse(/const ASSETS = (\[[^\]]*\]);/.exec(ler('sw.js'))[1].replace(/'/g, '"'))
  .map(a => a.replace(/^\.\//, '')).filter(Boolean);
const locais = html => [...ler(html).matchAll(/(?:src|href)="([^"#:]+)"/g)].map(m => m[1].replace(/^\.?\//, ''));
const doCss = [...ler('styles.css').matchAll(/url\(['"]?([^'")]+)['"]?\)/g)].map(m => m[1]).filter(u => !u.startsWith('data:'));
const daPagina = [...assets, ...locais('index.html'), ...locais('privacidade.html'), ...doCss];
const doServidor = ['sw.js', 'versao.json', 'package.json', 'package-lock.json', 'api/push-diario.js',
  'notificacoes/enviar.js', 'notificacoes/admin.js', 'notificacoes/resumo.js', 'notificacoes/fuso.js', 'calc.js', 'dados.js'];
for(const f of new Set([...daPagina, ...doServidor])) assert.ok(!ignorado(f), `${f} é usado em produção e não pode sair do deploy`);

/* notificacoes/ é código do servidor: a função api/ depende dela (não dá pra tirar do deploy),
   mas o site não serve — a Vercel redireciona antes de olhar o disco. */
const vercel = JSON.parse(ler('vercel.json'));
assert.deepStrictEqual((vercel.redirects || []).find(r => r.source === '/notificacoes/:path*'),
  { source: '/notificacoes/:path*', destination: '/', permanent: false });
assert.ok(!daPagina.some(f => f.startsWith('notificacoes/')), 'a página não pode depender de notificacoes/ (redirecionada)');

console.log('ok - deploy leva só o app: desenvolvimento fora do ar, nada do app de fora');
```

- [ ] **Passo 2: rodar e ver falhar**

Run: `node tests/vercel.test.cjs`
Esperado: FALHA com `AssertionError [ERR_ASSERTION]: CLAUDE.md não pode ir para produção`

- [ ] **Passo 3: registrar o teste no `test:unit` e commitar**

Em `package.json`, no script `test:unit`, acrescente ` tests/vercel.test.cjs` logo depois de `tests/headers.test.cjs` (a string continua uma linha só).

```bash
git add tests/vercel.test.cjs package.json
git commit -m "test: deploy não leva arquivo de desenvolvimento" -m "A Vercel serve a raiz do repositório como está, então CLAUDE.md, testes, scripts, workflows e configs do Firebase respondem 200 em produção. O teste exige que o .vercelignore tire esses arquivos e, do outro lado, que nada usado pelo app web, pelo app nativo ou pela função api/ saia do deploy."
```

- [ ] **Passo 4: implementar**

Substitua o conteúdo inteiro de `.vercelignore` por:

```
# Deploy leva só o app. A Vercel serve a raiz como está: o que não é do app sai daqui
# (tests/vercel.test.cjs confere os dois lados). notificacoes/ fica, porque a função
# api/ depende dela, e é redirecionada no vercel.json.
ios/
www/
docs/
tests/
scripts/
.github/
*.md
firebase.json
firebase.test.json
.firebaserc
firestore.rules
capacitor.config.json
```

Em `vercel.json`, acrescente a chave `redirects` entre `rewrites` e `headers` (mesma indentação de 2 espaços):

```json
  "redirects": [
    { "source": "/notificacoes/:path*", "destination": "/", "permanent": false }
  ],
```

Em `CLAUDE.md`, linha 7, troque `os arquivos da raiz são servidos como estão.` por:

```
os arquivos da raiz são servidos como estão — menos o que o `.vercelignore` tira do deploy (testes, scripts, docs, configs e notas `.md`) e `notificacoes/`, que só a função `api/` usa e a Vercel redireciona para a raiz. Arquivo de desenvolvimento novo fora dessas pastas entra no `.vercelignore` (`tests/vercel.test.cjs` confere).
```

(o resto da linha, `Deploy na Vercel; backend é Firebase (Auth + Firestore).`, continua depois.)

- [ ] **Passo 5: rodar e ver passar**

Run: `node tests/vercel.test.cjs && node tests/headers.test.cjs`
Esperado: `ok - deploy leva só o app: desenvolvimento fora do ar, nada do app de fora` e `ok - headers e CSP bloqueiam scripts inline e embedding`

Run: `npm run test:unit`
Esperado: todos `ok`.

- [ ] **Passo 6: commit**

```bash
git add .vercelignore vercel.json CLAUDE.md
git commit -m "fix: produção deixa de servir arquivos de desenvolvimento" -m "O .vercelignore passa a tirar do deploy testes, scripts, workflows do GitHub, notas .md e as configs do Firebase e do Capacitor, que não são do app e respondiam 200 em custta.com.br. A pasta notificacoes/ não pode sair, porque a função api/push-diario depende dela; por isso o vercel.json redireciona /notificacoes para a raiz, o que acontece antes de a Vercel olhar o disco. O repositório é público, então nada disso era segredo — a mudança tira superfície à toa do ar. O CLAUDE.md registra a regra para arquivo novo."
```

---

### Tarefa 4: integração, prévia e entrega (controlador)

- [ ] **Passo 1: juntar as branches** na `fix/blindagem-seguranca` (worktree `.claude/worktrees/blindagem`), em ordem, por cherry-pick dos commits de `blindagem/escape`, `blindagem/navegador` e `blindagem/vercel`. Os arquivos são disjuntos; conflito = parar e investigar.
- [ ] **Passo 2: rodar tudo** no worktree integrado: `npm run test:unit`, a suíte `tests/browser/xss.cjs` (comando do Passo 2 da Tarefa 1) e `tests/browser/mobile.cjs` pelo mesmo comando. O `npm run test:browser` completo (com emuladores) roda na CI.
- [ ] **Passo 3: revisão final do branch inteiro** por um revisor novo (superpowers:requesting-code-review).
- [ ] **Passo 4: push e PR** (`gh pr create`), em prosa: contexto → o que muda → decisão técnica, sem detalhe de exploração. Esperar a CI (`gh pr checks --watch`).
- [ ] **Passo 5: conferir a prévia da Vercel** com `curl`: `CLAUDE.md`, `tests/rules.test.mjs`, `scripts/conta-demo.mjs`, `.github/workflows/testes.yml`, `firestore.rules`, `firebase.json`, `.firebaserc`, `capacitor.config.json`, `PRODUCT.md` → 404; `/notificacoes/enviar.js` → 307 para `/`; `/`, `/app.js`, `/sw.js`, `/versao.json`, `/vendor/firebase/firebase-app.js`, `/fontes/hanken-grotesk-800.woff2`, `/splash/splash-1290x2796.png`, `/privacidade.html` → 200; `/api/push-diario` → 503. Header `Content-Security-Policy` presente em `/`.
- [ ] **Passo 6: agent-browser na prévia** com stub de `window.CLOUD` (dados hostis) por `--init-script`: telas do Início, obra e relatório no iPhone 16 Pro; zero `[data-xss]` no DOM, print.
- [ ] **Passo 7: registrar** o relatório completo da auditoria no Obsidian (nota de estado do Custta + histórico) e atualizar a memória. Merge fica com o Giovani.
