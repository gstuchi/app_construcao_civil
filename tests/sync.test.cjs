'use strict';
const assert = require('assert');
const C = require('../calc.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

/* Classificação de erro: decide se vale tentar de novo. Errar aqui pra mais
   (tratar terminal como transitório) faz o app martelar o servidor pra sempre;
   errar pra menos faz uma oscilação de rede virar erro na cara do usuário. */
t('erros de rede são transitórios — vale tentar de novo', () => {
  ['unavailable', 'deadline-exceeded', 'resource-exhausted', 'cancelled', 'internal', 'aborted']
    .forEach(code => assert.strictEqual(C.erroEhTerminal({ code }), false, code));
});

t('erros de permissão e de forma são terminais', () => {
  ['permission-denied', 'unauthenticated', 'invalid-argument', 'not-found', 'failed-precondition']
    .forEach(code => assert.strictEqual(C.erroEhTerminal({ code }), true, code));
});

t('erro sem code é transitório — falha de rede crua não traz code', () => {
  assert.strictEqual(C.erroEhTerminal(null), false);
  assert.strictEqual(C.erroEhTerminal({}), false);
  assert.strictEqual(C.erroEhTerminal(new Error('Failed to fetch')), false);
});

t('code vem com prefixo do Firestore em alguns caminhos', () => {
  assert.strictEqual(C.erroEhTerminal({ code: 'firestore/permission-denied' }), true);
  assert.strictEqual(C.erroEhTerminal({ code: 'PERMISSION_DENIED' }), true);
});

/* Backoff: 1s, 2s, 4s, 8s, 16s, teto 30s. Cresce pra não gastar bateria
   martelando o servidor com a rede fora. */
t('backoff dobra a cada tentativa', () => {
  assert.strictEqual(C.proximoBackoff(0), 1000);
  assert.strictEqual(C.proximoBackoff(1), 2000);
  assert.strictEqual(C.proximoBackoff(2), 4000);
  assert.strictEqual(C.proximoBackoff(3), 8000);
  assert.strictEqual(C.proximoBackoff(4), 16000);
});

t('backoff para de crescer em 30s', () => {
  assert.strictEqual(C.proximoBackoff(5), 30000);
  assert.strictEqual(C.proximoBackoff(9), 30000);
  assert.strictEqual(C.proximoBackoff(100), 30000);
});

t('backoff aceita entrada suja sem explodir', () => {
  assert.strictEqual(C.proximoBackoff(-3), 1000);
  assert.strictEqual(C.proximoBackoff(undefined), 1000);
  assert.strictEqual(C.proximoBackoff('2'), 4000);
});

console.log(`\n${n} testes passaram`);
