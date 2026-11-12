/* App Check do site, só observando. Tudo falso por route, sem rede e sem
   emulador: o site sai dos arquivos locais em hosts falsos, com a CSP real do
   vercel.json; o reCAPTCHA é um script de mentira, o Auth responde pronto e o
   Firestore fala por um WebChannel falso. Em 127.0.0.1 e localhost a página vem
   do servidor.cjs, que precisa estar no ar na 8123 (o rodar.cjs sobe).
   Uso: node tests/browser/app-check.cjs */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');

const RAIZ=path.resolve(__dirname,'../..');
const CABECALHOS=Object.fromEntries(require('../../vercel.json').headers[0].headers.map(h=>[h.key,h.value]));
const TIPOS={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.svg':'image/svg+xml','.png':'image/png','.woff2':'font/woff2'};
const TOKEN_RECAPTCHA='recaptcha-falso';
const TOKEN_APP_CHECK='app-check-falso';
const UID='uid-falso';
const HORA='2026-11-09T12:00:00.000000Z';
const HORA_ESCRITA='2026-11-09T12:00:01.000000Z';
const MARCA='dG9rZW4=';
const CAMPOS={
  obras:{arrayValue:{values:[{mapValue:{fields:{
    id:{stringValue:'o1'},nome:{stringValue:'Obra do falso'},fase:{stringValue:'construcao'},
    dataInicio:{stringValue:'2026-01-01'},gastos:{arrayValue:{}},
  }}}]}},
  config:{mapValue:{fields:{taxaMensal:{doubleValue:1}}}},
};
const SCRIPT_RECAPTCHA=`window.grecaptcha={enterprise:{
  ready(cb){cb();},
  render(_el,o){window.__retornoRecaptcha=o.callback;return 0;},
  execute(){window.__retornoRecaptcha();return Promise.resolve('${TOKEN_RECAPTCHA}');},
}};`;
const cors=rota=>({'access-control-allow-origin':rota.request().headers().origin||'*','access-control-allow-credentials':'true'});
const json=(rota,corpo)=>rota.fulfill({status:200,headers:{...cors(rota),'content-type':'application/json'},body:JSON.stringify(corpo)});
function jwt(){
  const b=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
  const agora=Math.floor(Date.now()/1000);
  return `${b({alg:'none'})}.${b({sub:UID,user_id:UID,iat:agora,exp:agora+3600,email:'ana@example.com'})}.x`;
}
function servirSite(rota,url){
  const rel=url.pathname==='/'?'/index.html':decodeURIComponent(url.pathname);
  if(rel==='/sentry-config.js') return rota.fulfill({status:200,headers:{...CABECALHOS,'content-type':'text/javascript'},body:'window.CUSTTA_SENTRY_CONFIG={dsn:""};'});
  const arq=path.join(RAIZ,rel);
  if(!arq.startsWith(RAIZ+path.sep)||!fs.existsSync(arq)||fs.statSync(arq).isDirectory()) return rota.fulfill({status:404,body:'nao achei'});
  return rota.fulfill({status:200,headers:{...CABECALHOS,'content-type':TIPOS[path.extname(arq)]||'application/octet-stream'},body:fs.readFileSync(arq)});
}
function responderAuth(rota,r){
  const url=rota.request().url();
  r.auth.push(rota.request().headers()['x-firebase-appcheck']);
  if(url.includes('accounts:signInWithPassword')) return json(rota,{localId:UID,email:'ana@example.com',idToken:jwt(),refreshToken:'r',expiresIn:'3600',registered:true});
  if(url.includes('accounts:lookup')) return json(rota,{users:[{localId:UID,email:'ana@example.com',emailVerified:true,passwordHash:'x',providerUserInfo:[{providerId:'password',federatedId:'ana@example.com',email:'ana@example.com'}],validSince:'1',lastLoginAt:'1',createdAt:'1'}]});
  if(url.includes('securetoken')) return json(rota,{access_token:jwt(),expires_in:'3600',token_type:'Bearer',refresh_token:'r',id_token:jwt(),user_id:UID,project_id:'app-construcao-civil'});
  return json(rota,{});
}
/* WebChannel falso: o POST de abertura devolve o handshake e entrega os cabeçalhos
   no corpo (campo headers, sem preflight); as mensagens saem pelo back channel, o
   GET longo, sempre em quadros "tamanho\njson\n". Como no servidor real, o quadro
   entregue fica na fila até o cliente confirmar, pelo AID, que o recebeu; até lá volta
   em todo GET. O cliente desiste de um GET já respondido (ver segurarAteDesistir), e
   sem o reenvio o que ia nele se perde e o stream fica mudo. */
function criarFirestore(r,{ctx,perdeOPrimeiroGet=false}={}){
  const canais=new Map();
  let contador=0;
  const quadro=o=>{ const t=JSON.stringify(o)+'\n'; return `${t.length}\n${t}`; };
  const texto=(rota,corpo)=>rota.fulfill({status:200,headers:{...cors(rota),'content-type':'text/plain'},body:corpo});
  function confirma(c,aid){ if(aid!==null) c.fila=c.fila.filter(([id])=>id>Number(aid)); }
  function solta(c){
    if(!c.pendente||!c.fila.length) return;
    const rota=c.pendente; c.pendente=null;
    const corpo=quadro(c.fila);
    if(perdeOPrimeiroGet&&!c.segurou){ c.segurou=true; segurarAteDesistir(c,rota,corpo); return; }
    // GET que o cliente já abortou pode recusar a resposta: o que ia nela segue na fila.
    texto(rota,corpo).catch(()=>{});
  }
  /* A resposta do 1º GET longo do canal sai, mas só chega depois que o cliente desistiu
     dele: sem nada em 4x o RTT do handshake, o WebChannel acha que um proxy segura a
     resposta, cancela o GET e abre outro em long polling. */
  function segurarAteDesistir(c,rota,corpo){
    const url=rota.request().url();
    ctx.waitForEvent('requestfailed',{predicate:q=>q.url()===url,timeout:5000})
      .then(()=>{ r.desistiu[c.tipo]++; },()=>{})
      .then(()=>texto(rota,corpo).catch(()=>{}));
  }
  function envia(c,msg){ c.fila.push([++c.ultimo,[msg]]); solta(c); }
  function aoListen(c,msg){
    const alvo=msg.addTarget;
    if(!alvo) return;
    const nome=alvo.documents.documents[0];
    envia(c,{targetChange:{targetChangeType:'ADD',targetIds:[alvo.targetId]}});
    if(nome.includes('/dados/')) envia(c,{documentChange:{document:{name:nome,fields:CAMPOS,createTime:HORA,updateTime:HORA},targetIds:[alvo.targetId]}});
    else envia(c,{documentDelete:{document:nome,removedTargetIds:[alvo.targetId],readTime:HORA}});
    envia(c,{targetChange:{targetChangeType:'CURRENT',targetIds:[alvo.targetId],resumeToken:MARCA,readTime:HORA}});
    envia(c,{targetChange:{targetChangeType:'NO_CHANGE',targetIds:[],resumeToken:MARCA,readTime:HORA}});
  }
  function aoWrite(c,msg){
    if(!msg.writes){ envia(c,{streamId:'s',streamToken:MARCA}); return; }
    r.escritas.push(...msg.writes);
    /* Hora depois da do documento e o serverTimestamp respondido: só assim o SDK grava a escrita no cache. */
    envia(c,{streamToken:MARCA,writeResults:msg.writes.map(w=>({updateTime:HORA_ESCRITA,transformResults:(w.updateTransforms||[]).map(()=>({timestampValue:HORA_ESCRITA}))})),commitTime:HORA_ESCRITA});
  }
  return async rota=>{
    const pedido=rota.request(), url=new URL(pedido.url());
    const tipo=url.pathname.includes('/Write/')?'Write':'Listen';
    if(pedido.method()!=='POST'){
      const c=canais.get(url.searchParams.get('SID'));
      if(!c||url.searchParams.get('TYPE')==='terminate') return texto(rota,'');
      confirma(c,url.searchParams.get('AID'));
      c.pendente=rota; solta(c);
      return;
    }
    const corpo=new URLSearchParams(pedido.postData()||'');
    let c=canais.get(url.searchParams.get('SID'));
    const abertura=!c;
    if(c) confirma(c,url.searchParams.get('AID'));
    if(abertura){
      c={sid:'sessao'+(++contador),tipo,fila:[],ultimo:0,pendente:null};
      canais.set(c.sid,c);
      r.abertura[tipo].push(corpo.get('headers')||'');
    }
    for(let i=0;i<Number(corpo.get('count')||0);i++) (tipo==='Listen'?aoListen:aoWrite)(c,JSON.parse(corpo.get(`req${i}___data__`)));
    /* RTT de handshake acima de zero: com zero o WebChannel não arma a detecção de proxy. */
    if(abertura&&perdeOPrimeiroGet) await new Promise(res=>setTimeout(res,30));
    return texto(rota,quadro(abertura?[[0,['c',c.sid,'',8,12,30000]]]:[1,c.ultimo,0]));
  };
}
/* Contexto com os falsos. Quem não tem falso e sai de onde não devia cai em r.fora;
   o gapi do login social (apis.google.com) não interessa aqui e é só abortado. */
async function contexto(browser,hostsFalsos,{reCaptcha='responde',perdeOPrimeiroGet=false}={}){
  const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844}});
  const r={script:[],troca:[],auth:[],abertura:{Listen:[],Write:[]},escritas:[],violacoes:[],erros:[],fora:[],scriptEntregue:false,desistiu:{Listen:0,Write:0}};
  r.atrasoDoScript=new Promise(solta=>{ r.soltaScript=solta; });
  await ctx.exposeBinding('__registraCSP',(_s,v)=>r.violacoes.push(v));
  await ctx.addInitScript(()=>{
    sessionStorage.setItem('splashVista','1');
    addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI));
  });
  await ctx.route(()=>true,rota=>{
    const url=new URL(rota.request().url());
    if(hostsFalsos.includes(url.hostname)) return servirSite(rota,url);
    if(['localhost','127.0.0.1'].includes(url.hostname)&&url.port==='8123') return rota.continue();
    if(url.hostname!=='apis.google.com') r.fora.push(url.href);
    return rota.abort();
  });
  await ctx.route(/^https:\/\/www\.google\.com\/recaptcha\//,async rota=>{
    r.script.push(rota.request().url());
    if(reCaptcha==='aborta') return rota.abort();
    if(reCaptcha==='lento'){ await r.atrasoDoScript; r.scriptEntregue=true; }
    return rota.fulfill({status:200,headers:{'content-type':'text/javascript'},body:SCRIPT_RECAPTCHA});
  });
  await ctx.route(/^https:\/\/content-firebaseappcheck\.googleapis\.com\//,rota=>{
    r.troca.push({url:rota.request().url(),corpo:rota.request().postData()||''});
    return json(rota,{token:TOKEN_APP_CHECK,ttl:'3600s'});
  });
  await ctx.route(/^https:\/\/(identitytoolkit|securetoken)\.googleapis\.com\//,rota=>responderAuth(rota,r));
  await ctx.route(/^https:\/\/firestore\.googleapis\.com\//,criarFirestore(r,{ctx,perdeOPrimeiroGet}));
  return {ctx,r};
}
async function abrir(ctx,r,endereco,waitUntil='load'){
  const page=await ctx.newPage();
  page.setDefaultTimeout(15000);
  page.on('pageerror',e=>r.erros.push(e.message));
  await page.goto(endereco,{waitUntil});
  await page.waitForFunction(()=>window.CLOUD);
  await page.evaluate(()=>CLOUD.ready);
  return page;
}
async function ate(cond,rotulo){
  const fim=Date.now()+15000;
  while(!cond()){
    if(Date.now()>fim) assert.fail(rotulo);
    await new Promise(res=>setTimeout(res,50));
  }
}
/* Entrar pela tela, ver o dado do servidor falso chegar e gravar uma mudança. */
async function preencherLogin(page){
  await page.waitForSelector('#fLogin',{state:'visible'});
  await page.fill('#lEmail','ana@example.com');
  await page.fill('#lSenha','Obra2026x');
}
async function entrarESincronizar(page,r){
  await preencherLogin(page);
  await page.click('#fLogin button[type=submit]');
  await page.waitForFunction(()=>!document.body.classList.contains('locked'));
  await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra do falso'));
  await page.evaluate(()=>{ db.obras[0].nome='Obra alterada'; save(); });
  await ate(()=>r.escritas.some(e=>JSON.stringify(e).includes('Obra alterada')),'a escrita não chegou ao Firestore falso');
  await page.waitForFunction(()=>CLOUD.estado()==='ocioso');
}
/* Sem rede: navigator.onLine falso e todo o Google abortado (a rota mais nova vale
   primeiro). O site segue vindo do route, no lugar do service worker. */
async function tirarARede(ctx){
  await ctx.setOffline(true);
  await ctx.route(/^https:\/\/([^/]+\.)?(google|googleapis|gstatic)\.com\//,rota=>rota.abort());
}
/* Recarrega e devolve os ms, desde o início da navegação, até a obra estar na tela destravada. */
async function recarregarEMedir(page,nome){
  await page.reload();
  const marca=await page.waitForFunction(n=>!document.body.classList.contains('locked')&&document.body.innerText.includes(n)&&performance.now(),nome);
  return Math.round(await marca.jsonValue());
}
/* Deixa vencido o token do App Check guardado, como depois de uma hora sem abrir o app. Devolve quantos achou. */
const vencerTokenGuardado=page=>page.evaluate(()=>new Promise((pronto,falha)=>{
  const aberto=indexedDB.open('firebase-app-check-database');
  aberto.onerror=()=>falha(aberto.error);
  aberto.onsuccess=()=>{
    const banco=aberto.result, tx=banco.transaction('firebase-app-check-store','readwrite'), cursor=tx.objectStore('firebase-app-check-store').openCursor();
    let achados=0;
    cursor.onsuccess=()=>{
      const c=cursor.result;
      if(!c) return;
      c.update({...c.value,value:{...c.value.value,expireTimeMillis:Date.now()-1000}});
      achados++; c.continue();
    };
    tx.oncomplete=()=>{ banco.close(); pronto(achados); };
    tx.onerror=()=>falha(tx.error);
  };
}));
const semIncidentes=r=>{
  assert.deepEqual(r.violacoes,[],'violação de CSP');
  assert.deepEqual(r.erros,[],'erro de página');
  assert.deepEqual(r.fora,[],'pedido fora dos falsos');
};
/* No WebChannel o cabeçalho vai no corpo do POST, em minúsculas. */
const tokenDaAbertura=h=>/(?:^|\r\n)x-firebase-appcheck:([^\r\n]*)/i.exec(h)?.[1];

(async()=>{
  const browser=await chromium.launch();
  try{
    /* 1. Endereço publicado: pede o script, troca o token e o Firestore e o Auth levam o token. */
    {
      const {ctx,r}=await contexto(browser,['custta.com.br']);
      const page=await abrir(ctx,r,'https://custta.com.br/');
      await entrarESincronizar(page,r);
      assert.ok(r.script.length>0,'não pediu o script do reCAPTCHA');
      assert.match(r.script[0],/^https:\/\/www\.google\.com\/recaptcha\/enterprise\.js/);
      await ate(()=>r.troca.length>0,'não trocou o token do App Check');
      assert.equal(r.troca.length,1,'uma troca só');
      assert.ok(r.troca[0].url.includes('exchangeRecaptchaEnterpriseToken'),r.troca[0].url);
      assert.ok(r.troca[0].corpo.includes(TOKEN_RECAPTCHA),'o token do reCAPTCHA vai na troca');
      assert.ok(r.abertura.Listen.length>0,'abriu o Listen');
      assert.ok(r.abertura.Listen.every(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'Listen sem o token do App Check');
      assert.ok(r.abertura.Write.some(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'Write sem o token do App Check');
      assert.ok(r.auth.length>0&&r.auth.every(t=>t===TOKEN_APP_CHECK),'Auth sem o token do App Check');
      semIncidentes(r);
      console.log('ok - custta.com.br pede o reCAPTCHA, troca o token e Firestore e Auth levam o X-Firebase-AppCheck');
      await ctx.close();
    }
    /* 2. Outros endereços publicados também ligam. */
    for(const host of ['app-construcao-civil.vercel.app','app-construcao-civil-git-proto-b4-gstuchi.vercel.app']){
      const {ctx,r}=await contexto(browser,[host]);
      await abrir(ctx,r,`https://${host}/`);
      assert.ok(r.script.length>0,`${host} não pediu o script do reCAPTCHA`);
      semIncidentes(r);
      console.log(`ok - ${host} liga o App Check`);
      await ctx.close();
    }
    /* 3. Endereços não publicados não ligam, nem os parecidos com os publicados. */
    for(const endereco of ['http://127.0.0.1:8123/','http://localhost:8123/','https://custta.com.br.exemplo.net/','https://falso-vercel.app.exemplo.net/']){
      const url=new URL(endereco);
      const {ctx,r}=await contexto(browser,url.port?[]:[url.hostname]);
      const page=await abrir(ctx,r,endereco);
      await entrarESincronizar(page,r);
      assert.deepEqual(r.script,[],`${endereco} pediu o reCAPTCHA`);
      assert.deepEqual(r.troca,[],`${endereco} trocou token`);
      assert.ok(r.abertura.Listen.length>0,'abriu o Listen');
      assert.ok(!r.abertura.Listen.some(tokenDaAbertura),`${endereco}: o Listen levou token`);
      semIncidentes(r);
      console.log(`ok - ${url.host} não liga o App Check e entra e sincroniza`);
      await ctx.close();
    }
    /* 4. Script do reCAPTCHA bloqueado: entrar e sincronizar seguem, sem token e sem erro novo. */
    {
      const {ctx,r}=await contexto(browser,['custta.com.br'],{reCaptcha:'aborta'});
      const page=await abrir(ctx,r,'https://custta.com.br/');
      await entrarESincronizar(page,r);
      assert.ok(r.script.length>0,'não tentou carregar o script');
      assert.deepEqual(r.troca,[],'não pode trocar token sem o reCAPTCHA');
      semIncidentes(r);
      console.log('ok - script do reCAPTCHA bloqueado: entrar e sincronizar seguem, sem erro de página');
      await ctx.close();
    }
    /* 5. Sem rede, com dado em cache: a obra aparece na hora, com o token do App Check
       guardado válido ou vencido (o normal depois de uma hora): vencido, o provedor
       desiste sem esperar o prazo. */
    for(const vencido of [false,true]){
      const {ctx,r}=await contexto(browser,['custta.com.br']);
      const page=await abrir(ctx,r,'https://custta.com.br/');
      await entrarESincronizar(page,r);
      if(vencido) assert.ok(await vencerTokenGuardado(page)>0,'não achou o token guardado');
      await tirarARede(ctx);
      const ms=await recarregarEMedir(page,'Obra alterada');
      assert.ok(ms<1000,`a obra levou ${ms} ms para aparecer sem rede`);
      /* Sem rede, o WebChannel testa a conexão com um pixel do Google, que o img-src barra (com ou sem App Check). */
      r.violacoes=r.violacoes.filter(v=>!v.startsWith('img-src: https://www.google.com/images/cleardot.gif'));
      semIncidentes(r);
      console.log(`ok - sem rede, token ${vencido?'vencido':'válido'}: a obra em cache aparece em ${ms} ms`);
      await ctx.close();
    }
    /* 6. reCAPTCHA lento: o script chega 8 s depois do clique. O login destrava no prazo,
       antes dele, e o pedido seguinte já leva token válido: o prazo não prende o token. */
    {
      const {ctx,r}=await contexto(browser,['custta.com.br'],{reCaptcha:'lento'});
      /* O load espera o script injetado; aqui ele só chega depois do clique. O prazo conta
         do primeiro pedido de token, que o App Check faz logo na abertura, não do clique. */
      const aberto=Date.now();
      const page=await abrir(ctx,r,'https://custta.com.br/','domcontentloaded');
      await preencherLogin(page);
      const inicio=Date.now();
      setTimeout(r.soltaScript,8000);
      await page.click('#fLogin button[type=submit]');
      await page.waitForFunction(()=>!document.body.classList.contains('locked'));
      const ms=Date.now()-inicio;
      assert.ok(!r.scriptEntregue,'o login esperou o script chegar');
      assert.ok(Date.now()-aberto>=3900&&ms<6000,`o login destravou em ${ms} ms`);
      assert.deepEqual(r.troca,[],'trocou token antes do script chegar');
      assert.ok(r.auth.length>0&&!r.auth.includes(TOKEN_APP_CHECK),'o login não podia ter token válido');
      await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra do falso'));
      await ate(()=>r.troca.length>0,'não trocou o token depois que o script chegou');
      await page.waitForTimeout(300); // o provedor só solta a tentativa em voo depois da resposta da troca
      await page.evaluate(()=>{ db.obras[0].nome='Obra alterada'; save(); });
      await ate(()=>r.escritas.some(e=>JSON.stringify(e).includes('Obra alterada')),'a escrita não chegou ao Firestore falso');
      assert.ok(r.abertura.Write.some(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'o pedido seguinte não levou o token válido');
      semIncidentes(r);
      console.log(`ok - reCAPTCHA lento: login destrava em ${ms} ms e o pedido seguinte leva token válido`);
      await ctx.close();
    }
    /* 7. A resposta do 1º GET longo de cada canal chega depois que o cliente desistiu dele:
       o que saiu ali volta no GET seguinte, como no servidor real, e entrar e sincronizar
       seguem. Na CI isso acontecia ao acaso, quando a resposta demorava mais que 4x o RTT
       do handshake, e a escrita nunca chegava. */
    {
      const {ctx,r}=await contexto(browser,['custta.com.br'],{perdeOPrimeiroGet:true});
      const page=await abrir(ctx,r,'https://custta.com.br/');
      await entrarESincronizar(page,r);
      assert.ok(r.desistiu.Listen>0&&r.desistiu.Write>0,`o cliente não desistiu do 1º GET longo (${JSON.stringify(r.desistiu)}): o cenário não prova o reenvio`);
      semIncidentes(r);
      console.log('ok - resposta do 1º GET longo perdida: o que saiu nele volta no GET seguinte e a escrita chega');
      await ctx.close();
    }
  }finally{ await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
