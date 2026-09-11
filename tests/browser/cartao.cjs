/* Fluxo de juros do cartão com dados sintéticos, sem serviços externos. */
const assert=require('node:assert/strict');
const path=require('node:path');
const os=require('node:os');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosCartao=[];
      addEventListener('error',e=>errosCartao.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosCartao.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=> 'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(()=>{
      db=normaliza({config:{taxaMensal:1},obras:[{id:'o',nome:'Casa teste',dataInicio:'2026-01-01',gastos:[]}]});
      renderAll();openObra('o');formGasto('o',null,1000);
    });
    assert.equal(await page.locator('#fJuros').isVisible(),false);
    await page.locator('#fPagto button').filter({hasText:'Cartão'}).click();
    assert.equal(await page.locator('#fJuros').isVisible(),true);
    await page.locator('#fParc').selectOption('2');
    await page.locator('#fJuros').fill('-1');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>obraById('o').gastos.length),0);
    await page.locator('#fJuros').fill('10,0');
    assert.match(await page.locator('#cartaoResumo').textContent(),/576,19.*152,38.*1.152,38/);
    await page.locator('#fData').fill('2026-10-11');
    await page.locator('#fDesc').fill('Compra com juros');
    await page.locator('#fParc').scrollIntoViewIfNeeded();
    await page.screenshot({path:path.join(os.tmpdir(),'custta-cartao.png')});
    await page.locator('#cSave').click();
    const dados=await page.evaluate(()=>({g:obraById('o').gastos,tx:taxa(),total:OBRA_CALC.totalBruto(obraById('o'))}));
    assert.equal(dados.total,1152.38);
    assert.equal(dados.tx,1);
    assert.deepEqual(dados.g.map(g=>g.data),['2026-10-11','2026-11-11']);
    assert.ok(dados.g.every(g=>g.pagamento==='cartao' && g.jurosCartao.taxaMensal===10));
    await page.evaluate(()=>{
      db=normaliza(JSON.parse(JSON.stringify(db)));
      formGasto('o',obraById('o').gastos[0]);
    });
    assert.equal(await page.locator('#fVal').inputValue(),'576,19');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>OBRA_CALC.totalBruto(obraById('o'))),1152.38);
    await page.evaluate(()=>formGasto('o',null,100));
    await page.locator('#fPagto button').filter({hasText:'Cartão'}).click();
    await page.locator('#fJuros').fill('5');
    await page.locator('#fPagto button').filter({hasText:'Pix'}).click();
    await page.locator('#cSave').click();
    const pix=await page.evaluate(()=>obraById('o').gastos.at(-1));
    assert.equal(pix.valor,100);assert.equal(pix.pagamento,'pix');assert.equal(pix.jurosCartao,undefined);
    await page.evaluate(()=>formGasto('o',null,100));
    await page.locator('#fPagto button').filter({hasText:'Cartão'}).click();
    await page.locator('#fParc').selectOption('3');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>obraById('o').gastos.slice(-3).map(g=>g.valor)),[33.33,33.33,33.34]);
    await page.waitForTimeout(200);
    assert.deepEqual(await page.evaluate(()=>errosCartao),[]);
    console.log('ok - juros mensais, parcelas, edição sem reaplicar juros e Pix sem taxa');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
