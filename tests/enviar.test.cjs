'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { enviaTodos } = require('../notificacoes/enviar.js');

const FieldPath = function(...partes){ this.partes = partes; };
const FieldValue = { delete:()=>'@del' };
const silencioso = { info(){}, warn(){}, error(){} };

function banco(pushDocs, dados){
  const removidos = [];
  return { removidos, db:{
    collection:()=>({ get:async()=>({ size:pushDocs.length, docs:pushDocs.map(([id, d])=>({ id, data:()=>d,
      ref:{ update:async(fp, v)=>removidos.push([id, ...fp.partes, v]) } })) }) }),
    doc:caminho=>({ get:async()=>({ data:()=>caminho.startsWith('dados/') ? dados : { tz:'America/Sao_Paulo' } }) }),
  } };
}
const DADOS = { obras:[{ id:'o1', nome:'Casa', fase:'construcao', gastos:[] }] };

test('envia por web push e FCM com obraId e remove tokens mortos', async()=>{
  const { db, removidos } = banco([['ana', {
    subs:{ s1:{ endpoint:'https://fcm.googleapis.com/fcm/send/x', keys:{} } },
    tokens:{ t1:{ token:'vivo' }, t2:{ token:'morto' }, t3:'formato-antigo' },
  }]], DADOS);
  const web = [], fcm = [];
  const r = await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date('2026-07-10T21:00:00Z'), log:silencioso,
    webpush:{ sendNotification:async(sub, payload)=>web.push([sub.endpoint, JSON.parse(payload)]) },
    messaging:{ send:async msg=>{ if(msg.token === 'morto') throw Object.assign(new Error('x'), { code:'messaging/registration-token-not-registered' }); fcm.push(msg); } },
  });
  assert.equal(web[0][1].obraId, 'o1');
  assert.deepEqual(fcm.map(m=>m.token), ['vivo', 'formato-antigo']);
  assert.deepEqual(fcm[0].notification, { title:'Custta', body:'Lançou os gastos de hoje?' });
  assert.deepEqual(fcm[0].data, { obraId:'o1' });
  assert.equal(fcm[0].apns.payload.aps.sound, 'default');
  assert.deepEqual(removidos, [['ana', 'tokens', 't2', '@del']]);
  assert.deepEqual(r, { enviados:3, removidos:1 });
});

test('falha transitória não remove token nem derruba os outros', async()=>{
  const { db, removidos } = banco([['ana', { tokens:{ a:{ token:'1' }, b:{ token:'2' } } }]], DADOS);
  const enviados = [];
  await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date('2026-07-10T21:00:00Z'), log:silencioso, webpush:{},
    messaging:{ send:async m=>{ if(m.token === '1') throw Object.assign(new Error('x'), { code:'messaging/internal-error' }); enviados.push(m.token); } } });
  assert.deepEqual(enviados, ['2']);
  assert.deepEqual(removidos, []);
});

test('sem subs nem tokens não lê dados', async()=>{
  let leu = false;
  const db = { collection:()=>({ get:async()=>({ size:1, docs:[{ id:'x', data:()=>({}), ref:{} }] }) }), doc:()=>{ leu = true; } };
  await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date(), log:silencioso, webpush:{}, messaging:{} });
  assert.equal(leu, false);
});
