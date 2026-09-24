'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

test('app.js e auth.js não usam confirm/alert nativos (somem no WKWebView)', ()=>{
  for(const nome of ['app.js', 'auth.js']){
    const fonte = readFileSync(join(__dirname, '..', nome), 'utf8').replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '');
    assert.doesNotMatch(fonte, /(^|[^.\w])(confirm|alert)\s*\(/m, nome);
  }
});

test('conta só Google: sem trocar senha e apagar sem campo de senha', ()=>{
  const app = readFileSync(join(__dirname, '..', 'app.js'), 'utf8');
  assert.match(app, /\$\('#ajSenha'\)\.classList\.toggle\('hidden', conta\?\.temSenha === false\)/);
  const ui = readFileSync(join(__dirname, '..', 'ui-confirm.js'), 'utf8');
  assert.match(ui, /temSenha === false/);
  assert.match(ui, /auth\/popup-blocked/);
  assert.match(ui, /auth\/user-mismatch/);
});
