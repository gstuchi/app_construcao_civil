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

beforeEach(() => {
  ctrl.setDocChamadas.length = 0;
  ctrl.respostas.length = 0;
  ctrl.signOutChamado = 0;
  eventos.length = 0;
  globalThis.navigator.onLine = true;
  ctrl.pendentesSDK = Promise.resolve();
});

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
  CLOUD.watchDados(() => {});
  assert.ok(ctrl.snapshotErroCb, 'watchDados precisa passar callback de erro pro onSnapshot');
  ctrl.snapshotErroCb({ code: 'permission-denied' });
  const leitura = eventos.filter(e => e.tipo === 'cloud-estado' && e.detail.origem === 'leitura');
  assert.strictEqual(leitura.length, 1);
  assert.strictEqual(leitura[0].detail.estado, 'erro');
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
