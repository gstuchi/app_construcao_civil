#!/usr/bin/env node
/* Sonda de ataque contra o banco de produção do Custta.

   O que prova: que as firestore.rules em produção barram, de fora, o que
   precisam barrar. Os testes de rules (tests/rules.test.mjs) rodam no emulador
   e provam o ARQUIVO; esta sonda prova o que está NO AR, falando com o Firestore
   pela API REST do mesmo jeito que qualquer atacante falaria. A apiKey do
   Firebase é pública por design (está em cloud.js), então a sonda parte do
   mesmo ponto que ele: só a chave e duas contas que ela mesma cria.

   O que tenta (cada tentativa vira uma linha da tabela):
     - sem login: ler, listar, gravar e fazer query nos documentos e coleções;
     - Ana contra o Bento (a vítima): ler, gravar e apagar os documentos dele,
       listar as coleções, query de grupo e query filtrando o documento dele;
     - Ana no próprio documento, mas com o que o cliente não pode gravar: plano,
       avisosOrcamento, cpf, trocar origem, trocar e-mail, chave extra no blob,
       taxa fora da faixa, obras no formato errado, 11 inscrições de push,
       coleção que não existe, subcoleção. Em perfis, isso vale na atualização
       E na criação (Ana apaga o próprio perfil e tenta recriá-lo com plano,
       cpf e afins), porque as rules de create e de update são regras diferentes;
     - caminhos estranhos (.. e ids reservados) e os outros bancos do projeto
       (Realtime Database e Storage).
   Cada ataque manda um corpo válido com UMA violação só, para que o 403 prove
   aquela regra e não um corpo malformado.

   Por que tem controle positivo: um 403 não diz nada se a sonda estiver cega
   (token errado, caminho errado, corpo recusado por outro motivo). Antes dos
   ataques, Ana e Bento fazem o que as rules PERMITEM (gravar e ler o que é
   deles) e a sonda exige sucesso. Se isso falhar, o verde dos ataques não vale
   e a sonda reprova. Depois dos ataques, o Bento relê o documento dele: o
   updateTime precisa ser o mesmo, senão alguém conseguiu escrever.

   Roda contra a PRODUÇÃO e cria contas reais no projeto. Elas são descartáveis:
   senha aleatória que nunca é impressa, e no fim (mesmo se algo estourar no
   meio) cada conta apaga os próprios documentos e a si mesma, e a sonda confirma
   que a conta sumiu. Conta que não for possível confirmar apagada aparece em
   "sobras" e reprova a sonda. Corpo de resposta 2xx nunca é lido nem impresso
   (se uma regra vazasse, seria dado de outra pessoa). Quando o status não bate,
   a linha mostra também o motivo curto do corpo de erro (error.status e
   error.message, truncado, sem token nem senha), que é o que diagnostica uma
   regra, uma chave ou um protocolo errado na primeira rodada real.

   Quando rodar: depois de `npm run rules:deploy`, para conferir o que subiu.

   Uso:
     node scripts/sonda-banco.mjs --producao     # ou: npm run sonda:banco

   Sem --producao não faz nada (sai com 2, sem tocar a rede). Saída: 0 = tudo
   barrado e sem sobras, 1 = alguma verificação falhou ou sobrou conta.

   Este repositório é público: nenhuma senha, token ou chave privada mora aqui.
   A única credencial é a apiKey pública, lida de cloud.js na hora. */
'use strict';
import { randomBytes } from 'node:crypto';
import { readFileSync, realpathSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const IDENTITY = 'https://identitytoolkit.googleapis.com/v1';
const TIMEOUT_MS = 15000;

const BARRADO = [403];
const CAMINHO_ESTRANHO = [400, 403, 404];
const OUTROS_BANCOS = [400, 401, 403, 404, 423, 'rede'];

/* A chave e o projeto vêm de cloud.js: é a mesma fonte que o app usa, então a
   sonda ataca exatamente o projeto que o app usa e nada é copiado para cá. */
export function lerConfig(textoCloudJs){
  const apiKey = /\bapiKey:\s*'([^']+)'/.exec(textoCloudJs)?.[1];
  const projeto = /\bprojectId:\s*'([^']+)'/.exec(textoCloudJs)?.[1];
  if(!apiKey) throw new Error("cloud.js sem apiKey: '...' — a sonda lê a chave de lá.");
  if(!projeto) throw new Error("cloud.js sem projectId: '...' — a sonda lê o projeto de lá.");
  return { apiKey, projeto };
}

const ehSucesso = status => status >= 200 && status < 300;

/* esperado: 'sucesso' (controle positivo) ou a lista de status aceitos (ataque;
   inclui 'rede' onde um host que não responde também significa "fechado").
   Qualquer 2xx num ataque reprova, mesmo que alguém o liste como aceito: o
   ataque deu certo. Erro de rede só passa onde 'rede' foi aceito. Quando não
   bate, o `motivo` do corpo de erro (se houver) entra no detalhe. */
export function classifica(esperado, resultado){
  const queria = esperado === 'sucesso' ? 'dar certo' : `ser ${esperado.join('/')}`;
  if(resultado.erroRede !== undefined){
    const ok = Array.isArray(esperado) && esperado.includes('rede');
    return { ok, detalhe: ok ? `rede: ${resultado.erroRede}` : `rede: ${resultado.erroRede} — devia ${queria}` };
  }
  const { status } = resultado;
  const ok = esperado === 'sucesso' ? ehSucesso(status) : !ehSucesso(status) && esperado.includes(status);
  const motivo = resultado.motivo ? ` [${resultado.motivo}]` : '';
  return { ok, detalhe: ok ? String(status) : `${status} — devia ${queria}${motivo}` };
}

/* JS → valor Firestore (formato REST), para montar os corpos dos ataques sem
   escrever o JSON do protocolo na mão. */
export function valor(v){
  if(v === null) return { nullValue: null };
  if(typeof v === 'boolean') return { booleanValue: v };
  if(typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if(typeof v === 'string') return { stringValue: v };
  if(Array.isArray(v)) return { arrayValue: v.length ? { values: v.map(valor) } : {} };
  if(typeof v === 'object') return { mapValue: { fields: campos(v) } };
  throw new Error('valor sem equivalente no Firestore: ' + typeof v);
}
const campos = obj => Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, valor(v)]));
const documento = obj => ({ fields: campos(obj) });

/* O blob que blobOk() aceita. Os ataques partem dele e estragam uma coisa. */
const blobValido = () => ({ obras: [], config: { taxaMensal: 1, topicosCustom: [] } });

const MOTIVO_MAX = 80;

/* Motivo curto de um corpo de erro: `error.status: error.message` do Firestore e
   do Identity Toolkit (o do RTDB é só uma string). Corpo de erro não carrega
   dado de outro usuário, mas por garantia o texto sai sem token nem senha,
   numa linha só e truncado. */
function motivoDoCorpo(json, segredos){
  const corpo = Array.isArray(json) ? json[0] : json;
  const erro = corpo?.error;
  if(!erro) return undefined;
  let texto = typeof erro === 'string'
    ? erro
    : [erro.status, erro.message].filter(x => typeof x === 'string' && x).join(': ');
  for(const segredo of segredos) if(segredo) texto = texto.split(segredo).join('***');
  texto = texto.replace(/\s+/g, ' ').trim();
  if(!texto) return undefined;
  return texto.length > MOTIVO_MAX ? texto.slice(0, MOTIVO_MAX - 1) + '…' : texto;
}

/* Uma requisição. Nunca lança: erro de rede e timeout viram { erroRede }, para
   uma queda no meio não impedir a limpeza nem passar por "banco fechado". O
   corpo de 2xx só é lido quando a sonda precisa dele (updateTime, idToken);
   nos ataques é descartado sem baixar, porque numa regra quebrada seria dado
   alheio. O de erro é lido só para extrair o `motivo` (ver motivoDoCorpo). */
async function requisita(fetch, metodo, url, { token, corpo, lerJson = false, segredos = [] } = {}){
  const headers = {};
  if(token) headers.Authorization = `Bearer ${token}`;
  if(corpo !== undefined) headers['Content-Type'] = 'application/json';
  try{
    const res = await fetch(url, {
      method: metodo,
      headers,
      body: corpo === undefined ? undefined : JSON.stringify(corpo),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    const sucesso = ehSucesso(res.status);
    if(!lerJson && sucesso){
      try{ await res.body?.cancel(); }catch{ /* sem corpo para soltar */ }
      return { status: res.status };
    }
    let json = null;
    try{ json = await res.json(); }catch{ /* resposta sem JSON */ }
    const resultado = { status: res.status };
    if(lerJson) resultado.json = json;
    if(!sucesso){
      const motivo = motivoDoCorpo(json, [token, ...segredos]);
      if(motivo) resultado.motivo = motivo;
    }
    return resultado;
  }catch(erro){
    return { erroRede: erro?.cause?.code || erro?.name || 'erro de rede' };
  }
}

async function criaConta(pede, apiKey, rotulo, email){
  /* A senha existe só aqui dentro: a sonda usa o idToken daí em diante e nunca
     volta a precisar dela. */
  const senha = randomBytes(18).toString('base64url');
  const r = await pede('POST', `${IDENTITY}/accounts:signUp?key=${apiKey}`, {
    corpo: { email, password: senha, returnSecureToken: true },
    lerJson: true,
    segredos: [senha],
  });
  if(r.erroRede !== undefined) throw new Error(`não consegui criar a conta descartável ${rotulo}: erro de rede (${r.erroRede})`);
  if(r.status !== 200 || !r.json?.idToken || !r.json?.localId){
    throw new Error(`não consegui criar a conta descartável ${rotulo} (HTTP ${r.status}${r.motivo ? ' ' + r.motivo : ''})`);
  }
  return { rotulo, email, uid: r.json.localId, idToken: r.json.idToken };
}

/* Caminhos que os ataques tentam gravar fora de dados|perfis|push/<uid>. Se a
   regra estivesse quebrada, ficariam documentos órfãos que apagar a conta não
   remove (documento de subcoleção sobrevive ao pai). */
const caminhosDeAtaque = uid => [`qualquer/${uid}`, `dados/${uid}/extra/x`];

/* accounts:lookup depois de apagar: o que prova a ausência é o erro de usuário
   inexistente no corpo, ou um 2xx sem usuário. 400 por outro motivo (limite de
   tentativas, chave) não prova nada, e erro de rede ou 5xx muito menos. */
function lookupConfirmaAusencia(l){
  if(l.erroRede !== undefined) return false;
  if(ehSucesso(l.status)) return !l.json?.users?.length;
  return l.status === 400 && /^(USER_NOT_FOUND|INVALID_ID_TOKEN)/.test(String(l.json?.error?.message ?? ''));
}

/* Cada conta apaga os próprios documentos (as rules só deixam o dono) e depois a
   si mesma, e a sonda confere com accounts:lookup. Nada aqui lança nem para no
   primeiro erro: sobrar uma conta por causa de um erro na outra seria o pior
   resultado possível. `suspeitos` são os caminhos de ataque cuja resposta não
   foi um 403 limpo (o documento pode ter sido gravado). Devolve os uids que não
   deu para confirmar apagados. */
async function limpa({ pede, apiKey, doc, contas, registra, suspeitos = new Set() }){
  const sobras = [];
  for(const conta of contas){
    for(const colecao of ['dados', 'perfis', 'push']){
      try{
        const r = await pede('DELETE', doc(`${colecao}/${conta.uid}`), { token: conta.idToken });
        if(r.status === 404) continue;
        const c = classifica('sucesso', r);
        if(!c.ok) registra(`limpeza: ${conta.rotulo} apaga ${colecao}/${conta.uid}`, false, c.detalhe);
      }catch{ /* segue para o próximo documento */ }
    }
    /* (A linha de falha acima leva o uid real de propósito: com a conta apagada logo
       depois, é a única pista de qual documento ficou no banco; uid é opaco e não
       é segredo.)
       404 e, onde o ataque foi barrado, 403 são o esperado e ficam em silêncio.
       O que não pode é um caminho suspeito continuar lá: aí a linha mostra o
       caminho REAL (com o uid), para quem for limpar saber o que apagar. */
    for(const caminho of caminhosDeAtaque(conta.uid)){
      try{
        const r = await pede('DELETE', doc(caminho), { token: conta.idToken });
        if(r.erroRede === undefined && (ehSucesso(r.status) || r.status === 404)) continue;
        if(r.status === 403 && !suspeitos.has(caminho)) continue;
        registra(`limpeza: resto de ataque em ${caminho}`, false, classifica('sucesso', r).detalhe);
      }catch{ /* segue */ }
    }
    /* Conta apagada = accounts:delete devolveu 2xx (em alguma tentativa) E o
       lookup confirma a ausência. Na 2ª tentativa o delete responde "usuário não
       existe", por isso o 2xx anterior é lembrado. */
    let apagou = false, apagada = false;
    for(let tentativa = 0; tentativa < 2 && !apagada; tentativa++){
      try{
        const d = await pede('POST', `${IDENTITY}/accounts:delete?key=${apiKey}`, { corpo: { idToken: conta.idToken } });
        if(d.erroRede === undefined && ehSucesso(d.status)) apagou = true;
        const l = await pede('POST', `${IDENTITY}/accounts:lookup?key=${apiKey}`, { corpo: { idToken: conta.idToken }, lerJson: true });
        apagada = apagou && lookupConfirmaAusencia(l);
      }catch{ /* tenta de novo, depois vira sobra */ }
    }
    if(!apagada) sobras.push(conta.uid);
  }
  return sobras;
}

export async function rodaSonda({ fetch, apiKey, projeto, log = () => {}, aleatorio = () => randomBytes(6).toString('hex') }){
  const raizDocs = `https://firestore.googleapis.com/v1/projects/${projeto}/databases/(default)/documents`;
  const doc = caminho => `${raizDocs}/${caminho}`;
  const pede = (metodo, url, opcoes) => requisita(fetch, metodo, url, opcoes);

  const linhas = [];
  const registra = (nome, ok, detalhe) => {
    linhas.push({ nome, ok, detalhe });
    log(`${ok ? '✔' : '✗'} ${nome} (${detalhe})`);
  };
  const checa = (nome, esperado, resultado) => {
    const { ok, detalhe } = classifica(esperado, resultado);
    registra(nome, ok, detalhe);
  };

  const contas = [];   // criadas até agora: a limpeza do finally olha esta lista
  const suspeitos = new Set();   // caminhos de ataque que não deram 403 limpo (ver limpa)
  let sobras = [];
  try{
    /* sonda-<papel>-<timestamp>-<aleatório>: o timestamp diz, no console do Auth,
       qual execução deixou sobra; o aleatório impede colisão na mesma hora. */
    const id = aleatorio(), agora = Date.now();
    const emailDe = papel => `sonda-${papel}-${agora}-${id}@example.com`;
    const ana = await criaConta(pede, apiKey, 'Ana', emailDe('ana'));
    contas.push(ana);
    const bento = await criaConta(pede, apiKey, 'Bento', emailDe('bento'));
    contas.push(bento);

    const dadosAna = `dados/${ana.uid}`, perfilAna = `perfis/${ana.uid}`, pushAna = `push/${ana.uid}`;
    const dadosBento = `dados/${bento.uid}`, perfilBento = `perfis/${bento.uid}`, pushBento = `push/${bento.uid}`;
    const gravaComo = (conta, caminho, obj, mascara = '') =>
      pede('PATCH', doc(caminho) + mascara, { token: conta.idToken, corpo: documento(obj) });
    const perfil = email => ({ email, criado: new Date().toISOString(), tz: 'America/Sao_Paulo', nome: 'Sonda', origem: 'outro' });
    const mascara = campo => `?updateMask.fieldPaths=${campo}`;

    /* ----- Controles positivos: o que as rules permitem tem de funcionar ----- */
    checa('controle: Ana grava dados/<ana>', 'sucesso', await gravaComo(ana, dadosAna, blobValido()));
    checa('controle: Ana lê dados/<ana>', 'sucesso', await pede('GET', doc(dadosAna), { token: ana.idToken }));
    checa('controle: Ana cria perfis/<ana>', 'sucesso', await gravaComo(ana, perfilAna, perfil(ana.email)));
    /* Os ataques de update em perfis mandam só o campo proibido com updateMask. Se
       o servidor ignorasse a máscara, o PATCH viraria substituição do documento
       por um campo só e levaria 403 pelo motivo errado (falta email e criado), e a
       sonda daria verde mesmo com a regra de update frouxa. Este controle manda a
       mesma forma com um campo PERMITIDO: só dá certo se a máscara for honrada. */
    checa('controle: Ana atualiza o próprio nome em perfis/<ana> via updateMask', 'sucesso',
      await gravaComo(ana, perfilAna, { nome: 'Sonda 2' }, mascara('nome')));
    checa('controle: Bento grava dados/<bento>', 'sucesso', await gravaComo(bento, dadosBento, blobValido()));
    checa('controle: Bento cria perfis/<bento>', 'sucesso', await gravaComo(bento, perfilBento, perfil(bento.email)));
    /* Sem endpoint nenhum: o cron de push não tem para onde mandar e ignora. */
    checa('controle: Bento grava push/<bento>', 'sucesso', await gravaComo(bento, pushBento, { tokens: {} }));
    const antes = await pede('GET', doc(dadosBento), { token: bento.idToken, lerJson: true });
    checa('controle: Bento lê dados/<bento>', 'sucesso', antes);
    const updateTimeAntes = antes.json?.updateTime;

    /* ----- Ataques ----- */
    const consultaGrupo = { structuredQuery: { from: [{ collectionId: 'dados', allDescendants: true }] } };
    const consultaDoBento = {
      structuredQuery: {
        from: [{ collectionId: 'dados' }],
        where: { fieldFilter: {
          field: { fieldPath: '__name__' }, op: 'EQUAL',
          value: { referenceValue: `projects/${projeto}/databases/(default)/documents/${dadosBento}` },
        } },
      },
    };
    const comoAna = { token: ana.idToken };
    const corpoBlob = documento(blobValido());
    const campoPerfil = (campo, v) => ({ ...comoAna, corpo: documento({ [campo]: v }) });
    const onzeSubs = Object.fromEntries(Array.from({ length: 11 }, (_, i) => [`s${i}`, {}]));

    /* [nome, método, url, opções do pedido, status aceitos, caminho que pode virar resto] */
    const ataques = [
      // sem login
      ['sem login lê dados/<ana>',                         'GET',  doc(dadosAna), {}, BARRADO],
      ['sem login lê perfis/<ana>',                        'GET',  doc(perfilAna), {}, BARRADO],
      ['sem login tenta listar a coleção dados',           'GET',  doc('dados'), {}, BARRADO],
      ['sem login grava dados/<ana>',                      'PATCH', doc(dadosAna), { corpo: corpoBlob }, BARRADO],
      ['sem login faz runQuery de grupo em dados',         'POST', `${raizDocs}:runQuery`, { corpo: consultaGrupo }, BARRADO],

      // Ana contra o Bento
      ['Ana lê dados/<bento>',                             'GET',  doc(dadosBento), comoAna, BARRADO],
      ['Ana lê perfis/<bento>',                            'GET',  doc(perfilBento), comoAna, BARRADO],
      ['Ana lê push/<bento>',                              'GET',  doc(pushBento), comoAna, BARRADO],
      ['Ana grava dados/<bento>',                          'PATCH', doc(dadosBento), { ...comoAna, corpo: corpoBlob }, BARRADO],
      ['Ana apaga dados/<bento>',                          'DELETE', doc(dadosBento), comoAna, BARRADO],
      ['Ana grava push/<bento>',                           'PATCH', doc(pushBento), { ...comoAna, corpo: documento({ tokens: {} }) }, BARRADO],
      ['Ana tenta listar a coleção dados',                 'GET',  doc('dados'), comoAna, BARRADO],
      ['Ana tenta listar a coleção perfis',                'GET',  doc('perfis'), comoAna, BARRADO],
      ['Ana faz runQuery de grupo em dados',               'POST', `${raizDocs}:runQuery`, { ...comoAna, corpo: consultaGrupo }, BARRADO],
      ['Ana faz runQuery em dados filtrando o doc do Bento', 'POST', `${raizDocs}:runQuery`, { ...comoAna, corpo: consultaDoBento }, BARRADO],

      // Ana no próprio documento, com o que o cliente não pode gravar
      ['Ana grava plano em perfis/<ana>',                  'PATCH', doc(perfilAna) + mascara('plano'), campoPerfil('plano', 'pro'), BARRADO],
      ['Ana grava avisosOrcamento em perfis/<ana>',        'PATCH', doc(perfilAna) + mascara('avisosOrcamento'), campoPerfil('avisosOrcamento', { x: 1 }), BARRADO],
      ['Ana grava cpf em perfis/<ana>',                    'PATCH', doc(perfilAna) + mascara('cpf'), campoPerfil('cpf', '00000000000'), BARRADO],
      ['Ana muda origem para google em perfis/<ana>',      'PATCH', doc(perfilAna) + mascara('origem'), campoPerfil('origem', 'google'), BARRADO],
      ['Ana muda email em perfis/<ana>',                   'PATCH', doc(perfilAna) + mascara('email'), campoPerfil('email', emailDe('outro')), BARRADO],
      ['Ana grava dados/<ana> com chave extra admin',      'PATCH', doc(dadosAna), { ...comoAna, corpo: documento({ ...blobValido(), admin: true }) }, BARRADO],
      ['Ana grava dados/<ana> com taxaMensal 999',         'PATCH', doc(dadosAna), { ...comoAna, corpo: documento({ ...blobValido(), config: { taxaMensal: 999, topicosCustom: [] } }) }, BARRADO],
      ['Ana grava dados/<ana> com obras como mapa',        'PATCH', doc(dadosAna), { ...comoAna, corpo: documento({ ...blobValido(), obras: {} }) }, BARRADO],
      ['Ana grava push/<ana> com 11 subs',                 'PATCH', doc(pushAna), { ...comoAna, corpo: documento({ subs: onzeSubs }) }, BARRADO],
      ['Ana grava em qualquer/<ana>',                      'PATCH', doc(`qualquer/${ana.uid}`), { ...comoAna, corpo: corpoBlob }, BARRADO, `qualquer/${ana.uid}`],
      ['Ana grava em dados/<ana>/extra/x',                 'PATCH', doc(`${dadosAna}/extra/x`), { ...comoAna, corpo: corpoBlob }, BARRADO, `${dadosAna}/extra/x`],

      // caminhos estranhos
      ['Ana lê dados/..%2Fperfis%2F<bento> (caminho com ..)', 'GET', doc(`dados/..%2Fperfis%2F${bento.uid}`), comoAna, CAMINHO_ESTRANHO],
      ['Ana lê dados/__<bento>__ (id reservado)',          'GET',  doc(`dados/__${bento.uid}__`), comoAna, CAMINHO_ESTRANHO],

      // outros bancos do projeto
      ['RTDB aberto sem login (firebaseio.com)',           'GET',  `https://${projeto}-default-rtdb.firebaseio.com/.json`, {}, OUTROS_BANCOS],
      ['Storage listado sem login',                        'GET',  `https://firebasestorage.googleapis.com/v0/b/${projeto}.firebasestorage.app/o`, {}, OUTROS_BANCOS],
    ];
    for(const [nome, metodo, url, opcoes, esperado, resto] of ataques){
      const resultado = await pede(metodo, url, opcoes);
      checa(nome, esperado, resultado);
      /* Só um 403 limpo garante que nada foi gravado; 2xx ou erro de rede, não. */
      if(resto && resultado.status !== 403) suspeitos.add(resto);
    }

    /* perfis/<ana> já existe (o controle o criou), então os ataques acima exercitam
       a regra de UPDATE. A regra de CREATE é outra e é onde um cadastro novo
       tentaria nascer com plano: 'pro'. Ana apaga o próprio perfil (as rules
       deixam, é o que a exclusão de conta usa) e tenta recriá-lo estragado. Só
       roda aqui, depois dos outros ataques, que dependem do perfil existir. */
    checa('preparo: Ana apaga perfis/<ana> para atacar a criação', 'sucesso', await pede('DELETE', doc(perfilAna), comoAna));
    const criacoes = [
      ['Ana cria perfis/<ana> com plano pro',              { plano: 'pro' }],
      ['Ana cria perfis/<ana> com avisosOrcamento',        { avisosOrcamento: { x: 1 } }],
      ['Ana cria perfis/<ana> com cpf',                    { cpf: '00000000000' }],
      ['Ana cria perfis/<ana> com origem fora da lista',   { origem: 'hacker' }],
      ['Ana cria perfis/<ana> com e-mail de outra pessoa', { email: emailDe('outro') }],
    ];
    for(const [nome, estrago] of criacoes){
      checa(nome, BARRADO, await pede('PATCH', doc(perfilAna), { ...comoAna, corpo: documento({ ...perfil(ana.email), ...estrago }) }));
    }

    /* ----- Integridade: nada do que Ana tentou pode ter mexido no Bento ----- */
    const depois = await pede('GET', doc(dadosBento), { token: bento.idToken, lerJson: true });
    if(depois.erroRede !== undefined || depois.status !== 200){
      registra('integridade: dados/<bento> igual depois dos ataques', false,
        `não consegui reler (${depois.status ?? depois.erroRede}) — o dado da vítima pode ter sumido`);
    }else if(!updateTimeAntes){
      registra('integridade: dados/<bento> igual depois dos ataques', false, 'sem updateTime de referência (a leitura de controle falhou)');
    }else if(depois.json?.updateTime !== updateTimeAntes){
      registra('integridade: dados/<bento> igual depois dos ataques', false, 'dado da vítima mudou');
    }else{
      registra('integridade: dados/<bento> igual depois dos ataques', true, 'updateTime igual');
    }
  }finally{
    sobras = await limpa({ pede, apiKey, doc, contas, registra, suspeitos });
    /* Se algo estourou no meio, o erro segue para quem chamou; a sobra não pode
       sumir junto com ele. */
    if(sobras.length) log(`contas descartáveis que não consegui confirmar apagadas: ${sobras.join(', ')}`);
  }

  const falhas = linhas.filter(l => !l.ok).length;
  const ok = falhas === 0 && sobras.length === 0;
  log(ok
    ? `SONDA OK: ${linhas.length} verificações, tudo barrado, nenhuma conta sobrou.`
    : `SONDA REPROVOU: ${falhas} de ${linhas.length} verificações falharam${sobras.length ? `; ${sobras.length} conta(s) sobrou(aram)` : ''}.`);
  return { ok, linhas, sobras };
}

const USO = `Uso: node scripts/sonda-banco.mjs --producao

A sonda ataca o banco de PRODUÇÃO: cria duas contas descartáveis, tenta violar as
rules e apaga tudo no fim. Por isso só roda com --producao explícito.
Rode depois de \`npm run rules:deploy\`.`;

async function principal(argv){
  if(!argv.includes('--producao')){
    console.error(USO);
    return 2;
  }
  const raiz = fileURLToPath(new URL('..', import.meta.url));
  const { apiKey, projeto } = lerConfig(readFileSync(path.join(raiz, 'cloud.js'), 'utf8'));
  console.log(`PRODUÇÃO: projeto ${projeto}. Duas contas descartáveis serão criadas e apagadas.`);
  const r = await rodaSonda({ fetch, apiKey, projeto, log: console.log });
  return r.ok ? 0 : 1;
}

/* Compara os caminhos REAIS: process.argv[1] mantém o caminho como foi digitado
   (inclusive via symlink), enquanto import.meta.url do módulo principal já é o
   real. Comparar como texto dava falso por symlink, a CLI não rodava e o processo
   saía com 0, o mesmo código de "banco fechado". */
function executadoDireto(){
  if(!process.argv[1]) return false;
  try{ return realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url)); }
  catch{ return false; }
}
if(executadoDireto()){
  principal(process.argv.slice(2))
    .then(codigo => process.exit(codigo))
    .catch(err => { console.error(err.message || err); process.exit(1); });
}
