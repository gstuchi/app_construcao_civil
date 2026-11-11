'use strict';
/* O filtro das violações de CSP que não são do app (tests/browser/csp-terceiros.cjs), no
   formato que as suítes registram: "diretiva: endereço barrado". */
const test = require('node:test');
const assert = require('node:assert/strict');
const { violacoesDoApp } = require('./browser/csp-terceiros.cjs');

test('o ping de telemetria do gapi não conta, com ou sem consulta', () => {
  assert.deepEqual(violacoesDoApp([
    'connect-src: https://apis.google.com/js/gen_204?c=50%3A1',
    'connect-src: https://apis.google.com/js/gen_204',
  ]), []);
});

test('qualquer outra violação continua contando, mesmo parecida com o ping', () => {
  const outras = [
    'connect-src: https://apis.google.com/js/api.js',
    'connect-src: https://apis.google.com/js/gen_2040',
    'connect-src: https://apis.google.com/js/gen_204/x',
    'connect-src: https://apis.google.com.exemplo.net/js/gen_204',
    'connect-src: https://apisxgoogle.com/js/gen_204',
    'connect-src: https://apis.googlexcom/js/gen_204',
    'connect-src: http://apis.google.com/js/gen_204',
    'img-src: https://exemplo.net/?u=connect-src: https://apis.google.com/js/gen_204',
    'img-src: https://apis.google.com/js/gen_204?c=1',
    'script-src-elem: https://apis.google.com/js/gen_204',
    'img-src: https://www.google.com/images/cleardot.gif?zx=1',
    'style-src-attr: inline',
  ];
  assert.deepEqual(violacoesDoApp(outras), outras);
});

test('numa lista misturada sai só o ping, e o resto fica na ordem', () => {
  assert.deepEqual(violacoesDoApp([
    'style-src-attr: inline',
    'connect-src: https://apis.google.com/js/gen_204?c=50%3A1',
    'connect-src: https://exemplo.net/',
  ]), ['style-src-attr: inline', 'connect-src: https://exemplo.net/']);
});
