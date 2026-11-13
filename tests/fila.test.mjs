/* Fila de escrita do cloud.js: tentativa automática, backoff, falha terminal e
   logout que não descarta trabalho. Roda sem browser e sem rede — o SDK do
   Firebase é desviado pro duplê em helpers/ por um loader de módulo. */
import { test, before, beforeEach } from 'node:test';
import assert from 'node:assert';
import { register } from 'node:module';
import { createRequire } from 'node:module';

register('./helpers/loader-firebase.mjs', import.meta.url);

const require = createRequire(import.meta.url);
const CALC = require('../calc.js');

let CLOUD, ctrl, eventos;
/* Sessão do navegador (sessionStorage) e recargas da página: valem para o teste
   inteiro, e cada abreSessao é uma página nova na mesma sessão. */
let sessao, recargas;
function armazem(){
  const m = new Map();
  return {
    falha: false, // true: setItem lança, como armazenamento cheio ou bloqueado
    getItem: k => (m.has(k) ? m.get(k) : null),
    setItem(k, v){ if(this.falha) throw new Error('QuotaExceededError'); m.set(k, String(v)); },
    removeItem: k => { m.delete(k); },
  };
}

/* cloud.js é escrito pro browser: precisa de window, navigator e CustomEvent. */
function montaJanela(){
  eventos = [];
  const alvo = new EventTarget();
  globalThis.window = {
    addEventListener: alvo.addEventListener.bind(alvo),
    removeEventListener: alvo.removeEventListener.bind(alvo),
    dispatchEvent: e => { eventos.push({ tipo: e.type, detail: e.detail }); return alvo.dispatchEvent(e); },
    OBRA_CALC: CALC,
    sessionStorage: sessao,
    location: { reload(){ recargas++; } },
  };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value: { onLine: true }, configurable: true, writable: true });
}

const estados = () => eventos.filter(e => e.tipo === 'cloud-estado').map(e => e.detail.estado);
const ultimoEstado = () => estados()[estados().length - 1];
const espera = () => new Promise(r => setImmediate(r));

before(async () => {
  sessao = armazem(); recargas = 0;
  montaJanela();
  const mod = await import('../cloud.js');
  void mod;
  CLOUD = globalThis.window.CLOUD;
  ctrl = (await import('./helpers/firebase-stub.mjs')).__ctrl;
  assert.ok(CLOUD, 'cloud.js precisa expor window.CLOUD');
});

/* Sessão nova a cada teste. Por padrão a conta já viu os dados (snapshot do
   servidor), como depois de abrir o app com rede; só os testes da guarda de
   carregamento partem de antes disso. */
const doServidor = { data: () => ({ obras: [], config: {} }), metadata: { fromCache: false, hasPendingWrites: false } };
async function abreSessao({ carregada = true } = {}){
  if(ctrl) ctrl.morto = null; // página nova, SDK novo
  montaJanela();
  await import('../cloud.js?teste=' + Math.random());
  CLOUD = globalThis.window.CLOUD;
  await CLOUD.ready;
  if(carregada){ CLOUD.watchDados(() => {}); ctrl.snapshotCb(doServidor); }
  ctrl.setDocChamadas.length = 0;
  ctrl.respostas.length = 0;
  ctrl.signOutChamado = 0;
  eventos.length = 0;
  globalThis.navigator.onLine = true;
  ctrl.pendentesSDK = Promise.resolve();
  ctrl.token = Promise.resolve('token-teste');
}
beforeEach(() => { sessao = armazem(); recargas = 0; return abreSessao(); });

/* O backoff começa em 1s. Escritas são entregues ao SDK imediatamente. */
const passa = ms => new Promise(r => setTimeout(r, ms));

test('escrita que dá certo resolve a promise e volta pra ocioso', async () => {
  const p = CLOUD.saveDados({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } });
  await passa(400);
  await p; // rejeita o teste se nunca resolver
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('falha de rede não resolve na hora: reagenda e sobe na tentativa seguinte', async () => {
  ctrl.respostas.push({ code: 'unavailable' });
  const p = CLOUD.saveDados({ obras: [], config: {} });
  await passa(400);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'primeira tentativa saiu');
  assert.ok(estados().includes('repetindo'), 'estado repetindo foi publicado: ' + estados());

  await passa(1200); // backoff da 1ª falha = 1s
  await p;
  assert.strictEqual(ctrl.setDocChamadas.length, 2, 'tentou de novo sozinho');
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('falha terminal rejeita a promise, para o backoff e segura o dado', async () => {
  ctrl.respostas.push({ code: 'permission-denied' });
  const p = CLOUD.saveDados({ obras: [], config: {} });
  await passa(400);
  await assert.rejects(p, err => err.code === 'permission-denied');
  assert.strictEqual(ultimoEstado(), 'erro');
  assert.ok(CLOUD.temPendencia(), 'o dado não subiu, então continua guardado');

  await passa(1500);
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'não fica martelando o servidor');

  // e "Tentar de novo" reaproveita o blob guardado
  await CLOUD.tentarDeNovo();
  assert.strictEqual(ctrl.setDocChamadas.length, 2);
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('offline entrega todas as versões ao SDK antes de qualquer confirmação', async () => {
  globalThis.navigator.onLine = false;
  let confirmaPrimeira, confirmaSegunda;
  ctrl.respostas.push(new Promise(r => { confirmaPrimeira = r; }), new Promise(r => { confirmaSegunda = r; }));
  const p1 = CLOUD.saveDados({ obras: [{ id: 'primeira' }], config: {} });
  const p2 = CLOUD.saveDados({ obras: [{ id: 'segunda' }], config: {} });
  assert.strictEqual(ctrl.setDocChamadas.length, 2, 'última alteração também chega ao cache sem esperar rede');
  assert.strictEqual(ctrl.setDocChamadas[1].dados.obras[0].id, 'segunda');
  assert.strictEqual(ultimoEstado(), 'offline');

  globalThis.navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  assert.strictEqual(ultimoEstado(), 'salvando');
  confirmaPrimeira();
  await espera();
  assert.ok(CLOUD.temPendencia(), 'confirmação antiga não encerra a versão nova');
  confirmaSegunda();
  await Promise.all([p1, p2]);
  assert.strictEqual(ultimoEstado(), 'ocioso');
});

test('logout com pendência que não sobe recusa com code pendente', async () => {
  ctrl.respostas.push({ code: 'permission-denied' });
  CLOUD.saveDados({ obras: [], config: {} });
  await passa(400);
  assert.ok(CLOUD.temPendencia());

  ctrl.respostas.push({ code: 'permission-denied' });
  await assert.rejects(() => CLOUD.logout(), err => err.code === 'pendente');
  assert.strictEqual(ctrl.signOutChamado, 0, 'não sai enquanto tem trabalho não salvo');

  await CLOUD.tentarDeNovo();
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1, 'sai depois de recuperar a escrita');
  assert.strictEqual(CLOUD.temPendencia(), false);
});

test('logout normal sobe o pendente antes de sair', async () => {
  CLOUD.saveDados({ obras: [], config: {} });
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1);
  assert.ok(ctrl.setDocChamadas.length >= 1, 'o que estava na fila subiu antes do signOut');
});

test('erro de leitura do onSnapshot vira estado de erro visível', async () => {
  const parar = CLOUD.watchDados(() => {});
  assert.ok(ctrl.snapshotErroCb, 'watchDados precisa passar callback de erro pro onSnapshot');
  ctrl.snapshotErroCb({ code: 'permission-denied' });
  const leitura = eventos.filter(e => e.tipo === 'cloud-estado' && e.detail.origem === 'leitura');
  assert.strictEqual(leitura.length, 1);
  assert.strictEqual(leitura[0].detail.estado, 'erro');
  parar();
});

test('logout espera escrita em voo e só depois desativa push e sai', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r => { confirma = r; }));
  const p = CLOUD.saveDados({ obras: [], config: {} });
  let push = false;
  const saida = CLOUD.logout({ antesDeSair: async()=>{ push = true; } });
  await espera();
  assert.strictEqual(ctrl.signOutChamado, 0);
  assert.strictEqual(push, false);
  await assert.rejects(CLOUD.saveDados({ obras: [], config: {} }), { code: 'cancelled' });
  confirma();
  await Promise.all([p, saida]);
  assert.strictEqual(push, true);
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout espera fila do SDK recuperada de sessão anterior', async () => {
  let confirma;
  ctrl.pendentesSDK = new Promise(r => { confirma = r; });
  const saida = CLOUD.logout();
  await espera();
  assert.strictEqual(ctrl.signOutChamado, 0);
  confirma();
  await saida;
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('timeout de logout mantém sessão e permite confirmação posterior', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r=>{ confirma = r; }));
  const p = CLOUD.saveDados({ obras: [], config: {} });
  await assert.rejects(CLOUD.logout(), { code: 'pendente' });
  assert.strictEqual(ctrl.signOutChamado, 0);
  assert.ok(CLOUD.temPendencia());
  confirma();
  await p;
  await CLOUD.logout();
  assert.strictEqual(ctrl.signOutChamado, 1);
});

test('logout offline não descarta dados nem com opção forcar', async () => {
  navigator.onLine = false;
  await assert.rejects(CLOUD.logout({ forcar: true }), { code: 'pendente' });
  assert.strictEqual(ctrl.signOutChamado, 0);
});

test('snapshot pendente recuperado é entregue para restaurar a tela', async () => {
  let recebido;
  CLOUD.watchDados((blob, meta) => { recebido = { blob, meta }; });
  ctrl.snapshotCb({ data:()=>({ obras: [{ id: 'recuperada' }] }), metadata: { fromCache: true, hasPendingWrites: true } });
  assert.strictEqual(recebido.blob.obras[0].id, 'recuperada');
  assert.strictEqual(recebido.meta.localDirty, false);
  assert.ok(CLOUD.temPendencia());
  ctrl.snapshotCb({ data:()=>({ obras: [] }), metadata: { fromCache: false, hasPendingWrites: false } });
});

test('troca de conta invalida callbacks antigos e não envia blob para outra pessoa', async () => {
  let rejeita;
  ctrl.respostas.push(new Promise((_r, reject) => { rejeita = reject; }));
  const p = CLOUD.saveDados({ obras: [{ id: 'privada' }], config: {} });
  ctrl.authCb({ uid: 'outra', email: 'outra@exemplo.com' });
  await assert.rejects(p, { code: 'cancelled' });
  rejeita({ code: 'unavailable' });
  await espera();
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
  assert.strictEqual(ctrl.setDocChamadas[0].ref.path, 'dados/u-teste');
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
});

test('erro de leitura resiste a escrita e rede; retry recria assinatura', async () => {
  const parar = CLOUD.watchDados(()=>{});
  const antiga = ctrl.snapshotCb;
  ctrl.snapshotErroCb({ code:'permission-denied' });
  await CLOUD.saveDados({ obras:[], config:{} });
  assert.equal(CLOUD.estado(), 'erro', 'ack de escrita não esconde falha de leitura');
  window.dispatchEvent(new Event('online'));
  assert.equal(CLOUD.estado(), 'erro');
  const pronta = CLOUD.tentarDeNovo();
  assert.notEqual(ctrl.snapshotCb, antiga);
  ctrl.snapshotCb({ data:()=>({ obras:[] }), metadata:{ fromCache:false, hasPendingWrites:false } });
  await pronta;
  assert.equal(CLOUD.estado(), 'ocioso');
  parar();
});

test('limite invalida ack anterior e impede retry de enviar blob grande', async () => {
  let confirma;
  ctrl.respostas.push(new Promise(r=>{ confirma=r; }));
  const primeiro = CLOUD.saveDados({ obras:[], config:{} });
  const grande = CLOUD.saveDados({ obras:[], config:{ texto:'x'.repeat(900001) } });
  await assert.rejects(grande, { code:'limite' });
  await assert.rejects(primeiro, { code:'limite' });
  confirma(); await espera();
  assert.equal(CLOUD.estado(), 'erro');
  await assert.rejects(CLOUD.tentarDeNovo(), { code:'limite' });
  assert.equal(ctrl.setDocChamadas.length, 1);
  await CLOUD.saveDados({ obras:[], config:{} });
  assert.equal(CLOUD.estado(), 'ocioso');
});

test('refresh com falha de rede mantém sessão; credencial inválida encerra', async()=>{
  ctrl.token = Promise.reject({ code:'auth/network-request-failed' });
  assert.equal(await CLOUD.verificarSessao(true), false);
  assert.equal(ctrl.signOutChamado, 0);
  ctrl.token = Promise.reject({ code:'auth/invalid-refresh-token' });
  assert.equal(await CLOUD.verificarSessao(true), false);
  assert.equal(ctrl.signOutChamado, 1);
});

test('refresh antigo não encerra usuário que entrou depois', async()=>{
  let rejeita;
  ctrl.token = new Promise((_r,r)=>{ rejeita=r; });
  const verificou = CLOUD.verificarSessao(true);
  ctrl.authCb({ uid:'outra', email:'outra@exemplo.com' });
  rejeita({ code:'auth/invalid-refresh-token' });
  await verificou;
  assert.equal(ctrl.signOutChamado, 0);
  ctrl.authCb({ uid:'u-teste', email:'teste@exemplo.com' });
});

/* Quem não viu os dados não grava. Num aparelho novo sem rede o primeiro snapshot
   vem do cache, sem documento; gravar ali reescreveria o documento inteiro por cima
   das obras que só o servidor tem. Conta como visto: snapshot do servidor (com ou
   sem documento; conta nova de verdade recebe "não existe" dele) ou do cache com
   o documento. */
const semDocumento = doCache => ({ data: () => undefined, metadata: { fromCache: doCache, hasPendingWrites: false } });
const comDocumento = doCache => ({ data: () => ({ obras: [{ id: 'so-no-servidor' }], config: {} }), metadata: { fromCache: doCache, hasPendingWrites: false } });
const recusouSemErroDeSincronizacao = async p => {
  await assert.rejects(p, { code: 'nao-carregado' });
  assert.strictEqual(ctrl.setDocChamadas.length, 0, 'nada vai para a fila do SDK');
  assert.strictEqual(CLOUD.temPendencia(), false);
  assert.ok(!estados().includes('erro'), 'recusa não é erro de sincronização: ' + estados());
  assert.deepStrictEqual(eventos.filter(e => e.tipo === 'cloud-erro').map(e => e.detail),
    [{ code: 'nao-carregado', terminal: false }], 'a tela precisa saber o motivo');
};

for(const [abertura, chega, grava] of [
  ['sem snapshot nenhum', null, false],
  ['com o cache sem documento', semDocumento(true), false],
  ['com o cache com documento', comDocumento(true), true],
  ['com o servidor sem documento (conta nova)', semDocumento(false), true],
  ['com o servidor com documento', comDocumento(false), true],
]){
  test(`abertura ${abertura}: ${grava ? 'grava' : 'recusa com nao-carregado'}`, async () => {
    await abreSessao({ carregada: false });
    CLOUD.watchDados(() => {});
    if(chega) ctrl.snapshotCb(chega);
    eventos.length = 0;
    const p = CLOUD.saveDados({ obras: [{ id: 'nova' }], config: {} });
    if(!grava) return recusouSemErroDeSincronizacao(p);
    await p;
    assert.strictEqual(ctrl.setDocChamadas.length, 1);
  });
}

test('depois de ver os dados, snapshot do cache sem documento não volta a recusar', async () => {
  // conta nova que já ouviu "não existe" do servidor e então perdeu a rede
  await abreSessao({ carregada: false });
  CLOUD.watchDados(() => {});
  ctrl.snapshotCb(semDocumento(false));
  ctrl.snapshotCb(semDocumento(true));
  await CLOUD.saveDados({ obras: [{ id: 'nova' }], config: {} });
  assert.strictEqual(ctrl.setDocChamadas.length, 1);
});

test('troca de conta volta a exigir os dados da conta que entrou', async () => {
  ctrl.authCb({ uid: 'outra', email: 'outra@exemplo.com' });
  await espera();
  eventos.length = 0;
  await recusouSemErroDeSincronizacao(CLOUD.saveDados({ obras: [], config: {} }));
  ctrl.authCb({ uid: 'u-teste', email: 'teste@exemplo.com' });
});

/* ---------- cliente do Firestore morto ----------
   Depois de uma quebra interna o SDK web lança INTERNAL ASSERTION FAILED (b815) em
   toda operação, na hora, até a página recarregar, e o code chega vazio: o que se
   grava depois disso fica só na memória. O duplê imita com ctrl.morto. */
const B815 = 'FIRESTORE (12.18.0) INTERNAL ASSERTION FAILED: Unexpected state (ID: b815) CONTEXT: '
  + '{"el":"TypeError: Cannot read properties of undefined (reading \'batchId\')"}';
const morre = (extra = {}) => { ctrl.morto = Object.assign(new Error(B815), extra); };
const blobCom = descricao => ({ obras: [{ id: 'o1', nome: 'Obra', fase: 'construcao', dataInicio: '2026-11-01',
  gastos: [{ id: 'g1', valor: 10, topico: 'estrutura', descricao, data: '2026-11-13', pagamento: 'pix' }] }],
  config: { taxaMensal: 1, topicosCustom: [] } });
const erroNaJanela = () => window.dispatchEvent(Object.assign(new Event('error'), { error: new Error(B815), message: 'Uncaught Error: ' + B815 }));
/* Página nova na mesma sessão: devolve a cópia que a abertura oferece à tela. */
async function reabre(){
  await abreSessao({ carregada: false });
  let oferecida = null;
  CLOUD.watchDados((_blob, meta) => { if(meta.copia) oferecida = meta.copia; });
  ctrl.snapshotCb(doServidor);
  return oferecida;
}
/* true quando a página pede confirmação antes de sair. */
function seguraSaida(){
  const e = new Event('beforeunload', { cancelable: true });
  Object.defineProperty(e, 'returnValue', { value: undefined, writable: true });
  window.dispatchEvent(e);
  return e.defaultPrevented;
}

test('cliente morto: a gravação vai para a cópia e a página recarrega uma vez, sem tentar de novo', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('depois da morte')).catch(() => {});
  await passa(1500);
  assert.strictEqual(recargas, 1, 'a página não recarregou');
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'tentou de novo com o cliente morto');
  assert.ok(!estados().includes('repetindo'), 'voltou a dizer "Salvando…": ' + estados());
  assert.deepStrictEqual(await reabre(), blobCom('depois da morte'), 'a página nova não recebeu a cópia');
});

test('cliente morto: a mensagem decide, não o code', { timeout: 8000 }, async () => {
  morre({ code: 'unavailable' });
  CLOUD.saveDados(blobCom('com code de rede')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 1, 'com code de rede não foi tratado como cliente morto');
});

test('o TypeError que antecede a quebra não é cliente morto: segue o backoff', { timeout: 8000 }, async () => {
  ctrl.respostas.push(Promise.reject(new TypeError("Cannot read properties of undefined (reading 'batchId')")));
  CLOUD.saveDados(blobCom('x')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 0);
  assert.ok(estados().includes('repetindo'), estados());
  await passa(1100); // a nova tentativa sobe: nenhum backoff fica agendado para o teste seguinte
});

test('duas detecções seguidas valem uma: recarrega uma vez e não arma o aviso de saída', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('primeira')).catch(() => {});
  await passa(20);
  erroNaJanela();
  CLOUD.saveDados(blobCom('segunda')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 1);
  assert.ok(!estados().includes('erro'), 'publicou erro durante a recarga: ' + estados());
  assert.strictEqual(seguraSaida(), false, 'armou o aviso de saída e travaria a recarga');
  assert.deepStrictEqual(await reabre(), blobCom('segunda'), 'a cópia não ficou com a última versão');
});

test('morto sem nada só na memória não recarrega; a gravação seguinte guarda e recarrega', { timeout: 8000 }, async () => {
  morre();
  erroNaJanela();
  await passa(20);
  assert.strictEqual(recargas, 0, 'recarregou sem nada a salvar e derrubaria o formulário aberto');
  assert.deepStrictEqual(estados(), [], 'a tela mudou sem nada a dizer');
  CLOUD.saveDados(blobCom('depois')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 1);
  assert.strictEqual(ctrl.setDocChamadas.length, 0, 'tentou gravar no cliente que já se sabia morto');
  assert.ok(!estados().includes('salvando'), 'disse "Salvando…" com o cliente sabidamente morto: ' + estados());
  assert.deepStrictEqual(await reabre(), blobCom('depois'));
});

test('a quebra vista numa promessa ou na leitura também marca o cliente morto', { timeout: 8000 }, async () => {
  for(const [nome, avisa] of [
    ['promessa', () => window.dispatchEvent(Object.assign(new Event('unhandledrejection'), { reason: new Error(B815) }))],
    ['leitura', () => ctrl.snapshotErroCb(new Error(B815))],
  ]){
    sessao = armazem(); recargas = 0;
    await abreSessao();
    morre();
    avisa();
    assert.ok(!estados().includes('erro'), `${nome}: a quebra virou erro de sincronização: ${estados()}`);
    CLOUD.saveDados(blobCom('x')).catch(() => {});
    await passa(20);
    assert.strictEqual(ctrl.setDocChamadas.length, 0, `${nome}: não reconheceu a quebra`);
    assert.strictEqual(recargas, 1, nome);
  }
});

test('segunda morte na mesma sessão: não recarrega, avisa, segura a saída e o toque recarrega', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('primeira')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 1);
  assert.deepStrictEqual(await reabre(), blobCom('primeira'));
  await CLOUD.saveDados(blobCom('primeira')); // a tela reaplica e o servidor confirma
  morre();
  eventos.length = 0;
  await assert.rejects(CLOUD.saveDados(blobCom('segunda')), { code: 'cliente-morto' });
  assert.strictEqual(recargas, 1, 'recarregou de novo: laço');
  assert.strictEqual(ultimoEstado(), 'erro');
  assert.ok(eventos.some(e => e.tipo === 'cloud-erro' && e.detail.code === 'cliente-morto' && e.detail.terminal),
    'a tela não foi avisada');
  assert.ok(eventos.some(e => e.tipo === 'cloud-estado' && e.detail.estado === 'erro' && e.detail.code === 'cliente-morto'),
    'o estado de erro saiu sem o code cliente-morto');
  assert.strictEqual(CLOUD.clienteMorto(), true);
  assert.strictEqual(seguraSaida(), true, 'fechar com lançamento só na memória não pede confirmação');
  window.dispatchEvent(new Event('online'));
  window.dispatchEvent(new Event('offline'));
  ctrl.snapshotErroCb(Object.assign(new Error('Missing or insufficient permissions.'), { code: 'permission-denied' }));
  assert.strictEqual(ultimoEstado(), 'erro', 'rede ou leitura tirou o aviso');
  assert.strictEqual(CLOUD.clienteMorto(), true, 'rede ou leitura tirou o aviso');
  assert.strictEqual(CLOUD.recarregar(), true);
  assert.strictEqual(recargas, 2, 'o toque não recarregou');
  assert.strictEqual(seguraSaida(), false, 'a recarga pedida pelo toque perguntaria se pode sair');
  assert.deepStrictEqual(await reabre(), blobCom('segunda'));
});

test('sem onde guardar a cópia não recarrega: a recarga apagaria o lançamento', { timeout: 8000 }, async () => {
  sessao.falha = true;
  morre();
  await assert.rejects(CLOUD.saveDados(blobCom('sem onde guardar')), { code: 'cliente-morto' });
  assert.strictEqual(recargas, 0);
  assert.strictEqual(CLOUD.clienteMorto(), true);
  assert.strictEqual(seguraSaida(), true);
  assert.strictEqual(CLOUD.recarregar(), false, 'o toque recarregaria sem a cópia');
  assert.strictEqual(recargas, 0);
  ctrl.authCb(null); // a conta sai: o aviso não passa para a próxima
  await espera();
  assert.strictEqual(CLOUD.clienteMorto(), false, 'o aviso da conta que saiu ficou para a próxima');
});

test('na abertura a cópia vem para a tela só quando a conta foi vista, e sai quando o servidor confirma', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('guardado')).catch(() => {});
  await passa(20);
  await abreSessao({ carregada: false });
  const ofertas = [];
  CLOUD.watchDados((_blob, meta) => ofertas.push(meta.copia || null));
  ctrl.snapshotCb(semDocumento(true));
  assert.deepStrictEqual(ofertas, [null], 'ofereceu a cópia antes de ver os dados da conta');
  ctrl.snapshotCb(doServidor);
  ctrl.snapshotCb(doServidor);
  assert.deepStrictEqual(ofertas, [null, blobCom('guardado'), null], 'a cópia não veio uma vez, na primeira leitura');
  await CLOUD.saveDados(blobCom('guardado'));
  assert.strictEqual(await reabre(), null, 'a cópia ficou depois de o servidor confirmar');
});

test('enquanto a cópia existe cada gravação a atualiza; se não der, ela sai', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('v1')).catch(() => {});
  await passa(20);
  await abreSessao({ carregada: false });
  CLOUD.watchDados(() => {});
  ctrl.snapshotCb(doServidor);
  ctrl.respostas.push(new Promise(() => {}), new Promise(() => {})); // o servidor não confirma
  CLOUD.saveDados(blobCom('v1'));
  CLOUD.saveDados(blobCom('v2'));
  assert.deepStrictEqual(await reabre(), blobCom('v2'), 'a cópia ficou velha: reaplicada, apagaria o v2');
  ctrl.respostas.push(new Promise(() => {}));
  sessao.falha = true;
  CLOUD.saveDados(blobCom('v3'));
  sessao.falha = false;
  assert.strictEqual(await reabre(), null, 'a cópia v2 ficou e apagaria o v3 na recarga seguinte');
});

test('logout com o cliente morto recusa e a cópia fica', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('não pode sumir')).catch(() => {});
  await passa(20);
  await assert.rejects(CLOUD.logout(), { code: 'pendente' });
  assert.strictEqual(ctrl.signOutChamado, 0);
  assert.deepStrictEqual(await reabre(), blobCom('não pode sumir'));
});

test('troca de conta e logout que deu certo apagam a cópia', { timeout: 8000 }, async () => {
  morre();
  CLOUD.saveDados(blobCom('da conta')).catch(() => {});
  await passa(20);
  assert.deepStrictEqual(await reabre(), blobCom('da conta'), 'a cópia não foi guardada');
  ctrl.authCb(null); // a sessão da conta acabou nesta página
  await espera();
  assert.strictEqual(await reabre(), null, 'a cópia sobreviveu à saída da conta');

  sessao = armazem(); recargas = 0;
  await abreSessao();
  morre();
  CLOUD.saveDados(blobCom('da conta')).catch(() => {});
  await passa(20);
  assert.deepStrictEqual(await reabre(), blobCom('da conta'), 'a cópia não foi guardada'); // a tela ainda não reaplicou
  await CLOUD.logout();
  assert.strictEqual(await reabre(), null, 'a cópia sobreviveu ao logout');
});

test('gravação em voo que o SDK morto nunca responde também vai para a cópia', { timeout: 8000 }, async () => {
  ctrl.respostas.push(new Promise(() => {})); // entregue antes da quebra; a fila do SDK morto não anda
  CLOUD.saveDados(blobCom('em voo'));
  morre();
  erroNaJanela();
  await passa(20);
  assert.strictEqual(recargas, 1, 'a gravação presa no SDK morto ficou só na memória');
  assert.deepStrictEqual(await reabre(), blobCom('em voo'));
});

test('quebra durante o backoff cancela a nova tentativa agendada', { timeout: 8000 }, async () => {
  sessao.falha = true; // sem onde guardar: fica parado já na primeira morte
  ctrl.respostas.push({ code: 'unavailable' });
  CLOUD.saveDados(blobCom('esperando')).catch(() => {});
  await passa(20); // backoff de 1 s agendado
  morre();
  erroNaJanela();
  const avisos = () => eventos.filter(e => e.tipo === 'cloud-erro' && e.detail.code === 'cliente-morto').length;
  assert.strictEqual(avisos(), 1);
  await passa(1300);
  assert.strictEqual(avisos(), 1, 'a nova tentativa agendada rodou com o cliente morto e repetiu o aviso');
});

test('a marca da recarga cabe e a cópia não: não recarrega sem a cópia', { timeout: 8000 }, async () => {
  const grava = sessao.setItem.bind(sessao);
  sessao.setItem = (k, v) => { if(String(v).length > 20) throw new Error('QuotaExceededError'); grava(k, v); }; // cota: 1 caractere cabe, 1 MB não
  morre();
  const gravacao = CLOUD.saveDados(blobCom('grande'));
  await passa(20);
  assert.strictEqual(recargas, 0, 'recarregou sem a cópia');
  await assert.rejects(gravacao, { code: 'cliente-morto' });
});

test('cópia de outra conta não é oferecida na abertura', { timeout: 8000 }, async () => {
  sessao.setItem('custta-copia', JSON.stringify({ uid: 'outra-conta', quando: 1, blob: blobCom('de outra conta') }));
  assert.strictEqual(await reabre(), null, 'os dados de outra conta iriam para a tela e seriam gravados nesta');
});

test('asserção interna do Auth não é cliente morto: grava e não recarrega', { timeout: 8000 }, async () => {
  const msg = 'INTERNAL ASSERTION FAILED: Pending promise was never set'; // firebase-auth.js, sem o prefixo FIRESTORE
  window.dispatchEvent(Object.assign(new Event('error'), { error: new Error(msg), message: 'Uncaught Error: ' + msg }));
  CLOUD.saveDados(blobCom('x')).catch(() => {});
  await passa(20);
  assert.strictEqual(recargas, 0, 'erro do Auth recarregou a página');
  assert.strictEqual(ctrl.setDocChamadas.length, 1, 'erro do Auth impediu a gravação');
});

test('segunda morte vista pela janela, com gravação em voo, avisa a tela', { timeout: 8000 }, async () => {
  sessao.setItem('custta-recarregou', '1');
  await abreSessao(); // página nova de uma sessão que já recarregou
  ctrl.respostas.push(new Promise(() => {}));
  CLOUD.saveDados(blobCom('em voo')).catch(() => {});
  await passa(20);
  morre();
  erroNaJanela();
  assert.strictEqual(recargas, 0);
  assert.strictEqual(CLOUD.clienteMorto(), true);
  assert.ok(eventos.some(e => e.tipo === 'cloud-erro' && e.detail.code === 'cliente-morto'), 'sem aviso');
  assert.strictEqual(ultimoEstado(), 'erro');
});

test('parado, a quebra repetida não repete o aviso; lançamento novo repete', { timeout: 8000 }, async () => {
  sessao.falha = true; // sem onde guardar: fica parado já na primeira morte
  morre();
  await assert.rejects(CLOUD.saveDados(blobCom('a')), { code: 'cliente-morto' });
  const avisos = () => eventos.filter(e => e.tipo === 'cloud-erro' && e.detail.code === 'cliente-morto').length;
  assert.strictEqual(avisos(), 1);
  erroNaJanela();
  erroNaJanela();
  assert.strictEqual(avisos(), 1, 'a quebra repetida repetiu o aviso');
  await assert.rejects(CLOUD.saveDados(blobCom('b')), { code: 'cliente-morto' });
  assert.strictEqual(avisos(), 2, 'o lançamento novo ficou sem resposta');
});
