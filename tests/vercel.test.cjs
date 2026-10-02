'use strict';
/* A Vercel serve a raiz do repositório como está: o que não é do app sai pelo .vercelignore.
   O próprio git julga as regras (mesma semântica do .vercelignore) e o teste trava os dois
   lados: todo arquivo versionado ou é usado em produção, ou sai do deploy. */
const assert = require('assert');
const { readFileSync, readdirSync } = require('fs');
const { execFileSync } = require('child_process');
const path = require('path');

const raiz = path.join(__dirname, '..');
const ler = f => readFileSync(path.join(raiz, f), 'utf8');
const git = (...args) => execFileSync('git', args, { cwd: raiz, encoding: 'utf8' }).split('\n').filter(Boolean);
const versionados = git('ls-files', '-c');
const foraDoDeploy = new Set(git('ls-files', '-c', '-i', '--exclude-from=.vercelignore'));

/* O que a página usa: o precache do sw.js (também é o que o build-www copia para o app nativo),
   src/href dos HTML e url() dos CSS. */
const semPrefixo = u => u.replace(/^\.?\//, '');
const bloco = /const ASSETS = (\[[^\]]*\]);/.exec(ler('sw.js'));
assert.ok(bloco, 'sw.js mudou o formato do ASSETS: ajuste este teste e o scripts/build-www.mjs');
const assets = JSON.parse(bloco[1].replace(/'/g, '"')).map(semPrefixo).filter(Boolean);
const doHtml = f => [...ler(f).matchAll(/(?:src|href)="([^"#:]+)"/g)].map(m => semPrefixo(m[1])).filter(Boolean);
const doCss = f => [...ler(f).matchAll(/url\(['"]?([^'")]+)['"]?\)/g)].map(m => m[1])
  .filter(u => !u.startsWith('data:')).map(semPrefixo);
const daPagina = new Set([...assets, ...doHtml('index.html'), ...doHtml('privacidade.html'),
  ...doCss('styles.css'), ...doCss('privacidade.css')]);

/* O que a função api/ carrega: fecho dos require relativos a partir de api/*.js. */
const doServidor = new Set();
const fila = readdirSync(path.join(raiz, 'api')).filter(f => f.endsWith('.js')).map(f => `api/${f}`);
while(fila.length){
  const f = fila.shift();
  if(doServidor.has(f)) continue;
  doServidor.add(f);
  for(const m of ler(f).matchAll(/require\('(\.{1,2}\/[^']+)'\)/g)) fila.push(path.posix.join(path.posix.dirname(f), m[1]));
}

/* Sobe sem ser referenciado: a Vercel precisa (package*.json instala as dependências da função;
   vercel.json, .vercelignore e .gitignore ela lê e não serve), o app busca por código
   (sw.js pelo pwa.js, versao.json pelo app nativo) ou é licença (a OFL acompanha a fonte). */
const tambemSobe = ['package.json', 'package-lock.json', 'vercel.json', '.vercelignore', '.gitignore',
  'sw.js', 'versao.json', 'LICENSE', 'fontes/OFL.txt', 'vendor/firebase/LICENSE', 'vendor/sentry/LICENSE'];

const usados = new Set([...daPagina, ...doServidor, ...tambemSobe]);
for(const f of usados){
  assert.ok(versionados.includes(f), `${f} é usado em produção mas não está no repositório`);
  assert.ok(!foraDoDeploy.has(f), `${f} é usado em produção e não pode sair do deploy`);
}
/* notificacoes/ sobe (a função depende dela), mas não é servida: o vercel.json redireciona. */
const redirecionado = f => f.startsWith('notificacoes/');
for(const f of versionados){
  if(usados.has(f) || redirecionado(f)) continue;
  assert.ok(foraDoDeploy.has(f),
    `${f} iria para produção: se é de desenvolvimento, ponha no .vercelignore; se o app usa, referencie ou liste em tambemSobe`);
}

const vercel = JSON.parse(ler('vercel.json'));
assert.deepStrictEqual((vercel.redirects || []).find(r => r.source === '/notificacoes/:path*'),
  { source: '/notificacoes/:path*', destination: '/', permanent: false });
assert.ok(![...daPagina].some(redirecionado), 'a página não pode depender de notificacoes/ (redirecionada)');

console.log('ok - deploy leva só o app: desenvolvimento fora do ar, nada do app de fora');
