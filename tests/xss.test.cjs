'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const fonte = readFileSync(join(__dirname, '..', 'app.js'), 'utf8');

const perigos = [
  '${ICON(t.ic)} ${t.nm}',
  '${pIc}${t.nm}',
  '<option value="${o.id}">',
  // campo persistido dentro de atributo: fecha as aspas e injeta onfocus=
  'value="${o.dataInicio}"',
  "value=\"${o.areaM2||''}\"",
  'value="${isEdit?gasto.data:todayISO()}"',
  '<option value="${m}"',
];

for(const trecho of perigos){
  assert.ok(!fonte.includes(trecho), `interpolação sem escape em innerHTML: ${trecho}`);
}

/* Atributo cru é tão explorável quanto texto cru — e no app nativo não há CSP pra segurar.
   Todo value="${...}" precisa passar por escapeHtml ou por um formatador que só devolve dígito. */
const seguro = v => v.includes('escapeHtml(')
  || v.includes('OBRA_CALC.numParaCampo(')
  || /^(todayISO\(\)|i\+1)$/.test(v);
const valores = [...fonte.matchAll(/value="\$\{([^}]*)\}"/g)].map(m => m[1].trim());
const crus = valores.filter(v => !seguro(v));
assert.deepStrictEqual(crus, [], `value="${'${...}'}" sem escape: ${crus.join(' | ')}`);

console.log('ok - dados persistidos não entram crus em innerHTML nem em atributo');
