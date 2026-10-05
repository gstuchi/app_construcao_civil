/* Título do login escrito à mão: marcação acessível e segura para a CSP, um tempo para
   cada traço da caneta e o logo pronto com "reduzir movimento". O comportamento na tela
   (começo, fim, vibração) fica em tests/browser/escrita.cjs. */
const test = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

const raiz = join(__dirname, '..');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const css = readFileSync(join(raiz, 'styles.css'), 'utf8');
const titulo = html.match(/<div class="auth-title"[\s\S]*?<\/h1>/)?.[0] || '';
const svg = titulo.match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)?.[0] || '';

test('o título do login é um SVG lido como "custta."', ()=>{
  assert.ok(svg, 'svg.logo-escrito dentro do h1 da tela de entrada');
  assert.match(svg, /^<svg class="logo-escrito"[^>]* role="img" aria-label="custta\."/);
  assert.ok(!/class="logotipo"/.test(titulo), 'o texto antigo saiu do título (o SVG o substitui)');
  assert.ok(!/\sstyle="/.test(svg), 'nada de style= no SVG: a CSP bloqueia');
});

test('ids do SVG são únicos, com prefixo, e toda referência existe', ()=>{
  const ids = [...svg.matchAll(/\sid="([^"]+)"/g)].map(m => m[1]);
  assert.ok(ids.length > 0);
  assert.ok(ids.every(i => i.startsWith('le-')), 'prefixo le- (o index.html tem outros ids)');
  assert.equal(new Set(ids).size, ids.length, 'ids repetidos');
  const todos = [...html.matchAll(/\sid="([^"]+)"/g)].map(m => m[1]);
  for(const i of ids) assert.equal(todos.filter(x => x === i).length, 1, `#${i} repetido no index.html`);
  for(const [, ref] of svg.matchAll(/url\(#([^)]+)\)/g)) assert.ok(ids.includes(ref), `url(#${ref}) sem destino`);
  for(const [, ref] of css.matchAll(/url\(#(le-[^)]+)\)/g)) assert.ok(ids.includes(ref), `styles.css: url(#${ref}) sem destino`);
});

test('cada traço da caneta tem o seu tempo no styles.css', ()=>{
  const penas = [...svg.matchAll(/<path class="le-pena (le-p\d+)" pathLength="1"/g)].map(m => m[1]);
  assert.ok(penas.length >= 9, 'um traço por letra (o t e o a têm dois)');
  assert.equal(new Set(penas).size, penas.length);
  for(const p of penas) assert.match(css, new RegExp(`\\.logo-escrito\\.escrevendo \\.${p}\\{animation:`), `${p} sem animação`);
});

test('com "reduzir movimento" o logo aparece pronto', ()=>{
  const blocos = [...css.matchAll(/@media \(prefers-reduced-motion:\s*reduce\)\s*\{([^@]*?)\}\s*\}/g)].map(m => m[1]);
  assert.ok(blocos.some(b => /\.logo-escrito[^{]*\{[^}]*animation:none/.test(b)), 'animação desligada no .logo-escrito');
});
