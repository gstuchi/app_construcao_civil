'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const G = require('../gestos.js');

test('eixo: só decide depois de 10px e exige predominância horizontal', ()=>{
  assert.equal(G.eixo(5, 3), null);
  assert.equal(G.eixo(-30, 5), 'h');
  assert.equal(G.eixo(12, 11), 'v'); // diagonal fica com a rolagem
  assert.equal(G.eixo(2, 40), 'v');
});

test('linha: abre além da metade do botão ou com rapidez para a esquerda', ()=>{
  assert.equal(G.fimArrastoLinha(-50, 0), 'abrir');
  assert.equal(G.fimArrastoLinha(-30, 0), 'fechar');
  assert.equal(G.fimArrastoLinha(-15, -0.8), 'abrir');
  assert.equal(G.fimArrastoLinha(-70, 0.8), 'fechar');
});

test('sheet: fecha passando de 120px ou puxão rápido', ()=>{
  assert.equal(G.fimArrastoSheet(130, 0), 'fechar');
  assert.equal(G.fimArrastoSheet(60, 1.2), 'fechar');
  assert.equal(G.fimArrastoSheet(60, 0.2), 'voltar');
  assert.equal(G.fimArrastoSheet(20, 2), 'voltar'); // tremida curta não fecha
});

test('borda: volta além de 35% da largura ou com rapidez', ()=>{
  assert.equal(G.fimArrastoBorda(150, 0, 390), 'voltar');
  assert.equal(G.fimArrastoBorda(100, 0, 390), 'cancelar');
  assert.equal(G.fimArrastoBorda(60, 0.7, 390), 'voltar');
});

test('borda só no app nativo ou no PWA instalado, e só nos primeiros 24px', ()=>{
  const cl = (...c) => ({ contains: x => c.includes(x) });
  assert.equal(G.bordaAtiva(10, cl('nativo')), true);
  assert.equal(G.bordaAtiva(10, cl('standalone')), true);
  assert.equal(G.bordaAtiva(10, cl()), false);   // Safari comum: a borda é do navegador
  assert.equal(G.bordaAtiva(30, cl('nativo')), false);
});
