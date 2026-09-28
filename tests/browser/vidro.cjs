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

    /* (as tarefas seguintes acrescentam blocos aqui, antes do fechamento do try) */
  }finally{
    await browser.close();
  }
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nVidro ok');
  process.exit(falhas ? 1 : 0);
})();
