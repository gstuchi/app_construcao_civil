import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require = createRequire(import.meta.url);
const { __ctrl:ctrl } = await import('./helpers/firebase-stub.mjs');
let cloud;
beforeEach(async()=>{
  const event = new EventTarget();
  globalThis.window = { addEventListener:event.addEventListener.bind(event), dispatchEvent:event.dispatchEvent.bind(event),
    OBRA_CALC:require('../calc.js'), location:{ reload(){} } };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value:{ onLine:true }, configurable:true });
  ctrl.setDocChamadas = []; ctrl.respostas = [];
  await import('../cloud.js?push=' + Math.random()); cloud = window.CLOUD; await cloud.ready;
});
test('token FCM grava e remove em push/{uid}.tokens com merge', async()=>{
  await cloud.savePushToken('k1', { token:'t', plataforma:'ios', criado:'2026-09-16' });
  await cloud.removePushToken('k1');
  assert.deepEqual(ctrl.setDocChamadas.map(c=>[c.ref.path, c.dados]), [
    ['push/u-teste', { tokens:{ k1:{ token:'t', plataforma:'ios', criado:'2026-09-16' } } }],
    ['push/u-teste', { tokens:{ k1:'@del' } }],
  ]);
});
