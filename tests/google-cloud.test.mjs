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
  ctrl.perfil=null; ctrl.perfilCache=null; ctrl.setDocChamadas=[];
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
test('falha na volta do redirect vira evento cloud-social-erro do Google',async()=>{
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-social-erro');
  assert.ok(ev); assert.deepEqual(ev.detail,{code:'auth/account-exists-with-different-credential',provedor:'google.com'});
});
test('perfilPendente: perfil no cache responde sem ir ao servidor',async()=>{
  await entraComo(['google.com']); ctrl.passos=[];
  ctrl.perfilCache={nome:'Ana'};
  assert.equal(await cloud.perfilPendente(),false);
  assert.deepEqual(ctrl.passos,['getCache:perfis/u-teste']);
});
test('perfilPendente: fora do cache (ou erro no cache) pergunta ao servidor',async()=>{
  await entraComo(['google.com']); ctrl.passos=[];
  assert.equal(await cloud.perfilPendente(),true, 'servidor sem doc = pendente');
  assert.deepEqual(ctrl.passos,['getCache:perfis/u-teste','getServer:perfis/u-teste']);
  ctrl.passos=[]; ctrl.falhas.getCache={code:'internal'}; ctrl.perfil={nome:'Ana'};
  assert.equal(await cloud.perfilPendente(),false);
  assert.deepEqual(ctrl.passos,['getCache:perfis/u-teste','getServer:perfis/u-teste']);
  ctrl.perfil=null; ctrl.falhas.getServer={code:'unavailable'};
  assert.equal(await cloud.perfilPendente(),false, 'erro no servidor não trava');
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

/* App iOS: OBRA_NATIVO falso com o plugin do Google. ehNativo é lido na importação. */
let pedidosGoogle, respostaGoogle, falhaGoogle;
async function carregarNativo(){
  pedidosGoogle=[]; respostaGoogle={ idToken:'id-google' }; falhaGoogle=null;
  window.OBRA_NATIVO={ ehNativo:()=>true,
    entrarGoogle:async a=>{ pedidosGoogle.push(a); if(falhaGoogle) throw falhaGoogle; return respostaGoogle; },
    sairGoogle:()=>{ ctrl.passos.push('sairGoogle'); return Promise.resolve(true); } };
  Object.assign(ctrl,{ credenciais:[], popups:[], resultadoLogin:{ user:{ uid:'u-teste' } } });
  await carregar();
}
test('app: entrarGoogle usa o plugin com o client web do projeto e entra com a credencial do Google',async()=>{
  await carregarNativo();
  await cloud.entrarGoogle();
  assert.deepEqual(ctrl.popups,[]);
  assert.equal(pedidosGoogle.length,1);
  const { clientId }=pedidosGoogle[0];
  // client web do mesmo projeto do Firebase: senão o Firebase recusa o idToken
  assert.match(clientId,/^(\d+)-[a-z0-9]+\.apps\.googleusercontent\.com$/);
  assert.equal(clientId.split('-')[0],ctrl.config.messagingSenderId);
  assert.deepEqual(ctrl.credenciais,[{ providerId:'google.com', idToken:'id-google' }]);
});
test('app: desistir do Google sobe sem tentar entrar',async()=>{
  await carregarNativo();
  falhaGoogle={ code:'auth/user-cancelled' };
  await assert.rejects(cloud.entrarGoogle(),{ code:'auth/user-cancelled' });
  assert.deepEqual(ctrl.credenciais,[]);
});
test('app: Google sem idToken é erro, não login',async()=>{
  await carregarNativo();
  respostaGoogle={ idToken:'' };
  await assert.rejects(cloud.entrarGoogle(),{ code:'auth/invalid-credential' });
  assert.deepEqual(ctrl.credenciais,[]);
});
test('app: apagar conta só Google reautentica pelo plugin, não revoga e esquece o Google',async()=>{
  await carregarNativo();
  const fetchOriginal=globalThis.fetch;
  try{
    let fetchs=0; globalThis.fetch=async()=>{ fetchs++; return { ok:true, status:200 }; };
    await entraComo(['google.com']); ctrl.passos=[]; ctrl.revogados=[];
    await cloud.apagarConta('','APAGAR');
    assert.equal(ctrl.passos[0],'reauthGoogle');
    assert.deepEqual(ctrl.popups,[]);
    assert.equal(fetchs,0,'revogação é só da Apple');
    assert.deepEqual(ctrl.revogados,[]);
    const i=n=>ctrl.passos.indexOf(n);
    assert.ok(i('deleteUser')>=0 && i('deleteUser')<i('sairGoogle'),'esquece o Google depois de apagar o usuário: '+ctrl.passos);
  }finally{ globalThis.fetch=fetchOriginal; }
});
test('app: sair esquece o Google depois do signOut do Firebase',async()=>{
  await carregarNativo();
  await entraComo(['google.com']); ctrl.passos=[];
  await cloud.logout();
  const i=n=>ctrl.passos.indexOf(n);
  assert.ok(i('signOut')>=0 && i('signOut')<i('sairGoogle'),'ordem: '+ctrl.passos);
});
test('app: sairGoogle que nunca responde não segura a saída',async()=>{
  await carregarNativo();
  window.OBRA_NATIVO.sairGoogle=()=>new Promise(()=>{});
  await entraComo(['google.com']); ctrl.passos=[];
  await cloud.logout();
  assert.ok(ctrl.passos.includes('signOut'));
});
