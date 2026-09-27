'use strict';
const assert = require('assert');
const { montaResumo, endpointPushValido, estadoOrcamento, avisosOrcamento } = require('../notificacoes/resumo.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

const obraCom = (extra) => ({ nome: 'Casa 1', fase: 'construcao', gastos: [], ...extra });

t('endpoint push aceita provedores conhecidos e bloqueia SSRF', () => {
  assert.strictEqual(endpointPushValido('https://fcm.googleapis.com/fcm/send/abc'), true);
  assert.strictEqual(endpointPushValido('https://updates.push.services.mozilla.com/wpush/v2/abc'), true);
  assert.strictEqual(endpointPushValido('https://web.push.apple.com/QP/abc'), true);
  assert.strictEqual(endpointPushValido('http://fcm.googleapis.com/fcm/send/abc'), false);
  assert.strictEqual(endpointPushValido('https://127.0.0.1/admin'), false);
  assert.strictEqual(endpointPushValido('https://metadata.google.internal/'), false);
  assert.strictEqual(endpointPushValido('não é url'), false);
});

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
  assert.strictEqual(r.titulo, 'Custta');
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

t('dados malformados de um usuário não derrubam o cron', () => {
  const dados = { obras: [
    obraCom({ afazeres: { corrompido: true }, gastos: [{ valor: 10 }] }),
    null,
  ]};
  assert.doesNotThrow(() => montaResumo(dados, '2026-08-01'));
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

t('valor não numérico não vira NaN no total', () => {
  const dados = { obras: [ obraCom({ gastos: [
    { id:'g1', valor: 1000,  data: '2026-08-15' },
    { id:'g2', valor: null,  data: '2026-08-20' },
  ]}) ]};
  const r = montaResumo(dados, '2026-08-01');
  assert.ok(r.corpo.includes(BRL.format(1000)), r.corpo);
  assert.ok(!r.corpo.includes('NaN'), r.corpo);
});

t('manhã não cobra lançamento (o dia ainda não aconteceu)', () => {
  const dados = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-09' }] }) ]};
  assert.ok(montaResumo(dados, '2026-07-10', 'noite').corpo.includes('Lançou os gastos de hoje?'));
  assert.strictEqual(montaResumo(dados, '2026-07-10', 'manha'), null);
});

t('manhã mantém afazeres e parcelas', () => {
  const dados = { obras: [ obraCom({
    afazeres: [{ id:'a', texto:'x', feito:false }],
    gastos: [{ id:'g1', valor: 1000, data: '2026-08-15' }],
  }) ]};
  const r = montaResumo(dados, '2026-08-01', 'manha');
  const linhas = r.corpo.split('\n');
  assert.strictEqual(linhas.length, 2, r.corpo);
  assert.ok(linhas[0].includes('afazer'));
  assert.ok(linhas[1].includes('parcela'));
});

t('período ausente ou desconhecido se comporta como noite', () => {
  const dados = { obras: [ obraCom({ gastos: [{ id:'g1', valor: 10, data: '2026-07-09' }] }) ]};
  for(const p of [undefined, null, '', 'tarde', 'MANHA']){
    assert.ok(montaResumo(dados, '2026-07-10', p).corpo.includes('Lançou'), String(p));
  }
});

t('obraId só quando exatamente uma obra gera o resumo', () => {
  const uma = { obras: [ { id:'o1', nome:'A', fase:'construcao', gastos: [] }, { id:'o2', nome:'B', fase:'vendida', gastos: [] } ] };
  assert.strictEqual(montaResumo(uma, '2026-07-10', 'noite').obraId, 'o1');
  const duas = { obras: [ { id:'o1', fase:'construcao', gastos: [] }, { id:'o2', fase:'construcao', gastos: [] } ] };
  assert.strictEqual('obraId' in montaResumo(duas, '2026-07-10', 'noite'), false);
  const afazer = { obras: [ { id:'o1', fase:'pronta', afazeres:[{ feito:false }], gastos: [] }, { id:'o2', fase:'pronta', gastos: [] } ] };
  assert.strictEqual(montaResumo(afazer, '2026-07-10', 'manha').obraId, 'o1');
});

const obraOrc = (id, nome, orcamento, gastos, extra) => ({ id, nome, fase:'construcao', dataInicio:'2026-01-01',
  orcamento, gastos: gastos.map(([topico, valor], i) => ({ id:id + i, topico, valor, data:'2026-07-10' })), ...extra });
const CASA = obraOrc('o1', 'Casa Alphaville', { modo:'topicos', topicos:{ fundacao:90000, estrutura:250000 } },
  [['fundacao', 98000], ['estrutura', 231000]]);

t('estadoOrcamento: só itens a partir de perto', () => {
  assert.deepStrictEqual(estadoOrcamento({ obras:[CASA] }),
    { 'o1|total':'perto', 'o1|t:fundacao':'passou', 'o1|t:estrutura':'perto' });
  assert.deepStrictEqual(estadoOrcamento({ obras:[] }), {});
  assert.deepStrictEqual(estadoOrcamento(null), {});
});

t('sem memória (anterior ausente ou null): nenhum aviso de orçamento', () => {
  assert.deepStrictEqual(avisosOrcamento({ obras:[CASA] }, null), { linhas:[], obraIds:[] });
  assert.strictEqual(montaResumo({ obras:[CASA] }, '2026-07-10', 'noite'), null);
});

t('primeira vez: frases de tópico e de total, passou antes de perto', () => {
  const r = avisosOrcamento({ obras:[CASA] }, {});
  assert.deepStrictEqual(r.linhas, [
    'Fundação passou R$ 8 mil do previsto',
    'Casa Alphaville chegou a 97% do orçamento',
    'Estrutura chegou a 92% do previsto',
  ]);
  assert.deepStrictEqual(r.obraIds, ['o1']);
});

t('mesmo nível: silêncio; subida perto → passou: avisa de novo', () => {
  const estado = estadoOrcamento({ obras:[CASA] });
  assert.deepStrictEqual(avisosOrcamento({ obras:[CASA] }, estado).linhas, []);
  const estourou = obraOrc('o1', 'Casa Alphaville', CASA.orcamento, [['fundacao', 98000], ['estrutura', 260000]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[estourou] }, estado).linhas,
    ['Casa Alphaville passou R$ 18 mil do orçamento', 'Estrutura passou R$ 10 mil do previsto']);
});

t('descida esquece: depois de baixar, nova subida avisa', () => {
  const folgada = obraOrc('o1', 'Casa Alphaville', { modo:'topicos', topicos:{ fundacao:200000, estrutura:250000 } },
    [['fundacao', 98000], ['estrutura', 100000]]);
  const estado = estadoOrcamento({ obras:[folgada] });
  assert.deepStrictEqual(estado, {});
  assert.strictEqual(avisosOrcamento({ obras:[CASA] }, estado).linhas.length, 3);
});

t('memória com lixo não quebra nem silencia', () => {
  const r = avisosOrcamento({ obras:[CASA] }, { 'o1|t:fundacao':'constructor', 'o1|total':42 });
  assert.strictEqual(r.linhas.length, 3);
});

t('obra vendida não avisa; várias obras ganham o nome entre parênteses', () => {
  const vendida = obraOrc('v', 'Vendida', { modo:'total', total:10 }, [['terreno', 100]], { fase:'vendida', venda:{ valor:1, data:'2026-07-01' } });
  const outra = obraOrc('o2', 'Sobrado', { modo:'total', total:1008000 }, [['estrutura', 1048000]]);
  const r = avisosOrcamento({ obras:[CASA, vendida, outra] }, {});
  assert.ok(r.linhas.includes('Fundação (Casa Alphaville) passou R$ 8 mil do previsto'), r.linhas.join(' | '));
  assert.ok(!r.linhas.some(l => l.includes('Vendida')));
  assert.deepStrictEqual(r.obraIds, ['o1', 'o2']);
});

t('no máximo 3 frases; o resto vira contagem', () => {
  const muitos = obraOrc('o1', 'Casa', { modo:'topicos', topicos:{ fundacao:10, estrutura:10, eletrica:10, pintura:10 } },
    [['fundacao', 20], ['estrutura', 20], ['eletrica', 20], ['pintura', 20]]);
  const r = avisosOrcamento({ obras:[muitos] }, {});
  assert.strictEqual(r.linhas.length, 4);
  assert.strictEqual(r.linhas[3], '+ 2 avisos de orçamento');
});

t('tópico próprio usa o nome dele; tópico apagado cai no id', () => {
  const dados = { config:{ taxaMensal:1, topicosCustom:[{ id:'c_portao', nm:'Portão', ic:'etiqueta' }] },
    obras:[obraOrc('o1', 'Casa', { modo:'topicos', topicos:{ c_portao:1000, c_sumiu:1000 } }, [['c_portao', 1500], ['c_sumiu', 1500]])] };
  const linhas = avisosOrcamento(dados, {}).linhas;
  assert.ok(linhas.includes('Portão passou R$ 500,00 do previsto'), linhas.join(' | '));
  assert.ok(linhas.includes('c_sumiu passou R$ 500,00 do previsto'), linhas.join(' | '));
});

t('montaResumo: avisos de orçamento vêm primeiro e viram atalho da obra', () => {
  const dados = { obras:[{ ...CASA, afazeres:[{ id:'a', texto:'x', feito:false }] }] };
  const r = montaResumo(dados, '2026-07-10', 'noite', {});
  assert.strictEqual(r.corpo.split('\n')[0], 'Fundação passou R$ 8 mil do previsto');
  assert.ok(r.corpo.includes('1 afazer pendente'));
  assert.strictEqual(r.obraId, 'o1');
});

t('valores grandes ficam curtos', () => {
  const grande = obraOrc('o1', 'Casa', { modo:'total', total:1000000 }, [['terreno', 2250000]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[grande] }, {}).linhas, ['Casa passou R$ 1,25 mi do orçamento']);
  const mil = obraOrc('o1', 'Casa', { modo:'total', total:1000 }, [['terreno', 2500]]);
  assert.deepStrictEqual(avisosOrcamento({ obras:[mil] }, {}).linhas, ['Casa passou R$ 1,5 mil do orçamento']);
});

console.log(`\n${n} testes ok`);
