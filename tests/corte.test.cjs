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

test('regra: incidente traz a política e o estado; sem condição nem valores, eles vêm nulos', ()=>{
  assert.deepEqual(regra.interpretar(eventoDe({ version: '1.2', incident: { incident_id: 'x', policy_name: 'leituras', state: 'open' } })),
    { tipo: 'incidente', politica: 'leituras', estado: 'open', condicao: null, valorObservado: null, limiar: null });
});

/* O aviso como o Monitoring publica (versão 1.2, do T4 de 12/11, com os IDs trocados): o valor
   observado e o limiar vêm em texto. */
const avisoReal = ({ condicao = 'Leituras do Firestore: mais de 2.000 em 1 h', observado = '2512.000', limiar = '2000', estado = 'open', politica = 'leituras' } = {}) => ({
  version: '1.2',
  incident: {
    condition: { conditionThreshold: { aggregations: [{ alignmentPeriod: '3600s', crossSeriesReducer: 'REDUCE_SUM', perSeriesAligner: 'ALIGN_SUM' }],
      comparison: 'COMPARISON_GT', duration: '0s', filter: 'metric.type="firestore.googleapis.com/document/read_ops_count"', thresholdValue: 2000, trigger: { count: 1 } },
    displayName: condicao, name: 'projects/alvo/alertPolicies/1/conditions/2' },
    condition_name: condicao, ended_at: null, incident_id: '0.abc', metadata: { system_labels: {}, user_labels: {} },
    metric: { displayName: 'Document reads', labels: {}, type: 'firestore.googleapis.com/document/read_ops_count' },
    observed_value: observado, policy_name: politica,
    resource: { labels: { project_id: 'alvo', resource_container: '1' }, type: 'firestore.googleapis.com/Database' },
    resource_id: '', resource_name: 'alvo Firestore Database', resource_type_display_name: 'Firestore Database',
    scoping_project_id: 'alvo', scoping_project_number: 1, severity: 'No severity', started_at: 1794516898, state: estado,
    summary: 'Document reads for alvo Firestore Database is above the threshold of 2000.000 with a value of 2512.000.',
    threshold_value: limiar, url: 'https://console.cloud.google.com/monitoring/alerting/alerts/0.abc',
  },
});

test('regra: incidente traz a condição, cortada em 200, e o valor observado e o limiar como número', ()=>{
  assert.deepEqual(regra.interpretar(eventoDe(avisoReal())),
    { tipo: 'incidente', politica: 'leituras', estado: 'open', condicao: 'Leituras do Firestore: mais de 2.000 em 1 h', valorObservado: 2512, limiar: 2000 });
  const numero = v => regra.interpretar(eventoDe(avisoReal({ observado: v }))).valorObservado;
  assert.equal(numero('586.000'), 586, 'texto do Monitoring vira número: 586, não 586 mil');
  assert.equal(numero(' 2512.5 '), 2512.5);
  assert.equal(numero(2512), 2512);
  for(const ruim of ['', '  ', 'abc', '1e3', '0x10', 'Infinity', '586,000', true, null, {}, []]) assert.equal(numero(ruim), null, JSON.stringify(ruim));
  assert.equal(regra.interpretar(eventoDe(avisoReal({ limiar: 'dois mil' }))).limiar, null);
  const condicao = c => regra.interpretar(eventoDe(avisoReal({ condicao: c }))).condicao;
  assert.equal(condicao('x'.repeat(300)), 'x'.repeat(200));
  for(const ruim of [123, null, '', '   ', ['a']]) assert.equal(condicao(ruim), null, JSON.stringify(ruim));
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

test('regra: no modo oficial o projeto tira a cobrança em R$ 60 e o de fora não muda', ()=>{
  assert.equal(regra.decidirOrcamento('projeto', 5999, 'oficial'), 'nada');
  assert.equal(regra.decidirOrcamento('projeto', 6000, 'oficial'), 'tirar-cobranca');
  assert.equal(regra.decidirOrcamento('projeto', 30000, 'oficial'), 'tirar-cobranca');
  assert.equal(regra.decidirOrcamento('fora', 9999, 'oficial'), 'nada');
  assert.equal(regra.decidirOrcamento('fora', 10000, 'oficial'), 'tirar-cobranca');
  assert.equal(regra.decidirOrcamento('projeto', 6000, 'dois-tempos'), 'desligar-api');
});

test('regra: modo do corte só aceita o texto exato, e sem variável vale dois-tempos', ()=>{
  assert.equal(regra.modoDoCorte(undefined), 'dois-tempos');
  assert.equal(regra.modoDoCorte('dois-tempos'), 'dois-tempos');
  assert.equal(regra.modoDoCorte('oficial'), 'oficial');
  for(const valor of ['OFICIAL', 'oficial ', '', 'dois_tempos', 'true']) assert.equal(regra.modoDoCorte(valor), null, JSON.stringify(valor));
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
  const tirada = regra.registrarCobrancaTirada(base, agora);
  assert.equal(regra.registrarFalha(falhou, depois), falhou, 'sem mudança, nada a regravar');
  assert.equal(regra.registrarApiDesligada(desligada, depois), desligada);
  assert.equal(regra.registrarCobrancaTirada(tirada, depois), tirada);
});

const { criarGoogle, ConflitoDeEstado } = require('../corte/google.js');

class ErroHttp extends Error {
  constructor(status){ super(`HTTP ${status}`); this.response = { status }; }
}

const URL_API = 'https://serviceusage.googleapis.com/v1/projects/alvo/services/firestore.googleapis.com';
const URL_COBRANCA = 'https://cloudbilling.googleapis.com/v1/projects/alvo/billingInfo';
const URL_OBJETO = 'https://storage.googleapis.com/storage/v1/b/estado-teste/o/estado.json';
const URL_UPLOAD = 'https://storage.googleapis.com/upload/storage/v1/b/estado-teste/o?uploadType=media&name=estado.json&ifGenerationMatch=';

/* O Google inteiro num objeto: URL errada estoura, e falhar[rótulo] injeta erro uma vez por item. */
function googleFalso({ api = 'ENABLED', cobranca = true, estado = null } = {}){
  const g = { api, cobranca, estado, geracao: estado ? 5 : 0, chamadas: [], falhar: {}, enviados: [], leiturasAteDesligar: 0 };
  const talvezFalhe = rotulo => { const f = g.falhar[rotulo]; if(f && f.length) throw f.shift(); };
  g.cliente = { async request(o){
    assert.equal(o.timeout, 30000, 'todo pedido ao Google tem prazo');
    const metodo = o.method || 'GET';
    let rotulo;
    if(metodo === 'GET' && o.url === URL_API) rotulo = 'api-ler';
    else if(metodo === 'POST' && o.url === `${URL_API}:disable`) rotulo = 'api-desligar';
    else if(metodo === 'GET' && o.url === URL_COBRANCA) rotulo = 'cobranca-ler';
    else if(metodo === 'PUT' && o.url === URL_COBRANCA) rotulo = 'cobranca-tirar';
    else if(metodo === 'GET' && o.url === `${URL_OBJETO}?fields=generation`) rotulo = 'estado-meta';
    else if(metodo === 'GET' && o.url === `${URL_OBJETO}?alt=media`) rotulo = 'estado-ler';
    else if(metodo === 'POST' && o.url.startsWith(URL_UPLOAD)) rotulo = 'estado-gravar';
    else throw new Error(`rota inesperada: ${metodo} ${o.url}`);
    g.chamadas.push(rotulo);
    talvezFalhe(rotulo);
    if(rotulo === 'api-ler'){
      if(g.leiturasAteDesligar > 0 && --g.leiturasAteDesligar === 0) g.api = 'DISABLED';
      return { status: 200, data: { name: 'projects/1/services/firestore.googleapis.com', state: g.api } };
    }
    if(rotulo === 'api-desligar'){
      assert.deepEqual(o.data, { disableDependentServices: false, checkIfServiceHasUsage: 'SKIP' });
      if(g.demoraDesligar) g.leiturasAteDesligar = g.demoraDesligar; else g.api = 'DISABLED';
      return { status: 200, data: { name: 'operations/x' } };
    }
    if(rotulo === 'cobranca-ler') return { status: 200, data: g.cobranca ? { billingEnabled: true, billingAccountName: 'billingAccounts/1' } : { billingAccountName: '' } };
    if(rotulo === 'cobranca-tirar'){
      assert.deepEqual(o.data, { billingAccountName: '' });
      g.cobranca = false;
      return { status: 200, data: { billingAccountName: '' } };
    }
    if(rotulo === 'estado-meta'){
      if(!g.estado) throw new ErroHttp(404);
      return { status: 200, data: { generation: String(g.geracao) } };
    }
    if(rotulo === 'estado-ler') return { status: 200, data: o.responseType === 'text' ? JSON.stringify(g.estado) : g.estado };
    const esperada = o.url.slice(URL_UPLOAD.length);
    if(esperada !== String(g.geracao)) throw new ErroHttp(412);
    assert.equal(o.headers['Content-Type'], 'application/json');
    g.estado = JSON.parse(o.data);
    g.enviados.push(g.estado);
    g.geracao += 1;
    return { status: 200, data: { generation: String(g.geracao) } };
  } };
  g.adaptador = () => criarGoogle({ cliente: g.cliente, projeto: 'alvo', bucket: 'estado-teste' });
  return g;
}

test('google: estado da API vem do services.get', async ()=>{
  const g = googleFalso({ api: 'DISABLED' });
  assert.equal(await g.adaptador().estadoDaApi(), 'DISABLED');
  assert.deepEqual(g.chamadas, ['api-ler']);
});

test('google: desligar pede services.disable sem derrubar dependente e sem checar uso', async ()=>{
  const g = googleFalso();
  await g.adaptador().desligarApi();
  assert.deepEqual(g.chamadas, ['api-desligar']);
});

test('google: erro da API chega ao chamador com o status', async ()=>{
  const g = googleFalso();
  g.falhar['api-desligar'] = [new ErroHttp(400)];
  await assert.rejects(g.adaptador().desligarApi(), e => e.response.status === 400);
});

test('google: cobrança ligada só com billingEnabled verdadeiro', async ()=>{
  assert.equal(await googleFalso({ cobranca: true }).adaptador().cobrancaLigada(), true);
  assert.equal(await googleFalso({ cobranca: false }).adaptador().cobrancaLigada(), false, 'campo ausente na resposta é falso');
});

test('google: tirar a cobrança manda billingAccountName vazio', async ()=>{
  const g = googleFalso();
  await g.adaptador().tirarCobranca();
  assert.deepEqual(g.chamadas, ['cobranca-tirar']);
  assert.equal(g.cobranca, false);
});

test('google: sem estado no bucket começa vazio e cria com ifGenerationMatch=0', async ()=>{
  const g = googleFalso();
  const r = await g.adaptador().atualizarEstado(e => ({ ...e, primeiraFalha: 'x' }));
  assert.equal(r.primeiraFalha, 'x');
  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-gravar']);
  assert.deepEqual(g.estado.orcamentos, {});
});

test('google: atualizar lê a geração antes do conteúdo e regrava com ela', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  const r = await g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' }));
  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler', 'estado-gravar']);
  assert.equal(r.primeiraFalha, 'a');
  assert.equal(g.estado.apiDesligadaEm, 'b');
  assert.equal(g.geracao, 6);
});

test('google: transformar sem mudança não regrava', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  await g.adaptador().atualizarEstado(e => e);
  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler']);
});

test('google: conflito na gravação tenta uma vez de novo, sobre o estado relido', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  g.falhar['estado-gravar'] = [new ErroHttp(412)];
  const vistos = [];
  await g.adaptador().atualizarEstado(e => { vistos.push(e.primeiraFalha); return { ...e, apiDesligadaEm: 'b' }; });
  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler', 'estado-gravar', 'estado-meta', 'estado-ler', 'estado-gravar']);
  assert.equal(vistos.length, 2);
  assert.equal(g.estado.apiDesligadaEm, 'b');
});

test('google: segundo conflito seguido desiste com ConflitoDeEstado', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  g.falhar['estado-gravar'] = [new ErroHttp(412), new ErroHttp(412)];
  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), ConflitoDeEstado);
  assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 2);
});

test('google: falha ao ler o estado chega ao chamador, sem virar estado vazio', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  g.falhar['estado-meta'] = [new ErroHttp(503)];
  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), e => e.response.status === 503);
  assert.deepEqual(g.chamadas, ['estado-meta']);
});

test('google: erro na gravação que não é conflito não repete', async ()=>{
  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
  g.falhar['estado-gravar'] = [new ErroHttp(500)];
  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), e => e.response.status === 500);
  assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 1);
});

const { criarManipulador, registrarFuncao } = require('../corte/index.js');

const T0 = '2026-11-09T12:00:00.000Z';
const mais = (iso, ms) => new Date(Date.parse(iso) + ms).toISOString();
const SEIS_HORAS = 6 * 60 * 60 * 1000;
const ENV = { ARMADO_API: 'true', ARMADO_COBRANCA: 'true', ORCAMENTO_PROJETO: 'projeto', ORCAMENTO_FORA_FIRESTORE: 'fora',
  POLITICA_ALERTA: 'leituras', PROJETO_ALVO: 'alvo', BUCKET_ESTADO: 'estado-teste' };
const incidente = (politica, estado) => ({ version: '1.2', incident: { incident_id: 'i', policy_name: politica, state: estado } });
const foraDe = custo => msgOrcamento(custo, { budgetDisplayName: 'fora' });
const semEstado = chamadas => chamadas.filter(c => !c.startsWith('estado-'));

async function rodar(g, corpo, { env = {}, agora = T0, evento } = {}){
  const linhas = [];
  const receber = criarManipulador({
    carregar: () => g.adaptador(), env: { ...ENV, ...env }, agora: () => new Date(agora),
    escrever: l => linhas.push(JSON.parse(l)), esperar: async () => {},
  });
  let erro = null;
  try{ await receber(evento || eventoDe(corpo)); }catch(e){ erro = e; }
  return { erro, linhas, de: m => linhas.filter(l => l.marca === m) };
}
function passagemUnica(r){
  assert.equal(r.de('corte-passagem').length, 1, 'uma passagem por mensagem');
  return r.de('corte-passagem')[0];
}
const estadoCom = (orcamentos, resto = {}) => ({ orcamentos, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null, ...resto });
const noMes = (maiorCusto, base = 0, intervalo = '2026-11') => ({ intervalo, base, maiorCusto });

test('cenário 1: 59,99 não faz nada e registra a passagem', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(59.99));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), []);
  const p = passagemUnica(r);
  assert.equal(p.severity, 'INFO'); assert.equal(p.custo, 59.99); assert.equal(p.orcamento, 'projeto'); assert.equal(p.fez, 'nada'); assert.ok(p.message);
  assert.deepEqual(r.de('corte-acao'), []);
  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 59.99);
});

test('cenário 2: 60,00 desliga a API e confere pelo services.get', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(60));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  const [a] = r.de('corte-acao');
  assert.equal(a.severity, 'ALERT'); assert.equal(a.custo, 60); assert.equal(a.orcamento, 'projeto'); assert.equal(a.acao, 'desligar-api');
  assert.equal(g.estado.apiDesligadaEm, T0);
  assert.equal(passagemUnica(r).fez, 'desligou a API');
});

test('cenário 3: repetida com a API já desligada não chama disable nem regrava', async ()=>{
  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(60) }, { apiDesligadaEm: T0 }) });
  const r = await rodar(g, msgOrcamento(60));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler']);
  assert.ok(!g.chamadas.includes('estado-gravar'));
  assert.deepEqual(r.de('corte-acao'), []);
  assert.equal(passagemUnica(r).fez, 'API já estava desligada');
});

test('cenário 4: 40 depois de 61 não muda o maiorCusto nem faz nada', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(61) }) });
  const r = await rodar(g, msgOrcamento(40));
  assert.equal(r.erro, null);
  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler']);
  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 61);
  assert.equal(passagemUnica(r).custo, 40);
});

test('cenário 5: primeira mensagem em 300 desliga a API e, confirmada, não tira a cobrança', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(300));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  assert.equal(g.cobranca, true);
  assert.equal(g.estado.cobrancaTiradaEm, null);
});

test('cenário 6: 120 com a API desligada não toca na cobrança', async ()=>{
  const g = googleFalso({ api: 'DISABLED' });
  const r = await rodar(g, msgOrcamento(120));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler']);
});

test('cenário 7: disable falha com custo de 100 ou mais: grava a primeira falha, relança e não corta', async ()=>{
  const erro = new ErroHttp(403);
  const g = googleFalso();
  g.falhar['api-desligar'] = [erro];
  const r = await rodar(g, msgOrcamento(120));
  assert.equal(r.erro, erro);
  assert.equal(g.estado.primeiraFalha, T0);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  assert.equal(r.de('corte-erro').length, 1);
  assert.equal(r.de('corte-erro')[0].custo, 120);
  passagemUnica(r);
});

test('cenário 7: falha com menos de 6 horas ainda não corta', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS - 1) });
  assert.ok(r.erro);
  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
  assert.equal(g.estado.primeiraFalha, T0, 'a contagem não recomeça');
});

test('cenário 7: falha que persiste 6 horas tira a cobrança e não relança', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const agora = mais(T0, SEIS_HORAS);
  const r = await rodar(g, msgOrcamento(120), { agora });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler', 'cobranca-ler', 'cobranca-tirar']);
  assert.equal(g.estado.cobrancaTiradaEm, agora);
  assert.equal(r.de('corte-acao')[0].acao, 'tirar-cobranca');
  assert.equal(passagemUnica(r).fez, 'tirou a cobrança');
});

test('cenário 7: com ARMADO_COBRANCA=false, 6 horas de falha só dizem que faria, e relança', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS), env: { ARMADO_COBRANCA: 'false' } });
  assert.ok(r.erro);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler', 'cobranca-ler']);
  assert.match(r.de('corte-acao')[0].message, /faria/);
});

test('cenário 7: 99,99 com falha antiga não corta', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(99.99) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const r = await rodar(g, msgOrcamento(99.99), { agora: mais(T0, 3 * SEIS_HORAS) });
  assert.ok(r.erro);
  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
});

test('estado real: FAILED_PRECONDITION com a API ligada é falha, não sucesso', async ()=>{
  const g = googleFalso();
  g.falhar['api-desligar'] = [new ErroHttp(400)];
  const r = await rodar(g, msgOrcamento(60));
  assert.ok(r.erro);
  assert.equal(g.estado.primeiraFalha, T0);
  assert.equal(g.estado.apiDesligadaEm, null);
});

test('estado real: disable com erro e services.get DISABLED não é falha', async ()=>{
  const g = googleFalso();
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const original = g.cliente.request;
  g.cliente.request = async o => {
    try{ return await original(o); }
    catch(e){ if(o.url.endsWith(':disable')) g.api = 'DISABLED'; throw e; }
  };
  const r = await rodar(g, msgOrcamento(120));
  assert.equal(r.erro, null);
  assert.equal(g.estado.primeiraFalha, null);
  assert.equal(g.estado.apiDesligadaEm, T0);
});

test('estado real: disable sem erro, mas a API continua ligada, conta como falha', async ()=>{
  const g = googleFalso();
  g.demoraDesligar = 1000;
  const r = await rodar(g, msgOrcamento(60));
  assert.ok(r.erro);
  assert.equal(g.estado.primeiraFalha, T0);
  assert.equal(g.chamadas.filter(c => c === 'api-ler').length, 7, 'uma leitura antes e seis de confirmação');
});

test('estado real: desligamento que demora é confirmado sem registrar falha', async ()=>{
  const g = googleFalso();
  g.demoraDesligar = 3;
  const r = await rodar(g, msgOrcamento(60));
  assert.equal(r.erro, null);
  assert.equal(g.estado.primeiraFalha, null);
  assert.equal(g.estado.apiDesligadaEm, T0);
});

test('estado real: sem conseguir ler o services.get depois do erro não conta falha', async ()=>{
  const g = googleFalso();
  const erroDesligar = new ErroHttp(403), erroLer = new ErroHttp(503);
  g.falhar['api-desligar'] = [erroDesligar];
  const original = g.cliente.request;
  let leituras = 0;
  g.cliente.request = async o => {
    if(o.url.endsWith('firestore.googleapis.com') && !o.method && ++leituras > 1) throw erroLer;
    return original(o);
  };
  const r = await rodar(g, msgOrcamento(120));
  assert.equal(r.erro, erroLer);
  assert.equal(g.estado.primeiraFalha, null);
});

test('estado real: API confirmada desligada encerra a falha anterior', async ()=>{
  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, 2 * SEIS_HORAS) });
  assert.equal(r.erro, null);
  assert.equal(g.estado.primeiraFalha, null);
  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
});

test('cenário 8: falha ao ler o estado com a API desligada relança e não corta', async ()=>{
  const erro = new ErroHttp(503);
  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  g.falhar['estado-meta'] = [erro];
  const r = await rodar(g, msgOrcamento(300), { agora: mais(T0, 3 * SEIS_HORAS) });
  assert.equal(r.erro, erro);
  assert.deepEqual(semEstado(g.chamadas), []);
  assert.equal(r.de('corte-erro').length, 1);
  passagemUnica(r);
});

test('cenário 9: orçamento fora do Firestore em 99,99 não faz nada', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, foraDe(99.99));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), []);
  assert.equal(passagemUnica(r).orcamento, 'fora');
});

test('cenário 9: orçamento fora do Firestore em 100 tira a cobrança sem esperar e sem olhar a API', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, foraDe(100));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler', 'cobranca-tirar']);
  assert.equal(g.estado.cobrancaTiradaEm, T0);
  assert.equal(r.de('corte-acao')[0].acao, 'tirar-cobranca');
});

test('cenário 10: alerta open da política certa desliga a API, sem olhar custo', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, incidente('leituras', 'open'));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  assert.equal(g.estado.apiDesligadaEm, T0);
  assert.equal(r.de('corte-acao')[0].acao, 'desligar-api');
  assert.equal(passagemUnica(r).tipo, 'incidente');
});

test('cenário 10: alerta closed, da política certa ou de outra, não faz nada', async ()=>{
  for(const corpo of [incidente('leituras', 'closed'), incidente('outra', 'closed')]){
    const g = googleFalso();
    const r = await rodar(g, corpo);
    assert.equal(r.erro, null);
    assert.deepEqual(g.chamadas, [], JSON.stringify(corpo));
    assert.deepEqual(r.de('corte-erro'), [], JSON.stringify(corpo));
    assert.equal(passagemUnica(r).fez, 'nada');
  }
});

test('cenário 10: alerta open de outra política dá erro, sem agir e sem relançar', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, incidente('outra', 'open'));
  assert.equal(r.erro, null);
  assert.deepEqual(g.chamadas, []);
  assert.equal(r.de('corte-erro').length, 1, 'um corte-erro por alerta de política desconhecida');
  assert.match(r.de('corte-erro')[0].message, /outra/);
  assert.equal(passagemUnica(r).fez, 'ignorou política desconhecida');
});

test('cenário 10: bucket fora do ar não segura o desligar do alerta', async ()=>{
  const erro = new ErroHttp(503);
  const g = googleFalso();
  g.falhar['estado-meta'] = [erro];
  const r = await rodar(g, incidente('leituras', 'open'));
  assert.equal(r.erro, erro, 'relança para o Pub/Sub repetir e o registro entrar');
  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  assert.equal(g.api, 'DISABLED');
});

test('cenário 10: alerta com disable falhando registra a falha, relança e não corta', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(500) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const r = await rodar(g, incidente('leituras', 'open'), { agora: mais(T0, 3 * SEIS_HORAS) });
  assert.ok(r.erro);
  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
});

/* A política de leituras tem três condições em OR, e cada uma abre o próprio incidente: no T6c
   chegaram três open por ataque em ~6 min 40 s. Do segundo em diante a API já está desligada. */
test('cenário 10: dois e três open seguidos com a API já desligada dão um corte-acao só, e só o primeiro grava', async ()=>{
  for(const vezes of [2, 3]){
    const g = googleFalso();
    const avisos = [];
    for(let i = 0; i < vezes; i++) avisos.push(await rodar(g, incidente('leituras', 'open'), { agora: mais(T0, i * 200000) }));
    const caso = `${vezes} open`;
    const acoes = avisos.flatMap(r => r.de('corte-acao'));
    assert.equal(acoes.length, 1, caso);
    assert.equal(acoes[0].acao, 'desligar-api', caso);
    assert.equal(g.chamadas.filter(c => c === 'api-desligar').length, 1, `${caso}: um disable só`);
    assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 1, `${caso}: os seguintes não regravam o estado`);
    assert.equal(g.estado.apiDesligadaEm, T0, `${caso}: vale a hora do primeiro`);
    for(const r of avisos.slice(1)){
      assert.equal(r.erro, null, caso);
      assert.deepEqual(r.de('corte-erro'), [], caso);
      assert.equal(passagemUnica(r).fez, 'API já estava desligada', caso);
    }
  }
});

test('cenário 10: o corte-acao e a passagem do open dizem a condição, o valor observado e o limiar', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, avisoReal());
  assert.equal(r.erro, null);
  const [a] = r.de('corte-acao');
  assert.equal(a.acao, 'desligar-api');
  assert.equal(a.condicao, 'Leituras do Firestore: mais de 2.000 em 1 h');
  assert.equal(a.valorObservado, 2512);
  assert.equal(a.limiar, 2000);
  assert.equal(a.politica, 'leituras');
  assert.equal(a.message, 'API do Firestore desligada: Leituras do Firestore: mais de 2.000 em 1 h');
  const p = passagemUnica(r);
  assert.deepEqual([p.condicao, p.valorObservado, p.limiar], ['Leituras do Firestore: mais de 2.000 em 1 h', 2512, 2000]);

  const desarmada = await rodar(googleFalso(), avisoReal({ condicao: 'Leituras do Firestore: mais de 2.500 em 5 min', observado: '2700', limiar: '2500' }), { env: { ARMADO_API: 'false' } });
  const [f] = desarmada.de('corte-acao');
  assert.equal(f.acao, 'faria-desligar-api');
  assert.deepEqual([f.condicao, f.valorObservado, f.limiar], ['Leituras do Firestore: mais de 2.500 em 5 min', 2700, 2500]);
  assert.match(f.message, /^faria desligar a API do Firestore \(ARMADO_API=false\): Leituras do Firestore: mais de 2\.500 em 5 min$/);
});

test('cenário 10: open sem a condição e os valores, ou com tipo errado, corta igual', async ()=>{
  for(const corpo of [incidente('leituras', 'open'), avisoReal({ condicao: 42, observado: 'muito', limiar: {} })]){
    const g = googleFalso();
    const r = await rodar(g, corpo);
    assert.equal(r.erro, null);
    assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
    const [a] = r.de('corte-acao');
    assert.equal(a.acao, 'desligar-api');
    assert.deepEqual([a.condicao, a.valorObservado, a.limiar], [null, null, null]);
    assert.equal(a.message, 'API do Firestore desligada');
  }
});

test('cenário 10: o segundo open, que não corta, ainda deixa na passagem qual condição abriu', async ()=>{
  const g = googleFalso();
  await rodar(g, avisoReal({ condicao: 'Leituras do Firestore: mais de 2.500 em 5 min', observado: '2700', limiar: '2500' }));
  const r = await rodar(g, avisoReal({ condicao: 'Leituras do Firestore: mais de 2.000 em 1 h', observado: '4500', limiar: '2000' }), { agora: mais(T0, 34000) });
  assert.deepEqual(r.de('corte-acao'), []);
  const p = passagemUnica(r);
  assert.equal(p.fez, 'API já estava desligada');
  assert.deepEqual([p.condicao, p.valorObservado, p.limiar], ['Leituras do Firestore: mais de 2.000 em 1 h', 4500, 2000]);
});

/* Corrida, item 7 do pedido da trava: no T6c o 2º open veio 34 s e 58 s depois do 1º, e a função
   espera até 50 s pela confirmação do desligamento (6 voltas de 10 s). Duas instâncias sobre o
   mesmo Google falso: a primeira para na espera da confirmação, numa porta que o teste abre, e a
   segunda chega com a API ainda ENABLED. Decisão: aceitar o 2º corte-acao; o teste prende o que
   acontece, nas duas ordens em que o estado pode ser gravado. */
const portao = () => { let abrir; const aberta = new Promise(r => { abrir = r; }); return { aberta, abrir }; };
async function ate(condicao){
  for(let i = 0; i < 10000; i++){
    if(condicao()) return;
    await new Promise(r => setImmediate(r));
  }
  throw new Error('a corrida não chegou ao ponto esperado');
}
function instancia(g, { agora, esperar = async () => {}, cliente = g.cliente }){
  const linhas = [];
  const receber = criarManipulador({
    carregar: () => criarGoogle({ cliente, projeto: 'alvo', bucket: 'estado-teste' }), env: ENV,
    agora: () => new Date(agora), escrever: l => linhas.push(JSON.parse(l)), esperar,
  });
  return { receber: corpo => receber(eventoDe(corpo)).then(() => null, e => e), de: m => linhas.filter(l => l.marca === m) };
}
const C5MIN_AVISO = 'Leituras do Firestore: mais de 2.500 em 5 min', C1H_AVISO = 'Leituras do Firestore: mais de 2.000 em 1 h';
const AVISO_5MIN = avisoReal({ condicao: C5MIN_AVISO, observado: '2700', limiar: '2500' });
const AVISO_1H = avisoReal({ condicao: C1H_AVISO, observado: '4500', limiar: '2000' });
const T34 = mais(T0, 34000);
const contar = (g, rotulo) => g.chamadas.filter(c => c === rotulo).length;

test('corrida: open com o corte do anterior em curso dá um 2º corte-acao, com a condição dele, e o estado fica de quem grava primeiro', async ()=>{
  for(const primeiroAGravar of ['o segundo', 'o primeiro']){
    const g = googleFalso();
    g.demoraDesligar = 3;
    const p1 = portao(), p2 = portao();
    const a = instancia(g, { agora: T0, esperar: () => p1.aberta });
    const b = instancia(g, { agora: T34, esperar: primeiroAGravar === 'o primeiro' ? () => p2.aberta : async () => {} });
    const ra = a.receber(AVISO_5MIN);
    await ate(() => contar(g, 'api-ler') === 2);
    const rb = b.receber(AVISO_1H);
    if(primeiroAGravar === 'o segundo'){
      assert.equal(await rb, null, 'o segundo lê ENABLED, pede o disable de novo e confirma enquanto o primeiro dorme');
      p1.abrir();
    }else{
      await ate(() => contar(g, 'api-ler') === 4);
      p1.abrir();
      assert.equal(await ra, null);
      p2.abrir();
    }
    assert.equal(await ra, null);
    assert.equal(await rb, null);
    const caso = `grava primeiro ${primeiroAGravar}`;
    assert.deepEqual(a.de('corte-acao').map(l => [l.acao, l.condicao]), [['desligar-api', C5MIN_AVISO]], caso);
    assert.deepEqual(b.de('corte-acao').map(l => [l.acao, l.condicao]), [['desligar-api', C1H_AVISO]], caso);
    assert.equal(contar(g, 'api-desligar'), 2, caso);
    assert.equal(contar(g, 'estado-gravar'), 1, `${caso}: quem grava depois acha a hora já gravada`);
    assert.equal(g.estado.apiDesligadaEm, primeiroAGravar === 'o segundo' ? T34 : T0, caso);
    assert.equal(g.estado.primeiraFalha, null, caso);
    assert.deepEqual([...a.de('corte-erro'), ...b.de('corte-erro')], [], caso);
    assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')), caso);
  }
});

test('corrida: se o disable do segundo dá erro com o primeiro em curso, a falha que ele grava some na repetição do Pub/Sub, nas duas ordens', async ()=>{
  for(const primeiroAGravar of ['o segundo', 'o primeiro']){
    const g = googleFalso();
    g.demoraDesligar = 4;
    const p1 = portao(), p3 = portao();
    const a = instancia(g, { agora: T0, esperar: () => p1.aberta });
    let segurarB = primeiroAGravar === 'o primeiro';
    const clienteB = { async request(o){
      if(segurarB && o.url.endsWith('?fields=generation')){ segurarB = false; await p3.aberta; }
      return g.cliente.request(o);
    } };
    const b = instancia(g, { agora: T34, cliente: clienteB });
    const ra = a.receber(AVISO_5MIN);
    await ate(() => contar(g, 'api-ler') === 2);
    const erro = new ErroHttp(400);
    g.falhar['api-desligar'] = [erro];
    const rb = b.receber(AVISO_1H);
    const caso = `grava primeiro ${primeiroAGravar}`;
    if(primeiroAGravar === 'o segundo'){
      assert.equal(await rb, erro, `${caso}: o segundo vê a API ligada na única leitura depois do erro, grava a falha e relança`);
      assert.equal(g.estado.primeiraFalha, T34, caso);
      p1.abrir();
      assert.equal(await ra, null);
    }else{
      await ate(() => contar(g, 'api-ler') === 4);
      p1.abrir();
      assert.equal(await ra, null);
      assert.equal(g.estado.apiDesligadaEm, T0, caso);
      p3.abrir();
      assert.equal(await rb, erro, caso);
      assert.deepEqual([g.estado.apiDesligadaEm, g.estado.primeiraFalha], [T0, T34], `${caso}: a falha grava por cima do corte registrado`);
    }
    assert.deepEqual(a.de('corte-acao').map(l => l.condicao), [C5MIN_AVISO], caso);
    assert.deepEqual(b.de('corte-acao'), [], caso);
    assert.equal(b.de('corte-erro').length, 1, `${caso}: um aviso de falha a mais, passageiro`);

    const repeticao = instancia(g, { agora: mais(T0, 60000) });
    assert.equal(await repeticao.receber(AVISO_1H), null, caso);
    assert.deepEqual(repeticao.de('corte-acao'), [], caso);
    assert.equal(g.estado.primeiraFalha, null, `${caso}: a repetição acha a API desligada e encerra a falha`);
    assert.equal(g.estado.apiDesligadaEm, T0, `${caso}: e não mexe na hora do corte`);
    assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')), `${caso}: nada chega à cobrança`);
  }
});

test('cenário 11: desarmado só registra que faria', async ()=>{
  const env = { ARMADO_API: 'false', ARMADO_COBRANCA: 'false' };
  const g1 = googleFalso();
  const r1 = await rodar(g1, msgOrcamento(120), { env });
  assert.equal(r1.erro, null);
  assert.deepEqual(semEstado(g1.chamadas), ['api-ler']);
  assert.match(r1.de('corte-acao')[0].message, /faria/);
  assert.equal(r1.de('corte-acao')[0].severity, 'ALERT');
  assert.equal(g1.estado.primeiraFalha, null, 'desarmado não tentou: não é falha');
  assert.equal(passagemUnica(r1).fez, 'faria desligar a API');

  const g2 = googleFalso();
  const r2 = await rodar(g2, foraDe(100), { env });
  assert.deepEqual(semEstado(g2.chamadas), ['cobranca-ler']);
  assert.match(r2.de('corte-acao')[0].message, /faria/);

  const g3 = googleFalso();
  const r3 = await rodar(g3, incidente('leituras', 'open'), { env });
  assert.deepEqual(semEstado(g3.chamadas), ['api-ler']);
  assert.match(r3.de('corte-acao')[0].message, /faria/);
});

test('cenário 11: os dois interruptores são independentes', async ()=>{
  const g1 = googleFalso();
  await rodar(g1, foraDe(100), { env: { ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
  assert.ok(!g1.chamadas.includes('cobranca-tirar'));
  const g2 = googleFalso();
  await rodar(g2, msgOrcamento(60), { env: { ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
  assert.ok(g2.chamadas.includes('api-desligar'));
  const g3 = googleFalso();
  await rodar(g3, msgOrcamento(60), { env: { ARMADO_API: 'false', ARMADO_COBRANCA: 'true' } });
  assert.ok(!g3.chamadas.includes('api-desligar'));
  const g4 = googleFalso();
  await rodar(g4, foraDe(100), { env: { ARMADO_API: 'false', ARMADO_COBRANCA: 'true' } });
  assert.ok(g4.chamadas.includes('cobranca-tirar'));
});

test('cenário 11: só o texto exato true arma', async ()=>{
  for(const valor of ['TRUE', '1', 'sim', '', undefined]){
    const g = googleFalso();
    const r = await rodar(g, msgOrcamento(120), { env: { ARMADO_API: valor } });
    assert.ok(!g.chamadas.includes('api-desligar'), String(valor));
    assert.match(r.de('corte-acao')[0].message, /faria/, String(valor));
  }
});

test('cenário 12: mês novo zera base e maiorCusto; mensagem do mês velho é ignorada', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(90, 70, '2026-10') }) });
  const r1 = await rodar(g, msgOrcamento(65));
  assert.equal(r1.erro, null);
  assert.deepEqual(g.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 65 });
  assert.ok(g.chamadas.includes('api-desligar'), 'sem a base de outubro, 65 passa de 60');

  const h = googleFalso({ estado: estadoCom({ projeto: noMes(5) }) });
  const r2 = await rodar(h, msgOrcamento(90, { costIntervalStart: '2026-10-01T07:00:00Z' }));
  assert.equal(r2.erro, null);
  assert.deepEqual(h.chamadas, ['estado-meta', 'estado-ler']);
  assert.equal(h.estado.orcamentos.projeto.maiorCusto, 5);
  assert.equal(passagemUnica(r2).fez, 'ignorou mês velho');
});

test('cenário 13: depois de religar, X + 59 não faz nada e X + 60 desliga de novo', async ()=>{
  for(const base of [12.34, 4.07]){
    const quase = googleFalso({ estado: estadoCom({ projeto: noMes(base, base) }) });
    const r1 = await rodar(quase, msgOrcamento(Math.round((base + 59) * 100) / 100));
    assert.equal(r1.erro, null);
    assert.deepEqual(semEstado(quase.chamadas), [], `base ${base}`);
    const passou = googleFalso({ estado: estadoCom({ projeto: noMes(base, base) }) });
    const r2 = await rodar(passou, msgOrcamento(Math.round((base + 60) * 100) / 100));
    assert.equal(r2.erro, null);
    assert.ok(passou.chamadas.includes('api-desligar'), `base ${base}`);
    assert.equal(r2.de('corte-acao')[0].custo, 60);
  }
});

test('cenário 14: moeda diferente de BRL só dá alarme', async ()=>{
  const g = googleFalso({ estado: estadoCom({ projeto: noMes(1) }) });
  const r = await rodar(g, msgOrcamento(500, { currencyCode: 'USD' }));
  assert.equal(r.erro, null);
  assert.deepEqual(g.chamadas, []);
  const [e] = r.de('corte-erro');
  assert.equal(e.severity, 'ALERT');
  assert.match(e.message, /moeda/);
  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 1);
  passagemUnica(r);
});

test('cenário 15: mensagem ilegível registra erro e não relança', async ()=>{
  for(const evento of [{ data: {} }, eventoDe('lixo'), eventoDe({ qualquer: 1 })]){
    const g = googleFalso();
    const r = await rodar(g, null, { evento });
    assert.equal(r.erro, null);
    assert.deepEqual(g.chamadas, []);
    assert.equal(r.de('corte-erro').length, 1);
    passagemUnica(r);
  }
});

test('cenário 16: cobrança já tirada não chama update', async ()=>{
  const g = googleFalso({ cobranca: false });
  const r = await rodar(g, foraDe(150));
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
  assert.equal(g.estado.cobrancaTiradaEm, T0);
  assert.deepEqual(r.de('corte-acao'), []);
});

test('cenário 16: falha de 6 horas com a cobrança já tirada não chama update nem relança', async ()=>{
  const g = googleFalso({ cobranca: false, estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
  g.falhar['api-desligar'] = [new ErroHttp(403)];
  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS) });
  assert.equal(r.erro, null);
  assert.ok(g.chamadas.includes('cobranca-ler'));
  assert.ok(!g.chamadas.includes('cobranca-tirar'));
  assert.equal(passagemUnica(r).fez, 'cobrança já estava tirada');
});

const OFICIAL = { MODO_CORTE: 'oficial' };

test('cenário 17: modo oficial, 59,99 no projeto não faz nada', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(59.99), { env: OFICIAL });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), []);
  assert.deepEqual(r.de('corte-acao'), []);
  assert.equal(passagemUnica(r).fez, 'nada');
});

test('cenário 17: modo oficial, 60 no projeto tira a cobrança sem olhar a API e sem esperar as 6 horas', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(60), { env: OFICIAL });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler', 'cobranca-tirar']);
  assert.equal(g.cobranca, false);
  assert.equal(g.api, 'ENABLED');
  assert.equal(g.estado.cobrancaTiradaEm, T0);
  assert.equal(g.estado.primeiraFalha, null);
  assert.equal(g.estado.apiDesligadaEm, null);
  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 60);
  const a = r.de('corte-acao')[0];
  assert.equal(a.acao, 'tirar-cobranca'); assert.equal(a.severity, 'ALERT'); assert.equal(a.orcamento, 'projeto'); assert.equal(a.custo, 60);
  assert.equal(passagemUnica(r).fez, 'tirou a cobrança');
});

test('cenário 17: modo oficial vale sobre o custo descontada a base', async ()=>{
  const quase = googleFalso({ estado: estadoCom({ projeto: noMes(12.34, 12.34) }) });
  await rodar(quase, msgOrcamento(72.33), { env: OFICIAL });
  assert.deepEqual(semEstado(quase.chamadas), []);
  const passou = googleFalso({ estado: estadoCom({ projeto: noMes(12.34, 12.34) }) });
  const r = await rodar(passou, msgOrcamento(72.34), { env: OFICIAL });
  assert.deepEqual(semEstado(passou.chamadas), ['cobranca-ler', 'cobranca-tirar']);
  assert.equal(r.de('corte-acao')[0].custo, 60);
});

test('cenário 17: modo oficial com ARMADO_COBRANCA=false só registra que faria, mesmo com a API armada', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(300), { env: { ...OFICIAL, ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
  assert.equal(g.cobranca, true);
  assert.equal(g.estado.cobrancaTiradaEm, null);
  assert.equal(r.de('corte-acao')[0].acao, 'faria-tirar-cobranca');
  assert.match(r.de('corte-acao')[0].message, /faria/);
  assert.equal(passagemUnica(r).fez, 'faria tirar a cobrança');
});

test('cenário 17: modo oficial com a cobrança já tirada não chama update nem relança', async ()=>{
  const g = googleFalso({ cobranca: false, estado: estadoCom({ projeto: noMes(70) }, { cobrancaTiradaEm: T0 }) });
  const r = await rodar(g, msgOrcamento(80), { env: OFICIAL, agora: mais(T0, 3600000) });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
  assert.equal(g.estado.cobrancaTiradaEm, T0);
  assert.equal(passagemUnica(r).fez, 'cobrança já estava tirada');
});

test('cenário 17: modo oficial, falha ao tirar a cobrança relança para o Pub/Sub repetir', async ()=>{
  const erro = new ErroHttp(503);
  const g = googleFalso();
  g.falhar['cobranca-tirar'] = [erro];
  const r = await rodar(g, msgOrcamento(60), { env: OFICIAL });
  assert.equal(r.erro, erro);
  assert.equal(g.estado.cobrancaTiradaEm, null);
  assert.ok(!g.chamadas.some(c => c.startsWith('api-')));
});

test('cenário 17: modo oficial não muda o orçamento fora do Firestore', async ()=>{
  const abaixo = googleFalso();
  await rodar(abaixo, foraDe(99.99), { env: OFICIAL });
  assert.deepEqual(semEstado(abaixo.chamadas), []);
  const acima = googleFalso();
  const r = await rodar(acima, foraDe(100), { env: OFICIAL });
  assert.equal(r.erro, null);
  assert.deepEqual(semEstado(acima.chamadas), ['cobranca-ler', 'cobranca-tirar']);
  assert.match(r.de('corte-acao')[0].message, /fora do Firestore/);
});

test('cenário 17: modo oficial, alerta aberto só registra, sem ação e sem falar com o Google', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, incidente('leituras', 'open'), { env: OFICIAL });
  assert.equal(r.erro, null);
  assert.deepEqual(g.chamadas, []);
  assert.deepEqual(r.de('corte-acao'), []);
  assert.deepEqual(r.de('corte-erro'), []);
  const p = passagemUnica(r);
  assert.equal(p.tipo, 'incidente'); assert.equal(p.politica, 'leituras'); assert.match(p.fez, /registrou/);
});

test('cenário 18: dois-tempos escrito é o mesmo corte de quando a variável não existe', async ()=>{
  const env = { MODO_CORTE: 'dois-tempos' };
  const g1 = googleFalso();
  await rodar(g1, msgOrcamento(60), { env });
  assert.deepEqual(semEstado(g1.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
  const g2 = googleFalso();
  await rodar(g2, incidente('leituras', 'open'), { env });
  assert.deepEqual(semEstado(g2.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
});

test('cenário 18: MODO_CORTE desconhecido dá corte-erro e nenhuma ação, em qualquer mensagem', async ()=>{
  for(const valor of ['OFICIAL', 'oficial ', '', 'dois_tempos']){
    for(const corpo of [msgOrcamento(300), foraDe(300), incidente('leituras', 'open')]){
      const g = googleFalso();
      const r = await rodar(g, corpo, { env: { MODO_CORTE: valor } });
      const caso = JSON.stringify([valor, corpo]);
      assert.equal(r.erro, null, caso);
      assert.deepEqual(g.chamadas, [], caso);
      assert.deepEqual(r.de('corte-acao'), [], caso);
      assert.equal(r.de('corte-erro').length, 1, caso);
      assert.match(r.de('corte-erro')[0].message, /MODO_CORTE/, caso);
      passagemUnica(r);
    }
  }
});

test('orçamento com nome desconhecido dá erro, sem relançar e sem agir', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(500, { budgetDisplayName: 'renomeado' }));
  assert.equal(r.erro, null);
  assert.deepEqual(g.chamadas, []);
  assert.match(r.de('corte-erro')[0].message, /renomeado/);
  passagemUnica(r);
});

test('falha ao tirar a cobrança relança para o Pub/Sub repetir', async ()=>{
  const erro = new ErroHttp(503);
  const g = googleFalso();
  g.falhar['cobranca-tirar'] = [erro];
  const r = await rodar(g, foraDe(100));
  assert.equal(r.erro, erro);
  assert.equal(g.estado.cobrancaTiradaEm, null);
  assert.equal(r.de('corte-erro').length, 1);
});

test('toda linha do registro é um JSON com severity, message e marca', async ()=>{
  const g = googleFalso();
  const r = await rodar(g, msgOrcamento(60));
  assert.ok(r.linhas.length >= 2);
  for(const l of r.linhas){
    assert.equal(typeof l.severity, 'string');
    assert.equal(typeof l.message, 'string');
    assert.match(l.marca, /^corte-(passagem|acao|erro)$/);
  }
});

test('index registra a função receber no framework de CloudEvents', ()=>{
  const registrados = [];
  registrarFuncao({ cloudEvent: (nome, fn) => registrados.push([nome, typeof fn]) }, ENV);
  assert.deepEqual(registrados, [['receber', 'function']]);
});

/* Os scripts rodam de verdade, com um gcloud falso no PATH que anota cada chamada, com os
   argumentos separados por |, na ordem em que chegaram. */
const { spawnSync, spawn } = require('node:child_process');
const { mkdtempSync, writeFileSync, readFileSync, chmodSync, existsSync } = require('node:fs');
const { tmpdir } = require('node:os');
const path = require('node:path');
const http = require('node:http');
const PYTHON_REAL = spawnSync('sh', ['-c', 'command -v python3'], { encoding: 'utf8' }).stdout.trim();

const PASTA_CORTE = path.join(__dirname, '..', 'corte');
const GCLOUD_FALSO = `#!/bin/sh
(IFS='|'; printf '%s\\n' "$*") >> "$GCLOUD_DIR/log"
case "$1 $2" in
  "storage objects")
    [ -f "$GCLOUD_DIR/sem-objeto" ] && exit 1
    echo 7;;
  "storage cat") cat "$GCLOUD_DIR/estado.json";;
  "storage cp")
    n=$(cat "$GCLOUD_DIR/falhas-cp")
    if [ "$n" -gt 0 ]; then echo $((n-1)) > "$GCLOUD_DIR/falhas-cp"; echo 'precondição falhou' >&2; exit 1; fi
    cp "$3" "$GCLOUD_DIR/gravado.json";;
  "services enable") [ -f "$GCLOUD_DIR/falha-enable" ] && exit 1; exit 0;;
  "functions deploy") exit 0;;
  "auth print-access-token")
    [ -f "$GCLOUD_DIR/sem-token" ] && { echo 'ERROR: (gcloud.auth.print-access-token) sem conta ativa' >&2; exit 1; }
    echo token-falso;;
  *) echo "gcloud falso: chamada inesperada: $*" >&2; exit 99;;
esac
`;

/* pythonQuebra: a primeira chamada ao python3, a da trava, sai com esse código; as outras vão ao de verdade. */
function prepararGcloud({ estado = '{}', falhasCp = 0, semObjeto = false, falhaEnable = false, semToken = false, pythonQuebra = 0 } = {}){
  const dir = mkdtempSync(path.join(tmpdir(), 'corte-gcloud-'));
  writeFileSync(path.join(dir, 'gcloud'), GCLOUD_FALSO);
  chmodSync(path.join(dir, 'gcloud'), 0o755);
  writeFileSync(path.join(dir, 'estado.json'), typeof estado === 'string' ? estado : JSON.stringify(estado));
  writeFileSync(path.join(dir, 'falhas-cp'), String(falhasCp));
  if(semObjeto) writeFileSync(path.join(dir, 'sem-objeto'), '');
  if(falhaEnable) writeFileSync(path.join(dir, 'falha-enable'), '');
  if(semToken) writeFileSync(path.join(dir, 'sem-token'), '');
  if(pythonQuebra){
    writeFileSync(path.join(dir, 'python3'), `#!/bin/sh
if [ ! -f "$GCLOUD_DIR/python-quebrou" ]; then
  : > "$GCLOUD_DIR/python-quebrou"
  echo 'Traceback (most recent call last): quebra falsa' >&2
  exit ${pythonQuebra}
fi
exec ${PYTHON_REAL} "$@"
`);
    chmodSync(path.join(dir, 'python3'), 0o755);
  }
  return dir;
}
const ambienteDe = (dir, env) => ({ ...process.env, PATH: `${dir}:${process.env.PATH}`, GCLOUD_DIR: dir, ...env });
function resultadoDe(dir, status, stdout, stderr){
  const arquivoLog = path.join(dir, 'log'), gravado = path.join(dir, 'gravado.json');
  return {
    status, saida: stdout + stderr,
    log: existsSync(arquivoLog) ? readFileSync(arquivoLog, 'utf8').split('\n').filter(Boolean).map(l => l.split('|')) : [],
    gravado: existsSync(gravado) ? JSON.parse(readFileSync(gravado, 'utf8')) : null,
  };
}

function rodarScript(nome, args, { env = {}, ...opcoes } = {}){
  const dir = prepararGcloud(opcoes);
  const r = spawnSync('bash', [path.join(PASTA_CORTE, nome), ...args], { encoding: 'utf8', cwd: tmpdir(), env: ambienteDe(dir, env) });
  return resultadoDe(dir, r.status, r.stdout, r.stderr);
}

/* As políticas como a API devolveu no G1 refeito (17/11), com o e-mail trocado: a de leituras, com
   as três condições em OR, e a de aviso ao lado, que a trava não lê. */
const FILTRO_LEITURAS = 'metric.type="firestore.googleapis.com/document/read_ops_count" AND resource.type="firestore.googleapis.com/Database"';
const registro = mutateTime => ({ mutateTime, mutatedBy: 'giovani@example.com' });
const condicaoDe = (politica, id, displayName, alignmentPeriod, thresholdValue) => ({
  conditionThreshold: {
    filter: FILTRO_LEITURAS, comparison: 'COMPARISON_GT', thresholdValue, duration: '0s', trigger: { count: 1 },
    aggregations: [{ alignmentPeriod, perSeriesAligner: 'ALIGN_SUM', crossSeriesReducer: 'REDUCE_SUM' }],
  },
  displayName, name: `${politica}/conditions/${id}`,
});
const politicaDe = (name, displayName, conditions, content, criada, mudada) => ({
  name, displayName, combiner: 'OR', creationRecord: registro(criada), mutationRecord: registro(mudada), conditions,
  documentation: { content, mimeType: 'text/markdown' },
  notificationChannels: ['projects/app-construcao-civil/notificationChannels/4046886658766328506'],
  enabled: true, alertStrategy: { autoClose: '1800s' },
});
const P_AVISO = 'projects/app-construcao-civil/alertPolicies/18027824024381381616';
const P_LEITURAS = 'projects/app-construcao-civil/alertPolicies/3538567307137321334';
const POLITICA_AVISO = politicaDe(P_AVISO, 'custta-leituras-aviso', [
  condicaoDe(P_AVISO, '18027824024381380643', 'Aviso de leituras do Firestore: mais de 600 em 1 h', '3600s', 600),
  condicaoDe(P_AVISO, '18027824024381381684', 'Aviso de leituras do Firestore: mais de 2.000 em 24 h', '86400s', 2000),
], 'Só aviso, nunca corta: leituras acima de 600 em 1 h ou de 2.000 em 24 h. O uso normal é de poucas leituras por dia. Abra Firestore > Uso e chame o Claude.',
'2026-11-17T18:18:27.471276040Z', '2026-11-17T18:18:27.471276040Z');
const POLITICA_LEITURAS = politicaDe(P_LEITURAS, 'custta-leituras', [
  condicaoDe(P_LEITURAS, '4892309744294522298', 'Leituras do Firestore: mais de 2.500 em 5 min', '300s', 2500),
  condicaoDe(P_LEITURAS, '4892309744294519197', 'Leituras do Firestore: mais de 2.000 em 1 h', '3600s', 2000),
  condicaoDe(P_LEITURAS, '4892309744294520192', 'Leituras do Firestore: mais de 6.000 em 6 h', '21600s', 6000),
], 'Soma de leituras acima do limite numa das três janelas: 2.500 em 5 min, 2.000 em 1 h ou 6.000 em 6 h. O uso normal é de poucas leituras por dia. Abra Firestore > Uso e chame o Claude.',
'2026-11-10T17:15:37.518101114Z', '2026-11-17T18:18:47.870629685Z');
const POLITICAS = { alertPolicies: [POLITICA_AVISO, POLITICA_LEITURAS], totalSize: 2 };
const C5MIN = 'Leituras do Firestore: mais de 2.500 em 5 min';
const C1H = 'Leituras do Firestore: mais de 2.000 em 1 h';
const C6H = 'Leituras do Firestore: mais de 6.000 em 6 h';

const serieCom = points => ({ timeSeries: [{
  metric: { type: 'firestore.googleapis.com/document/read_ops_count' },
  resource: { type: 'firestore.googleapis.com/Database', labels: { project_id: 'alvo' } },
  metricKind: 'DELTA', valueType: 'INT64', points,
}], unit: '1' });
const STATUS = { 403: 'PERMISSION_DENIED', 404: 'NOT_FOUND', 429: 'RESOURCE_EXHAUSTED', 503: 'UNAVAILABLE' };

/* O Monitoring numa porta local. alertPolicies.list devolve `politicas`; timeSeries.list devolve,
   numa série só (REDUCE_SUM), os pontos de `leituras` ([fim do minuto, quantas]) do intervalo
   pedido, do mais novo ao mais velho e com int64Value em texto, como a API. O ponto que fecha no
   início do intervalo também vem: quem decide a janela é o script. Com `porPagina`, as duas listas
   vêm em páginas, com nextPageToken; com `semFim`, a de políticas manda sempre mais uma página,
   até a 200ª, quando desiste com 429, para um laço sem teto falhar em vez de travar o teste;
   `serie` troca a resposta da série inteira. `falhar` por rota: um código HTTP, 'mudo' (nunca
   responde), 'derruba' (fecha a conexão), 'lixo' (200 sem JSON) ou { redireciona: url } (302).
   Anota cada pedido. */
async function subirMonitoring({ politicas = POLITICAS, leituras = [], falhar = {}, porPagina = Infinity, semFim = false, serie } = {}){
  const pedidos = [];
  const servidor = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://monitoring');
    const busca = Object.fromEntries(url.searchParams);
    pedidos.push({ metodo: req.method, caminho: url.pathname, busca, auth: req.headers.authorization, cota: req.headers['x-goog-user-project'] });
    const responder = (status, corpo) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=UTF-8' }); res.end(JSON.stringify(corpo)); };
    const rota = url.pathname.endsWith('/alertPolicies') ? 'politicas' : url.pathname.endsWith('/timeSeries') ? 'serie' : null;
    if(!rota || req.method !== 'GET') return responder(404, { error: { code: 404, message: `rota inesperada: ${req.method} ${url.pathname}`, status: 'NOT_FOUND' } });
    const falha = falhar[rota];
    if(falha === 'mudo') return;
    if(falha === 'derruba') return req.socket.destroy();
    if(falha === 'lixo'){ res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end('<html>isto não é json</html>'); }
    if(falha && falha.redireciona){ res.writeHead(302, { Location: falha.redireciona }); return res.end(); }
    if(falha) return responder(falha, { error: { code: falha, message: `falha falsa em ${rota}`, status: STATUS[falha] } });
    const de = Number(busca.pageToken || 0);
    if(rota === 'politicas' && semFim){
      if(de >= 200) return responder(429, { error: { code: 429, message: 'chega de páginas', status: STATUS[429] } });
      return responder(200, { alertPolicies: [], nextPageToken: String(de + 1) });
    }
    const pagina = (itens, chave, resto = {}) => {
      const corpo = { ...resto, ...(itens.length ? { [chave]: itens.slice(de, de + porPagina) } : {}) };
      if(de + porPagina < itens.length) corpo.nextPageToken = String(de + porPagina);
      return corpo;
    };
    if(rota === 'politicas') return responder(200, pagina(politicas.alertPolicies || [], 'alertPolicies', { totalSize: politicas.totalSize }));
    if(serie) return responder(200, serie(busca));
    const inicio = Date.parse(busca['interval.startTime']), fim = Date.parse(busca['interval.endTime']);
    const pontos = leituras.filter(([t]) => Date.parse(t) >= inicio && Date.parse(t) <= fim)
      .sort(([a], [b]) => Date.parse(b) - Date.parse(a))
      .map(([t, n]) => ({ interval: { startTime: semMs(Date.parse(t) - MINUTO), endTime: t }, value: { int64Value: String(n) } }));
    const { points, ...resto } = pagina(pontos, 'points');
    responder(200, points ? { ...serieCom(points), ...resto } : { ...resto, unit: '1' });
  });
  await new Promise(r => servidor.listen(0, '127.0.0.1', r));
  return {
    url: `http://127.0.0.1:${servidor.address().port}`, pedidos,
    fechar: () => new Promise(r => { servidor.close(r); servidor.closeAllConnections(); }),
  };
}

/* AGORA fixa o relógio da trava: 18h00 UTC, 15h00 em Brasília. */
const AGORA = '2026-11-17T18:00:00Z';
const MINUTO = 60000;
const semMs = ms => new Date(ms).toISOString().replace('.000Z', 'Z');
/* n leituras por minuto nos `minutos` minutos que terminam em `fim`: um ponto por minuto. */
const rajada = (fim, minutos, n) => Array.from({ length: minutos }, (_, i) => [semMs(Date.parse(fim) - i * MINUTO), n]);

/* O religar roda sem bloquear o processo do teste, para o Monitoring falso daqui responder a ele
   enquanto roda; o spawnSync pararia o laço de eventos até o fim do script. */
async function rodarReligar(args, { env = {}, monitoring = {}, ...opcoes } = {}){
  const dir = prepararGcloud(opcoes);
  const m = await subirMonitoring(monitoring);
  try{
    const r = await new Promise((resolve, reject) => {
      const filho = spawn('bash', [path.join(PASTA_CORTE, 'religar.sh'), ...args], {
        cwd: tmpdir(), env: ambienteDe(dir, { AGORA, URL_MONITORING: m.url, ...env }),
      });
      let stdout = '', stderr = '';
      filho.stdout.setEncoding('utf8').on('data', d => { stdout += d; });
      filho.stderr.setEncoding('utf8').on('data', d => { stderr += d; });
      filho.on('error', reject);
      filho.on('close', status => resolve(resultadoDe(dir, status, stdout, stderr)));
    });
    return { ...r, pedidos: m.pedidos };
  }finally{
    await m.fechar();
  }
}
const ESTADO_CORTADO = {
  orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 0, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 3, maiorCusto: 12.5 } },
  primeiraFalha: '2026-11-09T12:00:00.000Z', apiDesligadaEm: '2026-11-09T13:00:00.000Z', cobrancaTiradaEm: '2026-11-09T14:00:00.000Z',
};
const OBJETO_GS = 'gs://custta-corte-estado/estado.json';
const nomeDe = chamada => chamada.slice(0, 3).join(' ');

test('religar: pede o token da trava, lê a geração, depois o conteúdo, grava condicionado e só então religa', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.log.map(nomeDe), [
    'auth print-access-token', `storage objects describe`, `storage cat ${OBJETO_GS}`, `storage cp ${r.log[3][2]}`, 'services enable firestore.googleapis.com',
  ]);
  assert.deepEqual(r.log[1].slice(3), [OBJETO_GS, '--format=value(generation)']);
  assert.deepEqual(r.log[3].slice(3), [OBJETO_GS, '--if-generation-match=7']);
  assert.deepEqual(r.log[4], ['services', 'enable', 'firestore.googleapis.com', '--project', 'app-construcao-civil']);
});

test('religar: com a cobrança tirada, base vira o maiorCusto nos dois orçamentos e os três registros zeram', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.gravado, {
    orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 84.2, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 12.5, maiorCusto: 12.5 } },
    primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null,
  });
});

test('religar: sem cobrança tirada, o orçamento de fora do Firestore não muda, com folga ou sem', async ()=>{
  const estado = { ...ESTADO_CORTADO, cobrancaTiradaEm: null };
  for(const args of [[], ['--folga', '15']]){
    const r = await rodarReligar(args, { estado });
    assert.equal(r.status, 0, r.saida);
    assert.deepEqual(r.gravado.orcamentos['custta-fora-firestore'], ESTADO_CORTADO.orcamentos['custta-fora-firestore'], args.join(' '));
    assert.equal(r.gravado.primeiraFalha, null);
    assert.equal(r.gravado.apiDesligadaEm, null);
    assert.equal(r.gravado.cobrancaTiradaEm, null);
  }
});

test('religar: com a cobrança tirada, --folga soma às bases dos dois orçamentos, sem ruído de ponto flutuante', async ()=>{
  const r = await rodarReligar(['--folga', '15'], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.gravado.orcamentos['custta-projeto'].base, 99.2);
  assert.equal(r.gravado.orcamentos['custta-fora-firestore'].base, 27.5, 'o custo atrasado do ataque também chega ao orçamento de fora');
  const fino = await rodarReligar(['--folga', '0.1'], { estado: {
    orcamentos: { 'custta-projeto': noMes(0.2), 'custta-fora-firestore': noMes(0.2) }, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z',
  } });
  assert.equal(fino.gravado.orcamentos['custta-projeto'].base, 0.3);
  assert.equal(fino.gravado.orcamentos['custta-fora-firestore'].base, 0.3);
});

test('religar: com a folga no orçamento de fora, o custo atrasado do mesmo ataque não tira a cobrança de novo', async ()=>{
  const cortado = { orcamentos: { projeto: noMes(40), fora: noMes(101) }, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: T0 };
  const r = await rodarReligar(['--folga', '150'], { estado: cortado, env: { ORCAMENTO_PROJETO: 'projeto', ORCAMENTO_FORA_FIRESTORE: 'fora' } });
  assert.equal(r.status, 0, r.saida);
  const g = googleFalso({ cobranca: true, estado: r.gravado });
  const relatorio = await rodar(g, foraDe(205));
  assert.equal(relatorio.erro, null);
  assert.ok(!g.chamadas.includes('cobranca-tirar'), 'a cobrança de volta não cai pelo relatório atrasado');
  assert.equal(passagemUnica(relatorio).fez, 'nada');
});

test('religar: os nomes dos orçamentos trocam por ambiente; orçamento de outro nome não muda', async ()=>{
  const outro = noMes(50, 1);
  const estado = { orcamentos: { p: noMes(10), f: noMes(20), 'custta-projeto': outro }, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' };
  const r = await rodarReligar(['--folga', '5'], { estado, env: { ORCAMENTO_PROJETO: 'p', ORCAMENTO_FORA_FIRESTORE: 'f' } });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.gravado.orcamentos, { p: noMes(10, 15), f: noMes(20, 25), 'custta-projeto': outro });
});

const emReais = v => `R$ ${v.toFixed(2).replace('.', ',')}`;

test('religar: termina dizendo em quanto cada corte volta, calculado da base gravada', async ()=>{
  const r = await rodarReligar(['--folga', '15'], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  const fim = r.saida.trim().split('\n').slice(-2);
  assert.deepEqual(fim, ['API cai de novo em R$ 159,20', 'cobrança cai em R$ 127,50']);
  /* Os limites vivem em regra.js e o script, sem Node, repete os dois: mudar lá sem mudar aqui quebra. */
  const { 'custta-projeto': projeto, 'custta-fora-firestore': fora } = r.gravado.orcamentos;
  assert.deepEqual(fim, [`API cai de novo em ${emReais(projeto.base + regra.LIMITE_API / 100)}`, `cobrança cai em ${emReais(fora.base + regra.LIMITE_COBRANCA / 100)}`]);
});

test('religar: sem cobrança tirada, não fala de cobrança', async ()=>{
  const r = await rodarReligar([], { estado: { ...ESTADO_CORTADO, cobrancaTiradaEm: null } });
  assert.equal(r.status, 0, r.saida);
  assert.match(r.saida, /API cai de novo em R\$ 144,20\n$/);
  assert.doesNotMatch(r.saida, /cobrança cai/);
});

test('religar: sem registro dos orçamentos, a API cai no limite cheio e a cobrança não muda', async ()=>{
  const r = await rodarReligar(['--folga', '15'], { estado: { orcamentos: {}, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' } });
  assert.equal(r.status, 0, r.saida);
  assert.match(r.saida, /API cai de novo em R\$ 60,00\n$/);
  assert.doesNotMatch(r.saida, /cobrança cai/);
  assert.equal(r.gravado.cobrancaTiradaEm, null);
});

test('religar: argumento errado para antes de qualquer gcloud', async ()=>{
  for(const args of [['--folga', 'abc'], ['--folga', '-5'], ['--folga'], ['--folga', '1.2.3'], ['--outro']]){
    const r = await rodarReligar(args, { estado: ESTADO_CORTADO });
    assert.notEqual(r.status, 0, args.join(' '));
    assert.deepEqual(r.log, [], args.join(' '));
  }
});

test('religar: conflito na gravação tenta uma vez de novo, relendo tudo', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, falhasCp: 1 });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.log.map(c => c.slice(0, 2).join(' ')), [
    'auth print-access-token', 'storage objects', 'storage cat', 'storage cp', 'storage objects', 'storage cat', 'storage cp', 'services enable',
  ]);
  assert.equal(r.saida.match(/API cai de novo/g).length, 1, 'o que vale agora sai uma vez só');
});

test('religar: sem conseguir gravar a base, não religa a API', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, falhasCp: 2 });
  assert.notEqual(r.status, 0);
  assert.ok(!r.log.some(c => c[0] === 'services'), 'a base grava antes de religar');
  assert.equal(r.log.filter(c => c[1] === 'cp').length, 2);
});

test('religar: estado.json ausente ou ilegível para sem gravar nem religar', async ()=>{
  const sem = await rodarReligar([], { estado: ESTADO_CORTADO, semObjeto: true });
  assert.notEqual(sem.status, 0);
  assert.ok(!sem.log.some(c => c[1] === 'cp' || c[0] === 'services'));
  const ruim = await rodarReligar([], { estado: 'não é json' });
  assert.notEqual(ruim.status, 0);
  assert.ok(!ruim.log.some(c => c[1] === 'cp' || c[0] === 'services'));
});

test('religar: falha ao religar aparece no código de saída', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, falhaEnable: true });
  assert.notEqual(r.status, 0);
  assert.ok(r.gravado, 'a base já está gravada: repetir o script é seguro');
  assert.doesNotMatch(r.saida, /API cai de novo/);
});

test('religar: projeto e bucket trocam por ambiente, para o projeto descartável', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, env: { PROJETO_ALVO: 'descartavel', BUCKET_ESTADO: 'balde' } });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.log.find(c => c[1] === 'cat')[2], 'gs://balde/estado.json');
  assert.deepEqual(r.log.find(c => c[0] === 'services'), ['services', 'enable', 'firestore.googleapis.com', '--project', 'descartavel']);
  assert.equal(r.pedidos.length, 4);
  for(const p of r.pedidos){
    assert.match(p.caminho, /^\/v3\/projects\/descartavel\//, 'a trava lê a política e a métrica do projeto alvo');
    assert.equal(p.cota, 'descartavel');
  }
});

const semBucket = r => !r.log.some(c => c[0] === 'storage' || c[0] === 'services');
const linhaDe = (r, condicao) => r.saida.split('\n').find(l => l.startsWith(`- ${condicao}: `));

test('religar: a trava lê a política do projeto alvo e, de cada condição, a série da janela dela mais 5 min', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.pedidos.map(p => `${p.metodo} ${p.caminho}`), [
    'GET /v3/projects/app-construcao-civil/alertPolicies', ...Array(3).fill('GET /v3/projects/app-construcao-civil/timeSeries'),
  ]);
  for(const p of r.pedidos){
    assert.equal(p.auth, 'Bearer token-falso');
    assert.equal(p.cota, 'app-construcao-civil', 'o projeto de cota vai no cabeçalho: sem ele o gcloud do Cloud Shell divide a cota');
  }
  const series = r.pedidos.slice(1).map(p => p.busca);
  for(const b of series){
    assert.equal(b.filter, FILTRO_LEITURAS);
    assert.equal(b['interval.endTime'], AGORA);
    assert.equal(b['aggregation.alignmentPeriod'], '60s');
    assert.equal(b['aggregation.perSeriesAligner'], 'ALIGN_SUM');
    assert.equal(b['aggregation.crossSeriesReducer'], 'REDUCE_SUM');
  }
  assert.deepEqual(series.map(b => b['interval.startTime']), ['2026-11-17T17:50:00Z', '2026-11-17T16:55:00Z', '2026-11-17T11:55:00Z']);
});

test('religar: a trava segura com a soma em metade do limiar e deixa com uma leitura a menos', async ()=>{
  const segura = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { leituras: [['2026-11-17T17:30:00Z', 1000]] } });
  assert.equal(segura.status, 3, segura.saida);
  assert.ok(semBucket(segura), 'recusada, nada muda no bucket nem na API');
  assert.equal(segura.gravado, null);
  assert.equal(linhaDe(segura, C1H), `- ${C1H}: 1.000 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h35.`);
  assert.equal(linhaDe(segura, C5MIN), `- ${C5MIN}: 0 leituras em 10 min; segura com 1.250 ou mais; livre.`);
  assert.equal(linhaDe(segura, C6H), `- ${C6H}: 1.000 leituras em 6 h 05 min; segura com 3.000 ou mais; livre.`);
  assert.match(segura.saida, /Religue a partir de 17\/11 15h35, horário de Brasília: é o mínimo, contando só as leituras que a métrica já mostra \(ela atrasa uns 4 minutos\)\./);
  assert.match(segura.saida, /a API NÃO foi religada/);

  const deixa = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { leituras: [['2026-11-17T17:30:00Z', 999]] } });
  assert.equal(deixa.status, 0, deixa.saida);
  assert.ok(deixa.log.some(c => c[0] === 'services'));
  assert.equal(linhaDe(deixa, C1H), `- ${C1H}: 999 leituras em 1 h 05 min; segura com 1.000 ou mais; livre.`);
  assert.doesNotMatch(deixa.saida, /Religue a partir/);
});

test('religar: a hora em que solta sai da série por minuto, não do fim do ataque mais a janela', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { leituras: [['2026-11-17T17:00:00Z', 600], ['2026-11-17T17:40:00Z', 500]] } });
  assert.equal(r.status, 3, r.saida);
  assert.equal(linhaDe(r, C1H), `- ${C1H}: 1.100 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h05.`);
  assert.match(r.saida, /Religue a partir de 17\/11 15h05/, 'pelo fim do ataque mais a janela seriam 15h45');
});

test('religar: com várias janelas segurando, cada uma diz a hora dela e vale a mais tarde', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { leituras: rajada('2026-11-17T17:55:00Z', 9, 500) } });
  assert.equal(r.status, 3, r.saida);
  assert.equal(linhaDe(r, C5MIN), `- ${C5MIN}: 2.500 leituras em 10 min; segura com 1.250 ou mais; solta 17/11 15h03.`);
  assert.equal(linhaDe(r, C1H), `- ${C1H}: 4.500 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h59.`);
  assert.equal(linhaDe(r, C6H), `- ${C6H}: 4.500 leituras em 6 h 05 min; segura com 3.000 ou mais; solta 17/11 20h55.`);
  assert.match(r.saida, /Religue a partir de 17\/11 20h55/);
});

test('religar: a hora sobe para o minuto seguinte quando o ponto não fecha no minuto', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { leituras: [['2026-11-17T17:30:30.250Z', 1000]] } });
  assert.equal(r.status, 3, r.saida);
  assert.match(linhaDe(r, C1H), /; solta 17\/11 15h36\.$/);
});

test('religar: com outros números na custta-leituras, a trava acompanha', async ()=>{
  const outra = { ...POLITICA_LEITURAS, conditions: [condicaoDe(P_LEITURAS, '9', 'Leituras: mais de 5.000 em 10 min', '600s', 5000)] };
  const monitoring = n => ({ politicas: { alertPolicies: [POLITICA_AVISO, outra], totalSize: 2 }, leituras: [['2026-11-17T17:55:00Z', n]] });
  const segura = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: monitoring(2500) });
  assert.equal(segura.status, 3, segura.saida);
  assert.equal(segura.pedidos[1].busca['interval.startTime'], '2026-11-17T17:45:00Z');
  assert.equal(linhaDe(segura, 'Leituras: mais de 5.000 em 10 min'), '- Leituras: mais de 5.000 em 10 min: 2.500 leituras em 15 min; segura com 2.500 ou mais; solta 17/11 15h10.');
  const deixa = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: monitoring(2499) });
  assert.equal(deixa.status, 0, deixa.saida);
});

test('religar: limiar e janela vêm da política lida, a do nome em POLITICA_ALERTA', async ()=>{
  const P = 'projects/alvo/alertPolicies/1';
  const teste = politicaDe(P, 'leituras-teste', [condicaoDe(P, '2', 'Teste: mais de 10 em 2 min', '120s', 10)], 'teste', '2026-11-17T17:00:00Z', '2026-11-17T17:00:00Z');
  const monitoring = { politicas: { alertPolicies: [POLITICA_LEITURAS, teste], totalSize: 2 }, leituras: [['2026-11-17T17:57:00Z', 5]] };
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, env: { POLITICA_ALERTA: 'leituras-teste' }, monitoring });
  assert.equal(r.status, 3, r.saida);
  assert.equal(r.pedidos.length, 2, 'a política e a série da condição única');
  assert.equal(r.pedidos[1].busca['interval.startTime'], '2026-11-17T17:53:00Z');
  assert.equal(linhaDe(r, 'Teste: mais de 10 em 2 min'), '- Teste: mais de 10 em 2 min: 5 leituras em 7 min; segura com 5 ou mais; solta 17/11 15h04.');
});

test('religar: a trava segue as páginas da política e da série', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { porPagina: 1, leituras: [['2026-11-17T17:00:00Z', 600], ['2026-11-17T17:40:00Z', 500]] } });
  assert.equal(r.status, 3, r.saida);
  assert.match(linhaDe(r, C1H), /: 1\.100 leituras em 1 h 05 min;/);
  assert.ok(r.pedidos.some(p => p.caminho.endsWith('/alertPolicies') && p.busca.pageToken === '1'), 'a de leituras vem na segunda página');
  const daHora = r.pedidos.filter(p => p.busca['interval.startTime'] === '2026-11-17T16:55:00Z');
  assert.deepEqual(daHora.map(p => p.busca.pageToken), [undefined, '1']);
  for(const p of daHora) assert.equal(p.busca.filter, FILTRO_LEITURAS, 'a página seguinte repete o pedido');
});

async function portaFechada(){
  const s = http.createServer();
  await new Promise(r => s.listen(0, '127.0.0.1', r));
  const { port } = s.address();
  await new Promise(r => s.close(r));
  return port;
}

test('religar: sem conseguir ler a política ou a série, a trava não deixa religar e diz por quê', { timeout: 120000 }, async ()=>{
  const umaHora = POLITICA_LEITURAS.conditions[1];
  const comLimiar = mudanca => ({ ...umaHora, conditionThreshold: { ...umaHora.conditionThreshold, ...mudanca } });
  const soCom = (...conditions) => ({ politicas: { alertPolicies: [POLITICA_AVISO, { ...POLITICA_LEITURAS, conditions }], totalSize: 2 } });
  const agregacao = (alignmentPeriod, perSeriesAligner = 'ALIGN_SUM') => ({ alignmentPeriod, perSeriesAligner, crossSeriesReducer: 'REDUCE_SUM' });
  const ponto = value => ({ interval: { startTime: '2026-11-17T17:29:00Z', endTime: '2026-11-17T17:30:00Z' }, value });
  const espiao = await subirMonitoring();
  const casos = [
    ['sem a política', { monitoring: { politicas: { alertPolicies: [POLITICA_AVISO], totalSize: 1 } } }, /a política custta-leituras não existe no projeto app-construcao-civil/],
    ['nenhuma política no projeto', { monitoring: { politicas: {} } }, /a política custta-leituras não existe/],
    ['duas com o mesmo nome', { monitoring: { politicas: { alertPolicies: [POLITICA_LEITURAS, POLITICA_LEITURAS], totalSize: 2 } } }, /há 2 políticas custta-leituras/],
    ['lista de condições vazia', { monitoring: soCom() }, /a política custta-leituras não tem condição/],
    ['sem lista de condições', { monitoring: { politicas: { alertPolicies: [{ ...POLITICA_LEITURAS, conditions: undefined }] } } }, /não tem condição/],
    ['taxa no lugar de soma', { monitoring: soCom(comLimiar({ aggregations: [agregacao('3600s', 'ALIGN_RATE')] })) }, /a condição Leituras do Firestore: mais de 2\.000 em 1 h não é soma acima de um limiar/],
    ['comparação abaixo', { monitoring: soCom(comLimiar({ comparison: 'COMPARISON_LT' })) }, /não é soma acima de um limiar/],
    ['sem limiar', { monitoring: soCom(comLimiar({ thresholdValue: undefined })) }, /não é soma acima de um limiar/],
    ['limiar zero', { monitoring: soCom(comLimiar({ thresholdValue: 0 })) }, /não é soma acima de um limiar/],
    ['duas agregações', { monitoring: soCom(comLimiar({ aggregations: [agregacao('3600s'), agregacao('3600s')] })) }, /não é soma acima de um limiar/],
    ['média entre as séries', { monitoring: soCom(comLimiar({ aggregations: [{ alignmentPeriod: '3600s', perSeriesAligner: 'ALIGN_SUM', crossSeriesReducer: 'REDUCE_MEAN' }] })) }, /não é soma acima de um limiar/],
    ['sem redutor entre as séries', { monitoring: soCom(comLimiar({ aggregations: [{ alignmentPeriod: '3600s', perSeriesAligner: 'ALIGN_SUM' }] })) }, /não é soma acima de um limiar/],
    ['razão, com denominatorFilter', { monitoring: soCom(comLimiar({ denominatorFilter: FILTRO_LEITURAS, denominatorAggregations: [agregacao('3600s')] })) }, /não é soma acima de um limiar/],
    ['janela fora do formato', { monitoring: soCom(comLimiar({ aggregations: [agregacao('1h')] })) }, /não é soma acima de um limiar/],
    ['condição de ausência', { monitoring: soCom({ displayName: 'Sem dado', conditionAbsent: { filter: FILTRO_LEITURAS, duration: '600s' } }) }, /a condição Sem dado não é soma acima de um limiar/],
    ['HTTP 403 na política', { monitoring: { falhar: { politicas: 403 } } }, /o Monitoring respondeu HTTP 403 PERMISSION_DENIED: falha falsa em politicas/],
    ['HTTP 503 na série', { monitoring: { falhar: { serie: 503 } } }, /o Monitoring respondeu HTTP 503 UNAVAILABLE: falha falsa em serie/],
    ['corpo que não é JSON', { monitoring: { falhar: { serie: 'lixo' } } }, /a resposta do Monitoring veio fora do formato \(JSONDecodeError/],
    ['conexão derrubada', { monitoring: { falhar: { politicas: 'derruba' } } }, /RemoteDisconnected|ConnectionResetError/],
    ['prazo estourado', { monitoring: { falhar: { serie: 'mudo' } } }, /timed out/],
    ['ponto sem valor', { monitoring: { serie: () => serieCom([ponto({})]) } }, /um ponto da série veio com valor fora do formato: \{\}/],
    ['valor que não é número', { monitoring: { serie: () => serieCom([ponto({ int64Value: 'muitas' })]) } }, /valor fora do formato: \{"int64Value": "muitas"\}/],
    ['valor negativo', { monitoring: { serie: () => serieCom([ponto({ int64Value: '5000' }), ponto({ int64Value: '-5000' })]) } }, /valor fora do formato: \{"int64Value": "-5000"\}/],
    ['int64Value em número, fora do formato da API', { monitoring: { serie: () => serieCom([ponto({ int64Value: 1000 })]) } }, /valor fora do formato: \{"int64Value": 1000\}/],
    ['valor booleano', { monitoring: { serie: () => serieCom([ponto({ doubleValue: true })]) } }, /valor fora do formato: \{"doubleValue": true\}/],
    ['valor negativo em double', { monitoring: { serie: () => serieCom([ponto({ doubleValue: -1.5 })]) } }, /valor fora do formato/],
    ['redirecionamento, que levaria o token junto', { monitoring: { falhar: { politicas: { redireciona: `${espiao.url}/v3/projects/app-construcao-civil/alertPolicies` } } } }, /o Monitoring respondeu HTTP 302/],
    ['páginas sem fim', { monitoring: { semFim: true } }, /o Monitoring mandou mais de 50 páginas de alertPolicies/],
    ['fim do ponto ilegível', { monitoring: { serie: () => serieCom([{ interval: { startTime: '2026-11-17T17:29:00Z', endTime: '17/11/2026 17:30' }, value: { int64Value: '5' } }]) } }, /hora fora do formato: 17\/11\/2026 17:30/],
    ['token negado', { semToken: true }, /o gcloud não deu o token de acesso: ERROR: \(gcloud\.auth\.print-access-token\) sem conta ativa/],
    ['Monitoring fora do ar', { env: { URL_MONITORING: `http://127.0.0.1:${await portaFechada()}` } }, /Connection refused/],
  ];
  try{
    for(const [nome, opcoes, motivo] of casos){
      const r = await rodarReligar([], { estado: ESTADO_CORTADO, ...opcoes });
      assert.equal(r.status, 4, `${nome}: ${r.saida}`);
      assert.ok(semBucket(r), nome);
      assert.equal(r.gravado, null, nome);
      assert.match(r.saida, /Trava: sem ler as leituras, não deixo religar: /, nome);
      assert.match(r.saida, motivo, nome);
      assert.match(r.saida, /a API NÃO foi religada/, nome);
      if(nome === 'páginas sem fim') assert.equal(r.pedidos.length, 50, 'para no teto de 50 páginas');
    }
  }finally{
    await espiao.fechar();
  }
  assert.deepEqual(espiao.pedidos, [], 'o redirecionamento não foi seguido: o token não saiu');
});

test('religar: série com doubleValue soma igual à de int64Value', async ()=>{
  const serie = n => () => serieCom([{ interval: { startTime: '2026-11-17T17:29:00Z', endTime: '2026-11-17T17:30:00Z' }, value: { doubleValue: n } }]);
  const segura = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { serie: serie(1000) } });
  assert.equal(segura.status, 3, segura.saida);
  assert.equal(linhaDe(segura, C1H), `- ${C1H}: 1.000 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h35.`);
  const deixa = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { serie: serie(999.5) } });
  assert.equal(deixa.status, 0, deixa.saida);
});

test('religar: python da trava que não termina, ou que falta, conta como não leu', async ()=>{
  for(const codigo of [1, 127]){
    const r = await rodarReligar([], { estado: ESTADO_CORTADO, pythonQuebra: codigo });
    assert.equal(r.status, 4, `${codigo}: ${r.saida}`);
    assert.ok(semBucket(r), String(codigo));
    assert.match(r.saida, new RegExp(`a trava não rodou até o fim \\(saída ${codigo}\\): a API NÃO foi religada`));
  }
});

test('religar: a trava não usa proxy do ambiente, para o token ir só ao Monitoring', async ()=>{
  const morto = `http://127.0.0.1:${await portaFechada()}`;
  const env = { http_proxy: morto, https_proxy: morto, HTTP_PROXY: morto, HTTPS_PROXY: morto, no_proxy: '', NO_PROXY: '' };
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, env });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.pedidos.length, 4);
});

const SEGURA_1H = { leituras: [['2026-11-17T17:30:00Z', 1000]] };

test('religar: --forcar sem motivo para antes de qualquer gcloud e de qualquer pedido ao Monitoring', async ()=>{
  for(const args of [['--forcar'], ['--forcar', ''], ['--forcar', '  \t '], ['--forcar', '--folga', '5'], ['--folga', '5', '--forcar'], ['--forcar', '-x']]){
    const r = await rodarReligar(args, { estado: ESTADO_CORTADO, monitoring: SEGURA_1H });
    assert.equal(r.status, 2, JSON.stringify(args));
    assert.deepEqual(r.log, [], JSON.stringify(args));
    assert.deepEqual(r.pedidos, [], JSON.stringify(args));
    assert.match(r.saida, /uso: religar\.sh \[--folga N\] \[--forcar "motivo"\]/);
  }
});

test('religar: --forcar religa com a soma alta, mostra o que a trava diz e registra no estado o motivo e o resultado', async ()=>{
  const motivo = 'corte falso: uso legítimo cresceu, limiar subiu para 4.000 em 1 h';
  const r = await rodarReligar(['--forcar', motivo], { estado: ESTADO_CORTADO, monitoring: SEGURA_1H });
  assert.equal(r.status, 0, r.saida);
  assert.ok(r.log.some(c => c[0] === 'services'), 'religou');
  assert.equal(linhaDe(r, C1H), `- ${C1H}: 1.000 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h35.`);
  assert.match(r.saida, new RegExp(`Religando à força, com a trava em "segura"\\. Motivo: ${motivo}`));
  assert.doesNotMatch(r.saida, /NÃO foi religada/);
  const [registro, ...resto] = r.gravado.religadosForcados;
  assert.deepEqual(resto, []);
  assert.deepEqual(Object.keys(registro).sort(), ['em', 'motivo', 'resultado', 'trava']);
  assert.equal(registro.em, '2026-11-17T18:00:00.000Z');
  assert.equal(registro.motivo, motivo);
  assert.equal(registro.resultado, 'segura');
  assert.match(registro.trava[0], /^Trava: leituras ainda altas na política custta-leituras\. Religue a partir de 17\/11 15h35/);
  assert.ok(registro.trava.includes(`- ${C1H}: 1.000 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h35.`));
  assert.equal(r.gravado.orcamentos['custta-projeto'].base, 84.2, 'a base grava como sempre');
  assert.equal(r.gravado.apiDesligadaEm, null);
});

test('religar: --forcar vale sem leitura e com o python da trava quebrado, e registra o porquê', async ()=>{
  const semLeitura = await rodarReligar(['--forcar', 'Monitoring fora'], { estado: ESTADO_CORTADO, monitoring: { falhar: { politicas: 403 } } });
  assert.equal(semLeitura.status, 0, semLeitura.saida);
  assert.ok(semLeitura.log.some(c => c[0] === 'services'));
  const [a] = semLeitura.gravado.religadosForcados;
  assert.equal(a.resultado, 'nao-leu');
  assert.deepEqual(a.trava, ['Trava: sem ler as leituras, não deixo religar: o Monitoring respondeu HTTP 403 PERMISSION_DENIED: falha falsa em politicas.']);

  const quebrado = await rodarReligar(['--forcar', 'python quebrou'], { estado: ESTADO_CORTADO, pythonQuebra: 1 });
  assert.equal(quebrado.status, 0, quebrado.saida);
  assert.ok(quebrado.log.some(c => c[0] === 'services'));
  const [b] = quebrado.gravado.religadosForcados;
  assert.equal(b.resultado, 'nao-leu');
  assert.deepEqual(b.trava, ['a trava não rodou até o fim (saída 1)']);
});

test('religar: --forcar com a trava livre também registra, com o resultado livre', async ()=>{
  const r = await rodarReligar(['--folga', '5', '--forcar', 'por garantia'], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  const [registro] = r.gravado.religadosForcados;
  assert.equal(registro.resultado, 'livre');
  assert.equal(registro.motivo, 'por garantia');
  assert.equal(r.gravado.orcamentos['custta-projeto'].base, 89.2, 'a folga vale junto, em qualquer ordem');
});

test('religar: cada --forcar acrescenta ao registro, e religar sem ele não mexe no registro', async ()=>{
  const antes = { em: '2026-11-10T09:00:00.000Z', motivo: 'o primeiro', resultado: 'segura', trava: ['linha'] };
  const estado = { ...ESTADO_CORTADO, religadosForcados: [antes] };
  const motivo = 'aspas "duplas", acento e\nquebra de linha';
  const forcado = await rodarReligar(['--forcar', motivo], { estado, monitoring: SEGURA_1H });
  assert.equal(forcado.status, 0, forcado.saida);
  assert.equal(forcado.gravado.religadosForcados.length, 2);
  assert.deepEqual(forcado.gravado.religadosForcados[0], antes);
  assert.equal(forcado.gravado.religadosForcados[1].motivo, motivo, 'o motivo grava como veio');

  const normal = await rodarReligar([], { estado });
  assert.equal(normal.status, 0, normal.saida);
  assert.deepEqual(normal.gravado.religadosForcados, [antes]);

  const avulso = await rodarReligar(['--forcar', 'o segundo'], { estado: { ...ESTADO_CORTADO, religadosForcados: antes }, monitoring: SEGURA_1H });
  assert.equal(avulso.status, 0, avulso.saida);
  assert.deepEqual(avulso.gravado.religadosForcados.map(f => f.motivo), ['o primeiro', 'o segundo'], 'registro antigo fora de lista entra na lista, não some');
});

test('religar: --forcar sem conseguir gravar a base não religa nem deixa registro', async ()=>{
  const r = await rodarReligar(['--forcar', 'teste'], { estado: ESTADO_CORTADO, monitoring: SEGURA_1H, falhasCp: 2 });
  assert.equal(r.status, 1, r.saida);
  assert.equal(r.log.filter(c => c[1] === 'cp').length, 2, 'tentou gravar a base com o registro, duas vezes');
  assert.ok(!r.log.some(c => c[0] === 'services'));
  assert.equal(r.gravado, null);
});

test('religar: o registro do --forcar sobrevive às regravações da função, em todo caminho que regrava o estado', async ()=>{
  const forcados = [{ em: '2026-11-17T18:00:00.000Z', motivo: 'corte falso', resultado: 'segura', trava: ['Trava: linha'] }];
  const com = (orcamentos, resto = {}) => googleFalso({ estado: estadoCom(orcamentos, { religadosForcados: forcados, ...resto }) });
  const falhando = com({ projeto: noMes(10) });
  falhando.falhar['api-desligar'] = [new ErroHttp(403)];
  const casos = [
    ['maiorCusto sobe', com({ projeto: noMes(10) }), msgOrcamento(20)],
    ['orçamento desliga a API', com({ projeto: noMes(10) }), msgOrcamento(70)],
    ['alerta desliga a API', com({}), incidente('leituras', 'open')],
    ['falha ao desligar', falhando, msgOrcamento(70)],
    ['cobrança tirada', com({}), foraDe(100)],
    ['API já desligada encerra a falha', com({}, { primeiraFalha: T0 }), incidente('leituras', 'open')],
  ];
  casos[5][1].api = 'DISABLED';
  for(const [nome, g, corpo] of casos){
    await rodar(g, corpo);
    assert.ok(g.enviados.length > 0, `${nome}: o caso precisa regravar o estado`);
    for(const enviado of g.enviados) assert.deepEqual(enviado.religadosForcados, forcados, nome);
  }
});

test('religar: a recusa ensina o caminho do corte falso: subir o limiar e forçar com motivo', async ()=>{
  const segura = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: SEGURA_1H });
  assert.equal(segura.status, 3);
  assert.match(segura.saida, /suba o limiar da política e rode com --forcar "motivo"/);
  const semLeitura = await rodarReligar([], { estado: ESTADO_CORTADO, monitoring: { falhar: { serie: 503 } } });
  assert.equal(semLeitura.status, 4);
  assert.match(semLeitura.saida, /ou rode com --forcar "motivo"/);
});

test('religar: o projeto da cota troca por PROJETO_COTA; a política e a série seguem as do projeto alvo', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, env: { PROJETO_COTA: 'custta-corte' } });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.pedidos.length, 4);
  for(const p of r.pedidos){
    assert.equal(p.cota, 'custta-corte');
    assert.match(p.caminho, /^\/v3\/projects\/app-construcao-civil\//);
  }
});

test('religar: URL_MONITORING só aceita o Monitoring falso local, e AGORA só vale junto com ela', async ()=>{
  for(const env of [
    { URL_MONITORING: 'https://monitoring.googleapis.com' },
    { URL_MONITORING: 'http://localhost:8123' },
    { URL_MONITORING: 'http://127.0.0.1:8123/v3' },
    { URL_MONITORING: 'http://127.0.0.1.exemplo.com:80' },
    { URL_MONITORING: 'http://127.0.0.1:' },
    { URL_MONITORING: '', AGORA: '2026-11-17T23:00:00Z' },
  ]){
    const r = await rodarReligar([], { estado: ESTADO_CORTADO, env });
    assert.equal(r.status, 2, `${JSON.stringify(env)}: ${r.saida}`);
    assert.deepEqual(r.log, [], 'para antes de qualquer gcloud: nem o token sai');
    assert.deepEqual(r.pedidos, []);
    assert.match(r.saida, /só vale nos testes|só aceita http:\/\/127\.0\.0\.1:porta/);
  }
});

test('religar: a hora que a trava diz é honesta: nela passa e um minuto antes ainda segura', async ()=>{
  const casos = [
    [rajada('2026-11-17T17:55:00Z', 9, 500), AGORA, '17\\/11 20h55', '2026-11-17T23:55:00Z'],
    [[['2026-11-17T17:00:00Z', 600], ['2026-11-17T17:40:00Z', 500]], AGORA, '17\\/11 15h05', '2026-11-17T18:05:00Z'],
    [[['2026-11-17T17:30:30.123456789Z', 1000]], AGORA, '17\\/11 15h36', '2026-11-17T18:36:00Z'],
    [rajada('2026-11-18T00:50:00Z', 9, 500), '2026-11-18T01:00:00Z', '18\\/11 03h50', '2026-11-18T06:50:00Z'],
  ];
  for(const [leituras, agora, impressa, utc] of casos){
    const monitoring = { leituras };
    const r = await rodarReligar([], { estado: ESTADO_CORTADO, env: { AGORA: agora }, monitoring });
    assert.equal(r.status, 3, r.saida);
    assert.match(r.saida, new RegExp(`Religue a partir de ${impressa}, horário de Brasília: é o mínimo`), r.saida);
    const na = await rodarReligar([], { estado: ESTADO_CORTADO, env: { AGORA: utc }, monitoring });
    assert.equal(na.status, 0, `${utc}: ${na.saida}`);
    const antes = await rodarReligar([], { estado: ESTADO_CORTADO, env: { AGORA: semMs(Date.parse(utc) - MINUTO) }, monitoring });
    assert.equal(antes.status, 3, `um minuto antes de ${utc}: ${antes.saida}`);
  }
});

test('religar: sem a base de fusos, a hora sai em UTC-3 fixo, sem estourar', async ()=>{
  const r = await rodarReligar([], { estado: ESTADO_CORTADO, env: { PYTHONTZPATH: '/nao-existe' }, monitoring: { leituras: [['2026-11-17T17:30:00Z', 1000]] } });
  assert.equal(r.status, 3, r.saida);
  assert.equal(linhaDe(r, C1H), `- ${C1H}: 1.000 leituras em 1 h 05 min; segura com 1.000 ou mais; solta 17/11 15h35.`);
});

test('religar: nenhum limiar nem janela da política mora no script', ()=>{
  assert.doesNotMatch(readFileSync(path.join(PASTA_CORTE, 'religar.sh'), 'utf8'), /\b(2500|2000|6000|3600|21600)\b/);
});

test('religar: roda no Cloud Shell só com gcloud e python3, sem Node e só com a biblioteca padrão', ()=>{
  const texto = readFileSync(path.join(PASTA_CORTE, 'religar.sh'), 'utf8');
  assert.match(texto, /python3/);
  assert.doesNotMatch(texto, /\b(node|npm|npx|jq|curl|wget)\b/);
  const modulos = [...texto.matchAll(/^\s*(?:import\s+([\w., ]+?)\s*$|from\s+([\w.]+)\s+import\b)/gm)]
    .flatMap(m => (m[1] || m[2]).split(',').map(s => s.trim().split('.')[0]));
  assert.ok(modulos.includes('urllib'), 'a REST vai pelo urllib');
  for(const m of modulos) assert.ok(['datetime', 'json', 'os', 're', 'subprocess', 'sys', 'urllib', 'zoneinfo'].includes(m), m);
});

const envDe = chamada => Object.fromEntries(chamada.find(a => a.startsWith('--set-env-vars=')).slice('--set-env-vars='.length).split(',').map(p => p.split('=')));

test('implantar: sem argumento, sobe desarmada, com os parâmetros combinados', ()=>{
  const r = rodarScript('implantar.sh', []);
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.log.length, 1);
  const c = r.log[0];
  assert.deepEqual(c.slice(0, 3), ['functions', 'deploy', 'custta-corte']);
  const conta = 'custta-corte@custta-corte.iam.gserviceaccount.com';
  for(const flag of ['--gen2', '--runtime=nodejs22', '--region=us-central1', `--source=${PASTA_CORTE}`, '--entry-point=receber',
    '--trigger-topic=custta-corte', '--retry', `--service-account=${conta}`, `--trigger-service-account=${conta}`,
    '--no-allow-unauthenticated', '--timeout=300s', '--max-instances=3', '--project=custta-corte']) assert.ok(c.includes(flag), flag);
  assert.deepEqual(envDe(c), {
    ARMADO_API: 'false', ARMADO_COBRANCA: 'false', MODO_CORTE: 'dois-tempos', PROJETO_ALVO: 'app-construcao-civil', BUCKET_ESTADO: 'custta-corte-estado',
    ORCAMENTO_PROJETO: 'custta-projeto', ORCAMENTO_FORA_FIRESTORE: 'custta-fora-firestore', POLITICA_ALERTA: 'custta-leituras',
  });
});

test('implantar: cada interruptor arma só pelo próprio argumento', ()=>{
  const so = args => { const r = rodarScript('implantar.sh', args); assert.equal(r.status, 0, r.saida); const e = envDe(r.log[0]); return [e.ARMADO_API, e.ARMADO_COBRANCA]; };
  assert.deepEqual(so(['--armar-api']), ['true', 'false']);
  assert.deepEqual(so(['--armar-cobranca']), ['false', 'true']);
  assert.deepEqual(so(['--armar-api', '--armar-cobranca']), ['true', 'true']);
});

test('implantar: --modo-oficial passa MODO_CORTE=oficial; sem ele, dois-tempos', ()=>{
  const env = (args, ambiente) => { const r = rodarScript('implantar.sh', args, { env: ambiente }); assert.equal(r.status, 0, r.saida); return envDe(r.log[0]); };
  assert.equal(env(['--modo-oficial']).MODO_CORTE, 'oficial');
  assert.equal(env(['--armar-cobranca', '--modo-oficial']).MODO_CORTE, 'oficial');
  assert.equal(env(['--armar-api', '--armar-cobranca']).MODO_CORTE, 'dois-tempos');
  assert.equal(env([], { MODO_CORTE: 'oficial' }).MODO_CORTE, 'dois-tempos', 'só o argumento muda o modo');
  const desarmada = env(['--modo-oficial']);
  assert.deepEqual([desarmada.ARMADO_API, desarmada.ARMADO_COBRANCA], ['false', 'false'], 'o modo não arma nada');
});

test('implantar: argumento desconhecido para antes do gcloud', ()=>{
  for(const args of [['--armar'], ['true'], ['--armar-api', 'x'], ['--modo'], ['--modo-oficial', 'x']]){
    const r = rodarScript('implantar.sh', args);
    assert.notEqual(r.status, 0, args.join(' '));
    assert.deepEqual(r.log, [], args.join(' '));
  }
});

test('implantar: projetos e nomes trocam por ambiente, para o projeto descartável', ()=>{
  const r = rodarScript('implantar.sh', [], { env: { PROJETO_FUNCAO: 'corte-teste', PROJETO_ALVO: 'descartavel', BUCKET_ESTADO: 'balde' } });
  assert.equal(r.status, 0, r.saida);
  assert.ok(r.log[0].includes('--project=corte-teste'));
  assert.ok(r.log[0].includes('--service-account=custta-corte@corte-teste.iam.gserviceaccount.com'));
  assert.equal(envDe(r.log[0]).PROJETO_ALVO, 'descartavel');
  assert.equal(envDe(r.log[0]).BUCKET_ESTADO, 'balde');
});
