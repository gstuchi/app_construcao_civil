'use strict';
/* A Vercel serve a raiz do repositório como está: o que não é do app sai pelo .vercelignore.
   Este teste trava os dois lados — arquivo de desenvolvimento fora do ar, e nada que o app
   web, o app nativo ou a função api/ usam fora do deploy. */
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const ler = f => readFileSync(join(raiz, f), 'utf8');
const regras = ler('.vercelignore').split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));
assert.ok(regras.every(r => r.endsWith('/') || r.startsWith('*.') || !/[*?[!]/.test(r)),
  'padrão novo no .vercelignore: ensine o casamento deste teste antes de usar');
// Mesma semântica do .gitignore para os três formatos usados: pasta/ (em qualquer nível), *.ext e caminho exato.
const ignorado = caminho => regras.some(r =>
  r.endsWith('/') ? `/${caminho}`.includes(`/${r}`)
  : r.startsWith('*.') ? caminho.endsWith(r.slice(1))
  : caminho === r);

const foraDoAr = ['CLAUDE.md', 'AGENTS.md', 'PRODUCT.md', 'README.md', 'notificacoes/README.md',
  'tests/rules.test.mjs', 'tests/browser/servidor.cjs', 'scripts/conta-demo.mjs', '.github/workflows/testes.yml',
  'firebase.json', 'firebase.test.json', '.firebaserc', 'firestore.rules', 'capacitor.config.json',
  'docs/plans/2026-10-02-blindagem-seguranca.md', 'ios/App/App/Info.plist', 'www/index.html'];
for(const f of foraDoAr) assert.ok(ignorado(f), `${f} não pode ir para produção`);

const assets = JSON.parse(/const ASSETS = (\[[^\]]*\]);/.exec(ler('sw.js'))[1].replace(/'/g, '"'))
  .map(a => a.replace(/^\.\//, '')).filter(Boolean);
const locais = html => [...ler(html).matchAll(/(?:src|href)="([^"#:]+)"/g)].map(m => m[1].replace(/^\.?\//, ''));
const doCss = [...ler('styles.css').matchAll(/url\(['"]?([^'")]+)['"]?\)/g)].map(m => m[1]).filter(u => !u.startsWith('data:'));
const daPagina = [...assets, ...locais('index.html'), ...locais('privacidade.html'), ...doCss];
const doServidor = ['sw.js', 'versao.json', 'package.json', 'package-lock.json', 'api/push-diario.js',
  'notificacoes/enviar.js', 'notificacoes/admin.js', 'notificacoes/resumo.js', 'notificacoes/fuso.js', 'calc.js', 'dados.js'];
for(const f of new Set([...daPagina, ...doServidor])) assert.ok(!ignorado(f), `${f} é usado em produção e não pode sair do deploy`);

/* notificacoes/ é código do servidor: a função api/ depende dela (não dá pra tirar do deploy),
   mas o site não serve — a Vercel redireciona antes de olhar o disco. */
const vercel = JSON.parse(ler('vercel.json'));
assert.deepStrictEqual((vercel.redirects || []).find(r => r.source === '/notificacoes/:path*'),
  { source: '/notificacoes/:path*', destination: '/', permanent: false });
assert.ok(!daPagina.some(f => f.startsWith('notificacoes/')), 'a página não pode depender de notificacoes/ (redirecionada)');

console.log('ok - deploy leva só o app: desenvolvimento fora do ar, nada do app de fora');
