'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criar, hashEndpoint } = require('../push.js');

function janelaWeb({ permissao = 'granted', falhaSalvar = false } = {}){
  const log = [];
  let sub = null;
  const pushManager = {
    getSubscription: async()=>sub,
    subscribe: async opcoes=>{ log.push(['subscribe', opcoes.userVisibleOnly]);
      sub = { endpoint:'https://fcm.googleapis.com/fcm/send/abc', toJSON:()=>({ endpoint:'https://fcm.googleapis.com/fcm/send/abc', keys:{ p256dh:'p', auth:'a' } }),
        unsubscribe: async()=>{ log.push(['unsubscribe']); sub = null; } };
      return sub; },
  };
  const win = {
    PushManager:function(){}, Notification:{ permission:'default', requestPermission: async()=>{ win.Notification.permission = permissao; return permissao; } },
    navigator:{ serviceWorker:{ getRegistration: async()=>({ active:{}, pushManager }), addEventListener(){} } },
    location:{ hash:'', pathname:'/', search:'' }, history:{ replaceState(){} },
    CLOUD:{ savePushSub: async(k, v)=>{ log.push(['save', k, v.endpoint]); if(falhaSalvar) throw new Error('rede'); },
            removePushSub: async k=>log.push(['remove', k]) },
    OBRA_DIAG:{ registra(){} },
  };
  return { win, log };
}

test('web: ativar inscreve e grava com chave do endpoint', async()=>{
  const { win, log } = janelaWeb();
  const push = criar(win);
  assert.equal(push.suportado(), true);
  assert.equal(await push.permissao(), 'default');
  assert.equal(await push.ativar(), true);
  assert.equal(await push.inscrito(), true);
  assert.deepEqual(log, [['subscribe', true], ['save', hashEndpoint('https://fcm.googleapis.com/fcm/send/abc'), 'https://fcm.googleapis.com/fcm/send/abc']]);
});

test('web: permissão negada não inscreve', async()=>{
  const { win, log } = janelaWeb({ permissao:'denied' });
  assert.equal(await criar(win).ativar(), false);
  assert.deepEqual(log, []);
});

test('web: falha ao gravar desfaz inscrição e propaga', async()=>{
  const { win, log } = janelaWeb({ falhaSalvar:true });
  await assert.rejects(criar(win).ativar(), /rede/);
  assert.deepEqual(log.at(-1), ['unsubscribe']);
});

test('web: desativar remove inscrição local e remota', async()=>{
  const { win, log } = janelaWeb();
  const push = criar(win);
  await push.ativar(); log.length = 0;
  await push.desativa();
  assert.deepEqual(log, [['unsubscribe'], ['remove', hashEndpoint('https://fcm.googleapis.com/fcm/send/abc')]]);
  assert.equal(await push.inscrito(), false);
});

test('sem suporte: desativa resolve sem tocar em nada', async()=>{
  const push = criar({ navigator:{}, location:{ hash:'' } });
  assert.equal(push.suportado(), false);
  await push.desativa();
});
