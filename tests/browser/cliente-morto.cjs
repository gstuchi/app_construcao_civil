/* Cliente do Firestore morto (INTERNAL ASSERTION FAILED, b815): o lançamento feito
   depois da morte não se perde e a tela não diz "Salvando…" com ele só na memória.
   SDK real e Firestore Emulator; nenhum acesso ao banco de produção.
   Servidor: CUSTTA_EMULADORES=1 node tests/browser/servidor.cjs
   Execução: firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
             --only firestore,auth "node tests/browser/cliente-morto.cjs"

   Como o cliente morre aqui: igual à Blindagem 4 (12/11). A conexão de escrita, já
   aberta e sem gravação em voo, é fechada pelo servidor com PERMISSION_DENIED. O SDK
   12.18.0 tira um lote da fila vazia (remote_store.ts, handleWriteError), quebra com
   TypeError e daí em diante toda operação lança INTERNAL ASSERTION FAILED (b815). O
   emulador nunca fecha a conexão desse jeito, então a rota abaixo entrega o
   fechamento no canal de escrita. O canal roda em long polling só nesta suíte: cada
   resposta do servidor é um GET que termina, e a rota responde o seguinte com o erro.
   O caminho dentro do SDK é o mesmo do streaming. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, getDoc } = require('firebase/firestore');

const PROJETO = 'demo-custta-cliente-morto';
const UID = 'cliente-morto', EMAIL = 'morto@example.com';
const URL_APP = 'http://localhost:8123';

function cloudNoEmulador(){
  let c = fs.readFileSync(path.resolve(__dirname, '../../cloud.js'), 'utf8');
  const troca = (de, para) => { assert.ok(c.includes(de), 'cloud.js mudou: ' + de); c = c.replace(de, para); };
  troca("projectId: 'app-construcao-civil'", `projectId: '${PROJETO}'`);
  troca('deleteField, waitForPendingWrites,', 'deleteField, waitForPendingWrites, connectFirestoreEmulator,');
  troca('localCache: persistentLocalCache(', 'experimentalForceLongPolling: true, localCache: persistentLocalCache(');
  troca('let currentUser = null;', `connectFirestoreEmulator(db, '127.0.0.1', 8080, { mockUserToken: { sub: '${UID}', email: '${EMAIL}' } });
let currentUser = null;`);
  return c;
}

/* firebase-auth falso: a sessão da conta já está guardada neste aparelho. */
const authFalso = `
  export const getAuth = ()=>({});
  export const getIdToken = ()=>Promise.resolve('token-teste');
  export const onAuthStateChanged = (_a, cb)=>{ cb({ uid:'${UID}', email:'${EMAIL}' }); };
  export const EmailAuthProvider = { credential:()=>({}) };
  export const reauthenticateWithCredential = ()=>Promise.resolve();
  export const updatePassword = ()=>Promise.resolve();
  export const deleteUser = ()=>Promise.resolve();
  export const sendEmailVerification = ()=>Promise.resolve();
  export const reload = ()=>Promise.resolve();
  export const createUserWithEmailAndPassword = ()=>Promise.reject(new Error('Não usado'));
  export const signInWithEmailAndPassword = ()=>Promise.reject(new Error('Não usado'));
  export const sendPasswordResetEmail = ()=>Promise.resolve();
  export const signOut = ()=>Promise.resolve();
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

/* O canal de escrita do SDK passa pela rota; matar() fecha a próxima resposta com
   PERMISSION_DENIED, uma vez. */
async function canalDeEscrita(context){
  let matar = false;
  const pendentes = new Set();
  const fecha = item => {
    if(item.feito) return;
    item.feito = true; pendentes.delete(item); matar = false;
    const corpo = JSON.stringify([[item.aid + 1, [{ error: { code: 403, status: 'PERMISSION_DENIED',
      message: 'Permission denied on resource project (teste).' } }]]]);
    item.route.fulfill({ status: 200, body: `${corpo.length}\n${corpo}`, headers: {
      'content-type': 'text/plain', 'access-control-allow-origin': URL_APP, 'access-control-allow-credentials': 'true' } })
      .catch(()=>{});
  };
  await context.route(/127\.0\.0\.1:8080\/google\.firestore\.v1\.Firestore\/Write\/channel/, async route=>{
    const req = route.request(), u = new URL(req.url());
    if(req.method() !== 'GET' || u.searchParams.get('RID') !== 'rpc') return route.continue();
    const item = { route, aid: Number(u.searchParams.get('AID') || 0), feito: false };
    pendentes.add(item);
    if(matar) return fecha(item);
    try{
      const resposta = await route.fetch();
      if(item.feito) return;
      item.feito = true; pendentes.delete(item);
      await route.fulfill({ response: resposta });
    }catch{ /* página recarregou com o GET em aberto */ }
  });
  return { matar(){ matar = true; for(const item of [...pendentes]) fecha(item); } };
}

/* Espera sem lançar: a asserção é quem diz o que faltou. */
async function ate(condicao, ms){
  const fim = Date.now() + ms;
  while(Date.now() < fim){
    try{ if(await condicao()) return true; }catch{ /* página recarregando */ }
    await new Promise(r=>setTimeout(r, 100));
  }
  return false;
}

(async()=>{
  const browser = await chromium.launch();
  const env = await initializeTestEnvironment({ projectId: PROJETO, firestore: { host: '127.0.0.1', port: 8080 } });
  try{
    await env.clearFirestore();
    const noServidor = async()=>{
      let dados; // withSecurityRulesDisabled descarta o retorno do callback
      await env.withSecurityRulesDisabled(async ctx=>{ dados = (await getDoc(doc(ctx.firestore(), 'dados', UID))).data(); });
      return dados?.obras?.[0] ? dados.obras[0].gastos.map(g=>g.id) : null; // null: a obra não está lá
    };

    const context = await browser.newContext({ serviceWorkers: 'block' });
    await context.route('**/cloud.js', r=>r.fulfill({ contentType: 'text/javascript', body: cloudNoEmulador() }));
    await context.route('**/firebase-auth.js', r=>r.fulfill({ contentType: 'text/javascript', body: authFalso }));
    await context.addInitScript(()=>{
      sessionStorage.setItem('splashVista', '1');
      window.__toasts = [];
      document.addEventListener('DOMContentLoaded', ()=>{
        new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>{
          if(n.classList?.contains('toast')) window.__toasts.push(n.textContent);
        }))).observe(document.getElementById('toastWrap'), { childList: true });
      });
    });
    const canal = await canalDeEscrita(context);
    const page = await context.newPage();
    let cargas = 0, mortes = 0;
    page.on('load', ()=>{ cargas++; });
    page.on('pageerror', e=>{ if(/reading 'batchId'/.test(e.message)) mortes++; });
    const dialogos = [];
    page.on('dialog', d=>{ dialogos.push(d.type()); d.dismiss().catch(()=>{}); });
    const pilula = ()=>page.evaluate(()=>{
      const p = document.getElementById('syncPill');
      return p.classList.contains('hidden') ? '' : p.textContent.trim();
    });
    const abriu = ()=>page.waitForFunction(()=>window.CLOUD && CLOUD.user() && typeof dadosCarregados !== 'undefined' && dadosCarregados);
    const lanca = (id, descricao)=>page.evaluate(([id, descricao])=>{
      db.obras[0].gastos.push({ id, valor: 1234.56, topico: 'estrutura', descricao, data: '2026-11-13', pagamento: 'pix' });
      salvarComAviso('Gasto lançado com sucesso').catch(()=>{});
      renderAll();
    }, [id, descricao]);
    const mata = async()=>{
      const antes = mortes;
      canal.matar();
      assert.ok(await ate(()=>mortes > antes, 10000), 'o SDK não quebrou: o fechamento injetado não chegou');
    };

    await page.goto(URL_APP);
    await abriu();
    await page.evaluate(()=>{
      db = normaliza({ obras: [{ id: 'o1', nome: 'Obra da prova', fase: 'construcao', dataInicio: '2026-11-01', gastos: [] }],
        config: db.config });
      renderAll();
      return save();
    });
    assert.deepEqual(await noServidor(), [], 'a obra da prova não subiu');

    /* 1. Morre com a fila vazia; o lançamento seguinte sobrevive à recarga e sobe. */
    await mata();
    await lanca('g-depois', 'Lançado depois da morte');
    const recarregou = await ate(()=>cargas >= 2, 10000);
    assert.equal(recarregou, true, 'a página não recarregou sozinha: o lançamento ficou só na memória');
    await abriu();
    assert.ok(await ate(()=>page.evaluate(()=>db.obras[0]?.gastos?.some(g=>g.id === 'g-depois')), 10000),
      'o lançamento feito depois da morte não voltou na recarga');
    assert.ok(await ate(async()=>(await noServidor()).includes('g-depois'), 15000),
      'o lançamento feito depois da morte não chegou ao servidor');
    assert.ok(await ate(()=>page.evaluate(()=>!CLOUD.temPendencia()), 10000), 'a gravação reaplicada não foi confirmada');
    assert.ok(await ate(()=>page.evaluate(()=>!JSON.stringify({ ...sessionStorage }).includes('Lançado depois da morte')), 5000),
      'a cópia guardada ficou na sessão depois de o servidor confirmar');
    const avisos = await page.evaluate(()=>window.__toasts);
    assert.ok(avisos.some(t=>/recarregou para salvar seus últimos lançamentos/.test(t)),
      'a tela não disse por que recarregou: ' + JSON.stringify(avisos));
    console.log('ok - lançamento feito com o cliente morto sobrevive à recarga automática e sobe');

    /* 2. Morre de novo na mesma sessão: não recarrega em laço, não diz "Salvando…" nem
       "feche e abra", segura o fechamento e recarrega quando a pessoa toca no aviso. */
    await mata();
    await lanca('g-segunda', 'Lançado na segunda morte');
    const recarregouDeNovo = await ate(()=>cargas >= 3, 4000);
    assert.equal(recarregouDeNovo, false, 'recarregou de novo sozinho: a guarda contra laço falhou');
    assert.equal(await pilula(), 'Não salvou', 'com lançamento só na memória a pílula tem de dizer "Não salvou"');
    const avisosParado = await page.evaluate(()=>window.__toasts);
    assert.ok(avisosParado.some(t=>/Seus últimos lançamentos ainda não foram para a nuvem/.test(t)),
      'a segunda morte não avisou: ' + JSON.stringify(avisosParado));
    await page.evaluate(()=>{ window.dispatchEvent(new Event('offline')); window.dispatchEvent(new Event('online')); });
    assert.equal(await pilula(), 'Não salvou', 'a rede tirou o aviso');
    // erro qualquer da tela com lançamento só na memória: o aviso genérico manda fechar o app
    await page.evaluate(()=>{ ultimoAvisoErro = 0; window.__toasts.length = 0; setTimeout(()=>{ throw new Error('erro qualquer da tela'); }); });
    await page.waitForTimeout(300);
    const avisosDoErro = await page.evaluate(()=>window.__toasts);
    assert.ok(!avisosDoErro.some(t=>/feche e abra/.test(t)), 'com lançamento só na memória o aviso mandou fechar o app');
    await page.keyboard.press('a'); // gesto da pessoa: sem ele o navegador não pergunta antes de fechar
    await page.close({ runBeforeUnload: true });
    assert.ok(await ate(()=>dialogos.includes('beforeunload'), 3000), 'fechar com lançamento só na memória não pediu confirmação');
    assert.equal(page.isClosed(), false, 'a página fechou');
    const dialogosAntesDoToque = dialogos.length;
    await page.locator('#syncPill').click();
    assert.ok(await ate(()=>cargas >= 3, 10000), 'o toque em "Não salvou" não recarregou');
    assert.equal(dialogos.length, dialogosAntesDoToque, 'a recarga pedida pelo toque perguntou se podia sair');
    await abriu();
    assert.ok(await ate(async()=>(await noServidor()).includes('g-segunda'), 15000),
      'o lançamento da segunda morte não chegou ao servidor');
    assert.deepEqual((await noServidor()).sort(), ['g-depois', 'g-segunda'], 'o servidor perdeu um dos lançamentos');
    console.log('ok - segunda morte na sessão não recarrega em laço, avisa, segura o fechamento e sobe pelo toque');

    /* 3. Sem onde guardar (sessionStorage cheio ou bloqueado): recarregar apagaria o
       lançamento, então nem a recarga automática nem o toque recarregam. */
    const semEspaco = await browser.newContext({ serviceWorkers: 'block' });
    await semEspaco.route('**/cloud.js', r=>r.fulfill({ contentType: 'text/javascript', body: cloudNoEmulador() }));
    await semEspaco.route('**/firebase-auth.js', r=>r.fulfill({ contentType: 'text/javascript', body: authFalso }));
    await semEspaco.addInitScript(()=>{
      sessionStorage.setItem('splashVista', '1');
      const grava = Storage.prototype.setItem;
      Storage.prototype.setItem = function(k, v){
        if(this === sessionStorage && k !== 'splashVista') throw new DOMException('cheio', 'QuotaExceededError');
        return grava.call(this, k, v);
      };
      window.__toasts = [];
      document.addEventListener('DOMContentLoaded', ()=>{
        new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>{
          if(n.classList?.contains('toast')) window.__toasts.push(n.textContent);
        }))).observe(document.getElementById('toastWrap'), { childList: true });
      });
    });
    const canal3 = await canalDeEscrita(semEspaco);
    const pagina3 = await semEspaco.newPage();
    let cargas3 = 0, mortes3 = 0;
    pagina3.on('load', ()=>{ cargas3++; });
    pagina3.on('pageerror', e=>{ if(/reading 'batchId'/.test(e.message)) mortes3++; });
    await pagina3.goto(URL_APP);
    await pagina3.waitForFunction(()=>window.CLOUD && CLOUD.user() && typeof dadosCarregados !== 'undefined' && dadosCarregados);
    await pagina3.evaluate(()=>save()); // abre a conexão de escrita
    canal3.matar();
    assert.ok(await ate(()=>mortes3 > 0, 10000), 'o SDK não quebrou na terceira página');
    await pagina3.evaluate(()=>{
      db.obras[0].gastos.push({ id: 'g-sem-espaco', valor: 1, topico: 'estrutura', descricao: 'Sem onde guardar', data: '2026-11-13', pagamento: 'pix' });
      salvarComAviso('Gasto lançado com sucesso').catch(()=>{});
      renderAll();
    });
    assert.equal(await ate(()=>cargas3 >= 2, 3000), false, 'recarregou sem a cópia e apagaria o lançamento');
    await pagina3.evaluate(()=>{ window.__toasts.length = 0; });
    await pagina3.locator('#syncPill').click();
    assert.equal(await ate(()=>cargas3 >= 2, 2000), false, 'o toque recarregou sem a cópia');
    const avisosSemEspaco = await pagina3.evaluate(()=>window.__toasts);
    assert.ok(avisosSemEspaco.some(t=>/Não deu para guardar seus últimos lançamentos neste aparelho/.test(t)),
      'o toque sem a cópia não explicou: ' + JSON.stringify(avisosSemEspaco));
    await semEspaco.close();
    console.log('ok - sem onde guardar a cópia, nada recarrega e o toque explica');
  } finally { await env.cleanup(); await browser.close(); }
})().catch(err=>{ console.error(err); process.exitCode = 1; });
