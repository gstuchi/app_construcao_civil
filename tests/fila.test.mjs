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
});

/* O debounce é de 300ms e o backoff começa em 1s: os testes avançam o relógio
   de verdade em passos curtos em vez de mockar timer, pra não acoplar o teste
   à implementação. */
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

test('sem rede não tenta escrever: espera o online', async () => {
  globalThis.navigator.onLine = false;
  CLOUD.saveDados({ obras: [], config: {} });
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
  CLOUD.saveDados({ obras: [], config: {} });
  await passa(400);
  assert.ok(CLOUD.temPendencia());

  ctrl.respostas.push({ code: 'permission-denied' });
  await assert.rejects(() => CLOUD.logout(), err => err.code === 'pendente');
  assert.strictEqual(ctrl.signOutChamado, 0, 'não sai enquanto tem trabalho não salvo');

  await CLOUD.logout({ forcar: true });
  assert.strictEqual(ctrl.signOutChamado, 1, 'com forcar, sai mesmo assim');
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
