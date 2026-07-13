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

t('resumoVenda: exemplo canônico (3mi/2mi em 24 meses)', () => {
  const r = C.resumoVenda(3000000, 2000000, 24);
  assert.strictEqual(r.lucro, 1000000);
  perto(r.pctCusto, 50, 0.001);
  perto(r.pctVenda, 33.333, 0.001);
  perto(r.taxaMes, 1.7037, 0.001); // 1.5^(1/24)-1
});

t('resumoVenda: prejuízo fica negativo', () => {
  const r = C.resumoVenda(1500000, 2000000, 12);
  assert.strictEqual(r.lucro, -500000);
  assert.ok(r.pctCusto < 0 && r.pctVenda < 0 && r.taxaMes < 0);
});

t('resumoVenda: base inválida vira null', () => {
  const z = C.resumoVenda(0, 2000000, 12);
  assert.deepStrictEqual(z, { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null });
  const c = C.resumoVenda(3000000, 0, 12);
  assert.deepStrictEqual(c, { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null });
  assert.strictEqual(C.resumoVenda(3000000, 2000000, 0).taxaMes, null);
});

const obraEvo = {
  dataInicio: '2026-01-10',
  gastos: [
    { valor: 100000, data: '2026-01-15', topico: 'terreno',  descricao: 'Sinal do terreno' },
    { valor:  50000, data: '2026-03-10', topico: 'pintura',  descricao: 'Tinta acrílica' },
  ],
};

t('serieEvolucao: um ponto por mês, acumulado certo', () => {
  const s = C.serieEvolucao(obraEvo, 1, '2026-04-20');
  assert.deepStrictEqual(s.map(p => p.mes), ['2026-01', '2026-02', '2026-03', '2026-04']);
  assert.strictEqual(s[0].bruto, 100000);
  assert.strictEqual(s[1].bruto, 100000);          // fev sem gasto repete
  assert.strictEqual(s[2].bruto, 150000);
  assert.ok(s[1].corrigido > s[0].corrigido);      // corrigido segue rendendo
  s.forEach(p => assert.ok(p.corrigido >= p.bruto));
});

t('serieEvolucao: vendida congela no mês da venda', () => {
  const vend = { ...obraEvo, venda: { data: '2026-03-20', valor: 1 } };
  const s = C.serieEvolucao(vend, 1, '2026-12-25');
  assert.strictEqual(s[s.length - 1].mes, '2026-03');
});

t('serieEvolucao: sem gastos = vazio; janela máx 24 meses', () => {
  assert.deepStrictEqual(C.serieEvolucao({ dataInicio: '2026-01-01', gastos: [] }, 1, '2026-06-01'), []);
  const antiga = { dataInicio: '2020-01-01', gastos: [{ valor: 1000, data: '2020-01-05' }] };
  const s = C.serieEvolucao(antiga, 1, '2026-07-06');
  assert.strictEqual(s.length, 24);
  assert.strictEqual(s[s.length - 1].mes, '2026-07');
});

t('serieMensal: soma por mês e zera meses vazios', () => {
  const s = C.serieMensal([
    { valor: 1000, data: '2026-01-10' },
    { valor: 500,  data: '2026-01-20' },
    { valor: 2000, data: '2026-03-05' },
  ]);
  assert.deepStrictEqual(s, [
    { mes: '2026-01', total: 1500 },
    { mes: '2026-02', total: 0 },
    { mes: '2026-03', total: 2000 },
  ]);
});

t('serieMensal: um gasto só, vazio e virada de ano', () => {
  assert.deepStrictEqual(C.serieMensal([{ valor: 750, data: '2026-06-05' }]),
    [{ mes: '2026-06', total: 750 }]);
  assert.deepStrictEqual(C.serieMensal([]), []);
  const s = C.serieMensal([{ valor: 100, data: '2025-12-20' }, { valor: 300, data: '2026-02-01' }]);
  assert.deepStrictEqual(s.map(p => p.mes), ['2025-12', '2026-01', '2026-02']);
  assert.deepStrictEqual(s.map(p => p.total), [100, 0, 300]);
});

t('serieMensal: janela máx 24 meses, fica com os últimos', () => {
  const s = C.serieMensal([{ valor: 100, data: '2020-01-05' }, { valor: 200, data: '2026-07-10' }]);
  assert.strictEqual(s.length, 24);
  assert.strictEqual(s[s.length - 1].mes, '2026-07');
  assert.strictEqual(s[s.length - 1].total, 200);
});

const mapaTop = { terreno: { nm: 'Terreno' }, pintura: { nm: 'Pintura' } };

t('filtraGastos: texto acha descrição e tópico, sem acento', () => {
  const g = obraEvo.gastos;
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: 'tinta' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: 'PINTURA' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: 'acrilica' }).length, 1); // sem acento
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: 'piscina' }).length, 0);
});

t('filtraGastos: mês, combinado e vazio', () => {
  const g = obraEvo.gastos;
  assert.strictEqual(C.filtraGastos(g, mapaTop, { mes: '2026-01' }).length, 1);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: 'terreno', mes: '2026-03' }).length, 0);
  assert.strictEqual(C.filtraGastos(g, mapaTop, {}).length, 2);
  assert.strictEqual(C.filtraGastos(g, mapaTop, { texto: '' }).length, 2);
});

const obrasAgg = [
  { dataInicio:'2026-01-10', gastos:[{ valor:100000, data:'2026-01-15', topico:'terreno' }] },
  { dataInicio:'2026-02-01', venda:{ data:'2026-03-10', valor:1 },
    gastos:[{ valor:50000, data:'2026-02-05', topico:'pintura' }] },
];

t('serieEvolucaoAgregada: união de meses e soma', () => {
  const s = C.serieEvolucaoAgregada(obrasAgg, 1, '2026-04-20');
  assert.deepStrictEqual(s.map(p=>p.mes), ['2026-01','2026-02','2026-03','2026-04']);
  assert.strictEqual(s[0].bruto, 100000);
  assert.strictEqual(s[1].bruto, 150000);
  assert.ok(s[3].corrigido > s[3].bruto);
  // obra 2 vendida em mar: corrigido dela congela, mas o da obra 1 segue subindo
  assert.ok(s[3].corrigido > s[2].corrigido);
});

t('aPagar: janela de 30 dias', () => {
  const os = [{ dataInicio:'2026-07-01', gastos:[
    { valor:100, data:'2026-07-10' },  // +4d: dentro
    { valor:200, data:'2026-08-04' },  // +29d: dentro
    { valor:400, data:'2026-08-10' },  // +35d: fora
    { valor:800, data:'2026-07-01' },  // passado: fora
  ]}];
  assert.deepStrictEqual(C.aPagar(os, '2026-07-06'), { total:300, qtd:2 });
});

t('gastosRecentes: ordena e limita', () => {
  const os = [
    { id:'a', nome:'A', dataInicio:'2026-01-01', gastos:[{ id:'g1', valor:1, data:'2026-01-02' },{ id:'g3', valor:3, data:'2026-03-01' }] },
    { id:'b', nome:'B', dataInicio:'2026-01-01', gastos:[{ id:'g2', valor:2, data:'2026-02-01' }] },
  ];
  const r = C.gastosRecentes(os, 2);
  assert.deepStrictEqual(r.map(x=>x.gasto.id), ['g3','g2']);
  assert.strictEqual(r[0].obraNome, 'A');
});

t('precoPorM2', () => {
  assert.strictEqual(C.precoPorM2(3000000, 300), 10000);
  assert.strictEqual(C.precoPorM2(3000000, 0), null);
  assert.strictEqual(C.precoPorM2(3000000, null), null);
  assert.strictEqual(C.precoPorM2(0, 300), null);
});

console.log(`OK: ${n} testes`);
