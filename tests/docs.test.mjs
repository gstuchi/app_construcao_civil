/* Guarda a apresentação do repositório: licença, capturas do README, caminhos
   de documentação e links relativos. Nada aqui roda no app — é justamente por
   isso que precisa de teste: documentação quebra em silêncio. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const versionados = execFileSync('git', ['ls-files'], { cwd: RAIZ, encoding: 'utf8' })
  .split('\n').filter(Boolean);
const ler = rel => readFileSync(path.join(RAIZ, rel), 'utf8');

test('LICENSE proprietária, com titular, ano e resumo em inglês', () => {
  const licenca = ler('LICENSE');
  assert.match(licenca, /Copyright \(c\) 2026 Giovani Stuchi/);
  assert.match(licenca, /Todos os direitos reservados/i);
  assert.match(licenca, /All rights reserved/i, 'resumo em inglês — quem revisa app store lê inglês');
  assert.match(licenca, /vendor\//, 'precisa ressalvar as licenças dos SDKs versionados');
  const pkg = JSON.parse(ler('package.json'));
  assert.equal(pkg.license, 'UNLICENSED', 'convenção npm para código proprietário');
  assert.equal(pkg.private, true);
});

/* O spec e o plano desta própria mudança descrevem a renomeação — citar o
   caminho antigo neles é o registro histórico, não uma referência viva. */
const PODEM_CITAR_CAMINHO_ANTIGO = [
  'docs/specs/2026-09-17-repositorio-profissional-design.md',
  'docs/plans/2026-09-17-repositorio-profissional.md',
  'tests/docs.test.mjs',
];

test('nenhum arquivo aponta mais para a pasta antiga de documentação', () => {
  const antigo = 'docs/' + 'superpowers';
  const textuais = versionados.filter(f =>
    /\.(md|js|mjs|cjs|json|yml|yaml|html|css)$/.test(f) &&
    !f.startsWith('ios/') && !f.startsWith('vendor/') &&
    !PODEM_CITAR_CAMINHO_ANTIGO.includes(f));
  const culpados = textuais.filter(f => ler(f).includes(antigo));
  assert.deepEqual(culpados, [], 'ainda citam o caminho antigo de spec/plano');
  assert.ok(versionados.some(f => f.startsWith('docs/specs/')), 'docs/specs/ precisa existir');
  assert.ok(versionados.some(f => f.startsWith('docs/plans/')), 'docs/plans/ precisa existir');
  assert.ok(!versionados.some(f => f.startsWith(antigo + '/')), 'a pasta antiga precisa sumir do git');
});
