/* Formulários da obra com dados sintéticos, sem serviços externos: o teto de obras das rules, a área com casas
   decimais na edição e a venda fora do intervalo. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosObras=[];
      addEventListener('error',e=>errosObras.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosObras.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=> 'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    // 300 obras: "Nova obra" avisa e não abre a folha (a 301ª as rules recusam, e toda gravação seguinte falharia)
    await page.evaluate(()=>{
      dadosCarregados=true;
      db=normaliza({obras:Array.from({length:300},(_,i)=>({id:`o${i}`,nome:`Obra ${i}`,dataInicio:'2026-01-01',gastos:[]}))});
      renderAll();formNovaObra();
    });
    await page.locator('dialog.confirma-dialog').waitFor();
    assert.equal(await page.locator('dialog.confirma-dialog .confirma-msg').textContent(),'Limite de 300 obras. Apague uma obra antiga para criar outra.');
    assert.equal(await page.locator('#fNome').count(),0,'a folha de nova obra não abre');
    await page.locator('dialog.confirma-dialog button').click();
    // com 299, abre; a obra nova entra com o orçamento total
    await page.evaluate(()=>{ db.obras.pop(); formNovaObra(); });
    await page.locator('#fNome').fill('Casa nova');
    await page.locator('#fArea').fill('3,125');
    await page.locator('#fOrc').fill('100.000,00');
    await page.locator('#cSave').click();
    const nova=await page.evaluate(()=>db.obras.at(-1));
    assert.equal(nova.nome,'Casa nova');assert.equal(nova.areaM2,3.125);assert.deepEqual(nova.orcamento,{modo:'total',total:100000});
    // editar sem mexer na área com três casas não a multiplica por mil (o parseNum lia "3.125" como 3125)
    await page.evaluate(id=>formEditarObra(obraById(id)),nova.id);
    assert.equal(await page.locator('#fArea').inputValue(),'3,125');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(id=>obraById(id).areaM2,nova.id),3.125);
    // venda antes do início não grava
    await page.evaluate(id=>formVenda(obraById(id)),nova.id);
    await page.locator('#fVal').fill('500.000,00');
    await page.locator('#fData').fill('2020-01-01');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(id=>obraById(id).fase,nova.id),'construcao');
    await page.waitForTimeout(200);
    assert.deepEqual(await page.evaluate(()=>errosObras),[]);
    console.log('ok - teto de obras, área com três casas na edição e venda fora do intervalo');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
