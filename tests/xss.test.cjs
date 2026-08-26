'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const fonte = readFileSync(join(__dirname, '..', 'app.js'), 'utf8');

const perigos = [
  '${ICON(t.ic)} ${t.nm}',
  '${pIc}${t.nm}',
  '<option value="${o.id}">',
];

for(const trecho of perigos){
  assert.ok(!fonte.includes(trecho), `interpolação sem escape em innerHTML: ${trecho}`);
}

console.log('ok - dados persistidos não entram crus em innerHTML');
