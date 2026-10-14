/* Formulários da obra com dados sintéticos, sem serviços externos: a obra nova com o orçamento total e a venda fora
   do intervalo. */
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
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:d=>{window.salvoObras=JSON.parse(JSON.stringify(d));return Promise.resolve();},estado:()=> 'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    // a obra nova entra com o orçamento total
    await page.evaluate(()=>{ dadosCarregados=true; db=normaliza({obras:[]}); renderAll(); formNovaObra(); });
    await page.locator('#fNome').fill('Casa nova');
    await page.locator('#fArea').fill('3,125');
    await page.locator('#fOrc').fill('100.000,00');
    await page.locator('#fEst').fill('900.000,00');
    await page.locator('#fData').fill('2025-08-12');
    await page.locator('#cSave').click();
    const nova=await page.evaluate(()=>db.obras.at(-1));
    assert.equal(nova.nome,'Casa nova');assert.equal(nova.areaM2,3.125);assert.deepEqual(nova.orcamento,{modo:'total',total:100000});
    // venda antes do início não grava
    await page.evaluate(id=>formVenda(obraById(id)),nova.id);
    await page.locator('#fVal').fill('500.000,00');
    await page.locator('#fData').fill('2020-01-01');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>document.activeElement.id),'fData');
    assert.ok((await page.locator('#toastWrap').textContent()).includes('Data da venda precisa ficar entre o início da obra e hoje'));
    // sem valor, volta ao valor antes de olhar a data
    await page.locator('#fVal').fill('');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>document.activeElement.id),'fVal');
    // a obra nova gravou o início e a estimativa
    assert.deepEqual(await page.evaluate(id=>[obraById(id).dataInicio,obraById(id).valorEstimadoVenda],nova.id),['2025-08-12',900000]);
    // editar: sem nome não grava; com um gasto chegando de outro aparelho com a folha aberta, grava o nome aparado, o
    // início, a estimativa e a área vazia como null, e o resto da obra fica
    await page.evaluate(id=>formEditarObra(obraById(id)),nova.id);
    await page.locator('#fNome').fill(' ');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(id=>[obraById(id).nome,document.activeElement.id],nova.id),['Casa nova','fNome']);
    await page.locator('#fNome').fill(' Casa editada ');
    await page.locator('#fData').fill('2025-09-01');
    await page.locator('#fEst').fill('1.500.000,00');
    await page.locator('#fArea').fill('');
    await page.evaluate(id=>{ db=normaliza(JSON.parse(JSON.stringify(db))); obraById(id).gastos.push({id:'g1',valor:10,topico:'extras',descricao:'Areia',data:'2026-01-02',pagamento:'pix'}); },nova.id);
    await page.locator('#cSave').click();
    for(const o of await page.evaluate(id=>[obraById(id),salvoObras.obras.find(o=>o.id===id)],nova.id))
      assert.deepEqual([o.nome,o.dataInicio,o.valorEstimadoVenda,o.areaM2,o.orcamento,o.gastos.map(g=>g.id)],
        ['Casa editada','2025-09-01',1500000,null,{modo:'total',total:100000},['g1']]);
    assert.deepEqual(await page.evaluate(()=>[backdrop.classList.contains('show'),document.querySelector('#v-obra h2').textContent.includes('Casa editada')]),[false,true]);
    assert.equal(await page.evaluate(id=>obraById(id).fase,nova.id),'construcao');
    await page.waitForTimeout(200);
    assert.deepEqual(await page.evaluate(()=>errosObras),[]);
    console.log('ok - obra nova com orçamento e venda fora do intervalo');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
