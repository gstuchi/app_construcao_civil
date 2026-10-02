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
  // números e datas do blob também: dados.js valida o tipo hoje, mas o escape não pode depender disso
  'Excluir parcela ${g.parcela.n}/${g.parcela.de}',
  'compra em ${g.parcela.de}x',
  'Parcela ${gasto.parcela.n}/${gasto.parcela.de}',
  "${String(o.areaM2).replace('.',',')}",
  '/${m.slice(2,4)}',
];

for(const trecho of perigos){
  assert.ok(!fonte.includes(trecho), `interpolação sem escape em innerHTML: ${trecho}`);
}

/* fmtData monta dd/mm/aa com pedaços crus da data e entra em vários templates. */
assert.match(fonte, /const fmtData = iso => \{[^\n]*return escapeHtml\(`/, 'fmtData precisa devolver o texto escapado');

/* Atributo cru é tão explorável quanto texto cru: a CSP (header na web, <meta> no app nativo)
   barra script inline, mas não barra HTML injetado (link, formulário, botão falso).
   Todo value="${...}" precisa passar por escapeHtml ou por um formatador que só devolve dígito. */
const seguro = v => v.includes('escapeHtml(')
  || v.includes('OBRA_CALC.numParaCampo(')
  || /^(todayISO\(\)|i\+1)$/.test(v);
const valores = [...fonte.matchAll(/value="\$\{([^}]*)\}"/g)].map(m => m[1].trim());
const crus = valores.filter(v => !seguro(v));
assert.deepStrictEqual(crus, [], `value="${'${...}'}" sem escape: ${crus.join(' | ')}`);

console.log('ok - dados persistidos não entram crus em innerHTML nem em atributo');
