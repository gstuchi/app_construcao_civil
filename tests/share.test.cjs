const { test } = require('node:test');
const assert = require('node:assert/strict');
const { csv, json } = require('../share.js');
const dados = { obras:[{ nome:'Casa; "A"', fase:'construcao', gastos:[{
  descricao:' =HYPERLINK("https://exemplo.com")', valor:1234.56, data:'2026-09-09',
  topico:'custom', parcela:{ n:2, de:3 }
}] }], config:{ topicosCustom:[{ id:'custom', nm:'Mão de obra' }] } };
test('JSON preserva estado completo sem alterar origem', ()=>{
  const antes = JSON.stringify(dados), copia = JSON.parse(json(dados));
  assert.deepEqual(copia.dados, dados); assert.equal(copia.versao, 1);
  assert.equal(JSON.stringify(dados), antes);
});
test('CSV preserva aspas, acentos, centavos e neutraliza fórmulas', ()=>{
  const texto = csv(dados);
  assert.ok(texto.startsWith('\uFEFF'));
  assert.ok(texto.includes('"Casa; ""A"""'));
  assert.ok(texto.includes('"\' =HYPERLINK'));
  assert.ok(texto.includes('"Mão de obra"'));
  assert.ok(texto.includes('"1234,56";"2";"3"'));
  assert.equal(csv({obras:[]}).split('\r\n').length, 2);
});
