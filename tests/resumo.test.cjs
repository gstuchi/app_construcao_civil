'use strict';
const assert = require('assert');
const { montaResumo } = require('../notificacoes/resumo.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

const obraCom = (extra) => ({ nome: 'Casa 1', fase: 'construcao', gastos: [], ...extra });

t('sem obras: null (nada a dizer, nem lembrete)', () => {
  assert.strictEqual(montaResumo({ obras: [] }, '2026-07-10'), null);
  assert.strictEqual(montaResumo(null, '2026-07-10'), null);
});

t('afazeres pendentes somam entre obras e plural correto', () => {
  const dados = { obras: [
    obraCom({ afazeres: [{ id:'a', texto:'x', feito:false }, { id:'b', texto:'y', feito:true }],
              gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }),
    obraCom({ afazeres: [{ id:'c', texto:'z', feito:false }] }),
  ]};
  const r = montaResumo(dados, '2026-07-10');
  assert.ok(r.corpo.includes('2 afazeres pendentes'), r.corpo);
  assert.strictEqual(r.titulo, 'Minhas Obras');
});

t('1 afazer pendente no singular', () => {
  const dados = { obras: [ obraCom({ afazeres: [{ id:'a', texto:'x', feito:false }],
    gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  const r = montaResumo(dados, '2026-07-10');
  assert.ok(r.corpo.includes('1 afazer pendente'), r.corpo);
  assert.ok(!r.corpo.includes('afazeres'), r.corpo);
});

t('obra antiga sem campo afazeres não quebra', () => {
  const dados = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  assert.strictEqual(montaResumo(dados, '2026-07-10'), null);
});

t('parcelas: só no dia 1, gastos do mês com data >= hoje', () => {
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-15' }, // parcela deste mês
    { id:'g2', valor: 500,  data: '2026-08-01' }, // hoje conta
    { id:'g3', valor: 900,  data: '2026-09-15' }, // mês que vem: fora
    { id:'g4', valor: 100,  data: '2026-07-20' }, // passado: fora
  ]}) ]};
  const r = montaResumo(dados, '2026-08-01');
  assert.ok(r.corpo.includes('2 parcelas vencem este mês (' + BRL.format(1500) + ')'), r.corpo);
});

t('parcelas não aparecem fora do dia 1', () => {
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-15' },
    { id:'g2', valor: 10,   data: '2026-08-02' }, // lançou hoje
  ]}) ]};
  const r = montaResumo(dados, '2026-08-02');
  assert.strictEqual(r, null);
});

t('parcela única no singular', () => {
  // gasto com data == hoje (dia 1): conta como parcela do mês E como "lançou hoje"
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000, data: '2026-08-01' },
  ]}) ]};
  const r = montaResumo(dados, '2026-08-01');
  assert.ok(r.corpo.includes('1 parcela vence este mês (' + BRL.format(1000) + ')'), r.corpo);
  assert.ok(!r.corpo.includes('parcelas'), r.corpo);
});

t('lembrete só quando nenhum gasto com data de hoje', () => {
  const sem = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-09' }] }) ]};
  const com = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-10' }] }) ]};
  assert.ok(montaResumo(sem, '2026-07-10').corpo.includes('Lançou os gastos de hoje?'));
  assert.strictEqual(montaResumo(com, '2026-07-10'), null);
});

t('lembrete só se existe obra em construção', () => {
  const dados = { obras: [ obraCom({ fase: 'vendida', gastos: [{ id:'g1', valor: 10, data: '2026-07-01' }] }) ]};
  assert.strictEqual(montaResumo(dados, '2026-07-10'), null);
});

t('linhas na ordem: afazeres, parcelas, lembrete', () => {
  const dados = { obras: [ obraCom({
    afazeres: [{ id:'a', texto:'x', feito:false }],
    gastos: [{ id:'g1', valor: 1000, data: '2026-08-15' }],
  }) ]};
  const r = montaResumo(dados, '2026-08-01');
  const linhas = r.corpo.split('\n');
  assert.strictEqual(linhas.length, 3);
  assert.ok(linhas[0].includes('afazer'));
  assert.ok(linhas[1].includes('parcela'));
  assert.ok(linhas[2].includes('Lançou'));
});

console.log(`\n${n} testes ok`);
