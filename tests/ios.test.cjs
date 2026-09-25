'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const raiz = join(__dirname, '..');
const ler = p => readFileSync(join(raiz, p), 'utf8');
/* Regras "folha" (sem chaves internas): suficiente para o styles.css, que não aninha além de @media. */
const regras = css => [...css.replace(/\/\*[\s\S]*?\*\//g, '').matchAll(/([^{}]+)\{([^{}]*)\}/g)]
  .map(m => ({ sel: m[1].trim(), decl: m[2] }));

test('viewport não deixa o iOS dar zoom ao focar campo', ()=>{
  const meta = ler('index.html').match(/<meta name="viewport" content="([^"]+)"/)[1];
  assert.match(meta, /maximum-scale=1\b/);
  assert.match(meta, /viewport-fit=cover/);
});

test('nenhum campo de texto com fonte abaixo de 16px', ()=>{
  const culpados = regras(ler('styles.css'))
    .filter(r => /(^|[\s,>+~(])(input|select|textarea)\b/.test(r.sel))
    .flatMap(r => [...r.decl.matchAll(/font-size:\s*([\d.]+)px/g)].map(m => [r.sel, Number(m[1])]))
    .filter(([, px]) => px < 16);
  assert.deepEqual(culpados, [], 'fonte <16px em campo faz o iOS ampliar a página e não voltar');
});

test('fundo sem background-attachment fixed (o iOS repinta a cada quadro de rolagem)', ()=>{
  assert.doesNotMatch(ler('styles.css'), /background-attachment\s*:\s*fixed/);
});

test('capa da barra de status vale no app nativo e no PWA', ()=>{
  const css = ler('styles.css');
  assert.match(css, /html\.nativo body::after/);
  assert.match(css, /html\.standalone body::after/);
});

test('barra de navegação iOS: voltar, título pequeno e título grande', ()=>{
  const html = ler('index.html');
  for(const id of ['navVoltar', 'navTitulo', 'tituloGrande']) assert.match(html, new RegExp(`id="${id}"`));
});

test('barras translúcidas com material por tema', ()=>{
  const css = ler('styles.css');
  const blocos = ['  :root{', '  html[data-theme="light"]{', '  html[data-skin="azul"]{', '  html[data-skin="azul"][data-theme="light"]{'];
  for(const b of blocos){
    const i = css.indexOf(b); assert.ok(i >= 0, `bloco ${b} sumiu`);
    const corpo = css.slice(i, css.indexOf('}', i));
    assert.match(corpo, /--barra:\s*rgba\(/, `${b} sem --barra`);
  }
  assert.match(css, /nav\.tabs\{[^}]*-webkit-backdrop-filter/);
  assert.match(css, /header\.top\.colapsada\{[^}]*-webkit-backdrop-filter/);
});

test('trocar de tela diz a direção da navegação', ()=>{
  const app = ler('app.js');
  assert.match(app, /document\.body\.dataset\.nav\s*=/);
});

test('voltar da barra com hidden some de fato (display da classe venceria o do atributo)', ()=>{
  assert.match(ler('styles.css'), /\.nav-voltar\[hidden\]\{[^}]*display:\s*none/);
});

test('conteúdo no padrão iOS: alça no sheet, linha de lista alta, botão alto', ()=>{
  const css = ler('styles.css');
  assert.match(css, /\.sheet::before\{/);
  assert.match(css, /ul\.list li\{[^}]*min-height:\s*56px/);
  assert.match(css, /\.btn\{[^}]*min-height:\s*50px/);
});

test('lista de obras com chevron e busca com lupa', ()=>{
  const app = ler('app.js');
  assert.match(app, /class="chevron"/);
  assert.match(app, /class="busca-ic"/);
});

test('indicadores da obra opacos no celular (o globo não passa através)', ()=>{
  const opacas = regras(ler('styles.css'))
    .filter(r => /background:\s*var\(--surface-solid\)/.test(r.decl))
    .flatMap(r => r.sel.split(',').map(s => s.trim()));
  assert.ok(opacas.includes('.kpi'), '.kpi sem fundo sólido no celular');
});

test('sem o × na vista (toque), a linha do gasto não guarda a coluna vazia de 44px', ()=>{
  const css = ler('styles.css');
  const bloco = css.match(/@media \(max-width:600px\) and \(pointer:coarse\)\{([\s\S]*?)\n  \}/);
  assert.ok(bloco, 'falta o bloco para toque em tela estreita');
  assert.match(bloco[1], /ul\.list li\.gasto-row\{[^}]*grid-template-columns:\s*38px minmax\(0,\s*1fr\)\s*[;}]/);
});

test('botões × de apagar com nome em português (o VoiceOver lia "multiplicação")', ()=>{
  const app = ler('app.js');
  const botoes = [...app.matchAll(/const (\w+) = el\('button','li-del','×'\);\s*\n\s*\1\.setAttribute\('aria-label','([^']+)'\)/g)].map(m => m[2]);
  assert.equal((app.match(/el\('button','li-del','×'\)/g) || []).length, botoes.length, 'algum × sem aria-label logo depois');
  assert.deepEqual(botoes.sort(), ['Apagar afazer', 'Apagar gasto', 'Apagar tópico']);
});
