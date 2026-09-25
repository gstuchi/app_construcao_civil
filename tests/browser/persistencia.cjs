/* Regressão com SDK real e Firestore Emulator. Nenhum acesso ao banco de produção.
   Servidor: node tests/browser/servidor.cjs
   Execução: firebase emulators:exec --only firestore "node tests/browser/persistencia.cjs"
   Playwright deve estar disponível no NODE_PATH. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

(async()=>{
  const browser = await chromium.launch();
  try{
    const context = await browser.newContext({ serviceWorkers: 'block' });
    const root = path.resolve(__dirname, '../..');
    let cloud = fs.readFileSync(path.join(root, 'cloud.js'), 'utf8');
    cloud = cloud.replace("projectId: 'app-construcao-civil'", "projectId: 'demo-custta-offline'");
    cloud = cloud.replace('deleteField, waitForPendingWrites,',
      'deleteField, waitForPendingWrites, connectFirestoreEmulator, disableNetwork, enableNetwork,');
    cloud = cloud.replace('let currentUser = null;', `
      connectFirestoreEmulator(db, '127.0.0.1', 8080, { mockUserToken: { sub: 'offline-test', email: 'offline@example.com' } });
      await disableNetwork(db);
      Object.defineProperty(navigator, 'onLine', { configurable: true, get:()=>false });
      window.__reconecta = async()=>{
        Object.defineProperty(navigator, 'onLine', { configurable:true, get:()=>true });
        await enableNetwork(db);
        window.dispatchEvent(new Event('online'));
      };
      window.__servidor = async()=> (await getDocFromServer(doc(db, 'dados', 'offline-test'))).data();
      let currentUser = null;
    `);
    await context.route('**/cloud.js', r=>r.fulfill({ contentType:'text/javascript', body:cloud }));
    await context.route('**/firebase-auth.js', r=>r.fulfill({ contentType:'text/javascript', body:`
      export const getAuth = ()=>({});
      export const getIdToken = ()=>Promise.resolve('token-teste');
      export const onAuthStateChanged = (_auth, cb)=>{ cb(sessionStorage.getItem('teste-saiu') ? null : { uid:'offline-test', email:'offline@example.com' }); };
      export const EmailAuthProvider = { credential:()=>({}) };
      export const reauthenticateWithCredential = ()=>Promise.resolve();
      export const updatePassword = ()=>Promise.resolve();
      export const deleteUser = ()=>Promise.resolve();
      export const sendEmailVerification = ()=>Promise.resolve();
      export const reload = ()=>Promise.resolve();
      export const createUserWithEmailAndPassword = ()=>Promise.reject(new Error('Não usado'));
      export const signInWithEmailAndPassword = ()=>Promise.reject(new Error('Não usado'));
      export const sendPasswordResetEmail = ()=>Promise.resolve();
      export const signOut = ()=>{ sessionStorage.setItem('teste-saiu','1'); return Promise.resolve(); };
      export class GoogleAuthProvider { setCustomParameters(){} }
      export const signInWithPopup = ()=>Promise.reject(new Error('Não usado'));
      export const signInWithRedirect = ()=>Promise.reject(new Error('Não usado'));
      export const getRedirectResult = ()=>Promise.resolve(null);
      export const reauthenticateWithPopup = ()=>Promise.resolve();
    ` }));
    await context.addInitScript(()=>sessionStorage.setItem('splashVista', '1'));
    let page = await context.newPage();
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>window.CLOUD && CLOUD.user());
    await page.evaluate(()=>{
      window.__local = 0;
      CLOUD.watchDados((blob, meta)=>{
        if(meta.pendingWrites && blob?.obras?.[0]?.gastos?.length === 2) window.__local++;
      });
      const obra = { id:'offline-obra', nome:'Obra offline', fase:'construcao', dataInicio:'2026-09-01', gastos:[] };
      const blob = { obras:[obra], config:{ taxaMensal:1, topicosCustom:[] } };
      obra.gastos.push({ id:'g1', valor:100, data:'2026-09-08', topico:'terreno', descricao:'Primeiro' });
      CLOUD.saveDados(blob);
      obra.gastos.push({ id:'g2', valor:200, data:'2026-09-08', topico:'terreno', descricao:'Segundo' });
      CLOUD.saveDados(blob);
    });
    await page.waitForFunction(()=>window.__local > 0);
    assert.equal(await page.evaluate(()=>CLOUD.temPendencia()), true);
    await page.close();
    page = await context.newPage();
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>window.CLOUD && CLOUD.user());
    await page.waitForFunction(()=>db.obras[0]?.gastos?.length === 2);
    assert.equal(await page.evaluate(()=>db.obras[0].gastos.reduce((s,g)=>s+g.valor,0)), 300);
    assert.equal(await page.evaluate(()=>CLOUD.temPendencia()), true);
    assert.equal(await page.evaluate(()=>CLOUD.logout().then(()=> 'saiu', e=>e.code)), 'pendente');
    console.log('ok - duas alterações offline sobrevivem ao fechamento e restauram a tela');
    await page.evaluate(()=>window.__reconecta());
    await page.waitForFunction(()=>!CLOUD.temPendencia());
    const remoto = await page.evaluate(()=>window.__servidor());
    assert.equal(remoto.obras[0].gastos.length, 2);
    assert.equal(remoto.obras[0].gastos[1].valor, 200);
    await page.evaluate(()=>{ CLOUD.logout().catch(e=>window.__falha=e.code); });
    await page.waitForFunction(()=>window.CLOUD && !CLOUD.user() && !CLOUD.cacheBloqueado());
    assert.equal(await page.evaluate(()=>sessionStorage.getItem('teste-saiu')), '1');
    console.log('ok - reconexão grava versão completa no emulador e libera logout');
  } finally { await browser.close(); }
})().catch(err=>{ console.error(err); process.exitCode = 1; });
