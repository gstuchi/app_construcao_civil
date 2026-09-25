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
