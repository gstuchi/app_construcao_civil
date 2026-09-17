'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criarHandler } = require('../api/push-diario.js');

function resposta(){
  const r = { status:0, corpo:null };
  r.res = { status(c){ r.status = c; return this; }, json(b){ r.corpo = b; return this; } };
  return r;
}
const carregar = chamadas => () => ({ enviaTodos: async a => { chamadas.push(a.periodo); return { enviados:2, removidos:0 }; }, deps:{} });

test('sem CRON_SECRET configurado responde 503 e não envia', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), {})({ headers:{}, query:{} }, r.res);
  assert.equal(r.status, 503); assert.deepEqual(chamadas, []);
});

test('segredo errado responde 401', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer outro' }, query:{} }, r.res);
  assert.equal(r.status, 401); assert.deepEqual(chamadas, []);
});

test('segredo certo envia com período da query', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer s3' }, query:{ periodo:'manha' } }, r.res);
  assert.equal(r.status, 200); assert.deepEqual(chamadas, ['manha']); assert.deepEqual(r.corpo, { enviados:2, removidos:0 });
  const r2 = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer s3' }, query:{ periodo:'xyz' } }, r2.res);
  assert.equal(chamadas.at(-1), 'noite');
});

test('vercel.json agenda 9h e 18h de Brasília na rota', ()=>{
  const v = require('../vercel.json');
  assert.deepEqual(v.crons, [
    { path:'/api/push-diario?periodo=manha', schedule:'0 12 * * *' },
    { path:'/api/push-diario?periodo=noite', schedule:'0 21 * * *' },
  ]);
});
