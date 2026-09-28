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
    await teste('desktop: nome da obra some do painel do topo, não repete o título grande', async ()=>{
      const { ctx, page } = await abrir(browser, { viewport:{ width:1440, height:900 } });
      await page.evaluate(() => openObra('o1'));
      /* opacity, além de visibility: #navTitulo (barra colapsada) é aria-hidden e fica com
         opacity:0 até rolar — existe no layout (a coluna do grid mede pelo texto) mas não
         aparece pra ninguém; sem esse filtro o teste acusaria repetição que não existe na tela */
      const n = await page.evaluate(() => [...document.querySelectorAll('body *')].filter(e =>
        e.children.length === 0 && e.textContent.trim() === 'Casa Azul' && e.getClientRects().length &&
        getComputedStyle(e).visibility !== 'hidden' && parseFloat(getComputedStyle(e).opacity) > 0 &&
        e.getBoundingClientRect().width > 1).length);
      assert.equal(n, 1, 'nome da obra repetido na tela');
      await ctx.close();
    });

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
      /* .grupo-obras e .obra-head são o invólucro sem material da lista/subtítulo (T9): o
         painel de verdade é opaco */
      assert.match(await estilo(page, '.panel:not(.grupo-obras):not(.obra-head)', 'backgroundColor'), /^rgb\(/);
      await ctx.close();
    });

    /* ---- login ---- */
    await teste('cartão do login é vidro sobre o globo', async ()=>{
      const { ctx, page } = await abrir(browser, { logado:false });
      assert.match(await estilo(page, '.auth-card', 'backdropFilter'), /blur\(40px\)/);
      assert.equal(await estilo(page, '.auth-card', 'borderTopWidth'), '0px');
      assert.equal(await estilo(page, '.auth-inner', 'backgroundColor'), 'rgba(0, 0, 0, 0)');
      await ctx.close();
    });

    /* (as tarefas seguintes acrescentam blocos aqui, antes do fechamento do try) */
  }finally{
    await browser.close();
  }
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nVidro ok');
  process.exit(falhas ? 1 : 0);
})();
