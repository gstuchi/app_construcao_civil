/* O CACHE do sw.js tem de subir quando o ASSETS muda: sem isso, quem já instalou o app
   continua com o retrato velho offline. A CI dos PRs roda o scripts/cache-do-sw.mjs contra a base. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { conferirCache, lerSw } from '../scripts/cache-do-sw.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const BASE = { versao: 73, assets: ['./', './index.html', './app.js'] };
const sw = (versao, assets) =>
  `const CACHE = 'obras-v${versao}';\nconst ASSETS = [${assets.map(a => `'${a}'`).join(', ')}];\n`;

test('lê o CACHE e o ASSETS do sw.js do repositório', () => {
  const lido = lerSw(readFileSync(join(raiz, 'sw.js'), 'utf8'));
  assert.ok(Number.isInteger(lido?.versao) && lido.versao > 0, `CACHE sem número: ${lido?.versao}`);
  for(const a of ['./', './index.html', './app.js', './styles.css']){
    assert.ok(lido.assets.includes(a), `ASSETS sem ${a}`);
  }
});

test('ASSETS igual passa, com o CACHE igual ou maior, e a ordem não conta', () => {
  for(const atual of [
    { versao: 73, assets: [...BASE.assets] },
    { versao: 74, assets: [...BASE.assets] },
    { versao: 73, assets: ['./app.js', './', './index.html'] },
  ]){
    const r = conferirCache(BASE, atual);
    assert.equal(r?.ok, true, r?.texto);
    assert.match(r.texto, /ASSETS igual/);
  }
});

test('arquivo novo no ASSETS sem subir o CACHE reprova e diz para quanto subir', () => {
  const r = conferirCache(BASE, { versao: 73, assets: [...BASE.assets, './novo.js'] });
  assert.equal(r?.ok, false);
  assert.match(r.texto, /entrou \.\/novo\.js/);
  assert.match(r.texto, /Suba para obras-v74\./);
});

test('arquivo que sai do ASSETS sem subir o CACHE reprova', () => {
  const r = conferirCache(BASE, { versao: 73, assets: ['./', './index.html'] });
  assert.equal(r?.ok, false);
  assert.match(r.texto, /saiu \.\/app\.js/);
  assert.match(r.texto, /Suba para obras-v74\./);
});

test('ASSETS mudou e o CACHE subiu: passa, e o texto diz o que mudou', () => {
  const r = conferirCache(BASE, { versao: 74, assets: ['./', './index.html', './novo.js'] });
  assert.equal(r?.ok, true, r?.texto);
  assert.match(r.texto, /obras-v73 → obras-v74/);
  assert.match(r.texto, /entrou \.\/novo\.js; saiu \.\/app\.js/);
});

test('a versão compara como número: obras-v99 → obras-v100 passa', () => {
  const r = conferirCache(lerSw(sw(99, ['./'])), lerSw(sw(100, ['./', './novo.js'])));
  assert.equal(r?.ok, true, r?.texto);
});

test('CACHE que desce reprova, mesmo com o ASSETS igual: revert de um PR que subiu o CACHE', () => {
  const revert = conferirCache({ versao: 74, assets: [...BASE.assets, './novo.js'] }, BASE);
  assert.equal(revert?.ok, false);
  assert.match(revert.texto, /desceu.*obras-v75/);
  const soDesceu = conferirCache(BASE, { versao: 72, assets: [...BASE.assets] });
  assert.equal(soDesceu?.ok, false);
  assert.match(soDesceu.texto, /desceu.*obras-v74/);
});

test('sw.js fora do formato para com erro que aponta este script', () => {
  assert.throws(() => lerSw("const CACHE = 'custta-1';\nconst ASSETS = ['./'];\n"), /scripts\/cache-do-sw\.mjs/);
  assert.throws(() => lerSw("const CACHE = 'obras-v1';\n"), /scripts\/cache-do-sw\.mjs/);
});

test('pela linha de comando, contra a base no git: reprova sem subir o CACHE e passa subindo', () => {
  const repo = realpathSync(mkdtempSync(join(tmpdir(), 'cache-do-sw-')));
  /* Chamado por um caminho com symlink, o argv[1] fica com o symlink e o import.meta.url vem
     resolvido: sem o realpath, o script não se reconhecia e saía 0 sem conferir nada. */
  const atalho = `${repo}-atalho`;
  symlinkSync(repo, atalho, 'dir');
  try{
    mkdirSync(join(repo, 'scripts'));
    copyFileSync(join(raiz, 'scripts', 'cache-do-sw.mjs'), join(repo, 'scripts', 'cache-do-sw.mjs'));
    const git = (...args) => execFileSync('git', ['-c', 'init.defaultBranch=main', '-c', 'commit.gpgsign=false',
      '-c', 'user.name=Teste', '-c', 'user.email=teste@exemplo.invalid', ...args], { cwd: repo, stdio: 'pipe' });
    writeFileSync(join(repo, 'sw.js'), sw(5, ['./', './index.html']));
    git('init', '-q');
    git('add', '.');
    git('commit', '-q', '-m', 'base');
    const rodarPor = (pasta, ...args) =>
      spawnSync(process.execPath, [join(pasta, 'scripts', 'cache-do-sw.mjs'), ...args], { encoding: 'utf8' });
    const rodar = (...args) => rodarPor(repo, ...args);

    writeFileSync(join(repo, 'sw.js'), sw(5, ['./', './index.html', './novo.js']));
    const semSubir = rodar('HEAD');
    assert.equal(semSubir.status, 1, semSubir.stderr);
    assert.match(semSubir.stderr, /sw\.js contra HEAD: .*entrou \.\/novo\.js.*Suba para obras-v6\./);
    const peloAtalho = rodarPor(atalho, 'HEAD');
    assert.equal(peloAtalho.status, 1, `pelo symlink, o script tem de conferir igual: ${peloAtalho.stdout}${peloAtalho.stderr}`);

    writeFileSync(join(repo, 'sw.js'), sw(6, ['./', './index.html', './novo.js']));
    const subindo = rodar('HEAD');
    assert.equal(subindo.status, 0, subindo.stderr);
    assert.match(subindo.stdout, /sw\.js contra HEAD: CACHE obras-v5 → obras-v6, ASSETS mudou \(entrou \.\/novo\.js\): em dia\./);

    const semBase = rodar();
    assert.equal(semBase.status, 2, 'sem a base, explica o uso');
    assert.match(semBase.stderr, /uso: node scripts\/cache-do-sw\.mjs/);
    assert.equal(rodar('-x').status, 2, 'ref com hífen viraria opção do git show');
    const baseQueNaoExiste = rodar('ramo-que-nao-existe');
    assert.equal(baseQueNaoExiste.status, 1, 'base que não existe reprova: a CI nunca passa calada');
  }finally{
    rmSync(atalho, { force: true });
    rmSync(repo, { recursive: true, force: true });
  }
});
