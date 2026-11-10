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

test('cenário 10: alerta closed ou de outra política não faz nada', async ()=>{
  for(const corpo of [incidente('leituras', 'closed'), incidente('outra', 'open')]){
    const g = googleFalso();
    const r = await rodar(g, corpo);
    assert.equal(r.erro, null);
    assert.deepEqual(g.chamadas, [], JSON.stringify(corpo));
    assert.equal(passagemUnica(r).fez, 'nada');
  }
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
const { spawnSync } = require('node:child_process');
const { mkdtempSync, writeFileSync, readFileSync, chmodSync, existsSync } = require('node:fs');
const { tmpdir } = require('node:os');
const path = require('node:path');

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
  *) echo "gcloud falso: chamada inesperada: $*" >&2; exit 99;;
esac
`;

function rodarScript(nome, args, { estado = '{}', falhasCp = 0, env = {}, semObjeto = false, falhaEnable = false } = {}){
  const dir = mkdtempSync(path.join(tmpdir(), 'corte-gcloud-'));
  writeFileSync(path.join(dir, 'gcloud'), GCLOUD_FALSO);
  chmodSync(path.join(dir, 'gcloud'), 0o755);
  writeFileSync(path.join(dir, 'estado.json'), typeof estado === 'string' ? estado : JSON.stringify(estado));
  writeFileSync(path.join(dir, 'falhas-cp'), String(falhasCp));
  if(semObjeto) writeFileSync(path.join(dir, 'sem-objeto'), '');
  if(falhaEnable) writeFileSync(path.join(dir, 'falha-enable'), '');
  const r = spawnSync('bash', [path.join(PASTA_CORTE, nome), ...args], {
    encoding: 'utf8', cwd: tmpdir(), env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, GCLOUD_DIR: dir, ...env },
  });
  const arquivoLog = path.join(dir, 'log'), gravado = path.join(dir, 'gravado.json');
  return {
    status: r.status, saida: r.stdout + r.stderr,
    log: existsSync(arquivoLog) ? readFileSync(arquivoLog, 'utf8').split('\n').filter(Boolean).map(l => l.split('|')) : [],
    gravado: existsSync(gravado) ? JSON.parse(readFileSync(gravado, 'utf8')) : null,
  };
}
const ESTADO_CORTADO = {
  orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 0, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 3, maiorCusto: 12.5 } },
  primeiraFalha: '2026-11-09T12:00:00.000Z', apiDesligadaEm: '2026-11-09T13:00:00.000Z', cobrancaTiradaEm: '2026-11-09T14:00:00.000Z',
};
const OBJETO_GS = 'gs://custta-corte-estado/estado.json';
const nomeDe = chamada => chamada.slice(0, 3).join(' ');

test('religar: lê a geração, depois o conteúdo, grava condicionado e só então religa', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.log.map(nomeDe), [
    `storage objects describe`, `storage cat ${OBJETO_GS}`, `storage cp ${r.log[2][2]}`, 'services enable firestore.googleapis.com',
  ]);
  assert.deepEqual(r.log[0].slice(3), [OBJETO_GS, '--format=value(generation)']);
  assert.deepEqual(r.log[2].slice(3), [OBJETO_GS, '--if-generation-match=7']);
  assert.deepEqual(r.log[3], ['services', 'enable', 'firestore.googleapis.com', '--project', 'app-construcao-civil']);
});

test('religar: com a cobrança tirada, base vira o maiorCusto nos dois orçamentos e os três registros zeram', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.gravado, {
    orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 84.2, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 12.5, maiorCusto: 12.5 } },
    primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null,
  });
});

test('religar: sem cobrança tirada, o orçamento de fora do Firestore não muda, com folga ou sem', ()=>{
  const estado = { ...ESTADO_CORTADO, cobrancaTiradaEm: null };
  for(const args of [[], ['--folga', '15']]){
    const r = rodarScript('religar.sh', args, { estado });
    assert.equal(r.status, 0, r.saida);
    assert.deepEqual(r.gravado.orcamentos['custta-fora-firestore'], ESTADO_CORTADO.orcamentos['custta-fora-firestore'], args.join(' '));
    assert.equal(r.gravado.primeiraFalha, null);
    assert.equal(r.gravado.apiDesligadaEm, null);
    assert.equal(r.gravado.cobrancaTiradaEm, null);
  }
});

test('religar: --folga soma só à base do orçamento do projeto, sem ruído de ponto flutuante', ()=>{
  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.gravado.orcamentos['custta-projeto'].base, 99.2);
  assert.equal(r.gravado.orcamentos['custta-fora-firestore'].base, 12.5, 'fora do Firestore nunca leva folga');
  const fino = rodarScript('religar.sh', ['--folga', '0.1'], { estado: { orcamentos: { 'custta-projeto': noMes(0.2) } } });
  assert.equal(fino.gravado.orcamentos['custta-projeto'].base, 0.3);
});

test('religar: os nomes dos orçamentos trocam por ambiente; orçamento de outro nome não muda', ()=>{
  const outro = noMes(50, 1);
  const estado = { orcamentos: { p: noMes(10), f: noMes(20), 'custta-projeto': outro }, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' };
  const r = rodarScript('religar.sh', ['--folga', '5'], { estado, env: { ORCAMENTO_PROJETO: 'p', ORCAMENTO_FORA_FIRESTORE: 'f' } });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.gravado.orcamentos, { p: noMes(10, 15), f: noMes(20, 20), 'custta-projeto': outro });
});

const emReais = v => `R$ ${v.toFixed(2).replace('.', ',')}`;

test('religar: termina dizendo em quanto cada corte volta, calculado da base gravada', ()=>{
  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: ESTADO_CORTADO });
  assert.equal(r.status, 0, r.saida);
  const fim = r.saida.trim().split('\n').slice(-2);
  assert.deepEqual(fim, ['API cai de novo em R$ 159,20', 'cobrança cai em R$ 112,50']);
  /* Os limites vivem em regra.js e o script, sem Node, repete os dois: mudar lá sem mudar aqui quebra. */
  const { 'custta-projeto': projeto, 'custta-fora-firestore': fora } = r.gravado.orcamentos;
  assert.deepEqual(fim, [`API cai de novo em ${emReais(projeto.base + regra.LIMITE_API / 100)}`, `cobrança cai em ${emReais(fora.base + regra.LIMITE_COBRANCA / 100)}`]);
});

test('religar: sem cobrança tirada, não fala de cobrança', ()=>{
  const r = rodarScript('religar.sh', [], { estado: { ...ESTADO_CORTADO, cobrancaTiradaEm: null } });
  assert.equal(r.status, 0, r.saida);
  assert.match(r.saida, /API cai de novo em R\$ 144,20\n$/);
  assert.doesNotMatch(r.saida, /cobrança cai/);
});

test('religar: sem registro dos orçamentos, a API cai no limite cheio e a cobrança não muda', ()=>{
  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: { orcamentos: {}, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' } });
  assert.equal(r.status, 0, r.saida);
  assert.match(r.saida, /API cai de novo em R\$ 60,00\n$/);
  assert.doesNotMatch(r.saida, /cobrança cai/);
  assert.equal(r.gravado.cobrancaTiradaEm, null);
});

test('religar: argumento errado para antes de qualquer gcloud', ()=>{
  for(const args of [['--folga', 'abc'], ['--folga', '-5'], ['--folga'], ['--folga', '1.2.3'], ['--outro']]){
    const r = rodarScript('religar.sh', args, { estado: ESTADO_CORTADO });
    assert.notEqual(r.status, 0, args.join(' '));
    assert.deepEqual(r.log, [], args.join(' '));
  }
});

test('religar: conflito na gravação tenta uma vez de novo, relendo tudo', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhasCp: 1 });
  assert.equal(r.status, 0, r.saida);
  assert.deepEqual(r.log.map(c => c.slice(0, 2).join(' ')), [
    'storage objects', 'storage cat', 'storage cp', 'storage objects', 'storage cat', 'storage cp', 'services enable',
  ]);
  assert.equal(r.saida.match(/API cai de novo/g).length, 1, 'o que vale agora sai uma vez só');
});

test('religar: sem conseguir gravar a base, não religa a API', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhasCp: 2 });
  assert.notEqual(r.status, 0);
  assert.ok(!r.log.some(c => c[0] === 'services'), 'a base grava antes de religar');
  assert.equal(r.log.filter(c => c[1] === 'cp').length, 2);
});

test('religar: estado.json ausente ou ilegível para sem gravar nem religar', ()=>{
  const sem = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, semObjeto: true });
  assert.notEqual(sem.status, 0);
  assert.ok(!sem.log.some(c => c[1] === 'cp' || c[0] === 'services'));
  const ruim = rodarScript('religar.sh', [], { estado: 'não é json' });
  assert.notEqual(ruim.status, 0);
  assert.ok(!ruim.log.some(c => c[1] === 'cp' || c[0] === 'services'));
});

test('religar: falha ao religar aparece no código de saída', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhaEnable: true });
  assert.notEqual(r.status, 0);
  assert.ok(r.gravado, 'a base já está gravada: repetir o script é seguro');
  assert.doesNotMatch(r.saida, /API cai de novo/);
});

test('religar: projeto e bucket trocam por ambiente, para o projeto descartável', ()=>{
  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, env: { PROJETO_ALVO: 'descartavel', BUCKET_ESTADO: 'balde' } });
  assert.equal(r.status, 0, r.saida);
  assert.equal(r.log[1][2], 'gs://balde/estado.json');
  assert.deepEqual(r.log[3], ['services', 'enable', 'firestore.googleapis.com', '--project', 'descartavel']);
});

test('religar: roda no Cloud Shell só com gcloud e python3, sem Node', ()=>{
  const texto = readFileSync(path.join(PASTA_CORTE, 'religar.sh'), 'utf8');
  assert.match(texto, /python3/);
  assert.doesNotMatch(texto, /\b(node|npm|npx|jq)\b/);
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
    '--no-allow-unauthenticated', '--timeout=300s', '--project=custta-corte']) assert.ok(c.includes(flag), flag);
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
