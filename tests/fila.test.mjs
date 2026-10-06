/* Fila de escrita do cloud.js: tentativa automática, backoff, falha terminal e
   logout que não descarta trabalho. Roda sem browser e sem rede — o SDK do
   Firebase é desviado pro duplê em helpers/ por um loader de módulo. */
import { test, before, beforeEach } from 'node:test';
import assert from 'node:assert';
import { register } from 'node:module';
import { createRequire } from 'node:module';

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

before(async () => {
  montaJanela();
  const mod = await import('../cloud.js');
  void mod;
  CLOUD = globalThis.window.CLOUD;
  ctrl = (await import('./helpers/firebase-stub.mjs')).__ctrl;
  assert.ok(CLOUD, 'cloud.js precisa expor window.CLOUD');
});

/* Sessão nova a cada teste. Por padrão a conta já viu os dados (snapshot do
   servidor), como depois de abrir o app com rede; só os testes da guarda de
   carregamento partem de antes disso. */
const doServidor = { data: () => ({ obras: [], config: {} }), metadata: { fromCache: false, hasPendingWrites: false } };
async function abreSessao({ carregada = true } = {}){
  montaJanela();
  await import('../cloud.js?teste=' + Math.random());
  CLOUD = globalThis.window.CLOUD;
  await CLOUD.ready;
  if(carregada){ CLOUD.watchDados(() => {}); ctrl.snapshotCb(doServidor); }
  ctrl.setDocChamadas.length = 0;
  ctrl.respostas.length = 0;
  ctrl.signOutChamado = 0;
  eventos.length = 0;
  globalThis.navigator.onLine = true;
  ctrl.pendentesSDK = Promise.resolve();
  ctrl.token = Promise.resolve('token-teste');
}
beforeEach(() => abreSessao());

/* O backoff começa em 1s. Escritas são entregues ao SDK imediatamente. */
const passa = ms => new Promise(r => setTimeout(r, ms));

test('escrita que dá certo resolve a promise e volta pra ocioso', async () => {
  const p = CLOUD.saveDados({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } });
  await passa(400);
  await p; // rejeita o teste se nunca resolver
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('falha de rede não resolve na hora: reagenda e sobe na tentativa seguinte', async () => {
  ctrl.respostas.push({ code: 'unavailable' });
  const p = CLOUD.saveDados({ obras: [], config: {} });
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
  const p = CLOUD.saveDados({ obras: [], config: {} });
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

test('offline entrega todas as versões ao SDK antes de qualquer confirmação', async () => {
  globalThis.navigator.onLine = false;
  let confirmaPrimeira, confirmaSegunda;
  ctrl.respostas.push(new Promise(r => { confirmaPrimeira = r; }), new Promise(r => { confirmaSegunda = r; }));
  const p1 = CLOUD.saveDados({ obras: [{ id: 'primeira' }], config: {} });
  const p2 = CLOUD.saveDados({ obras: [{ id: 'segunda' }], config: {} });
  assert.strictEqual(ctrl.setDocChamadas.length, 2, 'última alteração também chega ao cache sem esperar rede');
  assert.strictEqual(ctrl.setDocChamadas[1].dados.obras[0].id, 'segunda');
  assert.strictEqual(ultimoEstado(), 'offline');

  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  assert.strictEqual(ultimoEstado(), 'salvando');
  confirmaPrimeira();
  await espera();
  assert.ok(CLOUD.temPendencia(), 'confirmação antiga não encerra a versão nova');
  confirmaSegunda();
  await Promise.all([p1, p2]);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('logout com pendência que não sobe recusa com code pendente', async () => {
  ctrl.respostas.push({ code: 'permission-denied' });
  CLOUD.saveDados({ obras: [], config: {} });
  await passa(400);
  assert.ok(CLOUD.temPendencia());

  ctrl.respostas.push({ code: 'permission-denied' });
  await assert.rejects(() => CLOUD.logout(), err => err.code === 'pendente');
  assert.strictEqual(ctrl.signOutChamado, 0, 'não sai enquanto tem trabalho não salvo');

  await CLOUD.tentarDeNovo();
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1, 'sai depois de recuperar a escrita');
  assert.strictEqual(CLOUD.temPendencia(), false);
});

test('logout normal sobe o pendente antes de sair', async () => {
  CLOUD.saveDados({ obras: [], config: {} });
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1);
  assert.ok(ctrl.setDocChamadas.length >= 1, 'o que estava na fila subiu antes do signOut');
});

test('erro de leitura do onSnapshot vira estado de erro visível', async () => {
  const parar = CLOUD.watchDados(() => {});
  assert.ok(ctrl.snapshotErroCb, 'watchDados precisa passar callback de erro pro onSnapshot');
  ctrl.snapshotErroCb({ code: 'permission-denied' });
  const leitura = eventos.filter(e => e.tipo === 'cloud-estado' && e.detail.origem === 'leitura');
  assert.strictEqual(leitura.length, 1);
  assert.strictEqual(leitura[0].detail.estado, 'erro');
  parar();
});

test('logout espera escrita em voo e só depois desativa push e sai', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r => { confirma = r; }));
  const p = CLOUD.saveDados({ obras: [], config: {} });
  let push = false;
  const saida = CLOUD.logout({ antesDeSair: async()=>{ push = true; } });
  await espera();
  assert.strictEqual(ctrl.signOutChamado, 0);
  assert.strictEqual(push, false);
  await assert.rejects(CLOUD.saveDados({ obras: [], config: {} }), { code: 'cancelled' });
  confirma();
  await Promise.all([p, saida]);
  assert.strictEqual(push, true);
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout espera fila do SDK recuperada de sessão anterior', async () => {
  let confirma;
  ctrl.pendentesSDK = new Promise(r => { confirma = r; });
  const saida = CLOUD.logout();
  await espera();
  assert.strictEqual(ctrl.signOutChamado, 0);
  confirma();
  await saida;
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('timeout de logout mantém sessão e permite confirmação posterior', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r=>{ confirma = r; }));
  const p = CLOUD.saveDados({ obras: [], config: {} });
  await assert.rejects(CLOUD.logout(), { code: 'pendente' });
  assert.strictEqual(ctrl.signOutChamado, 0);
  assert.ok(CLOUD.temPendencia());
  confirma();
  await p;
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout offline não descarta dados nem com opção forcar', async () => {
  navigator.onLine = false;
  await assert.rejects(CLOUD.logout({ forcar: true }), { code: 'pendente' });
  assert.strictEqual(ctrl.signOutChamado, 0);
});

test('snapshot pendente recuperado é entregue para restaurar a tela', async () => {
  let recebido;
  CLOUD.watchDados((blob, meta) => { recebido = { blob, meta }; });
  ctrl.snapshotCb({ data:()=>({ obras: [{ id: 'recuperada' }] }), metadata: { fromCache: true, hasPendingWrites: true } });
  assert.strictEqual(recebido.blob.obras[0].id, 'recuperada');
  assert.strictEqual(recebido.meta.localDirty, false);
  assert.ok(CLOUD.temPendencia());
  ctrl.snapshotCb({ data:()=>({ obras: [] }), metadata: { fromCache: false, hasPendingWrites: false } });
});

test('troca de conta invalida callbacks antigos e não envia blob para outra pessoa', async () => {
  let rejeita;
  ctrl.respostas.push(new Promise((_r, reject) => { rejeita = reject; }));
  const p = CLOUD.saveDados({ obras: [{ id: 'privada' }], config: {} });
  ctrl.authCb({ uid: 'outra', email: 'outra@exemplo.com' });
  await assert.rejects(p, { code: 'cancelled' });
  rejeita({ code: 'unavailable' });
  await espera();
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
  assert.strictEqual(ctrl.setDocChamadas[0].ref.path, 'dados/u-teste');
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
});

test('erro de leitura resiste a escrita e rede; retry recria assinatura', async () => {
  const parar = CLOUD.watchDados(()=>{});
  const antiga = ctrl.snapshotCb;
  ctrl.snapshotErroCb({ code:'permission-denied' });
  await CLOUD.saveDados({ obras:[], config:{} });
  assert.equal(CLOUD.estado(), 'erro', 'ack de escrita não esconde falha de leitura');
  window.dispatchEvent(new Event('online'));
  assert.equal(CLOUD.estado(), 'erro');
  const pronta = CLOUD.tentarDeNovo();
  assert.notEqual(ctrl.snapshotCb, antiga);
  ctrl.snapshotCb({ data:()=>({ obras:[] }), metadata:{ fromCache:false, hasPendingWrites:false } });
  await pronta;
  assert.equal(CLOUD.estado(), 'ocioso');
  parar();
});

test('limite invalida ack anterior e impede retry de enviar blob grande', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r=>{ confirma=r; }));
  const primeiro = CLOUD.saveDados({ obras:[], config:{} });
  const grande = CLOUD.saveDados({ obras:[], config:{ texto:'x'.repeat(900001) } });
  await assert.rejects(grande, { code:'limite' });
  await assert.rejects(primeiro, { code:'limite' });
  confirma(); await espera();
  assert.equal(CLOUD.estado(), 'erro');
  await assert.rejects(CLOUD.tentarDeNovo(), { code:'limite' });
  assert.equal(ctrl.setDocChamadas.length, 1);
  await CLOUD.saveDados({ obras:[], config:{} });
  assert.equal(CLOUD.estado(), 'ocioso');
});

test('refresh com falha de rede mantém sessão; credencial inválida encerra', async()=>{
  ctrl.token = Promise.reject({ code:'auth/network-request-failed' });
  assert.equal(await CLOUD.verificarSessao(true), false);
  assert.equal(ctrl.signOutChamado, 0);
  ctrl.token = Promise.reject({ code:'auth/invalid-refresh-token' });
  assert.equal(await CLOUD.verificarSessao(true), false);
  assert.equal(ctrl.signOutChamado, 1);
});

test('refresh antigo não encerra usuário que entrou depois', async()=>{
  let rejeita;
  ctrl.token = new Promise((_r,r)=>{ rejeita=r; });
  const verificou = CLOUD.verificarSessao(true);
  ctrl.authCb({ uid:'outra', email:'outra@exemplo.com' });
  rejeita({ code:'auth/invalid-refresh-token' });
  await verificou;
  assert.equal(ctrl.signOutChamado, 0);
  ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com' });
});

/* Quem não viu os dados não grava. Num aparelho novo sem rede o primeiro snapshot
   vem do cache, sem documento; gravar ali reescreveria o documento inteiro por cima
   das obras que só o servidor tem. Conta como visto: snapshot do servidor (com ou
   sem documento; conta nova de verdade recebe "não existe" dele) ou do cache com
   o documento. */
const semDocumento = doCache => ({ data: () => undefined, metadata: { fromCache: doCache, hasPendingWrites: false } });
const comDocumento = doCache => ({ data: () => ({ obras: [{ id: 'so-no-servidor' }], config: {} }), metadata: { fromCache: doCache, hasPendingWrites: false } });
const recusouSemErroDeSincronizacao = async p => {
  await assert.rejects(p, { code: 'nao-carregado' });
  assert.strictEqual(ctrl.setDocChamadas.length, 0, 'nada vai para a fila do SDK');
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.ok(!estados().includes('erro'), 'recusa não é erro de sincronização: ' + estados());
  assert.deepStrictEqual(eventos.filter(e => e.tipo === 'cloud-erro').map(e => e.detail),
    [{ code: 'nao-carregado', terminal: false }], 'a tela precisa saber o motivo');
};

for(const [abertura, chega, grava] of [
  ['sem snapshot nenhum', null, false],
  ['com o cache sem documento', semDocumento(true), false],
  ['com o cache com documento', comDocumento(true), true],
  ['com o servidor sem documento (conta nova)', semDocumento(false), true],
  ['com o servidor com documento', comDocumento(false), true],
]){
  test(`abertura ${abertura}: ${grava ? 'grava' : 'recusa com nao-carregado'}`, async () => {
    await abreSessao({ carregada: false });
    CLOUD.watchDados(() => {});
    if(chega) ctrl.snapshotCb(chega);
    eventos.length = 0;
    const p = CLOUD.saveDados({ obras: [{ id: 'nova' }], config: {} });
    if(!grava) return recusouSemErroDeSincronizacao(p);
    await p;
    assert.strictEqual(ctrl.setDocChamadas.length, 1);
  });
}

test('depois de ver os dados, snapshot do cache sem documento não volta a recusar', async () => {
  // conta nova que já ouviu "não existe" do servidor e então perdeu a rede
  await abreSessao({ carregada: false });
  CLOUD.watchDados(() => {});
  ctrl.snapshotCb(semDocumento(false));
  ctrl.snapshotCb(semDocumento(true));
  await CLOUD.saveDados({ obras: [{ id: 'nova' }], config: {} });
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
});

test('troca de conta volta a exigir os dados da conta que entrou', async () => {
  ctrl.authCb({ uid: 'outra', email: 'outra@exemplo.com' });
  await espera();
  eventos.length = 0;
  await recusouSemErroDeSincronizacao(CLOUD.saveDados({ obras: [], config: {} }));
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
});
