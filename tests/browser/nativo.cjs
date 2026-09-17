/* App como se estivesse no WKWebView: window.Capacitor falso registra chamadas.
   Dados sintéticos, sem rede. Rode com node tests/browser/servidor.cjs no ar. */
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

const OBRAS = { config:{ taxaMensal:1, topicosCustom:[{ id:'c_x', nm:'<img src=x onerror=alert(1)>', ic:'etiqueta' }] },
  obras:[{ id:'o1', nome:'Casa Azul', fase:'construcao', dataInicio:'2026-01-01', areaM2:80,
    gastos:[{ id:'g1', valor:150, topico:'c_x', descricao:'Cimento', data:'2026-02-01', pagamento:'pix' }] }] };

async function abrir(browser, { nativo, viewport = { width:390, height:844 }, antes }){
  const ctx = await browser.newContext({ viewport, serviceWorkers:'allow' });
  await ctx.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
  await ctx.route('https://**/*', r => r.abort());
  await ctx.addInitScript(([nativo, obras]) => {
    sessionStorage.setItem('splashVista', '1');
    window.errosPagina = [];
    addEventListener('error', e => errosPagina.push(e.message));
    addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
    window.CLOUD = { user:()=>({ uid:'teste', email:'t@t.com', emailVerificado:true }), onAuth:cb=>cb({ uid:'teste' }),
      watchDados:cb=>{ setTimeout(()=>cb(JSON.parse(JSON.stringify(obras)), { fromCache:false, pendingWrites:false, localDirty:false })); return ()=>{}; },
      saveDados:()=>Promise.resolve(), estado:()=>'ocioso', ready:Promise.resolve(), tentarDeNovo:()=>{ window.flushes = (window.flushes||0)+1; return Promise.resolve(); },
      savePushSub:()=>Promise.resolve(), removePushSub:()=>Promise.resolve(),
      savePushToken:(k,v)=>{ window.tokenSalvo=[k,v]; return Promise.resolve(); }, removePushToken:k=>{ window.tokenRemovido=k; return Promise.resolve(); } };
    if(!nativo) return;
    window.chamadasNativas = []; window.ouvintesNativos = {};
    const respostas = {
      'Filesystem.writeFile': a => ({ uri:'file:///cache/' + a.path }),
      'FirebaseMessaging.requestPermissions': () => ({ receive:'granted' }),
      'FirebaseMessaging.checkPermissions': () => ({ receive:'prompt' }),
      'FirebaseMessaging.getToken': () => ({ token:'tok-teste' }),
    };
    const plugin = nome => new Proxy({}, { get:(_, metodo) => {
      if(metodo === 'then') return undefined;
      if(metodo === 'addListener') return (ev, fn) => { chamadasNativas.push([nome, 'addListener', ev]); ouvintesNativos[nome + ':' + ev] = fn; return Promise.resolve({ remove(){} }); };
      return async a => { chamadasNativas.push([nome, metodo, a]); const f = respostas[nome + '.' + metodo]; return f ? f(a) : undefined; };
    } });
    const nomes = ['App','Share','Filesystem','Haptics','StatusBar','SplashScreen','FirebaseMessaging'];
    window.Capacitor = { isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:Object.fromEntries(nomes.map(n => [n, plugin(n)])) };
  }, [nativo, OBRAS]);
  if(antes) await antes(ctx);
  const page = await ctx.newPage();
  await page.goto('http://localhost:8123');
  await page.waitForFunction(() => typeof db !== 'undefined' && db.obras.length === 1);
  return { ctx, page };
}

(async()=>{
  const browser = await chromium.launch();
  try{
    /* ---- Task 3: condicionais ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.waitForTimeout(800);
      assert.equal(await page.evaluate(async()=> (await navigator.serviceWorker.getRegistrations()).length), 0, 'nativo não registra SW');
      const viewport = await page.getAttribute('meta[name=viewport]', 'content');
      assert.ok(!/user-scalable|maximum-scale/.test(viewport), 'zoom precisa ficar liberado: ' + viewport);
      await page.evaluate(()=>window.dispatchEvent(new Event('beforeinstallprompt')));
      assert.equal(await page.locator('#installHint').isHidden(), true, 'nativo não oferece instalar PWA');
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      assert.ok(!/Safari|Tela de Início/.test(await page.locator('#ajNotifNota').textContent()), 'nativo não menciona Safari');
      assert.deepEqual(await page.evaluate(()=>errosPagina), []);
      await ctx.close();
    }
    {
      const { ctx, page } = await abrir(browser, { nativo:false });
      await page.waitForFunction(async()=> (await navigator.serviceWorker.getRegistrations()).length === 1, null, { timeout:5000 });
      await ctx.close();
    }
    /* ---- Task 4: diálogos ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      await page.locator('#ajTopicos .li-del').first().click();
      const dlg = page.locator('dialog.confirma-dialog');
      assert.equal(await dlg.locator('.confirma-msg').textContent(), 'Este tópico tem gastos lançados. Mova ou apague os gastos antes.');
      await dlg.locator('[data-acao=confirmar]').click();
      await page.evaluate(()=>openObra('o1'));
      await page.locator('#oGastos .li-del').first().click();
      await dlg.locator('[data-acao=cancelar]').click();
      assert.equal(await page.evaluate(()=>obraById('o1').gastos.length), 1, 'cancelar mantém gasto');
      await page.locator('#oGastos .li-del').first().click();
      await dlg.locator('[data-acao=confirmar]').click();
      // fechar o <dialog> dispara o evento 'close' como tarefa assíncrona: espera o efeito, não só o clique.
      await page.waitForFunction(()=>obraById('o1').gastos.length === 0);
      await page.evaluate(()=>{ db.obras[0].gastos=[]; showView('ajustes'); renderAjustes(); });
      await page.locator('#ajTopicos .li-del').first().click();
      assert.equal(await dlg.locator('.confirma-msg').textContent(), 'Remover o tópico “<img src=x onerror=alert(1)>”?', 'nome aparece literal');
      await dlg.locator('[data-acao=confirmar]').click();
      await page.waitForFunction(()=>db.config.topicosCustom.length === 0);
      assert.deepEqual(await page.evaluate(()=>errosPagina), []);
      await ctx.close();
    }
    /* ---- Task 5: compartilhar ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ openObra('o1'); showView('relatorio'); renderRelatorio(); });
      assert.match(await page.locator('#relPrint').textContent(), /Compartilhar planilha/);
      await page.locator('#relPrint').click();
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='Share'));
      const share = await page.evaluate(()=>chamadasNativas.find(c=>c[0]==='Share'));
      assert.match(share[2].files[0], /^file:\/\/\/cache\/custta-.*\.csv$/);
      await page.evaluate(()=>{ showView('graficos'); renderGraficos(); });
      assert.match(await page.locator('#grafPrint').textContent(), /Compartilhar planilha/);
      await ctx.close();
      const web = await abrir(browser, { nativo:false });
      await web.page.evaluate(()=>{ openObra('o1'); showView('relatorio'); renderRelatorio(); });
      assert.match(await web.page.locator('#relPrint').textContent(), /Imprimir/);
      await web.ctx.close();
    }
    /* ---- Task 7: push nativo ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      await page.locator('#ajNotif').click();
      await page.waitForFunction(()=>window.tokenSalvo);
      assert.equal(await page.evaluate(()=>tokenSalvo[1].token), 'tok-teste');
      await page.evaluate(()=>ouvintesNativos['FirebaseMessaging:notificationActionPerformed']({ notification:{ data:{ obraId:'o1' } } }));
      await page.waitForFunction(()=>obraAberta === 'o1');
      assert.equal(await page.locator('#v-obra').isVisible(), true);
      await ctx.close();
    }
    /* ---- Task 10: adições nativas ---- */
    {
      // sem splashVista: prova que o splash web some mesmo na primeira abertura
      const antes = ctx => ctx.addInitScript(()=>sessionStorage.removeItem('splashVista'));
      const { ctx, page } = await abrir(browser, { nativo:true, antes });
      const chamou = (p, m) => page.evaluate(([p, m]) => chamadasNativas.filter(c => c[0] === p && c[1] === m), [p, m]);
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='SplashScreen' && c[1]==='hide'));
      assert.deepEqual((await chamou('StatusBar', 'setStyle')).at(-1)[2], { style:'DARK' }, 'tema escuro padrão → texto claro');
      await page.evaluate(()=>aplicaTema(true));
      assert.deepEqual((await chamou('StatusBar', 'setStyle')).at(-1)[2], { style:'LIGHT' });
      await page.evaluate(()=>{ openObra('o1'); formGasto('o1', null, 50); });
      await page.locator('#fDesc').fill('Areia');
      await page.locator('#cSave').click();
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='Haptics'));
      await page.evaluate(()=>ouvintesNativos['App:appStateChange']({ isActive:false }));
      assert.equal(await page.evaluate(()=>window.flushes), 1);
      assert.equal(await page.locator('#splash').count(), 0, 'splash web não aparece no nativo');
      await ctx.close();
    }
    console.log('ok - nativo');
  }finally{ await browser.close(); }
})().catch(err => { console.error(err); process.exitCode = 1; });
