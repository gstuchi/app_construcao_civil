/* Login com Google pela UI, com o popup do Auth emulator e Firestore reais nos emuladores.
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
     --only firestore,auth "node tests/browser/google.cjs"
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
async function entrarGooglePeloEmulador(page, email, nome){
  const popup=await abrirPopup(page, ()=>page.locator('#btnGoogle').click());
  await popup.locator('#add-account-button').click();
  await popup.locator('#email-input').fill(email);
  await popup.locator('#display-name-input').fill(nome);
  await popup.locator('#sign-in').click();
}
// Conta Google já criada no emulador: escolhe pelo e-mail na lista.
async function escolherConta(popup, email){
  await popup.locator('.js-reuse-account',{hasText:email}).first().click();
}
const travado=page=>page.evaluate(()=>document.body.classList.contains('locked'));
/* O logout limpa o cache e recarrega a página. Esperar só o "locked" deixa o
   próximo page.evaluate correr contra o reload; espera o documento novo. */
async function sair(page){
  const antes=await page.evaluate(()=>window.__documentoId);
  await page.locator('#btnSair:visible, #btnSairSide:visible').first().click();
  await page.locator('dialog.confirma-dialog [data-acao=confirmar]').click();
  await page.waitForFunction(antes=>window.__documentoId !== antes && window.CLOUD && !CLOUD.user() && !CLOUD.cacheBloqueado() && document.body.classList.contains('locked'),antes,{timeout:30000});
}

/* App nativo: CSP da <meta> do www/ (libera a checagem de versão) e plugin GoogleSignIn
   falso. O id_token em JSON é aceito pelo Auth emulator sem assinatura. Pedidos ficam
   espelhados no sessionStorage porque sair e apagar recarregam a página. */
async function contextoNativo(novoContexto){
  const ctx=await novoContexto();
  await ctx.route(BASE+'/',async r=>{
    const resp=await r.fetch(); const h=resp.headers();
    h['content-security-policy']=h['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://app-construcao-civil.vercel.app");
    await r.fulfill({response:resp,headers:h});
  });
  await ctx.route('https://app-construcao-civil.vercel.app/versao.json',r=>r.fulfill({contentType:'application/json',headers:{'access-control-allow-origin':'*'},body:fs.readFileSync(path.join(ROOT,'versao.json'),'utf8')}));
  await ctx.addInitScript(()=>{
    const registra=p=>{ const l=JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]'); l.push(p); sessionStorage.setItem('__pedidosGoogle',JSON.stringify(l)); };
    window.Capacitor={ isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:{
      GoogleSignIn:{
        initialize:async a=>{ registra(['initialize',a]); },
        signIn:async()=>{ registra(['signIn']); const r=JSON.parse(sessionStorage.getItem('__respostaGoogle')||'null');
          if(r && r.erro) throw Object.assign(new Error(r.erro.message),{code:r.erro.code}); return r; },
        signOut:async()=>{ registra(['signOut']); } } } };
  });
  return ctx;
}
const idTokenGoogle=(sub,email,name)=>JSON.stringify({sub,email,email_verified:true,name});
const pedidosGoogle=page=>page.evaluate(()=>JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]'));
const respostaGoogle=(page,r)=>page.evaluate(r=>sessionStorage.setItem('__respostaGoogle',JSON.stringify(r)),r);

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
  try{
    const context=await novoContexto();
    const page=await abrirApp(context);

    // 1. botão nas duas abas; "Falta pouco" escondido
    await page.locator('#authTabs button[data-k="cad"]').click();
    assert.equal(await page.locator('#btnGoogle').isVisible(),true);
    await page.locator('#authTabs button[data-k="login"]').click();
    assert.equal(await page.locator('#btnGoogle').isVisible(),true);
    assert.equal(await page.locator('#fPerfil').isVisible(),false);
    console.log('ok - botão do Google nas abas Entrar e Criar conta, sem "Falta pouco"');

    // 2. primeiro login Google cai no "Falta pouco" com o nome do Google
    await entrarGooglePeloEmulador(page,'ana.google@example.com','Ana Maria Souza');
    await page.waitForSelector('#fPerfil',{state:'visible'});
    assert.equal(await page.inputValue('#pNome'),'Ana');
    assert.equal(await page.inputValue('#pSobrenome'),'Maria Souza');
    assert.equal(await travado(page),true);
    const uidAna=await page.evaluate(()=>CLOUD.user().uid);
    assert.deepEqual(await page.evaluate(()=>CLOUD.user().provedores),['google.com']);
    console.log('ok - primeiro login Google abre "Falta pouco" com nome e sobrenome do Google');

    // 3. origem obrigatória
    await page.locator('#fPerfil button[type=submit]').click();
    assert.equal(await page.textContent('#pMsg'),'Conte como conheceu o Custta.');
    assert.equal(await page.evaluate(()=>document.activeElement.id),'pOrigem');
    console.log('ok - "Falta pouco" sem origem avisa e foca a origem');

    // 4. completar perfil destrava e grava perfis/{uid}
    await page.selectOption('#pOrigem','indicacao');
    await page.locator('#pDetalhe').fill('Seu João');
    await page.locator('#fPerfil button[type=submit]').click();
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    const perfil=(await leDoc('perfis',uidAna)).data();
    assert.equal(perfil.nome,'Ana'); assert.equal(perfil.sobrenome,'Maria Souza');
    assert.equal(perfil.origem,'indicacao'); assert.equal(perfil.origemDetalhe,'Seu João');
    assert.equal(perfil.email,'ana.google@example.com');
    assert.ok(perfil.tz); assert.ok(perfil.criado);
    console.log('ok - completar o perfil destrava e grava nome, origem e detalhe');

    // 5. Ajustes de conta só Google
    await page.locator('nav.tabs [data-tab="ajustes"]').click();
    await page.waitForSelector('#ajApagar',{state:'visible'});
    assert.equal(await page.locator('#ajSenha').isVisible(),false);
    assert.equal(await page.locator('#avisoEmail').isVisible(),false);
    assert.equal(await page.locator('#ajVerificacao').isVisible(),false);
    console.log('ok - conta só Google não oferece trocar senha nem confirmar e-mail');

    // 6. sair e voltar com a mesma conta: entra direto
    await sair(page);
    {
      const popup=await abrirPopup(page,()=>page.locator('#btnGoogle').click());
      await escolherConta(popup,'ana.google@example.com');
    }
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    assert.equal(await page.locator('#fPerfil').isVisible(),false);
    assert.equal(await page.evaluate(()=>CLOUD.user().uid),uidAna);
    console.log('ok - segundo login Google destrava direto, sem "Falta pouco"');

    // 7. apagar conta só Google: sem senha, confirma no popup do Google
    assert.equal((await leDoc('perfis',uidAna)).exists(),true);
    await page.locator('nav.tabs [data-tab="ajustes"]').click();
    await page.locator('#ajApagar').click();
    await page.waitForSelector('#contaConfirmacao',{state:'visible'});
    assert.equal(await page.locator('#contaSenha').count(),0);
    await page.locator('#contaConfirmacao').fill('APAGAR');
    {
      const popup=await abrirPopup(page,()=>page.locator('#contaEnviar').click());
      assert.equal(await page.locator('#contaMensagem').textContent(),'Confirme sua conta Google na janela que abriu.');
      await escolherConta(popup,'ana.google@example.com');
    }
    // window.CLOUD: durante a recarga o documento novo ainda não tem CLOUD, e CLOUD solto estoura ReferenceError
    await page.waitForFunction(()=>document.body.classList.contains('locked') && window.CLOUD && !CLOUD.user(),null,{timeout:20000});
    /* apagar a conta limpa o cache local e recarrega: a condição acima pode valer ainda na página
       velha, e o formulário só aparece depois da recarga. Espera ele em vez de conferir na hora
       (no runner da CI, com a página mais pesada de pintar, a conferência imediata pegava o meio) */
    await page.locator('#fLogin').waitFor({ state:'visible', timeout:20000 });
    for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uidAna)).exists(),false,`${colecao}/${uidAna} sobrou`);
    console.log('ok - apagar conta Google reautentica pelo popup e remove dados, perfis e push');

    // 8. conta com senha que depois entra com Google no mesmo e-mail
    await page.locator('#authTabs button[data-k="cad"]').click();
    await page.locator('#cNome').fill('Bia');
    await page.locator('#cEmail').fill('dupla@example.com');
    await page.locator('#cSenha').fill('Obra2026x'); await page.locator('#cSenha2').fill('Obra2026x');
    await page.selectOption('#cOrigem','instagram');
    await page.locator('#fCad button[type=submit]').click();
    await page.waitForFunction(()=>CLOUD.user() && !document.querySelector('#fCad button[type=submit]').disabled);
    const uidBia=await page.evaluate(()=>CLOUD.user().uid);
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    await sair(page);
    await entrarGooglePeloEmulador(page,'dupla@example.com','Bia');
    await page.waitForFunction(()=>CLOUD.user() && (!document.body.classList.contains('locked') || !document.getElementById('fPerfil').classList.contains('hidden')));
    // perfilPendente é assíncrono: dá tempo de ele decidir antes de afirmar
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    assert.equal(await page.locator('#fPerfil').isVisible(),false);
    const bia=await page.evaluate(()=>CLOUD.user());
    assert.equal(bia.uid,uidBia);
    await page.locator('nav.tabs [data-tab="ajustes"]').click();
    await page.waitForSelector('#ajApagar',{state:'visible'});
    const senhaVisivel=await page.locator('#ajSenha').isVisible();
    if(bia.provedores.includes('password')){
      assert.equal(senhaVisivel,true);
      console.log(`ok - senha + Google no mesmo e-mail: mesmo uid, provedores ${bia.provedores.join(',')}, "Trocar senha" visível`);
    }else{
      console.log(`ok - senha + Google no mesmo e-mail: emulador substituiu o provedor password (e-mail não verificado); mesmo uid, provedores ${bia.provedores.join(',')}, "Trocar senha" ${senhaVisivel?'visível':'escondido'}`);
    }

    // 9. erro na volta do redirect aparece na tela de login
    await sair(page);
    await page.evaluate(()=>window.dispatchEvent(new CustomEvent('cloud-social-erro',{detail:{code:'auth/account-exists-with-different-credential',provedor:'google.com'}})));
    assert.equal(await page.textContent('#lMsg'),'Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez.');
    console.log('ok - erro do redirect vira mensagem em português no login');

    // 9b. a mensagem velha do Google não volta depois de entrar por e-mail e sair
    await page.locator('#authTabs button[data-k="cad"]').click();
    await page.locator('#cNome').fill('Carla');
    await page.locator('#cEmail').fill('carla@example.com');
    await page.locator('#cSenha').fill('Obra2026x'); await page.locator('#cSenha2').fill('Obra2026x');
    await page.selectOption('#cOrigem','instagram');
    await page.locator('#fCad button[type=submit]').click();
    await page.waitForFunction(()=>!document.body.classList.contains('locked'));
    await sair(page);
    assert.equal(await page.textContent('#lMsg'),'');
    console.log('ok - erro antigo do Google some depois de entrar por e-mail e sair');
    await context.close();

    // 9c. duas abas no "Falta pouco": a que salva por último não fica presa
    {
      const ctxAbas=await novoContexto();
      const abaA=await abrirApp(ctxAbas);
      await entrarGooglePeloEmulador(abaA,'duas.abas@example.com','Davi Lima');
      await abaA.waitForSelector('#fPerfil',{state:'visible'});
      const abaB=await abrirApp(ctxAbas);
      await abaB.waitForSelector('#fPerfil',{state:'visible'});
      for(const aba of [abaA,abaB]) await aba.selectOption('#pOrigem','youtube');
      await abaA.locator('#fPerfil button[type=submit]').click();
      await abaA.waitForFunction(()=>!document.body.classList.contains('locked'));
      await abaB.locator('#fPerfil button[type=submit]').click();
      await abaB.waitForFunction(()=>!document.body.classList.contains('locked'));
      assert.equal(await abaB.textContent('#pMsg'),'');
      console.log('ok - segunda aba no "Falta pouco" destrava quando a outra já gravou o perfil');
      await ctxAbas.close();
    }

    // 10-14. app nativo (WKWebView) com o plugin GoogleSignIn falso
    {
      const ctxNativo=await contextoNativo(novoContexto);
      const pNativo=await abrirApp(ctxNativo);
      assert.equal(await pNativo.evaluate(()=>OBRA_NATIVO.ehNativo()),true);

      // 10. Apple e Google nas duas abas, Apple em cima, mesmo tamanho
      for(const aba of ['cad','login']){
        await pNativo.locator(`#authTabs button[data-k="${aba}"]`).click();
        assert.equal(await pNativo.locator('#btnGoogle').isVisible(),true);
        assert.equal(await pNativo.locator('#btnApple').isVisible(),true);
        // a troca de aba anima o cartão com transform: espera assentar para medir o tamanho real
        await pNativo.waitForFunction(()=>document.getAnimations().every(an=>an.effect.getComputedTiming().iterations===Infinity || an.playState==='finished'));
        const a=await pNativo.locator('#btnApple').boundingBox(), g=await pNativo.locator('#btnGoogle').boundingBox();
        assert.ok(a.y<g.y,`Apple deve ficar acima do Google (${a.y} vs ${g.y})`);
        assert.equal(Math.round(a.width),Math.round(g.width)); assert.equal(Math.round(a.height),Math.round(g.height));
      }
      console.log('ok - app: Google aparece abaixo da Apple, do mesmo tamanho, nas abas Entrar e Criar conta');

      // 11. desistência: nenhum erro na tela, botões voltam
      await respostaGoogle(pNativo,{erro:{code:'SIGN_IN_CANCELED',message:'The user canceled the sign-in flow.'}});
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForFunction(()=>!document.querySelector('#btnGoogle').disabled && JSON.parse(sessionStorage.getItem('__pedidosGoogle')||'[]').some(p=>p[0]==='signIn'));
      assert.equal(await pNativo.textContent('#lMsg'),'');
      assert.equal(await travado(pNativo),true);
      assert.deepEqual((await pedidosGoogle(pNativo))[0],['initialize',{clientId:'111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com'}]);
      console.log('ok - app: desistir da folha do Google não mostra erro; initialize com o client web');

      // 12. primeiro login no app: "Falta pouco" com o nome do Google
      await respostaGoogle(pNativo,{idToken:idTokenGoogle('google-gabi','gabi.app@example.com','Gabi Souza Lima')});
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForSelector('#fPerfil',{state:'visible'});
      assert.equal(await pNativo.inputValue('#pNome'),'Gabi');
      assert.equal(await pNativo.inputValue('#pSobrenome'),'Souza Lima');
      assert.deepEqual(await pNativo.evaluate(()=>CLOUD.user().provedores),['google.com']);
      await pNativo.selectOption('#pOrigem','instagram');
      await pNativo.locator('#fPerfil button[type=submit]').click();
      await pNativo.waitForFunction(()=>!document.body.classList.contains('locked'));
      const uidGabi=await pNativo.evaluate(()=>CLOUD.user().uid);
      const perfilGabi=(await leDoc('perfis',uidGabi)).data();
      assert.equal(perfilGabi.nome,'Gabi'); assert.equal(perfilGabi.sobrenome,'Souza Lima');
      assert.equal(perfilGabi.email,'gabi.app@example.com');
      console.log('ok - app: primeiro login Google abre "Falta pouco" com o nome do Google e grava o perfil');

      // 13. sair esquece o Google; entrar de novo com a mesma conta cai no mesmo uid, direto
      await sair(pNativo);
      assert.ok((await pedidosGoogle(pNativo)).some(p=>p[0]==='signOut'),'sair deveria chamar GoogleSignIn.signOut');
      await pNativo.locator('#btnGoogle').click();
      await pNativo.waitForFunction(()=>!document.body.classList.contains('locked'));
      assert.equal(await pNativo.evaluate(()=>CLOUD.user().uid),uidGabi);
      assert.equal(await pNativo.locator('#fPerfil').isVisible(),false);
      console.log('ok - app: sair esquece o Google e voltar com a mesma conta entra direto no mesmo uid');

      // 14. apagar conta só Google no app: reautentica pelo plugin, não revoga, remove tudo
      const revogacoes=[];
      await ctxNativo.route(/accounts:revokeToken/,r=>{ revogacoes.push(r.request().url()); return r.fulfill({status:200,contentType:'application/json',body:'{}'}); });
      const signInsAntes=(await pedidosGoogle(pNativo)).filter(p=>p[0]==='signIn').length;
      await pNativo.locator('nav.tabs [data-tab="ajustes"]').click();
      await pNativo.locator('#ajApagar').click();
      await pNativo.waitForSelector('#contaConfirmacao',{state:'visible'});
      await pNativo.locator('#contaConfirmacao').fill('APAGAR');
      await pNativo.locator('#contaEnviar').click();
      await pNativo.waitForFunction(()=>document.body.classList.contains('locked') && window.CLOUD && !CLOUD.user(),null,{timeout:20000});
      await pNativo.locator('#fLogin').waitFor({state:'visible',timeout:20000});
      for(const colecao of ['dados','perfis','push']) assert.equal((await leDoc(colecao,uidGabi)).exists(),false,`${colecao}/${uidGabi} sobrou`);
      assert.equal((await pedidosGoogle(pNativo)).filter(p=>p[0]==='signIn').length,signInsAntes+1,'reautenticação pelo plugin');
      assert.deepEqual(revogacoes,[],'conta Google não revoga token (isso é só da Apple)');
      console.log('ok - app: apagar conta só Google reautentica pelo plugin, não revoga e remove os dados');
      await ctxNativo.close();
    }

    // 15.
    assert.deepEqual(violacoes,[]); assert.deepEqual(errosPagina,[]);
    console.log('ok - nenhuma violação de CSP nem erro de página');
  }finally{ await browser.close(); await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
