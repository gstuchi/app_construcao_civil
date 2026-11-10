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
    if(rotulo === 'estado-ler') return { status: 200, data: JSON.stringify(g.estado) };
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
