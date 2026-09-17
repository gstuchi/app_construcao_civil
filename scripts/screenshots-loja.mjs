#!/usr/bin/env node
/* Gera as capturas de tela do Custta pra ficha da App Store (Fase 5).
   Sobe o servidor estático de tests/browser/servidor.cjs, injeta dados sintéticos
   direto em `db` (sem Firestore, sem rede) e fotografa 5 telas em 1290×2796
   (iPhone 6.9"/6.7": viewport 430×932 com deviceScaleFactor 3).
   Uso: node scripts/screenshots-loja.mjs [diretorio-de-saida] */
'use strict';
import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { mkdir, readFile } from 'node:fs/promises';
import path from 'node:path';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const LARGURA_ALVO = 1290, ALTURA_ALVO = 2796;
const VIEWPORT = { width: 430, height: 932 };
const ESCALA = 3;

/* ---------- dados sintéticos (função pura — cobrida por tests/screenshots.test.mjs) ---------- */

/* Divide um total em `n` parcelas mensais iguais (a última absorve o resto dos
   centavos), gerando os N gastos irmãos de uma compra parcelada no cartão. */
function gerarParcelas({ obraId, topico, descricao, valorTotal, primeiraData, n }) {
  const grupoId = 'grp_' + obraId + '_' + descricao.toLowerCase().replace(/[^a-z0-9]+/g, '');
  const base = Math.floor((valorTotal / n) * 100) / 100;
  const valores = Array.from({ length: n }, () => base);
  valores[n - 1] = Math.round((valorTotal - base * (n - 1)) * 100) / 100;
  const [ano, mes, dia] = primeiraData.split('-').map(Number);
  return valores.map((valor, i) => {
    const totalMes = mes - 1 + i;
    const d = new Date(Date.UTC(ano + Math.floor(totalMes / 12), totalMes % 12, dia));
    const data = d.toISOString().slice(0, 10);
    return {
      id: `${grupoId}_${i + 1}`, valor, topico, descricao, data, pagamento: 'cartao',
      grupoId, parcela: { n: i + 1, de: n },
      jurosCartao: { taxaMensal: 2.5, valorCompra: valorTotal, nParcelas: n, totalCompra: Math.round(valores.reduce((s, v) => s + v, 0) * 100) / 100, jurosCompra: 0 },
    };
  });
}

function gasto(id, data, topico, descricao, valor, pagamento = 'pix') {
  return { id, valor, topico, descricao, data, pagamento };
}

function afazer(id, texto, feito = false) {
  return { id, texto, feito };
}

/* 3 obras plausíveis de construção civil no Brasil, em fases diferentes,
   com dezenas de gastos espalhados por tópico/mês, algumas compras parceladas
   no cartão (grupoId + parcela) e alguns afazeres — pra preencher todas as
   telas capturadas com dados realistas. Nada de lorem ipsum ou pessoa real. */
export function dadosDemo() {
  const sobrado = {
    id: 'o1', nome: 'Sobrado Vila Nova', fase: 'construcao', dataInicio: '2026-01-15',
    areaM2: 180, valorEstimadoVenda: 950000,
    gastos: [
      gasto('g101', '2026-01-20', 'terreno', 'Escritura e ITBI do lote', 42000),
      gasto('g102', '2026-01-28', 'projeto', 'Projeto arquitetônico e ART', 8500),
      gasto('g103', '2026-02-03', 'projeto', 'Alvará de construção', 2100),
      gasto('g104', '2026-02-10', 'fundacao', 'Sondagem do solo', 1800),
      gasto('g105', '2026-02-18', 'fundacao', 'Escavação e radier', 15600),
      gasto('g106', '2026-02-25', 'matbasicos', 'Cimento e areia — 1ª carga', 9800),
      gasto('g107', '2026-03-05', 'ferragem', 'Vergalhão e arame recozido', 11200),
      gasto('g108', '2026-03-12', 'estrutura', 'Forma e concretagem dos pilares', 22400),
      gasto('g109', '2026-03-20', 'maoobra', 'Equipe de fundação — semana 1', 6400),
      gasto('g110', '2026-03-27', 'maoobra', 'Equipe de fundação — semana 2', 6400),
      gasto('g111', '2026-04-04', 'aluguelmaq', 'Aluguel de betoneira', 1300),
      gasto('g112', '2026-04-11', 'estrutura', 'Laje pré-moldada do térreo', 26800),
      gasto('g113', '2026-04-18', 'alvenaria', 'Blocos cerâmicos — térreo', 13500),
      gasto('g114', '2026-04-25', 'maoobra', 'Pedreiro — alvenaria térreo', 8900),
      gasto('g115', '2026-05-02', 'hidraulica', 'Tubulação hidráulica térreo', 7200),
      gasto('g116', '2026-05-09', 'eletrica', 'Passagem elétrica e quadro', 9600),
      gasto('g117', '2026-05-16', 'alvenaria', 'Blocos cerâmicos — 1º andar', 12800),
      gasto('g118', '2026-05-23', 'estrutura', 'Laje do 1º andar', 24100),
      gasto('g119', '2026-05-30', 'telhado', 'Madeiramento do telhado', 14300),
      gasto('g120', '2026-06-06', 'telhado', 'Telhas cerâmicas e cumeeira', 10700),
      gasto('g121', '2026-06-13', 'matextra', 'Aluguel de andaime', 2200),
      gasto('g122', '2026-06-20', 'maoobra', 'Pedreiro — 1º andar', 9100),
      gasto('g123', '2026-07-04', 'revest', 'Argamassa e rejunte', 3400),
      gasto('g124', '2026-07-18', 'pintura', 'Massa corrida e selador', 2600),
      gasto('g125', '2026-08-01', 'hidraulica', 'Louças e metais do banheiro social', 4800),
      gasto('g126', '2026-08-15', 'outros', 'Taxas de ligação de água e luz', 1650),
      gasto('g127', '2026-09-01', 'matbasicos', 'Cimento e areia — acabamento', 4200),
      gasto('g128', '2026-09-10', 'maoobra', 'Eletricista — instalação final', 3800),
      ...gerarParcelas({ obraId: 'o1', topico: 'esquadrias', descricao: 'Portas e janelas de alumínio', valorTotal: 18600, primeiraData: '2026-06-10', n: 3 }),
    ],
    afazeres: [
      afazer('a101', 'Pagar pedreiro da semana', false),
      afazer('a102', 'Comprar tinta para a fachada', false),
      afazer('a103', 'Agendar vistoria elétrica', false),
      afazer('a104', 'Aprovar planta do telhado com o engenheiro', true),
    ],
  };

  const reforma = {
    id: 'o2', nome: 'Reforma Apto 32', fase: 'pronta', dataInicio: '2026-02-01',
    areaM2: 68, valorEstimadoVenda: 420000,
    gastos: [
      gasto('g201', '2026-02-05', 'projeto', 'Projeto de interiores', 3200),
      gasto('g202', '2026-02-12', 'matbasicos', 'Demolição e remoção de entulho', 4100),
      gasto('g203', '2026-02-20', 'hidraulica', 'Troca de tubulação do banheiro', 5600),
      gasto('g204', '2026-02-27', 'eletrica', 'Fiação nova e quadro de disjuntores', 6800),
      gasto('g205', '2026-03-06', 'hidraulica', 'Louças e metais da cozinha', 3900),
      gasto('g206', '2026-03-13', 'revest', 'Porcelanato do banheiro', 4400),
      gasto('g207', '2026-03-20', 'acabamento', 'Gesso e sanca do living', 5200),
      gasto('g208', '2026-03-27', 'maoobra', 'Pedreiro e ajudante — semana 1', 5800),
      gasto('g209', '2026-04-03', 'maoobra', 'Pedreiro e ajudante — semana 2', 5800),
      gasto('g210', '2026-04-10', 'esquadrias', 'Portas internas de madeira', 6900),
      gasto('g211', '2026-04-17', 'pintura', 'Pintura geral do apartamento', 5100),
      gasto('g212', '2026-04-24', 'acabamento', 'Marcenaria — armários planejados', 22000, 'cartao'),
      gasto('g213', '2026-05-08', 'extras', 'Persianas e cortinas', 3300),
      gasto('g214', '2026-05-15', 'eletrica', 'Luminárias e spots', 2800),
      gasto('g215', '2026-05-22', 'revest', 'Rodapé e soleiras', 1900),
      gasto('g216', '2026-06-05', 'outros', 'Limpeza pós-obra', 950),
      gasto('g217', '2026-06-19', 'extras', 'Ar-condicionado split', 4600),
      ...gerarParcelas({ obraId: 'o2', topico: 'revest', descricao: 'Piso porcelanato sala e quartos', valorTotal: 13600, primeiraData: '2026-03-15', n: 4 }),
    ],
    afazeres: [
      afazer('a201', 'Instalar luminárias da cozinha', false),
      afazer('a202', 'Levar a chave extra para o corretor', false),
      afazer('a203', 'Assinar contrato de pintura', true),
    ],
  };

  const jardimSul = {
    id: 'o3', nome: 'Casa Jardim Sul', fase: 'vendida', dataInicio: '2026-01-01',
    areaM2: 140, valorEstimadoVenda: 760000, venda: { data: '2026-08-20', valor: 780000 },
    gastos: [
      gasto('g301', '2026-01-05', 'terreno', 'Compra do terreno', 180000),
      gasto('g302', '2026-01-15', 'projeto', 'Projeto e aprovação na prefeitura', 7200),
      gasto('g303', '2026-01-25', 'fundacao', 'Fundação em radier', 19800),
      gasto('g304', '2026-02-05', 'estrutura', 'Estrutura de concreto armado', 34500),
      gasto('g305', '2026-02-20', 'alvenaria', 'Alvenaria completa', 21300),
      gasto('g306', '2026-03-05', 'telhado', 'Estrutura e telhas do telhado', 16700),
      gasto('g307', '2026-03-20', 'eletrica', 'Instalação elétrica completa', 12400),
      gasto('g308', '2026-04-03', 'hidraulica', 'Instalação hidráulica completa', 10900),
      gasto('g309', '2026-04-17', 'revest', 'Revestimentos e porcelanato', 15600),
      gasto('g310', '2026-05-01', 'pintura', 'Pintura interna e externa', 8200),
      gasto('g311', '2026-05-15', 'maoobra', 'Mão de obra geral — acabamento', 18400),
      gasto('g312', '2026-06-01', 'piscina', 'Piscina de fibra e filtro', 32000),
      gasto('g313', '2026-06-15', 'paisagismo', 'Jardim e grama sintética', 9600),
      gasto('g314', '2026-07-01', 'esquadrias', 'Janelas e portas de alumínio', 14200),
      gasto('g315', '2026-07-15', 'outros', 'Documentação e habite-se', 3400),
      ...gerarParcelas({ obraId: 'o3', topico: 'extras', descricao: 'Portão eletrônico e cerca elétrica', valorTotal: 9800, primeiraData: '2026-05-10', n: 2 }),
    ],
    afazeres: [
      afazer('a301', 'Entregar as chaves ao comprador', true),
      afazer('a302', 'Cancelar seguro da obra', true),
    ],
  };

  return { config: { taxaMensal: 1, topicosCustom: [] }, obras: [sobrado, reforma, jardimSul] };
}

/* ---------- leitura do cabeçalho PNG (função pura) ---------- */

const ASSINATURA_PNG = '89504e470d0a1a0a';

export function tamanhoPng(buffer) {
  if (!buffer || buffer.length < 24) throw new Error('arquivo pequeno demais para ser um PNG');
  if (buffer.subarray(0, 8).toString('hex') !== ASSINATURA_PNG) throw new Error('assinatura PNG inválida');
  if (buffer.subarray(12, 16).toString('latin1') !== 'IHDR') throw new Error('IHDR ausente ou fora de posição');
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

/* ---------- captura (só roda quando o arquivo é executado direto) ---------- */

async function subirServidor() {
  const servidor = spawn(process.execPath, ['tests/browser/servidor.cjs'], { cwd: RAIZ, stdio: 'inherit' });
  for (let n = 0; n < 50; n++) {
    try { if ((await fetch('http://localhost:8123')).ok) return servidor; } catch { /* ainda subindo */ }
    if (n === 49) throw new Error('servidor não iniciou em 5s');
    await new Promise(r => setTimeout(r, 100));
  }
  return servidor;
}

async function capturar(saidaDir) {
  await mkdir(saidaDir, { recursive: true });
  const dados = dadosDemo();
  const servidor = await subirServidor();
  const browser = await chromium.launch();
  try {
    const ctx = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: ESCALA, serviceWorkers: 'block' });
    await ctx.route('**/cloud.js', r => r.fulfill({ contentType: 'text/javascript', body: '' }));
    await ctx.route('https://**/*', r => r.abort());
    await ctx.addInitScript(() => {
      sessionStorage.setItem('splashVista', '1');
      window.errosPagina = [];
      addEventListener('error', e => errosPagina.push(e.message));
      addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
      // dados são injetados direto em `db` depois do goto — watchDados não participa,
      // então fica de propósito inerte (evita corrida com o carregamento inicial).
      window.CLOUD = {
        user: () => ({ uid: 'demo', email: 'demo@custta.app', emailVerificado: true }),
        onAuth: cb => cb({ uid: 'demo' }),
        watchDados: () => () => {},
        saveDados: () => Promise.resolve(),
        estado: () => 'ocioso',
        ready: Promise.resolve(),
      };
    });
    const page = await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.waitForFunction(() => typeof db !== 'undefined' && typeof normaliza === 'function');
    await page.evaluate(dados => { db = normaliza(dados); renderAll(); }, dados);
    await page.waitForFunction(() => document.querySelectorAll('#obrasList li').length === 3);

    const foto = async (nome, opts = {}) => {
      await page.waitForTimeout(150); // um frame de sobra pra layout de SVG assentar
      const destino = path.join(saidaDir, nome);
      await page.screenshot({ path: destino, animations: 'disabled', ...opts });
      const { width, height } = tamanhoPng(await readFile(destino));
      if (width !== LARGURA_ALVO || height !== ALTURA_ALVO) {
        throw new Error(`${nome}: ${width}x${height}, esperado ${LARGURA_ALVO}x${ALTURA_ALVO}`);
      }
      console.log(`ok - ${nome} (${width}x${height})`);
    };

    // 1) Início — lista de obras + comparativo
    await page.waitForFunction(() => document.querySelectorAll('#panelComp .hbar').length === 3);
    await foto('01-inicio.png');

    // 2) Detalhe da obra — KPIs, donut pequeno, afazeres
    await page.evaluate(() => openObra('o1'));
    await page.waitForFunction(() => document.querySelectorAll('#obraBody .kpi').length === 4
      && document.querySelectorAll('#oDonut circle').length > 0);
    await foto('02-obra.png');

    // 3) Relatório — a tabela é mais larga que a tela (rolagem horizontal real do
    // app); rola até alinhar a coluna "Data" à esquerda, revelando Bruto/Corrigido
    // sem cortar nenhum valor no meio.
    await page.evaluate(() => { showView('relatorio'); renderRelatorio(); });
    await page.waitForFunction(() => document.querySelectorAll('.rep-table tbody tr').length > 0);
    await page.evaluate(() => {
      const scroller = document.querySelector('.rep-scroll');
      const th = document.querySelectorAll('.rep-table thead th')[1];
      scroller.scrollLeft += th.getBoundingClientRect().left - scroller.getBoundingClientRect().left;
    });
    await foto('03-relatorio.png');

    // 4) Gráficos — evolução + gasto por mês inteiros na tela (o donut+legenda
    // por si só já é mais alto que a viewport; melhor não cortar gráfico nenhum
    // pela metade do que mostrar os três espremidos).
    await page.evaluate(() => { showView('graficos'); renderGraficos(); });
    await page.waitForFunction(() => document.querySelectorAll('#grafBody svg').length >= 3);
    await page.evaluate(() => {
      const evo = document.querySelector('#evoSvgG').closest('.panel');
      const mes = document.querySelector('#mesSvgG').closest('.panel');
      const topo = evo.getBoundingClientRect().top + window.scrollY;
      const fundo = mes.getBoundingClientRect().bottom + window.scrollY;
      window.scrollTo(0, (topo + fundo) / 2 - window.innerHeight / 2);
    });
    await foto('04-graficos.png');

    // 5) Será que vale a pena? — simulador com cenário preenchido
    await page.evaluate(() => { showView('simula'); renderSimula(); });
    await page.evaluate(() => {
      document.querySelector('#simObra').value = 'o2';
      const v = document.querySelector('#simValor'); v.value = '480.000,00'; v.dataset.touched = '1';
      document.querySelector('#simMeses').value = '4';
      simulaCompute();
    });
    await page.waitForFunction(() => document.querySelector('.card.saldo .k-val')?.textContent.trim().length > 0);
    // a tabela "pelo bruto/pelo corrigido" também estica um pouco além da tela;
    // rola pro fim pra mostrar a coluna "Pelo corrigido" completa.
    await page.evaluate(() => {
      const scroller = document.querySelector('#simOut .rep-scroll');
      if (scroller) scroller.scrollLeft = scroller.scrollWidth - scroller.clientWidth;
    });
    await foto('05-simulador.png');

    const erros = await page.evaluate(() => errosPagina);
    if (erros.length) throw new Error('erros no console durante a captura: ' + erros.join(', '));

    await ctx.close();
  } finally {
    await browser.close();
    servidor.kill();
  }
}

const executadoDireto = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (executadoDireto) {
  const saidaDir = process.argv[2] || '/tmp/custta-loja';
  capturar(saidaDir)
    .then(() => console.log('capturas salvas em ' + saidaDir))
    .catch(err => { console.error(err); process.exitCode = 1; });
}
