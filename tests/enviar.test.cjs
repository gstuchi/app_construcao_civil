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

function bancoPerfil({ subs, dados, perfil }){
  const gravacoes = [];
  const db = {
    collection:()=>({ get:async()=>({ size:1, docs:[{ id:'ana', data:()=>({ subs }), ref:{ update:async()=>{} } }] }) }),
    doc:caminho=>({ get:async()=>caminho.startsWith('dados/')
      ? { exists:true, data:()=>dados }
      : { exists:!!perfil, data:()=>perfil || undefined, ref:{ update:async v=>gravacoes.push([caminho, v]) } } }),
  };
  return { db, gravacoes };
}
const SUB = { s1:{ endpoint:'https://fcm.googleapis.com/fcm/send/x', keys:{} } };
const DADOS_ORC = { obras:[{ id:'o1', nome:'Casa', fase:'construcao', dataInicio:'2026-01-01',
  orcamento:{ modo:'topicos', topicos:{ fundacao:90000 } },
  gastos:[{ id:'g1', topico:'fundacao', valor:98000, data:'2026-07-10' }] }] };
const ESTADO_ORC = { 'o1|total':'passou', 'o1|t:fundacao':'passou' };
const rodar = (db, sendNotification) => enviaTodos({ db, FieldPath, FieldValue, periodo:'noite',
  agora:new Date('2026-07-10T21:00:00Z'), log:silencioso, webpush:{ sendNotification }, messaging:{} });

test('orçamento: avisa uma vez e grava a memória no perfil depois de entregar', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{ tz:'America/Sao_Paulo' } });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(JSON.parse(payload)));
  assert.equal(web.length, 1);
  assert.deepEqual(web[0].corpo.split('\n'), ['Casa passou R$ 8 mil do orçamento', 'Fundação passou R$ 8 mil do previsto']);
  assert.equal('avisosOrcamento' in web[0], false, 'memória não vai no payload');
  assert.deepEqual(gravacoes, [['perfis/ana', { avisosOrcamento:ESTADO_ORC }]]);
});

test('orçamento: mesma memória não reenvia nem regrava', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{ avisosOrcamento:ESTADO_ORC } });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(payload));
  assert.deepEqual(web, []);
  assert.deepEqual(gravacoes, []);
});

test('orçamento: sem perfil não avisa e não cria perfil', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:null });
  const web = [];
  await rodar(db, async(sub, payload)=>web.push(payload));
  assert.deepEqual(web, []);
  assert.deepEqual(gravacoes, []);
});

test('orçamento: envio falhou em todos os aparelhos, memória fica como estava', async()=>{
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:DADOS_ORC, perfil:{} });
  await rodar(db, async()=>{ throw Object.assign(new Error('x'), { statusCode:500 }); });
  assert.deepEqual(gravacoes, []);
});

test('orçamento: descida grava a memória mesmo sem nada a dizer', async()=>{
  const folgado = structuredClone(DADOS_ORC);
  folgado.obras[0].orcamento.topicos.fundacao = 200000;
  const { db, gravacoes } = bancoPerfil({ subs:SUB, dados:folgado, perfil:{ avisosOrcamento:ESTADO_ORC } });
  await rodar(db, async()=>{ throw new Error('não deveria enviar'); });
  assert.deepEqual(gravacoes, [['perfis/ana', { avisosOrcamento:{} }]]);
});
