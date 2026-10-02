/* XSS com dados hostis: o blob entra pelo caminho real (watchDados → normaliza → renderAll)
   e percorre todas as telas, folhas e diálogos. Nenhum elemento, atributo ou handler pode
   nascer de texto do usuário — com a CSP ligada e com ela desligada (bypassCSP): sem a CSP
   um handler injetado rodaria e acusaria em __xss, então a segunda passada prova que o
   escape do texto segura sozinho. Datas, números e parcela não chegam hostis aqui (o
   dados.js valida o tipo antes); o escape deles é travado pelo tests/xss.test.cjs.
   Sem contas ou serviços externos. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

// Começa com &amp; (o value tem de voltar igual: prova o escape do &), fecha aspas simples e duplas, injeta atributo com handler e cria elementos com handler.
const P=`&amp; '" data-xss="1" autofocus onfocus="window.__xss=1"><img data-xss src=x onerror="window.__xss=1"><svg data-xss onload="window.__xss=1"></svg>`;
// Curto: ids e chaves do orçamento (dados.js descarta tópico de orçamento com mais de 80 caracteres).
const C=`'" data-xss="1"><img data-xss src=x>`;
const ID1='o1'+C;
const isoLocal=d=>new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,10);
const emDias=n=>{const d=new Date();d.setDate(d.getDate()+n);return isoLocal(d);};
const HOSTIL={
  obras:[
    {id:ID1,nome:'Obra '+P,fase:'construcao',dataInicio:'2025-01-10',valorEstimadoVenda:900000,areaM2:120,
      orcamento:{modo:'topicos',topicos:{[C]:50000,c_hostil:20000,fundacao:10000}},
      afazeres:[{id:'a1'+C,texto:'Afazer '+P,feito:false},{id:'a2',texto:P,feito:true}],
      gastos:[
        {id:'g1'+C,valor:1000,topico:C,descricao:'Desc '+P,data:'2025-02-01',pagamento:P},
        {id:'g2',valor:2000,topico:'c_hostil',descricao:P,data:'2025-03-01',pagamento:'pix'},
        {id:'g3',valor:300,topico:'fundacao',descricao:P,data:emDias(1),pagamento:'cartao',grupoId:'gr'+C,parcela:{n:1,de:2},
          jurosCartao:{taxaMensal:P,nParcelas:P,jurosCompra:P,totalCompra:P,valorCompra:P}},
        {id:'g4',valor:300,topico:'fundacao',descricao:P,data:emDias(31),pagamento:'cartao',grupoId:'gr'+C,parcela:{n:2,de:2}},
        {id:'g5',valor:100,topico:'f'+C,descricao:'x',data:'2025-04-01',pagamento:'pix'},
      ]},
    {id:'o2',nome:P,fase:'pronta',dataInicio:'2025-01-01',valorEstimadoVenda:null,areaM2:80,
      gastos:[{id:'h1',valor:5000,topico:'fundacao',descricao:P,data:'2025-01-15',pagamento:'pix'}]},
  ],
  config:{taxaMensal:1,topicosCustom:[{id:'c_hostil',nm:'Tópico '+P,ic:P},{id:'c_livre'+C,nm:P,ic:'etiqueta'}]},
};
const USUARIO={uid:'teste',email:P+'@example.com',emailVerificado:false,temSenha:true,provedores:['password']};
const PERFIL={nome:P,sobrenome:P};
// Qualquer um destes no DOM = texto do usuário virou HTML. O app não usa handler inline (CSP).
const INJETADO='[data-xss],[onerror],[onload],[onfocus],[onclick],[onmouseover]';

async function percorre(browser,semCSP){
  const modo=semCSP?'sem CSP':'com CSP';
  const ctx=await browser.newContext({serviceWorkers:'block',bypassCSP:semCSP});
  try{
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(({hostil,usuario,perfil})=>{
      sessionStorage.setItem('splashVista','1');
      window.violacoes=[];
      addEventListener('securitypolicyviolation',e=>violacoes.push(e.violatedDirective));
      window.temHostil=sel=>[...document.querySelectorAll(sel)].some(e=>e.textContent.includes('<img data-xss'));
      window.CLOUD={user:()=>usuario,onAuth:cb=>cb(usuario),
        watchDados:cb=>{setTimeout(()=>cb(hostil,{}),0);return()=>{};},
        saveDados:()=>Promise.resolve(),estado:()=>'ocioso',lerPerfil:()=>Promise.resolve(perfil)};
    },{hostil:HOSTIL,usuario:USUARIO,perfil:PERFIL});
    const page=await ctx.newPage();
    const errosPagina=[];
    page.on('pageerror',e=>errosPagina.push(e.message));
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>document.querySelectorAll('#obrasList li').length===2);

    const confere=async(passo,chegou,arg)=>{
      // Injeção primeiro: texto que vira HTML deixa de aparecer como texto, e o "chegou" abaixo
      // acusaria "não chegou à tela" — diagnóstico errado justamente para o que a suíte quer pegar.
      const r=await page.evaluate(sel=>({
        injetados:[...document.querySelectorAll(sel)].map(e=>e.outerHTML.slice(0,120)),
        xss:window.__xss,
        violacoes:window.violacoes.slice(),
      }),INJETADO);
      assert.deepEqual(r.injetados,[],`${modo} · ${passo}: HTML injetado`);
      assert.equal(r.xss,undefined,`${modo} · ${passo}: script injetado rodou`);
      assert.deepEqual(r.violacoes,[],`${modo} · ${passo}: violação de CSP`);
      assert.ok(await page.evaluate(chegou,arg),`${modo} · ${passo}: o dado hostil não chegou à tela — o teste não provaria nada`);
    };
    const fechaDialogo=()=>page.evaluate(()=>document.querySelector('dialog.confirma-dialog')?.close());

    await confere('início',()=>temHostil('#obrasList')&&temHostil('#compBars'));
    await page.evaluate(id=>openObra(id),ID1);
    await confere('obra',()=>temHostil('#obraBody .obra-head')&&temHostil('#obraBody .orc-lista')&&temHostil('#oAfazeres')&&temHostil('#oDonutLeg')&&temHostil('#oGastos')&&temHostil('#obraBody .orc-fora'));
    await page.evaluate(p=>{filtroTexto=p;renderObra();},P);
    await confere('busca',p=>$('#fBusca').value===p,P);
    await page.evaluate(()=>{filtroTexto='';renderObra();});
    await page.evaluate(id=>formEditarObra(obraById(id)),ID1);
    await confere('editar obra',p=>$('#fNome').value==='Obra '+p,P);
    await page.evaluate(()=>$('#cDel').click());
    await page.waitForSelector('dialog.confirma-dialog');
    await confere('confirmar apagar obra',()=>temHostil('dialog.confirma-dialog'));
    await fechaDialogo();
    await page.evaluate(id=>{closeSheet();formGasto(id,obraById(id).gastos.find(g=>g.id==='g3'));},ID1);
    await confere('editar parcela com juros',p=>$('#fDesc').value===p&&temHostil('#sheet .muted-note'),P);
    await page.evaluate(()=>{closeSheet();formGasto(null,null,100);});
    await confere('novo gasto',()=>temHostil('#fObra'));
    await page.evaluate(id=>{closeSheet();formOrcamento(id);},ID1);
    await confere('orçamento',()=>temHostil('#sheet .orc-campos'));
    await page.evaluate(([id,top])=>{closeSheet();sheetTopico(id,top);},[ID1,C]);
    await confere('tópico',()=>temHostil('#sheet .top-head'));
    await page.evaluate(id=>{closeSheet();sheetAPagar(id);},ID1);
    await confere('a pagar',()=>temHostil('#aPagarGastos'));
    await page.evaluate(id=>{closeSheet();const o=obraById(id);gastoRow(o,o.gastos.find(g=>g.id==='g3')).querySelector('.li-del').click();},ID1);
    await confere('excluir parcela',()=>/Excluir parcela 1\/2/.test($('#sheet h3').textContent));
    await page.evaluate(()=>{closeSheet();formVenda(obraById('o2'));});
    await confere('registrar venda',()=>temHostil('#sheet h3'));
    await page.evaluate(id=>{closeSheet();openObra(id);showView('graficos');renderGraficos();},ID1);
    await confere('gráficos',()=>temHostil('#grafBody'));
    await page.evaluate(()=>{showView('relatorio');renderRelatorio();});
    await confere('relatório',()=>temHostil('#relBody')&&$('#relBody').textContent.includes('01/02/25'));
    await page.evaluate(id=>{showView('simula');renderSimula();$('#simObra').value=id;const v=$('#simValor');v.value='900.000,00';v.dataset.touched='1';simulaCompute();},ID1);
    await confere('simulação',id=>temHostil('#simObra')&&$('#simObra').value===id&&!!$('#simOut table'),ID1);
    await page.evaluate(()=>{showView('ajustes');renderAjustes();});
    await page.waitForFunction(()=>temHostil('#ajNome'));
    await confere('ajustes',()=>temHostil('#ajTopicos')&&temHostil('#ajEmail')&&temHostil('#avisoEmailTexto'));
    await page.evaluate(()=>document.querySelectorAll('#ajTopicos .li-del')[1].click());
    await page.waitForSelector('dialog.confirma-dialog');
    await confere('remover tópico',()=>temHostil('dialog.confirma-dialog'));
    await fechaDialogo();
    await page.evaluate(p=>toast(p,'erro'),P);
    await confere('aviso (toast)',()=>temHostil('#toastWrap'));
    assert.deepEqual(errosPagina,[],`${modo}: exceção na página com dado hostil`);
  }finally{await ctx.close();}
}

(async()=>{
  const browser=await chromium.launch();
  try{
    for(const semCSP of [false,true]) await percorre(browser,semCSP);
    console.log('ok - dados hostis em todas as telas, folhas e diálogos não viram HTML, com e sem CSP');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
