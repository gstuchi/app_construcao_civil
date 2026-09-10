/* Segurança e CSP no navegador, mais boot offline com SDK local real. */
const assert=require('node:assert/strict');
const path=require('node:path');
const os=require('node:os');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:414,height:896}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1'); window.__violacoes=[];window.__erros=[];
      addEventListener('securitypolicyviolation',e=>__violacoes.push(e.violatedDirective+': '+e.blockedURI));
      addEventListener('error',e=>__erros.push(e.message));
      window.CLOUD={ready:Promise.resolve(),user:()=>({uid:'local',email:'local@example.com'}),onAuth:cb=>cb({uid:'local',email:'local@example.com'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=> 'ocioso',temPendencia:()=>false};
    });
    const page=await ctx.newPage();await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>typeof normaliza==='function');
    const ataque='<img src=x onerror=alert(1)>';
    await page.evaluate(ataque=>{
      db=normaliza({config:{taxaMensal:1,topicosCustom:[{id:'custom',nm:ataque,ic:'etiqueta'}]},obras:[{id:'o1',nome:ataque,dataInicio:'2026-01-01',fase:'construcao',gastos:[{id:'g1',valor:100,topico:'custom',data:'2026-01-02',descricao:ataque}]},{id:'o2',nome:'Segunda',dataInicio:'2026-01-01',gastos:[{id:'g2',valor:50,topico:'terreno',data:'2026-01-02'}]}]});renderAll();
    },ataque);
    assert.ok(await page.locator('#compBars .hb-bruto').first().evaluate(e=>parseFloat(e.style.width)>0));
    for(const run of [()=>openObra('o1'),()=>renderGraficos(),()=>renderRelatorio(),()=>{closeSheet();showView('simula');renderSimula();document.querySelector('#simValor').value='1';simulaCompute();},()=>{closeSheet();showView('ajustes');renderAjustes();},()=>formGasto('o1'),()=>formEditarObra(obraById('o1'))]){
      await page.evaluate(run);assert.equal(await page.locator('img[src="x"]').count(),0);
    }
    await page.evaluate(()=>{closeSheet();showView('ajustes');renderAjustes();});
    assert.ok((await page.locator('#ajTopicos').textContent()).includes(ataque));
    await page.locator('#ajTaxa').fill('21');await page.locator('#ajTaxa').dispatchEvent('change');
    assert.equal(await page.evaluate(()=>db.config.taxaMensal),1);
    assert.ok((await page.locator('#toastWrap').textContent()).includes('20%'));
    await page.evaluate(()=>{const e=document.querySelector('#ajNovoTopico');e.value='x'.repeat(81);document.querySelector('#ajAddTopico').click();});
    assert.equal(await page.evaluate(()=>db.config.topicosCustom.length),1);
    await page.evaluate(()=>formNovaObra());
    await page.evaluate(()=>{document.querySelector('#fNome').value='x'.repeat(121);document.querySelector('#cSave').click();});
    assert.equal(await page.evaluate(()=>db.obras.length),2);
    for(const width of [414,1440]){
      await page.setViewportSize({width,height:900});
      for(const light of [false,true]){
        await page.evaluate(light=>{closeSheet();aplicaTema(light);openObra('o1');},light);
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
        await page.screenshot({animations:"disabled",path:path.join(os.tmpdir(),`custta-fase3-${width}-${light}.png`)});
      }
    }
    assert.deepEqual(await page.evaluate(()=>__violacoes),[]);
    assert.deepEqual(await page.evaluate(()=>__erros),[]);
    await page.goto('http://localhost:8123/privacidade.html');
    assert.deepEqual(await page.evaluate(()=>__violacoes),[]);
    console.log('ok - XSS literal, limites JS, taxa inválida, gráficos e temas sob CSP sem violações');
    await ctx.close();
    const real=await browser.newContext();
    await real.addInitScript(()=>{window.__violacoes=[];addEventListener('securitypolicyviolation',e=>__violacoes.push(e.violatedDirective));});
    await real.route('https://**/*',r=>r.abort());
    let p=await real.newPage();await p.goto('http://localhost:8123');
    await p.waitForFunction(()=>window.CLOUD);
    await p.evaluate(()=>navigator.serviceWorker.ready);
    await p.waitForFunction(async()=>!!(await caches.match('./vendor/firebase/firebase-firestore.js')));
    assert.deepEqual(await p.evaluate(()=>__violacoes),[]);
    await real.setOffline(true);await p.close();p=await real.newPage();
    await p.goto('http://localhost:8123');await p.waitForFunction(()=>window.CLOUD);
    assert.equal(await p.evaluate(()=>CLOUD.user()),null);
    assert.deepEqual(await p.evaluate(()=>__violacoes),[]);
    console.log('ok - SDK real inicializa com rede externa bloqueada e reabre offline pelo service worker');
    await real.close();
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
