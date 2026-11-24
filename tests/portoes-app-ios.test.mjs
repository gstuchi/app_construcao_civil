import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DISPARAM, NIVEIS, arquivosDoPR, escolher, nivelDosPortoes, superficie } from '../scripts/portoes-app-ios.mjs';

/* O filtro de portões do app nativo (spec da etapa 4, "Portões por superfície"): o nível sai dos arquivos que o PR muda
   e, na dúvida, é tudo. Um nível baixo demais deixa de rodar teste: cada regra tem o caso que sobe e o que não sobe. */
const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const script = join(raiz, 'scripts', 'portoes-app-ios.mjs');
const nivel = (...arquivos) => nivelDosPortoes(arquivos).nivel;

test('o núcleo, o site e os vetores ficam no nível núcleo', () => {
  for (const arquivo of ['app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift', 'app-ios/CusttaNucleo/Package.swift',
    'app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift', 'calc.js', 'dados.js', 'push.js', 'cadastro.js',
    'teclado.js', 'scripts/vetores-calc.mjs', 'tests/vetores/calc.json'])
    assert.equal(superficie(arquivo), 'nucleo', arquivo);
  assert.equal(nivel('calc.js', 'tests/vetores/calc.json', 'app-ios/CusttaNucleo/Sources/CusttaNucleo/Calc.swift'), 'nucleo');
});

test('a análise e os testes dela ficam no nível telas, que inclui o núcleo', () => {
  for (const arquivo of ['app-ios/Custta/Analise/ValeAPenaView.swift', 'app-ios/Custta/Analise/Graficos/Anel.swift',
    'app-ios/CusttaTests/Analise/FaixaDoValeAPenaTests.swift', 'app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift'])
    assert.equal(superficie(arquivo), 'telas', arquivo);
  assert.equal(nivel('app-ios/Custta/Analise/ValeAPenaView.swift'), 'telas');
  assert.equal(nivel('app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift', 'app-ios/Custta/Analise/Anel.swift',
    'app-ios/CusttaUITests/Analise/GraficosUITests.swift'), 'telas', 'o 2a: núcleo e análise juntos');
});

test('qualquer outro arquivo do app, o catálogo, os testes compartilhados e o workflow rodam tudo', () => {
  for (const arquivo of ['app-ios/Custta/Telas/ObraView.swift', 'app-ios/Custta/Identidade/Blocos.swift',
    'app-ios/Custta/Assets.xcassets/Esmeralda/Placa.colorset/Contents.json', 'app-ios/Custta/Falsos/VitrineDaAnalise.swift',
    'app-ios/CusttaUITests/LeituraNoVidroUITests.swift', 'app-ios/CusttaUITests/AuditoriaUITests.swift',
    'app-ios/CusttaUITests/Abrir.swift', 'app-ios/CusttaTests/BlocosTests.swift', 'app-ios/Custta.xcodeproj/project.pbxproj',
    'app-ios/Custta/AnaliseNova/X.swift', 'app-ios/CusttaUITests/AnaliseUITests.swift', 'app-ios/ExportOptions.plist',
    'scripts/simulador-ios.mjs', '.github/workflows/app-ios.yml'])
    assert.equal(superficie(arquivo), 'tudo', arquivo);
  // Um arquivo só já sobe o PR inteiro.
  assert.equal(nivel('app-ios/Custta/Analise/ValeAPenaView.swift', 'app-ios/Custta/Telas/PrincipalView.swift'), 'tudo');
  assert.equal(nivel('calc.js', '.github/workflows/app-ios.yml'), 'tudo');
});

test('o que não dispara o workflow não muda o nível', () => {
  for (const arquivo of ['docs/plans/2026-11-24-app-nativo-etapa4-marco2.md', 'styles.css', 'app.js', 'package.json',
    'tests/workflow.test.cjs', 'scripts/portoes-app-ios.mjs', 'scripts/icones-app-ios.mjs', 'ios/App/App/Info.plist',
    '.github/workflows/test.yml', 'app-ios.md', 'tests/vetores.test.mjs'])
    assert.equal(superficie(arquivo), 'fora', arquivo);
  assert.equal(nivel('docs/plans/checklist.md', 'app-ios/Custta/Analise/Anel.swift'), 'telas');
  assert.equal(nivel('styles.css', 'calc.js'), 'nucleo');
});

test('na dúvida, tudo', () => {
  assert.deepEqual(nivelDosPortoes([]), { nivel: 'tudo', porque: ['nenhum arquivo do diff dispara o app-ios.yml'] });
  assert.equal(nivel('docs/plans/x.md', 'styles.css'), 'tudo', 'o workflow rodou e nada do diff o dispara: o diff não é o do PR');
  // O caminho entre aspas é o nome com acento que o git escapou: não casa com regra nenhuma.
  assert.equal(superficie('"app-ios/Custta/Telas/Relat\\303\\263rio.swift"'), 'tudo');
  assert.equal(superficie(''), 'tudo');
  assert.equal(nivel('calc.js', '"app-ios/Custta/Telas/Relat\\303\\263rio.swift"'), 'tudo');
});

test('o porquê traz os arquivos que decidiram o nível, até cinco', () => {
  const telas = [1, 2, 3, 4, 5, 6, 7].map(n => `app-ios/Custta/Analise/A${n}.swift`);
  const r = nivelDosPortoes(['calc.js', ...telas]);
  assert.equal(r.nivel, 'telas');
  assert.deepEqual(r.porque, telas.slice(0, 5));
  assert.equal(r.mais, 2);
  assert.deepEqual(nivelDosPortoes(['calc.js', 'app-ios/Custta/Telas/ObraView.swift']).porque, ['app-ios/Custta/Telas/ObraView.swift']);
});

test('os níveis e os caminhos que disparam são os do workflow', () => {
  assert.deepEqual(NIVEIS, ['nucleo', 'telas', 'tudo']);
  const yml = readFileSync(join(raiz, '.github', 'workflows', 'app-ios.yml'), 'utf8');
  const caminhos = [...(/\n  pull_request:\n    paths:\n((?:      - .*\n)+)/.exec(yml)?.[1] ?? '').matchAll(/- '([^']+)'/g)].map(m => m[1]);
  assert.deepEqual(caminhos, DISPARAM, 'o filtro e o app-ios.yml têm de concordar sobre o que dispara o workflow');
  // Cada caminho que dispara tem nível: nenhum fica de fora.
  for (const caminho of DISPARAM) assert.notEqual(superficie(caminho.replace('**', 'x')), 'fora', caminho);
});

// Um repositório de mentira com o commit de merge de um PR, como o checkout do `pull_request` (refs/pull/N/merge).
function repositorio(mudancas) {
  const pasta = mkdtempSync(join(tmpdir(), 'portoes-'));
  const git = (...args) => execFileSync('git', ['-c', 'user.name=teste', '-c', 'user.email=teste@exemplo.invalid', '-c',
    'commit.gpgsign=false', ...args], { cwd: pasta, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  const gravar = arquivos => {
    for (const [nome, texto] of Object.entries(arquivos)) {
      mkdirSync(dirname(join(pasta, nome)), { recursive: true });
      writeFileSync(join(pasta, nome), texto);
    }
    git('add', '-A');
  };
  git('init', '-q', '-b', 'main');
  gravar({ 'calc.js': '1\n', 'app-ios/Custta/Telas/Velha.swift': 'struct Velha {}\n', 'LEIA.md': 'a\n' });
  git('commit', '-q', '-m', 'base');
  git('switch', '-q', '-c', 'pr');
  mudancas({ gravar, git, pasta });
  git('commit', '-q', '-m', 'pr');
  git('switch', '-q', 'main');
  gravar({ 'LEIA.md': 'b\n' });
  git('commit', '-q', '-m', 'a base andou');
  git('merge', '-q', '--no-ff', '-m', 'merge do PR', 'pr');
  return { pasta, git };
}

test('lê o diff do commit de merge do PR, e não o que a base andou', () => {
  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/Custta/Analise/Anel.swift': 'struct Anel {}\n' }));
  assert.deepEqual(arquivosDoPR(pasta), ['app-ios/Custta/Analise/Anel.swift']);
  assert.equal(escolher([], pasta).nivel, 'telas');
});

test('o arquivo que sai de uma pasta compartilhada para a análise conta pelas duas', () => {
  const { pasta } = repositorio(({ git, pasta }) => {
    mkdirSync(join(pasta, 'app-ios/Custta/Analise'), { recursive: true });
    git('mv', 'app-ios/Custta/Telas/Velha.swift', 'app-ios/Custta/Analise/Velha.swift');
  });
  assert.deepEqual(arquivosDoPR(pasta).sort(), ['app-ios/Custta/Analise/Velha.swift', 'app-ios/Custta/Telas/Velha.swift']);
  assert.equal(escolher([], pasta).nivel, 'tudo');
});
test('o nome com acento chega inteiro', () => {
  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/Custta/Telas/Relatório.swift': 'struct R {}\n' }));
  assert.deepEqual(arquivosDoPR(pasta), ['app-ios/Custta/Telas/Relatório.swift']);
  assert.equal(escolher([], pasta).nivel, 'tudo');
});

test('fora de um commit de merge, ou sem git, roda tudo e diz por quê', () => {
  const { pasta, git } = repositorio(({ gravar }) => gravar({ 'calc.js': '2\n' }));
  assert.equal(escolher([], pasta).nivel, 'nucleo');
  git('switch', '-q', '--detach', 'pr');
  const semMerge = escolher([], pasta);
  assert.equal(semMerge.nivel, 'tudo');
  assert.match(semMerge.porque[0], /^o diff do PR não pôde ser lido: /);
  assert.equal(escolher([], join(tmpdir(), 'portoes-pasta-que-nao-existe')).nivel, 'tudo');
});

test('no botão, o nível pedido; sem ele ou errado, tudo', () => {
  for (const n of NIVEIS) assert.deepEqual(escolher(['--nivel', n]), { nivel: n, porque: ['pedido no botão'] });
  assert.equal(escolher(['--nivel', 'nada']).nivel, 'tudo');
  assert.equal(escolher(['--nivel', '']).nivel, 'tudo');
  assert.equal(escolher(['--nivel']).nivel, 'tudo');
});

test('a linha de comando grava o nível para o workflow', () => {
  const saida = join(mkdtempSync(join(tmpdir(), 'portoes-saida-')), 'saida');
  const resumo = saida + '-resumo';
  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/CusttaNucleo/Sources/CusttaNucleo/X.swift': 'let x = 1\n' }));
  const dito = execFileSync(process.execPath, [script], { cwd: pasta, encoding: 'utf8', env: { ...process.env, GITHUB_OUTPUT: saida, GITHUB_STEP_SUMMARY: resumo } });
  assert.equal(dito, 'portões: nucleo (app-ios/CusttaNucleo/Sources/CusttaNucleo/X.swift)\n');
  assert.equal(readFileSync(saida, 'utf8'), 'nivel=nucleo\n');
  assert.match(readFileSync(resumo, 'utf8'), /^### Portões do app nativo: nucleo\n\napp-ios\/CusttaNucleo\//);
  const noBotao = execFileSync(process.execPath, [script, '--nivel', 'telas'], { cwd: pasta, encoding: 'utf8', env: { ...process.env, GITHUB_OUTPUT: saida, GITHUB_STEP_SUMMARY: resumo } });
  assert.equal(noBotao, 'portões: telas (pedido no botão)\n');
  assert.equal(readFileSync(saida, 'utf8'), 'nivel=nucleo\nnivel=telas\n');
});
