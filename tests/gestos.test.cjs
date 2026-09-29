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

test('sheet: com campo em foco, só puxa pela alça (32px de cima)', ()=>{
  assert.equal(G.podePuxarSheet({ scrollTop:0, focoEmCampo:false, yNoSheet:300 }), true);
  assert.equal(G.podePuxarSheet({ scrollTop:40, focoEmCampo:false, yNoSheet:10 }), false); // rolado: o sheet rola
  assert.equal(G.podePuxarSheet({ scrollTop:0, focoEmCampo:true, yNoSheet:300 }), false);  // digitando: não descarta o form
  assert.equal(G.podePuxarSheet({ scrollTop:0, focoEmCampo:true, yNoSheet:20 }), true);    // pela alça, pode
  assert.equal(G.podePuxarSheet({ scrollTop:0, focoEmCampo:true, yNoSheet:33 }), false);
});

test('sheet: bloqueia a rolagem nativa em puxão para baixo predominante, mesmo antes do eixo decidir', ()=>{
  assert.equal(G.bloqueiaPuxada(2, 6), true);   // 6px para baixo, quase reto: já dá pra saber
  assert.equal(G.bloqueiaPuxada(0, 1), true);   // 1px para baixo conta (decisão vale desde o início)
  assert.equal(G.bloqueiaPuxada(6, 2), false);  // horizontal predominante: não é puxão de sheet
  assert.equal(G.bloqueiaPuxada(2, -6), false); // para cima: o sheet rola, não puxa
  assert.equal(G.bloqueiaPuxada(0, 0), false);  // parado
});

test('borda: só com a tela livre por cima e o voltar à vista', ()=>{
  const livre = { sheetAberto:false, dialogoAberto:false, tecladoAberto:false, bloqueado:false, temVoltar:true, voltarCoberto:false };
  assert.equal(G.podeVoltarBorda(livre), true);
  assert.equal(G.podeVoltarBorda({ ...livre, tecladoAberto:true }), false); // teclado de valor por cima da obra
  assert.equal(G.podeVoltarBorda({ ...livre, sheetAberto:true }), false);
  assert.equal(G.podeVoltarBorda({ ...livre, dialogoAberto:true }), false);
  assert.equal(G.podeVoltarBorda({ ...livre, bloqueado:true }), false);     // tela de login
  assert.equal(G.podeVoltarBorda({ ...livre, temVoltar:false }), false);    // aba sem voltar
  assert.equal(G.podeVoltarBorda({ ...livre, voltarCoberto:true }), false); // qualquer overlay por cima do voltar
});

test('projeta: impulso vira distância (Apple, desaceleração 0,995 por ms)', ()=>{
  assert.equal(G.projeta(0), 0);
  assert.ok(Math.abs(G.projeta(1) - 199) < 0.5);    // 1px/ms ≈ 199px adiante
  assert.ok(Math.abs(G.projeta(-1) + 199) < 0.5);   // sinal preservado
  assert.ok(Math.abs(G.projeta(1, 0.99) - 99) < 0.5);
});

test('elástico: resiste cada vez mais e nunca passa da dimensão', ()=>{
  assert.equal(G.elastico(0, 100), 0);
  const a = G.elastico(50, 100), b = G.elastico(100, 100), c = G.elastico(1000, 100);
  assert.ok(a > 0 && a < 50);
  assert.ok(b > a && c > b && c < 100);
  assert.equal(G.elastico(-50, 100), -a);
});

test('sheet: o destino projetado decide, não só onde soltou', ()=>{
  assert.equal(G.fimArrastoSheet(200, -1.5), 'voltar'); // desceu muito mas jogou para cima
  assert.equal(G.fimArrastoSheet(40, 0.5), 'fechar');   // curto e rápido para baixo
  assert.equal(G.fimArrastoSheet(100, 0), 'voltar');
});

test('linha: arrasto longo devolvido para a direita fecha', ()=>{
  assert.equal(G.fimArrastoLinha(-100, 1), 'fechar');
  assert.equal(G.fimArrastoLinha(-10, -0.3), 'abrir');
});

test('borda: peteleco curto não volta, lento e longo sim', ()=>{
  assert.equal(G.fimArrastoBorda(30, 2, 390), 'cancelar'); // menos de 40px: toque acidental
  assert.equal(G.fimArrastoBorda(140, 0, 390), 'voltar');
  assert.equal(G.fimArrastoBorda(200, -1, 390), 'cancelar'); // arrastou e devolveu
});
