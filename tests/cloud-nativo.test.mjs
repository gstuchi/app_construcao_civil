import { test } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require = createRequire(import.meta.url);
const { __ctrl:ctrl } = await import('./helpers/firebase-stub.mjs');

async function carregar(nativo){
  const event = new EventTarget();
  globalThis.window = { addEventListener:event.addEventListener.bind(event), dispatchEvent:event.dispatchEvent.bind(event),
    OBRA_CALC:require('../calc.js'), location:{ reload(){} }, OBRA_NATIVO:{ ehNativo:()=>nativo } };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value:{ onLine:true }, configurable:true });
  ctrl.tabManager = null;
  await import('../cloud.js?nativo=' + nativo + Math.random());
  return ctrl.tabManager;
}

test('nativo usa aba única; web mantém várias abas', async()=>{
  assert.equal(await carregar(true), 'single');
  assert.equal(await carregar(false), 'multiple');
});
