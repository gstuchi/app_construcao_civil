/* Aceitação da Fase 1: SDKs Auth/Firestore reais, somente emuladores locais.
   node tests/browser/servidor.cjs
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase1
     --only firestore,auth "node tests/browser/fase1.cjs"
   Playwright deve estar no NODE_PATH. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const PROJECT = 'demo-custta-phase1';
const ROOT = path.resolve(__dirname, '../..');
const RULES = fs.readFileSync(path.join(ROOT, 'firestore.rules'), 'utf8');
const envs = [];
async function rules(text){
  const env = await initializeTestEnvironment({ projectId:PROJECT,
    firestore:{ host:'127.0.0.1', port:8080, rules:text } });
  envs.push(env);
  return env;
}

(async()=>{
  const env = await rules(RULES);
  const browser = await chromium.launch();
  try{
    const context = await browser.newContext({ serviceWorkers:'block', viewport:{ width:414, height:896 } });
    let source = fs.readFileSync(path.join(ROOT, 'cloud.js'), 'utf8')
      .replace("projectId: 'app-construcao-civil'", `projectId: '${PROJECT}'`)
      .replace('sendPasswordResetEmail, signOut,', 'sendPasswordResetEmail, signOut, connectAuthEmulator,')
      .replace('deleteField, waitForPendingWrites,', 'deleteField, waitForPendingWrites, connectFirestoreEmulator, getDocFromServer, disableNetwork, enableNetwork,')
      .replace('const auth = getAuth(app);', `const auth = getAuth(app);
        connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings:true });
        window.__token = ()=>auth.currentUser.getIdToken(true).then(()=>null,e=>e.code);`)
      .replace('let currentUser = null;', `
        connectFirestoreEmulator(db, '127.0.0.1', 8080);
        window.__renovaRede = async()=>{ await disableNetwork(db); await enableNetwork(db); };
        window.__remoto = async()=> (await getDocFromServer(doc(db,'dados',auth.currentUser.uid))).data();
        let currentUser = null;`);
    await context.route('**/cloud.js', r=>r.fulfill({ contentType:'text/javascript', body:source }));
    await context.addInitScript(()=>sessionStorage.setItem('splashVista','1'));
    const page = await context.newPage();
    page.setDefaultTimeout(20000);
    page.on('pageerror', e=>console.log('[pageerror]', e.message));
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>window.CLOUD);
    await page.evaluate(()=>CLOUD.signup('phase1@example.com', 'Only-local-emulator-913!'));
    await page.waitForFunction(()=>CLOUD.user() && !document.body.classList.contains('locked'));
    const uid = await page.evaluate(()=>CLOUD.user().uid);
    await page.evaluate(async()=>{
      db = normaliza({ obras:[{ id:'o1', nome:'Obra de aceitação', fase:'construcao', dataInicio:'2026-09-01', gastos:[] }] });
      await save(); renderAll();
    });
    console.log('ok - cadastro e sessão com Auth real no emulador');

    // Negação real de escrita. Mesma edição é reenviada após restaurar as rules.
    await rules(RULES.replace('if meu(uid) && blobOk();', 'if false;'));
    const denied = await page.evaluate(()=>{
      db.obras[0].gastos.push({ id:'negado', valor:150, descricao:'Preservar', data:'2026-09-08', topico:'terreno', pagamento:'pix' });
      return salvarComAviso('Gasto lançado com sucesso').then(()=>null,e=>e.code);
    });
    assert.equal(denied, 'permission-denied');
    await page.waitForFunction(()=>CLOUD.estado() === 'erro');
    assert.equal(await page.evaluate(()=>db.obras[0].gastos.length), 1);
    assert.ok(await page.locator('#toastWrap').textContent().then(t=>!t.includes('vamos tentar de novo sozinhos') && !t.includes('sucesso')));
    await rules(RULES);
    await page.locator('#syncPill').click();
    await page.waitForFunction(()=>!CLOUD.temPendencia() && CLOUD.estado() === 'ocioso');
    assert.equal((await page.evaluate(()=>window.__remoto())).obras[0].gastos.length, 1);
    await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'dados',uid), {
      obras:[{ id:'remota', nome:'Atualização remota', fase:'construcao', dataInicio:'2026-09-01', gastos:[] }],
      config:{ taxaMensal:2, topicosCustom:[] }
    }));
    await page.waitForFunction(()=>db.obras[0]?.id === 'remota');
    console.log('ok - permission-denied preserva edição; retry confirma; snapshot remoto volta sem reload');

    // Uma assinatura encerrada por erro precisa ser recriada de verdade.
    await rules(RULES.replace('allow get:            if meu(uid);', 'allow get: if false;'));
    await page.evaluate(()=>{ window.__stopRead = CLOUD.watchDados(()=>{}); });
    await page.evaluate(()=>window.__renovaRede());
    await page.waitForFunction(()=>document.querySelector('#syncPill').textContent.includes('Não sincronizou'));
    await rules(RULES);
    await page.locator('#syncPill').click();
    await page.waitForFunction(()=>CLOUD.estado() === 'ocioso');
    await page.evaluate(()=>window.__stopRead());
    console.log('ok - retry recupera assinatura de leitura encerrada por permission-denied');

    // Interrompe transporte com uma requisição de escrita já iniciada.
    const cdp = await context.newCDPSession(page);
    let hold = true, chegou, libera;
    const iniciou = new Promise(r=>{ chegou=r; });
    const liberado = new Promise(r=>{ libera=r; });
    await context.route('**/*Firestore/Write/channel**', async route=>{
      if(hold && route.request().method() === 'POST'){
        chegou(); await liberado; await route.abort('internetdisconnected');
      } else await route.continue();
    });
    await page.evaluate(()=>{
      window.__confirmou = false;
      db.obras[0].gastos.push({ id:'rede', valor:300, data:'2026-09-08', topico:'terreno', descricao:'Caiu no envio', pagamento:'pix' });
      salvarComAviso('Gasto lançado com sucesso').then(()=>{ window.__confirmou=true; });
    });
    await Promise.race([iniciou, new Promise((_,r)=>setTimeout(()=>r(new Error('Escrita não interceptada')),15000))]);
    await cdp.send('Network.emulateNetworkConditions', { offline:true, latency:0, downloadThroughput:0, uploadThroughput:0 });
    hold=false; libera();
    await page.waitForFunction(()=>CLOUD.estado() === 'offline');
    assert.equal(await page.evaluate(()=>window.__confirmou), false);
    await cdp.send('Network.emulateNetworkConditions', { offline:false, latency:0, downloadThroughput:-1, uploadThroughput:-1 });
    await page.waitForFunction(()=>window.__confirmou && !CLOUD.temPendencia(), null, { timeout:45000 });
    assert.equal((await page.evaluate(()=>window.__remoto())).obras[0].gastos[0].id, 'rede');
    await context.unroute('**/*Firestore/Write/channel**');
    console.log('ok - queda durante envio via CDP recupera sem reload e sem sucesso antecipado');

    // Aviso preventivo e bloqueio real em bytes. Redução recupera a gravação.
    await page.evaluate(()=>{
      document.querySelector('#toastWrap').innerHTML='';
      db.obras[0].gastos[0].descricao = 'á'.repeat(350000);
      return save();
    });
    assert.match(await page.locator('#toastWrap').textContent(), /próximos do limite/);
    const limite = await page.evaluate(()=>{
      db.obras[0].gastos[0].descricao = 'á'.repeat(450001);
      return salvarComAviso('Gasto atualizado').then(()=>null,e=>e.code);
    });
    assert.equal(limite,'limite');
    assert.equal(await page.evaluate(()=>CLOUD.estado()),'erro');
    assert.ok(!(await page.locator('#toastWrap').textContent()).includes('Gasto atualizado'));
    assert.ok((await page.evaluate(()=>window.__remoto())).obras[0].gastos[0].descricao.length < 450001);
    await page.evaluate(()=>{ db.obras[0].gastos[0].descricao='Reduzida'; return save(); });
    await page.waitForFunction(()=>CLOUD.estado() === 'ocioso');
    console.log('ok - aviso em 700KB, bloqueio acima de 900KB e recuperação após reduzir');

    // Exclusão administrativa apenas da conta descartável no emulador.
    await page.evaluate(()=>formEditarObra(db.obras[0]));
    assert.equal(await page.evaluate(()=>document.body.classList.contains('sheet-open')),true);
    const apagou = await fetch(`http://127.0.0.1:9099/emulator/v1/projects/${PROJECT}/accounts`, { method:'DELETE' });
    assert.ok(apagou.ok);
    const valida = await page.evaluate(()=>CLOUD.verificarSessao(true));
    assert.equal(valida, false, 'refresh de conta removida precisa falhar');
    await page.waitForFunction(()=>!CLOUD.user() && document.body.classList.contains('locked'));
    assert.match(await page.locator('#lMsg').textContent(), /Sua sessão expirou/);
    assert.equal(await page.evaluate(()=>db.obras.length),0);
    assert.equal(await page.evaluate(()=>document.body.classList.contains('sheet-open')),false);
    assert.equal(await page.evaluate(()=>sheet.textContent),'');
    console.log('ok - refresh inválido encerra sessão, limpa tela e explica expiração');
  } finally {
    await browser.close();
    for(const env of envs) await env.cleanup();
  }
})().catch(err=>{ console.error(err); process.exitCode=1; });
