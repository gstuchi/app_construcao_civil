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
  assert.match(semComentario, /--vidro-filtro:saturate\(180%\) blur\(24px\) brightness\(var\(--vidro-luz\)\)/);
  assert.match(semComentario, /--vidro-filtro-forte:saturate\(180%\) blur\(40px\) brightness\(var\(--vidro-luz\)\)/);
});

test('recuos: sem backdrop-filter, transparência reduzida e contraste alto deixam o vidro sólido', ()=>{
  let trechoContraste;
  for(const cab of ['@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px)))',
                    '@media (prefers-reduced-transparency: reduce)', '@media (prefers-contrast: more)']){
    const i = semComentario.indexOf(cab);
    assert.ok(i >= 0, `falta ${cab}`);
    const trecho = semComentario.slice(i, i + 700);
    assert.match(trecho, /--vidro:var\(--surface-solid\)/, `${cab} não deixa --vidro sólido`);
    assert.match(trecho, /--vidro-folha:var\(--surface-solid\)/, `${cab} não deixa --vidro-folha sólido`);
    if(cab === '@media (prefers-contrast: more)') trechoContraste = trecho;
  }
  assert.match(semComentario.slice(semComentario.indexOf('@media (prefers-reduced-transparency: reduce)')), /--vidro-filtro:none/);
  assert.match(trechoContraste, /--vidro-luz:1(?![.\d])/, 'contraste alto não fixa --vidro-luz:1 (brilho volta ao neutro)');
});

test('todo backdrop-filter vem com -webkit-backdrop-filter (Safari)', ()=>{
  const sem = regras.filter(r => /(^|;|\s)backdrop-filter:/.test(r.decl) && !/-webkit-backdrop-filter:/.test(r.decl)).map(r => r.sel);
  assert.deepEqual(sem, []);
});

test('sem color-mix (WKWebView do iOS 15)', ()=>{
  assert.doesNotMatch(semComentario, /color-mix\(/);
});

test('efeito de borda da barra mora no ::before, não no header (raiz de fundo)', ()=>{
  const antes = regras.find(r => r.sel === 'header.top::before');
  assert.ok(antes, 'falta header.top::before');
  assert.match(antes.decl, /-webkit-backdrop-filter:/);
  assert.match(antes.decl, /mask-image:/);
  const noHeader = regras.filter(r => /^header\.top(\.colapsada)?$/.test(r.sel) && /backdrop-filter:/.test(r.decl));
  assert.deepEqual(noHeader.map(r => r.sel), []);
});

test('botões de ação em cápsula (iOS 26)', ()=>{
  assert.ok(regras.some(r => r.sel === '.btn' && /border-radius:999px/.test(r.decl)), '.btn base sem cápsula');
});

test('login sem cores soltas: a moldura cinza fixa saiu', ()=>{
  const card = regras.find(r => r.sel === '.auth-card');
  assert.ok(card);
  assert.doesNotMatch(card.decl, /#6C6C6C|#222\b/i);
  assert.match(card.decl, /var\(--vidro-folha\)/);
});

test('toque encolhe na hora e volta com mola; troca de tela com mola', ()=>{
  assert.ok(regras.some(r => r.sel === '.btn' && /transition:transform var\(--mola-dur\) var\(--mola\)/.test(r.decl)), '.btn sem mola de volta');
  assert.ok(regras.some(r => r.sel === '.btn:active' && /scale\(\.97\)/.test(r.decl) && /\.1s ease-out/.test(r.decl)), '.btn:active sem resposta imediata');
  for(const k of ['entra-direita', 'entra-esquerda']){
    assert.ok(regras.some(r => new RegExp(`animation:${k} var\\(--mola-dur\\) var\\(--mola\\)`).test(r.decl)), `${k} sem mola`);
  }
});
