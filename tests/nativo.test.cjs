'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criar, sha256Puro } = require('../nativo.js');
const { createHash, webcrypto } = require('node:crypto');

function janelaNativa(extra = {}){
  const chamadas = [], erros = [];
  const plugin = (nome, impl = {}) => new Proxy(impl, { get:(alvo, metodo)=>
    metodo in alvo ? alvo[metodo] : async(...args)=>{ chamadas.push([nome, metodo, ...args]); return {}; } });
  const win = {
    Capacitor:{ isNativePlatform:()=>true, Plugins:{
      Haptics:plugin('Haptics'), StatusBar:plugin('StatusBar'), SplashScreen:plugin('SplashScreen'),
      Share:plugin('Share'),
      Filesystem:plugin('Filesystem', { writeFile:async(a)=>{ chamadas.push(['Filesystem','writeFile',a]); return { uri:'file:///cache/'+a.path }; } }),
      App:plugin('App', { addListener:(ev, fn)=>{ chamadas.push(['App','addListener',ev]); win.__appState = fn; } }),
      ...extra,
    } },
    OBRA_DIAG:{ registra:(...a)=>erros.push(a) },
  };
  return { win, chamadas, erros };
}

test('web: tudo neutro e sem erro', async()=>{
  const n = criar({});
  assert.equal(n.ehNativo(), false);
  assert.equal(n.plugin('Share'), null);
  assert.equal(await n.compartilharArquivo({ nome:'a.csv', texto:'x', tipo:'text/csv', titulo:'t' }), null);
  assert.equal(await n.vibrar(), null);
  assert.equal(await n.barraStatus(true), null);
  assert.equal(await n.esconderSplash(), null);
  n.aoSegundoPlano(()=>{ throw new Error('não deveria'); });
  assert.equal(criar(null).ehNativo(), false);
});

test('nativo: plugins recebem argumentos certos', async()=>{
  const { win, chamadas } = janelaNativa();
  const n = criar(win);
  assert.equal(n.ehNativo(), true);
  await n.vibrar();
  await n.barraStatus(true);
  await n.barraStatus(false);
  await n.esconderSplash();
  assert.deepEqual(chamadas, [
    ['Haptics','impact',{ style:'LIGHT' }],
    ['StatusBar','setStyle',{ style:'LIGHT' }],
    ['StatusBar','setStyle',{ style:'DARK' }],
    ['SplashScreen','hide',undefined],
  ]);
});

test('nativo: compartilhar grava no cache e abre share sheet', async()=>{
  const { win, chamadas } = janelaNativa();
  const r = await criar(win).compartilharArquivo({ nome:'custta.csv', texto:'a;b', tipo:'text/csv', titulo:'Dados do Custta' });
  assert.equal(r, true);
  assert.deepEqual(chamadas, [
    ['Filesystem','writeFile',{ path:'custta.csv', data:'a;b', directory:'CACHE', encoding:'utf8', recursive:true }],
    ['Share','share',{ title:'Dados do Custta', files:['file:///cache/custta.csv'] }],
  ]);
});

test('nativo: cancelar share não é erro; falha real lança e registra', async()=>{
  const cancela = janelaNativa({ Share:{ share:async()=>{ throw new Error('Share canceled'); } } });
  assert.equal(await criar(cancela.win).compartilharArquivo({ nome:'a', texto:'', tipo:'', titulo:'' }), true);
  const falha = janelaNativa({ Share:{ share:async()=>{ throw new Error('disco cheio'); } } });
  await assert.rejects(criar(falha.win).compartilharArquivo({ nome:'a', texto:'', tipo:'', titulo:'' }), /disco cheio/);
  assert.equal(falha.erros[0][0], 'nativo-share');
});

test('nativo: erro de plugin não propaga', async()=>{
  const { win, erros } = janelaNativa({ Haptics:{ impact:async()=>{ throw new Error('sem motor'); } } });
  assert.equal(await criar(win).vibrar(), null);
  assert.equal(erros[0][0], 'nativo-haptics');
});

test('nativo: segundo plano chama só ao ficar inativo', ()=>{
  const { win } = janelaNativa();
  let n = 0;
  criar(win).aoSegundoPlano(()=>n++);
  win.__appState({ isActive:true });
  win.__appState({ isActive:false });
  assert.equal(n, 1);
});

test('marcarAmbiente: nativo e standalone viram classe no <html>', ()=>{
  const classes = new Set();
  const doc = { documentElement:{ classList:{ add:c=>classes.add(c) } } };
  const win = { Capacitor:{ isNativePlatform:()=>true, Plugins:{} }, matchMedia:()=>({ matches:false }), navigator:{} };
  criar(win).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['nativo']);
  classes.clear();
  const web = { matchMedia:q=>({ matches:q === '(display-mode: standalone)' }), navigator:{} };
  criar(web).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['standalone']);
  classes.clear();
  criar({ matchMedia:()=>({ matches:false }), navigator:{ standalone:true } }).marcarAmbiente(doc);
  assert.deepEqual([...classes], ['standalone']);
});

test('sha256Puro bate com o crypto do Node (vários blocos e UTF-8)', ()=>{
  const entradas = ['', 'abc', 'a'.repeat(55), 'a'.repeat(56), 'a'.repeat(64), 'a'.repeat(200), 'ção 🍎', '0f'.repeat(32)];
  for(const e of entradas) assert.equal(sha256Puro(e), createHash('sha256').update(e, 'utf8').digest('hex'), JSON.stringify(e));
});

test('entrarApple: fora do app devolve null', async()=>{
  assert.equal(await criar({}).entrarApple({ rawNonce:'x' }), null);
});

test('entrarApple: pede e-mail e nome e manda o SHA-256 do nonce, com e sem crypto.subtle', async()=>{
  const pedidos = [];
  const resposta = { idToken:'id', authorizationCode:'cod', givenName:'Bia', familyName:'Lima' };
  for(const cripto of [undefined, webcrypto]){
    const { win } = janelaNativa({ AppleSignIn:{ signIn:async a=>{ pedidos.push(a); return resposta; } } });
    if(cripto) win.crypto = cripto;
    assert.deepEqual(await criar(win).entrarApple({ rawNonce:'abc' }), resposta);
  }
  const esperado = createHash('sha256').update('abc').digest('hex');
  assert.deepEqual(pedidos, [
    { scopes:['EMAIL','FULL_NAME'], nonce:esperado },
    { scopes:['EMAIL','FULL_NAME'], nonce:esperado },
  ]);
});

test('entrarApple: desistência vira auth/user-cancelled sem registrar erro', async()=>{
  for(const code of ['SIGN_IN_CANCELED', '1001', 1001]){
    const { win, erros } = janelaNativa({ AppleSignIn:{ signIn:async()=>{ throw Object.assign(new Error('Sign in was canceled.'), { code }); } } });
    await assert.rejects(criar(win).entrarApple({ rawNonce:'n' }), { code:'auth/user-cancelled' });
    assert.deepEqual(erros, []);
  }
});

test('entrarApple: outra falha sobe e fica no diagnóstico', async()=>{
  const { win, erros } = janelaNativa({ AppleSignIn:{ signIn:async()=>{ throw Object.assign(new Error('falhou'), { code:'1000' }); } } });
  await assert.rejects(criar(win).entrarApple({ rawNonce:'n' }), { message:'falhou' });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-apple');
});

test('entrarGoogle e sairGoogle: fora do app devolvem null', async()=>{
  const n = criar({});
  assert.equal(await n.entrarGoogle({ clientId:'web' }), null);
  assert.equal(await n.sairGoogle(), null);
});

test('entrarGoogle: initialize com o client web uma vez só, depois signIn', async()=>{
  const chamadas = [];
  const resposta = { idToken:'id-google', email:'bia@gmail.com', displayName:'Bia Lima' };
  const { win } = janelaNativa({ GoogleSignIn:{
    initialize:async a=>{ chamadas.push(['initialize', a]); },
    signIn:async()=>{ chamadas.push(['signIn']); return resposta; } } });
  const n = criar(win);
  assert.deepEqual(await n.entrarGoogle({ clientId:'web-id' }), resposta);
  assert.deepEqual(await n.entrarGoogle({ clientId:'web-id' }), resposta);
  assert.deepEqual(chamadas, [['initialize', { clientId:'web-id' }], ['signIn'], ['signIn']]);
});

test('entrarGoogle: initialize que falha é tentado de novo no login seguinte', async()=>{
  let falhar = true;
  const chamadas = [];
  const { win, erros } = janelaNativa({ GoogleSignIn:{
    initialize:async()=>{ chamadas.push('initialize'); if(falhar) throw new Error('GIDClientID is missing from Info.plist.'); },
    signIn:async()=>{ chamadas.push('signIn'); return { idToken:'id' }; } } });
  const n = criar(win);
  await assert.rejects(n.entrarGoogle({ clientId:'web' }), { message:/GIDClientID/ });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-google');
  falhar = false;
  assert.deepEqual(await n.entrarGoogle({ clientId:'web' }), { idToken:'id' });
  assert.deepEqual(chamadas, ['initialize', 'initialize', 'signIn']);
});

test('entrarGoogle: desistência vira auth/user-cancelled sem registrar erro', async()=>{
  const { win, erros } = janelaNativa({ GoogleSignIn:{ initialize:async()=>{},
    signIn:async()=>{ throw Object.assign(new Error('The user canceled the sign-in flow.'), { code:'SIGN_IN_CANCELED' }); } } });
  await assert.rejects(criar(win).entrarGoogle({ clientId:'web' }), { code:'auth/user-cancelled' });
  assert.deepEqual(erros, []);
});

test('entrarGoogle: outra falha sobe e fica no diagnóstico', async()=>{
  const { win, erros } = janelaNativa({ GoogleSignIn:{ initialize:async()=>{},
    signIn:async()=>{ throw new Error('The Internet connection appears to be offline.'); } } });
  await assert.rejects(criar(win).entrarGoogle({ clientId:'web' }), { message:/offline/ });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-google');
});

test('sairGoogle: chama signOut no app e nunca propaga erro', async()=>{
  let saiu = 0;
  const { win } = janelaNativa({ GoogleSignIn:{ signOut:async()=>{ saiu++; } } });
  assert.equal(await criar(win).sairGoogle(), true);
  assert.equal(saiu, 1);
  const falha = janelaNativa({ GoogleSignIn:{ signOut:async()=>{ throw new Error('keychain'); } } });
  assert.equal(await criar(falha.win).sairGoogle(), null);
  assert.equal(falha.erros.length, 1);
  assert.equal(falha.erros[0][0], 'nativo-google');
});
