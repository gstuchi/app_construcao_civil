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

    /* (as tarefas seguintes acrescentam blocos aqui, antes do fechamento do try) */
  }finally{
    await browser.close();
  }
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nVidro ok');
  process.exit(falhas ? 1 : 0);
})();
