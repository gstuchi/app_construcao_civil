/* Orçamento previsto × real com dados sintéticos: sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
const assert=require('node:assert/strict');
const path=require('node:path');
const os=require('node:os');
const {chromium}=require('playwright');

const gasto=(topico,valor,i,data='2026-03-01')=>({id:'g'+topico+i,topico,valor,data,descricao:'x',pagamento:'pix'});
const OBRAS=[
  {id:'a',nome:'Casa Alphaville 12',dataInicio:'2026-02-03',
   orcamento:{modo:'topicos',topicos:{terreno:180000,fundacao:90000,estrutura:250000,eletrica:100000,acabamento:180000}},
   gastos:[['terreno',180000],['fundacao',98000],['estrutura',231000],['eletrica',58000],['acabamento',45000],['hidraulica',12000]].map(([t,v],i)=>gasto(t,v,i))},
  {id:'b',nome:'Sobrado Granja Viana',dataInicio:'2026-01-10',orcamento:{modo:'total',total:1008000},gastos:[gasto('estrutura',1048000,0)]},
  {id:'c',nome:'Casa Tamboré 5',dataInicio:'2025-05-01',gastos:[gasto('terreno',934200,0,'2025-06-01')]},
];
const contraste=(a,b)=>{const lum=c=>{const [r,g,bb]=c.map(v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);});return 0.2126*r+0.7152*g+0.0722*bb;};
  const [l1,l2]=[lum(a),lum(b)].sort((x,y)=>y-x);return (l1+0.05)/(l2+0.05);};

async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
  const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width,height:852}});
  await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
  await ctx.route('https://**/*',r=>r.abort());
  await ctx.addInitScript(({tema,skin})=>{
    sessionStorage.setItem('splashVista','1');
    localStorage.setItem('mo_tema',tema); if(skin==='azul') localStorage.setItem('mo_skin','azul');
    window.errosOrc=[];
    addEventListener('error',e=>errosOrc.push(e.message));
    addEventListener('securitypolicyviolation',e=>errosOrc.push(e.violatedDirective));
    window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=>'ocioso'};
  },{tema,skin});
  const page=await ctx.newPage();
  await page.goto('http://localhost:8123');
  await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
    window.OBRAS_TESTE=structuredClone(obras);
    db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});renderAll();},OBRAS);
  return {ctx,page};
}

(async()=>{
  const browser=await chromium.launch();
  try{
    const {ctx,page}=await abrir(browser);
    // Início
    const linha=nome=>page.locator('#obrasList li').filter({hasText:nome});
    assert.match(await linha('Casa Alphaville 12').locator('.orc-mini').textContent(),/77% do orçamento/);
    const sobrado=linha('Sobrado Granja Viana').locator('.orc-mini');
    assert.match(await sobrado.textContent(),/104% · passou R\$ 40 mil/);
    assert.equal(await sobrado.locator('.alerta').count(),1);
    assert.equal(await linha('Casa Tamboré 5').locator('.orc-mini').count(),0,'obra sem orçamento fica igual');

    // Obra com orçamento por tópico
    await page.evaluate(()=>openObra('a'));
    const card=page.locator('#oOrc');
    const txt=(await card.textContent()).replace(/\s+/g,' ');
    assert.match(txt,/R\$\s612\.000,00 de R\$\s800\.000,00/);
    assert.match(txt,/77% usado/);
    assert.match(txt,/sobra R\$\s188\.000,00/);
    assert.equal((await card.locator('.orc-pill').textContent()).trim(),'dentro do previsto');
    const largura=await card.locator('.orc-barra i').evaluate(i=>i.style.width);
    assert.equal(largura,'77%');
    const nomes=await page.locator('.orc-topicos .orc-item .orc-nome').allTextContents();
    assert.deepEqual(nomes,['Fundação','Terreno','Estrutura','Elétrica','Acabamento','Fora do orçamento']);
    const item=nome=>page.locator('.orc-topicos .orc-item').filter({has:page.locator('.orc-nome',{hasText:nome})});
    assert.equal((await item('Fundação').locator('.orc-frase').textContent()).trim(),'Passou R$ 8 mil do previsto');
    assert.equal(await item('Fundação').locator('.orc-frase.alerta').count(),1);
    assert.equal(await item('Fundação').locator('.orc-barra.alerta').count(),1);
    assert.equal((await item('Estrutura').locator('.orc-frase').textContent()).trim(),'Faltam R$ 19 mil — 92%');
    assert.equal((await item('Terreno').locator('.orc-frase').textContent()).trim(),'Chegou ao previsto — 100%');
    assert.equal(await item('Elétrica').locator('.orc-frase').count(),0);
    assert.equal(await item('Elétrica').locator('.orc-barra.alerta').count(),0);
    assert.match(await item('Fora do orçamento').textContent(),/R\$ 12 mil[\s\S]*Encanamento/);
    assert.equal(await page.locator('#oOrcEditar').count(),1);
    assert.equal(await page.locator('#oOrcDefinir').count(),0);
    assert.equal(await page.locator('.kpis .kpi').count(),4,'KPIs continuam');
    // tocar no tópico abre a folha do tópico que já existe
    await item('Fundação').click();
    assert.match(await page.locator('#sheet').textContent(),/Fundação/);
    await page.evaluate(()=>closeSheet());

    // Obra com orçamento total estourado
    await page.evaluate(()=>openObra('b'));
    assert.equal((await page.locator('#oOrc .orc-pill').textContent()).trim(),'passou do previsto');
    assert.match((await page.locator('#oOrc .orc-rodape').textContent()).replace(/\s+/g,' '),/104% usado passou R\$\s40\.000,00/);
    assert.equal(await page.locator('.orc-topicos').count(),0);

    // Obra sem orçamento: sem card, só a porta de entrada
    await page.evaluate(()=>openObra('c'));
    assert.equal(await page.locator('#oOrc').count(),0);
    assert.equal(await page.locator('#oOrcDefinir').count(),1);

    // Folha: definir só o total numa obra sem orçamento
    await page.locator('#oOrcDefinir').click();
    assert.equal((await page.locator('#sheet .seg button.on').textContent()).trim(),'Só o total');
    assert.equal(await page.locator('#orcTopWrap').isHidden(),true);
    await page.locator('#orcTotal').fill('500000');
    assert.equal(await page.locator('#orcTotal').inputValue(),'500.000');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>obraById('c').orcamento),{modo:'total',total:500000});
    assert.equal(await page.locator('#oOrc').count(),1);

    // Folha por tópico: abre no modo salvo, soma ao vivo, salva só valores > 0
    await page.evaluate(()=>{db.config.topicosCustom=[{id:'c_portao',nm:'Portão',ic:'etiqueta'}];openObra('a');});
    await page.locator('#oOrcEditar').click();
    assert.equal((await page.locator('#sheet .seg button.on').textContent()).trim(),'Por tópico');
    assert.equal(await page.locator('#sheet .seg button.on').getAttribute('aria-pressed'),'true');
    const somaTxt=async()=>(await page.locator('#orcSoma').textContent()).replace(/\s/g,' ');
    assert.equal(await somaTxt(),'R$ 800.000,00');
    assert.match(await page.locator('#orcTopWrap').textContent(),/Tópico sem valor não entra na comparação\./);
    const campo=id=>page.locator(`#orcTopWrap input[data-top="${id}"]`);
    assert.equal(await campo('fundacao').inputValue(),'90.000,00');
    assert.equal(await campo('hidraulica').getAttribute('placeholder'),'sem valor');
    assert.equal(await campo('c_portao').count(),1,'tópico próprio também tem campo');
    await campo('fundacao').fill('100000');
    assert.equal(await somaTxt(),'R$ 810.000,00');
    await campo('eletrica').fill('');
    assert.equal(await somaTxt(),'R$ 710.000,00');
    await campo('c_portao').fill('5.000,50');
    for(const fonte of await page.locator('#sheet input').evaluateAll(els=>els.map(e=>parseFloat(getComputedStyle(e).fontSize))))
      assert.ok(fonte>=16,'campo com fonte < 16px dá zoom no iOS');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>obraById('a').orcamento),
      {modo:'topicos',topicos:{terreno:180000,fundacao:100000,estrutura:250000,acabamento:180000,c_portao:5000.5}});

    // Trocar pra "Só o total" e salvar vazio tira o orçamento
    await page.locator('#oOrcEditar').click();
    await page.locator('#sheet .seg button',{hasText:'Só o total'}).click();
    assert.equal(await page.locator('#orcTotal').isVisible(),true);
    // trocar de modo não pode apagar o previsto por tópico sem o construtor ver o número
    assert.equal(await page.locator('#orcTotal').inputValue(),'715.000,50');
    await page.locator('#orcTotal').fill('');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>'orcamento' in obraById('a')),false);
    assert.equal(await page.locator('#oOrcDefinir').count(),1);

    // Tirar orçamento pede confirmação
    await page.evaluate(()=>openObra('b'));
    await page.locator('#oOrcEditar').click();
    await page.locator('#orcTirar').click();
    await page.locator('dialog[open] button',{hasText:'Tirar orçamento'}).click();
    await page.waitForFunction(()=>!('orcamento' in obraById('b')));
    assert.equal(await page.locator('#oOrc').count(),0);

    // Nova obra com orçamento total
    await page.evaluate(()=>formNovaObra());
    await page.locator('#fNome').fill('Casa Nova');
    await page.locator('#fArea').fill('200');
    await page.locator('#fOrc').fill('300000');
    await page.locator('#cSave').click();
    assert.deepEqual(await page.evaluate(()=>db.obras.find(o=>o.nome==='Casa Nova').orcamento),{modo:'total',total:300000});
    assert.equal(await page.locator('#oOrc').count(),1);
    // Nova obra sem orçamento: nada muda
    await page.evaluate(()=>formNovaObra());
    await page.locator('#fNome').fill('Casa Sem');
    await page.locator('#fArea').fill('100');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(()=>'orcamento' in db.obras.find(o=>o.nome==='Casa Sem')),false);

    // Folha a 320px: nada vaza na horizontal
    await page.setViewportSize({width:320,height:640});
    await page.evaluate(()=>{db=normaliza({obras:structuredClone(window.OBRAS_TESTE),config:{taxaMensal:1,topicosCustom:[]}});openObra('a');formOrcamento('a');});
    assert.ok(await page.locator('#sheet').evaluate(e=>e.scrollWidth<=e.clientWidth),'folha não rola na horizontal');
    await page.waitForTimeout(400); // espera a animação "up" (.28s) do sheet sentar antes de printar
    await page.screenshot({path:path.join(os.tmpdir(),'custta-orc-folha-320.png')});
    await page.evaluate(()=>closeSheet());
    await page.setViewportSize({width:393,height:852});
    await page.evaluate(()=>{formOrcamento('a');});
    await page.waitForTimeout(400);
    await page.screenshot({path:path.join(os.tmpdir(),'custta-orc-folha.png')});
    await page.evaluate(()=>{ const s=document.querySelector('#sheet'); s.scrollTop=1e6; });
    await page.waitForTimeout(200);
    await page.screenshot({path:path.join(os.tmpdir(),'custta-orc-folha-fim.png')});
    await page.evaluate(()=>{closeSheet();db=normaliza({obras:structuredClone(window.OBRAS_TESTE),config:{taxaMensal:1,topicosCustom:[]}});renderAll();});

    // Larguras e temas: sem rolagem horizontal
    for(const width of [320,393,430,768,1440]){
      await page.setViewportSize({width,height:852});
      for(const light of [false,true]){
        await page.evaluate(light=>{aplicaTema(light);showView('inicio');renderAll();},light);
        await page.waitForTimeout(400); // espera a transição de tela (.32s) sentar antes de medir/printar
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`início ${width}`);
        if(width===320 || width===393){
          for(const nome of ['Casa Alphaville 12','Sobrado Granja Viana']){
            const larguraMini = await linha(nome).locator('.orc-barra.mini').evaluate(el=>el.getBoundingClientRect().width);
            assert.ok(larguraMini>=40, `mini de "${nome}" em ${width}px: ${larguraMini}px`);
          }
        }
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-orc-inicio-${light?'claro':'escuro'}.png`)});
        await page.evaluate(()=>openObra('a'));
        await page.waitForTimeout(400);
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`obra ${width}`);
        if(width===393) await page.screenshot({path:path.join(os.tmpdir(),`custta-orc-obra-${light?'claro':'escuro'}.png`),fullPage:true});
      }
    }
    assert.deepEqual(await page.evaluate(()=>errosOrc),[]);
    await ctx.close();

    // Contraste do texto novo nos 4 combos tema × skin
    for(const tema of ['escuro','claro']) for(const skin of ['esmeralda','azul']){
      const {ctx,page}=await abrir(browser,{tema,skin});
      await page.evaluate(()=>openObra('a'));
      const medidas=await page.evaluate(()=>['.orc-frase.alerta','#oOrc .orc-pill','#oOrc .orc-rodape','.orc-val','.orc-fora .orc-frase'].map(sel=>{
        const el=document.querySelector(sel); const cs=getComputedStyle(el);
        let fundo=cs.backgroundColor,no=el;
        while(/rgba\(0, 0, 0, 0\)|transparent/.test(fundo)&&no.parentElement){no=no.parentElement;fundo=getComputedStyle(no).backgroundColor;}
        return {sel,cor:cs.color,fundo};
      }));
      const rgb=s=>s.match(/[\d.]+/g).slice(0,3).map(Number);
      const base=rgb(await page.evaluate(()=>getComputedStyle(document.body).backgroundColor));
      for(const m of medidas){
        const f=m.fundo.match(/[\d.]+/g).map(Number); const a=f[3]===undefined?1:f[3];
        const fundo=[0,1,2].map(i=>f[i]*a+base[i]*(1-a));
        const c=contraste(rgb(m.cor),fundo);
        assert.ok(c>=4.5,`${tema}/${skin} ${m.sel}: contraste ${c.toFixed(2)}`);
      }
      await ctx.close();
    }
    console.log('ok - orçamento: card, lista por tópico, início, 5 larguras, 2 temas e contraste nos 4 combos');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
