/* Cadastro completo pela UI, Auth e Firestore reais nos emuladores locais.
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
     --only firestore,auth "node tests/browser/cadastro.cjs" */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc}=require('firebase/firestore');
const PROJECT='demo-custta-phase2';
const ROOT=path.resolve(__dirname,'../..');
const cloudEmulado=()=>fs.readFileSync(path.join(ROOT,'cloud.js'),'utf8')
  .replace("projectId: 'app-construcao-civil'",`projectId: '${PROJECT}'`)
  .replace('sendPasswordResetEmail, signOut,','sendPasswordResetEmail, signOut, connectAuthEmulator,')
  .replace('deleteField, waitForPendingWrites,','deleteField, waitForPendingWrites, connectFirestoreEmulator,')
  .replace('const auth = getAuth(app);',"const auth = getAuth(app); connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});")
  .replace('const CHAVE_LIMPEZA',"connectFirestoreEmulator(db,'127.0.0.1',8080);\nconst CHAVE_LIMPEZA");
(async()=>{
  const env=await initializeTestEnvironment({projectId:PROJECT,firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(path.join(ROOT,'firestore.rules'),'utf8')}});
  const browser=await chromium.launch();
  // withSecurityRulesDisabled (v5.0.2) roda o callback mas descarta o retorno dele
  // (só dá `await callback(context)`, sem `return`) — ler o perfil precisa escrever
  // numa variável de fora, não depender do valor de retorno do wrapper.
  const lePerfil=async uid=>{
    let dados; await env.withSecurityRulesDisabled(async ctx=>{ dados=(await getDoc(doc(ctx.firestore(),'perfis',uid))).data(); });
    return dados;
  };
  try{
    const context=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844}});
    const violacoes=[];
    await context.exposeBinding('__registraCSP',(_s,info)=>violacoes.push(info));
    await context.addInitScript(()=>addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI)));
    const source=cloudEmulado();
    await context.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:source}));
    await context.addInitScript(()=>sessionStorage.setItem('splashVista','1'));
    const page=await context.newPage(); page.setDefaultTimeout(15000);
    const errosPagina=[]; page.on('pageerror',err=>errosPagina.push(err.message));
    await page.goto('http://localhost:8123'); await page.waitForFunction(()=>window.CLOUD);
    await page.locator('#authTabs button[data-k="cad"]').click();

    // checklist reage ao digitar
    const ok=()=>page.$$eval('#cRegras li.ok',l=>l.map(x=>x.dataset.regra));
    await page.locator('#cSenha').fill('abc');
    assert.deepEqual(await ok(),['letra','email','comum']);
    await page.locator('#cSenha').fill('Obra2026x');
    assert.deepEqual(await ok(),['tamanho','letra','numero','email','comum']);
    console.log('ok - checklist marca cada regra ao digitar');

    // ordem de validação: nome primeiro
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Digite seu nome.');
    assert.equal(await page.evaluate(()=>document.activeElement.id),'cNome');
    await page.locator('#cNome').fill('  Ana  ');
    await page.locator('#cEmail').fill('cadastro@example.com');
    await page.locator('#cSenha').fill('senha123');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Essa senha é muito comum. Escolha outra.');
    await page.locator('#cSenha').fill('Obra2026x'); await page.locator('#cSenha2').fill('Obra2026y');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'As senhas não são iguais.');
    await page.locator('#cSenha2').fill('Obra2026x');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Conte como conheceu o Custta.');
    console.log('ok - senha óbvia, confirmação diferente e origem vazia bloqueiam');

    // detalhe aparece só para indicação/outro e some ao trocar
    assert.equal(await page.locator('#cDetalheWrap').isVisible(),false);
    await page.selectOption('#cOrigem','indicacao');
    assert.equal(await page.textContent('#cDetalheLabel'),'Quem indicou? (opcional)');
    await page.locator('#cDetalhe').fill('Seu João');
    await page.selectOption('#cOrigem','instagram');
    assert.equal(await page.locator('#cDetalheWrap').isVisible(),false);
    await page.selectOption('#cOrigem','indicacao');
    assert.equal(await page.inputValue('#cDetalhe'),'');
    await page.locator('#cDetalhe').fill('Seu João');
    console.log('ok - detalhe da origem aparece, some e não vaza ao trocar');

    await page.locator('#fCad button[type=submit]').click();
    // signup() só resolve (e reabilita o botão via comLoading) depois do setDoc do perfil —
    // esperar só CLOUD.user() é uma corrida contra onAuthStateChanged, que dispara antes dele.
    await page.waitForFunction(()=>CLOUD.user() && !document.querySelector('#fCad button[type=submit]').disabled);
    const uid=await page.evaluate(()=>CLOUD.user().uid);
    const perfil=await lePerfil(uid);
    assert.equal(perfil.nome,'Ana'); assert.equal(perfil.sobrenome,undefined);
    assert.equal(perfil.origem,'indicacao'); assert.equal(perfil.origemDetalhe,'Seu João');
    assert.equal(perfil.email,'cadastro@example.com'); assert.ok(perfil.tz);
    console.log('ok - cadastro grava nome, origem e detalhe no perfil');

    // Ajustes mostra e edita o nome. signup() dispara 'perfil-alterado' depois do
    // setDoc de perfis/{uid} terminar, então o cache por uid do Ajustes (que o primeiro
    // renderAjustes() automático de onAuthStateChanged pode ter preenchido antes do
    // perfil ser gravado) sempre reflete o nome certo sem precisar de reload.
    await page.evaluate(()=>showView('ajustes'));
    await page.waitForFunction(()=>document.getElementById('ajNome').textContent==='Ana');
    assert.equal(await page.textContent('#ajNomeEditar'),'Editar nome');
    await page.locator('#ajNomeEditar').click();
    assert.equal(await page.inputValue('#contaNome'),'Ana');
    await page.locator('#contaSobrenome').fill('Lima'); await page.locator('#contaEnviar').click();
    await page.waitForSelector('.conta-dialog',{state:'detached'});
    await page.waitForFunction(()=>document.getElementById('ajNome').textContent==='Ana Lima');
    const depois=await lePerfil(uid);
    assert.equal(depois.sobrenome,'Lima'); assert.equal(depois.origem,'indicacao');
    console.log('ok - Ajustes mostra o nome e a edição persiste');

    // troca de senha: checklist e repetição
    await page.locator('#ajSenha').click();
    await page.locator('#contaSenha').fill('Obra2026x');
    await page.locator('#contaConfirmacao').fill('curta1');
    await page.locator('#contaNova2').fill('curta1');
    await page.locator('#contaEnviar').click();
    assert.equal(await page.textContent('#contaMensagem'),'Use pelo menos 8 caracteres.');
    await page.locator('#contaConfirmacao').fill('Nova2026x'); await page.locator('#contaNova2').fill('Nova2026y');
    await page.locator('#contaEnviar').click();
    assert.equal(await page.textContent('#contaMensagem'),'As senhas novas não são iguais.');
    await page.locator('#contaNova2').fill('Nova2026x'); await page.locator('#contaEnviar').click();
    await page.waitForSelector('.conta-dialog',{state:'detached'});
    console.log('ok - trocar senha exige regra nova e repetição igual');

    // usuário antigo sem nome: Ajustes não quebra e oferece "Adicionar nome"
    await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'perfis',uid),{email:'cadastro@example.com',criado:'2026-01-01T00:00:00.000Z'}));
    await page.reload(); await page.waitForFunction(()=>CLOUD.user());
    await page.evaluate(()=>showView('ajustes'));
    await page.waitForFunction(()=>document.getElementById('ajNomeEditar').textContent==='Adicionar nome');
    assert.equal(await page.locator('#ajNome').isVisible(),false);
    console.log('ok - perfil antigo sem nome oferece "Adicionar nome"');

    assert.deepEqual(violacoes,[]); assert.deepEqual(errosPagina,[]);
    console.log('ok - nenhuma violação de CSP nem erro de página');
  }finally{ await browser.close(); await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
