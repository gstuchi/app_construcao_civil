import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require=createRequire(import.meta.url);
const { __ctrl:ctrl }=await import('./helpers/firebase-stub.mjs');
let cloud;
beforeEach(async()=>{
  const event=new EventTarget();
  globalThis.window={ addEventListener:event.addEventListener.bind(event), dispatchEvent:event.dispatchEvent.bind(event),
    OBRA_CALC:require('../calc.js'), OBRA_CADASTRO:require('../cadastro.js'),
    location:{ reload:()=>ctrl.passos.push('reload') } };
  globalThis.CustomEvent=globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis,'navigator',{value:{onLine:true},configurable:true});
  ctrl.passos=[]; ctrl.falhas={}; ctrl.respostas=[]; ctrl.pendentesSDK=Promise.resolve();
  ctrl.perfil=null; ctrl.updateDocChamadas=[];
  await import('../cloud.js?conta='+Math.random()); cloud=window.CLOUD; await cloud.ready;
});
test('exclusão confirma documentos antes da conta e limpa cache por último',async()=>{
  await cloud.apagarConta('senha','APAGAR',{antesDeApagar:async()=>ctrl.passos.push('push')});
  assert.deepEqual(ctrl.passos,['reauth','push','delete:dados/u-teste','delete:perfis/u-teste','delete:push/u-teste','commit','deleteUser','terminate','clear','reload']);
});
test('senha errada e offline impedem qualquer delete',async()=>{
  ctrl.falhas.reauth={code:'auth/invalid-credential'};
  await assert.rejects(cloud.apagarConta('errada','APAGAR'),{code:'auth/invalid-credential'});
  assert.deepEqual(ctrl.passos,['reauth']); ctrl.passos=[]; navigator.onLine=false;
  await assert.rejects(cloud.apagarConta('senha','APAGAR'),{code:'offline'});
  assert.deepEqual(ctrl.passos,[]);
});
test('falha no batch mantém conta e cache; falha na conta informa exclusão parcial',async()=>{
  ctrl.falhas.commit={code:'permission-denied'};
  await assert.rejects(cloud.apagarConta('senha','APAGAR'),{code:'permission-denied'});
  assert.ok(!ctrl.passos.includes('deleteUser')); assert.ok(!ctrl.passos.includes('clear'));
  delete ctrl.falhas.commit; ctrl.falhas.deleteUser={code:'auth/network-request-failed'};
  await assert.rejects(cloud.apagarConta('senha','APAGAR'),{dadosApagados:true});
  assert.ok(!ctrl.passos.includes('clear'));
});
test('troca de senha aplica a regra nova antes de reautenticar',async()=>{
  await assert.rejects(cloud.trocarSenha('atual','123'),{code:'auth/weak-password',message:'Use pelo menos 8 caracteres.'});
  await assert.rejects(cloud.trocarSenha('atual','abcdefghij'),{code:'auth/weak-password',message:'Inclua pelo menos um número.'});
  assert.deepEqual(ctrl.passos,[]);
  await cloud.trocarSenha('atual','Nova-segura1');
  assert.deepEqual(ctrl.passos,['reauth','senha']);
});
test('cadastro grava perfil com nome e origem junto do e-mail e fuso',async()=>{
  ctrl.setDocChamadas=[];
  await cloud.signup('ana@exemplo.com','Obra2026x',{nome:'Ana',origem:'instagram'});
  const perfil=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(perfil.dados.nome,'Ana'); assert.equal(perfil.dados.origem,'instagram');
  assert.ok(perfil.dados.tz); assert.ok(perfil.dados.criado);
});
test('lerPerfil devolve nome e sobrenome, e null quando falta ou falha',async()=>{
  ctrl.perfil={email:'x',nome:'Ana',sobrenome:'Lima',origem:'google'};
  assert.deepEqual(await cloud.lerPerfil(),{nome:'Ana',sobrenome:'Lima'});
  ctrl.perfil=null; assert.equal(await cloud.lerPerfil(),null);
  ctrl.falhas.get={code:'unavailable'}; assert.equal(await cloud.lerPerfil(),null);
});
test('salvarNome atualiza e remove sobrenome vazio',async()=>{
  await cloud.salvarNome('Ana','Lima');
  await cloud.salvarNome('Ana','');
  assert.deepEqual(ctrl.updateDocChamadas.map(c=>c.dados),[{nome:'Ana',sobrenome:'Lima'},{nome:'Ana',sobrenome:'@del'}]);
});
test('logout limpa após signOut; falha de limpeza bloqueia novo login até retry',async()=>{
  ctrl.falhas.clear={code:'failed-precondition'};
  await assert.rejects(cloud.logout(),{code:'failed-precondition'});
  assert.deepEqual(ctrl.passos,['signOut','terminate','clear']);
  assert.equal(cloud.cacheBloqueado(),true);
  await assert.rejects(cloud.login('teste@exemplo.com','senha'),{code:'cache'});
  delete ctrl.falhas.clear; await cloud.limparCache();
  assert.equal(ctrl.passos.at(-1),'reload');
});
