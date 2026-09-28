'use strict';
/* Guardas do Liquid Glass (docs/specs/2026-09-28-vidro-liquido-design.md). */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const css = readFileSync(join(__dirname, '..', 'styles.css'), 'utf8');
const semComentario = css.replace(/\/\*[\s\S]*?\*\//g, '');
const regras = [...semComentario.matchAll(/([^{}]+)\{([^{}]*)\}/g)].map(m => ({ sel: m[1].trim(), decl: m[2] }));
const BLOCOS = ['  :root{', '  html[data-theme="light"]{', '  html[data-skin="azul"]{', '  html[data-skin="azul"][data-theme="light"]{'];
const corpoDoBloco = b => { const i = css.indexOf(b); assert.ok(i >= 0, `bloco ${b} sumiu`); return css.slice(i, css.indexOf('}', i)); };

test('material de vidro definido nos quatro combos tema×cor', ()=>{
  for(const b of BLOCOS){
    const corpo = corpoDoBloco(b);
    for(const t of ['--vidro', '--vidro-folha', '--vidro-luz', '--vidro-tinta', '--vidro-tinta-ink', '--vidro-brilho', '--vidro-sombra'])
      assert.match(corpo, new RegExp(`${t}:`), `${b} sem ${t}`);
  }
  assert.doesNotMatch(css, /--barra\b/, '--barra foi substituído por --vidro');
});

test('filtros do vidro são tokens globais', ()=>{
  assert.match(semComentario, /--vidro-filtro:saturate\(180%\) blur\(24px\)/);
  assert.match(semComentario, /--vidro-filtro-forte:saturate\(180%\) blur\(40px\)/);
});

test('recuos: sem backdrop-filter, transparência reduzida e contraste alto deixam o vidro sólido', ()=>{
  for(const cab of ['@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px)))',
                    '@media (prefers-reduced-transparency: reduce)', '@media (prefers-contrast: more)']){
    const i = semComentario.indexOf(cab);
    assert.ok(i >= 0, `falta ${cab}`);
    const trecho = semComentario.slice(i, i + 700);
    assert.match(trecho, /--vidro:var\(--surface-solid\)/, `${cab} não deixa --vidro sólido`);
    assert.match(trecho, /--vidro-folha:var\(--surface-solid\)/, `${cab} não deixa --vidro-folha sólido`);
  }
  assert.match(semComentario.slice(semComentario.indexOf('@media (prefers-reduced-transparency: reduce)')), /--vidro-filtro:none/);
});

test('todo backdrop-filter vem com -webkit-backdrop-filter (Safari)', ()=>{
  const sem = regras.filter(r => /(^|;|\s)backdrop-filter:/.test(r.decl) && !/-webkit-backdrop-filter:/.test(r.decl)).map(r => r.sel);
  assert.deepEqual(sem, []);
});

test('sem color-mix (WKWebView do iOS 15)', ()=>{
  assert.doesNotMatch(semComentario, /color-mix\(/);
});
