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

function janelaNativa({ receive = 'granted', falhaSalvar = false, falhaExcluir = false, falhaRemoverToken = false, permissaoAtual = 'prompt' } = {}){
  const log = [], memoria = new Map(), ouvintes = {};
  let tokenAtual = 'tok-1';
  const fcm = {
    checkPermissions: async()=>({ receive:permissaoAtual }),
    requestPermissions: async()=>({ receive }),
    getToken: async()=>({ token:tokenAtual }),
    deleteToken: async()=>{ if(falhaExcluir) throw new Error('fcm indisponível'); log.push(['deleteToken']); },
    addListener: (ev, fn)=>{ ouvintes[ev] = fn; },
  };
  const win = {
    navigator:{}, location:{ hash:'' },
    OBRA_NATIVO:{ ehNativo:()=>true, plugin:n => n === 'FirebaseMessaging' ? fcm : null },
    localStorage:{ getItem:k=>memoria.get(k) ?? null, setItem:(k,v)=>memoria.set(k,v), removeItem:k=>memoria.delete(k) },
    CLOUD:{ savePushToken: async(k, v)=>{ log.push(['save', k, v.token, v.plataforma]); if(falhaSalvar) throw new Error('rede'); },
            removePushToken: async k=>{ log.push(['remove', k]); if(falhaRemoverToken) throw new Error('rede'); } },
    OBRA_DIAG:{ registra(){} },
  };
  return { win, log, ouvintes, setToken:t=>{ tokenAtual = t; } };
}

test('nativo: ativar pede permissão, grava token e lembra a chave', async()=>{
  const { win, log } = janelaNativa();
  const push = criar(win);
  assert.equal(push.suportado(), true);
  assert.equal(await push.permissao(), 'default');
  assert.equal(await push.ativar(), true);
  assert.equal(await push.inscrito(), true);
  assert.deepEqual(log, [['save', hashEndpoint('tok-1'), 'tok-1', 'ios']]);
  await push.desativa();
  assert.deepEqual(log.slice(1), [['remove', hashEndpoint('tok-1')], ['deleteToken']]);
  assert.equal(await push.inscrito(), false);
});

test('nativo: fcm falha ao apagar o token mas desativar conclui (logout/apagar conta não travam)', async()=>{
  const { win, log } = janelaNativa({ falhaExcluir:true });
  const push = criar(win);
  await push.ativar(); log.length = 0;
  await push.desativa(); // não deve lançar mesmo com deleteToken rejeitando
  assert.deepEqual(log, [['remove', hashEndpoint('tok-1')]]);
  assert.equal(await push.inscrito(), false);
});

test('nativo: negado não grava; falha ao gravar apaga token', async()=>{
  const negado = janelaNativa({ receive:'denied' });
  assert.equal(await criar(negado.win).ativar(), false);
  assert.deepEqual(negado.log, []);
  const falha = janelaNativa({ falhaSalvar:true });
  await assert.rejects(criar(falha.win).ativar(), /rede/);
  assert.deepEqual(falha.log.at(-1), ['deleteToken']);
});

test('nativo: sincronizarToken salva o novo e remove o antigo quando o aparelho troca', async()=>{
  const { win, log, setToken } = janelaNativa({ permissaoAtual:'granted' });
  const push = criar(win);
  await push.ativar(); log.length = 0;
  setToken('tok-2');
  await push.sincronizarToken();
  assert.deepEqual(log, [['save', hashEndpoint('tok-2'), 'tok-2', 'ios'], ['remove', hashEndpoint('tok-1')]]);
  assert.equal(await push.inscrito(), true);
});

test('nativo: sincronizarToken não faz nada quando o token não mudou', async()=>{
  const { win, log } = janelaNativa({ permissaoAtual:'granted' });
  const push = criar(win);
  await push.ativar(); log.length = 0;
  await push.sincronizarToken();
  assert.deepEqual(log, []);
});

test('nativo: sincronizarToken não faz nada sem chave salva ou sem permissão concedida', async()=>{
  const semChave = janelaNativa({ permissaoAtual:'granted' });
  await criar(semChave.win).sincronizarToken();
  assert.deepEqual(semChave.log, []);

  const semPermissao = janelaNativa({ permissaoAtual:'prompt' });
  await criar(semPermissao.win).ativar(); semPermissao.log.length = 0;
  semPermissao.setToken('tok-2');
  await criar(semPermissao.win).sincronizarToken();
  assert.deepEqual(semPermissao.log, []);
});

test('nativo: tokenReceived atualiza o token salvo sem esperar sincronizarToken', async()=>{
  const { win, log, ouvintes } = janelaNativa({ permissaoAtual:'granted' });
  const push = criar(win);
  await push.ativar(); log.length = 0;
  ouvintes.tokenReceived({ token:'tok-2' });
  await new Promise(r => setTimeout(r, 0));
  assert.deepEqual(log, [['save', hashEndpoint('tok-2'), 'tok-2', 'ios'], ['remove', hashEndpoint('tok-1')]]);
});

test('web: sincronizarToken é no-op', async()=>{
  const { win } = janelaWeb();
  await criar(win).sincronizarToken();
});

test('nativo: tokenReceived sem chave salva não rearma notificações sem consentimento', async()=>{
  const { win, log, ouvintes } = janelaNativa({ permissaoAtual:'granted' });
  const push = criar(win); // nunca ativou neste aparelho — não há chave salva
  ouvintes.tokenReceived({ token:'tok-2' });
  await new Promise(r => setTimeout(r, 0));
  assert.deepEqual(log, []);
  assert.equal(await push.inscrito(), false);
});

test('nativo: desativar no meio de uma sincronização em voo desfaz o token novo sem religar', async()=>{
  const { win, log, ouvintes } = janelaNativa({ permissaoAtual:'granted' });
  const push = criar(win);
  await push.ativar(); log.length = 0; // chave salva = hash('tok-1')

  let resolverSalvar;
  win.CLOUD.savePushToken = (k, v) => { log.push(['save', k, v.token, v.plataforma]); return new Promise(r => { resolverSalvar = r; }); };

  ouvintes.tokenReceived({ token:'tok-2' }); // dispara atualizarToken; savePushToken ainda não resolveu
  await Promise.resolve(); // deixa o listener chegar até o await do savePushToken

  await push.desativa(); // sair/apagar conta rodando no meio da sincronização
  assert.equal(await push.inscrito(), false);

  resolverSalvar(); // savePushToken finalmente resolve
  await new Promise(r => setTimeout(r, 0)); // deixa atualizarToken perceber o desativar e desfazer

  assert.equal(await push.inscrito(), false, 'não pode religar depois do desativar concorrente');
  assert.deepEqual(log, [
    ['save', hashEndpoint('tok-2'), 'tok-2', 'ios'],
    ['remove', hashEndpoint('tok-1')],
    ['deleteToken'],
    ['remove', hashEndpoint('tok-2')], // desfaz o token novo — nunca chegou a religar
  ]);
});

test('nativo: toque na notificação entrega obraId', ()=>{
  const { win, ouvintes } = janelaNativa();
  const recebidos = [];
  criar(win).aoAbrirNotificacao(id => recebidos.push(id));
  ouvintes.notificationActionPerformed({ notification:{ data:{ obraId:'o1' } } });
  ouvintes.notificationActionPerformed({ notification:{ data:{} } });
  assert.deepEqual(recebidos, ['o1', null]);
});

test('web: hash #obra= abre uma vez e mensagem do SW também', ()=>{
  const ouvintes = {}, trocas = [];
  const win = { navigator:{ serviceWorker:{ addEventListener:(ev, fn)=>{ ouvintes[ev] = fn; } } },
    location:{ hash:'#obra=abc123', pathname:'/', search:'' }, history:{ replaceState:(...a)=>trocas.push(a) } };
  const recebidos = [];
  criar(win).aoAbrirNotificacao(id => recebidos.push(id));
  ouvintes.message({ data:{ tipo:'abrir-obra', obraId:'xyz' } });
  ouvintes.message({ data:{ tipo:'outra' } });
  assert.deepEqual(recebidos, ['abc123', 'xyz']);
  assert.equal(trocas.length, 1);
});
