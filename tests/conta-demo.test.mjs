/* A conta de demonstração é escrita pelo Admin SDK, que passa por cima das
   firestore.rules. Então nada garante o formato na hora de gravar — se sair um
   campo a mais, a escrita funciona hoje e o app quebra na primeira vez que o
   revisor mexer em qualquer coisa, porque aí a regra vale. Este teste é o que
   ocupa o lugar das rules: confere o documento contra o que blobOk() aceita. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { documentoDados, documentoPerfil, lerArgs, EMAIL_PADRAO } from '../scripts/conta-demo.mjs';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rules = readFileSync(path.join(RAIZ, 'firestore.rules'), 'utf8');

test('dados/{uid} tem só as chaves que blobOk() aceita', () => {
  const doc = documentoDados();
  assert.deepEqual(Object.keys(doc).sort(), ['_atualizado', 'config', 'obras']);
  assert.ok(Array.isArray(doc.obras));
  assert.ok(doc.obras.length <= 300, 'blobOk limita em 300 obras');
  assert.deepEqual(Object.keys(doc.config).sort(), ['taxaMensal', 'topicosCustom']);
  assert.equal(typeof doc.config.taxaMensal, 'number');
  assert.ok(doc.config.taxaMensal > 0 && doc.config.taxaMensal <= 20, 'blobOk exige 0 < taxa <= 20');
  assert.ok(Array.isArray(doc.config.topicosCustom));
  assert.ok(doc.config.topicosCustom.length <= 50);
});

/* Os limites acima estão escritos em dois lugares: aqui e nas rules. Se alguém
   afrouxar as rules e esquecer deste teste, tudo bem; o contrário — apertar as
   rules e deixar o script gravando o formato velho — é que dói. */
test('os limites conferidos são mesmo os que estão nas rules', () => {
  assert.match(rules, /hasOnly\(\['obras', 'config', '_atualizado'\]\)/);
  assert.match(rules, /d\.obras\.size\(\) <= 300/);
  assert.match(rules, /d\.config\.taxaMensal <= 20/);
  assert.match(rules, /d\.config\.topicosCustom\.size\(\) <= 50/);
});

test('a conta chega cheia — empty state não mostra o produto', () => {
  const doc = documentoDados();
  assert.ok(doc.obras.length >= 2, 'a Guideline 2.1 pede o app em uso, não uma obra só');
  const gastos = doc.obras.reduce((s, o) => s + o.gastos.length, 0);
  assert.ok(gastos >= 20, `poucos gastos para o revisor ver o app funcionando: ${gastos}`);
  const fases = new Set(doc.obras.map(o => o.fase));
  assert.ok(fases.size >= 2, 'obras em fases diferentes mostram o ciclo todo');
  const parceladas = doc.obras.flatMap(o => o.gastos).filter(g => g.parcela);
  assert.ok(parceladas.length > 0, 'ao menos uma compra parcelada no cartão');
});

test('perfis/{uid} não leva plano nem cpf', () => {
  const perfil = documentoPerfil('alguem@exemplo.com');
  assert.deepEqual(Object.keys(perfil).sort(), ['criado', 'email', 'tz']);
  assert.ok(!('plano' in perfil), 'plano é escrito só pelo Admin SDK do servidor, nunca aqui');
  assert.ok(!('cpf' in perfil), 'o CPF foi removido do produto na Fase 2');
});

test('_atualizado é o milissegundo que o app usa, não um Timestamp', () => {
  const doc = documentoDados(1758240000000);
  assert.equal(doc._atualizado, 1758240000000);
  assert.equal(typeof doc._atualizado, 'number');
});

test('o padrão é o emulador; produção precisa ser pedida', () => {
  assert.equal(lerArgs([]).producao, false, 'sem flag o script não pode tocar em produção');
  assert.equal(lerArgs([]).email, EMAIL_PADRAO);
  assert.equal(lerArgs(['--producao']).producao, true);
  assert.equal(lerArgs(['--email', 'outro@exemplo.com']).email, 'outro@exemplo.com');
  assert.equal(lerArgs(['--senha', 'abc']).senha, 'abc');
});
