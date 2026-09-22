/* Conta descartável, Auth e Firestore reais, exclusivamente emuladores locais.
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
     --only firestore,auth "node tests/browser/fase2.cjs" */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc}=require('firebase/firestore');
const {execFileSync}=require('node:child_process');
const PROJECT='demo-custta-phase2';
const ROOT=path.resolve(__dirname,'../..');
(async()=>{
  const env=await initializeTestEnvironment({projectId:PROJECT,firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(path.join(ROOT,'firestore.rules'),'utf8')}});
  const browser=await chromium.launch();
  try{
    const context=await browser.newContext({serviceWorkers:'block',viewport:{width:414,height:896},acceptDownloads:true});
    const violacoes=[];
    await context.exposeBinding('__registraCSP',(_source,info)=>violacoes.push(info));
    await context.addInitScript(()=>addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI)));
    const source=fs.readFileSync(path.join(ROOT,'cloud.js'),'utf8')
      .replace("projectId: 'app-construcao-civil'",`projectId: '${PROJECT}'`)
      .replace('sendPasswordResetEmail, signOut,','sendPasswordResetEmail, signOut, connectAuthEmulator,')
      .replace('deleteField, waitForPendingWrites,','deleteField, waitForPendingWrites, connectFirestoreEmulator,')
      .replace('const auth = getAuth(app);',"const auth = getAuth(app); connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});")
      .replace('const CHAVE_LIMPEZA',"connectFirestoreEmulator(db,'127.0.0.1',8080);\nconst CHAVE_LIMPEZA");
    await context.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:source}));
    await context.addInitScript(()=>{ sessionStorage.setItem('splashVista','1'); window.__documentoId=crypto.randomUUID(); });
    const page=await context.newPage(); page.setDefaultTimeout(15000);
    page.on('pageerror',err=>console.log('PAGEERROR',err.message));
    await page.goto('http://localhost:8123'); await page.waitForFunction(()=>window.CLOUD);
    await page.evaluate(()=>CLOUD.signup('fase2@example.com','Local-emulador-123!'));
    await page.waitForFunction(()=>CLOUD.user());
    const uid=await page.evaluate(()=>CLOUD.user().uid);
    await page.evaluate(async()=>{
      db=normaliza({obras:[{id:'fase2',nome:'Casa exportação única',fase:'construcao',dataInicio:'2026-09-09',gastos:[{id:'g1',valor:123.45,descricao:'Cimento',data:'2026-09-09',topico:'terreno',pagamento:'pix'}]}]});
      await save(); renderAll(); showView('ajustes');
    });
    await env.withSecurityRulesDisabled(async ctx=>assert.ok((await getDoc(doc(ctx.firestore(),'perfis',uid))).data().tz));
    assert.equal(await page.locator('#ajVerificacao').isVisible(),true);
    await page.locator('#ajVerificar').click();
    await page.waitForFunction(()=>document.getElementById('ajVerificarMsg').textContent.includes('enviado'));
    const oob=await fetch(`http://127.0.0.1:9099/emulator/v1/projects/${PROJECT}/oobCodes`).then(r=>r.json());
    assert.ok(oob.oobCodes.some(c=>c.requestType==='VERIFY_EMAIL'));
    console.log('ok - cadastro grava fuso; verificação de e-mail envia sem bloquear acesso');
    for(const [seletor,formato] of [['#ajJson','json'],['#ajCsv','csv']]){
      const download=page.waitForEvent('download'); await page.locator(seletor).click();
      const arquivo=await download; const texto=fs.readFileSync(await arquivo.path(),'utf8');
      if(formato==='json') assert.equal(JSON.parse(texto).dados.obras[0].gastos[0].valor,123.45);
      else assert.ok(texto.includes('123,45') && texto.includes('Cimento'));
    }
    console.log('ok - arquivos JSON e CSV reais contêm lançamentos exportados');
    await page.locator('#ajSenha').click();
    await page.locator('#contaSenha').fill('incorreta'); await page.locator('#contaConfirmacao').fill('Nova-local-456!');
    await page.locator('#contaNova2').fill('Nova-local-456!');
    await page.locator('#contaEnviar').click();
    await page.waitForFunction(()=>document.getElementById('contaMensagem').textContent.includes('incorreta'));
    await page.locator('#contaSenha').fill('Local-emulador-123!'); await page.locator('#contaConfirmacao').fill('Nova-local-456!');
    await page.locator('#contaNova2').fill('Nova-local-456!');
    await page.locator('#contaEnviar').click(); await page.waitForSelector('.conta-dialog',{state:'detached'});
    assert.ok(await page.evaluate(()=>CLOUD.trocarSenha('Nova-local-456!','Nova-local-456!').then(()=>true)));
    console.log('ok - senha incorreta rejeitada; troca com reautenticação funciona');
    for(const largura of [414,1440]){
      await page.setViewportSize({width:largura,height:900});
      for(const claro of [false,true]){
        await page.evaluate(claro=>{ aplicaTema(claro); showView('ajustes'); },claro);
        await page.locator('#ajApagar').click();
        const caixa=await page.locator('.conta-dialog').boundingBox();
        assert.ok(caixa.x>=0 && caixa.x+caixa.width<=largura);
        await page.screenshot({path:path.join(process.env.TEMP,`custta-fase2-${largura}-${claro}.png`)});
        await page.locator('#contaCancelar').click();
      }
    }
    console.log('ok - formulários cabem no celular e desktop, temas claro e escuro');
    await context.setOffline(true);
    assert.equal(await page.evaluate(()=>CLOUD.apagarConta('Nova-local-456!','APAGAR').then(()=>null,e=>e.code)),'offline');
    await context.setOffline(false);
    await page.locator('#ajApagar').click();
    await page.locator('#contaSenha').fill('Nova-local-456!'); await page.locator('#contaConfirmacao').fill('APAGAR');
    const antesDeApagar=await page.evaluate(()=>window.__documentoId);
    await page.locator('#contaEnviar').click();
    /* Esperas de recarga: flush da fila (teto de 5s no cloud.js) + terminate + clearIndexedDbPersistence
       + reload. No runner do GitHub isso passa dos 15s padrão da suíte, então estas duas ganham folga. */
    await page.waitForFunction(antes=>window.__documentoId !== antes && typeof db !== 'undefined' && window.CLOUD && !CLOUD.user() && !document.querySelector('.conta-dialog') && document.body.classList.contains('locked'),antesDeApagar,{timeout:30000});
    await env.withSecurityRulesDisabled(async ctx=>{
      const adminDb=ctx.firestore();
      for(const colecao of ['dados','perfis','push']) assert.equal((await getDoc(doc(adminDb,colecao,uid))).exists(),false);
    });
    // A consulta administrativa de contas é feita pelo endpoint Auth do emulador.
    const lista=await fetch(`http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:batchGet`,{headers:{Authorization:'Bearer owner'}}).then(r=>r.json());
    assert.ok(!lista.error, JSON.stringify(lista.error));
    assert.ok(!(lista.users||[]).some(u=>u.localId===uid));
    assert.equal(await page.evaluate(()=>localStorage.getItem('custta-limpar-cache')),null);
    assert.equal(await page.evaluate(()=>db.obras.length),0);
    console.log('ok - exclusão remove Auth e três documentos; limpeza local termina e volta ao login');
    await page.evaluate(()=>CLOUD.signup('logout-fase2@example.com','Local-emulador-123!'));
    await page.waitForFunction(()=>CLOUD.user());
    await page.evaluate(()=>CLOUD.saveDados({obras:[],config:{taxaMensal:1,topicosCustom:[]}}));
    const outra=await context.newPage(); await outra.goto('http://localhost:8123');
    await outra.waitForFunction(()=>window.CLOUD && CLOUD.user());
    assert.equal(await page.evaluate(()=>CLOUD.logout().then(()=>null,e=>e.code)),'outra-aba');
    assert.ok(await page.evaluate(()=>CLOUD.user()));
    await outra.close();
    console.log('ok - outra aba aberta impede saída e preserva sessão');
    const antesDeSair=await page.evaluate(()=>window.__documentoId);
    await page.evaluate(()=>{ CLOUD.logout().catch(e=>window.__falhaSaida=e.code); });
    /* Esperas de recarga: flush da fila (teto de 5s no cloud.js) + terminate + clearIndexedDbPersistence
       + reload. No runner do GitHub isso passa dos 15s padrão da suíte, então estas duas ganham folga. */
    await page.waitForFunction(antes=>window.__documentoId !== antes && typeof db !== 'undefined' && window.CLOUD && !CLOUD.user() && !CLOUD.cacheBloqueado() && localStorage.getItem('custta-limpar-cache') === null && document.body.classList.contains('locked'),antesDeSair,{timeout:30000});
    assert.equal(await page.evaluate(()=>localStorage.getItem('custta-limpar-cache')),null);
    console.log('ok - logout normal sincroniza, limpa cache e recarrega sem sessão');
    await page.locator('#lEmail').fill('logout-fase2@example.com');
    await page.locator('#lSenha').fill('Local-emulador-123!');
    await page.locator('#fLogin button[type="submit"]').click();
    await page.waitForFunction(()=>CLOUD.user() && !document.body.classList.contains('locked'));
    await page.locator('#btnNovaObra').click();
    await page.locator('#fNome').fill('  Obra pelo formulário  ');
    await page.locator('#fArea').fill('180,5');
    await page.locator('#cSave').click();
    await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra pelo formulário'));
    assert.equal(await page.evaluate(()=>db.obras.find(o=>o.nome==='Obra pelo formulário').areaM2),180.5);
    await page.locator('#fab').click();
    for(const key of ['1','2','3','4']) await page.locator(`.valor-key[data-k="${key}"]`).click();
    await page.locator('.valor-ok').click();
    await page.locator('#fDesc').fill('  Cimento pelo formulário  ');
    await page.locator('#cSave').click();
    await page.waitForFunction(()=>db.obras[0]?.gastos[0]?.valor===12.34 && !CLOUD.temPendencia());
    assert.equal(await page.evaluate(()=>db.obras[0].gastos[0].descricao),'Cimento pelo formulário');
    console.log('ok - login, criação de obra e lançamento pelo teclado/formulários reais');
    await env.withSecurityRulesDisabled(async ctx=>{
      const adminDb=ctx.firestore();
      await setDoc(doc(adminDb,'perfis','legado'),{email:'legado@example.com',cpf:'00000000000',plano:'gratis'});
      const executar=aplicar=>JSON.parse(execFileSync(process.execPath,
        [path.join(ROOT,'notificacoes/scripts/purga-cpf.mjs'),'--project',PROJECT,...(aplicar?['--apply']:[])],
        {encoding:'utf8',env:{...process.env,FIRESTORE_EMULATOR_HOST:'127.0.0.1:8080',FIREBASE_SERVICE_ACCOUNT:''}}));
      assert.equal(executar(false).encontrados,1);
      assert.ok((await getDoc(doc(adminDb,'perfis','legado'))).data().cpf);
      assert.equal(executar(true).removidos,1);
      const perfil=(await getDoc(doc(adminDb,'perfis','legado'))).data();
      assert.ok(!Object.hasOwn(perfil,'cpf')); assert.equal(perfil.plano,'gratis');
      assert.equal(executar(false).encontrados,0);
    });
    console.log('ok - expurgo em dry-run preserva CPF; aplicação remove só CPF e segunda execução encontra zero');
    assert.deepEqual(violacoes,[], 'CSP não deve bloquear fluxos reais de conta');
  }finally{await browser.close();await env.cleanup();}
})().catch(err=>{console.error(err);process.exitCode=1;});
