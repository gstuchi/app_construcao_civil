'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criar } = require('../nativo.js');

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
