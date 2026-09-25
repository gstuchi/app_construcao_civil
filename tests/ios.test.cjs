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
