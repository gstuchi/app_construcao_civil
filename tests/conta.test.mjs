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
  ctrl.perfil=null; ctrl.updateDocChamadas=[]; ctrl.verificado=false; ctrl.aoVerificar=null;
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
test('signup avisa perfil-alterado só depois do setDoc do perfil terminar',async()=>{
  ctrl.setDocChamadas=[];
  let gravadoAoDisparar=false;
  window.addEventListener('perfil-alterado',()=>{
    gravadoAoDisparar=ctrl.setDocChamadas.some(c=>c.ref.path==='perfis/u-teste');
  });
  await cloud.signup('ana@exemplo.com','Obra2026x',{nome:'Ana'});
  assert.ok(gravadoAoDisparar);
});
test('lerPerfil devolve nome e sobrenome, e null quando falta ou falha',async()=>{
  ctrl.perfil={email:'x',nome:'Ana',sobrenome:'Lima',origem:'google'};
  assert.deepEqual(await cloud.lerPerfil(),{nome:'Ana',sobrenome:'Lima'});
  ctrl.perfil=null; assert.equal(await cloud.lerPerfil(),null);
  ctrl.falhas.get={code:'unavailable'}; assert.equal(await cloud.lerPerfil(),null);
});
test('salvarNome exige internet e não escreve nada offline',async()=>{
  ctrl.setDocChamadas=[];
  navigator.onLine=false;
  await assert.rejects(cloud.salvarNome('Ana','Lima'),{code:'offline'});
  assert.equal(ctrl.updateDocChamadas.length,0);
  assert.ok(!ctrl.setDocChamadas.some(c=>c.ref.path==='perfis/u-teste'));
  assert.ok(!ctrl.passos.some(p=>p.startsWith('get:')));
});
test('salvarNome atualiza perfil existente, curando o e-mail e removendo sobrenome vazio',async()=>{
  ctrl.perfil={email:'ANA@exemplo.com',nome:'Ana'};
  await cloud.salvarNome('Ana','Lima');
  await cloud.salvarNome('Ana','');
  assert.deepEqual(ctrl.updateDocChamadas.map(c=>c.dados),[
    {email:'teste@exemplo.com',nome:'Ana',sobrenome:'Lima'},
    {email:'teste@exemplo.com',nome:'Ana',sobrenome:'@del'},
  ]);
});
test('salvarNome cria o perfil quando o doc não existe (conta órfã)',async()=>{
  ctrl.perfil=null; ctrl.setDocChamadas=[];
  await cloud.salvarNome('Ana','Lima');
  const chamada=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(chamada.dados.email,'teste@exemplo.com');
  assert.ok(chamada.dados.criado);
  assert.ok(chamada.dados.tz);
  assert.equal(chamada.dados.nome,'Ana');
  assert.equal(chamada.dados.sobrenome,'Lima');
});
test('salvarNome cria perfil sem sobrenome quando não informado',async()=>{
  ctrl.perfil=null; ctrl.setDocChamadas=[];
  await cloud.salvarNome('Ana','');
  const chamada=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(chamada.dados.nome,'Ana');
  assert.ok(!('sobrenome' in chamada.dados));
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
test('cadastro envia a confirmação de e-mail depois de gravar o perfil',async()=>{
  ctrl.setDocChamadas=[];
  let perfilJaGravado=null;
  ctrl.aoVerificar=()=>{ perfilJaGravado=ctrl.setDocChamadas.some(c=>c.ref.path==='perfis/u-teste'); };
  await cloud.signup('ana@exemplo.com','Obra2026x',{nome:'Ana',origem:'instagram'});
  assert.equal(perfilJaGravado,true);
  assert.ok(ctrl.passos.includes('verificacao'));
});
test('falha ao enviar a confirmação não derruba o cadastro',async()=>{
  ctrl.falhas.verificacao={code:'auth/too-many-requests'};
  await cloud.signup('ana@exemplo.com','Obra2026x',{nome:'Ana',origem:'instagram'});
  assert.ok(ctrl.passos.includes('verificacao'));
});
test('conferirVerificacao atualiza a conta e avisa quando o e-mail foi confirmado',async()=>{
  let avisos=0; window.addEventListener('cloud-conta',()=>avisos++);
  assert.equal(await cloud.conferirVerificacao(),false);
  assert.equal(cloud.user().emailVerificado,false); assert.equal(avisos,0);
  ctrl.verificado=true;
  assert.equal(await cloud.conferirVerificacao(),true);
  assert.equal(cloud.user().emailVerificado,true); assert.equal(avisos,1);
});
test('conferirVerificacao offline não quebra e mantém o estado',async()=>{
  navigator.onLine=false;
  assert.equal(await cloud.conferirVerificacao(),false);
  assert.equal(cloud.user().emailVerificado,false);
});
