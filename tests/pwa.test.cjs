'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const sw = readFileSync(join(raiz, 'sw.js'), 'utf8');
const manifest = JSON.parse(readFileSync(join(raiz, 'manifest.json'), 'utf8'));

for(const icon of manifest.icons || []){
  assert.ok(sw.includes(`'./${icon.src}'`), `ícone do manifesto fora do precache: ${icon.src}`);
}
assert.ok(/if\s*\(\s*!res\.ok\s*\)\s*return res/.test(sw), 'service worker pode substituir cache bom por resposta 4xx/5xx');

console.log('ok - precache contém ícones e ignora respostas HTTP com erro');
