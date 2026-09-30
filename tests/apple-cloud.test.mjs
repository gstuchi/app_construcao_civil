import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require=createRequire(import.meta.url);
const { __ctrl:ctrl }=await import('./helpers/firebase-stub.mjs');
let cloud, eventos, diag, pedidos, nativo, chamadasFetch;
const tique=()=>new Promise(r=>setTimeout(r,0));
async function carregar(){ await import('../cloud.js?apple='+Math.random()); cloud=window.CLOUD; await cloud.ready; }
async function entraComo(providerIds){
  await ctrl.authCb({ uid:'u-teste', email:'bia@privaterelay.appleid.com', emailVerified:true, displayName:null,
    providerData:providerIds.map(providerId=>({providerId})) });
  await tique();
}
/* OBRA_NATIVO falso: ehNativo liga o caminho do app iOS no cloud.js (lido na importação). */
async function preparar({ ehNativo=false }={}){
  const event=new EventTarget(); eventos=[]; diag=[]; pedidos=[]; chamadasFetch=[];
  nativo={ ehNativo:()=>ehNativo, falha:null,
    resposta:{ idToken:'id-apple', authorizationCode:'codigo-apple', givenName:'Bia', familyName:'Lima' },
    entrarApple:async a=>{ pedidos.push(a); if(nativo.falha) throw nativo.falha; return nativo.resposta; } };
  globalThis.window={ addEventListener:event.addEventListener.bind(event),
    dispatchEvent:e=>{ eventos.push(e); return event.dispatchEvent(e); },
    OBRA_CALC:require('../calc.js'), OBRA_CADASTRO:require('../cadastro.js'), OBRA_NATIVO:nativo,
    OBRA_DIAG:{ registra:(...a)=>diag.push(a) },
    location:{ reload:()=>ctrl.passos.push('reload') } };
  globalThis.CustomEvent=globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis,'navigator',{value:{onLine:true},configurable:true});
  globalThis.fetch=async(url,init)=>{ chamadasFetch.push({url,init}); return { ok:true, status:200 }; };
  Object.assign(ctrl,{ passos:[], falhas:{}, respostas:[], pendentesSDK:Promise.resolve(), perfil:null, perfilCache:null,
    setDocChamadas:[], credenciais:[], revogados:[], perfisAtualizados:[], popups:[], resultadoLogin:null, resultadoPopup:null });
  await carregar();
}
function sessaoFalsa(inicial={}){
  const m=new Map(Object.entries(inicial));
  globalThis.sessionStorage={ getItem:k=>m.has(k)?m.get(k):null, setItem:(k,v)=>m.set(k,String(v)), removeItem:k=>m.delete(k) };
  return m;
}
beforeEach(()=>preparar());
afterEach(()=>{ delete globalThis.matchMedia; delete globalThis.sessionStorage; });

test('web: entrarApple abre popup da Apple pedindo e-mail e nome em pt_BR',async()=>{
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['popup']);
  const p=ctrl.popups[0];
  assert.equal(p.providerId,'apple.com');
  assert.deepEqual(p.escopos,['email','name']);
  assert.deepEqual(p.parametros,{locale:'pt_BR'});
});
test('web: PWA instalado usa redirect e lembra que foi a Apple',async()=>{
  const sessao=sessaoFalsa(); globalThis.matchMedia=q=>({matches:q==='(display-mode: standalone)'});
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['redirect']);
  assert.equal(sessao.get('custta-redirect'),'apple.com');
});
test('web: popup bloqueado cai no redirect; desistência sobe',async()=>{
  sessaoFalsa();
  ctrl.falhas.popup={code:'auth/popup-blocked'};
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['popup','redirect']);
  ctrl.passos=[]; ctrl.falhas.popup={code:'auth/popup-closed-by-user'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/popup-closed-by-user'});
});
test('volta do redirect com erro avisa o provedor certo e esquece a marca',async()=>{
  const sessao=sessaoFalsa({'custta-redirect':'apple.com'});
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-social-erro');
  assert.deepEqual(ev.detail,{code:'auth/account-exists-with-different-credential',provedor:'apple.com'});
  assert.equal(sessao.has('custta-redirect'),false);
  eventos=[]; await carregar(); await tique();
  assert.equal(eventos.find(e=>e.type==='cloud-social-erro').detail.provedor,'google.com','sem marca é Google');
});
test('web: nome que só veio na resposta da Apple vai pro displayName',async()=>{
  ctrl.resultadoPopup={ user:{uid:'u-teste',displayName:null}, _tokenResponse:{providerId:'apple.com',firstName:'Bia',lastName:'Lima'} };
  await cloud.entrarApple();
  assert.deepEqual(ctrl.perfisAtualizados,[{displayName:'Bia Lima'}]);
  ctrl.perfisAtualizados=[];
  ctrl.resultadoPopup={ user:{uid:'u-teste',displayName:'Já Tem'}, _tokenResponse:{providerId:'apple.com',firstName:'Bia'} };
  await cloud.entrarApple();
  assert.deepEqual(ctrl.perfisAtualizados,[],'não sobrescreve nome existente');
});
test('nativo: plugin da Apple + signInWithCredential com o nonce cru',async()=>{
  await preparar({ehNativo:true});
  ctrl.resultadoLogin={ user:{uid:'u-teste',displayName:null} };
  await cloud.entrarApple(); await cloud.entrarApple();
  assert.ok(!ctrl.passos.includes('popup'));
  assert.match(pedidos[0].rawNonce,/^[0-9a-f]{64}$/);
  assert.notEqual(pedidos[0].rawNonce,pedidos[1].rawNonce,'nonce novo a cada login');
  assert.deepEqual(ctrl.credenciais[0],{providerId:'apple.com',idToken:'id-apple',rawNonce:pedidos[0].rawNonce});
  assert.deepEqual(ctrl.perfisAtualizados[0],{displayName:'Bia Lima'});
});
test('nativo: desistência sobe sem tentar entrar',async()=>{
  await preparar({ehNativo:true});
  nativo.falha={code:'auth/user-cancelled'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/user-cancelled'});
  assert.deepEqual(ctrl.credenciais,[]);
});
test('nativo: Apple sem idToken é erro, não login',async()=>{
  await preparar({ehNativo:true});
  nativo.resposta={idToken:'',authorizationCode:'x'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/invalid-credential'});
  assert.deepEqual(ctrl.credenciais,[]);
});
test('falha ao gravar o nome não derruba o login',async()=>{
  await preparar({ehNativo:true});
  ctrl.resultadoLogin={ user:{uid:'u-teste',displayName:null} };
  ctrl.falhas.updateProfile={code:'auth/network-request-failed'};
  await cloud.entrarApple();
  assert.ok(ctrl.passos.includes('credencial'));
});
test('perfilPendente vale para conta Apple',async()=>{
  await entraComo(['apple.com']);
  assert.equal(await cloud.perfilPendente(),true);
  ctrl.perfil={origem:'instagram'};
  assert.equal(await cloud.perfilPendente(),false);
});
test('web: apagar conta só Apple reautentica pela Apple, revoga o access token e apaga',async()=>{
  await entraComo(['apple.com']); ctrl.passos=[];
  ctrl.resultadoPopup={ credencial:{accessToken:'tok-apple'} };
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthPopup');
  assert.equal(ctrl.popups.at(-1).providerId,'apple.com');
  assert.deepEqual(ctrl.revogados,['tok-apple']);
  const i=n=>ctrl.passos.indexOf(n);
  assert.ok(i('commit')<i('revogar') && i('revogar')<i('deleteUser'),'revoga depois de apagar os dados e antes do usuário: '+ctrl.passos);
});
test('app: apagar conta só Apple reautentica pelo plugin e revoga o código pela API',async()=>{
  await preparar({ehNativo:true});
  await entraComo(['apple.com']); ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthApple');
  assert.equal(chamadasFetch.length,1);
  const {url,init}=chamadasFetch[0];
  assert.ok(url.startsWith('https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key='),url);
  assert.equal(init.method,'POST');
  assert.deepEqual(JSON.parse(init.body),{providerId:'apple.com',tokenType:'CODE',token:'codigo-apple',idToken:'token-teste'});
  assert.ok(ctrl.passos.includes('deleteUser'));
});
test('revogação que falha não impede apagar a conta e fica no diagnóstico',async()=>{
  await entraComo(['apple.com']); ctrl.passos=[];
  ctrl.resultadoPopup={ credencial:{accessToken:'tok-apple'} };
  ctrl.falhas.revogar={code:'auth/internal-error',message:'falhou'};
  await cloud.apagarConta('','APAGAR');
  assert.ok(ctrl.passos.includes('deleteUser'));
  assert.equal(diag[0][0],'apple-revogar');

  await preparar({ehNativo:true});
  globalThis.fetch=async()=>({ok:false,status:400});
  await entraComo(['apple.com']); ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.ok(ctrl.passos.includes('deleteUser'));
  assert.equal(diag[0][0],'apple-revogar');
});
test('conta com senha (mesmo com Apple) confirma pela senha e não revoga',async()=>{
  await entraComo(['password','apple.com']); ctrl.passos=[];
  await cloud.apagarConta('senha','APAGAR');
  assert.ok(ctrl.passos.includes('reauth'));
  for(const p of ['reauthPopup','reauthApple','revogar']) assert.ok(!ctrl.passos.includes(p),p);
});
test('conta Google + Apple sem senha confirma pela Apple',async()=>{
  await entraComo(['google.com','apple.com']);
  ctrl.resultadoPopup={ credencial:{accessToken:'tok'} };
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.popups.at(-1).providerId,'apple.com');
});
test('trocarSenha continua reautenticando por senha',async()=>{
  await entraComo(['password']); ctrl.passos=[];
  await cloud.trocarSenha('Velha2026x','Nova2026xy');
  assert.deepEqual(ctrl.passos.filter(p=>['reauth','senha'].includes(p)),['reauth','senha']);
});
