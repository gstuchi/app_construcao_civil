/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos. Sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

const g=(id,topico,valor,data,descricao='')=>({id,valor,topico,descricao,data,pagamento:'pix'});
/* Nove tópicos: a legenda da obra mostra 7, a dos Gráficos todos. Pintura e Alvenaria empatam em R$ 10 mil (a Pintura
   aparece primeiro nos gastos) e Outros fica abaixo de 0,5%. */
const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construcao',valorEstimadoVenda:450000,areaM2:120,gastos:[
  g('a1','pintura',6000,'2026-02-01','Tinta acrílica'),g('a2','alvenaria',10000,'2026-01-15','Blocos'),
  g('a3','pintura',2500,'2026-01-15'),g('a4','terreno',150000,'2025-12-01','Terreno'),g('a5','eletrica',5400.5,'2026-02-10','Fios'),
  g('a6','hidraulica',3000,'2026-02-10','Tubos'),g('a7','fundacao',20000,'2026-01-20','Sapatas'),
  g('a8','telhado',2500,'2026-12-03','Telhas'),g('a9','projeto',1200,'2026-01-05','Alvará'),g('a10','outros',300,'2026-03-10','Limpeza'),
  g('a11','pintura',1500,'2026-01-15','Massa corrida')]};

(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosAnalise=[];
      addEventListener('error',e=>errosAnalise.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosAnalise.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=>'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
      db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
      dadosCarregados=true;renderAll();openObra('a');},[CASA]);
    const texto=s=>s.replace(/\s+/g,' ').trim();

    // Gasto por tópico na obra: do maior para o menor, no empate o que aparece primeiro nos gastos; a legenda para em 7
    const legendaDaObra=await page.$$eval('#oDonutLeg .row',rs=>rs.map(r=>[r.querySelector('.nm').textContent,r.querySelector('.vl').textContent]));
    assert.deepEqual(legendaDaObra.map(([n,v])=>[texto(n),texto(v)]),[['Terreno','74% · R$ 150 mil'],['Fundação','10% · R$ 20 mil'],
      ['Pintura','5% · R$ 10 mil'],['Alvenaria','5% · R$ 10 mil'],['Elétrica','3% · R$ 5,4 mil'],['Encanamento','1% · R$ 3,0 mil'],
      ['Telhado','1% · R$ 2,5 mil']]);
    assert.equal(await page.locator('#oDonut circle').count(),9);
    assert.equal(texto(await page.locator('#oDonutTotal').textContent()),'R$ 202 mil');

    // Nos Gráficos: todos os tópicos, na mesma ordem, no anel e na legenda
    await page.evaluate(()=>{showView('graficos');renderGraficos();});
    const legendaDosGraficos=await page.$$eval('#grafBody .graf-leg li',ls=>ls.map(l=>[l.dataset.top,l.querySelector('.t').textContent,l.querySelector('.li-val').textContent]));
    assert.deepEqual(legendaDosGraficos.map(([id,n,v])=>[id,texto(n),texto(v)]),[['terreno','Terreno','74% · R$ 150 mil'],
      ['fundacao','Fundação','10% · R$ 20 mil'],['pintura','Pintura','5% · R$ 10 mil'],['alvenaria','Alvenaria','5% · R$ 10 mil'],
      ['eletrica','Elétrica','3% · R$ 5,4 mil'],['hidraulica','Encanamento','1% · R$ 3,0 mil'],['telhado','Telhado','1% · R$ 2,5 mil'],
      ['projeto','Documentação','1% · R$ 1,2 mil'],['outros','Outros','0% · R$ 300,00']]);
    assert.deepEqual(await page.$$eval('#grafBody .graf-donut circle',cs=>cs.map(c=>c.dataset.top)),
      ['terreno','fundacao','pintura','alvenaria','eletrica','hidraulica','telhado','projeto','outros']);

    assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
    await ctx.close();
    console.log('ok - análise: gasto por tópico na obra e nos Gráficos');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
