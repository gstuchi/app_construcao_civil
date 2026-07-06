'use strict';
const assert = require('assert');
const C = require('../calc.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

t('fmtDigitado: milhar ao vivo', () => {
  assert.strictEqual(C.fmtDigitado('2000000'), '2.000.000');
  assert.strictEqual(C.fmtDigitado('2'), '2');
  assert.strictEqual(C.fmtDigitado(''), '');
});
t('fmtDigitado: vírgula abre centavos (máx 2)', () => {
  assert.strictEqual(C.fmtDigitado('2500,5'), '2.500,5');
  assert.strictEqual(C.fmtDigitado('2500,567'), '2.500,56');
  assert.strictEqual(C.fmtDigitado(','), '0,');
});
t('fmtDigitado: lixo colado é limpo', () => {
  assert.strictEqual(C.fmtDigitado('R$ 1.2a3,4,5'), '123,45');
  assert.strictEqual(C.fmtDigitado('007'), '7');
});
t('fmtCompleto: completa ,00', () => {
  assert.strictEqual(C.fmtCompleto('2.000.000'), '2.000.000,00');
  assert.strictEqual(C.fmtCompleto('2500,5'), '2.500,50');
  assert.strictEqual(C.fmtCompleto(''), '');
});
t('numParaCampo', () => {
  assert.strictEqual(C.numParaCampo(2000000), '2.000.000,00');
  assert.strictEqual(C.numParaCampo(1234.5), '1.234,50');
  assert.strictEqual(C.numParaCampo(null), '');
});
t('parseNum: ida e volta com a máscara', () => {
  assert.strictEqual(C.parseNum('2.000.000,00'), 2000000);
  assert.strictEqual(C.parseNum('2.000.000'), 2000000); // sem blur (simulador ao vivo)
  assert.strictEqual(C.parseNum('2.500,50'), 2500.5);
});
t('parseNum: taxa com ponto decimal continua funcionando', () => {
  assert.strictEqual(C.parseNum('1.5'), 1.5);   // #ajTaxa digitado com ponto
  assert.strictEqual(C.parseNum('1,5'), 1.5);
  assert.strictEqual(C.parseNum(''), 0);
  assert.strictEqual(C.parseNum(7), 7);
});

console.log(`\n${n} testes passaram ✔`);
