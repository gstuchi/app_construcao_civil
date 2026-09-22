#!/usr/bin/env node
/* Gera as capturas de tela do Custta pra ficha da App Store (Fase 5).
   Sobe o servidor estático de tests/browser/servidor.cjs, injeta dados sintéticos
   direto em `db` (sem Firestore, sem rede) e fotografa 5 telas em 1290×2796
   (iPhone 6.9"/6.7": viewport 430×932 com deviceScaleFactor 3).
   Uso: node scripts/screenshots-loja.mjs [diretorio-de-saida]   (5 capturas da loja, 1290×2796)
        node scripts/screenshots-loja.mjs --readme               (3 capturas em 1× direto em docs/img/) */
'use strict';
import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { mkdir, readFile } from 'node:fs/promises';
import path from 'node:path';
/* Os dados sintéticos saíram daqui para dados-demo.mjs quando a conta de
   demonstração da revisão da Apple passou a usar os mesmos — ela não pode
   carregar o Playwright só para chegar neles. Reexportado porque
   tests/screenshots.test.mjs já importava dadosDemo deste módulo. */
import { dadosDemo } from './dados-demo.mjs';
export { dadosDemo };

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const VIEWPORT = { width: 430, height: 932 };
const ESCALA = 3;

/* As três capturas que vão para o topo do README, em 1× (430×932). As mesmas
   telas da loja, sem o número na frente — no README elas têm nome, não ordem. */
export const TELAS_README = new Map([
  ['01-inicio.png', 'inicio.png'],
  ['02-obra.png', 'obra.png'],
  ['04-graficos.png', 'graficos.png'],
]);


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

async function capturar(saidaDir, { escala = ESCALA, mapa = null } = {}) {
  await mkdir(saidaDir, { recursive: true });
  const alvoL = VIEWPORT.width * escala, alvoA = VIEWPORT.height * escala;
  const dados = dadosDemo();
  const servidor = await subirServidor();
  const browser = await chromium.launch();
  try {
    const ctx = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: escala, serviceWorkers: 'block' });
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
      const saidaNome = mapa ? mapa.get(nome) : nome;
      if (!saidaNome) return; // tela que este modo não fotografa
      await page.waitForTimeout(150); // um frame de sobra pro layout de SVG assentar
      const destino = path.join(saidaDir, saidaNome);
      await page.screenshot({ path: destino, animations: 'disabled', ...opts });
      const { width, height } = tamanhoPng(await readFile(destino));
      if (width !== alvoL || height !== alvoA) {
        throw new Error(`${saidaNome}: ${width}x${height}, esperado ${alvoL}x${alvoA}`);
      }
      console.log(`ok - ${saidaNome} (${width}x${height})`);
    };

    // 1) Início — lista de obras + comparativo. Com só 3 obras o conteúdo fica mais
    // baixo que a viewport (nav.tabs é fixa no rodapé); em vez de deixar toda a
    // sobra como uma faixa vazia embaixo, distribui a diferença entre topo e
    // rodapé — composição mais equilibrada, sem faixa vazia grande.
    await page.waitForFunction(() => document.querySelectorAll('#panelComp .hbar').length === 3);
    await page.evaluate(() => {
      const nav = document.querySelector('nav.tabs');
      const app = document.querySelector('.app');
      const folga = nav.getBoundingClientRect().top - app.getBoundingClientRect().bottom;
      if (folga > 20) app.style.marginTop = Math.round(folga / 2) + 'px';
    });
    await foto('01-inicio.png');
    await page.evaluate(() => { document.querySelector('.app').style.marginTop = ''; }); // só valia pra essa foto

    // 2) Detalhe da obra — KPIs, donut pequeno, afazeres. nav.tabs e o FAB são
    // fixos no rodapé/canto; a lista de afazeres tem itens muito próximos (só
    // ~2px de intervalo), então qualquer rolagem que caiba um 2º afazer inteiro
    // corta o cabeçalho "custta." no topo. Prioriza o cabeçalho limpo: sem
    // rolar (scrollY=0), esconde os afazeres além do primeiro pra fechar a
    // lista com uma borda limpa em vez de deixar o 2º sangrando sob a nav.
    await page.evaluate(() => openObra('o1'));
    await page.waitForFunction(() => document.querySelectorAll('#obraBody .kpi').length === 4
      && document.querySelectorAll('#oDonut circle').length > 0);
    await page.evaluate(() => {
      const itens = [...document.querySelectorAll('#oAfazeres li')];
      itens.slice(1).forEach(li => { li.style.display = 'none'; });
    });
    await foto('02-obra.png');

    // 3) Relatório — a tabela é mais larga que a tela (rolagem horizontal real do
    // app); rola até alinhar a coluna "Data" à esquerda, revelando Bruto/Corrigido
    // por completo (a coluna "Correção" fica cortada à direita — aceitável, é a
    // 5ª coluna). Na vertical, ajusta pelo mínimo necessário pra nenhuma linha
    // ficar pela metade sob a nav fixa do rodapé.
    await page.evaluate(() => { showView('relatorio'); renderRelatorio(); });
    await page.waitForFunction(() => document.querySelectorAll('.rep-table tbody tr').length > 0);
    await page.evaluate(() => {
      const scroller = document.querySelector('.rep-scroll');
      const th = document.querySelectorAll('.rep-table thead th')[1];
      scroller.scrollLeft += th.getBoundingClientRect().left - scroller.getBoundingClientRect().left;
    });
    await page.evaluate(() => {
      const navTop = document.querySelector('nav.tabs').getBoundingClientRect().top;
      const linhas = [...document.querySelectorAll('.rep-table tbody tr')]
        .map(tr => tr.getBoundingClientRect()).filter(r => r.bottom > r.top);
      for (let i = 0; i < linhas.length - 1; i++) {
        const meio = (linhas[i].bottom + linhas[i + 1].top) / 2;
        const rolagem = meio - navTop;
        if (rolagem >= 0) { window.scrollBy(0, rolagem); return; }
      }
    });
    await foto('03-relatorio.png');

    // 4) Gráficos — evolução + gasto por mês inteiros na tela (o donut+legenda
    // por si só já é mais alto que a viewport). Rola exatamente até o topo do
    // card "Evolução da obra" — ele começa inteiro na borda superior, sem
    // sobrar tirinha cortada de outro card acima.
    await page.evaluate(() => { showView('graficos'); renderGraficos(); });
    await page.waitForFunction(() => document.querySelectorAll('#grafBody svg').length >= 3);
    await page.evaluate(() => {
      const evo = document.querySelector('#evoSvgG').closest('.panel');
      window.scrollTo(0, evo.getBoundingClientRect().top + window.scrollY);
      // o botão "Imprimir/salvar PDF" vem logo depois do card "Gasto por mês" e
      // sobra bem pertinho da nav fixa — só a pontinha dele apareceria, cortada.
      // Melhor escondê-lo nessa foto do que deixar essa tirinha.
      const btn = document.querySelector('#grafPrint');
      if (btn) btn.style.display = 'none';
    });
    await foto('04-graficos.png');

    // 5) Será que vale a pena? — simulador com cenário preenchido. Sem rolagem
    // horizontal: o rótulo da linha (1ª coluna) tem prioridade e fica inteiro;
    // a coluna "Pelo corrigido" é que fica cortada à direita.
    await page.evaluate(() => { showView('simula'); renderSimula(); });
    await page.evaluate(() => {
      document.querySelector('#simObra').value = 'o2';
      const v = document.querySelector('#simValor'); v.value = '480.000,00'; v.dataset.touched = '1';
      document.querySelector('#simMeses').value = '4';
      simulaCompute();
    });
    await page.waitForFunction(() => document.querySelector('.card.saldo .k-val')?.textContent.trim().length > 0);
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
  const args = process.argv.slice(2);
  const soReadme = args.includes('--readme');
  const saidaDir = args.find(a => !a.startsWith('--')) || '/tmp/custta-loja';
  (async () => {
    if (soReadme) {
      // As do README são as mesmas telas em 1×, gravadas direto no repositório.
      await capturar(path.join(RAIZ, 'docs', 'img'), { escala: 1, mapa: TELAS_README });
      console.log('capturas do README salvas em docs/img');
    } else {
      await capturar(saidaDir);
      console.log('capturas da loja salvas em ' + saidaDir);
    }
  })().catch(err => { console.error(err); process.exitCode = 1; });
}
