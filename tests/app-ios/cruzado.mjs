/* Conferência cruzada site ↔ app nativo na mesma conta, contra os emuladores do Firebase.
   Só local (precisa de simulador, Java e dos emuladores): npm run test:app-ios:cruzado.

   O "site" aqui é o SDK JavaScript do Firebase gravando como o cloud.js grava (documento
   inteiro com _atualizado do servidor), com as regras de verdade do site (dados.js, calc.js).
   O app é o build Debug no simulador:
     1. o site cria a conta e grava a v1 (obra com orçamento, obra vendida com orçamento por
        tópico estourado, obra com compra parcelada no cartão com juros e campos que só o site conhece);
     2. CruzadoUITests entra pelo formulário e confere o total e o orçamento que o calc.js calculou;
     3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
     4. CruzadoTests segue os roteiros abaixo pelas regras das telas do app: o dos gastos (lançar no Pix e no
        cartão parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a
        compra toda), o da obra (criar três, editar, marcar como pronta, vender, desfazer a venda da obra vendida
        do site e apagar a terceira criada) e o do orçamento (definir por total, passar para por tópico, editar
        por tópico guardando o tópico fora da lista e o campo que só o site conhece, trocar para o total, tirar e
        salvar vazio), gravando cada passo pelo Sincronizador; antes do orçamento e a cada passo dele, pede a este
        roteiro (POST no auxiliar) que confira o documento daquele momento contra o que o site gravaria até ali, e
        cada passo do orçamento parte do documento relido, como a pessoa abre a folha depois do eco da gravação;
     5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou), que é
        exatamente o que o site gravaria com as mesmas respostas (dados.js, com os mesmos ids), sem perder os
        campos que só o site conhece nem pôr o que a leitura acrescentaria (no documento antes do orçamento,
        gravado sem leitura no meio), e que o site soma o resultado.
   Teste pulado não passa: sem o pedido de mudança ou sem a gravação do app, o roteiro falha. */
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword } from 'firebase/auth';
import { initializeFirestore, connectFirestoreEmulator, doc, setDoc, getDocFromServer, serverTimestamp, Timestamp, terminate } from 'firebase/firestore';
import { testarNoSimulador } from '../../scripts/simulador-ios.mjs';

const require = createRequire(import.meta.url);
const C = require('../../calc.js');
const D = require('../../dados.js');

const app = initializeApp({ apiKey: 'chave-dos-emuladores', projectId: 'demo-custta-phase2', appId: '1:111188093030:web:cruzado' });
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const db = initializeFirestore(app, {});
connectFirestoreEmulator(db, '127.0.0.1', 8080);

const email = `cruzado-${Date.now()}@example.com`;
const senha = 'Casa2026x';
const { user } = await createUserWithEmailAndPassword(auth, email, senha);
const documento = doc(db, 'dados', user.uid);
const gravarComoOSite = blob => setDoc(documento, { ...blob, _atualizado: serverTimestamp() });

/* Compra no cartão com juros, montada pelo próprio calc.js: o total da obra (a soma das parcelas,
   com juros) é diferente do valor da compra. */
const compra = C.parcelamentoCartao(3000, 3, 2.5, '2026-03-10');
const { parcelas: vencimentos, ...jurosCartao } = compra;
const parcelasComJuros = vencimentos.map((p, i) => ({ id: `z${i + 1}`, grupoId: 'gz', parcela: { n: i + 1, de: compra.nParcelas },
  valor: p.valor, topico: 'eletrica', descricao: 'Fios e disjuntores', data: p.data, pagamento: 'cartao', jurosCartao }));
assert.notEqual(C.totalBruto({ gastos: parcelasComJuros }), compra.valorCompra, 'as parcelas têm juros');
const v1 = {
  obras: [
    { id: 'c1', nome: 'Casa do teste cruzado', dataInicio: '2026-01-10', fase: 'construcao', campoSoDoSite: { versao: 7 },
      valorEstimadoVenda: 600000, orcamento: { modo: 'total', total: 50000 },
      gastos: [{ id: 'x1', valor: 12345.67, topico: 'fundacao', descricao: 'Sapatas', data: '2026-02-01', pagamento: 'pix', notaSoDoSite: 'fica' }] },
    /* O orçamento por tópico com um tópico fora da lista da folha (um tópico próprio apagado) e um campo que só o site
       conhece: o app guarda os dois, e o site de antes do PR 0 da etapa 3 perdia (achado 7). */
    { id: 'c2', nome: 'Sobrado vendido', dataInicio: '2025-03-01', fase: 'vendida', venda: { valor: 480000, data: '2025-12-20' },
      orcamento: { modo: 'topicos', topicos: { estrutura: 100000, acabamento: 50000, c_apagado: 7000 }, notaDoSite: 'fica' },
      gastos: [
        { id: 'y1', valor: 120000, topico: 'estrutura', descricao: 'Laje', data: '2025-04-10', pagamento: 'pix' },
        { id: 'y2', valor: 61000.5, topico: 'acabamento', descricao: 'Porcelanato', data: '2025-09-02', pagamento: 'pix' },
        { id: 'y3', valor: 2500, topico: 'outros', descricao: 'Limpeza', data: '2025-12-01', pagamento: 'pix' },
      ] },
    { id: 'c3', nome: 'Reforma com compra parcelada', dataInicio: '2026-02-15', fase: 'construcao', gastos: parcelasComJuros },
  ],
  config: { taxaMensal: 1, topicosCustom: [] },
};
const v2 = structuredClone(v1);
v2.obras[0].gastos.push({ id: 'x2', valor: 40000, topico: 'estrutura', descricao: 'Laje', data: '2026-03-01', pagamento: 'pix' });
/* O roteiro de gastos do app (etapa 2): cada passo é o que a pessoa responde na folha do gasto. Os ids dos gastos
   novos vêm daqui, para o site montar o mesmo resultado com as regras dele. */
const HOJE = '2026-04-01';
const roteiro = [
  { acao: 'lancar', obra: 'c1', entrada: { valor: 999.99, topico: 'pintura', descricao: 'Tinta lançada no app', data: '2026-04-01', pagamento: 'pix' } },
  { acao: 'lancar', obra: 'c1', entrada: { valor: 3000, topico: 'eletrica', descricao: 'Quadro de luz', data: '2026-04-10', pagamento: 'cartao', parcelas: 3, juros: 2.5 } },
  { acao: 'editar', obra: 'c1', gasto: 'x1', entrada: { valor: 12000, topico: 'fundacao', descricao: 'Sapatas e baldrames', data: '2026-02-02', pagamento: 'cartao' } },
  { acao: 'editar', obra: 'c3', gasto: 'z2', entrada: { valor: 1100, topico: 'eletrica', descricao: 'Fios e disjuntores', data: '2026-04-10', pagamento: 'cartao' } },
  /* A z2 sai com a compra toda no fim: a parcela editada que fica no documento é a da compra lançada acima, com o
     mesmo valor e a mesma data (o total e as datas conferidos embaixo não mudam). */
  { acao: 'editar', obra: 'c1', gasto: 'app4', entrada: { valor: C.parcelamentoCartao(3000, 3, 2.5, '2026-04-10').parcelas[1].valor, topico: 'eletrica', descricao: 'Quadro de luz, 2ª parcela', data: '2026-05-10', pagamento: 'cartao' } },
  { acao: 'apagar', obra: 'c2', gasto: 'y3' },
  { acao: 'apagarCompra', obra: 'c3', grupo: 'gz' },
];
const ids = ['app1', 'app2', 'app3', 'app4', 'app5'];
/* O roteiro da obra (etapa 2, parte 3): o que a pessoa responde na folha "Nova obra" (a área com três casas, que o
   editar do site multiplicava por 1000), em "Editar obra" (a estimativa da c1 apagada), nas ações da fase e na folha
   da venda. A conferência só compara o documento final: as obras criadas que ela confere ficam (uma com tudo
   preenchido e o início diferente de HOJE, outra com início, estimativa e orçamento vazios), e a que se apaga é uma
   terceira, criada só para isso. Pela mesma razão, a c1 já tem estimativa: apagar o que era null não mudaria nada. */
const roteiroDaObra = [
  { acao: 'criar', id: 'appo1', campos: { nome: 'Galpão criado no app', dataInicio: '2026-03-16', valorEstimadoVenda: 350000, areaM2: 3.125, orcamento: 120000 } },
  { acao: 'criar', id: 'appo2', campos: { nome: 'Obra criada no app com campos vazios', dataInicio: '', valorEstimadoVenda: 0, areaM2: 50, orcamento: 0 } },
  { acao: 'criar', id: 'appo3', campos: { nome: 'Obra criada e apagada no app', dataInicio: '', valorEstimadoVenda: 0, areaM2: 50, orcamento: 0 } },
  { acao: 'editar', obra: 'c1', campos: { nome: 'Casa do teste cruzado, editada', dataInicio: '2026-01-12', valorEstimadoVenda: 0, areaM2: 180.5, orcamento: 0 } },
  { acao: 'fase', obra: 'c1', fase: 'pronta' },
  { acao: 'vender', obra: 'c1', valor: 650000, data: '2026-04-01' },
  { acao: 'desfazer', obra: 'c2' },
  { acao: 'apagarObra', obra: 'appo3' },
];
/* O roteiro do orçamento (etapa 3): o que a pessoa responde na folha "Orçamento da obra" (o modo e as linhas com valor; a
   linha que não está aqui vai vazia) e o "Tirar orçamento". A obra c3 começa sem orçamento; a c2, por tópico, com o tópico
   fora da lista e o campo do site. Cada passo é conferido no documento: a c2 termina sem orçamento, e o que o passo 3 e o
   4 guardaram só a conferência deles prova (um roteiro que só compara o fim deixaria passar a regra quebrada no meio). */
const roteiroDoOrcamento = [
  { acao: 'salvar', obra: 'c3', modo: 'total', total: 80000 },
  { acao: 'salvar', obra: 'c3', modo: 'topicos', valores: { fundacao: 30000, eletrica: 5000.5 } },
  { acao: 'salvar', obra: 'c2', modo: 'topicos', valores: { estrutura: 110000, outros: 3000 } },
  { acao: 'salvar', obra: 'c2', modo: 'total', total: 120000 },
  { acao: 'tirar', obra: 'c3' },
  { acao: 'salvar', obra: 'c2', modo: 'total', total: 0 },
];
/** As linhas da folha do orçamento do site (o topicos() do app.js): os fixos e depois os próprios, cada uma com o valor dado
    ou vazia (0), como o "Salvar" lê. */
const valoresDaFolha = (db, dados = {}) => Object.fromEntries([...C.TOPICOS.map(t => t.id), ...db.config.topicosCustom.map(t => t.id)]
  .map(id => [id, dados[id] || 0]));

/** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js; do roteiro do
    orçamento, os `passosDoOrcamento` primeiros, cada um a partir do documento relido. */
function comoOSite(blob, passosDoOrcamento = roteiroDoOrcamento.length){
  let db = D.normaliza(structuredClone(blob));
  const fila = [...ids], novoId = () => fila.shift();
  for(const p of roteiro){
    const o = db.obras.find(x => x.id === p.obra);
    if(p.acao === 'lancar') o.gastos.push(...D.gastosLancados(p.entrada, D.conferirGasto(p.entrada, null, HOJE), novoId));
    else if(p.acao === 'editar'){
      const i = o.gastos.findIndex(g => g.id === p.gasto);
      o.gastos[i] = D.gastoEditado(o.gastos[i], p.entrada, D.conferirGasto(p.entrada, o.gastos[i], HOJE));
    }
    else if(p.acao === 'apagar') o.gastos = o.gastos.filter(g => g.id !== p.gasto);
    else o.gastos = o.gastos.filter(g => g.grupoId !== p.grupo);
  }
  // A obra: formNovaObra, formEditarObra, mudarFase, a venda e o desfazer do app.js, e o apagar.
  for(const p of roteiroDaObra){
    const o = db.obras.find(x => x.id === p.obra);
    if(p.acao === 'criar'){ assert.equal(D.conferirObra(p.campos, true), null); db.obras.push(D.obraNova(p.campos, p.id, HOJE)); }
    else if(p.acao === 'editar'){ assert.equal(D.conferirObra(p.campos, false), null); db.obras[db.obras.indexOf(o)] = D.obraEditada(o, p.campos); }
    else if(p.acao === 'fase') o.fase = p.fase;
    else if(p.acao === 'vender'){ assert.equal(D.conferirVenda(p.valor, p.data, o.dataInicio, HOJE), null); o.venda = { valor: p.valor, data: p.data }; o.fase = 'vendida'; }
    else if(p.acao === 'desfazer'){ delete o.venda; o.fase = 'pronta'; }
    else db.obras = db.obras.filter(x => x.id !== p.obra);
  }
  /* O orçamento: o formOrcamento do app.js (orcamentoGravado do dados.js; vazio tira a chave) e o "Tirar orçamento". Cada passo
     parte do documento relido: a pessoa abre a folha depois de chegar o eco da gravação anterior, e o site troca o db pelo
     documento normalizado (bootCloud do app.js), como o app (Sincronizador.recebeu) e como um outro aparelho o lê; a leitura
     põe afazeres e venda null nas obras que não têm (as criadas no app, a da venda desfeita). */
  for(const p of roteiroDoOrcamento.slice(0, passosDoOrcamento)){
    db = D.normaliza(db);
    const o = db.obras.find(x => x.id === p.obra);
    const novo = p.acao === 'tirar' ? null : D.orcamentoGravado(o.orcamento, p.modo, p.total || 0, valoresDaFolha(db, p.valores));
    if(novo) o.orcamento = novo; else delete o.orcamento;
  }
  return db;
}

/* O que a lista de obras do site mostra (app.js, renderInicio): total curto na tela, completo para o
   leitor de tela, e a linha do orçamento. */
const textoOrcamento = o => {
  const orc = C.orcamentoObra(o);
  if(!orc) return null;
  return orc.nivel === 'passou' ? `${orc.pct}% · passou ${C.moneyCurto(-orc.sobra)}` : `${orc.pct}% do orçamento`;
};
const esperado = blob => D.normaliza(blob).obras.map(o => ({ id: o.id, nome: o.nome, total: C.money(C.totalBruto(o)), orcamento: textoOrcamento(o) }));

await gravarComoOSite(v1);

let siteMudou = false;
/* Depois de cada passo do orçamento, o app pede a conferência do documento daquele momento: 200 quando é o que o site gravaria
   com as respostas até ali, 409 com as duas versões da obra quando não é. Antes do primeiro (o passo 0), pede que este roteiro
   guarde o documento dos roteiros do gasto e da obra, gravados em seguida, sem leitura no meio: é nele que se confere que o app
   não grava o que a leitura acrescenta. */
const conferidos = [];
let antesDoOrcamento;
const auxiliar = createServer(async (req, res) => {
  if(req.method === 'POST' && req.url === '/site/mudar'){ await gravarComoOSite(v2); siteMudou = true; res.end('ok'); return; }
  const passo = /^\/app\/orcamento\/(\d+)$/.exec(req.url);
  if(req.method === 'POST' && passo){
    const n = Number(passo[1]);
    const doc = (await getDocFromServer(documento)).data();
    delete doc._atualizado;
    if(n === 0){ conferidos.push(n); antesDoOrcamento = doc; res.end('ok'); return; }
    const doSite = comoOSite(v2, n);
    const obra = roteiroDoOrcamento[n - 1].obra;
    const igual = C.canon(doc) === C.canon(doSite);
    conferidos.push(n);
    if(!igual){
      res.statusCode = 409;
      const daObra = d => JSON.stringify(d.obras.find(o => o.id === obra)?.orcamento ?? null);
      res.end(`passo ${n} (${obra}): o app gravou ${daObra(doc)}, o site gravaria ${daObra(doSite)}`);
      return;
    }
    res.end('ok');
    return;
  }
  res.statusCode = 404; res.end();
});
await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));

const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
  CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_ROTEIRO_OBRA: JSON.stringify(roteiroDaObra), CUSTTA_HOJE: HOJE,
  CUSTTA_ROTEIRO_ORCAMENTO: JSON.stringify(roteiroDoOrcamento) };
let antesDoApp;
try{
  await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
  assert.ok(siteMudou, 'o teste de tela não pediu a mudança do site: foi pulado (o ambiente chegou até ele?)');
  antesDoApp = (await getDocFromServer(documento)).data()._atualizado;
  await testarNoSimulador(['CusttaTests/CruzadoTests'], env);
}finally{ auxiliar.close(); }
assert.deepEqual(conferidos, [0, ...roteiroDoOrcamento.map((_, i) => i + 1)], 'o app pediu a conferência do documento antes do orçamento e de cada passo dele, na ordem');

const final = (await getDocFromServer(documento)).data();
assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atualizado do servidor');
assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
delete final._atualizado;
assert.equal(C.canon(antesDoOrcamento), C.canon(comoOSite(v2, 0)), 'os roteiros do gasto e da obra gravaram o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
const v3 = comoOSite(v2);
assert.equal(C.canon(final), C.canon(v3), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
const porId = id => final.obras.find(o => o.id === id);
assert.deepEqual(final.obras.map(o => o.id), ['c1', 'c2', 'c3', 'appo1', 'appo2'], 'as obras criadas no app no fim, como o push do site; a terceira, criada só para isso, foi apagada');
const c1 = porId('c1'), c2 = porId('c2'), c3 = porId('c3'), criada = porId('appo1'), vazia = porId('appo2');
assert.deepEqual(c1.campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece, numa obra editada e vendida no app');
const x1 = c1.gastos.find(g => g.id === 'x1');
assert.equal(x1.notaSoDoSite, 'fica', 'campo de gasto que só o site conhece, num gasto editado no app');
assert.equal(x1.pagamento, 'cartao', 'a edição trocou o Pix pelo cartão');
assert.ok(!('jurosCartao' in x1), 'cartão na edição não ganha juros nem parcelas (app.js:1071)');
assert.equal(c3.gastos.length, 0, 'a compra toda da obra c3 saiu, inclusive a parcela editada');
assert.deepEqual(c2.gastos.map(g => g.id), ['y1', 'y2'], 'gasto de obra vendida também se apaga');
const compraDoApp = c1.gastos.filter(g => g.grupoId === 'app2');
assert.deepEqual(compraDoApp.map(g => [g.parcela.n, g.parcela.de, g.data]), [[1, 3, '2026-04-10'], [2, 3, '2026-05-10'], [3, 3, '2026-06-10']],
  'a compra em 3x lançada no app: as parcelas e as datas do site');
const cartao = C.parcelamentoCartao(3000, 3, 2.5, '2026-04-10');
assert.deepEqual(compraDoApp[0].jurosCartao, { taxaMensal: 2.5, valorCompra: 3000, nParcelas: 3, totalCompra: cartao.totalCompra, jurosCompra: cartao.jurosCompra },
  'as condições da compra, iguais nas parcelas');
assert.equal(C.money(C.totalBruto(D.normaliza(final).obras.find(o => o.id === 'c1'))), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
// A obra (etapa 2, parte 3).
const antes = id => antesDoOrcamento.obras.find(o => o.id === id);
assert.ok(!('afazeres' in antes('appo1')) && !('venda' in antes('appo1')), 'a obra criada no app vai como o obraNova do site: sem afazeres e sem venda (a leitura acrescenta)');
assert.equal(criada.areaM2, 3.125, 'a área com três casas chega inteira');
assert.deepEqual(criada.orcamento, { modo: 'total', total: 120000 }, 'o orçamento total da obra nova');
assert.equal(criada.valorEstimadoVenda, 350000);
assert.equal(criada.dataInicio, '2026-03-16', 'o início digitado na obra nova, não o de hoje');
assert.deepEqual([vazia.dataInicio, vazia.valorEstimadoVenda, 'orcamento' in vazia], [HOJE, null, false],
  'a obra criada com campos vazios vai como no site: começa hoje, estimativa null e sem orçamento');
assert.equal(c1.nome, 'Casa do teste cruzado, editada');
assert.equal(c1.valorEstimadoVenda, null, 'a estimativa apagada na edição vira null, como no site');
assert.equal(c1.areaM2, 180.5);
assert.deepEqual(c1.orcamento, { modo: 'total', total: 50000 }, 'editar a obra não mexe no orçamento');
assert.equal(c1.fase, 'vendida');
assert.deepEqual(c1.venda, { valor: 650000, data: '2026-04-01' }, 'a venda como o site grava');
assert.equal(c2.fase, 'pronta');
assert.ok(!('venda' in antes('c2')), 'desfazer a venda tira a chave, como o delete do site');
// O orçamento (etapa 3): o fim do roteiro tira os dois (o que cada passo gravou, a conferência dele provou).
assert.ok(!('orcamento' in c2) && !('orcamento' in c3), 'tirar e salvar vazio tiram a chave, como o delete do site');
await terminate(db);
console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e os roteiros do gasto, da obra e do orçamento gravaram o que o site gravaria, passo a passo no orçamento, sem perder nada');
process.exit(0);
