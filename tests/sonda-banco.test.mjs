/* A sonda de ataque (scripts/sonda-banco.mjs) bate no Firebase de produção, e
   este teste nunca faz isso: tudo roda contra um Firebase FALSO em memória.
   O falso aplica uma versão enxuta das firestore.rules (dono, forma do blob,
   campos do perfil, limite de subs), o que importa porque o teste precisa
   provar duas coisas opostas:
     1. com o banco fechado a sonda dá verde, sem sobrar conta nem documento;
     2. quando uma regra quebra (ou um controle positivo falha), ela dá vermelho.
   Sem o segundo lado, um verde da sonda não valeria nada. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmdirSync, symlinkSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { lerConfig, classifica, rodaSonda, valor } from '../scripts/sonda-banco.mjs';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/* ---------- Firebase falso ---------- */

const ehMapa = v => v !== null && typeof v === 'object' && !Array.isArray(v);

/* Valor Firestore (formato REST) → JS, para as regras do falso poderem olhar o corpo. */
function decodifica(v){
  if('nullValue' in v) return null;
  if('booleanValue' in v) return v.booleanValue;
  if('integerValue' in v) return Number(v.integerValue);
  if('doubleValue' in v) return v.doubleValue;
  if('stringValue' in v) return v.stringValue;
  if('arrayValue' in v) return (v.arrayValue.values || []).map(decodifica);
  if('mapValue' in v) return decodificaCampos(v.mapValue.fields || {});
  throw new Error('tipo de valor que o falso não conhece: ' + JSON.stringify(v));
}
const decodificaCampos = campos => Object.fromEntries(Object.entries(campos).map(([k, v]) => [k, decodifica(v)]));

/* Espelho enxuto de firestore.rules. Se as rules mudarem de forma, o espelho
   aqui só precisa continuar barrando os mesmos ataques que a sonda tenta. */
const ORIGENS = ['instagram', 'indicacao', 'google', 'tiktok', 'youtube', 'outro'];
const so = (obj, permitidas) => Object.keys(obj).every(k => permitidas.includes(k));
const textoAte = (d, campo, max) => !(campo in d) || (typeof d[campo] === 'string' && d[campo].length <= max);

function dadosOk(d){
  return so(d, ['obras', 'config', '_atualizado'])
    && Array.isArray(d.obras) && d.obras.length <= 300
    && ehMapa(d.config) && so(d.config, ['taxaMensal', 'topicosCustom'])
    && typeof d.config.taxaMensal === 'number' && d.config.taxaMensal > 0 && d.config.taxaMensal <= 20
    && Array.isArray(d.config.topicosCustom) && d.config.topicosCustom.length <= 50;
}
function perfilClienteOk(d, email){
  return typeof d.email === 'string' && d.email === email && d.email.length <= 320
    && typeof d.criado === 'string' && d.criado.length <= 40
    && (!('tz' in d) || (typeof d.tz === 'string' && d.tz.length <= 64))
    && (!('nome' in d) || (typeof d.nome === 'string' && d.nome.length >= 1 && d.nome.length <= 60))
    && textoAte(d, 'sobrenome', 80)
    && (!('origem' in d) || ORIGENS.includes(d.origem))
    && textoAte(d, 'origemDetalhe', 80);
}
function pushOk(d){
  return so(d, ['subs', 'tokens'])
    && (!('subs' in d) || (ehMapa(d.subs) && Object.keys(d.subs).length <= 10))
    && (!('tokens' in d) || (ehMapa(d.tokens) && Object.keys(d.tokens).length <= 10));
}
function escritaPermitida(colecao, atual, novo, email, updateSolto = false){
  if(colecao === 'dados') return dadosOk(novo);
  if(colecao === 'push') return pushOk(novo);
  if(colecao !== 'perfis') return false;
  if(!atual){
    return so(novo, ['email', 'criado', 'tz', 'nome', 'sobrenome', 'origem', 'origemDetalhe']) && perfilClienteOk(novo, email);
  }
  const afetadas = [...new Set([...Object.keys(atual), ...Object.keys(novo)])]
    .filter(k => JSON.stringify(atual[k]) !== JSON.stringify(novo[k]));
  return (updateSolto || so(Object.fromEntries(afetadas.map(k => [k, 1])), ['email', 'tz', 'nome', 'sobrenome'])) && perfilClienteOk(novo, email);
}

/* opcoes:
   vazar: { metodo, caminho: RegExp }  essa rota ignora as rules e age como o dono do documento
   negarDono                          até o dono leva 403 (controle positivo tem de quebrar)
   estourarEm: RegExp                 o fetch lança erro de rede quando "METODO url" casa com ela
   naoApagar                          accounts:delete diz ok, mas a conta continua viva
   mexerNoBento                       o updateTime de dados/uid-2 muda entre a 1ª e a 2ª leitura
   falharCadastro: n                  o n-ésimo signUp responde 400 (com ecoarSenha, o corpo ecoa a senha)
   ignorarMascara                     PATCH com updateMask vira substituição do documento inteiro
   perfilUpdateSolto                  a regra de update de perfis não confere affectedKeys
   escritaForaLiberada: true|'sem-delete'
                                      PATCH em qualquer/<uid> e dados/<uid>/extra/x passa; com
                                      'sem-delete' nem o dono consegue apagar depois
   falharDelete                       accounts:delete responde 400 e a conta continua viva
   lookupErro: 'MSG'                  accounts:lookup responde 400 com essa mensagem
   lookupStatus: n                    accounts:lookup responde esse status, sem corpo
   lookupFalhaUmaVez                  o 1º accounts:lookup responde 503
   ecoarToken                         corpo de erro do Firestore ecoa o token e uma mensagem longa */
function firebaseFalso(opcoes = {}){
  const contas = new Map();        // uid -> { email, idToken }
  const donoDoToken = new Map();   // idToken -> uid
  const docs = new Map();          // 'colecao/uid' -> { fields, updateTime }
  const senhas = [], tokens = [], emails = [], chamadas = [];
  let cadastros = 0, relogio = 0, leiturasBento = 0, lookups = 0;

  const resp = (status, corpo = {}) => ({ status, ok: status >= 200 && status < 300, json: async () => corpo });
  let tokenDaVez = '';
  const negado = (emArray = false) => {
    const erro = { code: 403, status: 'PERMISSION_DENIED',
      message: 'Missing or insufficient permissions.' + (opcoes.ecoarToken ? ` credencial=${tokenDaVez} ${'x'.repeat(200)}` : '') };
    return resp(403, emArray ? [{ error: erro }] : { error: erro });
  };
  const agora = () => new Date(Date.UTC(2026, 9, 5, 12, 0, ++relogio)).toISOString();
  const nomeDoc = (chave, d) => ({ name: `projects/p/databases/(default)/documents/${chave}`, fields: d.fields, updateTime: d.updateTime });

  async function fetchFalso(url, init = {}){
    const metodo = init.method || 'GET';
    const u = new URL(url);
    chamadas.push({ metodo, url: String(url), comSinal: init.signal instanceof AbortSignal });
    if(opcoes.estourarEm?.test(`${metodo} ${url}`)) throw new TypeError('fetch failed');
    const corpo = init.body ? JSON.parse(init.body) : {};

    /* ----- Identity Toolkit ----- */
    if(u.hostname === 'identitytoolkit.googleapis.com'){
      if(!u.searchParams.get('key')) return resp(400, { error: { message: 'API_KEY_INVALID' } });
      const acao = u.pathname.split('/').pop();
      if(acao === 'accounts:signUp'){
        cadastros++;
        assert.equal(corpo.returnSecureToken, true);
        assert.ok(corpo.email && corpo.password, 'signUp sem e-mail ou senha');
        senhas.push(corpo.password);
        if(opcoes.falharCadastro === cadastros){
          return resp(400, { error: { message: 'OPERATION_NOT_ALLOWED' + (opcoes.ecoarSenha ? ` senha=${corpo.password}` : '') } });
        }
        emails.push(corpo.email);
        const uid = `uid-${cadastros}`, idToken = `tok-${cadastros}`;
        contas.set(uid, { email: corpo.email, idToken });
        donoDoToken.set(idToken, uid);
        tokens.push(idToken);
        return resp(200, { idToken, localId: uid, email: corpo.email });
      }
      if(acao === 'accounts:lookup'){
        lookups++;
        if(opcoes.lookupErro) return resp(400, { error: { message: opcoes.lookupErro } });
        if(opcoes.lookupStatus) return resp(opcoes.lookupStatus, {});
        if(opcoes.lookupFalhaUmaVez && lookups === 1) return resp(503, {});
      }
      const uid = donoDoToken.get(corpo.idToken);
      if(!uid || !contas.has(uid)) return resp(400, { error: { message: 'USER_NOT_FOUND' } });
      if(acao === 'accounts:delete'){
        if(opcoes.falharDelete) return resp(400, { error: { message: 'TOO_MANY_ATTEMPTS_TRY_LATER' } });
        if(!opcoes.naoApagar) contas.delete(uid);
        return resp(200, {});
      }
      if(acao === 'accounts:lookup') return resp(200, { users: [{ localId: uid }] });
      return resp(404);
    }

    /* ----- Firestore REST ----- */
    if(u.hostname === 'firestore.googleapis.com'){
      const base = '/v1/projects/p/databases/(default)/documents';
      assert.ok(u.pathname.startsWith(base), 'caminho do Firestore fora do projeto esperado: ' + u.pathname);
      const resto = u.pathname.slice(base.length);

      const vaza = opcoes.vazar && opcoes.vazar.metodo === metodo && opcoes.vazar.caminho.test(u.pathname);
      let autor = null;
      const auth = init.headers?.Authorization;
      if(auth){
        tokenDaVez = auth.replace(/^Bearer /, '');
        const uid = donoDoToken.get(tokenDaVez);
        if(!uid || !contas.has(uid)) return resp(401, { error: { status: 'UNAUTHENTICATED' } });
        autor = uid;
      }

      if(resto === ':runQuery') return vaza ? resp(200, [{ readTime: 'x' }]) : negado(true);
      const segs = resto.split('/').filter(Boolean);
      if(segs.some(s => s.includes('..') || s.startsWith('__'))) return resp(400, { error: { status: 'INVALID_ARGUMENT' } });
      if(segs.length === 1) return vaza ? resp(200, { documents: [] }) : negado();
      if(vaza) autor = segs[1];                     // a rota "vazada" age como o dono
      else if(opcoes.negarDono) return negado();

      const colecao = segs[0], id = segs[1];
      const chave = segs.join('/');
      const meu = segs.length === 2 && ['dados', 'perfis', 'push'].includes(colecao) && autor === id;
      const foraLiberado = !!opcoes.escritaForaLiberada && !!autor && autor === id
        && ((colecao === 'qualquer' && segs.length === 2) || (colecao === 'dados' && segs.length === 4 && segs[2] === 'extra'));
      if(!meu && !foraLiberado) return negado();
      if(foraLiberado && metodo === 'DELETE' && opcoes.escritaForaLiberada === 'sem-delete') return negado();

      if(metodo === 'GET'){
        const d = docs.get(chave);
        if(!d) return resp(404);
        if(chave === 'dados/uid-2' && ++leiturasBento >= 2 && opcoes.mexerNoBento) d.updateTime = agora();
        return resp(200, nomeDoc(chave, d));
      }
      if(metodo === 'DELETE'){ docs.delete(chave); return resp(200, {}); }
      if(metodo === 'PATCH'){
        const atual = docs.get(chave);
        const mascara = opcoes.ignorarMascara ? [] : u.searchParams.getAll('updateMask.fieldPaths');
        let campos = corpo.fields || {};
        if(mascara.length){
          campos = { ...(atual?.fields || {}) };
          for(const m of mascara){ if(m in (corpo.fields || {})) campos[m] = corpo.fields[m]; else delete campos[m]; }
        }
        const email = contas.get(autor)?.email;
        if(!foraLiberado && !escritaPermitida(colecao, atual ? decodificaCampos(atual.fields) : null, decodificaCampos(campos), email, !!opcoes.perfilUpdateSolto)){
          return negado();
        }
        const novo = { fields: campos, updateTime: agora() };
        docs.set(chave, novo);
        return resp(200, nomeDoc(chave, novo));
      }
      return resp(405);
    }

    /* ----- RTDB, Storage e qualquer outro host: não existem neste projeto ----- */
    return resp(404);
  }

  return { fetch: fetchFalso, contas, docs, senhas, tokens, emails, chamadas };
}

const roda = (f, extra = {}) => rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {}, ...extra });

/* ---------- lerConfig / classifica / valor ---------- */

test('lerConfig acha apiKey e projeto no cloud.js real', () => {
  const c = lerConfig(readFileSync(new URL('../cloud.js', import.meta.url), 'utf8'));
  assert.match(c.apiKey, /^AIza[\w-]{20,}$/);
  assert.equal(c.projeto, 'app-construcao-civil');
});

test('lerConfig lança quando falta a apiKey ou o projeto', () => {
  assert.throws(() => lerConfig("const x = { projectId: 'p' };"), /apiKey/);
  assert.throws(() => lerConfig("const x = { apiKey: 'AIzaX' };"), /projectId/);
});

test('classifica: 2xx em ataque reprova, 403 esperado passa, 404 onde se espera 403 reprova', () => {
  assert.equal(classifica([403], { status: 403 }).ok, true);
  assert.equal(classifica([403], { status: 200 }).ok, false);
  assert.equal(classifica([403], { status: 404 }).ok, false);
  assert.equal(classifica('sucesso', { status: 200 }).ok, true);
  assert.equal(classifica('sucesso', { status: 403 }).ok, false);
  assert.equal(classifica([404, 'rede'], { erroRede: 'ENOTFOUND' }).ok, true);
  assert.equal(classifica([403], { erroRede: 'ENOTFOUND' }).ok, false);
});

test('classifica: 2xx reprova mesmo que alguém o liste como aceito, e erro de rede não passa por sucesso', () => {
  assert.equal(classifica([200, 403], { status: 200 }).ok, false);
  assert.equal(classifica([204], { status: 204 }).ok, false);
  assert.equal(classifica('sucesso', { erroRede: 'ECONNRESET' }).ok, false);
});

test('classifica: o detalhe diz o que veio e o que se esperava', () => {
  assert.equal(classifica([403], { status: 403 }).detalhe, '403');
  assert.equal(classifica([403], { status: 200 }).detalhe, '200 — devia ser 403');
  assert.equal(classifica([400, 403, 404], { status: 500 }).detalhe, '500 — devia ser 400/403/404');
  assert.match(classifica([403], { erroRede: 'ENOTFOUND' }).detalhe, /ENOTFOUND/);
});

test('classifica: quando o status não bate, o motivo do corpo de erro entra no detalhe; quando bate, não', () => {
  assert.equal(classifica([403], { status: 400, motivo: 'INVALID_ARGUMENT: caminho ruim' }).detalhe, '400 — devia ser 403 [INVALID_ARGUMENT: caminho ruim]');
  assert.equal(classifica('sucesso', { status: 403, motivo: 'PERMISSION_DENIED' }).detalhe, '403 — devia dar certo [PERMISSION_DENIED]');
  assert.equal(classifica([403], { status: 403, motivo: 'PERMISSION_DENIED' }).detalhe, '403');
});

test('valor converte JS em valor Firestore', () => {
  assert.deepEqual(valor(null), { nullValue: null });
  assert.deepEqual(valor(true), { booleanValue: true });
  assert.deepEqual(valor(7), { integerValue: '7' });
  assert.deepEqual(valor(1.5), { doubleValue: 1.5 });
  assert.deepEqual(valor('a'), { stringValue: 'a' });
  assert.deepEqual(valor([1, 'x']), { arrayValue: { values: [{ integerValue: '1' }, { stringValue: 'x' }] } });
  assert.deepEqual(valor({ a: 1 }), { mapValue: { fields: { a: { integerValue: '1' } } } });
  assert.deepEqual(valor([]), { arrayValue: {} });
  assert.deepEqual(valor({}), { mapValue: { fields: {} } });
});

/* ---------- rodaSonda contra o falso ---------- */

test('banco fechado: tudo ok, sem sobras', async () => {
  const f = firebaseFalso();
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, true, JSON.stringify(r.linhas.filter(l => !l.ok)));
  assert.deepEqual(r.sobras, []);
  assert.ok(r.linhas.length >= 30);
});

test('banco fechado: as duas contas somem e nenhum documento fica para trás', async () => {
  const f = firebaseFalso();
  await roda(f);
  assert.equal(f.contas.size, 0);
  assert.equal(f.docs.size, 0, 'documento de conta descartável ficou: ' + [...f.docs.keys()]);
});

test('controles positivos vêm antes de qualquer ataque', async () => {
  const f = firebaseFalso();
  const r = await roda(f);
  const nomes = r.linhas.map(l => l.nome);
  const ultimoControle = nomes.map(n => n.startsWith('controle')).lastIndexOf(true);
  const primeiroAtaque = nomes.findIndex(n => !n.startsWith('controle'));
  assert.ok(ultimoControle >= 0 && primeiroAtaque > ultimoControle, nomes.join('\n'));
  assert.equal(nomes.filter(n => n.startsWith('controle')).length, 8);
});

test('cobre os ataques do brief: sem login, Ana contra Bento, campos proibidos, caminhos estranhos, outros bancos', async () => {
  const f = firebaseFalso();
  const r = await roda(f);
  const nomes = r.linhas.map(l => l.nome).join('\n');
  for(const trecho of [
    'sem login', 'listar', 'runQuery',
    'dados/<bento>', 'perfis/<bento>', 'push/<bento>',
    'plano', 'avisosOrcamento', 'cpf', 'origem', 'email',
    'admin', 'taxaMensal', 'obras', '11 subs', 'qualquer/<ana>', 'dados/<ana>/extra/x',
    'cria perfis/<ana> com plano', 'cria perfis/<ana> com cpf', 'cria perfis/<ana> com e-mail de outra pessoa',
    '..', '__', 'RTDB', 'Storage', 'integridade',
  ]) assert.ok(nomes.includes(trecho), `a sonda não tem nenhuma verificação sobre "${trecho}"`);
});

test('regra quebrada (Ana lê dados do Bento) reprova', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'GET', caminho: /dados\/uid-2$/ } });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
  assert.ok(r.linhas.some(l => !l.ok && l.nome.includes('<bento>')), 'a linha reprovada devia ser a do Bento');
});

test('regra quebrada que deixa Ana sobrescrever o Bento reprova, e a integridade denuncia', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'PATCH', caminho: /dados\/uid-2$/ } });
  const r = await roda(f);
  assert.equal(r.ok, false);
  const integridade = r.linhas.find(l => l.nome.includes('integridade'));
  assert.equal(integridade.ok, false, 'o updateTime do Bento mudou e a sonda não viu');
});

test('regra quebrada que deixa listar a coleção reprova', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'GET', caminho: /documents\/dados$/ } });
  const r = await roda(f);
  assert.equal(r.ok, false);
});

test('regra quebrada em runQuery reprova', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'POST', caminho: /:runQuery$/ } });
  const r = await roda(f);
  assert.equal(r.ok, false);
});

test('controle positivo falhando reprova (sem falso verde)', async () => {
  const f = firebaseFalso({ negarDono: true });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
  assert.ok(r.linhas.some(l => !l.ok && l.nome.startsWith('controle')));
});

test('limpeza roda mesmo se um ataque estoura a rede', async () => {
  const f = firebaseFalso({ estourarEm: /runQuery/ });
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} }).catch(() => {});
  assert.equal(f.contas.size, 0, 'conta descartável ficou para trás');
});

test('erro de rede num ataque reprova a sonda (rede fora do ar não é banco fechado)', async () => {
  const f = firebaseFalso({ estourarEm: /runQuery/ });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.equal(f.contas.size, 0);
});

test('limpeza continua apesar de um erro: documento que não apaga não impede apagar as contas, mas é denunciado', async () => {
  const f = firebaseFalso({ estourarEm: /^DELETE .*documents\/dados\/uid-1$/ });
  const r = await roda(f);
  assert.equal(f.contas.size, 0, 'a limpeza parou no primeiro erro');
  assert.ok(f.docs.has('dados/uid-1'), 'o teste devia ter deixado o documento de Ana para trás');
  assert.equal(r.ok, false, 'documento órfão tem de reprovar para alguém limpar');
  /* O nome tem o uid REAL: com a conta apagada em seguida, é a única pista de qual
     documento ficou no banco (o uid é opaco, não é segredo). */
  assert.ok(r.linhas.some(l => !l.ok && l.nome === 'limpeza: Ana apaga dados/uid-1'),
    r.linhas.filter(l => !l.ok).map(l => l.nome).join('\n'));
  assert.ok(!r.linhas.some(l => l.nome.startsWith('limpeza') && /<\w+>/.test(l.nome)),
    'placeholder no lugar do uid na linha de limpeza');
});

test('cadastro que falha no meio: a sonda lança e apaga a conta que já existia', async () => {
  const f = firebaseFalso({ falharCadastro: 2 });
  await assert.rejects(roda(f), /conta descartável.*OPERATION_NOT_ALLOWED/);
  assert.equal(f.contas.size, 0, 'Ana ficou para trás');
});

test('conta que não some vira sobra e reprova', async () => {
  const f = firebaseFalso({ naoApagar: true });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
  assert.equal(r.sobras.length, 2);
});

test('saída nunca mostra senha nem token', async () => {
  const f = firebaseFalso();
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const texto = saida.join('\n');
  assert.ok(f.senhas.length === 2 && f.tokens.length === 2);
  for (const segredo of [...f.senhas, ...f.tokens]) assert.ok(!texto.includes(segredo), 'vazou segredo na saída');
});

test('saída nunca mostra segredo nem quando o banco está aberto e tudo reprova', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'GET', caminho: /dados\/uid-2$/ }, naoApagar: true, mexerNoBento: true });
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const texto = saida.join('\n');
  for (const segredo of [...f.senhas, ...f.tokens]) assert.ok(!texto.includes(segredo), 'vazou segredo na saída');
});

test('senhas: uma por conta, longas e diferentes', async () => {
  const f = firebaseFalso();
  await roda(f);
  assert.equal(new Set(f.senhas).size, 2);
  for (const s of f.senhas) assert.ok(s.length >= 20, 'senha curta demais');
});

test('dado da vítima alterado reprova', async () => {
  const f = firebaseFalso({ mexerNoBento: true }); // muda updateTime de dados/uid-2 entre as leituras
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
  const integridade = r.linhas.find(l => l.nome.includes('integridade'));
  assert.equal(integridade.ok, false);
  assert.match(integridade.detalhe, /vítima/);
});

test('toda requisição leva timeout, a apiKey só vai ao Identity Toolkit e nada sai do Google', async () => {
  const f = firebaseFalso();
  await roda(f);
  assert.ok(f.chamadas.length >= 40);
  for(const c of f.chamadas){
    assert.ok(c.comSinal, 'requisição sem AbortSignal.timeout: ' + c.url);
    const u = new URL(c.url);
    assert.match(u.hostname, /(googleapis\.com|firebaseio\.com)$/, 'host inesperado: ' + u.hostname);
    if(u.hostname === 'identitytoolkit.googleapis.com') assert.equal(u.searchParams.get('key'), 'k');
    else assert.equal(u.searchParams.has('key'), false, 'apiKey vazou para ' + u.hostname);
  }
});

test('o e-mail das contas é sonda-<papel>-<timestamp>-<aleatório>@example.com, descartável e rastreável', async () => {
  const f = firebaseFalso();
  await roda(f, { aleatorio: () => 'abc123' });
  assert.equal(f.emails.length, 2);
  assert.notEqual(f.emails[0], f.emails[1]);
  assert.match(f.emails[0], /^sonda-ana-\d{13}-abc123@example\.com$/);
  assert.match(f.emails[1], /^sonda-bento-\d{13}-abc123@example\.com$/);
});

test('duas execuções seguidas não colidem: cada uma cria e-mails novos', async () => {
  const f = firebaseFalso();
  let n = 0;
  await roda(f, { aleatorio: () => 'r' + ++n });
  await roda(f, { aleatorio: () => 'r' + ++n });
  assert.equal(new Set(f.emails).size, 4);
});

test('o log recebe só linhas de tabela e o resumo final', async () => {
  const f = firebaseFalso();
  const saida = [];
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const tabela = saida.filter(l => /^[✔✗] /.test(l));
  assert.equal(tabela.length, r.linhas.length);
  assert.equal(saida.length, tabela.length + 1, 'sobrou linha que não é da tabela nem o resumo');
  assert.match(saida.at(-1), /tudo barrado|OK/i);
});

test('o log marca a linha reprovada com o que veio e o que se esperava', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'GET', caminho: /dados\/uid-2$/ } });
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  assert.ok(saida.some(l => /^✗ .*<bento>.*\(200 — devia ser 403\)$/.test(l)), saida.join('\n'));
  assert.match(saida.at(-1), /REPROVOU/);
});

/* ---------- fix round 1 ---------- */

const linhaDe = (r, trecho) => r.linhas.find(l => l.nome.includes(trecho));

test('I1: controle positivo prova que o updateMask é honrado antes de qualquer ataque de update', async () => {
  const f = firebaseFalso();
  const r = await roda(f);
  const controle = linhaDe(r, 'via updateMask');
  assert.ok(controle && controle.nome.startsWith('controle'), 'falta o controle do updateMask');
  assert.equal(controle.ok, true);
});

test('I1: servidor que ignora o updateMask reprova pelo controle (sem falso verde)', async () => {
  const f = firebaseFalso({ ignorarMascara: true });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.equal(linhaDe(r, 'via updateMask').ok, false);
});

test('I1: regra de update frouxa E máscara ignorada (o falso verde que a revisão reproduziu) reprova', async () => {
  const f = firebaseFalso({ ignorarMascara: true, perfilUpdateSolto: true });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.equal(linhaDe(r, 'via updateMask').ok, false, 'sem o controle os 5 ataques dariam 403 pelo motivo errado');
});

test('I1: regra de update frouxa com máscara honrada reprova pelos ataques de update', async () => {
  const f = firebaseFalso({ perfilUpdateSolto: true });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.equal(linhaDe(r, 'Ana grava plano em perfis/<ana>').ok, false);
  assert.equal(linhaDe(r, 'via updateMask').ok, true, 'o controle é legítimo e tem de passar');
});

test('I2: limpeza tenta apagar qualquer/<uid> e a subcoleção, em silêncio quando o banco está fechado', async () => {
  const f = firebaseFalso();
  const r = await roda(f);
  assert.equal(r.ok, true, JSON.stringify(r.linhas.filter(l => !l.ok)));
  assert.ok(!r.linhas.some(l => l.nome.startsWith('limpeza')), 'o 403 esperado não pode virar linha');
  for (const caminho of ['qualquer/uid-1', 'dados/uid-1/extra/x', 'qualquer/uid-2', 'dados/uid-2/extra/x']) {
    assert.ok(f.chamadas.some(c => c.metodo === 'DELETE' && c.url.endsWith('/documents/' + caminho)), 'limpeza não tentou apagar ' + caminho);
  }
});

test('I2: ataque que passa por engano em qualquer/ e na subcoleção reprova, e a limpeza apaga o resto', async () => {
  const f = firebaseFalso({ escritaForaLiberada: true });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.equal(linhaDe(r, 'Ana grava em qualquer/<ana>').ok, false);
  assert.equal(linhaDe(r, 'Ana grava em dados/<ana>/extra/x').ok, false);
  assert.equal(f.docs.size, 0, 'documento órfão: ' + [...f.docs.keys()]);
  assert.equal(f.contas.size, 0);
});

test('I2: resto de ataque que não dá para apagar vira linha limpeza com o caminho REAL', async () => {
  const f = firebaseFalso({ escritaForaLiberada: 'sem-delete' });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.ok(f.docs.has('qualquer/uid-1') && f.docs.has('dados/uid-1/extra/x'), 'o teste devia deixar os restos para trás');
  const qualquer = r.linhas.find(l => l.nome === 'limpeza: resto de ataque em qualquer/uid-1');
  const extra = r.linhas.find(l => l.nome === 'limpeza: resto de ataque em dados/uid-1/extra/x');
  assert.ok(qualquer && extra, r.linhas.map(l => l.nome).join('\n'));
  assert.equal(qualquer.ok, false);
  assert.equal(extra.ok, false);
});

test('I2: resposta perdida na rede num ataque de escrita fora também deixa a limpeza denunciando o caminho', async () => {
  const f = firebaseFalso({ estourarEm: /^PATCH .*documents\/qualquer\/uid-1$/ });
  const r = await roda(f);
  assert.equal(r.ok, false);
  assert.ok(r.linhas.some(l => l.nome === 'limpeza: resto de ataque em qualquer/uid-1' && !l.ok),
    'o servidor pode ter gravado antes de a resposta se perder; a limpeza não consegue provar o contrário');
});

test('M2: accounts:delete falha e o lookup dá 400 por outro motivo: contas vivas viram sobra', async () => {
  const f = firebaseFalso({ falharDelete: true, lookupErro: 'TOO_MANY_ATTEMPTS_TRY_LATER' });
  const r = await roda(f);
  assert.equal(f.contas.size, 2, 'o teste devia deixar as duas contas vivas');
  assert.deepEqual(r.sobras, ['uid-1', 'uid-2']);
  assert.equal(r.ok, false);
});

test('M2: delete ok mas lookup com 400 que não diz "usuário não existe" não prova nada: sobra', async () => {
  const f = firebaseFalso({ lookupErro: 'TOO_MANY_ATTEMPTS_TRY_LATER' });
  const r = await roda(f);
  assert.equal(f.contas.size, 0);
  assert.equal(r.sobras.length, 2);
  assert.equal(r.ok, false);
});

test('M2: lookup com 5xx ou erro de rede não confirma: sobra', async () => {
  for (const opcoes of [{ lookupStatus: 503 }, { estourarEm: /accounts:lookup/ }]) {
    const f = firebaseFalso(opcoes);
    const r = await roda(f);
    assert.equal(r.sobras.length, 2, JSON.stringify(opcoes));
    assert.equal(r.ok, false);
  }
});

test('M2: INVALID_ID_TOKEN no lookup também prova a ausência', async () => {
  const f = firebaseFalso({ lookupErro: 'INVALID_ID_TOKEN' });
  const r = await roda(f);
  assert.deepEqual(r.sobras, []);
  assert.equal(r.ok, true, JSON.stringify(r.linhas.filter(l => !l.ok)));
});

test('M2: lookup que falha uma vez é tentado de novo, e o delete 2xx anterior vale (2ª tentativa não vira sobra)', async () => {
  const f = firebaseFalso({ lookupFalhaUmaVez: true });
  const r = await roda(f);
  assert.deepEqual(r.sobras, []);
  assert.equal(r.ok, true, JSON.stringify(r.linhas.filter(l => !l.ok)));
  assert.equal(f.contas.size, 0);
});

test('M6: linha reprovada mostra o motivo do corpo de erro (status e mensagem)', async () => {
  const f = firebaseFalso({ negarDono: true });
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const linha = saida.find(l => l.startsWith('✗ controle: Ana grava dados/<ana>'));
  assert.ok(linha, saida.join('\n'));
  assert.match(linha, /403 — devia dar certo \[PERMISSION_DENIED: Missing or insufficient permissions\.\]/);
});

test('M6: motivo é truncado e sai sem token (mesmo quando o servidor ecoa a credencial)', async () => {
  const f = firebaseFalso({ negarDono: true, ecoarToken: true });
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const reprovadas = saida.filter(l => l.startsWith('✗'));
  assert.ok(reprovadas.length > 0);
  for (const l of reprovadas) {
    assert.ok(!l.includes('tok-'), 'token na linha: ' + l);
    assert.ok(l.length < 200, 'linha longa demais: ' + l.length);
  }
  assert.ok(reprovadas.some(l => l.includes('…')), 'o motivo longo devia ter sido truncado');
  assert.ok(reprovadas.some(l => l.includes('***')), 'o token no corpo devia ter sido riscado');
});

test('M6: corpo de erro de runQuery (lista) também é lido, e 2xx de ataque não tem corpo lido', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'POST', caminho: /:runQuery$/ } });
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const vazou = saida.find(l => /^✗ .*runQuery/.test(l));
  assert.ok(vazou && /\(200 — devia ser 403\)$/.test(vazou), 'ataque 2xx não mostra corpo: ' + vazou);
  const f2 = firebaseFalso({ negarDono: true });
  const saida2 = [];
  await rodaSonda({ fetch: f2.fetch, apiKey: 'k', projeto: 'p', log: l => saida2.push(l) });
  assert.ok(saida2.every(l => !/\[object|undefined/.test(l)), saida2.join('\n'));
});

test('M6: erro do signUp mostra o motivo curto e nunca ecoa a senha', async () => {
  const f = firebaseFalso({ falharCadastro: 1, ecoarSenha: true });
  await assert.rejects(roda(f), err => {
    assert.match(err.message, /OPERATION_NOT_ALLOWED/);
    assert.ok(f.senhas.length === 1 && !err.message.includes(f.senhas[0]), 'a senha vazou na mensagem de erro');
    return true;
  });
});

/* ---------- CLI ---------- */

test('CLI sem --producao sai com 2 e explica o uso, sem tocar a rede', () => {
  const r = spawnSync(process.execPath, ['scripts/sonda-banco.mjs'], { cwd: RAIZ, encoding: 'utf8', timeout: 15000 });
  assert.equal(r.status, 2, r.stdout + r.stderr);
  assert.match(r.stdout + r.stderr, /--producao/);
});

test('CLI chamada por um caminho com symlink também roda (sem --producao: 2, nunca 0 em silêncio)', t => {
  const dir = mkdtempSync(path.join(tmpdir(), 'sonda-symlink-'));
  const elo = path.join(dir, 'repo');
  try {
    try { symlinkSync(RAIZ, elo, 'dir'); }
    catch (erro) { t.skip('este ambiente não deixa criar symlink em ' + tmpdir() + ' (' + (erro.code || erro.message) + ')'); return; }
    /* argv[1] mantém o caminho do symlink e import.meta.url vira o caminho real:
       comparar os dois como texto dava falso, a CLI não rodava e saía com 0, o
       mesmo código de "banco fechado". */
    const r = spawnSync(process.execPath, [path.join(elo, 'scripts', 'sonda-banco.mjs')], { cwd: dir, encoding: 'utf8', timeout: 15000 });
    assert.equal(r.status, 2, 'status ' + r.status + '\n' + r.stdout + r.stderr);
    assert.match(r.stdout + r.stderr, /--producao/);
  } finally {
    try { unlinkSync(elo); } catch { /* não chegou a criar */ }
    try { rmdirSync(dir); } catch { /* idem */ }
  }
});
