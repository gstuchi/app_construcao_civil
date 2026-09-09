const { test } = require('node:test');
const assert = require('node:assert/strict');
const { hojeNoFuso } = require('../notificacoes/fuso.js');
test('data segue fuso do perfil e fuso inválido usa Brasília',()=>{
  const agora=new Date('2026-09-09T02:00:00Z');
  assert.equal(hojeNoFuso('Asia/Tokyo',agora),'2026-09-09');
  assert.equal(hojeNoFuso('America/Sao_Paulo',agora),'2026-09-08');
  assert.equal(hojeNoFuso('invalido',agora),'2026-09-08');
});
