import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require=createRequire(import.meta.url);
const { __ctrl:ctrl }=await import('./helpers/firebase-stub.mjs');
let cloud, eventos;
async function carregar(){
  await import('../cloud.js?google='+Math.random()); cloud=window.CLOUD; await cloud.ready;
}
const tique=()=>new Promise(r=>setTimeout(r,0));
async function entraComo(providerIds){
  await ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com', emailVerified:true, displayName:'Ana Souza',
    providerData:providerIds.map(providerId=>({providerId})) });
  await tique();
}
beforeEach(async()=>{
  const event=new EventTarget(); eventos=[];
  globalThis.window={ addEventListener:event.addEventListener.bind(event),
    dispatchEvent:e=>{ eventos.push(e); return event.dispatchEvent(e); },
    OBRA_CALC:require('../calc.js'), OBRA_CADASTRO:require('../cadastro.js'),
    location:{ reload:()=>ctrl.passos.push('reload') } };
  globalThis.CustomEvent=globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis,'navigator',{value:{onLine:true},configurable:true});
  ctrl.passos=[]; ctrl.falhas={}; ctrl.respostas=[]; ctrl.pendentesSDK=Promise.resolve();
  ctrl.perfil=null; ctrl.setDocChamadas=[];
  await carregar();
});
afterEach(()=>{ delete globalThis.matchMedia; delete globalThis.location; });

test('authDomain é o próprio host só em custta.com.br',async()=>{
  assert.equal(ctrl.config.authDomain,'app-construcao-civil.firebaseapp.com');
  globalThis.location={hostname:'custta.com.br'}; await carregar();
  assert.equal(ctrl.config.authDomain,'custta.com.br');
  globalThis.location={hostname:'app-construcao-civil.vercel.app'}; await carregar();
  assert.equal(ctrl.config.authDomain,'app-construcao-civil.firebaseapp.com');
});
test('user() expõe provedores, temSenha e nome do Google',async()=>{
  await entraComo(['google.com']);
  assert.deepEqual(cloud.user().provedores,['google.com']);
  assert.equal(cloud.user().temSenha,false);
  assert.equal(cloud.user().nomeExibicao,'Ana Souza');
  await entraComo(['password','google.com']);
  assert.equal(cloud.user().temSenha,true);
  await ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com' }); await tique();
  assert.equal(cloud.user().temSenha,true, 'sem providerData conta como senha');
  assert.deepEqual(cloud.user().provedores,[]);
});
test('entrarGoogle usa popup na aba e redirect no PWA instalado',async()=>{
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['popup']);
  ctrl.passos=[]; globalThis.matchMedia=q=>({matches:q==='(display-mode: standalone)'});
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['redirect']);
});
test('popup bloqueado cai no redirect; outro erro sobe',async()=>{
  ctrl.falhas.popup={code:'auth/popup-blocked'};
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.passos,['popup','redirect']);
  ctrl.passos=[]; ctrl.falhas.popup={code:'auth/popup-closed-by-user'};
  await assert.rejects(cloud.entrarGoogle(),{code:'auth/popup-closed-by-user'});
  assert.deepEqual(ctrl.passos,['popup']);
});
test('falha na volta do redirect vira evento cloud-google-erro',async()=>{
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-google-erro');
  assert.ok(ev); assert.equal(ev.detail.code,'auth/account-exists-with-different-credential');
});
test('perfilPendente: só conta Google, lendo do servidor, falha não trava',async()=>{
  assert.equal(await cloud.perfilPendente(),false);
  assert.ok(!ctrl.passos.some(p=>p.startsWith('getServer')), 'conta por e-mail nem consulta');
  await entraComo(['google.com']);
  assert.equal(await cloud.perfilPendente(),true);
  assert.ok(ctrl.passos.includes('getServer:perfis/u-teste'));
  ctrl.perfil={nome:'Ana'};
  assert.equal(await cloud.perfilPendente(),false);
  ctrl.perfil=null; ctrl.falhas.getServer={code:'unavailable'};
  assert.equal(await cloud.perfilPendente(),false);
});
test('completarPerfil grava perfil completo e avisa perfil-alterado',async()=>{
  await entraComo(['google.com']);
  await cloud.completarPerfil({nome:'Ana',sobrenome:'Souza',origem:'instagram'});
  const g=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(g.dados.email,'teste@exemplo.com');
  assert.equal(g.dados.nome,'Ana'); assert.equal(g.dados.sobrenome,'Souza'); assert.equal(g.dados.origem,'instagram');
  assert.ok(g.dados.tz); assert.ok(g.dados.criado);
  assert.ok(eventos.some(e=>e.type==='perfil-alterado'));
  navigator.onLine=false;
  await assert.rejects(cloud.completarPerfil({nome:'Ana',origem:'instagram'}),{code:'offline'});
});
test('apagar conta só Google reautentica por popup, não por senha',async()=>{
  await entraComo(['google.com']);
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthPopup');
  assert.ok(!ctrl.passos.includes('reauth'));
  assert.ok(ctrl.passos.includes('deleteUser'));
});
test('conta com senha e Google continua reautenticando por senha',async()=>{
  await entraComo(['password','google.com']);
  await cloud.apagarConta('senha','APAGAR');
  assert.equal(ctrl.passos[0],'reauth');
});
/* Trava entre abas que só anota os passos: mostra se o popup veio antes dela. */
function comTravas(){
  Object.defineProperty(globalThis,'navigator',{configurable:true,value:{onLine:true,locks:{
    request(_nome, opcoes, cb){
      ctrl.passos.push(opcoes.mode==='shared' ? 'trava:aba' : 'trava:exclusiva');
      return Promise.resolve(cb({}));
    },
  }}});
}
test('conta só Google: popup de reautenticação vem antes da trava entre abas',async()=>{
  comTravas(); await carregar();
  await entraComo(['google.com']); ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthPopup', 'popup ainda dentro do gesto do usuário');
  assert.ok(ctrl.passos.indexOf('trava:exclusiva') > 0);
  assert.equal(ctrl.passos.filter(p=>p==='reauthPopup').length,1, 'não pede o popup de novo dentro da trava');
  assert.ok(ctrl.passos.includes('deleteUser'));
});
test('conta só Google: popup falhando não apaga nada',async()=>{
  comTravas(); await carregar();
  await entraComo(['google.com']); ctrl.passos=[];
  ctrl.falhas.reauthPopup={code:'auth/popup-blocked'};
  await assert.rejects(cloud.apagarConta('','APAGAR'),{code:'auth/popup-blocked'});
  assert.deepEqual(ctrl.passos,['reauthPopup']);
  delete ctrl.falhas.reauthPopup; ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.ok(ctrl.passos.includes('commit'), 'saindo voltou a false');
});
test('conta com senha reautentica dentro da trava, como antes',async()=>{
  comTravas(); await carregar();
  await entraComo(['password','google.com']); ctrl.passos=[];
  await cloud.apagarConta('senha','APAGAR');
  assert.ok(ctrl.passos.indexOf('reauth') > ctrl.passos.indexOf('trava:exclusiva'));
  assert.ok(!ctrl.passos.includes('reauthPopup'));
});
