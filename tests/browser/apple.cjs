/* Login com Apple pela UI: web com o popup do Auth emulator, app com o plugin AppleSignIn
   falso; Firestore e Auth reais nos emuladores.
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
     --only firestore,auth "node tests/browser/apple.cjs"
   O emulador responde ao signInWithPopup com a própria página em
   http://127.0.0.1:9099/emulator/auth/handler: "Add new account" (#add-account-button)
   abre o formulário (#email-input, #display-name-input) e #sign-in conclui; contas
   já criadas aparecem como .js-reuse-account na lista. */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {doc,getDoc}=require('firebase/firestore');
const PROJECT='demo-custta-phase2';
const ROOT=path.resolve(__dirname,'../..');
/* 127.0.0.1, não localhost: o iframe do Auth emulator (127.0.0.1:9099) precisa
   ser do mesmo site que o app. Com localhost ele vira iframe de terceiro, o
   Chromium nega sessionStorage a ele e o evento do popup nunca chega ao SDK. */
const BASE='http://127.0.0.1:8123';
const cloudEmulado=()=>fs.readFileSync(path.join(ROOT,'cloud.js'),'utf8')
  .replace("projectId: 'app-construcao-civil'",`projectId: '${PROJECT}'`)
  .replace('sendPasswordResetEmail, signOut,','sendPasswordResetEmail, signOut, connectAuthEmulator,')
  .replace('deleteField, waitForPendingWrites,','deleteField, waitForPendingWrites, connectFirestoreEmulator,')
  .replace('const auth = getAuth(app);',"const auth = getAuth(app); connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});")
  .replace('const CHAVE_LIMPEZA',"connectFirestoreEmulator(db,'127.0.0.1',8080);\nconst CHAVE_LIMPEZA");

async function abrirPopup(page, gatilho){
  const [popup]=await Promise.all([page.waitForEvent('popup'), gatilho()]);
  await popup.waitForLoadState();
  return popup;
}
async function entrarApplePeloEmulador(page, email, nome){
  const popup=await abrirPopup(page, ()=>page.locator('#btnApple').click());
  await popup.locator('#add-account-button').click();
  await popup.locator('#email-input').fill(email);
  if(nome) await popup.locator('#display-name-input').fill(nome);
  await popup.locator('#sign-in').click();
}
// Conta Apple já criada no emulador: escolhe pelo e-mail na lista.
async function escolherConta(popup, email){
  await popup.locator('.js-reuse-account',{hasText:email}).first().click();
}
/* Revogação: na web o SDK chama o emulador; no app o cloud.js chama a produção.
   As duas passam por aqui e nunca saem da máquina. O POST é JSON cross-origin: o
   Chromium pode mandar preflight OPTIONS, respondido sem entrar em `pedidos`. */
async function interceptaRevogacao(context, status=200){
  const pedidos=[];
  await context.route(/accounts:revokeToken/, async r=>{
    const cors={'access-control-allow-origin':'*','access-control-allow-headers':'*','access-control-allow-methods':'POST, OPTIONS'};
    if(r.request().method()==='OPTIONS') return r.fulfill({status:204,headers:cors});
    pedidos.push(r.request().postDataJSON());
    await r.fulfill({status, contentType:'application/json', headers:cors, body:status===200?'{}':'{"error":{"code":500,"message":"INTERNAL"}}'});
  });
  return pedidos;
}
/* App nativo: CSP da <meta> do www/ (libera a checagem de versão) e plugin AppleSignIn
   falso. O id_token em JSON é aceito pelo Auth emulator sem assinatura. */
async function contextoNativo(novoContexto){
  const ctx=await novoContexto();
  await ctx.route(BASE+'/',async r=>{
    const resp=await r.fetch(); const h=resp.headers();
    h['content-security-policy']=h['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://app-construcao-civil.vercel.app");
    await r.fulfill({response:resp,headers:h});
  });
  await ctx.route('https://app-construcao-civil.vercel.app/versao.json',r=>r.fulfill({contentType:'application/json',headers:{'access-control-allow-origin':'*'},body:fs.readFileSync(path.join(ROOT,'versao.json'),'utf8')}));
  await ctx.addInitScript(()=>{
    // o apagar recarrega a página: o espelho no sessionStorage guarda os pedidos além do reload
    window.__pedidosApple=JSON.parse(sessionStorage.getItem('__pedidosApple')||'[]'); window.__respostaApple=null;
    window.Capacitor={ isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:{
      AppleSignIn:{ signIn:async a=>{ window.__pedidosApple.push(a); sessionStorage.setItem('__pedidosApple',JSON.stringify(window.__pedidosApple)); const r=window.__respostaApple; if(r && r.erro) throw Object.assign(new Error(r.erro.message),{code:r.erro.code}); return r; } } } };
  });
  return ctx;
}
const idTokenFalso=(sub,email)=>JSON.stringify({sub,email,email_verified:true});
const travado=page=>page.evaluate(()=>document.body.classList.contains('locked'));
/* O logout limpa o cache e recarrega a página. Esperar só o "locked" deixa o
   próximo page.evaluate correr contra o reload; espera o documento novo. */
async function sair(page){
  const antes=await page.evaluate(()=>window.__documentoId);
  await page.locator('#btnSair:visible, #btnSairSide:visible').first().click();
  await page.locator('dialog.confirma-dialog [data-acao=confirmar]').click();
  await page.waitForFunction(antes=>window.__documentoId !== antes && window.CLOUD && !CLOUD.user() && !CLOUD.cacheBloqueado() && document.body.classList.contains('locked'),antes,{timeout:30000});
}

(async()=>{
  const env=await initializeTestEnvironment({projectId:PROJECT,firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(path.join(ROOT,'firestore.rules'),'utf8')}});
  /* No contexto nativo o documento sai de um route (CSP da <meta> do www/) e o Chromium o trata
     como espaço público: nega (Local Network Access) as chamadas aos emuladores em 127.0.0.1,
     que em produção não existem. A flag desliga só essa checagem, neste navegador de teste. */
  const browser=await chromium.launch({args:['--disable-features=LocalNetworkAccessChecks']});
  // withSecurityRulesDisabled descarta o retorno do callback: grava em variável de fora.
  const leDoc=async(colecao,uid)=>{
    let snap; await env.withSecurityRulesDisabled(async ctx=>{ snap=await getDoc(doc(ctx.firestore(),colecao,uid)); });
    return snap;
  };
  const violacoes=[], errosPagina=[];
  const novoContexto=async(opcoes={})=>{
    const context=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844},...opcoes});
    await context.exposeBinding('__registraCSP',(_s,info)=>violacoes.push(info));
    await context.addInitScript(()=>addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI)));
    const source=cloudEmulado();
    await context.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:source}));
    await context.addInitScript(()=>{ sessionStorage.setItem('splashVista','1'); window.__documentoId=crypto.randomUUID(); });
    return context;
  };
  const abrirApp=async context=>{
    const page=await context.newPage(); page.setDefaultTimeout(15000);
    page.on('pageerror',err=>errosPagina.push(err.message));
    await page.goto(BASE); await page.waitForFunction(()=>window.CLOUD);
    await page.evaluate(()=>CLOUD.ready);
    return page;
  };
  // Ajustes → Apagar conta → digita APAGAR (o envio fica com quem chama)
  const abrirApagar=async page=>{
    await page.locator('nav.tabs [data-tab="ajustes"]').click();
    await page.locator('#ajApagar').click();
    await page.waitForSelector('#contaConfirmacao',{state:'visible'});
    await page.locator('#contaConfirmacao').fill('APAGAR');
  };
  const esperaContaApagada=async page=>{
    await page.waitForFunction(()=>document.body.classList.contains('locked') && !CLOUD.user(),null,{timeout:20000});
    // o apagar recarrega a página; espera o formulário em vez de conferir na hora
    await page.locator('#fLogin').waitFor({ state:'visible', timeout:20000 });
  };
  try{
    const context=await novoContexto();
    const page=await abrirApp(context);

    // 1. botões nas duas abas, Apple acima do Google
    for(const aba of ['cad','login']){
      await page.locator(`#authTabs button[data-k="${aba}"]`).click();
      assert.equal(await page.locator('#btnApple').isVisible(),true);
      assert.equal(await page.locator('#btnGoogle').isVisible(),true);
      // a troca de aba anima o cartão com transform: espera assentar para medir o tamanho real
      await page.waitForFunction(()=>{
        // animações finitas (entrada do cartão) terminadas e altura do botão já no tamanho cheio
        const correndo=document.getAnimations().filter(an=>an.effect.getComputedTiming().iterations!==Infinity && an.playState!=='finished');
        return correndo.length===0 && document.getElementById('btnApple').getBoundingClientRect().height>=44;
      });
      const a=await page.locator('#btnApple').boundingBox(), g=await page.locator('#btnGoogle').boundingBox();
      assert.ok(a.y<g.y,`Apple deve ficar acima do Google (${a.y} vs ${g.y})`);
      assert.ok(a.height>=44,`altura da Apple ${a.height}`);
      assert.ok(Math.abs(a.height-g.height)<=1,`alturas diferentes: ${a.height} vs ${g.height}`);
    }
    assert.equal(await page.locator('#fPerfil').isVisible(),false);
    console.log('ok - botões Apple e Google nas abas Entrar e Criar conta, Apple acima e do mesmo tamanho');

    // 2. primeiro login Apple: "Falta pouco" só com a origem
    await entrarApplePeloEmulador(page,'bia@privaterelay.appleid.com','Beatriz Lima');
    await page.waitForSelector('#fPerfil',{state:'visible'});
    assert.equal(await page.locator('#pNomes').isVisible(),false);
    assert.equal(await page.textContent('#pTexto'),'Só falta contar como você conheceu o Custta.');
    assert.deepEqual(await page.evaluate(()=>CLOUD.user().provedores),['apple.com']);
    assert.equal(await travado(page),true);
    const uidBia=await page.evaluate(()=>CLOUD.user().uid);
    console.log('ok - primeiro login Apple abre "Falta pouco" sem pedir nome');

    // 3. completar perfil com o nome que a Apple mandou
    await page.selectOption('#pOrigem','instagram');
    await page.locator('#fPerfil button[type=submit]').click();
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    const perfil=(await leDoc('perfis',uidBia)).data();
    assert.equal(perfil.nome,'Beatriz'); assert.equal(perfil.sobrenome,'Lima');
    assert.equal(perfil.origem,'instagram');
    assert.equal(perfil.email,'bia@privaterelay.appleid.com');
    assert.ok(perfil.tz); assert.ok(perfil.criado);
    console.log('ok - completar o perfil destrava e grava nome da Apple, sobrenome, origem e e-mail');

    // 4. Ajustes de conta só Apple
    await page.locator('nav.tabs [data-tab="ajustes"]').click();
    await page.waitForSelector('#ajApagar',{state:'visible'});
    assert.equal(await page.locator('#ajSenha').isVisible(),false);
    assert.equal(await page.locator('#avisoEmail').isVisible(),false);
    console.log('ok - conta só Apple não oferece trocar senha nem confirmar e-mail');

    // 5. sair e voltar com a mesma conta: entra direto
    await sair(page);
    {
      const popup=await abrirPopup(page,()=>page.locator('#btnApple').click());
      await escolherConta(popup,'bia@privaterelay.appleid.com');
    }
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    assert.equal(await page.locator('#fPerfil').isVisible(),false);
    assert.equal(await page.evaluate(()=>CLOUD.user().uid),uidBia);
    console.log('ok - segundo login Apple destrava direto, sem "Falta pouco"');

    // 6. apagar conta Apple: sem senha, reautentica no popup e revoga o token
    const revogacoes=await interceptaRevogacao(context);
    assert.equal((await leDoc('perfis',uidBia)).exists(),true);
    await abrirApagar(page);
    assert.equal(await page.locator('#contaSenha').count(),0);
    {
      const popup=await abrirPopup(page,()=>page.locator('#contaEnviar').click());
      assert.equal(await page.locator('#contaMensagem').textContent(),'Confirme sua conta Apple na janela que abriu.');
      await escolherConta(popup,'bia@privaterelay.appleid.com');
    }
    await esperaContaApagada(page);
    for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uidBia)).exists(),false,`${colecao}/${uidBia} sobrou`);
    assert.equal(revogacoes.length,1);
    assert.equal(revogacoes[0].providerId,'apple.com');
    assert.equal(revogacoes[0].tokenType,'ACCESS_TOKEN');
    assert.ok(revogacoes[0].token);
    console.log('ok - apagar conta Apple reautentica pelo popup, revoga o token e remove dados, perfis e push');
    await context.close();

    // 7. Apple sem nome e revogação falhando: perfil sem nome; conta apagada mesmo assim
    {
      const ctx=await novoContexto();
      const revFalha=await interceptaRevogacao(ctx,500);
      const p=await abrirApp(ctx);
      await entrarApplePeloEmulador(p,'sem.nome@privaterelay.appleid.com');
      await p.waitForSelector('#fPerfil',{state:'visible'});
      assert.equal(await p.locator('#pNomes').isVisible(),false);
      const uid=await p.evaluate(()=>CLOUD.user().uid);
      await p.selectOption('#pOrigem','youtube');
      await p.locator('#fPerfil button[type=submit]').click();
      await p.waitForFunction(()=>!document.body.classList.contains('locked'));
      const dados=(await leDoc('perfis',uid)).data();
      assert.equal('nome' in dados,false);
      assert.equal(dados.origem,'youtube');
      await abrirApagar(p);
      {
        const popup=await abrirPopup(p,()=>p.locator('#contaEnviar').click());
        await escolherConta(popup,'sem.nome@privaterelay.appleid.com');
      }
      await esperaContaApagada(p);
      for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uid)).exists(),false,`${colecao}/${uid} sobrou`);
      assert.ok(revFalha.length>=1,'a revogação deveria ter sido tentada');
      console.log('ok - Apple sem nome grava perfil sem nome e a conta é apagada mesmo com a revogação falhando');
      await ctx.close();
    }

    // 8-10. app nativo (WKWebView) com o plugin AppleSignIn falso
    {
      const ctxNativo=await contextoNativo(novoContexto);
      const pNativo=await abrirApp(ctxNativo);
      assert.equal(await pNativo.evaluate(()=>OBRA_NATIVO.ehNativo()),true);

      // 8. desistência: nenhum erro na tela, botões voltam
      await pNativo.evaluate(()=>{ window.__respostaApple={erro:{code:'SIGN_IN_CANCELED',message:'Sign in was canceled.'}}; });
      await pNativo.locator('#btnApple').click();
      await pNativo.waitForFunction(()=>!document.querySelector('#btnApple').disabled && window.__pedidosApple.length===1);
      assert.equal(await pNativo.textContent('#lMsg'),'');
      assert.equal(await travado(pNativo),true);
      assert.equal(await pNativo.locator('#btnGoogle').isVisible(),false);
      assert.equal(await pNativo.locator('#btnApple').isVisible(),true);
      console.log('ok - app: desistir da tela da Apple não mostra erro e mantém o login disponível');

      // 9. primeiro login no app
      const resposta={idToken:idTokenFalso('apple-caio','caio@privaterelay.appleid.com'),authorizationCode:'codigo-caio',givenName:'Caio',familyName:'Prado'};
      await pNativo.evaluate(r=>{ window.__respostaApple=r; },resposta);
      await pNativo.locator('#btnApple').click();
      await pNativo.waitForSelector('#fPerfil',{state:'visible'});
      assert.equal(await pNativo.locator('#pNomes').isVisible(),false);
      const pedidos=await pNativo.evaluate(()=>window.__pedidosApple);
      const ultimo=pedidos[pedidos.length-1];
      assert.deepEqual(ultimo.scopes,['EMAIL','FULL_NAME']);
      assert.match(ultimo.nonce,/^[0-9a-f]{64}$/);
      const nonce1=ultimo.nonce;
      // o nome chega ao perfil local por updateProfile, depois do onAuthStateChanged
      await pNativo.waitForFunction(()=>CLOUD.user()?.nomeExibicao==='Caio Prado');
      await pNativo.selectOption('#pOrigem','google');
      await pNativo.locator('#fPerfil button[type=submit]').click();
      await pNativo.waitForFunction(()=>!document.body.classList.contains('locked'));
      const uidCaio=await pNativo.evaluate(()=>CLOUD.user().uid);
      const perfilCaio=(await leDoc('perfis',uidCaio)).data();
      assert.equal(perfilCaio.nome,'Caio'); assert.equal(perfilCaio.sobrenome,'Prado');
      console.log('ok - app: primeiro login Apple usa nonce SHA-256, pede e-mail e nome e grava o perfil com o nome da Apple');

      // 10. apagar conta no app: reautentica com o plugin e revoga com o código
      const rev=await interceptaRevogacao(ctxNativo);
      await abrirApagar(pNativo);
      await pNativo.locator('#contaEnviar').click();
      await esperaContaApagada(pNativo);
      for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uidCaio)).exists(),false,`${colecao}/${uidCaio} sobrou`);
      assert.equal(rev.length,1);
      assert.equal(rev[0].providerId,'apple.com');
      assert.equal(rev[0].tokenType,'CODE');
      assert.equal(rev[0].token,'codigo-caio');
      assert.ok(rev[0].idToken);
      const todos=await pNativo.evaluate(()=>JSON.parse(sessionStorage.getItem('__pedidosApple')));
      assert.equal(todos.length,3);
      assert.match(todos[2].nonce,/^[0-9a-f]{64}$/);
      assert.notEqual(todos[2].nonce,nonce1);
      console.log('ok - app: apagar conta reautentica pelo plugin, revoga com o código e remove os dados');
      await ctxNativo.close();
    }

    // 11.
    assert.deepEqual(violacoes,[]); assert.deepEqual(errosPagina,[]);
    console.log('ok - nenhuma violação de CSP nem erro de página');
  }finally{ await browser.close(); await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
