'use strict';
/* Pacotes inventados (slopsquatting): a IA sugere um nome que não existe, alguém
   registra esse nome no npm e o `npm install` roda o script de instalação dele no
   Mac, onde ficam as chaves da Apple e os logins do Firebase e do GitHub. Estes
   testes não deixam dependência nova entrar sem gente conferir: lista revisada de
   pacotes diretos, lockfile só do registro oficial e script de instalação só com
   política. Nada aqui usa rede. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

const RAIZ = join(__dirname, '..');
const lerJson = rel => JSON.parse(readFileSync(join(RAIZ, rel), 'utf8'));
const lerTexto = rel => readFileSync(join(RAIZ, rel), 'utf8');

/* Cada pacote direto com o repositório conferido no registro antes de entrar
   (npm view <pacote> repository.url time.created maintainers, e os downloads da
   semana). Pacote novo: confira se existe, se o repositório é o oficial citado na
   documentação de quem recomendou, a idade e os downloads; só então anote aqui. */
const REVISADOS = {
  '.': {
    'firebase-admin': 'github.com/firebase/firebase-admin-node',
    'web-push': 'github.com/web-push-libs/web-push',
    '@capacitor-firebase/messaging': 'github.com/capawesome-team/capacitor-firebase',
    '@capacitor/app': 'github.com/ionic-team/capacitor-plugins',
    '@capacitor/cli': 'github.com/ionic-team/capacitor',
    '@capacitor/core': 'github.com/ionic-team/capacitor',
    '@capacitor/filesystem': 'github.com/ionic-team/capacitor-filesystem',
    '@capacitor/haptics': 'github.com/ionic-team/capacitor-haptics',
    '@capacitor/ios': 'github.com/ionic-team/capacitor',
    '@capacitor/share': 'github.com/ionic-team/capacitor-plugins',
    '@capacitor/splash-screen': 'github.com/ionic-team/capacitor-plugins',
    '@capacitor/status-bar': 'github.com/ionic-team/capacitor-plugins',
    '@capawesome/capacitor-apple-sign-in': 'github.com/capawesome-team/capacitor-plugins',
    '@capawesome/capacitor-google-sign-in': 'github.com/capawesome-team/capacitor-plugins',
    '@firebase/rules-unit-testing': 'github.com/firebase/firebase-js-sdk',
    '@sentry/browser': 'github.com/getsentry/sentry-javascript',
    'esbuild': 'github.com/evanw/esbuild',
    'firebase': 'github.com/firebase/firebase-js-sdk',
    'firebase-tools': 'github.com/firebase/firebase-tools',
    'playwright': 'github.com/microsoft/playwright',
  },
  'notificacoes': {
    'firebase-admin': 'github.com/firebase/firebase-admin-node',
    'web-push': 'github.com/web-push-libs/web-push',
  },
};

/* Nome do pacote pela chave do lockfile: "node_modules/a/node_modules/@b/c" → "@b/c". */
function nomeDaChave(chave){
  return chave.slice(chave.lastIndexOf('node_modules/') + 'node_modules/'.length);
}
/* Pacotes com script de instalação no lockfile que o allowScripts não cobre. */
function scriptsSemPolitica(lock, allowScripts = {}){
  const nomes = new Set();
  for(const [chave, p] of Object.entries(lock.packages || {})) if(chave && p.hasInstallScript) nomes.add(nomeDaChave(chave));
  return [...nomes].filter(n => !Object.hasOwn(allowScripts, n)).sort();
}
/* Entradas do lockfile que não são o tarball do próprio pacote no registro oficial, com hash
   sha512. Só o host não basta: `node_modules/foo` apontando para o tarball de `bar`, com a
   integridade de `bar`, também é do registro. O pacote é o `name` (alias do npm) ou o nome da chave. */
function foraDoRegistro(lock){
  return Object.entries(lock.packages || {})
    .filter(([chave, p]) => chave && !p.link &&
      !(String(p.resolved).startsWith(`https://registry.npmjs.org/${p.name ?? nomeDaChave(chave)}/-/`) &&
        String(p.integrity).startsWith('sha512-')))
    .map(([chave]) => chave);
}
/* Só faixa de versão do registro: git:, github:, file:, URL, alias npm: e "latest" pulam o lockfile revisado. */
const FAIXA = /^[~^]?\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;
/* Linhas que valem num .npmrc: sem comentário (# ou ;) e sem linha em branco. */
const linhasDoNpmrc = texto => texto.split(/\r?\n/).map(l => l.trim()).filter(l => l && !/^[#;]/.test(l));

test('funções do teste: nome com escopo e aninhado, política e registro', ()=>{
  assert.equal(nomeDaChave('node_modules/a/node_modules/@b/c'), '@b/c');
  assert.equal(nomeDaChave('node_modules/@firebase/util'), '@firebase/util');
  const lock = { packages: {
    '': {},
    'node_modules/esbuild': { hasInstallScript: true, resolved: 'https://registry.npmjs.org/esbuild/-/esbuild-0.28.2.tgz', integrity: 'sha512-x' },
    'node_modules/x/node_modules/@mal/pacote': { hasInstallScript: true, resolved: 'https://exemplo.invalid/p.tgz', integrity: 'sha1-y' },
    'node_modules/linkado': { link: true },
  } };
  assert.deepEqual(scriptsSemPolitica(lock, { esbuild: true }), ['@mal/pacote']);
  assert.deepEqual(scriptsSemPolitica(lock, { esbuild: true, '@mal/pacote': false }), [], 'negar também é política');
  assert.deepEqual(foraDoRegistro(lock), ['node_modules/x/node_modules/@mal/pacote']);
  for(const v of ['^14.3.0', '10.74.0', '~1.2.3-beta.1']) assert.ok(FAIXA.test(v), v);
  for(const v of ['github:a/b', 'git+https://x/y.git', 'file:../p', 'https://x/p.tgz', 'npm:outro@1.0.0', 'latest', '*', '>=1.0.0']) assert.ok(!FAIXA.test(v), v);
});

test('funções do teste: .npmrc só vale com a linha estrita e mais nada', ()=>{
  const ESTRITO = ['strict-allow-scripts=true'];
  assert.deepEqual(linhasDoNpmrc('# c\n; d\n\n  strict-allow-scripts=true  \r\n'), ESTRITO, 'comentário, linha em branco e fim de linha CRLF não contam');
  for(const texto of [
    'strict-allow-scripts=true\ndangerously-allow-all-scripts=true\n',
    'strict-allow-scripts=true\nstrict-allow-scripts=false\n',
    'strict-allow-scripts=true\nallow-scripts=esbuild\n',
    'strict-allow-scripts=false\n',
    'strict-allow-scripts=true # e o resto?\n',
    '# strict-allow-scripts=true\n',
    '',
  ]) assert.notDeepEqual(linhasDoNpmrc(texto), ESTRITO, JSON.stringify(texto));
});

test('funções do teste: registro só aceita o tarball do próprio pacote', ()=>{
  const reg = 'https://registry.npmjs.org';
  const entrada = (resolved, extra = {}) => ({ resolved, integrity: 'sha512-x', ...extra });
  const passam = {
    'node_modules/esbuild': entrada(`${reg}/esbuild/-/esbuild-0.28.2.tgz`),
    'node_modules/@firebase/util': entrada(`${reg}/@firebase/util/-/util-1.15.3.tgz`),
    'node_modules/a/node_modules/@b/c': entrada(`${reg}/@b/c/-/c-1.0.0.tgz`),
    // alias: a chave é o apelido e o name é o pacote de verdade, que dá o tarball
    'node_modules/string-width-cjs': entrada(`${reg}/string-width/-/string-width-4.2.3.tgz`, { name: 'string-width' }),
    'node_modules/@x/apelido': entrada(`${reg}/@y/real/-/real-1.0.0.tgz`, { name: '@y/real' }),
    'node_modules/linkado': { link: true },
  };
  const reprovam = {
    // tarball (e integridade) de outro pacote do registro: o nome da chave engana quem só olha o host
    'node_modules/foo': entrada(`${reg}/bar/-/bar-1.0.0.tgz`),
    'node_modules/@firebase/util': entrada(`${reg}/util/-/util-1.15.3.tgz`),
    // nome que só começa igual: lib não pode usar o tarball de lib-evil
    'node_modules/lib': entrada(`${reg}/lib-evil/-/lib-evil-1.0.0.tgz`),
    // alias cujo tarball é o do apelido, e não o do pacote que o name diz ser
    'node_modules/apelido': entrada(`${reg}/apelido/-/apelido-1.0.0.tgz`, { name: 'real' }),
    'node_modules/velho': { resolved: `${reg}/velho/-/velho-1.0.0.tgz`, integrity: 'sha1-y' },
    'node_modules/sem-integridade': { resolved: `${reg}/sem-integridade/-/sem-integridade-1.0.0.tgz` },
    'node_modules/sem-resolved': { integrity: 'sha512-x' },
    // host que só começa igual ao do registro
    'node_modules/falso': entrada('https://registry.npmjs.org.exemplo.invalid/falso/-/falso-1.0.0.tgz'),
  };
  for(const [chave, p] of Object.entries(passam))
    assert.deepEqual(foraDoRegistro({ packages: { '': {}, [chave]: p } }), [], `${chave} devia passar`);
  for(const [chave, p] of Object.entries(reprovam))
    assert.deepEqual(foraDoRegistro({ packages: { '': {}, [chave]: p } }), [chave], `${chave} devia reprovar`);
});

for(const dir of Object.keys(REVISADOS)){
  const em = rel => dir === '.' ? rel : `${dir}/${rel}`;
  const naPasta = dir === '.' ? '' : `cd ${dir}; `;
  const pkg = lerJson(em('package.json'));
  const lock = lerJson(em('package-lock.json'));
  const deps = { ...pkg.dependencies, ...pkg.devDependencies, ...pkg.optionalDependencies, ...pkg.peerDependencies };

  test(`${em('package.json')}: todo pacote direto foi conferido no registro`, ()=>{
    const novos = Object.keys(deps).filter(n => !Object.hasOwn(REVISADOS[dir], n)).sort();
    assert.deepEqual(novos, [], 'pacote sem conferência: confira no npm (existe? repositório oficial? idade? downloads?) e anote em REVISADOS com o repositório');
    const sairam = Object.keys(REVISADOS[dir]).filter(n => !Object.hasOwn(deps, n)).sort();
    assert.deepEqual(sairam, [], 'saiu do package.json: tire de REVISADOS');
  });
  test(`${em('package.json')}: dependência só por faixa de versão do registro`, ()=>{
    assert.deepEqual(Object.entries(deps).filter(([, v]) => !FAIXA.test(v)).map(([n, v]) => `${n}@${v}`), []);
  });
  test(`${em('package-lock.json')}: tudo do registro oficial, tarball do próprio pacote, com hash sha512`, ()=>{
    assert.ok(Object.keys(lock.packages).length > 100, 'lockfile quase vazio não prova nada');
    assert.deepEqual(foraDoRegistro(lock), [],
      'entrada que não é https://registry.npmjs.org/<pacote>/-/… com integridade sha512: confira o resolved e o integrity');
  });
  test(`${em('package.json')}: script de instalação só roda com política no allowScripts`, ()=>{
    assert.deepEqual(scriptsSemPolitica(lock, pkg.allowScripts), [],
      `script de instalação sem política. Rode: ${naPasta}npm ci --ignore-scripts; npm install-scripts ls; leia o script; npm install-scripts approve --no-allow-scripts-pin <pacote> (ou deny). Sem o --ignore-scripts o npm ci estrito para antes de instalar e o ls não vê nada. Nunca use --dangerously-allow-all-scripts`);
    const comScript = new Set(Object.entries(lock.packages).filter(([c, p]) => c && p.hasInstallScript).map(([c]) => nomeDaChave(c)));
    assert.deepEqual(Object.keys(pkg.allowScripts || {}).filter(n => !comScript.has(n)), [],
      `allowScripts com pacote que não tem mais script. Rode no Mac: ${naPasta}npm ci --ignore-scripts; npm install-scripts prune (o prune só vale com node_modules instalado: sem ele apaga todas as aprovações; fora do macOS tira também o fsevents)`);
    for(const [n, v] of Object.entries(pkg.allowScripts || {})){
      assert.equal(typeof v, 'boolean', `${n}: aprovação é true ou false`);
      assert.ok(!/.@/.test(n), `${n}: aprovação por nome, sem versão, para versão nova do Dependabot não travar`);
    }
  });
  test(`${em('.npmrc')}: npm 11 barra script de instalação não revisado, e nada mais no arquivo`, ()=>{
    assert.deepEqual(linhasDoNpmrc(lerTexto(em('.npmrc'))), ['strict-allow-scripts=true'],
      'o .npmrc só pode ter strict-allow-scripts=true: dangerously-allow-all-scripts, allow-scripts ou strict-allow-scripts=false numa linha a mais desligam a trava. Para destravar um install, pare e avise o Giovani');
  });
}

test('CI confere a assinatura do registro de tudo que instalou', ()=>{
  const ci = lerTexto('.github/workflows/testes.yml');
  assert.match(ci, /^\s*- run: npm audit signatures\s*$/m);
  assert.match(ci, /^\s*- run: npm audit signatures --prefix notificacoes\s*$/m);
  assert.ok(ci.indexOf('npm audit signatures') > ci.indexOf('npm ci --prefix notificacoes'), 'assinatura se confere depois de instalar');
});
