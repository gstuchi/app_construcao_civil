/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos, o Relatório e o "Vale a pena?". Sem contas nem rede.
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
/* Vendida com lucro bruto e abaixo do banco (e um gasto depois da venda); pronta com margem negativa; sem venda nem estimada. */
const VENDIDA={id:'v',nome:'Sobrado Centro',dataInicio:'2025-05-01',fase:'vendida',venda:{valor:230000,data:'2026-05-20'},
  valorEstimadoVenda:280000,areaM2:90,gastos:[g('v1','terreno',120000,'2025-06-01','Lote'),g('v2','alvenaria',90000,'2025-09-10','Paredes'),
  g('v3','outros',5000,'2026-07-01','Limpeza depois da venda')]};
const PRONTA={id:'p',nome:'Pronta Jardins',dataInicio:'2026-01-05',fase:'pronta',valorEstimadoVenda:100000,
  gastos:[g('p1','estrutura',150000,'2026-02-01','Estrutura')]};
const SEM_VENDA={id:'s',nome:'Terreno novo',dataInicio:'2026-09-01',fase:'construcao',gastos:[g('s1','terreno',80000,'2026-09-02','Sinal')]};
/* Total bruto zero: a parte do total da seleção fica em "0%". */
const ZERADA={id:'z',nome:'Obra zerada',dataInicio:'2026-03-01',fase:'construcao',gastos:[g('z1','pintura',0,'2026-03-02','Brinde')]};

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
      dadosCarregados=true;renderAll();openObra('a');},[CASA,VENDIDA,PRONTA,SEM_VENDA,ZERADA]);
    const texto=s=>s.replace(/\s+/g,' ').trim();

    // Gasto por tópico na obra (identidade da etapa 4): barra empilhada com os 6 maiores + "Outros", do maior para o
    // menor (no empate, o que aparece primeiro nos gastos); a legenda mostra os 4 maiores e "e mais N tópicos"
    const legendaDaObra=await page.$$eval('#obraBody .leg-mini > div:not(.mais-t)',rs=>rs.map(r=>[r.querySelector('.nm').textContent,r.querySelector('.pc').textContent]));
    assert.deepEqual(legendaDaObra.map(([n,v])=>[texto(n),texto(v)]),[['Terreno','74%'],['Fundação','10%'],['Pintura','5%'],['Alvenaria','5%']]);
    assert.equal(texto(await page.locator('#obraBody .leg-mini .mais-t').textContent()),'e mais 5 tópicos');
    const TOTAL=CASA.gastos.reduce((s,x)=>s+x.valor,0);
    const soma=ids=>CASA.gastos.filter(x=>ids.includes(x.topico)).reduce((s,x)=>s+x.valor,0);
    const PEDACOS=[['terreno'],['fundacao'],['pintura'],['alvenaria'],['eletrica'],['hidraulica'],['telhado','projeto','outros']];
    assert.deepEqual(await page.$$eval('#oPilha i',is=>is.map(i=>+i.dataset.peso)),PEDACOS.map(soma));
    assert.deepEqual(await page.$$eval('#oPilha i',is=>is.map(i=>i.dataset.cor)),['--g1','--g2','--g3','--g4','--g5','--g6','--g-outros']);
    // a barra leva aos Gráficos
    await page.locator('#oTopicos').click();
    assert.equal(await page.evaluate(()=>tab),'graficos');

    // Nos Gráficos: o anel com os mesmos 7 pedaços (piso de 10 de arco, o excedente sai do maior), que fecham a volta
    // sem buraco; a lista com todos os tópicos, os 6 em cor e o resto sob "Outros"
    const VOLTA=2*Math.PI*100;
    const arcos=await page.$$eval('#anel .peca:not(.fecho) .seg',cs=>cs.map(c=>[parseFloat(c.getAttribute('stroke-dasharray')),-parseFloat(c.getAttribute('stroke-dashoffset'))]));
    assert.equal(arcos.length,7);
    let ini=0;
    arcos.forEach(([len,de],i)=>{
      assert.ok(Math.abs(de-ini)<0.05,`pedaço ${i} começa em ${de}, esperado ${ini}`);
      assert.ok(len>=10-0.01,`pedaço ${i} abaixo do piso: ${len}`);
      if(soma(PEDACOS[i])/TOTAL*VOLTA>=10&&i>0) assert.ok(Math.abs(len-soma(PEDACOS[i])/TOTAL*VOLTA)<0.05,`pedaço ${i} fora da proporção`);
      ini+=len;
    });
    assert.ok(Math.abs(ini-VOLTA)<0.05,`o anel fecha a volta: ${ini} × ${VOLTA}`);
    assert.equal(texto(await page.locator('#anelCentro').textContent()),'total gasto R$ 202 mil 9 tópicos');
    const legendaDosGraficos=await page.$$eval('#grafBody .leg-lista [data-top]',ls=>ls.map(l=>[l.dataset.top,l.querySelector('.nm').textContent,l.querySelector('.pc').textContent,l.querySelector('.vl').textContent]));
    assert.deepEqual(legendaDosGraficos.map(([id,n,p,v])=>[id,texto(n),texto(p),texto(v)]),[['terreno','Terreno','74%','R$ 150.000'],
      ['fundacao','Fundação','10%','R$ 20.000'],['pintura','Pintura','5%','R$ 10.000'],['alvenaria','Alvenaria','5%','R$ 10.000'],
      ['eletrica','Elétrica','3%','R$ 5.400'],['hidraulica','Encanamento','1%','R$ 3.000'],['telhado','Telhado','1%','R$ 2.500'],
      ['projeto','Documentação','<1%','R$ 1.200'],['outros','Outros','<1%','R$ 300']]);
    assert.equal(texto(await page.locator('#grafBody .leg-lista .outros-sep').textContent()),'Outros · 3 tópicos');
    // tocar num pedaço mostra o tópico no meio; tocar de novo volta ao total
    await page.locator('#anel .peca[data-i="1"]:not(.fecho) .alvo').dispatchEvent('click');
    assert.equal(texto(await page.locator('#anelCentro').textContent()),'Fundação R$ 20 mil 10% do total Ver gastos ›');
    await page.locator('#anel .peca[data-i="1"]:not(.fecho) .alvo').dispatchEvent('click');
    assert.match(texto(await page.locator('#anelCentro').textContent()),/^total gasto/);
    await page.evaluate(()=>openObra('a'));

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
    // a cola passa a taxa da config à regra (com a taxa em 1 do teste ela passaria sem ser vista) e o tópico que não existe mais
    // aparece pelo id, no grupo e na linha sem descrição
    await page.evaluate(()=>{db.config.taxaMensal=0.5;renderRelatorio();});
    assert.deepEqual((await linhasDoRelatorio())[20],['TOTAL','','R$ 202.400,50','R$ 212.323,74','+R$ 9.923,24']);
    await page.evaluate(()=>{db.config.taxaMensal=1;db.obras[0].gastos.push({id:'x1',valor:100,topico:'c_sumiu',descricao:'',data:'2026-02-01',pagamento:'pix'});renderRelatorio();});
    assert.deepEqual((await linhasDoRelatorio()).filter(l=>l[0]==='c_sumiu'),
      [['c_sumiu','','R$ 100,00','R$ 108,41','+R$ 8,41'],['c_sumiu','01/02/26','R$ 100,00','R$ 108,41','+R$ 8,41']]);
    await page.evaluate(()=>{db.obras[0].gastos.pop();renderRelatorio();});
    // cada caixinha leva o id do seu gasto, na ordem das linhas
    assert.deepEqual(await page.$$eval('#relBody .rel-check',cs=>cs.map(c=>c.dataset.gasto)),['a4','a7','a3','a11','a1','a2','a5','a6','a8','a9','a10']);

    // Fim do relatório, com a cor pelo sinal, e a linha da correção: venda estimada e margem; venda, lucro e acima do banco;
    // margem negativa; e nada sem as duas
    const fimDoRelatorio=()=>page.$$eval('#relBody .rep-table tbody tr',trs=>trs.slice(trs.findIndex(tr=>tr.children[0].textContent.trim()==='TOTAL')+1)
      .map(tr=>[...tr.children].map(td=>[td.textContent.replace(/\s+/g,' ').trim(),td.className])));
    const linhaDaCorrecao=async()=>texto((await page.locator('#relBody .rep-head').innerText()).split('\n')[1]);
    assert.deepEqual(await fimDoRelatorio(),[[['Venda estimada',''],['',''],['R$ 450.000,00','']],
      [['Margem estimada (estimado − corrigido)',''],['',''],['R$ 227.310,09','pos']]]);
    assert.equal(await linhaDaCorrecao(),'Correção de 1% ao mês, da data de cada gasto até hoje (06/10/26).');
    await page.evaluate(()=>{db.config.taxaMensal=1.5;openObra('v');showView('relatorio');renderRelatorio();});
    assert.deepEqual(await fimDoRelatorio(),[[['Venda em 20/05/26',''],['',''],['R$ 230.000,00','']],
      [['Lucro bruto (venda − gasto)',''],['',''],['R$ 15.000,00','pos']],[['Acima do banco (venda − corrigido)',''],['',''],['-R$ 19.420,73','neg']]]);
    assert.equal(await linhaDaCorrecao(),'Correção de 1,5% ao mês, da data de cada gasto até a venda (20/05/26).');
    // resultado exatamente zero fica "pos" (>= 0): com a taxa em 0 o corrigido é o bruto, e a venda de R$ 215.000 iguala o gasto
    await page.evaluate(()=>{db.config.taxaMensal=0;db.obras.find(o=>o.id==='v').venda.valor=215000;renderRelatorio();});
    assert.deepEqual((await fimDoRelatorio()).slice(1).map(l=>l[2]),[['R$ 0,00','pos'],['R$ 0,00','pos']]);
    // a data da venda vem do blob e entra na linha da correção: sai escapada, sem criar elemento
    await page.evaluate(()=>{db.obras.find(o=>o.id==='v').venda.data='2026-05-<b>20';renderRelatorio();});
    assert.equal(await page.locator('#relBody .rep-head b').count(),0);
    assert.equal(await linhaDaCorrecao(),'Correção de 0% ao mês, da data de cada gasto até a venda (<b>20/05/26).');
    await page.evaluate(()=>{const v=db.obras.find(o=>o.id==='v').venda;v.valor=230000;v.data='2026-05-20';});
    await page.evaluate(()=>{db.config.taxaMensal=1;openObra('p');showView('relatorio');renderRelatorio();});
    assert.deepEqual(await fimDoRelatorio(),[[['Venda estimada',''],['',''],['R$ 100.000,00','']],
      [['Margem estimada (estimado − corrigido)',''],['',''],['-R$ 62.613,38','neg']]]);
    await page.evaluate(()=>{db.config.taxaMensal=0;db.obras.find(o=>o.id==='p').valorEstimadoVenda=150000;renderRelatorio();});
    assert.deepEqual((await fimDoRelatorio()).slice(1).map(l=>l[2]),[['R$ 0,00','pos']]);
    await page.evaluate(()=>{db.config.taxaMensal=1;db.obras.find(o=>o.id==='p').valorEstimadoVenda=100000;});
    await page.evaluate(()=>{openObra('s');showView('relatorio');renderRelatorio();});
    assert.deepEqual(await fimDoRelatorio(),[]);
    assert.equal(await linhaDaCorrecao(),'Correção de 1% ao mês, da data de cada gasto até hoje (06/10/26).');

    // Soma da seleção: "N item(ns)", o bruto, o corrigido sem arredondar cada gasto antes e a parte do total com 2 casas
    const selecao=async()=>page.evaluate(()=>[$('#relSelected').classList.contains('hidden'),
      ...['#relSelQtd','#relSelBruto','#relSelCorr','#relSelPct'].map(s=>$(s).textContent.replace(/\s+/g,' '))]);
    await page.evaluate(()=>{openObra('a');showView('relatorio');renderRelatorio();});
    await page.locator('.rel-check[data-gasto="a1"]').check();
    await page.locator('.rel-check[data-gasto="a3"]').check();
    assert.deepEqual(await selecao(),[false,'2 itens','R$ 8.500,00','R$ 9.229,86','4,20%']);
    await page.locator('.rel-check[data-gasto="a1"]').uncheck();
    assert.deepEqual(await selecao(),[false,'1 item','R$ 2.500,00','R$ 2.725,33','1,24%']);
    await page.locator('.rel-check[data-gasto="a3"]').uncheck();
    assert.equal((await selecao())[0],true);
    await page.evaluate(()=>{openObra('z');showView('relatorio');renderRelatorio();});
    await page.locator('.rel-check[data-gasto="z1"]').check();
    assert.deepEqual(await selecao(),[false,'1 item','R$ 0,00','R$ 0,00','0%']);

    // "Vale a pena?": o cartão e a tabela da simulação, com a cor pelo sinal no lucro e nas porcentagens
    // o veredito é o bloco sólido da identidade nova (âmbar quando rende menos); o texto sai no formato de antes:
    // o "−" tipográfico vira "-", e as linhas de baixo juntam com " · "
    const norm=`t=>t.replace(/\\s+/g,' ').replace(/−/g,'-').replace(/R\\$\\s?/g,'R$ ').trim()`;
    const cartao=()=>page.evaluate(norm=>{const n=eval(norm);const c=$('#simOut .sim-veredito');if(!c)return c;const abaixo=c.classList.contains('ambar');
      const ic=document.createElement('span');ic.innerHTML=ICON(abaixo?'alerta':'check');
      if(c.querySelector('.k-ic').innerHTML!==ic.innerHTML)throw new Error('o ícone do cartão não é o do veredito');
      return [abaixo,n(c.querySelector('.k-nome').textContent),n(c.querySelector('.sim-taxa').textContent),[...c.querySelectorAll('.k-obs')].map(e=>n(e.textContent)).join(' · ')];},norm);
    const tabela=()=>page.$$eval('#simOut .sim-tab tbody tr',(trs,norm)=>{const n=eval(norm);return trs.map(tr=>[tr.classList.contains('forte')?'rep-total':'',...[...tr.children].map(td=>[n(td.textContent),td.className])]);},norm);
    const linha=(rotulo,b,c,cb='',cc='',tr='')=>[tr,[rotulo,''],[b,cb],[c,cc]];
    await page.evaluate(()=>{showView('simula');renderSimula();});
    assert.equal(await page.locator('#simObra').inputValue(),'a');
    assert.equal(await page.locator('#simValor').inputValue(),'450.000,00');
    // As obras: as não vendidas com gastos, na ordem do documento. Enquanto a pessoa não digitou, o preço acompanha a venda
    // estimada da obra escolhida (achado 4: a segunda obra herdava o preço da primeira); sem estimada, o campo fica vazio
    assert.deepEqual(await page.$$eval('#simObra option',os=>os.map(o=>[o.value,o.textContent])),
      [['a','Casa Alphaville'],['p','Pronta Jardins'],['s','Terreno novo'],['z','Obra zerada']]);
    await page.locator('#simObra').selectOption('p');
    assert.equal(await page.locator('#simValor').inputValue(),'100.000,00');
    await page.locator('#simObra').selectOption('s');
    assert.equal(await page.locator('#simValor').inputValue(),'');
    assert.equal(texto(await page.locator('#simOut').textContent()),'Digite o preço de venda pra ver a conta.');
    await page.locator('#simObra').selectOption('a');
    assert.equal(await page.locator('#simValor').inputValue(),'450.000,00');
    assert.deepEqual(await cartao(),[false,'Vale a pena','8,63% ao mês','vendendo hoje · banco paga 1% · rende 8,6× o banco']);
    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 202.400,50','R$ 222.689,91'),linha('Venda','R$ 450.000,00','R$ 450.000,00'),
      linha('Lucro','R$ 247.599,50','R$ 227.310,09','pos','pos','rep-total'),linha('% sobre o custo','122,3%','102,1%','pos','pos'),
      linha('% sobre a venda','55,0%','50,5%','pos','pos'),linha('Rendimento ao mês','8,63% a.m.','7,55% a.m.'),
      linha('Preço por m² (120 m²)','R$ 3.750,00','R$ 3.750,00')]);
    // Os meses param em 120 na conta, mesmo digitados além do teto do campo (achado 5); negativos viram hoje
    await page.locator('#simMeses').fill('200');
    assert.deepEqual(await cartao(),[true,'Rende menos que o banco','0,62% ao mês','vendendo daqui a 120 meses · banco paga 1%']);
    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 202.400,50','R$ 734.855,94'),linha('Venda','R$ 450.000,00','R$ 450.000,00'),
      linha('Lucro','R$ 247.599,50','-R$ 284.855,94','pos','neg','rep-total'),linha('% sobre o custo','122,3%','-38,8%','pos','neg'),
      linha('% sobre a venda','55,0%','-63,3%','pos','neg'),linha('Rendimento ao mês','0,62% a.m.','-0,38% a.m.'),
      linha('Preço por m² (120 m²)','R$ 3.750,00','R$ 3.750,00')]);
    for(const meses of ['-2','']){
      await page.locator('#simMeses').fill(meses);
      assert.equal((await cartao())[3],'vendendo hoje · banco paga 1% · rende 8,6× o banco');
    }
    // Outra obra, com preço e meses digitados e o banco a 1,5%: rende menos, sem área
    await page.evaluate(()=>{db.config.taxaMensal=1.5;});
    await page.locator('#simObra').selectOption('p');
    await page.locator('#simValor').fill('120.000,00');
    await page.locator('#simMeses').fill('3');
    assert.deepEqual(await cartao(),[true,'Rende menos que o banco','-1,98% ao mês','vendendo daqui a 3 meses · banco paga 1,5%']);
    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 150.000,00','R$ 177.052,22'),linha('Venda','R$ 120.000,00','R$ 120.000,00'),
      linha('Lucro','-R$ 30.000,00','-R$ 57.052,22','neg','neg','rep-total'),linha('% sobre o custo','-20,0%','-32,2%','neg','neg'),
      linha('% sobre a venda','-25,0%','-47,5%','neg','neg'),linha('Rendimento ao mês','-1,98% a.m.','-3,43% a.m.')]);
    await page.evaluate(()=>{db.config.taxaMensal=1;});
    // Sem preço, a frase do site e nenhuma conta
    await page.locator('#simValor').fill('0');
    assert.equal(texto(await page.locator('#simOut').textContent()),'Digite o preço de venda pra ver a conta.');
    // Depois de digitar, o preço fica o digitado, em qualquer obra
    await page.locator('#simValor').fill('95.000,00');
    await page.locator('#simObra').selectOption('a');
    assert.equal(await page.locator('#simValor').inputValue(),'95.000,00');
    assert.equal((await tabela())[1][2][0],'R$ 95.000,00');
    // A escolhida continua escolhida ao redesenhar; vendida, cai na primeira elegível
    await page.locator('#simObra').selectOption('z');
    await page.evaluate(()=>renderSimula());
    assert.equal(await page.locator('#simObra').inputValue(),'z');
    await page.evaluate(()=>{const o=obraById('z');o.fase='vendida';o.venda={valor:1,data:'2026-10-01'};renderSimula();});
    assert.equal(await page.locator('#simObra').inputValue(),'a');

    assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
    await ctx.close();
    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório; conta, textos, obras e preço do "Vale a pena?"');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
