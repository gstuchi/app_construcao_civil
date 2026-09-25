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

(async()=>{
  const env=await initializeTestEnvironment({projectId:PROJECT,firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(path.join(ROOT,'firestore.rules'),'utf8')}});
  const browser=await chromium.launch();
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
    await page.waitForFunction(()=>document.body.classList.contains('locked') && !CLOUD.user(),null,{timeout:20000});
    assert.equal(await page.locator('#fLogin').isVisible(),true);
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
    await page.evaluate(()=>window.dispatchEvent(new CustomEvent('cloud-google-erro',{detail:{code:'auth/account-exists-with-different-credential'}})));
    assert.equal(await page.textContent('#lMsg'),'Este e-mail já tem conta com senha. Entre com e-mail e senha.');
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

    // 10. app nativo (WKWebView) não mostra o Google
    {
      const ctxNativo=await novoContexto();
      // no aparelho a CSP vem da <meta> do www/ (libera a checagem de versão); o servidor serve a CSP web
      await ctxNativo.route(BASE+'/',async r=>{
        const resp=await r.fetch(); const h=resp.headers();
        h['content-security-policy']=h['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://app-construcao-civil.vercel.app");
        await r.fulfill({response:resp,headers:h});
      });
      await ctxNativo.route('https://app-construcao-civil.vercel.app/versao.json',r=>r.fulfill({contentType:'application/json',headers:{'access-control-allow-origin':'*'},body:fs.readFileSync(path.join(ROOT,'versao.json'),'utf8')}));
      await ctxNativo.addInitScript(()=>{ window.Capacitor={ isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:{} }; });
      const pNativo=await abrirApp(ctxNativo);
      assert.equal(await pNativo.evaluate(()=>OBRA_NATIVO.ehNativo()),true);
      assert.equal(await pNativo.locator('#authGoogle').isVisible(),false);
      await pNativo.locator('#authTabs button[data-k="cad"]').click();
      assert.equal(await pNativo.locator('#authGoogle').isVisible(),false);
      console.log('ok - no app nativo o botão do Google fica escondido');
      await ctxNativo.close();
    }

    // 11.
    assert.deepEqual(violacoes,[]); assert.deepEqual(errosPagina,[]);
    console.log('ok - nenhuma violação de CSP nem erro de página');
  }finally{ await browser.close(); await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
