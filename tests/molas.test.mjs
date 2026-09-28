import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { MOLAS, curva, acomodacao, tokensCss } from '../scripts/molas.mjs';

const valores = linear => linear.slice('linear('.length, -1).split(',').map(Number);

test('curvas começam em 0 e terminam em 1', ()=>{
  for(const m of Object.values(MOLAS)){
    const v = valores(curva(m).linear);
    assert.equal(v[0], 0);
    assert.equal(v.at(-1), 1);
  }
});

test('mola padrão (amortecimento 1) nunca passa do destino; a de quique passa', ()=>{
  assert.ok(valores(curva(MOLAS.mola).linear).every(x => x <= 1));
  assert.ok(valores(curva(MOLAS['mola-quique']).linear).some(x => x > 1.005));
});

test('acomodação coerente com a resposta', ()=>{
  const d = acomodacao(MOLAS.mola), q = acomodacao(MOLAS['mola-quique']);
  assert.ok(d > 0.45 && d < 0.6, `mola: ${d}s`);
  assert.ok(q > 0.35 && q < 0.5, `quique: ${q}s`);
});

test('styles.css traz exatamente os tokens do gerador dentro do @supports de linear()', ()=>{
  const css = readFileSync(new URL('../styles.css', import.meta.url), 'utf8');
  const i = css.indexOf('@supports (transition-timing-function:linear(0, 1))');
  assert.ok(i >= 0, 'bloco @supports das molas sumiu');
  const bloco = css.slice(i, css.indexOf('}', css.indexOf('{', css.indexOf('{', i) + 1)));
  for(const linha of tokensCss()) assert.ok(bloco.includes(linha), `falta no CSS: ${linha.slice(0, 60)}…`);
});

test('movimento reduzido zera a duração das molas', ()=>{
  const css = readFileSync(new URL('../styles.css', import.meta.url), 'utf8');
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)\{\s*:root\{--mola-dur:0s;--mola-quique-dur:0s\}\s*\}/);
});
