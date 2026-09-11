/* Layout com dados sintéticos: sem contas ou serviços externos. */
const assert=require('node:assert/strict');
const path=require('node:path');
const os=require('node:os');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block'});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosMobile=[];
      addEventListener('error',e=>errosMobile.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosMobile.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=> 'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(()=>{
      db=normaliza({obras:[{id:'o',nome:'Casa teste',dataInicio:'2026-01-01',gastos:Array.from({length:20},(_,i)=>({id:String(i),descricao:i%2?'Condomínio residencial (9/11)':'Tambor Bianca para materiais',valor:1545.45,data:'2027-05-10',topico:'matextra',pagamento:'cartao'}))}]});
      renderAll();openObra('o');
    });
    await page.evaluate(()=>{
      const o=obraById('o');
      o.gastos.push({id:'vence',descricao:'Cimento futuro',valor:100,data:OBRA_CALC.addMesesClampado(todayISO(),0),topico:'matextra',pagamento:'pix'});
      const d=new Date();d.setDate(d.getDate()+1);o.gastos.at(-1).data=OBRA_CALC.dataLocalISO(d);
      renderObra();
    });
    await page.locator('#oAPagar').click();
    assert.equal(await page.locator('#aPagarGastos .gasto-row').count(),1);
    await page.locator('#aPagarGastos .li-main').click();
    await page.locator('#fDesc').fill('Cimento editado');
    await page.locator('#cSave').click();
    assert.match(await page.locator('#aPagarGastos').textContent(),/Cimento editado/);
    await page.locator('#aPagarFechar').click();
    for(const width of [320,393,430,768,1440]){
      await page.setViewportSize({width,height:852});
      for(const light of [false,true]){
        await page.evaluate(light=>{closeSheet();aplicaTema(light);openObra('o');},light);
        await page.locator('.gasto-row').first().scrollIntoViewIfNeeded();
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
        assert.ok(await page.locator('.gasto-row .tag').first().evaluate(e=>e.getBoundingClientRect().height<30),'etiqueta deve ocupar uma linha');
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-lista-${light}.png`)});
        const pos=await page.evaluate(()=>scrollY);
        await page.evaluate(()=>formGasto('o',null,800));
        assert.equal(await page.locator('#topicoBusca').count(),0);
        await page.locator('#fDesc').fill('Descrição preservada');
        await page.locator('#fChips button').filter({hasText:'Fundação'}).click();
        assert.match(await page.locator('#fChips .on').textContent(),/Fundação/);
        assert.equal(await page.locator('#fDesc').inputValue(),'Descrição preservada');
        await page.locator('#fDesc').fill('Teste de lançamento');
        // Altura menor simula espaço ocupado pelo teclado, sem alegar emular iOS.
        await page.setViewportSize({width,height:460});
        await page.waitForTimeout(200);
        assert.ok(await page.locator('#sheet').evaluate(e=>e.scrollWidth<=e.clientWidth),'formulário não pode rolar horizontalmente');
        await page.locator('#cSave').scrollIntoViewIfNeeded();
        const caixa=await page.locator('#cSave').boundingBox();
        assert.ok(caixa.x>=0 && caixa.x+caixa.width<=width);
        await page.setViewportSize({width,height:852});
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-form-${light}.png`)});
        await page.locator('#cCancel').click();
        assert.ok(Math.abs(await page.evaluate(()=>scrollY)-pos)<2,'fechar restaura posição da lista');
      }
    }
    assert.deepEqual(await page.evaluate(()=>errosMobile),[]);
    console.log('ok - formulário, botões de tópicos e vencimentos em 5 larguras e 2 temas');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
