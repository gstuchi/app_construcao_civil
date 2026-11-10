'use strict';
/* Corte de gastos (corte/), a Blindagem 4: a regra é pura, o adaptador do Google roda sobre um
   cliente HTTP falso e os scripts sobre um gcloud falso no PATH. Nada aqui usa rede nem precisa
   do npm install de corte/ (index.js carrega as dependências só quando a função roda). */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const regra = require('../corte/regra.js');

const b64 = c => Buffer.from(typeof c === 'string' ? c : JSON.stringify(c)).toString('base64');
const eventoDe = corpo => ({ data: { message: { data: b64(corpo), attributes: { schemaVersion: '1.0' } } } });
const NOV = '2026-11-01T07:00:00Z';
const msgOrcamento = (custo, extra = {}) => ({
  budgetDisplayName: 'projeto', costAmount: custo, costIntervalStart: NOV,
  budgetAmount: 120, budgetAmountType: 'SPECIFIED_AMOUNT', currencyCode: 'BRL', ...extra,
});

test('regra: orçamento traz nome, custo, moeda e o mês do intervalo', ()=>{
  assert.deepEqual(regra.interpretar(eventoDe(msgOrcamento(61.5))),
    { tipo: 'orcamento', nome: 'projeto', custo: 61.5, moeda: 'BRL', intervalo: '2026-11' });
});

test('regra: o mês sai certo em qualquer fuso do início do período', ()=>{
  for(const inicio of ['2026-11-01T07:00:00Z', '2026-11-01T08:00:00Z', '2026-11-01T00:00:00Z', '2026-10-31T15:00:00Z'])
    assert.equal(regra.interpretar(eventoDe(msgOrcamento(1, { costIntervalStart: inicio }))).intervalo, '2026-11', inicio);
  assert.equal(regra.interpretar(eventoDe(msgOrcamento(1, { costIntervalStart: '2027-01-01T08:00:00Z' }))).intervalo, '2027-01');
});

test('regra: incidente traz a política e o estado', ()=>{
  assert.deepEqual(regra.interpretar(eventoDe({ version: '1.2', incident: { incident_id: 'x', policy_name: 'leituras', state: 'open' } })),
    { tipo: 'incidente', politica: 'leituras', estado: 'open' });
});

test('regra: mensagem ilegível lança MensagemIlegivel', ()=>{
  assert.equal(typeof regra.MensagemIlegivel, 'function');
  const ruins = [
    {},
    { data: {} },
    { data: { message: {} } },
    { data: { message: { data: '' } } },
    { data: { message: { data: 123 } } },
    eventoDe('isto não é json'),
    eventoDe([1, 2]),
    eventoDe({ qualquer: 'coisa' }),
    eventoDe(msgOrcamento('61')),
    eventoDe(msgOrcamento(NaN)),
    eventoDe(msgOrcamento(10, { costIntervalStart: 'ontem' })),
    eventoDe(msgOrcamento(10, { currencyCode: undefined })),
    eventoDe(msgOrcamento(10, { budgetDisplayName: 7 })),
    eventoDe({ version: '1.2', incident: { state: 'open' } }),
    eventoDe({ version: '1.2', incident: { policy_name: 'x' } }),
  ];
  for(const e of ruins) assert.throws(()=>regra.interpretar(e), regra.MensagemIlegivel, JSON.stringify(e));
});

test('regra: estadoNormal completa o que falta e o estado vazio não tem nada', ()=>{
  assert.deepEqual(regra.estadoNormal(null), { orcamentos: {}, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null });
  assert.deepEqual(regra.estadoNormal({ primeiraFalha: 'x' }).orcamentos, {});
  assert.equal(regra.estadoNormal({ primeiraFalha: 'x' }).primeiraFalha, 'x');
});

const msg = (custo, nome = 'projeto', intervalo = '2026-11') => ({ tipo: 'orcamento', nome, custo, moeda: 'BRL', intervalo });

test('regra: primeira mensagem do orçamento cria o registro do mês', ()=>{
  const r = regra.aplicarOrcamento(regra.estadoNormal(null), msg(61), 'projeto');
  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 61 });
  assert.equal(r.custoCentavos, 6100);
});

test('regra: custo desconta a base em centavos, sem erro de ponto flutuante', ()=>{
  const base = 4.07;
  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base, maiorCusto: base } } });
  assert.equal(64.07 - base < 60, true, 'o caso do teste precisa ser o que quebra na conta em reais');
  assert.equal(regra.aplicarOrcamento(estado, msg(base + 59), 'projeto').custoCentavos, 5900);
  assert.equal(regra.aplicarOrcamento(estado, msg(64.07), 'projeto').custoCentavos, 6000);
});

test('regra: fora de ordem não mexe no maiorCusto', ()=>{
  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base: 0, maiorCusto: 61 } } });
  const r = regra.aplicarOrcamento(estado, msg(40), 'projeto');
  assert.equal(r.estado, estado, 'sem mudança devolve o mesmo objeto: nada a regravar');
  assert.equal(r.custoCentavos, 4000);
});

test('regra: custo acima do maiorCusto sobe o maiorCusto e guarda a base', ()=>{
  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base: 10, maiorCusto: 61 } } });
  const r = regra.aplicarOrcamento(estado, msg(70), 'projeto');
  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 10, maiorCusto: 70 });
  assert.equal(r.custoCentavos, 6000);
});

test('regra: mês novo zera base e maiorCusto, sem tocar no outro orçamento', ()=>{
  const fora = { intervalo: '2026-10', base: 5, maiorCusto: 5 };
  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-10', base: 70, maiorCusto: 90 }, fora } });
  const r = regra.aplicarOrcamento(estado, msg(3), 'projeto');
  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 3 });
  assert.deepEqual(r.estado.orcamentos.fora, fora);
  assert.equal(r.custoCentavos, 300);
});

test('regra: mensagem do mês velho depois do mês novo é ignorada', ()=>{
  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-12', base: 0, maiorCusto: 2 } } });
  const r = regra.aplicarOrcamento(estado, msg(90, 'projeto', '2026-11'), 'projeto');
  assert.equal(r.velha, true);
  assert.equal(r.estado, estado);
});

test('regra: virar o mês do projeto zera a primeiraFalha; o outro orçamento não mexe nela', ()=>{
  const antes = { orcamentos: { projeto: { intervalo: '2026-10', base: 0, maiorCusto: 80 }, fora: { intervalo: '2026-10', base: 0, maiorCusto: 1 } }, primeiraFalha: '2026-10-31T20:00:00.000Z' };
  assert.equal(regra.aplicarOrcamento(regra.estadoNormal(antes), msg(1), 'projeto').estado.primeiraFalha, null);
  assert.equal(regra.aplicarOrcamento(regra.estadoNormal(antes), msg(1, 'fora'), 'fora').estado.primeiraFalha, antes.primeiraFalha);
  const semRegistro = regra.estadoNormal({ primeiraFalha: '2026-10-31T20:00:00.000Z' });
  assert.equal(regra.aplicarOrcamento(semRegistro, msg(1), 'projeto').estado.primeiraFalha, semRegistro.primeiraFalha, 'primeira mensagem do orçamento não é virada de mês');
});

test('regra: papel do orçamento pelo nome configurado', ()=>{
  const config = { orcamentoProjeto: 'projeto', orcamentoFora: 'fora' };
  assert.equal(regra.papelDoOrcamento('projeto', config), 'projeto');
  assert.equal(regra.papelDoOrcamento('fora', config), 'fora');
  assert.equal(regra.papelDoOrcamento('outro', config), null);
});

test('regra: limiares em centavos, por papel', ()=>{
  assert.equal(regra.decidirOrcamento('projeto', 5999), 'nada');
  assert.equal(regra.decidirOrcamento('projeto', 6000), 'desligar-api');
  assert.equal(regra.decidirOrcamento('projeto', 30000), 'desligar-api');
  assert.equal(regra.decidirOrcamento('fora', 9999), 'nada');
  assert.equal(regra.decidirOrcamento('fora', 10000), 'tirar-cobranca');
});

test('regra: cobrança só sai com custo de R$ 100 e falha de 6 horas', ()=>{
  const seis = 6 * 60 * 60 * 1000, t0 = Date.parse('2026-11-09T12:00:00.000Z'), falha = new Date(t0).toISOString();
  assert.equal(regra.deveTirarCobrancaPorFalha(10000, falha, t0 + seis), true);
  assert.equal(regra.deveTirarCobrancaPorFalha(10000, falha, t0 + seis - 1), false);
  assert.equal(regra.deveTirarCobrancaPorFalha(9999, falha, t0 + seis), false);
  assert.equal(regra.deveTirarCobrancaPorFalha(10000, null, t0 + seis), false);
});

test('regra: o que fica registrado do estado real', ()=>{
  const agora = '2026-11-09T12:00:00.000Z', depois = '2026-11-09T13:00:00.000Z';
  const base = regra.estadoNormal(null);
  const falhou = regra.registrarFalha(base, agora);
  assert.equal(falhou.primeiraFalha, agora);
  assert.equal(regra.registrarFalha(falhou, depois).primeiraFalha, agora, 'a primeira falha não anda');
  const desligada = regra.registrarApiDesligada(falhou, agora);
  assert.equal(desligada.apiDesligadaEm, agora);
  assert.equal(desligada.primeiraFalha, null, 'API confirmada desligada encerra a falha');
  assert.equal(regra.registrarApiDesligada(desligada, depois).apiDesligadaEm, agora, 'vale a primeira vez');
  assert.equal(regra.registrarCobrancaTirada(base, agora).cobrancaTiradaEm, agora);
});
