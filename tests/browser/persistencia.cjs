/* Regressão com SDK real e Firestore Emulator. Nenhum acesso ao banco de produção.
   Servidor: node tests/browser/servidor.cjs
   Execução: firebase emulators:exec --only firestore "node tests/browser/persistencia.cjs"
   Playwright deve estar disponível no NODE_PATH. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

const PROJETO = 'demo-custta-offline';

/* O cloud.js de verdade, no emulador e já sem rede: a conta entra antes de qualquer
   resposta do servidor, como num aparelho que abre sem sinal. */
function cloudSemRede(uid, email){
  let cloud = fs.readFileSync(path.resolve(__dirname, '../../cloud.js'), 'utf8');
  cloud = cloud.replace("projectId: 'app-construcao-civil'", `projectId: '${PROJETO}'`);
  cloud = cloud.replace('deleteField, waitForPendingWrites,',
    'deleteField, waitForPendingWrites, connectFirestoreEmulator, disableNetwork, enableNetwork,');
  return cloud.replace('let currentUser = null;', `
      connectFirestoreEmulator(db, '127.0.0.1', 8080, { mockUserToken: { sub: '${uid}', email: '${email}' } });
      await disableNetwork(db);
      Object.defineProperty(navigator, 'onLine', { configurable: true, get:()=>false });
      window.__reconecta = async()=>{
        Object.defineProperty(navigator, 'onLine', { configurable:true, get:()=>true });
        await enableNetwork(db);
        window.dispatchEvent(new Event('online'));
      };
      window.__desconecta = async()=>{
        Object.defineProperty(navigator, 'onLine', { configurable:true, get:()=>false });
        await disableNetwork(db);
        window.dispatchEvent(new Event('offline'));
      };
      window.__servidor = async()=> (await getDocFromServer(doc(db, 'dados', '${uid}'))).data();
      let currentUser = null;
    `);
}

/* firebase-auth falso: a sessão da conta já está guardada neste aparelho. */
const authFalso = (uid, email) => `
      export const getAuth = ()=>({});
      export const getIdToken = ()=>Promise.resolve('token-teste');
      export const onAuthStateChanged = (_auth, cb)=>{ cb(sessionStorage.getItem('teste-saiu') ? null : { uid:'${uid}', email:'${email}' }); };
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
      export class OAuthProvider { constructor(id){ this.providerId=id; } addScope(){} setCustomParameters(){} credential(){ return {}; } static credentialFromResult(){ return null; } }
      export const signInWithCredential = ()=>Promise.reject(new Error('Não usado'));
      export const revokeAccessToken = ()=>Promise.resolve();
      export const updateProfile = ()=>Promise.resolve();
    `;

/* Um aparelho é um contexto do navegador: cache (IndexedDB) próprio, que começa vazio. */
async function aparelho(browser, uid, email, opcoes = {}){
  const context = await browser.newContext({ serviceWorkers: 'block', ...opcoes });
  const cloud = cloudSemRede(uid, email);
  await context.route('**/cloud.js', r=>r.fulfill({ contentType:'text/javascript', body:cloud }));
  await context.route('**/firebase-auth.js', r=>r.fulfill({ contentType:'text/javascript', body:authFalso(uid, email) }));
  await context.addInitScript(()=>sessionStorage.setItem('splashVista', '1'));
  return context;
}

(async()=>{
  const browser = await chromium.launch();
  let env;
  try{
    const context = await aparelho(browser, 'offline-test', 'offline@example.com');
    let page = await context.newPage();
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>window.CLOUD && CLOUD.user());
    /* Só grava quem já viu os dados da conta: o aparelho ouve o servidor uma vez
       (conta nova, "não existe") e então perde a rede. */
    await page.evaluate(()=>CLOUD.watchDados((_blob, meta)=>{ if(!meta.fromCache) window.__viuServidor = true; }));
    await page.evaluate(()=>window.__reconecta());
    await page.waitForFunction(()=>window.__viuServidor);
    await page.evaluate(()=>window.__desconecta());
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

    /* Aparelho novo (cache vazio) que perde a rede antes do primeiro snapshot do
       servidor: o snapshot do cache chega sem documento. A conta já tem uma obra,
       gravada por outro aparelho. Gravar ali regravaria o documento inteiro só com
       o que este aparelho tem. */
    const UID = 'aparelho-novo';
    env = await initializeTestEnvironment({ projectId: PROJETO, firestore: { host: '127.0.0.1', port: 8080 } });
    const obrasNoServidor = async()=>{
      let dados; // withSecurityRulesDisabled descarta o retorno do callback
      await env.withSecurityRulesDisabled(async ctx=>{ dados = (await getDoc(doc(ctx.firestore(), 'dados', UID))).data(); });
      return (dados?.obras || []).map(o=>o.nome).sort();
    };
    await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(), 'dados', UID), {
      obras: [{ id: 'so-no-servidor', nome: 'Obra que só o servidor tem', fase: 'construcao', dataInicio: '2026-09-01', areaM2: 120, gastos: [] }],
      config: { taxaMensal: 1, topicosCustom: [] },
    }));
    const novo = await aparelho(browser, UID, 'novo@example.com', { viewport: { width: 414, height: 896 } });
    page = await novo.newPage();
    page.on('pageerror', e=>console.log('[pageerror]', e.message));
    await page.goto('http://localhost:8123');
    await page.waitForFunction(()=>window.CLOUD && CLOUD.user() && !document.body.classList.contains('locked'));
    await page.evaluate(()=>CLOUD.watchDados((blob, meta)=>{ window.__visto = { existe: blob !== null, doCache: meta.fromCache }; }));
    await page.waitForFunction(()=>window.__visto?.doCache && !window.__visto.existe);
    const listaSemRede = (await page.locator('#obrasList').textContent()).trim();
    // Defesa em profundidade: o cloud.js recusa mesmo que uma tela tente gravar.
    const gravacaoDireta = await page.evaluate(()=>new Promise(resolve=>{
      CLOUD.saveDados({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } }).then(()=>resolve('confirmou'), e=>resolve(e.code));
      setTimeout(()=>resolve('na fila do SDK'), 300);
    }));
    const estadoDepoisDaRecusa = await page.evaluate(()=>CLOUD.estado());
    await page.locator('nav.tabs button[data-tab=inicio]').click();
    await page.locator('#fab').click();
    const abriuNovaObra = await page.locator('#fNome').count() > 0;
    if(abriuNovaObra){ // o site antes da correção deixava criar aqui
      await page.locator('#fNome').fill('Obra do aparelho novo');
      await page.locator('#fArea').fill('80');
      await page.locator('#cSave').click();
    }
    const avisos = await page.locator('#toastWrap').textContent();
    const pendenteSemRede = await page.evaluate(()=>CLOUD.temPendencia());
    await page.evaluate(()=>window.__reconecta());
    await page.waitForFunction(()=>window.__visto.doCache === false && !CLOUD.temPendencia());
    assert.deepEqual(await obrasNoServidor(), ['Obra que só o servidor tem'],
      'a obra que só o servidor tinha sumiu: o aparelho novo regravou o documento por cima');
    assert.match(listaSemRede, /Carregando suas obras/, 'sem ver o servidor, a lista não pode dizer que não há obra');
    assert.equal(gravacaoDireta, 'nao-carregado', 'o cloud.js também recusa');
    assert.notEqual(estadoDepoisDaRecusa, 'erro', 'a recusa não vira erro de sincronização');
    assert.equal(abriuNovaObra, false, 'o + não abre Nova obra antes de carregar');
    assert.match(avisos, /Conecte à internet para carregar suas obras antes de lançar/);
    assert.equal(pendenteSemRede, false, 'nada foi para a fila do SDK');
    console.log('ok - aparelho novo sem rede não grava por cima do servidor antes de ver os dados');

    await page.waitForFunction(()=>document.querySelector('#obrasList').textContent.includes('Obra que só o servidor tem'));
    await page.locator('#fab').click();
    await page.locator('#fNome').fill('Obra depois de carregar');
    await page.locator('#fArea').fill('90');
    await page.locator('#cSave').click();
    await page.waitForFunction(()=>!CLOUD.temPendencia());
    assert.deepEqual(await obrasNoServidor(), ['Obra depois de carregar', 'Obra que só o servidor tem']);
    console.log('ok - com o servidor de volta, a lista mostra a obra e gravar volta a funcionar');
  } finally { await env?.cleanup(); await browser.close(); }
})().catch(err=>{ console.error(err); process.exitCode = 1; });
