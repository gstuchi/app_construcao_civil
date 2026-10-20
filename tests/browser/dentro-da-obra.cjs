/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador) e o filtro dos lançamentos. Sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). O duplê do CLOUD guarda cada blob gravado em `salvos`:
   o teste confere o que foi para a nuvem, não só o `db` da página. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

const OBRA={id:'o',nome:'Casa Alphaville',dataInicio:'2026-01-10',gastos:[],
  afazeres:[{id:'a1',texto:'Comprar tinta',feito:false},{id:'a2',texto:'Pagar pedreiro',feito:true},
    {id:'a3',texto:'Ligar eletricista',feito:false,prioridade:'alta'}]};
const OBRA_FILTRO={id:'f',nome:'Sobrado Centro',dataInicio:'2026-01-10',afazeres:[],gastos:[
  {id:'g1',valor:1200,topico:'pintura',descricao:'Tinta acrílica',data:'2026-03-05',pagamento:'pix'},
  {id:'g2',valor:5400,topico:'eletrica',descricao:'Fios e disjuntores',data:'2026-02-10',pagamento:'pix'},
  {id:'g3',valor:800,topico:'eletrica',descricao:'Tomadas',data:'2026-02-20',pagamento:'pix'}]};

(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosObra=[];window.salvos=[];
      addEventListener('error',e=>errosObra.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosObra.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},
        saveDados:d=>{salvos.push(JSON.parse(JSON.stringify(d)));return Promise.resolve();},estado:()=>'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
      db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
      dadosCarregados=true;renderAll();openObra('o');},[OBRA,OBRA_FILTRO]);

    const textos=()=>page.locator('#oAfazeres li .li-main .t').allTextContents();
    const linha=texto=>page.locator('#oAfazeres li').filter({has:page.locator('.li-main .t',{hasText:texto})});
    const contador=async()=>(await page.locator('#afzCount').textContent()).trim();
    const salvo=()=>page.evaluate(()=>salvos.length?salvos.at(-1).obras.find(o=>o.id==='o').afazeres:null);
    const nuvemIgualAoDb=async()=>assert.deepEqual(await salvo(),await page.evaluate(()=>obraById('o').afazeres));

    // Pendentes antes dos feitos, cada grupo na ordem da lista
    assert.deepEqual(await textos(),['Comprar tinta','Ligar eletricista','Pagar pedreiro']);
    assert.equal(await contador(),'(2 pendentes)');

    // Adicionar: o texto aparado entra no começo, pendente; o campo limpa e fica com o foco
    await page.locator('#afzInput').fill('  Comprar areia  ');
    await page.locator('#afzAdd').click();
    const novo=await page.evaluate(()=>obraById('o').afazeres[0]);
    assert.equal(novo.texto,'Comprar areia');
    assert.equal(novo.feito,false);
    assert.equal(await page.locator('#afzInput').inputValue(),'');
    assert.equal(await page.evaluate(()=>document.activeElement.id),'afzInput');
    assert.equal(await contador(),'(3 pendentes)');
    await nuvemIgualAoDb();
    // Só espaços, pelo Enter: nada muda e nada grava
    const gravacoes=await page.evaluate(()=>salvos.length);
    await page.locator('#afzInput').fill('   ');
    await page.locator('#afzInput').press('Enter');
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.length),4);
    assert.equal(await page.evaluate(()=>salvos.length),gravacoes);
    assert.equal(await page.locator('.toast').count(),0,'campo vazio não avisa');

    // Marcar pelo círculo: vai para o alto dos feitos, com o campo desconhecido
    await linha('Ligar eletricista').locator('.afz-check').click();
    assert.deepEqual(await textos(),['Comprar areia','Comprar tinta','Ligar eletricista','Pagar pedreiro']);
    assert.deepEqual(await page.evaluate(()=>obraById('o').afazeres[0]),{id:'a3',texto:'Ligar eletricista',feito:true,prioridade:'alta'});
    assert.equal(await contador(),'(2 pendentes)');
    await nuvemIgualAoDb();
    // Desmarcar pelo texto: volta ao alto dos pendentes
    await linha('Pagar pedreiro').locator('.li-main').click();
    assert.deepEqual(await textos(),['Pagar pedreiro','Comprar areia','Comprar tinta','Ligar eletricista']);
    assert.equal(await contador(),'(3 pendentes)');
    await nuvemIgualAoDb();

    // Afazer apagado em outro aparelho com a lista na tela: tocar na linha velha não grava nada
    await page.evaluate(()=>{db=normaliza(JSON.parse(JSON.stringify(db)));const o=obraById('o');o.afazeres=o.afazeres.filter(a=>a.id!=='a1');});
    const antes=await page.evaluate(()=>salvos.length);
    await linha('Comprar tinta').locator('.afz-check').click();
    assert.equal(await page.evaluate(()=>salvos.length),antes);
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.some(a=>a.id==='a1')),false);
    await linha('Comprar tinta').locator('.li-del').click();
    assert.equal(await page.evaluate(()=>salvos.length),antes);
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.length),3);
    assert.deepEqual(await textos(),['Pagar pedreiro','Comprar areia','Ligar eletricista']);

    // Apagar sem perguntar
    await linha('Comprar areia').locator('.li-del').click();
    assert.deepEqual(await textos(),['Pagar pedreiro','Ligar eletricista']);
    assert.equal(await page.locator('dialog[open]').count(),0);
    await nuvemIgualAoDb();
    await linha('Pagar pedreiro').locator('.li-del').click();
    await linha('Ligar eletricista').locator('.li-del').click();
    assert.equal(await contador(),'');
    assert.match(await page.locator('#oAfazeres').textContent(),/Nenhum afazer\.\s*Anote o que falta na obra\./);
    assert.deepEqual(await salvo(),[]);

    // Filtro de mês: o mês escolhido não some do <select> quando sai o último gasto dele (achado 1)
    await page.evaluate(()=>openObra('f'));
    const meses=()=>page.locator('#fMes option').evaluateAll(os=>os.map(o=>[o.value,o.textContent]));
    const lancamentos=async()=>(await page.locator('#lanCount').textContent()).trim();
    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-03','mar/26'],['2026-02','fev/26']]);
    await page.locator('#fMes').selectOption('2026-03');
    assert.equal(await lancamentos(),'1/3');
    await page.locator('#oGastos li').filter({hasText:'Tinta acrílica'}).locator('.li-del').click();
    await page.locator('dialog[open] button',{hasText:'Excluir'}).click();
    await page.waitForFunction(()=>obraById('f').gastos.length===2);
    assert.equal(await page.locator('#fMes').inputValue(),'2026-03','o mês que filtra continua à vista');
    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-03','mar/26'],['2026-02','fev/26']]);
    assert.equal(await lancamentos(),'0/2');
    assert.match(await page.locator('#oGastos').textContent(),/Nada encontrado com esse filtro\./);
    // tirar o mês: ele sai da lista, que fica só com os meses que têm gasto
    await page.locator('#fMes').selectOption('');
    assert.equal(await lancamentos(),'2');
    await page.evaluate(()=>renderAll());
    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-02','fev/26']]);

    assert.deepEqual(await page.evaluate(()=>errosObra),[]);
    await ctx.close();
    console.log('ok - dentro da obra: afazeres e filtro de mês');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
