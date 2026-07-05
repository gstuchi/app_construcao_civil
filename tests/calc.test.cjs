'use strict';
const assert = require('assert');
const C = require('../calc.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }
const perto = (a, b, tol) => assert.ok(Math.abs(a - b) <= tol, `esperado ~${b}, veio ${a}`);

t('diasEntre básico', () => {
  assert.strictEqual(C.diasEntre('2026-07-04', '2026-07-04'), 0);
  assert.strictEqual(C.diasEntre('2026-07-04', '2026-07-05'), 1);
  assert.strictEqual(C.diasEntre('2026-07-05', '2026-07-04'), 0); // nunca negativo
});

t('corrigido: mesmo dia = valor bruto', () => {
  assert.strictEqual(C.corrigido(10000, '2026-07-04', '2026-07-04', 1), 10000);
});

t('corrigido: taxa zero = valor bruto', () => {
  assert.strictEqual(C.corrigido(10000, '2026-07-04', '2027-07-04', 0), 10000);
});

t('corrigido: 30 dias a 1% ≈ +0,986%', () => {
  // 1.01^(30/30.44) = 1.0098551
  perto(C.corrigido(10000, '2026-07-04', '2026-08-03', 1), 10098.55, 0.05);
});

t('corrigido: exemplo canônico da spec (~6 meses)', () => {
  // 04/07/2026 → 04/01/2027 = 184 dias = 6.0447 meses → 1.01^6.0447
  perto(C.corrigido(10000, '2026-07-04', '2027-01-04', 1), 10619.93, 0.5);
});

t('corrigido cresce com o tempo', () => {
  const a = C.corrigido(5000, '2026-01-01', '2026-06-01', 1);
  const b = C.corrigido(5000, '2026-01-01', '2026-12-01', 1);
  assert.ok(b > a && a > 5000);
});

const obraAberta = {
  dataInicio: '2026-01-01',
  gastos: [
    { valor: 100000, data: '2026-01-01' },
    { valor:  50000, data: '2026-06-01' },
  ],
};

t('totalBruto soma gastos', () => {
  assert.strictEqual(C.totalBruto(obraAberta), 150000);
});

t('totalCorrigido > totalBruto quando há tempo passado', () => {
  const tc = C.totalCorrigido(obraAberta, 1, '2026-07-04');
  assert.ok(tc > 150000);
});

t('totalCorrigido congela na venda', () => {
  const vendida = { ...obraAberta, venda: { data: '2026-07-01', valor: 300000 } };
  const noDiaDaVenda = C.totalCorrigido(vendida, 1, '2026-07-01');
  const muitoDepois  = C.totalCorrigido(vendida, 1, '2027-07-01'); // hoje não importa
  perto(muitoDepois, noDiaDaVenda, 0.001);
});

t('lucroVenda: null sem venda, bruto e vsBanco com venda', () => {
  assert.strictEqual(C.lucroVenda(obraAberta, 1), null);
  const vendida = { ...obraAberta, venda: { data: '2026-07-01', valor: 300000 } };
  const l = C.lucroVenda(vendida, 1);
  assert.strictEqual(l.bruto, 150000);
  assert.ok(l.vsBanco < l.bruto && l.vsBanco > 0);
});

t('mesesDeObra usa venda como fim quando vendida', () => {
  perto(C.mesesDeObra(obraAberta, '2026-07-04'), 184 / 30.44, 0.01);
  const vendida = { ...obraAberta, venda: { data: '2026-04-01', valor: 1 } };
  perto(C.mesesDeObra(vendida, '2027-01-01'), 90 / 30.44, 0.01);
});

t('taxaEquivalenteMensal: dobrar em 24 meses ≈ 2,93% a.m.', () => {
  perto(C.taxaEquivalenteMensal(2000000, 1000000, 24), 2.9302, 0.001);
});

t('taxaEquivalenteMensal: sem lucro = 0%', () => {
  perto(C.taxaEquivalenteMensal(1000, 1000, 12), 0, 1e-9);
});

t('taxaEquivalenteMensal: entradas inválidas viram null', () => {
  assert.strictEqual(C.taxaEquivalenteMensal(0, 1000, 12), null);
  assert.strictEqual(C.taxaEquivalenteMensal(1000, 0, 12), null);
  assert.strictEqual(C.taxaEquivalenteMensal(1000, 1000, 0), null);
});

t('addMesesClampado: mês normal e clamp no fim do mês', () => {
  assert.strictEqual(C.addMesesClampado('2026-07-17', 0), '2026-07-17');
  assert.strictEqual(C.addMesesClampado('2026-07-17', 1), '2026-08-17');
  assert.strictEqual(C.addMesesClampado('2026-07-17', 6), '2027-01-17'); // vira o ano
  assert.strictEqual(C.addMesesClampado('2026-01-31', 1), '2026-02-28'); // fev clampa
  assert.strictEqual(C.addMesesClampado('2028-01-31', 1), '2028-02-29'); // bissexto
  assert.strictEqual(C.addMesesClampado('2026-08-31', 1), '2026-09-30'); // 31 → 30
});

t('gerarParcelas: 10.000 em 10x = 10 de 1.000, dia 17 todo mês', () => {
  const ps = C.gerarParcelas(10000, 10, '2026-07-17');
  assert.strictEqual(ps.length, 10);
  ps.forEach(p => assert.strictEqual(p.valor, 1000));
  assert.strictEqual(ps[0].data, '2026-07-17');
  assert.strictEqual(ps[1].data, '2026-08-17');
  assert.strictEqual(ps[9].data, '2027-04-17');
});

t('gerarParcelas: centavos de arredondamento vão na última', () => {
  const ps = C.gerarParcelas(1000, 3, '2026-07-05');
  assert.strictEqual(ps[0].valor, 333.33);
  assert.strictEqual(ps[1].valor, 333.33);
  assert.strictEqual(ps[2].valor, 333.34);
  const soma = ps.reduce((s, p) => s + p.valor, 0);
  perto(soma, 1000, 1e-9);
});

t('gerarParcelas: 1x = um item com o total na data', () => {
  const ps = C.gerarParcelas(500.5, 1, '2026-07-05');
  assert.deepStrictEqual(ps, [{ valor: 500.5, data: '2026-07-05' }]);
});

console.log(`OK: ${n} testes`);
