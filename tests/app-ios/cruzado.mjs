/* Conferência cruzada site ↔ app nativo na mesma conta, contra os emuladores do Firebase.
   Só local (precisa de simulador, Java e dos emuladores): npm run test:app-ios:cruzado.

   O "site" aqui é o SDK JavaScript do Firebase gravando como o cloud.js grava (documento
   inteiro com _atualizado do servidor), com as regras de verdade do site (dados.js, calc.js).
   O app é o build Debug no simulador:
     1. o site cria a conta e grava a v1 (obra com orçamento, obra vendida com orçamento por
        tópico estourado, obra com compra parcelada no cartão com juros e campos que só o site conhece);
     2. CruzadoUITests entra pelo formulário e confere o total e o orçamento que o calc.js calculou;
     3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
     4. CruzadoTests segue o roteiro de gastos abaixo pelas regras das telas do app (lançar no Pix e no cartão
        parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a compra
        toda), gravando cada passo pelo Sincronizador;
     5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou), que é
        exatamente o que o site gravaria com as mesmas respostas (dados.js, com os mesmos ids), sem perder os
        campos que só o site conhece, e que o site soma o resultado.
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
      orcamento: { modo: 'total', total: 50000 },
      gastos: [{ id: 'x1', valor: 12345.67, topico: 'fundacao', descricao: 'Sapatas', data: '2026-02-01', pagamento: 'pix', notaSoDoSite: 'fica' }] },
    { id: 'c2', nome: 'Sobrado vendido', dataInicio: '2025-03-01', fase: 'vendida', venda: { valor: 480000, data: '2025-12-20' },
      orcamento: { modo: 'topicos', topicos: { estrutura: 100000, acabamento: 50000 } },
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
  { acao: 'apagar', obra: 'c2', gasto: 'y3' },
  { acao: 'apagarCompra', obra: 'c3', grupo: 'gz' },
];
const ids = ['app1', 'app2', 'app3', 'app4', 'app5'];
/** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js. */
function comoOSite(blob){
  const db = D.normaliza(structuredClone(blob));
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
const auxiliar = createServer(async (req, res) => {
  if(req.method === 'POST' && req.url === '/site/mudar'){ await gravarComoOSite(v2); siteMudou = true; res.end('ok'); return; }
  res.statusCode = 404; res.end();
});
await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));

const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
  CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_HOJE: HOJE };
let antesDoApp;
try{
  await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
  assert.ok(siteMudou, 'o teste de tela não pediu a mudança do site: foi pulado (o ambiente chegou até ele?)');
  antesDoApp = (await getDocFromServer(documento)).data()._atualizado;
  await testarNoSimulador(['CusttaTests/CruzadoTests'], env);
}finally{ auxiliar.close(); }

const final = (await getDocFromServer(documento)).data();
assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atualizado do servidor');
assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
delete final._atualizado;
const v3 = comoOSite(v2);
assert.equal(C.canon(final), C.canon(D.normaliza(v3)), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
assert.deepEqual(final.obras[0].campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece');
const x1 = final.obras[0].gastos.find(g => g.id === 'x1');
assert.equal(x1.notaSoDoSite, 'fica', 'campo de gasto que só o site conhece, num gasto editado no app');
assert.equal(x1.pagamento, 'cartao', 'a edição trocou o Pix pelo cartão');
assert.ok(!('jurosCartao' in x1), 'cartão na edição não ganha juros nem parcelas (app.js:1071)');
const z = final.obras[2].gastos;
assert.equal(z.length, 0, 'a compra toda da obra c3 saiu, inclusive a parcela editada');
assert.deepEqual(final.obras[1].gastos.map(g => g.id), ['y1', 'y2'], 'gasto de obra vendida também se apaga');
const compraDoApp = final.obras[0].gastos.filter(g => g.grupoId === 'app2');
assert.deepEqual(compraDoApp.map(g => [g.parcela.n, g.parcela.de, g.data]), [[1, 3, '2026-04-10'], [2, 3, '2026-05-10'], [3, 3, '2026-06-10']],
  'a compra em 3x lançada no app: as parcelas e as datas do site');
const cartao = C.parcelamentoCartao(3000, 3, 2.5, '2026-04-10');
assert.deepEqual(compraDoApp[0].jurosCartao, { taxaMensal: 2.5, valorCompra: 3000, nParcelas: 3, totalCompra: cartao.totalCompra, jurosCompra: cartao.jurosCompra },
  'as condições da compra, iguais nas parcelas');
assert.equal(C.money(C.totalBruto(D.normaliza(final).obras[0])), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
await terminate(db);
console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e o roteiro de gastos do app gravou o que o site gravaria, sem perder nada');
process.exit(0);
