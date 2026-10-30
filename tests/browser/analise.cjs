/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos e o Relatório. Sem contas nem rede.
   Hoje fica em 06/10/2026, no fuso de São Paulo (o relógio do Playwright), para os valores corrigidos não mudarem com o dia.
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
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852},timezoneId:'America/Sao_Paulo'});
    await ctx.clock.setFixedTime(new Date('2026-10-06T12:00:00-03:00'));
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

    // Relatório: um grupo por tópico, do maior bruto para o menor (no empate, o que aparece primeiro nos gastos); no grupo, os
    // gastos por data e, na mesma data, a ordem do documento; a descrição vazia vira o nome do tópico; o gasto a vencer não corrige
    await page.evaluate(()=>{showView('relatorio');renderRelatorio();});
    const linhasDoRelatorio=async()=>(await page.$$eval('#relBody .rep-table tbody tr',trs=>trs.map(tr=>[...tr.children].map(td=>td.textContent))))
      .map(l=>l.map(texto));
    assert.deepEqual((await linhasDoRelatorio()).slice(0,21),[
      ['Terreno','','R$ 150.000,00','R$ 165.942,65','+R$ 15.942,65'],['Terreno','01/12/25','R$ 150.000,00','R$ 165.942,65','+R$ 15.942,65'],
      ['Fundação','','R$ 20.000,00','R$ 21.767,00','+R$ 1.767,00'],['Sapatas','20/01/26','R$ 20.000,00','R$ 21.767,00','+R$ 1.767,00'],
      ['Pintura','','R$ 10.000,00','R$ 10.865,06','+R$ 865,06'],['Pintura','15/01/26','R$ 2.500,00','R$ 2.725,33','+R$ 225,33'],
      ['Massa corrida','15/01/26','R$ 1.500,00','R$ 1.635,20','+R$ 135,20'],['Tinta acrílica','01/02/26','R$ 6.000,00','R$ 6.504,54','+R$ 504,54'],
      ['Alvenaria','','R$ 10.000,00','R$ 10.901,30','+R$ 901,30'],['Blocos','15/01/26','R$ 10.000,00','R$ 10.901,30','+R$ 901,30'],
      ['Elétrica','','R$ 5.400,50','R$ 5.837,43','+R$ 436,93'],['Fios','10/02/26','R$ 5.400,50','R$ 5.837,43','+R$ 436,93'],
      ['Encanamento','','R$ 3.000,00','R$ 3.242,71','+R$ 242,71'],['Tubos','10/02/26','R$ 3.000,00','R$ 3.242,71','+R$ 242,71'],
      ['Telhado','','R$ 2.500,00','R$ 2.500,00','+R$ 0,00'],['Telhas','03/12/26','R$ 2.500,00','R$ 2.500,00','+R$ 0,00'],
      ['Documentação','','R$ 1.200,00','R$ 1.312,44','+R$ 112,44'],['Alvará','05/01/26','R$ 1.200,00','R$ 1.312,44','+R$ 112,44'],
      ['Outros','','R$ 300,00','R$ 321,32','+R$ 21,32'],['Limpeza','10/03/26','R$ 300,00','R$ 321,32','+R$ 21,32'],
      ['TOTAL','','R$ 202.400,50','R$ 222.689,91','+R$ 20.289,41']]);
    // cada caixinha leva o id do seu gasto, na ordem das linhas
    assert.deepEqual(await page.$$eval('#relBody .rel-check',cs=>cs.map(c=>c.dataset.gasto)),['a4','a7','a3','a11','a1','a2','a5','a6','a8','a9','a10']);

    assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
    await ctx.close();
    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos do relatório');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
