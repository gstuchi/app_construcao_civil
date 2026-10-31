import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

// Uma pasta como a que o xcresulttool exporta: o manifest.json e uma tabela por cena.
function laudo(pasta, cenas) {
  mkdirSync(pasta, { recursive: true });
  const anexos = Object.entries(cenas).map(([cena, linhas], i) => {
    writeFileSync(join(pasta, `${i}.txt`), [`Leitura — ${cena} (portão 4.5:1)`, ...linhas].join('\n') + '\n');
    return { exportedFileName: `${i}.txt`, suggestedHumanReadableName: `leitura — ${cena} (tabela)` };
  });
  anexos.push({ exportedFileName: 'print.png', suggestedHumanReadableName: 'leitura — a, claro (print)' });
  writeFileSync(join(pasta, 'manifest.json'), JSON.stringify([{ attachments: anexos }]));
}

function compara(...extra) {
  const base = mkdtempSync(join(tmpdir(), 'compara-laudo-'));
  laudo(join(base, 'antes'), {
    'a, claro': [
      '#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00',
      '#222222    50, 20    40× 12 pt  nota  5.00  pior  5.00',
      '#333333   100, 40    20× 10 pt  nota  8.00  pior  8.00',
      '#555555   300, 80    20× 10 pt  nota  6.00  pior  6.00',
    ],
    'c, escuro': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
    'd, igual': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
  });
  laudo(join(base, 'depois'), {
    'a, claro': [
      '#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00',
      '#232323    50, 20    40× 12 pt  nota  4.40  pior  4.40',
      '#333333   104, 40    20× 10 pt  nota  8.00  pior  8.00',
      '#444444   200, 60    10× 10 pt  nota  9.00  pior  9.00',
    ],
    'b, claro': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
    'd, igual': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
  });
  return execFileSync('node', [join(raiz, 'scripts/compara-laudo.mjs'), join(base, 'antes'), join(base, 'depois'),
    join(base, 'saida'), ...extra], { encoding: 'utf8' });
}

test('por cena: idênticas, mudadas, deslocadas, sem par e abaixo do portão; cena sem diferença não sai', () => {
  assert.equal(compara(), [
    'a, claro: 4 palavras, 1 idênticas, 1 mudadas, 1 deslocadas, 1 só antes, 1 só depois, 1 abaixo de 4.5',
    'SÓ DEPOIS: b, claro',
    'SÓ ANTES: c, escuro',
    'TOTAL: 2 cenas, 5 palavras, 2 idênticas, 1 mudadas, 1 deslocadas, 2 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});

test('o detalhe diz cada palavra que mudou, a que sobrou de cada lado e a que ficou abaixo de 4,5', () => {
  assert.equal(compara('--detalhe'), [
    'a, claro: 4 palavras, 1 idênticas, 1 mudadas, 1 deslocadas, 1 só antes, 1 só depois, 1 abaixo de 4.5',
    '   mudou 50,20 40×12: #222222 5.00 (pior 5.00) → #232323 4.40 (pior 4.40)',
    '   só antes  #555555 300,80 20×10 nota 6.00 pior 6.00',
    '   só depois #444444 200,60 10×10 nota 9.00 pior 9.00',
    '   ABAIXO #232323 50,20 40×12 nota 4.40',
    'SÓ DEPOIS: b, claro',
    'SÓ ANTES: c, escuro',
    'TOTAL: 2 cenas, 5 palavras, 2 idênticas, 1 mudadas, 1 deslocadas, 2 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});

// Cada regra de classe numa cena só: nota e pior contam como mudança; a deslocada é a mesma cor, y, largura e
// altura a até 6 pt; a sem par também passa pelo portão; 4,50 passa; a cena só com deslocadas também sai.
test('a regra de cada classe, com o limite de cada uma', () => {
  const l = (cor, x, y, nota, pior = nota, w = 20) =>
    `${cor}  ${x}, ${y}  ${w}× 10 pt  nota ${nota.toFixed(2)}  pior ${pior.toFixed(2)}`;
  const base = mkdtempSync(join(tmpdir(), 'compara-laudo-'));
  laudo(join(base, 'antes'), {
    e: [l('#666666', 10, 100, 7), l('#666666', 60, 100, 7), l('#676767', 110, 100, 7), l('#777777', 100, 120, 8),
      l('#888888', 200, 140, 8), l('#999999', 300, 160, 8), l('#AAAAAA', 10, 200, 8), l('#BBBBBB', 10, 220, 4.5),
      l('#DDDDDD', 200, 260, 8)],
    f: [l('#111111', 10, 20, 7)],
  });
  laudo(join(base, 'depois'), {
    e: [l('#666666', 10, 100, 6.5), l('#666666', 60, 100, 7, 6.9), l('#686868', 110, 100, 7),
      l('#777777', 107, 120, 8), l('#898989', 202, 140, 8), l('#999999', 302, 161, 8), l('#AAAAAA', 16, 200, 7.5),
      l('#BBBBBB', 10, 220, 4.5), l('#CCCCCC', 10, 240, 4.4), l('#DDDDDD', 202, 260, 8, 8, 22)],
    f: [l('#111111', 12, 20, 7)],
  });
  const saida = execFileSync('node', [join(raiz, 'scripts/compara-laudo.mjs'), join(base, 'antes'),
    join(base, 'depois'), join(base, 'saida'), '--detalhe'], { encoding: 'utf8' });
  assert.equal(saida, [
    'e: 10 palavras, 1 idênticas, 3 mudadas, 1 deslocadas, 4 só antes, 5 só depois, 1 abaixo de 4.5',
    '   mudou 10,100 20×10: #666666 7.00 (pior 7.00) → #666666 6.50 (pior 6.50)',
    '   mudou 60,100 20×10: #666666 7.00 (pior 7.00) → #666666 7.00 (pior 6.90)',
    '   mudou 110,100 20×10: #676767 7.00 (pior 7.00) → #686868 7.00 (pior 7.00)',
    '   deslocada 10→16,200 20×10: #AAAAAA 8.00 (pior 8.00) → #AAAAAA 7.50 (pior 7.50)',
    '   só antes  #777777 100,120 20×10 nota 8.00 pior 8.00',
    '   só antes  #888888 200,140 20×10 nota 8.00 pior 8.00',
    '   só antes  #999999 300,160 20×10 nota 8.00 pior 8.00',
    '   só antes  #DDDDDD 200,260 20×10 nota 8.00 pior 8.00',
    '   só depois #777777 107,120 20×10 nota 8.00 pior 8.00',
    '   só depois #898989 202,140 20×10 nota 8.00 pior 8.00',
    '   só depois #999999 302,161 20×10 nota 8.00 pior 8.00',
    '   só depois #CCCCCC 10,240 20×10 nota 4.40 pior 4.40',
    '   só depois #DDDDDD 202,260 22×10 nota 8.00 pior 8.00',
    '   ABAIXO #CCCCCC 10,240 20×10 nota 4.40',
    'f: 1 palavras, 0 idênticas, 0 mudadas, 1 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5',
    'TOTAL: 2 cenas, 11 palavras, 1 idênticas, 3 mudadas, 2 deslocadas, 9 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});
