const { test } = require('node:test');
const assert = require('node:assert/strict');
const { csv, json, exportar } = require('../share.js');
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
test('no nativo exporta pelo share sheet e não cai no download web', async()=>{
  const pedidos = [];
  const raiz = { OBRA_NATIVO:{ ehNativo:()=>true, compartilharArquivo:async a=>{ pedidos.push(a); return true; } } };
  await exportar(dados, 'csv', raiz);
  assert.equal(pedidos.length, 1);
  assert.match(pedidos[0].nome, /^custta-\d{4}-\d{2}-\d{2}\.csv$/);
  assert.equal(pedidos[0].tipo, 'text/csv;charset=utf-8');
  assert.equal(pedidos[0].titulo, 'Dados do Custta');
  assert.ok(pedidos[0].texto.includes('Mão de obra'));
});
