/* Vetores de teste compartilhados entre o site e o app nativo (docs/specs/2026-10-06-app-nativo-design.md,
   "Testes e validação"). Roda as funções de verdade do calc.js, do dados.js e do push.js sobre casos
   fixos e grava entrada e saída em tests/vetores/calc.json. O teste do site (tests/vetores.test.mjs)
   confere que o arquivo está em dia com o código; o núcleo Swift (app-ios/CusttaNucleo) lê o mesmo
   arquivo. Se as duas cópias das regras divergirem, um dos lados falha.

   Determinístico: "hoje" vem sempre do caso, o fuso é America/Sao_Paulo e a localidade pt_BR.UTF-8
   (sem os dois certos, o script se executa de novo com eles). Os ids e as datas dos casos são os que o
   site gera (base 36 e AAAA-MM-DD): para eles o localeCompare do calc.js dá a mesma ordem em qualquer
   língua.

   Uso: npm run vetores                              grava tests/vetores/calc.json
        node scripts/vetores-calc.mjs --imprimir     só imprime (o teste do site usa) */
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const FUSO = 'America/Sao_Paulo';
/* O calc.js ordena com localeCompare sem locale, que segue a localidade do processo e muda de máquina
   para máquina (o Mac do Giovani roda com en_US.UTF-8). pt_BR porque é a do navegador de quem usa o
   site: os vetores guardam o que o localeCompare faz em produção. O ICU do Node lê a variável e usa os
   próprios dados, sem depender da localidade instalada no sistema. */
const LOCALIDADE = 'pt_BR.UTF-8';
if(process.env.TZ !== FUSO || process.env.LC_ALL !== LOCALIDADE){
  const r = spawnSync(process.execPath, process.argv.slice(1), { stdio: 'inherit', env: { ...process.env, TZ: FUSO, LC_ALL: LOCALIDADE } });
  process.exit(r.status ?? 1);
}
if(Intl.DateTimeFormat().resolvedOptions().timeZone !== FUSO) throw new Error(`fuso ${FUSO} não pegou`);
if(new Intl.Collator().resolvedOptions().locale !== 'pt-BR') throw new Error(`localidade ${LOCALIDADE} não pegou`);

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const C = require('../calc.js');
const D = require('../dados.js');
const P = require('../push.js');

/* ---------- registro dos casos ---------- */
const grupos = {};
function semNaoFinito(v, onde){
  if(typeof v === 'number' && !Number.isFinite(v)) throw new Error(`${onde}: saída com ${v} não cabe em JSON`);
  if(v && typeof v === 'object') for(const x of Object.values(v)) semNaoFinito(x, onde);
}
/* Chama fn com uma cópia dos argumentos (nenhuma função pode alterar o caso gravado). */
function caso(grupo, nome, args, fn){
  const saida = fn(...structuredClone(args));
  semNaoFinito(saida, `${grupo} / ${nome}`);
  (grupos[grupo] ||= []).push({ caso: nome, args, saida: saida === undefined ? null : saida });
}
const calc = nome => (nomeCaso, ...args) => caso(`calc.${nome}`, nomeCaso, args, C[nome]);
const constante = (grupo, valor) => { grupos[grupo] = [{ caso: 'valor', args: [], saida: valor }]; };

/* ---------- obras de exemplo, normalizadas como o app as vê ---------- */
const HOJE = '2026-10-06';
const BLOB = D.normaliza({
  obras: [
    { id: 'o1', nome: 'Casa Alphaville', dataInicio: '2025-03-10', fase: 'construcao',
      valorEstimadoVenda: 1250000, areaM2: 210,
      orcamento: { modo: 'topicos', topicos: { fundacao: 90000, estrutura: 250000, c_mgf1abcd: 1000 } },
      gastos: [
        { id: 'g01', valor: 98000, topico: 'fundacao', descricao: 'Sapatas e baldrame', data: '2025-03-20', pagamento: 'pix' },
        { id: 'g02', valor: 231000, topico: 'estrutura', descricao: 'Laje do térreo', data: '2025-06-02', pagamento: 'pix' },
        { id: 'g03', valor: 12000.5, topico: 'hidraulica', descricao: 'Tubos e conexões', data: '2025-08-15', pagamento: 'pix' },
        { id: 'g04', valor: 3000, topico: 'pintura', descricao: 'Tinta acrílica', data: '2025-08-15', pagamento: 'pix' },
        { id: 'g05a', grupoId: 'gr1', parcela: { n: 1, de: 3 }, valor: 1033.34, topico: 'eletrica', descricao: 'Fios', data: '2026-09-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
        { id: 'g05b', grupoId: 'gr1', parcela: { n: 2, de: 3 }, valor: 1033.33, topico: 'eletrica', descricao: 'Fios', data: '2026-10-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
        { id: 'g05c', grupoId: 'gr1', parcela: { n: 3, de: 3 }, valor: 1033.33, topico: 'eletrica', descricao: 'Fios', data: '2026-11-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
      ],
      afazeres: [{ id: 'a1', texto: 'Comprar tinta', feito: false }, { id: 'a2', texto: 'Pagar pedreiro', feito: true }] },
    { id: 'o2', nome: 'Sobrado Centro', dataInicio: '2024-01-15', fase: 'vendida',
      venda: { valor: 980000, data: '2025-02-10' }, valorEstimadoVenda: 950000, areaM2: 180,
      orcamento: { modo: 'total', total: 700000 },
      gastos: [
        { id: 'h01', valor: 150000, topico: 'terreno', descricao: 'Terreno', data: '2024-01-15', pagamento: 'pix' },
        { id: 'h02', valor: 320000.75, topico: 'alvenaria', descricao: 'Blocos e mão de obra', data: '2024-05-31', pagamento: 'pix' },
        { id: 'h03', valor: 85000, topico: 'acabamento', descricao: 'Porcelanato', data: '2024-12-01', pagamento: 'cartao' },
        { id: 'h04', valor: 4500, topico: 'outros', descricao: 'Limpeza depois da venda', data: '2025-03-01', pagamento: 'pix' },
      ] },
    { id: 'o3', nome: 'Terreno novo', dataInicio: '2026-10-01', fase: 'construcao', gastos: [] },
    { id: 'o4', nome: 'Pronta Jardins', dataInicio: '2025-11-01', fase: 'pronta', valorEstimadoVenda: 610000, areaM2: 95.5,
      orcamento: { modo: 'total', total: 400000 },
      gastos: [
        { id: 'j01', valor: 200000, topico: 'estrutura', descricao: 'Estrutura', data: '2026-01-31', pagamento: 'pix' },
        { id: 'j02', valor: 165000, topico: 'maoobra', descricao: 'Equipe', data: '2026-02-28', pagamento: 'pix' },
        { id: 'j03', valor: 7000, topico: 'c_mgf1abcd', descricao: 'Automação da garagem', data: '2026-03-31', pagamento: 'pix' },
      ] },
  ],
  config: { taxaMensal: 1, topicosCustom: [{ id: 'c_mgf1abcd', nm: 'Automação', ic: 'etiqueta' }] },
});
const [O1, O2, O3, O4] = BLOB.obras;
const TOPICOS_MAPA = Object.fromEntries([...C.TOPICOS, ...BLOB.config.topicosCustom].map(t => [t.id, t]));

/* ---------- constantes ---------- */
constante('calc.DIAS_MES', C.DIAS_MES);
constante('calc.LIMITE_BLOB', C.LIMITE_BLOB);
constante('calc.AVISO_BLOB', C.AVISO_BLOB);
constante('calc.TOPICOS', C.TOPICOS);

/* ---------- fila de escrita ---------- */
const tamanho = calc('tamanhoBlob');
tamanho('blob vazio', D.normaliza(null));
tamanho('blob de exemplo', BLOB);
tamanho('acentos, emoji e escapes', { a: 'ção 😀🏗️', b: 'aspas "x" e barra \\', c: 'linha\nnova\ttab\u0001', d: [1, 0.1, 1e21, -1e-7, true, null] });
tamanho('chaves numéricas e unicode', { '10': 1, '2': 2, 'é': 3, '😀': [{}], '': '' });
const cabe = calc('blobCabe');
cabe('blob de exemplo cabe', BLOB);
/* Blobs grandes não vão inteiros no arquivo: o caso diz como montar (texto de N letras "a"
   no campo `preenchimento`) e o tamanho que dá; os dois lados montam igual. */
for(const alvo of [C.LIMITE_BLOB, C.LIMITE_BLOB + 1]){
  const base = { obras: [], config: { taxaMensal: 1, topicosCustom: [] }, preenchimento: '' };
  const vezes = alvo - C.tamanhoBlob(base);
  const blob = { ...base, preenchimento: 'a'.repeat(vezes) };
  if(C.tamanhoBlob(blob) !== alvo) throw new Error('blob grande com tamanho errado');
  (grupos['calc.blobCabe'] ||= []).push({ caso: `${alvo} bytes`, gerar: { base, campo: 'preenchimento', letra: 'a', vezes }, tamanho: alvo, saida: C.blobCabe(blob) });
}
const terminal = calc('erroEhTerminal');
for(const code of ['permission-denied', 'unauthenticated', 'invalid-argument', 'not-found', 'failed-precondition', 'unimplemented', 'out-of-range'])
  terminal(code, { code });
terminal('prefixo e sublinhado', { code: 'firestore/PERMISSION_DENIED' });
terminal('maiúsculas', { code: 'Unauthenticated' });
terminal('rede caiu', { code: 'unavailable' });
terminal('prazo', { code: 'deadline-exceeded' });
terminal('sem code', {});
terminal('code vazio', { code: '' });
terminal('code numérico', { code: 7 });
terminal('erro nulo', null);
const backoff = calc('proximoBackoff');
for(const n of [0, 1, 2, 3, 4, 5, 6, 30, -1, 2.7, '3', null, 'abc']) backoff(`tentativa ${JSON.stringify(n)}`, n);

/* ---------- datas ---------- */
const local = 'calc.dataLocalISO';
for(const [nome, ms] of [
  ['22h30 em Brasília ainda é o dia anterior em UTC', Date.UTC(2026, 7, 26, 1, 30)],
  ['meia-noite em Brasília', Date.UTC(2026, 7, 26, 3, 0)],
  ['um milissegundo antes da meia-noite', Date.UTC(2026, 7, 26, 2, 59, 59, 999)],
  ['horário de verão antigo (2018)', Date.UTC(2018, 10, 4, 2, 30)],
  ['época', 0],
]) (grupos[local] ||= []).push({ caso: nome, args: [ms], saida: C.dataLocalISO(new Date(ms)) });
const valida = calc('dataISOValida');
for(const s of ['2026-02-28', '2026-02-29', '2026-02-30', '2028-02-29', '2100-02-29', '2000-02-29', '2026-04-31',
  '2026-13-01', '2026-00-10', '2026-1-01', '20260101', '0050-01-01', '0099-12-31', '0100-01-01', '9999-12-31', '', 'abcd-ef-gh'])
  valida(JSON.stringify(s), s);
valida('nulo', null);
const igualOuDepois = calc('dataIgualOuDepois');
igualOuDepois('depois', '2026-03-01', '2026-01-01');
igualOuDepois('igual', '2026-01-01', '2026-01-01');
igualOuDepois('antes', '2025-12-31', '2026-01-01');
igualOuDepois('data inválida (30/02)', '2026-02-30', '2026-01-01');
igualOuDepois('mínimo inválido', '2026-03-01', '2026-02-30');
const dias = calc('diasEntre');
dias('mesmo dia', '2026-07-04', '2026-07-04');
dias('um dia', '2026-07-04', '2026-07-05');
dias('nunca negativo', '2026-07-05', '2026-07-04');
dias('virada de ano', '2025-12-31', '2026-01-01');
dias('ano bissexto', '2028-02-01', '2028-03-01');
dias('início do horário de verão antigo', '2018-11-03', '2018-11-05');
dias('fim do horário de verão antigo', '2019-02-16', '2019-02-18');
dias('seis meses (exemplo do spec)', '2026-07-04', '2027-01-04');
const meses = calc('addMesesClampado');
meses('31/01 + 1 mês', '2026-01-31', 1);
meses('31/01 + 1 mês em ano bissexto', '2028-01-31', 1);
meses('31/01 + 13 meses', '2026-01-31', 13);
meses('30/11 + 3 meses', '2026-11-30', 3);
meses('zero meses', '2026-05-15', 0);
meses('virada de ano', '2026-12-15', 1);
meses('36 meses', '2026-02-28', 36);

/* ---------- correção e lucro ---------- */
const corr = calc('corrigido');
corr('mesmo dia', 10000, '2026-07-04', '2026-07-04', 1);
corr('taxa zero', 10000, '2026-07-04', '2027-07-04', 0);
corr('30 dias a 1%', 10000, '2026-07-04', '2026-08-03', 1);
corr('seis meses (exemplo do spec)', 10000, '2026-07-04', '2027-01-04', 1);
corr('gasto depois do fim conta pelo valor', 5000, '2026-08-01', '2026-07-01', 1.5);
corr('taxa máxima', 1234.56, '2020-01-01', '2026-10-06', 20);
const bruto = calc('totalBruto');
for(const o of BLOB.obras) bruto(o.nome, o);
const totalCorr = calc('totalCorrigido');
for(const o of BLOB.obras) for(const taxa of [1, 0.85, 20]) totalCorr(`${o.nome} a ${taxa}%`, o, taxa, HOJE);
totalCorr('vendida corrige até a venda, mesmo com outro hoje', O2, 1, '2030-01-01');
const lucro = calc('lucroVenda');
for(const o of BLOB.obras) lucro(o.nome, o, 1);
lucro('gasto depois da venda entra pelo valor', O2, 2);
const mesesObra = calc('mesesDeObra');
for(const o of BLOB.obras) mesesObra(o.nome, o, HOJE);
mesesObra('vendida para na venda', O2, '2030-01-01');
const m2 = calc('precoPorM2');
m2('normal', 3000000, 300);
m2('área decimal', 610000, 95.5);
m2('sem área', 500000, null);
m2('área zero', 500000, 0);
m2('valor zero', 0, 100);
m2('valor negativo', -10, 100);

/* ---------- TIR e simulador ---------- */
const tir = calc('tirMensal');
tir('obra com gastos espalhados', O1.gastos, 1250000, HOJE);
tir('vendida, gasto depois da venda conta como pago nela', O2.gastos, O2.venda.valor, O2.venda.data);
tir('daqui a 12 meses', O4.gastos, 610000, '2027-10-06');
tir('venda abaixo do custo (TIR negativa)', O4.gastos, 300000, HOJE);
tir('sem venda', O1.gastos, 0, HOJE);
tir('sem gastos', [], 100000, HOJE);
tir('nenhum mês passou', [{ id: 'x', valor: 1000, data: HOJE }], 2000, HOJE);
tir('sem raiz: venda menor que gasto feito no próprio dia', [{ id: 'x', valor: 1000, data: '2026-01-01' }, { id: 'y', valor: 5000, data: HOJE }], 3000, HOJE);
tir('sem raiz: venda absurda passa de 1000% ao mês', [{ id: 'x', valor: 1, data: '2026-01-01' }], 1e15, HOJE);
/* Os limites da bissecção (−99% a +1000% ao mês) também são regra: R$ 1 gasto um mês antes. */
for(const [nome, venda] of [['acima de +1000% ao mês não tem raiz', 12.03], ['perto do teto de +1000%', 10.6],
  ['abaixo de −99% ao mês não tem raiz', 0.0045], ['perto do piso de −99%', 0.014]])
  tir(nome, [{ id: 'x', valor: 1, data: '2026-01-01' }], venda, '2026-02-01');
const acima = calc('rendimentoAcima');
acima('TIR acima do banco', 2.5, 1);
acima('TIR abaixo do banco', 0.4, 1);
acima('sem TIR', null, 1);
const resumo = calc('resumoVenda');
resumo('lucro', 1250000, 1000000);
resumo('prejuízo', 800000, 1000000);
resumo('venda zero', 0, 1000);
resumo('custo zero', 1000, 0);

/* ---------- séries dos gráficos ---------- */
const evo = calc('serieEvolucao');
for(const o of BLOB.obras) evo(o.nome, o, 1, HOJE);
evo('mais de 24 meses guarda só os últimos 24', { ...O2, venda: null, fase: 'construcao' }, 1, '2026-10-06');
evo('taxa alta', O4, 20, HOJE);
const mensal = calc('serieMensal');
for(const o of BLOB.obras) mensal(o.nome, o.gastos);
mensal('meses vazios no meio viram zero', [{ id: 'a', valor: 1, data: '2025-01-10' }, { id: 'b', valor: 2, data: '2025-04-02' }, { id: 'c', valor: 3, data: '2025-04-30' }]);
mensal('mais de 24 meses', [{ id: 'a', valor: 1, data: '2022-01-10' }, { id: 'b', valor: 2, data: '2025-04-02' }]);
mensal('ano 0050: o mês sai sem zeros e a série vai até a guarda de 600', [{ id: 'a', valor: 1, data: '0050-01-10' }, { id: 'b', valor: 2, data: '0050-03-02' }]);
const agregada = calc('serieEvolucaoAgregada');
agregada('todas as obras', BLOB.obras, 1, HOJE);
agregada('sem gastos', [O3], 1, HOJE);

/* ---------- a pagar, recentes e filtro ---------- */
const apagar = calc('aPagar');
apagar('janela de 30 dias', BLOB.obras, HOJE, 30);
apagar('padrão de 30 dias', BLOB.obras, HOJE);
apagar('limite exato no 30º dia', [{ id: 'z', gastos: [{ id: 'z1', valor: 100, data: '2026-08-05' }, { id: 'z2', valor: 200, data: '2026-08-06' }] }], '2026-07-06', 30);
apagar('mesmo dia não entra', [{ id: 'z', gastos: [{ id: 'z1', valor: 100, data: '2026-07-06' }] }], '2026-07-06', 30);
apagar('empate de data mantém a ordem das obras', [
  { id: 'p', gastos: [{ id: 'p1', valor: 1, data: '2026-07-10' }] },
  { id: 'q', gastos: [{ id: 'q1', valor: 2, data: '2026-07-10' }, { id: 'q2', valor: 3, data: '2026-07-08' }] }], '2026-07-06', 30);
const recentes = calc('gastosRecentes');
recentes('cinco mais recentes', BLOB.obras, 5);
recentes('padrão', BLOB.obras);
recentes('n negativo conta do fim, como o slice', BLOB.obras, -2);
recentes('desempate pelo id', [{ id: 'a', nome: 'A', gastos: [{ id: 'g1', valor: 1, data: '2026-01-02' }, { id: 'g3', valor: 3, data: '2026-01-02' }] },
  { id: 'b', nome: 'B', gastos: [{ id: 'g2', valor: 2, data: '2026-01-02' }] }], 2);
const acento = calc('semAcento');
for(const s of ['Mão de Obra', 'ÇÃO', 'pintura', '', 'Encanamento Hidráulico', 'Ünïcödé']) acento(JSON.stringify(s), s);
acento('nulo', null);
const filtra = calc('filtraGastos');
filtra('sem filtro', O1.gastos, TOPICOS_MAPA, null);
filtra('texto na descrição sem acento', O1.gastos, TOPICOS_MAPA, { texto: 'conexoes' });
filtra('texto no nome do tópico', O1.gastos, TOPICOS_MAPA, { texto: 'eletri' });
filtra('mês', O1.gastos, TOPICOS_MAPA, { mes: '2025-08' });
filtra('texto e mês', O1.gastos, TOPICOS_MAPA, { texto: 'tinta', mes: '2025-08' });
filtra('tópico próprio pelo nome', O4.gastos, TOPICOS_MAPA, { texto: 'automacao' });
filtra('tópico apagado busca pelo id', [{ id: 'k', valor: 1, topico: 'c_sumiu', descricao: '', data: '2026-01-01' }], TOPICOS_MAPA, { texto: 'c_sum' });
filtra('nada encontrado', O1.gastos, TOPICOS_MAPA, { texto: 'xyz' });

/* ---------- parcelas ---------- */
const parcelas = calc('gerarParcelas');
parcelas('resto de centavo na última', 100, 3, '2026-01-15');
parcelas('31/01 clampa em cada mês', 100, 3, '2026-01-31');
parcelas('uma parcela', 99.99, 1, '2026-05-10');
parcelas('mais parcelas que centavos', 0.02, 3, '2026-01-01');
parcelas('tantas parcelas quanto centavos', 0.03, 3, '2026-01-01');
parcelas('valor zero', 0, 2, '2026-01-01');
parcelas('n não inteiro', 100, 2.5, '2026-01-01');
parcelas('arredonda o total para centavos', 10.005, 2, '2026-01-01');
const cartao = calc('parcelamentoCartao');
cartao('sem juros', 1000, 3, 0, '2026-01-15');
cartao('com juros, última absorve o resto', 1000, 3, 2.5, '2026-01-15');
cartao('36x a 4,99%', 5432.1, 36, 4.99, '2026-01-31');
cartao('à vista no cartão', 250.5, 1, 3, '2026-02-10');
cartao('mais de 36 parcelas', 1000, 37, 0, '2026-01-15');
cartao('taxa acima de 100', 1000, 3, 101, '2026-01-15');
cartao('taxa negativa', 1000, 3, -1, '2026-01-15');
cartao('data inválida (30/02)', 1000, 3, 0, '2026-02-30');
cartao('valor zero', 0, 3, 0, '2026-01-15');
cartao('n não inteiro', 1000, 2.5, 0, '2026-01-15');

/* ---------- moeda: máscara, leitura e exibição ---------- */
const TEXTOS = ['', '0', '00', '007', '1.234', '1.234,56', '1,5', '1.5', '12.345', '1.2345', '-1.234', '1,2,3', '..5', '.5', '5.',
  '-', '-.5', '1-2', 'R$ 1.234,56', '  12 ', '1.234.567', '0,05', ',5', '12,', '1.000.000,00', '1e5', '99999999,999', 'abc', '1.234.5'];
const digitado = calc('fmtDigitado');
for(const t of TEXTOS) digitado(JSON.stringify(t), t);
digitado('número', 1234.5);
digitado('nulo', null);
const completo = calc('fmtCompleto');
for(const t of TEXTOS) completo(JSON.stringify(t), t);
const campo = calc('numParaCampo');
for(const n of [0, 1, 1234.5, 0.1 + 0.2, 99999999.99, 12.345, 100, 1e-7]) campo(String(n), n);
campo('nulo', null);
campo('texto vazio', '');
const ler = calc('parseNum');
for(const t of TEXTOS) ler(JSON.stringify(t), t);
ler('número passa direto', 12.5);
ler('nulo', null);
const money = calc('money');
for(const n of [0, 1, 1234.5, -1234.5, 0.125, 1.005, 2.675, 999.995, -0.001, 1234567.891, 99999999.99, 1e21]) money(String(n), n);
money('nulo', null);
const curto = calc('moneyShort');
for(const n of [0, 999.99, 1000, 1005, 8250, 9999, 10000, 12500, 999999, 1e6, 2.5e6, 9999999, 1e7, 10250000, 12350000, -1500, -2.5e6, -500, 123456789])
  curto(String(n), n);
const semZero = calc('moneyCurto');
for(const n of [8000, 8500, 1e6, 1.5e6, 12e6, 500, 10000]) semZero(String(n), n);
const fmtMeses = calc('fmtMeses');
for(const m of [0, 0.99, 1, 1.4, 1.5, 2, 2.5, 12.7]) fmtMeses(String(m), m);

/* ---------- orçamento previsto × real ---------- */
const orc = calc('orcamentoObra');
for(const o of BLOB.obras) orc(o.nome, o);
const comOrcamento = (orcamento, gastos) => ({ ...O3, orcamento, gastos });
const g = (topico, valor, id = topico) => ({ id, valor, topico, descricao: '', data: '2026-01-01', pagamento: 'pix' });
orc('por tópico: passou, perto e sem gasto; fora separado', comOrcamento({ modo: 'topicos', topicos: { fundacao: 90000, estrutura: 250000, c_apagado: 1000 } },
  [g('fundacao', 98000), g('estrutura', 231000), g('hidraulica', 12000), g('pintura', 3000)]));
orc('meio centavo acima ainda não passou', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 1000.004)]));
orc('mais de meio centavo passou', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 1000.006)]));
orc('89,5% arredonda para perto', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 895)]));
orc('empate de razão desempata pelo id', comOrcamento({ modo: 'topicos', topicos: { pintura: 100, eletrica: 200 } }, [g('pintura', 50), g('eletrica', 100)]));
orc('dois tópicos fora com o mesmo gasto desempatam pelo id', comOrcamento({ modo: 'topicos', topicos: { fundacao: 1000 } }, [g('fundacao', 500), g('pintura', 300), g('eletrica', 300)]));
orc('sem orçamento', O3);
orc('previsto zero some', comOrcamento({ modo: 'total', total: 0 }, []));

/* ---------- versão ---------- */
const versao = calc('versaoMaior');
versao('patch numérico', '1.0.10', '1.0.9');
versao('minor numérico', '1.2.0', '1.10.0');
versao('igual', '2.0.0', '2.0.0');
versao('maior major', '2.0.0', '1.99.99');
versao('inválida', 'abc', '1.0.0');
versao('sem a segunda', '1.0.0');
versao('dois números só', '1.0', '0.9.9');

/* ---------- comparação canônica ---------- */
const canon = calc('canon');
canon('chaves fora de ordem e aninhadas', { b: 1, a: [{ d: 1, c: 2 }], c: { z: null, y: true } });
canon('chaves numéricas vêm antes, em ordem numérica', { b: 1, '10': 2, '2': 3, a: 4, '01': 5, '-1': 6 });
canon('blob de exemplo', BLOB);
canon('unicode e escapes', { 'é': 'ção', 'a': 'aspas "x"', '😀': '\u0001\n' });
// O sort() compara unidade UTF-16: o emoji (D83D DE00) vem antes de U+E000; por escalar, como o < do Swift, viria depois.
canon('ordem UTF-16 do sort()', { '\u{ff5e}': 1, '\u{1f600}': 2, a: 3, '\u{e000}': 4 });

/* ---------- dados.js ---------- */
constante('dados.LIMITES', D.LIMITES);
const n = (nome, entrada) => caso('dados.normaliza', nome, [entrada], D.normaliza);
n('raiz nula', null);
n('raiz lista', []);
n('raiz texto', 'x');
n('blob vazio', {});
n('blob de exemplo já normalizado não muda', BLOB);
n('campo desconhecido em todo nível é preservado', {
  extra: { a: 1 },
  obras: [{ id: 'o', nome: 'Obra', dataInicio: '2026-01-01', fase: 'pronta', campoDoSite: [1, 2],
    venda: null, orcamento: { modo: 'total', total: 10, nota: 'x' },
    gastos: [{ id: 'g', valor: 1, topico: 'pintura', descricao: 'd', data: '2026-01-02', pagamento: 'pix', anexo: { url: 'u' },
      grupoId: 'gr', parcela: { n: 1, de: 2, extra: true } }],
    afazeres: [{ id: 'a', texto: 't', feito: true, prazo: '2026-02-01' }] }],
  config: { taxaMensal: 1, topicosCustom: [{ id: 'c_x', nm: 'X', ic: 'raio', cor: 'azul' }], futura: 1 },
});
n('taxa em texto com vírgula vira 1', { config: { taxaMensal: '1,5' } });
n('taxa em texto com ponto vale', { config: { taxaMensal: '1.5' } });
n('taxa hexadecimal em texto vale (Number do JavaScript)', { config: { taxaMensal: '0x2' } });
n('taxa com espaços vale', { config: { taxaMensal: ' 2 ' } });
n('taxa acima de 20 vira 1', { config: { taxaMensal: 25 } });
n('taxa zero vira 1', { config: { taxaMensal: 0 } });
n('taxa negativa vira 1', { config: { taxaMensal: -1 } });
n('taxa 20 vale', { config: { taxaMensal: 20 } });
n('taxa vazia vira 1', { config: { taxaMensal: '  ' } });
const obraCom = (campos, gastos = []) => ({ obras: [{ id: 'o', nome: 'Obra', dataInicio: '2026-01-01', gastos, ...campos }] });
n('obra vendida sem venda volta para construção', obraCom({ fase: 'vendida' }));
n('obra vendida com venda de data inválida volta para construção', obraCom({ fase: 'vendida', venda: { valor: 10, data: '2026-02-30' } }));
n('obra vendida com venda negativa volta para construção', obraCom({ fase: 'vendida', venda: { valor: -1, data: '2026-03-01' } }));
n('venda em texto vira número', obraCom({ fase: 'vendida', venda: { valor: '980000', data: '2026-03-01', obs: 'x' } }));
n('fase desconhecida vira construção', obraCom({ fase: 'demolida' }));
n('obra com data inválida (30/02) some', obraCom({ dataInicio: '2026-02-30' }));
n('obra sem id some', { obras: [{ nome: 'Sem id', dataInicio: '2026-01-01' }] });
n('ano 0050 vale para o dados.js', obraCom({ dataInicio: '0050-01-01' }));
n('id e nome numéricos viram texto', { obras: [{ id: 123, nome: 42, dataInicio: '2026-01-01' }, { id: 1.5, dataInicio: '2026-01-01' }] });
n('nome vazio vira "Obra sem nome"', obraCom({ nome: '' }));
n('estimado e área inválidos viram nulo', obraCom({ valorEstimadoVenda: -5, areaM2: 'abc' }));
n('estimado e área em texto viram número', obraCom({ valorEstimadoVenda: '500000', areaM2: '120.5' }));
n('itens que não são objeto saem da lista', { obras: [1, null, 'x', [], { id: 'o', dataInicio: '2026-01-01' }] });
n('obras que não é lista vira lista vazia', { obras: { id: 'o' } });
const gastoCom = campos => obraCom({}, [{ id: 'g', valor: 10, data: '2026-01-02', ...campos }]);
n('gasto com data 30/02 some', gastoCom({ data: '2026-02-30' }));
n('gasto sem id some', obraCom({}, [{ valor: 10, data: '2026-01-02' }]));
n('gasto negativo some', gastoCom({ valor: -5 }));
n('gasto zero fica', gastoCom({ valor: 0 }));
n('gasto em texto com ponto vira número', gastoCom({ valor: '1500.5' }));
n('gasto em texto com vírgula some', gastoCom({ valor: '1.234,56' }));
n('tópico e pagamento vazios ganham padrão', gastoCom({ topico: '', pagamento: '' }));
n('parcela inválida perde grupo e parcela', obraCom({}, [
  { id: 'g1', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 0, de: 3 } },
  { id: 'g2', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 3, de: 2 } },
  { id: 'g3', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 1.5, de: 3 } },
  { id: 'g4', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: 'x' },
  { id: 'g5', valor: 1, data: '2026-01-02', grupoId: 'gr' }]));
n('parcela válida sem grupo ganha grupo vazio', gastoCom({ parcela: { n: '2', de: '3' } }));
n('afazer: feito só com true exato; sem id some', obraCom({ afazeres: [
  { id: 'a1', texto: 'x', feito: 'true' }, { id: 'a2', texto: 5, feito: true }, { texto: 'sem id' }, { id: 'a3' }] }));
n('tópico próprio sem nome some; ícone vazio vira etiqueta', { config: { topicosCustom: [
  { id: 'c_a', nm: 'A', ic: '' }, { id: 'c_b', nm: '' }, { nm: 'Sem id' }, { id: 'c_c', nm: 'C' }] } });
n('orçamento por tópico descarta inválidos', obraCom({ orcamento: { modo: 'topicos', total: 9, topicos: {
  pintura: 1000, eletrica: '500', terreno: 0, hidraulica: -1, '  ': 10, ['x'.repeat(81)]: 10, ['y'.repeat(80)]: 7 } } }));
const cemMais = Object.fromEntries(Array.from({ length: 101 }, (_, i) => [`t${String(i).padStart(3, '0')}`, i + 1]));
n('orçamento por tópico guarda só os 100 primeiros', obraCom({ orcamento: { modo: 'topicos', topicos: cemMais } }));
n('id de tópico conta unidades UTF-16, como o length', obraCom({ orcamento: { modo: 'topicos', topicos: { ['😀'.repeat(40)]: 10, ['😀'.repeat(41)]: 20 } } }));
n('orçamento por tópico vazio some', obraCom({ orcamento: { modo: 'topicos', topicos: { pintura: 0 } } }));
n('orçamento total em texto', obraCom({ orcamento: { modo: 'total', total: '5000', topicos: { a: 1 } } }));
n('orçamento de modo desconhecido vira total', obraCom({ orcamento: { modo: 'xyz', total: 300 } }));
n('orçamento total zero some', obraCom({ orcamento: { modo: 'total', total: 0 } }));
n('orçamento que não é objeto some', obraCom({ orcamento: 'muito' }));

/* ---------- push.js e id ---------- */
for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
  caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
/* uid() do app.js: milissegundos em base 36 mais 4 letras aleatórias. Só o prefixo é fixo. */
for(const ms of [0, 35, 36, 1759750000000, 1700000000123, 4102444800000])
  caso('id.base36', String(ms), [ms], x => x.toString(36));

/* ---------- primitivas do JavaScript que as regras usam ---------- */
for(const x of [0, 1, -1, 0.1, 0.30000000000000004, 1e21, 1e-7, 1e-6, 123456789012345680000, 5e-324, 1.7976931348623157e308,
  100, 1500.5, 2 ** 53, 1 / 3, -1e-7, 12345.6789, 1e16, 1.5e300])
  caso('js.numeroParaTexto', String(x), [x], v => String(v));
for(const s of ['  12 ', '0x10', '0X1f', '1,5', '1e3', '1E-2', '.5', '5.', '+5', '-5', '-0x10', 'Infinity', '1_0', '0b11', '0o7',
  ' \u{a0}12\u{2028}', '\u{feff}3', '12abc', '', '   ', '0x', '1e', '.', '00012', '1.2.3', '0b2', '\t\n7\r', '1 2',
  // bordas: U+180E, U+0085 e U+200B não são espaço para o JavaScript; "infinity" em minúscula não é número;
  // literais com mais de 53 bits, que o Number() arredonda uma vez só
  '\u{180e}5', '\u{85}5', '\u{200b}5', 'infinity',
  '0x200000000000018', '0o20000000000000003', '0b1000000000000000000000000000000000000000000000000000011', '0o4000000000000000014'])
  caso('js.textoParaNumero', JSON.stringify(s), [s], v => { const x = Number(v); return Number.isFinite(x) ? x : null; });
for(const [x, casas] of [[8.25, 1], [1.005, 2], [2.5, 0], [0.5, 0], [10.25, 1], [12.35, 1], [1.45, 1], [999.95, 1], [0.05, 1], [1.25, 1], [1234.5678, 2], [0, 2],
  [-1.5, 0], [-0.001, 2], [1e21, 2]]) // bordas: negativo no empate, negativo que zera e o limite de 1e21
  caso('js.toFixed', `${x}.toFixed(${casas})`, [x, casas], (v, c) => v.toFixed(c));
for(const x of [0.5, 1.5, 2.5, -0.5, -1.5, -2.5, 0.49999999999999994, 1e16 + 1, -0.4])
  caso('js.round', String(x), [x], v => Math.round(v) + 0); // + 0 tira o −0, que o JSON já não guarda
for(const v of ['', 'simples', 'aspas "x"', 'barra \\', 'linha\nnova', 'tab\tx', '\u0000\u0001\u001f', 'ção', '😀🏗️', '\u{2028}\u{2029}', '/', '\u007f',
  [1, 'a', null, true, 0.5]])
  caso('js.stringify', JSON.stringify(v), [v], x => JSON.stringify(x));
for(const s of [' a ', '\u{a0}a\u{a0}', '\u{feff}a\u{2028}', '\u{3000}a\u{205f}', 'a b', '',
  '\u{180e}5', '\u{85}5', '\u{200b}5', 'infinity']) // bordas: o trim não tira U+180E, U+0085 nem U+200B
  caso('js.trim', JSON.stringify(s), [s], x => x.trim());

/* ---------- saída ---------- */
/* Informativo, fora da comparação do teste do site: de que Node e V8 saiu o arquivo. O Math.pow
   muda o último ULP entre versões do V8, e o ICU decide o texto do money. */
const geradoCom = { node: process.version, v8: process.versions.v8, icu: process.versions.icu };
const vetores = { formato: 1, fuso: FUSO, gerador: 'scripts/vetores-calc.mjs', geradoCom, grupos };
const texto = JSON.stringify(vetores, null, 2) + '\n';
if(process.argv.includes('--imprimir')) process.stdout.write(texto);
else{
  writeFileSync(path.join(RAIZ, 'tests', 'vetores', 'calc.json'), texto);
  console.log(`tests/vetores/calc.json: ${Object.keys(grupos).length} grupos, ${Object.values(grupos).reduce((s, l) => s + l.length, 0)} casos`);
}
