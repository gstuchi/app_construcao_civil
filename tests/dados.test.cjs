const {test}=require('node:test');
const assert=require('node:assert/strict');
const {normaliza}=require('../dados.js');
test('documentos malformados não quebram listas, datas e cálculos',()=>{
  for(const entrada of [null,[],42,'x',{obras:{},config:[]}]) assert.deepEqual(normaliza(entrada).obras,[]);
  const d=normaliza({obras:[null,{}, {id:'o',dataInicio:'2026-09-09',nome:'Casa',fase:'vendida',gastos:[null,{id:'bad',data:'2026-02-30',valor:8},{id:'ok',data:'2026-09-09',valor:'12.5',grupoId:'g',parcela:null}]}]});
  assert.equal(d.obras.length,1);assert.equal(d.obras[0].fase,'construcao');
  assert.equal(d.obras[0].gastos.length,1);assert.equal(d.obras[0].gastos[0].valor,12.5);
  assert.equal(d.obras[0].gastos[0].grupoId,undefined);
});
test('versões futuras e textos antigos são preservados sem mutar entrada',()=>{
  const entrada={futuro:{a:1},config:{futura:true,taxaMensal:'2',topicosCustom:[{id:'c',nm:'x'.repeat(200),extra:3}]},obras:[{id:'o',nome:'x'.repeat(300),dataInicio:'2026-01-01',extra:7,gastos:[{id:'g',data:'2026-01-01',valor:1,extra:8}],afazeres:[{id:'a',texto:'X',feito:false,extra:9}]}]};
  const copia=structuredClone(entrada), d=normaliza(entrada);
  assert.deepEqual(entrada,copia);assert.deepEqual(d.futuro,{a:1});assert.equal(d.config.futura,true);
  assert.equal(d.config.taxaMensal,2);assert.equal(d.config.topicosCustom[0].extra,3);
  assert.equal(d.obras[0].nome.length,300);assert.equal(d.obras[0].extra,7);
  assert.equal(d.obras[0].gastos[0].extra,8);assert.equal(d.obras[0].afazeres[0].extra,9);
  assert.deepEqual(normaliza(d),d);
});
test('metadados de parcela são validados mesmo sem grupoId',()=>{
  const d=normaliza({obras:[{id:'o',dataInicio:'2026-01-01',gastos:[{id:'g',data:'2026-01-01',valor:1,parcela:{n:'<img src=x onerror=alert(1)>',de:2}}]}]});
  assert.equal(d.obras[0].gastos[0].parcela,undefined);
});
