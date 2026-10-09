'use strict';
/* Guardas do app nativo (app-ios/) que o Xcode não confere sozinho: formato do projeto, bundle,
   versão e plataforma, assinatura, pacotes travados, o que vem do app de hoje (ios/App/App),
   cores por token e os scripts dos testes locais. Sem rede e sem Xcode: roda no test:unit. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync, readdirSync, statSync } = require('node:fs');
const { join } = require('node:path');
const { execFileSync } = require('node:child_process');

const RAIZ = join(__dirname, '..');
const ler = p => readFileSync(join(RAIZ, p), 'utf8');
const PBX = 'app-ios/Custta.xcodeproj/project.pbxproj';
const RESOLVED = 'app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved';

/* Blocos de build settings do alvo Custta (os que apontam para Custta/Info.plist), por nome. */
function configsDoApp(){
  const blocos = [...ler(PBX).matchAll(/isa = XCBuildConfiguration;\s*buildSettings = \{([\s\S]*?)\};\s*name = (\w+);/g)];
  return Object.fromEntries(blocos.filter(m => m[1].includes('INFOPLIST_FILE = Custta/Info.plist;')).map(m => [m[2], m[1]]));
}

function arquivosSwift(pasta){
  const r = [];
  for(const nome of readdirSync(join(RAIZ, pasta))){
    const rel = join(pasta, nome);
    if(statSync(join(RAIZ, rel)).isDirectory()) r.push(...arquivosSwift(rel));
    else if(nome.endsWith('.swift')) r.push(rel);
  }
  return r;
}

test('projeto no formato do Xcode 16+ (pastas sincronizadas), que o Xcode 26 da CI abre', () => {
  const pbx = ler(PBX);
  assert.match(pbx, /objectVersion = 77;/, 'abrir e salvar num Xcode mais novo pode subir o formato e quebrar a CI (Xcode 26)');
  assert.match(pbx, /preferredProjectObjectVersion = 77;/);
  for(const pasta of ['Custta', 'CusttaTests', 'CusttaUITests'])
    assert.match(pbx, new RegExp(`isa = PBXFileSystemSynchronizedRootGroup;[^}]*path = ${pasta};`), `pasta sincronizada ${pasta}`);
});

test('app: bundle br.com.custta.app, versão 2.0, iOS 26, só iPhone e só retrato', () => {
  const configs = configsDoApp();
  assert.deepEqual(Object.keys(configs).sort(), ['Debug', 'Release']);
  for(const [nome, c] of Object.entries(configs)){
    assert.match(c, /PRODUCT_BUNDLE_IDENTIFIER = br\.com\.custta\.app;/, nome);
    assert.match(c, /MARKETING_VERSION = 2\.0;/, nome);
    assert.match(c, /TARGETED_DEVICE_FAMILY = 1;/, nome);
    assert.match(c, /INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;/, nome);
    assert.match(c, /CODE_SIGN_ENTITLEMENTS = Custta\/Custta\.entitlements;/, nome);
  }
  const pbx = ler(PBX);
  const alvos = [...pbx.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);/g)].map(m => m[1]);
  assert.ok(alvos.length >= 2 && alvos.every(v => v === '26.0'), `iOS mínimo 26.0: ${alvos}`);
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2"'), 'só iPhone');
});

test('Release assina com o perfil App Store e push de produção; Debug assina sozinho', () => {
  const { Debug, Release } = configsDoApp();
  assert.match(Release, /CODE_SIGN_STYLE = Manual;/);
  assert.match(Release, /PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";/);
  assert.match(Release, /"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "Apple Distribution";/);
  assert.match(Release, /APS_ENVIRONMENT = production;/);
  assert.match(Debug, /CODE_SIGN_STYLE = Automatic;/);
  assert.match(Debug, /APS_ENVIRONMENT = development;/);
  assert.match(ler(PBX), /DEVELOPMENT_TEAM = 4S7JKDKN27;/);
});

test('pacotes: só Firebase e GoogleSignIn, em versão exata, e o Package.resolved bate', () => {
  const pbx = ler(PBX);
  assert.doesNotMatch(pbx, /upToNext(Major|Minor)Version|versionRange|minimumVersion/, 'pacote de terceiros só por versão exata');
  const remotos = [...pbx.matchAll(/repositoryURL = "([^"]+)";\s*requirement = \{\s*kind = (\w+);\s*version = ([\d.]+);/g)]
    .map(m => ({ url: m[1], tipo: m[2], versao: m[3] }));
  assert.deepEqual(remotos.map(r => r.url).sort(), ['https://github.com/firebase/firebase-ios-sdk.git', 'https://github.com/google/GoogleSignIn-iOS']);
  for(const r of remotos) assert.equal(r.tipo, 'exactVersion', `${r.url} preso por versão exata`);
  assert.deepEqual([...new Set([...pbx.matchAll(/isa = XCSwiftPackageProductDependency;[^}]*productName = (\w+);/g)].map(m => m[1]))].sort(),
    ['CusttaNucleo', 'FirebaseAuth', 'FirebaseFirestore', 'GoogleSignIn']);
  assert.match(pbx, /isa = XCLocalSwiftPackageReference;\s*relativePath = CusttaNucleo;/);

  const pins = JSON.parse(ler(RESOLVED)).pins;
  for(const r of remotos){
    const id = r.url.split('/').pop().replace(/\.git$/, '').toLowerCase();
    assert.equal(pins.find(p => p.identity === id)?.state.version, r.versao, `${id} no Package.resolved`);
  }
  // Mesma regra do app de hoje (tests/workflow.test.cjs): dono revisado, versão e commit, nunca branch.
  const DONOS = new Set(['firebase', 'google', 'openid', 'googleads']);
  for(const p of pins){
    const dono = /^https:\/\/github\.com\/([^/]+)\//.exec(p.location)?.[1];
    assert.ok(DONOS.has(dono), `${p.identity}: dono ${dono} não revisado`);
    assert.match(p.state.revision, /^[0-9a-f]{40}$/, `${p.identity} preso por commit`);
    assert.ok(p.state.version, `${p.identity} preso por versão`);
  }
});

test('o app nativo não leva o Sentry', () => {
  assert.doesNotMatch(ler(PBX), /sentry/i);
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), /import Sentry|SentrySDK/, f);
});

test('reaproveita do app de hoje: Firebase, entitlements e o esquema de URL do Google', () => {
  // Enquanto ios/ existir (até a remoção do Capacitor), as cópias não podem divergir.
  assert.equal(ler('app-ios/Custta/GoogleService-Info.plist'), ler('ios/App/App/GoogleService-Info.plist'));
  assert.equal(ler('app-ios/Custta/Custta.entitlements'), ler('ios/App/App/App.entitlements'));
  const google = ler('app-ios/Custta/GoogleService-Info.plist');
  const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
  const info = ler('app-ios/Custta/Info.plist');
  assert.equal(info.match(/<key>GIDClientID<\/key>\s*<string>([^<]+)<\/string>/)?.[1], valor('CLIENT_ID'));
  assert.ok(info.includes(`<string>${valor('REVERSED_CLIENT_ID')}</string>`), 'sem o esquema o login do Google derruba o app');
});

test('ícone 1024×1024 sem canal alfa', () => {
  const png = readFileSync(join(RAIZ, 'app-ios/Custta/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png'));
  assert.equal(png.toString('ascii', 12, 16), 'IHDR');
  assert.equal(png.readUInt32BE(16), 1024);
  assert.equal(png.readUInt32BE(20), 1024);
  assert.equal(png[25], 2, 'a App Store recusa ícone com canal alfa (ITMS-90717)');
});

test('scheme compartilhado Custta com o app e os dois alvos de teste', () => {
  const xml = ler('app-ios/Custta.xcodeproj/xcshareddata/xcschemes/Custta.xcscheme');
  for(const alvo of ['Custta', 'CusttaTests', 'CusttaUITests']) assert.match(xml, new RegExp(`BlueprintName = "${alvo}"`), alvo);
  assert.match(xml, /ReferencedContainer = "container:Custta\.xcodeproj"/);
});

test('manifesto de privacidade: sem rastreamento, UserDefaults pelo motivo certo e os dados da política', () => {
  const m = ler('app-ios/Custta/PrivacyInfo.xcprivacy');
  assert.match(m, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
  assert.match(m, /<key>NSPrivacyTrackingDomains<\/key>\s*<array\/>/);
  assert.match(m, /NSPrivacyAccessedAPICategoryUserDefaults<\/string>[\s\S]*?<string>CA92\.1<\/string>/, '@AppStorage e a marca de limpeza usam UserDefaults');
  // Os mesmos dados da política de privacidade do site (privacidade.html); o token do FCM entra na etapa 5.
  for(const tipo of ['EmailAddress', 'Name', 'UserID', 'OtherUserContent', 'OtherDataTypes'])
    assert.match(m, new RegExp(`NSPrivacyCollectedDataType${tipo}<`), `dado coletado ${tipo}`);
  assert.doesNotMatch(m, /<key>NSPrivacyCollectedDataTypeTracking<\/key>\s*<true\/>/, 'nada coletado para rastrear');
});

test('cores só por tokens: nenhuma cor solta no código do app', () => {
  const solta = /\bColor\s*\(\s*(red|hue|white|\.sRGB|\.displayP3|uiColor)\b|\bUIColor\s*\(\s*(red|white|hue|displayP3)\b|#colorLiteral|\bColor\.(red|green|blue|orange|yellow|pink|purple|black|white|gray|brown|cyan|mint|indigo|teal)\b|\.foreground(Style|Color)\(\s*\.(red|green|blue|orange|yellow|pink|purple|black|white|gray)\b/;
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), solta, `${f}: use paleta.cor(.token)`);
});

test('catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da Paleta', () => {
  execFileSync(process.execPath, ['scripts/cores-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
  const paleta = ler('app-ios/Custta/Identidade/Paleta.swift');
  const enumToken = paleta.slice(paleta.indexOf('enum Token'), paleta.indexOf('}', paleta.indexOf('enum Token')));
  const tokens = [...enumToken.matchAll(/case \w+ = "(\w+)"/g)].map(m => m[1]).sort();
  const tabela = ler('scripts/cores-app-ios.mjs');
  for(const pele of ['Esmeralda', 'Azul']){
    const bloco = tabela.slice(tabela.indexOf(`${pele}: {`), tabela.indexOf('}', tabela.indexOf(`${pele}: {`)));
    assert.deepEqual([...bloco.matchAll(/^\s+(\w+): \['/gm)].map(m => m[1]).sort(), tokens, `tokens da pele ${pele}`);
  }
});

test('aurora nas mesmas cores do site, nos quatro combos', async () => {
  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const css = ler('styles.css');
  const combos = { Esmeralda: [':root{', 'html[data-theme="light"]{'], Azul: ['html[data-skin="azul"]{', 'html[data-skin="azul"][data-theme="light"]{'] };
  const hex = rgb => '#' + rgb.split(',').map(n => Number(n).toString(16).padStart(2, '0').toUpperCase()).join('');
  for(const [pele, [escuro, claro]] of Object.entries(combos)){
    for(const [lado, seletor] of [[0, escuro], [1, claro]]){
      const bloco = css.slice(css.indexOf(seletor + '\n    --aurora-1'));
      for(const n of [1, 2, 3, 4])
        assert.equal(CORES[pele][`Aurora${n}`][lado], hex(bloco.match(new RegExp(`--aurora-${n}:([\\d,]+);`))[1]), `${pele} Aurora${n}`);
    }
  }
});

test('texto sobre sólido fecha 4,5:1 nos quatro combos', async () => {
  const { CORES, PARES_SOLIDOS } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const linear = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  const luminancia = hex => {
    const [r, g, b] = [1, 3, 5].map(i => linear(parseInt(hex.slice(i, i + 2), 16) / 255));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  for(const [pele, tokens] of Object.entries(CORES)){
    for(const [lado, nome] of [[0, 'escuro'], [1, 'claro']]){
      for(const [texto, fundo] of PARES_SOLIDOS){
        const [a, b] = [luminancia(tokens[texto][lado]), luminancia(tokens[fundo][lado])];
        const razao = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
        assert.ok(razao >= 4.5, `${pele} ${nome}: ${texto} sobre ${fundo} fica em ${razao.toFixed(2)}:1`);
      }
    }
  }
});

test('ícones em dia com o icons.js do site', () => {
  execFileSync(process.execPath, ['scripts/icones-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
});
