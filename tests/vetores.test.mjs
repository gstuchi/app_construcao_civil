/* Os vetores compartilhados (tests/vetores/calc.json) têm de estar em dia com o calc.js, o
   dados.js, o push.js e o cadastro.js: o app nativo confere a cópia dele das regras contra este arquivo
   (app-ios/CusttaNucleo). Falhou aqui? Rode `npm run vetores` e faça commit do arquivo junto
   com a mudança da regra; o workflow app-ios roda o lado Swift. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const arquivo = readFileSync(path.join(RAIZ, 'tests/vetores/calc.json'), 'utf8');
const vetores = JSON.parse(arquivo);

/* Estrutura, não bytes: o Math.pow do V8 muda o último ULP entre versões do Node (o corrigido
   sai 1 ULP diferente no Node 22 da CI e no 24 do Mac), e byte a byte o teste falharia sem
   regra nenhuma ter mudado. Texto, booleano e estrutura são exatos, e número também quando os
   dois lados são inteiros; se um dos lados não é inteiro (o ULP pode tirar um valor do inteiro),
   tolera 1e-12 relativo (o app nativo usa 1e-9). Não volte para byte a byte. */
function confere(obtido, esperado, onde){
  const falha = () => assert.fail(`${onde}: ${JSON.stringify(obtido)?.slice(0, 120)} × ${JSON.stringify(esperado)?.slice(0, 120)}`);
  if(typeof esperado === 'number' && typeof obtido === 'number' && !(Number.isInteger(esperado) && Number.isInteger(obtido))){
    if(!(Math.abs(obtido - esperado) <= 1e-12 * Math.max(Math.abs(obtido), Math.abs(esperado)))) falha();
    return;
  }
  if(esperado === null || typeof esperado !== 'object'){ if(obtido !== esperado) falha(); return; }
  if(obtido === null || typeof obtido !== 'object' || Array.isArray(obtido) !== Array.isArray(esperado)) falha();
  const [chavesObtidas, chavesEsperadas] = [Object.keys(obtido), Object.keys(esperado)];
  if(chavesObtidas.length !== chavesEsperadas.length || chavesObtidas.some((k, i) => k !== chavesEsperadas[i])) falha();
  for(const k of chavesEsperadas) confere(obtido[k], esperado[k], `${onde}.${k}`);
}

test('o arquivo de vetores está em dia com o código do site', () => {
  const r = spawnSync(process.execPath, ['scripts/vetores-calc.mjs', '--imprimir'],
    { cwd: RAIZ, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  assert.equal(r.status, 0, r.stderr);
  // geradoCom só diz de que Node e V8 saiu cada arquivo: fica fora da comparação
  const { geradoCom: _deAgora, ...gerado } = JSON.parse(r.stdout);
  const { geradoCom: _doArquivo, ...gravado } = vetores;
  try{ confere(gerado, gravado, 'calc.json'); }
  catch(e){ assert.fail(`tests/vetores/calc.json desatualizado (${e.message}): rode npm run vetores e faça commit do arquivo`); }
});

test('toda função e constante exportada do calc.js tem vetor', () => {
  const faltam = Object.keys(require('../calc.js')).filter(k => !vetores.grupos[`calc.${k}`]);
  assert.deepEqual(faltam, []);
});

test('toda exportação do cadastro.js tem vetor', () => {
  const faltam = Object.keys(require('../cadastro.js')).filter(k => !vetores.grupos[`cadastro.${k}`]);
  assert.deepEqual(faltam, []);
});

test('toda exportação do dados.js tem vetor; do push.js, a chave do token', () => {
  const faltam = Object.keys(require('../dados.js')).filter(k => !vetores.grupos[`dados.${k}`]);
  assert.deepEqual(faltam, []);
  // O resto do push.js é Web Push do navegador (criar, b64ToU8, VAPID_PUBLICA); o app nativo usa o FCM
  // na etapa 5 e só precisa gravar o token na mesma chave.
  assert.ok(vetores.grupos['push.hashEndpoint']?.length, 'push.hashEndpoint');
});

test('vetores determinísticos: fuso fixo e nenhum grupo vazio', () => {
  assert.equal(vetores.formato, 1);
  assert.equal(vetores.fuso, 'America/Sao_Paulo');
  for(const [g, casos] of Object.entries(vetores.grupos)) assert.ok(casos.length > 0, g);
});
