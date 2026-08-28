/* Fila de escrita do cloud.js: tentativa automática, backoff, falha terminal e
   logout que não descarta trabalho. Roda sem browser e sem rede — o SDK do
   Firebase é desviado pro duplê em helpers/ por um loader de módulo. */
import { test, before, beforeEach } from 'node:test';
import assert from 'node:assert';
import { register } from 'node:module';
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

register('./helpers/loader-firebase.mjs', import.meta.url);

const require = createRequire(import.meta.url);
const CALC = require('../calc.js');

let CLOUD, ctrl, eventos;

/* cloud.js é escrito pro browser: precisa de window, navigator e CustomEvent. */
function montaJanela(){
  eventos = [];
  const alvo = new EventTarget();
  globalThis.window = {
    addEventListener: alvo.addEventListener.bind(alvo),
    removeEventListener: alvo.removeEventListener.bind(alvo),
    dispatchEvent: e => { eventos.push({ tipo: e.type, detail: e.detail }); return alvo.dispatchEvent(e); },
    OBRA_CALC: CALC,
  };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value: { onLine: true }, configurable: true, writable: true });
}

const estados = () => eventos.filter(e => e.tipo === 'cloud-estado').map(e => e.detail.estado);
const ultimoEstado = () => estados()[estados().length - 1];
const espera = () => new Promise(r => setImmediate(r));
const salva = (blob, sessao = CLOUD.sessao()) => CLOUD.saveDados(blob, sessao);

before(async () => {
  montaJanela();
  const mod = await import('../cloud.js');
  void mod;
  CLOUD = globalThis.window.CLOUD;
  ctrl = (await import('./helpers/firebase-stub.mjs')).__ctrl;
  assert.ok(CLOUD, 'cloud.js precisa expor window.CLOUD');
});

beforeEach(() => {
  ctrl.setDocChamadas.length = 0;
  ctrl.respostas.length = 0;
  ctrl.signOutChamado = 0;
  ctrl.snapshots.length = 0;
  eventos.length = 0;
  globalThis.navigator.onLine = true;
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
});

/* O debounce é de 300ms e o backoff começa em 1s: os testes avançam o relógio
   de verdade em passos curtos em vez de mockar timer, pra não acoplar o teste
   à implementação. */
const passa = ms => new Promise(r => setTimeout(r, ms));

test('escrita que dá certo resolve a promise e volta pra ocioso', async () => {
  const p = salva({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } });
  await passa(400);
  await p; // rejeita o teste se nunca resolver
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('falha de rede não resolve na hora: reagenda e sobe na tentativa seguinte', async () => {
  ctrl.respostas.push({ code: 'unavailable' });
  const p = salva({ obras: [], config: {} });
  await passa(400);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'primeira tentativa saiu');
  assert.ok(estados().includes('repetindo'), 'estado repetindo foi publicado: ' + estados());

  await passa(1200); // backoff da 1ª falha = 1s
  await p;
  assert.strictEqual(ctrl.setDocChamadas.length, 2, 'tentou de novo sozinho');
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('falha terminal rejeita a promise, para o backoff e segura o dado', async () => {
  ctrl.respostas.push({ code: 'permission-denied' });
  const p = salva({ obras: [], config: {} });
  await passa(400);
  await assert.rejects(p, err => err.code === 'permission-denied');
  assert.strictEqual(ultimoEstado(), 'erro');
  assert.ok(CLOUD.temPendencia(), 'o dado não subiu, então continua guardado');

  await passa(1500);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'não fica martelando o servidor');

  // e "Tentar de novo" reaproveita o blob guardado
  await CLOUD.tentarDeNovo();
  assert.strictEqual(ctrl.setDocChamadas.length, 2);
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('sem rede não tenta escrever: espera o online', async () => {
  globalThis.navigator.onLine = false;
  salva({ obras: [], config: {} });
  await passa(400);
  assert.strictEqual(ctrl.setDocChamadas.length, 0, 'não gasta bateria tentando sem rede');
  assert.strictEqual(ultimoEstado(), 'offline');

  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  await passa(200);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'rede voltou: sobe na hora, sem esperar backoff');
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('logout com pendência que não sobe recusa com code pendente', async () => {
  ctrl.respostas.push({ code: 'permission-denied' });
  salva({ obras: [], config: {} });
  await passa(400);
  assert.ok(CLOUD.temPendencia());

  ctrl.respostas.push({ code: 'permission-denied' });
  await assert.rejects(() => CLOUD.logout(CLOUD.sessao()), err => err.code === 'pendente');
  assert.strictEqual(ctrl.signOutChamado, 0, 'não sai enquanto tem trabalho não salvo');

  await CLOUD.logout(CLOUD.sessao(), { forcar: true });
  assert.strictEqual(ctrl.signOutChamado, 1, 'com forcar, sai mesmo assim');
  assert.strictEqual(CLOUD.temPendencia(), false);
});

test('logout normal sobe o pendente antes de sair', async () => {
  salva({ obras: [], config: {} });
  await CLOUD.logout(CLOUD.sessao());
  assert.strictEqual(ctrl.signOutChamado, 1);
  assert.ok(ctrl.setDocChamadas.length >= 1, 'o que estava na fila subiu antes do signOut');
});

test('logout espera a escrita que já está em voo antes do signOut', async () => {
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  let libera;
  ctrl.respostas.push(new Promise(resolve => { libera = resolve; }));
  salva({ obras: [{ id: 'ainda-subindo' }], config: {} });
  await passa(400);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'escrita entrou em voo');

  const saindo = CLOUD.logout(CLOUD.sessao());
  await passa(50);
  assert.strictEqual(ctrl.signOutChamado, 0, 'não desloga enquanto a escrita segue em voo');

  libera();
  await saindo;
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout espera também a escrita mais nova enfileirada durante outra em voo', async () => {
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  let liberaPrimeira, liberaSegunda;
  ctrl.respostas.push(
    new Promise(resolve => { liberaPrimeira = resolve; }),
    new Promise(resolve => { liberaSegunda = resolve; }),
  );
  salva({ obras: [{ id: 'primeira' }], config: {} });
  await passa(400);
  salva({ obras: [{ id: 'segunda' }], config: {} });

  const saindo = CLOUD.logout(CLOUD.sessao());
  liberaPrimeira();
  await passa(50);
  assert.strictEqual(ctrl.signOutChamado, 0,
    'confirmação da escrita velha não libera logout enquanto a nova segue em voo');

  liberaSegunda();
  await saindo;
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout A não chama signOut depois que autenticação mudou para B', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  let liberaA;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  salva({ obras: [{ id: 'a-em-voo' }], config: {} });
  await passa(400);

  const saindoA = CLOUD.logout(CLOUD.sessao());
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  liberaA();

  await assert.rejects(saindoA, err => err.code === 'auth-changed');
  assert.strictEqual(ctrl.signOutChamado, 0,
    'logout capturado por A não pode encerrar sessão B');
});

test('logout com capacidade A já stale recusa sem afetar fila nem sessão B', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  const sessaoA = CLOUD.sessao();
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  globalThis.navigator.onLine = false;
  const pendenteB = salva({ obras: [{ id: 'b-pendente' }], config: {} });
  pendenteB.catch(()=>{});

  await assert.rejects(CLOUD.logout(sessaoA), err => err.code === 'auth-changed');
  assert.strictEqual(ctrl.signOutChamado, 0, 'capacidade stale não chama signOut');
  assert.strictEqual(CLOUD.temPendencia(), true, 'capacidade stale não descarta fila B');

  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  await pendenteB;
});

test('save disparado por callback durante saída conclui ou falha explícito', async () => {
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  let libera, segunda;
  ctrl.respostas.push(new Promise(resolve => { libera = resolve; }));
  const primeira = salva({ obras: [{ id: 'primeira' }], config: {} });
  primeira.then(()=>{
    segunda = salva({ obras: [{ id: 'callback-tardio' }], config: {} });
    segunda.catch(()=>{});
  });
  await passa(400);

  const saindo = CLOUD.logout(CLOUD.sessao());
  libera();
  await saindo;
  await espera();

  assert.ok(segunda, 'callback da primeira escrita tentou enfileirar a segunda');
  const resultado = await segunda.then(()=> 'salvou', err => err.code);
  assert.ok(resultado === 'salvou' || resultado === 'auth-signing-out',
    'segunda escrita não pode receber sucesso falso: ' + resultado);
  if(resultado === 'salvou')
    assert.strictEqual(ctrl.setDocChamadas.length, 2, 'sucesso exige segunda escrita real');
});

test('logout forçado rejeita promessa do blob descartado em vez de simular sucesso', async () => {
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  globalThis.navigator.onLine = false;
  const descartado = salva({ obras: [{ id: 'descartado' }], config: {} });
  descartado.catch(() => {});

  await CLOUD.logout(CLOUD.sessao(), { forcar: true });
  await assert.rejects(descartado, err => err.code === 'discarded');
});

test('logout forçado não deixa a nova conta escrever em paralelo com a anterior', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  let liberaA;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  salva({ obras: [{ id: 'a-em-voo' }], config: {} });
  await passa(400);

  await CLOUD.logout(CLOUD.sessao(), { forcar: true });
  ctrl.authCb(null);
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  const salvaB = salva({ obras: [{ id: 'b-novo' }], config: {} });
  await passa(400);
  assert.deepStrictEqual(ctrl.setDocChamadas.map(c => c.ref.path), ['dados/conta-a'],
    'B aguarda a escrita antiga terminar em vez de abrir escrita concorrente');

  liberaA();
  await salvaB;
  assert.deepStrictEqual(ctrl.setDocChamadas.map(c => c.ref.path),
    ['dados/conta-a', 'dados/conta-b']);
});

test('erro de leitura do onSnapshot vira estado de erro visível', async () => {
  CLOUD.watchDados(CLOUD.sessao(), () => {});
  assert.ok(ctrl.snapshotErroCb, 'watchDados precisa passar callback de erro pro onSnapshot');
  ctrl.snapshotErroCb({ code: 'permission-denied' });
  const leitura = eventos.filter(e => e.tipo === 'cloud-estado' && e.detail.origem === 'leitura');
  assert.strictEqual(leitura.length, 1);
  assert.strictEqual(leitura[0].detail.estado, 'erro');
});

test('callback tardio da sessão anterior não grava na conta nova', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  const sessaoA = CLOUD.sessao();
  let liberaA, tardia;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  const primeira = salva({ obras: [{ id: 'a-primeira' }], config: {} }, sessaoA);
  primeira.then(()=>{
    tardia = salva({ obras: [{ id: 'a-callback-tardio' }], config: {} }, sessaoA);
    tardia.catch(()=>{});
  });
  await passa(400);

  ctrl.authCb(null);
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  liberaA();
  await primeira;
  await espera();

  assert.ok(tardia, 'callback da conta A tentou salvar depois da entrada da conta B');
  await assert.rejects(tardia, err => err.code === 'auth-changed');
  await passa(400);
  assert.deepStrictEqual(ctrl.setDocChamadas.map(c => c.ref.path), ['dados/conta-a'],
    'callback vinculado à sessão A jamais pode escrever em dados/conta-b');
});

test('callback de mutação da sessão A não altera db depois da entrada B', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('const empty =');
  const fim = fonte.indexOf('const uid =');
  const chamadas = [];
  const contexto = {
    CLOUD: { saveDados: (blob, sessao) => { chamadas.push({ blob, sessao }); return Promise.resolve(); } },
    OBRA_CALC: { blobCabe: () => true },
    toast: () => {},
    Promise,
  };
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  const resultado = vm.runInNewContext(`${fonte.slice(inicio, fim)}
    sessaoDados = sessaoA;
    db.obras.push({ id: 'obra-a', gastos: [] });
    const callbackA = comSessaoDados(sessao => {
      db.obras[0].gastos.push({ id: 'gasto-tardio' });
      save(sessao);
    });
    sessaoDados = sessaoB;
    callbackA();
    ({ db, sessaoDados });`, { ...contexto, sessaoA, sessaoB });

  assert.strictEqual(resultado.db.obras[0].gastos.length, 0,
    'callback stale precisa parar antes de mutar db global');
  assert.strictEqual(chamadas.length, 0, 'callback stale não tenta salvar');
});

test('transição direta A para B limpa db antes do primeiro snapshot B', () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('function bootCloud(){');
  const fim = fonte.indexOf('/* Escrita que falhou', inicio);
  const watches = [];
  let authCb;
  const contexto = {
    CLOUD: {
      onAuth: cb => { authCb = cb; },
      sessao: () => contexto.sessao,
      watchDados: (...args) => { watches.push(args); return () => {}; },
    },
    sessao: null,
    unwatch: null,
    sessaoDados: null,
    db: { obras: [], config: {} },
    obraAberta: null,
    empty: () => ({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } }),
    showView: () => {}, renderAll: () => {},
    normaliza: x => x, canon: JSON.stringify,
  };
  vm.runInNewContext(`${fonte.slice(inicio, fim)}; bootCloud();`, contexto);

  contexto.sessao = Object.freeze({ uid: 'conta-a', geracao: 1 });
  authCb({ uid: 'conta-a' });
  const cbA = watches[0].at(-1);
  cbA({ obras: [{ id: 'segredo-a' }], config: {} },
    { pendingWrites: false, localDirty: false });
  assert.strictEqual(contexto.db.obras.length, 1);

  contexto.sessao = Object.freeze({ uid: 'conta-b', geracao: 2 });
  authCb({ uid: 'conta-b' });
  assert.deepStrictEqual(contexto.db.obras, [],
    'estado A não pode ficar visível enquanto snapshot B não chegou');
});

test('watch antigo ignora snapshot tardio depois de nova geração auth', () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  const sessaoA = CLOUD.sessao();
  const recebidos = [];
  CLOUD.watchDados(sessaoA, blob => recebidos.push(blob));
  const watchA = ctrl.snapshots.at(-1);

  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  watchA.cb({ data: () => ({ obras: [{ id: 'segredo-a' }] }),
    metadata: { fromCache: false, hasPendingWrites: false } });

  assert.deepStrictEqual(recebidos, [], 'callback da watch A foi revogado com sessão A');
});

test('escrita em voo A não marca snapshot B como alteração local', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  let liberaA;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  salva({ obras: [{ id: 'a-em-voo' }], config: {} });
  await passa(400);

  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  const recebidos = [];
  CLOUD.watchDados(CLOUD.sessao(), (_blob, meta) => recebidos.push(meta));
  ctrl.snapshots.at(-1).cb({ data: () => ({ obras: [{ id: 'b-remota' }] }),
    metadata: { fromCache: false, hasPendingWrites: false } });

  assert.strictEqual(recebidos[0].localDirty, false,
    'trabalho A não pode fazer app ignorar primeiro snapshot B');
  liberaA();
  await espera();
});

test('push vinculado à sessão A rejeita depois da entrada B', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  const sessaoA = CLOUD.sessao();
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });

  await assert.rejects(CLOUD.savePushSub('aparelho', { endpoint: 'x' }, sessaoA),
    err => err.code === 'auth-changed');
  await assert.rejects(CLOUD.removePushSub('aparelho', sessaoA),
    err => err.code === 'auth-changed');
  assert.strictEqual(ctrl.setDocChamadas.length, 0,
    'operação push A não pode usar currentUser B');
});

function montaPushApp({ ready, savePushSub, removePushSub, locks = {
  request: (_nome, _opcoes, fn) => fn(),
}, localStorage = {
  getItem: () => null, setItem: () => {}, removeItem: () => {},
} }){
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('async function pushAtual(){');
  const fim = fonte.indexOf('/* ===== AJUSTES ===== */', inicio);
  const contexto = {
    sessaoDados: Object.freeze({ uid: 'conta-a', geracao: 1 }),
    navigator: { serviceWorker: { ready }, ...(locks ? { locks } : {}) },
    Notification: { requestPermission: () => Promise.resolve('granted') },
    CLOUD: { savePushSub, removePushSub,
      sessaoAtiva: sessao => sessao === contexto.sessaoDados },
    hashEndpoint: endpoint => endpoint,
    b64ToU8: () => new Uint8Array(),
    VAPID_PUBLICA: 'vapid',
    pushSuportado: () => true,
    window: {}, localStorage, Promise, Uint8Array, setTimeout, clearTimeout,
  };
  const api = vm.runInNewContext(`${fonte.slice(inicio, fim)};
    ({ ativaPush, desativaPush, alternaPush, reconciliaPush, consultaPush,
       duranteSaidaPush });`, contexto);
  return { contexto, ...api };
}

function montaLogoutAuth({ sessao, desativa, duranteSaida, logout,
  alert = () => {}, confirm = () => true }){
  const fonte = readFileSync(new URL('../auth.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('let saindoDeProposito');
  const fim = fonte.indexOf('sair.onclick=doSair', inicio);
  const contexto = {
    confirm,
    alert,
    console: { warn: () => {} },
    window: { OBRA_PUSH: {
      desativa,
      duranteSaida: duranteSaida || (async (capacidade, decidir) => {
        const resultado = await desativa(capacidade);
        if(!resultado || resultado.seguro !== true) throw new Error('cleanup push sem confirmação');
        return decidir(resultado);
      }),
    } },
    CLOUD: { sessao: () => sessao(), logout },
  };
  return vm.runInNewContext(`${fonte.slice(inicio, fim)};
    ({ doSair, getSaindo: () => saindoDeProposito });`, contexto);
}

test('logout da UI conserva capacidade A durante cleanup mesmo após entrada B', async () => {
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  let atual = sessaoA, liberaPush;
  const argumentosPush = [], argumentosLogout = [];
  const auth = montaLogoutAuth({
    sessao: () => atual,
    desativa: sessao => {
      argumentosPush.push(sessao);
      return new Promise(resolve => { liberaPush = resolve; });
    },
    logout: (...args) => { argumentosLogout.push(args); return Promise.resolve(); },
  });

  const saindoA = auth.doSair();
  await espera();
  atual = sessaoB;
  liberaPush({ seguro: true });
  await saindoA;

  assert.strictEqual(argumentosPush[0], sessaoA,
    'cleanup push recebe capacidade imutável capturada no clique');
  assert.strictEqual(argumentosLogout[0][0], sessaoA,
    'logout não pode recapturar sessão B depois do await');
});

test('ativação push A não chama subscribe se sessão muda durante serviceWorker.ready', async () => {
  let liberaReady, subscriptions = 0;
  const reg = { pushManager: {
    subscribe: () => { subscriptions++; return Promise.resolve({}); },
    getSubscription: () => Promise.resolve(null),
  } };
  const ready = new Promise(resolve => { liberaReady = () => resolve(reg); });
  const app = montaPushApp({ ready,
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });
  const sessaoA = app.contexto.sessaoDados;

  const ativando = app.ativaPush(sessaoA);
  await espera();
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });
  liberaReady();

  assert.strictEqual(await ativando, false);
  assert.strictEqual(subscriptions, 0,
    'operação stale não pode criar inscrição origin-wide para conta B');
});

test('ativação push A não desfaz inscrição após sessão mudar durante subscribe', async () => {
  let liberaSubscribe, unsubscribes = 0, saves = 0;
  const sub = {
    endpoint: 'endpoint',
    toJSON: () => ({ endpoint: 'endpoint', keys: {} }),
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: {
    subscribe: () => new Promise(resolve => { liberaSubscribe = () => resolve(sub); }),
    getSubscription: () => Promise.resolve(null),
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: () => { saves++; return Promise.reject(Object.assign(new Error(), { code: 'auth-changed' })); },
    removePushSub: () => Promise.resolve() });
  const sessaoA = app.contexto.sessaoDados;

  const ativando = app.ativaPush(sessaoA);
  await espera();
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });
  liberaSubscribe();

  assert.strictEqual(await ativando, false);
  assert.strictEqual(saves, 0, 'sessão stale não grava inscrição na nuvem');
  assert.strictEqual(unsubscribes, 0,
    'não desfaz inscrição origin-wide que a sessão B pode estar usando');
});

test('desativação push A remove somente registro A após sessão mudar durante unsubscribe', async () => {
  let liberaUnsubscribe;
  const removes = [];
  const sub = {
    endpoint: 'endpoint',
    unsubscribe: () => new Promise(resolve => { liberaUnsubscribe = () => resolve(true); }),
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(sub) } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: () => Promise.resolve(),
    removePushSub: (chave, sessao) => { removes.push({ chave, sessao }); return Promise.resolve(); } });
  const sessaoA = app.contexto.sessaoDados;

  const desativando = app.desativaPush(sessaoA);
  await espera();
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });
  liberaUnsubscribe();
  await desativando;

  assert.strictEqual(removes.length, 1, 'cleanup pode apagar registro pertencente a A');
  assert.strictEqual(removes[0].chave, 'endpoint');
  assert.strictEqual(removes[0].sessao, sessaoA,
    'cleanup A nunca usa capacidade B para remover registro');
});

test('ativação B espera teardown A pausado e termina com inscrição B válida', async () => {
  let liberaUnsubscribe, inscrita = true, subscriptions = 0;
  const saves = [], removes = [];
  const subA = {
    endpoint: 'endpoint-a',
    unsubscribe: () => new Promise(resolve => {
      liberaUnsubscribe = () => { inscrita = false; resolve(true); };
    }),
  };
  const subB = {
    endpoint: 'endpoint-b',
    toJSON: () => ({ endpoint: 'endpoint-b', keys: {} }),
    unsubscribe: () => Promise.resolve(true),
  };
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(inscrita ? subA : null),
    subscribe: () => { subscriptions++; inscrita = true; return Promise.resolve(subB); },
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: (_chave, _sub, sessao) => { saves.push(sessao); return Promise.resolve(); },
    removePushSub: (_chave, sessao) => { removes.push(sessao); return Promise.resolve(); } });
  const sessaoA = app.contexto.sessaoDados;

  const desativandoA = app.desativaPush(sessaoA);
  await espera();
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;
  const ativandoB = app.ativaPush(sessaoB);
  await espera();

  assert.strictEqual(subscriptions, 0,
    'ativação B fica serializada até unsubscribe A terminar');
  liberaUnsubscribe();
  await Promise.all([desativandoA, ativandoB]);

  assert.strictEqual(inscrita, true, 'B continua inscrita após término tardio do teardown A');
  assert.deepStrictEqual(saves, [sessaoB], 'somente estado Firestore B é criado');
  assert.deepStrictEqual(removes, [sessaoA],
    'cleanup remove somente estado Firestore A, nunca B');
});

test('desativação push mantém cleanup completo do logout enquanto sessão é a mesma', async () => {
  let unsubscribes = 0, removes = 0;
  const sub = {
    endpoint: 'endpoint',
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(sub) } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: () => Promise.resolve(),
    removePushSub: () => { removes++; return Promise.resolve(); } });

  await app.desativaPush(app.contexto.sessaoDados);
  assert.strictEqual(unsubscribes, 1);
  assert.strictEqual(removes, 1);
});

test('operações push usam Web Lock exclusivo quando disponível', async () => {
  const pedidos = [];
  const locks = { request: (nome, opcoes, fn) => {
    pedidos.push({ nome, opcoes });
    return fn();
  } };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(null) } };
  const app = montaPushApp({ ready: Promise.resolve(reg), locks,
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });

  await app.desativaPush(app.contexto.sessaoDados);

  assert.strictEqual(pedidos.length, 1);
  assert.strictEqual(pedidos[0].nome, 'custta-push');
  assert.strictEqual(pedidos[0].opcoes.mode, 'exclusive');
});

test('toggle lê estado e decide somente dentro da transição push serializada', async () => {
  let entraNoLock;
  const locks = { request: (_nome, _opcoes, fn) => new Promise(resolve => {
    entraNoLock = () => resolve(fn());
  }) };
  let leituras = 0, unsubscribes = 0, subscriptions = 0;
  const sub = {
    endpoint: 'endpoint-a',
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: {
    getSubscription: () => { leituras++; return Promise.resolve(sub); },
    subscribe: () => { subscriptions++; return Promise.resolve(sub); },
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg), locks,
    localStorage: {
      getItem: () => JSON.stringify({ uid: 'conta-a', endpoint: 'endpoint-a' }),
      setItem: () => {}, removeItem: () => {},
    },
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });

  const alternando = app.alternaPush(app.contexto.sessaoDados);
  await espera();
  assert.strictEqual(leituras, 0, 'estado não é lido antes de adquirir lock');
  entraNoLock();
  await alternando;

  assert.ok(leituras >= 1);
  assert.strictEqual(unsubscribes, 1, 'estado ligado escolhe desativação sob mesmo lock');
  assert.strictEqual(subscriptions, 0, 'decisão atômica não ativa em paralelo');
});

test('falha transitória do lote em voo coalesce esperas no estado completo mais novo', async () => {
  let rejeitaPrimeiro;
  ctrl.respostas.push(new Promise((_resolve, reject) => { rejeitaPrimeiro = reject; }));
  const antiga = salva({ obras: [{ id: 'estado-antigo' }], config: {} });
  await passa(400);
  const nova = salva({ obras: [{ id: 'estado-completo-novo' }], config: {} });

  rejeitaPrimeiro(Object.assign(new Error('rede'), { code: 'unavailable' }));
  window.dispatchEvent(new CustomEvent('online'));
  await passa(100);

  const resultado = await Promise.race([
    Promise.all([antiga, nova]).then(() => 'resolvidas'),
    passa(300).then(() => 'timeout'),
  ]);
  assert.strictEqual(resultado, 'resolvidas', 'nenhum waiter do lote substituído fica órfão');
  assert.strictEqual(ctrl.setDocChamadas.at(-1).dados.obras[0].id, 'estado-completo-novo');
});

test('logout forçado rejeita waiters antigo e novo após falha transitória do lote em voo', async () => {
  let rejeitaPrimeiro;
  ctrl.respostas.push(new Promise((_resolve, reject) => { rejeitaPrimeiro = reject; }));
  const antiga = salva({ obras: [{ id: 'antigo' }], config: {} });
  antiga.catch(()=>{});
  await passa(400);
  const nova = salva({ obras: [{ id: 'novo' }], config: {} });
  nova.catch(()=>{});

  rejeitaPrimeiro(Object.assign(new Error('rede'), { code: 'unavailable' }));
  await espera();
  await CLOUD.logout(CLOUD.sessao(), { forcar: true });

  await assert.rejects(antiga, err => err.code === 'discarded');
  await assert.rejects(nova, err => err.code === 'discarded');
});

test('troca auth rejeita waiters antigo e novo após falha transitória do lote em voo', async () => {
  let rejeitaPrimeiro;
  ctrl.respostas.push(new Promise((_resolve, reject) => { rejeitaPrimeiro = reject; }));
  const antiga = salva({ obras: [{ id: 'antigo' }], config: {} });
  antiga.catch(()=>{});
  await passa(400);
  const nova = salva({ obras: [{ id: 'novo' }], config: {} });
  nova.catch(()=>{});

  rejeitaPrimeiro(Object.assign(new Error('rede'), { code: 'unavailable' }));
  await espera();
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });

  await assert.rejects(antiga, err => err.code === 'auth-changed');
  await assert.rejects(nova, err => err.code === 'auth-changed');
});

test('nova geração do mesmo uid descarta pendência da geração anterior', async () => {
  ctrl.authCb({ uid: 'mesmo-uid', email: 'a@exemplo.com' });
  globalThis.navigator.onLine = false;
  const antiga = salva({ obras: [{ id: 'geracao-antiga' }], config: {} });
  antiga.catch(()=>{});
  await passa(400);

  ctrl.authCb({ uid: 'mesmo-uid', email: 'a@exemplo.com' });
  await assert.rejects(antiga, err => err.code === 'auth-changed');
  assert.strictEqual(CLOUD.temPendencia(), false);

  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  await passa(100);
  assert.strictEqual(ctrl.setDocChamadas.length, 0,
    'uid igual não basta: fila velha também precisa comparar geração');
});

test('troca descarta lote pendente sem rejeitar escrita anterior em voo que confirma', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  const sessaoA = CLOUD.sessao();
  let liberaA;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  const emVooA = salva({ obras: [{ id: 'a-em-voo' }], config: {} }, sessaoA);
  await passa(400);

  const pendenteA = salva({ obras: [{ id: 'a-pendente' }], config: {} }, sessaoA);
  pendenteA.catch(()=>{});
  ctrl.authCb(null);
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });

  await assert.rejects(pendenteA, err => err.code === 'auth-changed');
  liberaA();
  await emVooA;
  assert.deepStrictEqual(ctrl.setDocChamadas.map(c => c.ref.path), ['dados/conta-a']);
});

test('troca de conta nunca grava o blob pendente da conta anterior na nova', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  globalThis.navigator.onLine = false;
  const pendente = salva({
    obras: [{ id: 'segredo-da-conta-a' }],
    config: { taxaMensal: 1, topicosCustom: [] },
  });
  pendente.catch(() => {});
  await passa(400);
  assert.ok(CLOUD.temPendencia(), 'blob da conta A ficou na fila offline');

  ctrl.authCb(null); // sessão revogada/expirada sem passar por CLOUD.logout()
  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  await passa(400);

  assert.ok(!ctrl.setDocChamadas.some(c => c.ref.path === 'dados/conta-b'),
    'dados da conta A jamais podem ser escritos no documento da conta B');
  assert.strictEqual(CLOUD.temPendencia(), false, 'fila antiga foi descartada na troca de conta');
  await assert.rejects(pendente, err => err.code === 'auth-changed');
});

test('conclusão tardia da escrita A não publica estado global na sessão B', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  let liberaA;
  ctrl.respostas.push(new Promise(resolve => { liberaA = resolve; }));
  const escritaA = salva({ obras: [{ id: 'a-em-voo' }], config: {} });
  await passa(400);

  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  eventos.length = 0;
  liberaA();
  await escritaA;
  await espera();

  assert.deepStrictEqual(estados(), [],
    'then da geração A não pode mudar a pill/estado global pertencente a B');
});

test('handler não muta db enquanto a mesma sessão está em signing-out', () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('const empty =');
  const fim = fonte.indexOf('const uid =');
  const sessao = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const chamadas = [];
  let ativa = false;
  const contexto = {
    CLOUD: {
      sessaoAtiva: s => ativa && s === sessao,
      saveDados: (blob, s) => { chamadas.push({ blob, s }); return Promise.resolve(); },
    },
    OBRA_CALC: { blobCabe: () => true }, toast: () => {}, Promise, sessao,
  };
  const resultado = vm.runInNewContext(`${fonte.slice(inicio, fim)}
    sessaoDados = sessao;
    db.obras.push({ id: 'obra', gastos: [] });
    const handler = comSessaoDados(s => {
      db.obras[0].gastos.push({ id: 'nao-pode-ficar' });
      save(s);
    });
    handler();
    ativa = true;
    ({ db });`, { ...contexto, get ativa(){ return ativa; }, set ativa(v){ ativa = v; } });

  assert.strictEqual(resultado.db.obras[0].gastos.length, 0,
    'save rejeitado no logout não pode deixar mutação para persistir depois');
  assert.strictEqual(chamadas.length, 0);
});

test('ativação só assume ownership depois do save e revoga A se auth muda no await', async () => {
  let liberaSave, unsubscribes = 0;
  const saves = [];
  const subA = {
    endpoint: 'endpoint-a',
    toJSON: () => ({ endpoint: 'endpoint-a', keys: {} }),
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(null),
    subscribe: () => Promise.resolve(subA),
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: (_chave, _sub, sessao) => {
      saves.push(sessao);
      return new Promise(resolve => { liberaSave = resolve; });
    },
    removePushSub: () => Promise.resolve(),
  });
  const sessaoA = app.contexto.sessaoDados;

  const ativandoA = app.ativaPush(sessaoA);
  while(!liberaSave) await espera();
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });
  liberaSave();

  assert.strictEqual(await ativandoA, false);
  assert.deepStrictEqual(saves, [sessaoA]);
  assert.strictEqual(unsubscribes, 1,
    'capacidade gravada para A precisa morrer antes da fila liberar B');
});

test('troca direta A→B revoga endpoint A e permite ciclo B independente', async () => {
  let atual = null, sequencia = 0;
  const saves = [], removes = [], unsubscribes = [];
  const novaSub = () => ({
    endpoint: `endpoint-${++sequencia}`,
    toJSON(){ return { endpoint: this.endpoint, keys: {} }; },
    unsubscribe(){ unsubscribes.push(this.endpoint); if(atual === this) atual = null; return Promise.resolve(true); },
  });
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(atual),
    subscribe: () => { atual = novaSub(); return Promise.resolve(atual); },
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: (chave, _sub, sessao) => { saves.push({ chave, sessao }); return Promise.resolve(); },
    removePushSub: (chave, sessao) => { removes.push({ chave, sessao }); return Promise.resolve(); },
  });
  const sessaoA = app.contexto.sessaoDados;
  assert.strictEqual(await app.ativaPush(sessaoA), true);
  const endpointA = atual.endpoint;

  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;
  await app.desativaPush(sessaoA);
  assert.deepStrictEqual(unsubscribes, [endpointA], 'endpoint origin-wide de A foi revogado');
  assert.strictEqual(removes.at(-1).sessao, sessaoA,
    'registro Firestore A foi removido/tentado com capacidade A');

  assert.strictEqual(await app.ativaPush(sessaoB), true);
  const endpointB = atual.endpoint;
  assert.notStrictEqual(endpointB, endpointA, 'B recebe endpoint rotacionado');
  await app.desativaPush(sessaoB);
  assert.deepStrictEqual(unsubscribes, [endpointA, endpointB]);
  assert.strictEqual(removes.at(-1).sessao, sessaoB,
    'B pode desativar sem depender da sessão A');
});

test('registro A removido permite cleanup mas endpoint ainda não pode ser reutilizado por B', async () => {
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const subA = {
    endpoint: 'endpoint-a',
    toJSON: () => ({ endpoint: 'endpoint-a', keys: {} }),
    unsubscribe: () => Promise.resolve(false),
  };
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(subA),
    subscribe: () => Promise.resolve(subA),
  } };
  let savesB = 0;
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: (_chave, _sub, sessao) => { if(sessao.uid === 'conta-b') savesB++; return Promise.resolve(); },
    removePushSub: () => Promise.resolve(),
  });
  app.contexto.sessaoDados = sessaoA;
  const teardownA = app.desativaPush(sessaoA);
  teardownA.catch(()=>{});
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;

  await assert.rejects(teardownA,
    err => err.code === 'push-still-active' || err.code === 'push-cleanup-failed');
  await assert.rejects(app.ativaPush(sessaoB), err =>
    err.code === 'push-still-active' || err.code === 'push-cleanup-failed');
  assert.strictEqual(savesB, 0,
    'B nunca registra/reusa endpoint enquanto não há prova de revogação de A');
});

test('sem Web Locks e sem inscrição toggle falha fechado sem subscribe nem save', async () => {
  let subscriptions = 0, saves = 0;
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(null),
    subscribe: () => { subscriptions++; return Promise.resolve({}); },
  } };
  const app = montaPushApp({
    ready: Promise.resolve(reg), locks: null,
    savePushSub: () => { saves++; return Promise.resolve(); },
    removePushSub: () => Promise.resolve(),
  });

  assert.strictEqual(await app.alternaPush(app.contexto.sessaoDados), false);
  assert.strictEqual(subscriptions, 0, 'ativação sem coordenação cross-tab não cria inscrição');
  assert.strictEqual(saves, 0, 'ativação indisponível não grava registro push');
});

test('cleanup não espera remoção remota pendurada quando unsubscribe confirma', async () => {
  let unsubscribes = 0;
  const sub = {
    endpoint: 'endpoint',
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(sub) } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: () => Promise.resolve(),
    removePushSub: () => new Promise(() => {}),
  });

  const resultado = await Promise.race([
    app.desativaPush(app.contexto.sessaoDados).then(() => 'resolvido'),
    passa(500).then(() => 'timeout'),
  ]);
  assert.strictEqual(resultado, 'resolvido');
  assert.strictEqual(unsubscribes, 1);
});

test('cleanup rejeita push-cleanup-failed somente quando remoção e unsubscribe falham', async () => {
  const sub = {
    endpoint: 'endpoint',
    unsubscribe: () => Promise.reject(new Error('unsubscribe falhou')),
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(sub) } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: () => Promise.resolve(),
    removePushSub: () => Promise.reject(new Error('remoção falhou')),
  });

  await assert.rejects(app.desativaPush(app.contexto.sessaoDados),
    err => err.code === 'push-cleanup-failed');
});

test('logout da UI falha fechado quando nenhum severing push foi confirmado', async () => {
  const avisos = [];
  let logouts = 0;
  const auth = montaLogoutAuth({
    sessao: () => Object.freeze({ uid: 'conta-a', geracao: 1 }),
    desativa: () => Promise.reject(Object.assign(new Error('cleanup inseguro'), {
      code: 'push-cleanup-failed',
    })),
    logout: () => { logouts++; return Promise.resolve(); },
    alert: msg => avisos.push(msg),
  });

  await auth.doSair();
  assert.strictEqual(logouts, 0, 'não encerra auth mantendo endpoint e registro ativos');
  assert.strictEqual(auth.getSaindo(), false);
  assert.match(avisos[0], /notifica/i);
});

test('logout da UI trata auth-changed esperado sem rejeição não tratada', async () => {
  const auth = montaLogoutAuth({
    sessao: () => Object.freeze({ uid: 'conta-a', geracao: 1 }),
    desativa: () => Promise.resolve({ seguro: true }),
    logout: () => Promise.reject(Object.assign(new Error('sessão mudou'), {
      code: 'auth-changed',
    })),
  });

  await auth.doSair();
  assert.strictEqual(auth.getSaindo(), false);
});

test('logout forçado da UI também trata auth-changed esperado', async () => {
  let chamadas = 0;
  const auth = montaLogoutAuth({
    sessao: () => Object.freeze({ uid: 'conta-a', geracao: 1 }),
    desativa: () => Promise.resolve({ seguro: true }),
    logout: () => {
      chamadas++;
      return Promise.reject(Object.assign(new Error('sessão mudou'), {
        code: chamadas === 1 ? 'pendente' : 'auth-changed',
      }));
    },
  });

  await auth.doSair();
  assert.strictEqual(chamadas, 2);
  assert.strictEqual(auth.getSaindo(), false);
});

test('B não reutiliza endpoint conhecido de A se só o registro remoto foi removido', async () => {
  let atual = null, salvaB = 0;
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const subA = {
    endpoint: 'endpoint-a',
    toJSON: () => ({ endpoint: 'endpoint-a', keys: {} }),
    unsubscribe: () => Promise.resolve(false),
  };
  const reg = { pushManager: {
    getSubscription: () => Promise.resolve(atual),
    subscribe: () => { atual = subA; return Promise.resolve(subA); },
  } };
  const app = montaPushApp({ ready: Promise.resolve(reg),
    savePushSub: (_chave, _dados, sessao) => {
      if(sessao.uid === 'conta-b') salvaB++;
      return Promise.resolve();
    },
    removePushSub: () => Promise.resolve(),
  });
  app.contexto.sessaoDados = sessaoA;
  assert.strictEqual(await app.ativaPush(sessaoA), true);

  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;
  await assert.rejects(app.ativaPush(sessaoB));
  assert.strictEqual(salvaB, 0);
});

test('troca direta A→B não instala sessão B quando teardown A falha', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('function bootCloud(){');
  const fim = fonte.indexOf('/* Escrita que falhou', inicio);
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  const watches = [], avisos = [];
  let authCb, atual = sessaoA;
  const contexto = {
    CLOUD: {
      onAuth: cb => { authCb = cb; }, sessao: () => atual,
      watchDados: (...args) => { watches.push(args); return () => {}; },
    },
    window: { OBRA_PUSH: {
      desativa: () => Promise.reject(
        Object.assign(new Error('unsubscribe falhou'), { code: 'push-cleanup-failed' })),
      reconcilia: () => Promise.resolve({ seguro: true }),
    } },
    sessaoDados: null, unwatch: null, db: { obras: [], config: {} }, obraAberta: null,
    empty: () => ({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } }),
    showView: () => {}, renderAll: () => {}, toast: msg => avisos.push(msg),
    normaliza: x => x, canon: JSON.stringify, console: { warn: () => {} }, Promise,
  };
  vm.runInNewContext(`${fonte.slice(inicio, fim)}; bootCloud();`, contexto);
  authCb({ uid: 'conta-a' });
  await espera();
  atual = sessaoB;
  authCb({ uid: 'conta-b' });
  await espera();
  await espera();

  assert.strictEqual(contexto.sessaoDados, sessaoA,
    'B não recebe capacidade enquanto endpoint A continua ativo');
  assert.strictEqual(watches.length, 1, 'watch B não abre após teardown inseguro');
  assert.match(avisos.at(-1), /notifica/i, 'falha não pode ser engolida');
});

test('teardown A atrasado não cancela endpoint que outra aba atribuiu a B', async () => {
  let unsubscribes = 0;
  const armazenamento = new Map([['custta-push-owner', JSON.stringify({
    uid: 'conta-b', endpoint: 'endpoint-b',
  })]]);
  const localStorage = {
    getItem: chave => armazenamento.get(chave) || null,
    setItem: (chave, valor) => armazenamento.set(chave, valor),
    removeItem: chave => armazenamento.delete(chave),
  };
  const subB = {
    endpoint: 'endpoint-b',
    unsubscribe: () => { unsubscribes++; return Promise.resolve(true); },
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(subB) } };
  const app = montaPushApp({ ready: Promise.resolve(reg), localStorage,
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });
  const sessaoA = app.contexto.sessaoDados;
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });

  await app.desativaPush(sessaoA);
  assert.strictEqual(unsubscribes, 0,
    'ownership compartilhado de B prevalece sobre estado local stale de A');
});

test('timeout remoto não libera Web Lock enquanto unsubscribe local continua', async () => {
  let liberaUnsubscribe, lockAtivo = false;
  const locks = { request: async (_nome, _opcoes, fn) => {
    lockAtivo = true;
    try{ return await fn(); }
    finally{ lockAtivo = false; }
  } };
  const sub = {
    endpoint: 'endpoint-a',
    unsubscribe: () => new Promise(resolve => { liberaUnsubscribe = resolve; }),
  };
  const reg = { pushManager: { getSubscription: () => Promise.resolve(sub) } };
  const app = montaPushApp({ ready: Promise.resolve(reg), locks,
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });

  const limpeza = app.desativaPush(app.contexto.sessaoDados);
  while(!liberaUnsubscribe) await espera();
  await passa(250);
  assert.strictEqual(lockAtivo, true,
    'lock cobre a operação perigosa real, não só Promise.race de 200ms');
  liberaUnsubscribe(true);
  await limpeza;
  assert.strictEqual(lockAtivo, false);
});

test('salvarComAviso não mostra confirmação nem timer de sessão A na UI B', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('const empty =');
  const fim = fonte.indexOf('const uid =');
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  let resolveSave, timer;
  const avisos = [];
  const contexto = {
    CLOUD: {
      saveDados: () => new Promise(resolve => { resolveSave = resolve; }),
      sessaoAtiva: sessao => sessao === contexto.sessaoDados,
    },
    OBRA_CALC: { blobCabe: () => true }, toast: msg => avisos.push(msg),
    setTimeout: fn => { timer = fn; return 1; }, clearTimeout: () => {}, Promise,
  };
  const api = vm.runInNewContext(`${fonte.slice(inicio, fim)};
    sessaoDados = sessaoA; ({ salvarComAviso, troca: () => { sessaoDados = sessaoB; } });`,
    { ...contexto, sessaoA, sessaoB });

  api.salvarComAviso(sessaoA, 'Gasto lançado com sucesso');
  api.troca();
  timer();
  resolveSave();
  await espera();
  assert.deepStrictEqual(avisos, [], 'feedback capturado por A não aparece na sessão B');
});

test('erro tardio da escrita A não publica ocioso na sessão B', async () => {
  ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
  let rejeitaA;
  ctrl.respostas.push(new Promise((_resolve, reject) => { rejeitaA = reject; }));
  const escritaA = salva({ obras: [{ id: 'a-em-voo' }], config: {} });
  escritaA.catch(()=>{});
  await passa(400);

  ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
  eventos.length = 0;
  rejeitaA(Object.assign(new Error('rede antiga'), { code: 'unavailable' }));
  await assert.rejects(escritaA, err => err.code === 'auth-changed');
  await espera();

  assert.deepStrictEqual(estados(), [],
    'catch stale não redefine estado global pertencente à sessão B');
});

test('logout falha fechado em exceção genérica e sem resultado positivo explícito', async () => {
  for(const desativa of [
    () => Promise.reject(new Error('Web Lock falhou')),
    () => Promise.resolve(undefined),
  ]){
    let logouts = 0;
    const avisos = [];
    const auth = montaLogoutAuth({
      sessao: () => Object.freeze({ uid: 'conta-a', geracao: 1 }), desativa,
      logout: () => { logouts++; return Promise.resolve(); },
      alert: msg => avisos.push(msg),
    });
    await auth.doSair();
    assert.strictEqual(logouts, 0);
    assert.strictEqual(auth.getSaindo(), false);
    assert.match(avisos[0], /notifica/i);
  }
});

test('toggle B não mostra nem reutiliza ownership A se unsubscribe falha', async () => {
  const armazenamento = new Map([['custta-push-owner', JSON.stringify({ uid: 'conta-a', endpoint: 'endpoint-a' })]]);
  const subA = { endpoint: 'endpoint-a', unsubscribe: () => Promise.resolve(false) };
  let salvaB = 0;
  const app = montaPushApp({
    ready: Promise.resolve({ pushManager: {
      getSubscription: () => Promise.resolve(subA),
      subscribe: () => { throw new Error('subscribe B inseguro'); },
    } }),
    localStorage: {
      getItem: chave => armazenamento.get(chave) || null,
      setItem: (chave, valor) => armazenamento.set(chave, valor),
      removeItem: chave => armazenamento.delete(chave),
    },
    savePushSub: () => { salvaB++; return Promise.resolve(); },
    removePushSub: () => Promise.resolve(),
  });
  app.contexto.sessaoDados = Object.freeze({ uid: 'conta-b', geracao: 2 });

  assert.strictEqual(await app.consultaPush(), null, 'UI B não considera endpoint A ligado');
  await assert.rejects(app.alternaPush(app.contexto.sessaoDados),
    err => err.code === 'push-still-active' || err.code === 'push-cleanup-failed');
  assert.strictEqual(salvaB, 0);
  assert.strictEqual(armazenamento.has('custta-push-owner'), true);
});

test('boot inicial B reconcilia push antes de abrir watch', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('function bootCloud(){');
  const fim = fonte.indexOf('/* Escrita que falhou', inicio);
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 1 });
  const ordem = [];
  let authCb, libera;
  const contexto = {
    CLOUD: { onAuth: cb => { authCb = cb; }, sessao: () => sessaoB,
      watchDados: () => { ordem.push('watch'); return () => {}; } },
    window: { OBRA_PUSH: { reconcilia: () => {
      ordem.push('reconcilia'); return new Promise(resolve => { libera = () => resolve({ seguro: true }); });
    } } },
    sessaoDados: null, unwatch: null, db: {}, obraAberta: null,
    empty: () => ({ obras: [], config: {} }), showView: () => {}, renderAll: () => {},
    toast: () => {}, normaliza: x => x, canon: JSON.stringify,
    console: { warn: () => {} }, Promise,
  };
  vm.runInNewContext(`${fonte.slice(inicio, fim)}; bootCloud();`, contexto);
  authCb({ uid: 'conta-b' });
  await espera();
  assert.deepStrictEqual(ordem, ['reconcilia']);
  assert.strictEqual(contexto.sessaoDados, null);
  libera();
  await espera();
  assert.deepStrictEqual(ordem, ['reconcilia', 'watch']);
  assert.strictEqual(contexto.sessaoDados, sessaoB);
});

test('boot inicial B falha fechado e alerta se reconciliação falha', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('function bootCloud(){');
  const fim = fonte.indexOf('/* Escrita que falhou', inicio);
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 1 });
  const watches = [], avisos = [];
  let authCb;
  const contexto = {
    CLOUD: { onAuth: cb => { authCb = cb; }, sessao: () => sessaoB,
      watchDados: () => { watches.push('watch'); return () => {}; } },
    window: { OBRA_PUSH: { reconcilia: () => Promise.reject(new Error('ready falhou')) } },
    sessaoDados: null, unwatch: null, db: {}, obraAberta: null,
    empty: () => ({ obras: [], config: {} }), showView: () => {}, renderAll: () => {},
    toast: msg => avisos.push(msg), normaliza: x => x, canon: JSON.stringify,
    console: { warn: () => {} }, Promise,
  };
  vm.runInNewContext(`${fonte.slice(inicio, fim)}; bootCloud();`, contexto);
  authCb({ uid: 'conta-b' });
  await passa(20);
  assert.deepStrictEqual(watches, []);
  assert.strictEqual(contexto.sessaoDados, null);
  assert.match(avisos[0], /notifica/i);
});

test('boot retoma uma vez após timeout e só abre watch depois da reconciliação real', async () => {
  const fonte = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
  const inicio = fonte.indexOf('function bootCloud(){');
  const fim = fonte.indexOf('/* Escrita que falhou', inicio);
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 1 });
  let authCb, liberaReal, chamadas = 0;
  const real = new Promise(resolve => { liberaReal = resolve; });
  const watches = [];
  const contexto = {
    CLOUD: { onAuth: cb => { authCb = cb; }, sessao: () => sessaoB,
      watchDados: () => { watches.push('watch'); return () => {}; } },
    window: { OBRA_PUSH: { reconcilia: () => {
      chamadas++;
      if(chamadas === 1)
        return Promise.reject(Object.assign(new Error('demorou'), { code: 'push-cleanup-timeout' }));
      return real.then(() => ({ seguro: true }));
    } } },
    sessaoDados: null, unwatch: null, db: {}, obraAberta: null,
    empty: () => ({ obras: [], config: {} }), showView: () => {}, renderAll: () => {},
    toast: () => {}, normaliza: x => x, canon: JSON.stringify,
    console: { warn: () => {} }, Promise,
  };
  vm.runInNewContext(`${fonte.slice(inicio, fim)}; bootCloud();`, contexto);
  authCb({ uid: 'conta-b' });
  await espera();
  await espera();

  assert.strictEqual(chamadas, 2, 'timeout ganha somente uma retomada serializada');
  assert.deepStrictEqual(watches, [], 'timeout nunca libera sessão/watch cedo');
  assert.strictEqual(contexto.sessaoDados, null);

  liberaReal();
  await espera();
  assert.deepStrictEqual(watches, ['watch']);
  assert.strictEqual(contexto.sessaoDados, sessaoB);
});

test('ativação também limita serviceWorker.ready pendurado', async () => {
  const app = montaPushApp({ ready: new Promise(() => {}),
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });
  await assert.rejects(app.ativaPush(app.contexto.sessaoDados),
    err => err.code === 'push-discovery-timeout');
});

test('ready e getSubscription pendurados têm timeout e liberam Web Lock sem unsubscribe', async () => {
  for(const ready of [
    new Promise(() => {}),
    Promise.resolve({ pushManager: { getSubscription: () => new Promise(() => {}) } }),
  ]){
    let lockAtivo = false;
    const locks = { request: async (_nome, _opcoes, fn) => {
      lockAtivo = true;
      try{ return await fn(); } finally{ lockAtivo = false; }
    } };
    const app = montaPushApp({ ready, locks,
      savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });
    await assert.rejects(app.desativaPush(app.contexto.sessaoDados),
      err => err.code === 'push-discovery-timeout');
    assert.strictEqual(lockAtivo, false, 'descoberta sem unsubscribe não retém lock');
  }
});

test('boot inicial B revoga subscription persistida de A antes da sessão', async () => {
  const armazenamento = new Map([['custta-push-owner', JSON.stringify({ uid: 'conta-a', endpoint: 'endpoint-a' })]]);
  let atual;
  const subA = { endpoint: 'endpoint-a', unsubscribe: () => {
    atual = null; return Promise.resolve(true);
  } };
  atual = subA;
  const app = montaPushApp({
    ready: Promise.resolve({ pushManager: { getSubscription: () => Promise.resolve(atual) } }),
    localStorage: {
      getItem: chave => armazenamento.get(chave) || null,
      setItem: (chave, valor) => armazenamento.set(chave, valor),
      removeItem: chave => armazenamento.delete(chave),
    },
    savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve(),
  });
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;

  const resultado = await app.reconciliaPush(sessaoB);
  assert.strictEqual(resultado.seguro, true);
  assert.strictEqual(resultado.localRevogado, true);
  assert.strictEqual(atual, null);
  assert.strictEqual(armazenamento.has('custta-push-owner'), false);
});

test('timeout de unsubscribe não libera lock nem inicia cleanup B concorrente', async () => {
  let liberaA, lockAtivo = false, atual;
  const locks = { request: async (_nome, _opcoes, fn) => {
    assert.strictEqual(lockAtivo, false);
    lockAtivo = true;
    try{ return await fn(); } finally{ lockAtivo = false; }
  } };
  const subA = { endpoint: 'endpoint-a', unsubscribe: () => new Promise(resolve => {
    liberaA = () => { atual = null; resolve(true); };
  }) };
  atual = subA;
  let subscriptions = 0;
  const subB = { endpoint: 'endpoint-b', toJSON: () => ({ endpoint: 'endpoint-b', keys: {} }), unsubscribe: () => Promise.resolve(true) };
  const app = montaPushApp({ locks, ready: Promise.resolve({ pushManager: {
    getSubscription: () => Promise.resolve(atual),
    subscribe: () => { subscriptions++; atual = subB; return Promise.resolve(subB); },
  } }), savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });

  const limpezaA = app.desativaPush(app.contexto.sessaoDados);
  while(!liberaA) await espera();
  await assert.rejects(limpezaA, err => err.code === 'push-cleanup-timeout');
  assert.strictEqual(lockAtivo, true);
  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;
  const ativacaoB = app.ativaPush(sessaoB);
  await passa(20);
  assert.strictEqual(subscriptions, 0);
  liberaA();
  assert.strictEqual(await ativacaoB, true);
});

test('cleanup push e decisão de signOut permanecem atômicos sob o mesmo Web Lock', async () => {
  let lockAtivo = false, filaLock = Promise.resolve(), atual, liberaDecisao;
  const locks = { request: (_nome, _opcoes, fn) => {
    const operacao = filaLock.then(async () => {
      lockAtivo = true;
      try{ return await fn(); } finally{ lockAtivo = false; }
    });
    filaLock = operacao.catch(()=>{});
    return operacao;
  } };
  const subA = { endpoint: 'endpoint-a', unsubscribe: () => {
    atual = null; return Promise.resolve(true);
  } };
  const subB = { endpoint: 'endpoint-b', toJSON: () => ({ endpoint: 'endpoint-b', keys: {} }) };
  atual = subA;
  let subscriptions = 0, decidiuComLock = false;
  const app = montaPushApp({ locks, ready: Promise.resolve({ pushManager: {
    getSubscription: () => Promise.resolve(atual),
    subscribe: () => { subscriptions++; atual = subB; return Promise.resolve(subB); },
  } }), savePushSub: () => Promise.resolve(), removePushSub: () => Promise.resolve() });
  const sessaoA = app.contexto.sessaoDados;

  const saidaA = app.duranteSaidaPush(sessaoA, () => {
    decidiuComLock = lockAtivo;
    return new Promise(resolve => { liberaDecisao = resolve; });
  });
  while(!liberaDecisao) await espera();

  const sessaoB = Object.freeze({ uid: 'conta-b', geracao: 2 });
  app.contexto.sessaoDados = sessaoB;
  const ativacaoB = app.ativaPush(sessaoB);
  await passa(20);
  assert.strictEqual(decidiuComLock, true, 'a decisão de signOut ainda ocorre sob exclusão');
  assert.strictEqual(subscriptions, 0,
    'outra aba não registra B entre a prova de cleanup A e a decisão de signOut');

  liberaDecisao('saiu');
  assert.strictEqual(await saidaA, 'saiu');
  assert.strictEqual(await ativacaoB, true);
});

test('logout da UI entrega toda a decisão de saída à exclusão push', async () => {
  const sessaoA = Object.freeze({ uid: 'conta-a', geracao: 1 });
  let chamadasExclusao = 0, dentroDaExclusao = false, logoutProtegido = false;
  const auth = montaLogoutAuth({
    sessao: () => sessaoA,
    desativa: () => { throw new Error('não deve separar cleanup da saída'); },
    duranteSaida: async (sessao, decidir) => {
      chamadasExclusao++;
      assert.strictEqual(sessao, sessaoA);
      dentroDaExclusao = true;
      try{ return await decidir({ seguro: true }); }
      finally{ dentroDaExclusao = false; }
    },
    logout: () => { logoutProtegido = dentroDaExclusao; return Promise.resolve(); },
  });

  await auth.doSair();
  assert.strictEqual(chamadasExclusao, 1);
  assert.strictEqual(logoutProtegido, true,
    'CLOUD.logout precisa decidir/signOut antes de liberar o Web Lock');
});

test('onAuth antes de ready entrega a geração inicial somente uma vez', async () => {
  const authCbPrincipal = ctrl.authCb;
  const cloudPrincipal = window.CLOUD;
  try{
    await import('../cloud.js?teste-on-auth-inicial');
    const cloudNovo = window.CLOUD;
    const recebidos = [];
    cloudNovo.onAuth(user => { recebidos.push(user && user.uid); });

    ctrl.authCb({ uid: 'conta-inicial', email: 'inicial@exemplo.com' });
    await espera();
    await espera();

    assert.deepStrictEqual(recebidos, ['conta-inicial'],
      'evento inicial e ready não podem notificar duas vezes a mesma geração');
  }finally{
    ctrl.authCb = authCbPrincipal;
    window.CLOUD = cloudPrincipal;
  }
});

test('onAuth serializa callbacks assíncronos entre gerações', async () => {
  const authCbPrincipal = ctrl.authCb;
  const cloudPrincipal = window.CLOUD;
  try{
    await import('../cloud.js?teste-on-auth-serial');
    const cloudNovo = window.CLOUD;
    let liberaA;
    const ordem = [];
    cloudNovo.onAuth(async user => {
      ordem.push('início-' + user.uid);
      if(user.uid === 'conta-a') await new Promise(resolve => { liberaA = resolve; });
      ordem.push('fim-' + user.uid);
    });

    ctrl.authCb({ uid: 'conta-a', email: 'a@exemplo.com' });
    while(!liberaA) await espera();
    ctrl.authCb({ uid: 'conta-b', email: 'b@exemplo.com' });
    await espera();
    assert.deepStrictEqual(ordem, ['início-conta-a'],
      'geração B não pode sobrepor teardown/boot assíncrono ainda em curso de A');

    liberaA();
    await espera();
    await espera();
    assert.deepStrictEqual(ordem,
      ['início-conta-a', 'fim-conta-a', 'início-conta-b', 'fim-conta-b']);
  }finally{
    ctrl.authCb = authCbPrincipal;
    window.CLOUD = cloudPrincipal;
  }
});

test('logout da UI trata falha genérica do CLOUD.logout e mostra feedback', async () => {
  const avisos = [];
  const auth = montaLogoutAuth({
    sessao: () => Object.freeze({ uid: 'conta-a', geracao: 1 }),
    desativa: () => Promise.resolve({ seguro: true }),
    logout: () => Promise.reject(new Error('Firebase indisponível')),
    alert: msg => avisos.push(msg),
  });

  await auth.doSair();
  assert.strictEqual(auth.getSaindo(), false);
  assert.strictEqual(avisos.length, 1);
  assert.match(avisos[0], /sair|tente de novo/i);
});
