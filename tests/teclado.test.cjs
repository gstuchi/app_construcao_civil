'use strict';
const assert = require('assert');
const T = require('../teclado.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

/* atalho: digita uma sequência de teclas a partir do zero */
function digita(...teclas){
  return teclas.reduce((c, k) => T.aplicarTecla(c, k), 0);
}

t('dígitos entram pela direita, centavos primeiro', () => {
  assert.strictEqual(digita('1'), 1);
  assert.strictEqual(digita('1','2'), 12);
  assert.strictEqual(digita('1','2','5'), 125);
  assert.strictEqual(digita('1','2','5','0'), 1250);
});
t('zero à esquerda não acumula', () => {
  assert.strictEqual(digita('0'), 0);
  assert.strictEqual(digita('0','0','0'), 0);
  assert.strictEqual(digita('0','0','7'), 7);
});
t('tecla 00 empurra duas casas', () => {
  assert.strictEqual(digita('1','2','00'), 1200);
  assert.strictEqual(digita('1','00','00'), 10000);
  assert.strictEqual(digita('00'), 0);
});
t('del apaga o último dígito', () => {
  assert.strictEqual(T.aplicarTecla(1250, 'del'), 125);
  assert.strictEqual(T.aplicarTecla(125, 'del'), 12);
});
t('del em zero continua zero', () => {
  assert.strictEqual(T.aplicarTecla(0, 'del'), 0);
  assert.strictEqual(T.aplicarTecla(5, 'del'), 0);
});
t('teto: tecla que estouraria é ignorada', () => {
  const teto = 9999999999; // R$ 99.999.999,99
  assert.strictEqual(T.aplicarTecla(teto, '5'), teto);
  assert.strictEqual(T.aplicarTecla(999999999, '9'), teto);
  assert.strictEqual(T.aplicarTecla(999999999, '00'), 999999999);
});
t('tecla desconhecida não mexe no valor', () => {
  assert.strictEqual(T.aplicarTecla(1250, 'x'), 1250);
  assert.strictEqual(T.aplicarTecla(1250, ''), 1250);
});

t('fmtCentavos: sempre 2 casas e milhar com ponto', () => {
  assert.strictEqual(T.fmtCentavos(0), '0,00');
  assert.strictEqual(T.fmtCentavos(7), '0,07');
  assert.strictEqual(T.fmtCentavos(125), '1,25');
  assert.strictEqual(T.fmtCentavos(125000), '1.250,00');
  assert.strictEqual(T.fmtCentavos(123456789), '1.234.567,89');
});

t('reais <-> centavos: ida e volta sem perder centavo', () => {
  assert.strictEqual(T.reaisParaCentavos(1250.5), 125050);
  assert.strictEqual(T.reaisParaCentavos(0), 0);
  assert.strictEqual(T.reaisParaCentavos(null), 0);
  assert.strictEqual(T.centavosParaReais(125050), 1250.5);
  assert.strictEqual(T.centavosParaReais(7), 0.07);
});
t('reais -> centavos arredonda em vez de truncar', () => {
  // 8.7*100 = 869.9999... em ponto flutuante
  assert.strictEqual(T.reaisParaCentavos(8.7), 870);
  assert.strictEqual(T.reaisParaCentavos(1.005), 101);
});

console.log(`\n${n} testes passaram`);
