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
