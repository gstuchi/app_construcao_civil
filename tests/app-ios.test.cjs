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
  const sistema = '(red|green|blue|orange|yellow|pink|purple|black|white|gray|brown|cyan|mint|indigo|teal|primary|secondary)';
  const solta = new RegExp(String.raw`\bColor\s*\(\s*(red|hue|white|\.sRGB|\.displayP3|uiColor|\.system\w+)\b|\bUIColor\s*\(\s*(red|white|hue|displayP3)\b|\bUIColor\.(${sistema}|label|system\w+)\b|#colorLiteral|\bColor\.${sistema}\b|\.(foreground(Style|Color)|background|fill|stroke|strokeBorder|border|tint)\(\s*\.${sistema}\b|\.shadow\(\s*color:\s*\.${sistema}\b`);
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

test('cores de base iguais às do site, nos quatro combos', async () => {
  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const css = ler('styles.css');
  const combos = { Esmeralda: [':root{', 'html[data-theme="light"]{'], Azul: ['html[data-skin="azul"]{', 'html[data-skin="azul"][data-theme="light"]{'] };
  const site = { Fundo: 'bg', Superficie: 'surface-solid', Linha: 'line', Texto: 'text', TextoSecundario: 'muted', Marca: 'brand',
    Destaque: 'accent', Positivo: 'profit', Alerta: 'warn', Negativo: 'red', SobreMarca: 'btn-ink' };
  const hex = v => '#' + (v.length === 4 ? [...v.slice(1)].map(c => c + c).join('') : v.slice(1)).toUpperCase();
  for(const [pele, [escuro, claro]] of Object.entries(combos)){
    for(const [lado, seletor] of [[0, escuro], [1, claro]]){
      const bloco = css.slice(css.indexOf(seletor), css.indexOf('}', css.indexOf(seletor)));
      for(const [token, variavel] of Object.entries(site))
        assert.equal(CORES[pele][token][lado], hex(bloco.match(new RegExp(`--${variavel}:(#[0-9a-fA-F]+);`))[1]), `${pele} ${token} (--${variavel})`);
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

test('ícones em dia com o icons.js do site', async () => {
  execFileSync(process.execPath, ['scripts/icones-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
  // O quadro do SVG (viewBox, linha e pontas) e o traço de cada ícone iguais aos do ICON() do site.
  const { USADOS, svg } = await import(join(RAIZ, 'scripts/icones-app-ios.mjs'));
  const { ICON } = require(join(RAIZ, 'icons.js'));
  const partes = s => {
    const [, abre, traco] = s.trim().match(/^<svg([^>]*)>([\s\S]*)<\/svg>$/);
    return { traco, ...Object.fromEntries([...abre.matchAll(/([\w-]+)="([^"]*)"/g)].map(m => [m[1], m[2]])) };
  };
  for(const nome of USADOS){
    const app = partes(svg(nome)), site = partes(ICON(nome));
    for(const chave of ['viewBox', 'fill', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'traco'])
      assert.equal(app[chave], site[chave], `${nome}: ${chave} diferente do ICON() do site`);
  }
});

test('globo com os mesmos continentes do globe.js', () => {
  const pares = texto => [...texto.matchAll(/\[\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\]|\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)/g)]
    .map(m => (m[1] ?? m[3]) + ',' + (m[2] ?? m[4]));
  const js = ler('globe.js'), swift = ler('app-ios/Custta/Identidade/Globo.swift');
  const doSite = pares(js.slice(js.indexOf('const CONTINENTS'), js.indexOf('];', js.indexOf('const CONTINENTS'))));
  const doApp = pares(swift.slice(swift.indexOf('static let continentes'), swift.indexOf('    ]\n', swift.indexOf('static let continentes'))));
  assert.ok(doSite.length > 150);
  assert.deepEqual(doApp, doSite);
});

test('globo desenhado como o globe.js: giro, centro, raio, halo, aro, pontos e grade', () => {
  const js = ler('globe.js'), swift = ler('app-ios/Custta/Identidade/Globo.swift'), mov = ler('app-ios/Custta/Identidade/Movimento.swift');
  const n = (texto, re) => { const m = texto.match(re); assert.ok(m, `não achei ${re}`); return m.slice(1).map(Number); };
  const paradas = (texto, re, ordem) => [...texto.matchAll(re)].flatMap(m => ordem.map(i => Number(m[i])));
  const pares = {
    'ângulo inicial e giro (rad/s)': [[...n(js, /let angle=([\d.]+)/), n(js, /\(now-last\)\*([\d.]+)/)[0] * 1000], n(swift, /let angulo = ([\d.]+) \+ ([\d.]+) \* relogio\.segundos/)],
    'centro': [n(js, /cx=W\*([\d.]+); cy=H\*([\d.]+)/), n(swift, /x: tamanho\.width \* ([\d.]+), y: tamanho\.height \* ([\d.]+)/)],
    'raio': [n(js, /R=Math\.min\(H\*([\d.]+), W\*([\d.]+)\)/), n(swift, /min\(tamanho\.height \* ([\d.]+), tamanho\.width \* ([\d.]+)\)/)],
    'halo: raios': [n(js, /createRadialGradient\(cx,cy,R\*([\d.]+),cx,cy,R\*([\d.]+)\)/), n(swift, /startRadius: r \* ([\d.]+), endRadius: r \* ([\d.]+)/)],
    'halo: paradas': [paradas(js, /addColorStop\(([\d.]+),`rgba\(\$\{C\.halo\},([\d.]+)\)`\)/g, [1, 2]), paradas(swift, /halo\.opacity\(([\d.]+)\), location: ([\d.]+)\)/g, [2, 1])],
    'aro': [[...n(js, /arc\(cx,cy,R\*([\d.]+)/), ...n(js, /\$\{C\.ring\},([\d.]+)\)/), ...n(js, /lineWidth=([\d.]+)/)],
      [...n(swift, /c\.x - r \* ([\d.]+)/), ...n(swift, /aro\.opacity\(([\d.]+)\)\), lineWidth: ([\d.]+)/)]],
    'alfa por profundidade': [n(js, /const a=bright \? ([\d.]+)\+depth\*([\d.]+) : ([\d.]+)\+depth\*([\d.]+)/),
      n(swift, /alfa = terra \? ([\d.]+) \+ profundidade \* ([\d.]+) : ([\d.]+) \+ profundidade \* ([\d.]+)/)],
    'lado por profundidade': [n(js, /const s=bright \? ([\d.]+)\+depth\*([\d.]+) : ([\d.]+)\+depth\*([\d.]+)/),
      n(swift, /lado = terra \? ([\d.]+) \+ profundidade \* ([\d.]+) : ([\d.]+) \+ profundidade \* ([\d.]+)/)],
    'hemisfério da frente, brilho e folga da tela': [[...n(js, /if\(z<([\d.]+)\)/), ...n(js, /depth>([\d.]+) \?/), ...n(js, /sx<-(\d+)\|\|sx>W\+(\d+)/)],
      [...n(swift, /guard z >= ([\d.]+)/), ...n(swift, /terra && z > ([\d.]+)/), ...n(swift, /guard sx >= -(\d+), sx <= w \+ (\d+)/)]],
    'grade do celular': [[...n(js, /innerWidth<700 \? ([\d.]+)/), ...n(js, /let lat=(-?\d+); lat<=(\d+)/), ...n(js, /max\(cosL,([\d.]+)\)/), ...n(js, /lat<(-\d+) \? true/)],
      [...n(swift, /let passo = ([\d.]+)/), ...n(swift, /var lat = (-?[\d.]+)/), ...n(swift, /while lat <= (\d+)/), ...n(swift, /max\(cosL, ([\d.]+)\)/), ...n(swift, /lat < (-\d+) \|\|/)]],
    'pixels por ponto': [n(js, /Math\.min\(([\d.]+), window\.devicePixelRatio/), n(swift, /densidade: CGFloat = ([\d.]+)/)],
    'no claro a 40%': [n(ler('styles.css'), /html\[data-theme="light"\] #globe\{opacity:([\d.]+)\}/), n(swift, /compositingGroup\(\)\.opacity\(([\d.]+)\)/)],
    '30 quadros por segundo': [n(js, /INTERVALO = 1000\/(\d+)/), n(mov, /preferred: (\d+)\)/)],
    'volta 400 ms depois da rolagem': [n(js, /setTimeout\(retomar,(\d+)\)/), n(mov, /\.milliseconds\((\d+)\)/)],
  };
  const arred = x => Math.round(x * 1e6) / 1e6;
  for(const [nome, [site, app]] of Object.entries(pares)) assert.deepEqual(app.map(arred), site.map(arred), nome);
});

test('aurora com a deriva do site: os três quadros, 26 s de ida e volta, ease-in-out', () => {
  const css = ler('styles.css'), swift = ler('app-ios/Custta/Identidade/Aurora.swift');
  assert.match(css, /animation:aurora-deriva 26s ease-in-out infinite alternate/);
  const quadro = /translate3d\((-?[\d.]+)%,(-?[\d.]+)%,0\) rotate\((-?[\d.]+)deg\) scale\(([\d.]+)\)/g;
  const doSite = [...css.slice(css.indexOf('@keyframes aurora-deriva')).matchAll(quadro)].slice(0, 3)
    .map(m => [m[1] / 100, m[2] / 100, Number(m[3]), Number(m[4])]);
  const doApp = [...swift.matchAll(/Deriva\(x: (-?[\d.]+), y: (-?[\d.]+), giro: (-?[\d.]+), escala: ([\d.]+)\)/g)]
    .map(m => m.slice(1, 5).map(Number));
  assert.equal(doSite.length, 3);
  assert.deepEqual(doApp, doSite);
  assert.match(swift, /truncatingRemainder\(dividingBy: 52\)/, 'ciclo de 52 s: 26 de ida e 26 de volta');
  assert.match(ler('app-ios/Custta/Identidade/Movimento.swift'), /static let suave = CurvaBezier\(x1: 0\.42, y1: 0, x2: 0\.58, y2: 1\)/,
    'o ease-in-out do CSS');
});

test('aurora desenhada como o #aurora do site: brilhos, base de 100°, camada, altura e máscara', () => {
  const css = ler('styles.css'), swift = ler('app-ios/Custta/Identidade/Aurora.swift');
  const regra = css.slice(css.indexOf('#aurora{'), css.indexOf('@keyframes aurora-deriva'));
  const pct = x => Math.round(x * 100);
  // No CSS o primeiro fundo fica por cima; no app os brilhos vão de baixo para cima.
  const doSite = [...regra.matchAll(/radial-gradient\((\d+)% (\d+)% at (\d+)% (\d+)%, rgba\(var\(--aurora-(\d)\),var\(--aurora-a\)\), transparent (\d+)%\)/g)]
    .map(m => [+m[1], +m[2], +m[3], +m[4], m[5] - 1, +m[6]]).reverse();
  const doApp = [...swift.slice(swift.indexOf('static let brilhos')).matchAll(/\(([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+), (\d), ([\d.]+)\)/g)]
    .slice(0, 4).map(m => [pct(m[1]), pct(m[2]), pct(m[3]), pct(m[4]), +m[5], pct(m[6])]);
  assert.equal(doSite.length, 4);
  assert.deepEqual(doApp, doSite, 'os quatro brilhos: tamanho, centro, cor e fim');
  const linear = regra.slice(regra.indexOf('linear-gradient(100deg'));
  const base = [...linear.slice(0, linear.indexOf(';')).matchAll(/rgba\(var\(--aurora-(\d)\),var\(--aurora-a\)\)(?: (\d+)%)?/g)]
    .map((m, i) => [m[1] - 1, m[2] ? +m[2] : i ? 100 : 0]);
  assert.deepEqual([...swift.matchAll(/\.init\(color: cores\[(\d)\]\.opacity\(a\), location: ([\d.]+)\)/g)].map(m => [+m[1], pct(m[2])]), base,
    'base: linear-gradient(100deg, A3, A1 35%, A2 65%, A3)');
  assert.equal(+swift.match(/let angulo = ([\d.]+) \* \.pi \/ 180/)[1], +regra.match(/linear-gradient\((\d+)deg/)[1], 'base a 100°');
  const [, cima, lado] = regra.match(/inset:-(\d+)% -(\d+)%/);
  const [, largura, altura] = swift.match(/\.frame\(width: largura \* ([\d.]+), height: altura \* ([\d.]+)\)/);
  assert.deepEqual([pct((largura - 1) / 2), pct((altura - 1) / 2)], [+lado, +cima], 'camada −30% dos lados e −15% em cima e embaixo');
  assert.equal(pct(swift.match(/geo\.size\.height \* ([\d.]+)/)[1]), +regra.match(/height:(\d+)vh/)[1], '78% da altura da tela');
  assert.equal(pct(swift.match(/fundo\.opacity\(0\), location: ([\d.]+)/)[1]), +regra.match(/linear-gradient\(to bottom,#000 (\d+)%,transparent\)/)[1],
    'some para baixo a partir de 40%');
});

test('animação própria respeita Reduzir movimento', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    if(/withAnimation|\.animation\(|\.transition\(/.test(t))
      assert.match(t, /accessibilityReduceMotion|reduzirMovimento/, `${f}: anima sem olhar o Reduzir movimento`);
    for(const m of t.matchAll(/LogoEscrito\(animado: ([^,)]+)/g))
      assert.match(m[1], /animaFundo/, `${f}: o logo se escreve sem olhar Reduzir movimento e Pouca Energia`);
  }
});

test('o logo escrito do app usa os caminhos do logo do site', () => {
  const svg = ler('index.html').match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)[0];
  const swift = ler('app-ios/Custta/Identidade/LogoEscrito.swift');
  const caminhos = [...svg.matchAll(/\sd="([^"]+)"/g)].map(m => m[1]);
  assert.ok(caminhos.length >= 16, 'caminhos do logo no index.html');
  for(const d of caminhos) assert.ok(swift.includes(`"${d}"`), `caminho do logo ausente no app: ${d.slice(0, 40)}…`);
});

test('logo escrito na ordem e nos tempos do site: letra, máscara, pena, traço, carimbo e varredura', () => {
  const svg = ler('index.html').match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)[0], css = ler('styles.css');
  const swift = ler('app-ios/Custta/Identidade/LogoEscrito.swift');
  const n = (texto, re) => { const m = texto.match(re); assert.ok(m, `não achei ${re}`); return m.slice(1).join(',').split(',').map(Number); };
  // Cada letra, na ordem do desenho, é revelada pelas penas da sua máscara (le-m0…le-m5), numeradas le-p0…le-p8.
  const mascaras = Object.fromEntries([...svg.matchAll(/<mask id="(le-m\d)"[\s\S]*?<\/mask>/g)]
    .map(m => [m[1], [...m[0].matchAll(/class="le-pena le-p(\d)" pathLength="1" d="([^"]+)"/g)]]));
  const doSite = [...svg.matchAll(/<path class="le-(neutra|tt)" mask="url\(#(le-m\d)\)" d="([^"]+)"/g)]
    .map(m => ({ glifo: m[3], penas: mascaras[m[2]].map(p => p[2]), tt: m[1] === 'tt' }));
  const doApp = [...swift.matchAll(/Letra\(glifo: "([^"]+)",\s+penas: \[([^\]]+)\],\s+tt: (true|false)\)/g)]
    .map(m => ({ glifo: m[1], penas: [...m[2].matchAll(/"([^"]+)"/g)].map(p => p[1]), tt: m[3] === 'true' }));
  assert.equal(doSite.length, 6);
  assert.deepEqual(doApp, doSite, 'as letras na ordem do site, cada uma com as penas da sua máscara');
  assert.deepEqual(Object.values(mascaras).flat().map(p => +p[1]), [0, 1, 2, 3, 4, 5, 6, 7, 8], 'penas na ordem le-p0…le-p8');
  // Os números do styles.css (duração, curva, início) e do desenho.
  const traco = i => n(css, new RegExp(`\\.le-p${i}\\{animation:leEscreve ([\\d.]+)s cubic-bezier\\(([\\d.,]+)\\) ([\\d.]+)s both\\}`));
  const carimbo = n(css, /\.le-ponto\{animation:leCarimba ([\d.]+)s cubic-bezier\(([\d.,]+)\) ([\d.]+)s both\}/);
  const varre = n(css, /\.le-varredura\{animation:leVarre ([\d.]+)s cubic-bezier\(([\d.,]+)\) ([\d.]+)s both\}/);
  const curva = nome => n(swift, new RegExp(`${nome} = CurvaBezier\\(x1: ([\\d.]+), y1: ([\\d.]+), x2: ([\\d.]+), y2: ([\\d.]+)\\)`));
  const pares = {
    'traços: início e duração (le-p0…le-p8)': [[0, 1, 2, 3, 4, 5, 6, 7, 8].flatMap(i => [traco(i)[5], traco(i)[0]]),
      [...swift.match(/static let tracos[^=]+= \[([^\]]+)\]/)[1].matchAll(/\(([\d.]+), ([\d.]+)\)/g)].flatMap(m => [+m[1], +m[2]])],
    'traços: a mesma curva nos nove': [[0, 1, 2, 3, 4, 5, 6, 7, 8].flatMap(i => traco(i).slice(1, 5)), Array(9).fill(curva('curvaDoTraco')).flat()],
    'traço: largura e dashoffset de 1,1 a 0': [[...n(css, /\.le-pena\{[^}]*stroke-width:(\d+)/), ...n(css, /leEscreve\{from\{stroke-dashoffset:([\d.]+)\}/)],
      [...n(swift, /larguraDaPena = ([\d.]+)/), ...n(swift, /let fim = 1 - ([\d.]+) \* \(1 -/)]],
    'carimbo: início, duração e curva com repique': [[carimbo[5], carimbo[0], ...carimbo.slice(1, 5)],
      [...n(swift, /carimbo = \(inicio: ([\d.]+), duracao: ([\d.]+)\)/), ...curva('curvaDoCarimbo')]],
    'vibração 120 ms depois do carimbo (auth.js)': [[carimbo[5] + n(ler('auth.js'), /'leCarimba'\) setTimeout\([^,]+, (\d+)\)/)[0] / 1000],
      n(swift, /vibracao = ([\d.]+)/)],
    'letras inteiras (le-fim)': [n(css, /\.le-fim\{animation:leAparece [\d.]+s linear ([\d.]+)s both\}/), n(swift, /inteiras = ([\d.]+)/)],
    'varredura: início, duração e curva': [[varre[5], varre[0], ...varre.slice(1, 5)],
      [...n(swift, /varredura = \(inicio: ([\d.]+), duracao: ([\d.]+)\)/), ...curva('curvaDaVarredura')]],
    'varredura: retângulo que cresce de x 1440': [n(svg, /class="le-varredura" x="(\d+)" y="(-\d+)" width="(\d+)" height="(\d+)"/),
      n(swift, /CGRect\(x: (\d+), y: (-\d+), width: (\d+) \* v, height: (\d+)\)/)],
    'degradê do tt (le-deg)': [n(svg, /id="le-deg" x1="0" y1="(-?\d+)" x2="0" y2="(-?\d+)"/),
      n(swift, /startPoint: CGPoint\(x: 0, y: (-?\d+)\), endPoint: CGPoint\(x: 0, y: (-?\d+)\)/)],
    'tt escuro some (leSome)': [n(css, /\.le-tt\{animation:leSome [\d.]+s linear ([\d.]+)s both\}/), n(swift, /static let some = ([\d.]+)/)],
    'caixa (viewBox)': [n(svg, /viewBox="(-?\d+) (-?\d+) (\d+) (\d+)"/), n(swift, /caixa = CGRect\(x: (-?\d+), y: (-?\d+), width: (\d+), height: (\d+)\)/)],
  };
  const arred = x => Math.round(x * 1e6) / 1e6;
  for(const [nome, [site, app]] of Object.entries(pares)) assert.deepEqual(app.map(arred), site.map(arred), nome);
});

test('fonte do botão do Google: Roboto Medium travada, registrada e com a licença', () => {
  const fonte = readFileSync(join(RAIZ, 'app-ios/Custta/Fontes/Roboto-Medium.ttf'));
  const hash = require('node:crypto').createHash('sha256').update(fonte).digest('hex');
  assert.equal(hash, '663bedb17df44144ea2ccf4c3a3c1853547bcfed2395ad29904502ea92c74bcb', 'Roboto v3.016 (unhinted/static) do googlefonts/roboto-3-classic');
  assert.match(ler('app-ios/Custta/Fontes/OFL-Roboto.txt'), /SIL Open Font License, Version 1\.1/);
  assert.match(ler('app-ios/Custta/Info.plist'), /<key>UIAppFonts<\/key>\s*<array>\s*<string>Roboto-Medium\.ttf<\/string>/);
});

test('ganchos dos testes e do laudo só no Debug: chave custta.* (fora tema, pele e vidro) e CUSTTA_* dentro de #if DEBUG', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const pilha = [];
    ler(f).split('\n').forEach((linha, i) => {
      const d = linha.trim();
      if(/^#if\b/.test(d)) pilha.push({ debug: /^#if\s+DEBUG\b/.test(d), ehDebug: /^#if\s+DEBUG\b/.test(d) });
      else if(/^#else\b/.test(d)){ const topo = pilha.at(-1); if(topo?.ehDebug) topo.debug = false; }
      else if(/^#endif\b/.test(d)) pilha.pop();
      else if(/"(custta\.(?!(tema|pele|vidro)")|CUSTTA_)/.test(linha))
        assert.ok(pilha.some(x => x.debug), `${f}:${i + 1}: gancho fora do #if DEBUG: ${d}`);
    });
  }
});

test('mensagem e aviso anunciados a cada texto novo, não só ao aparecer', () => {
  for(const f of arquivosSwift('app-ios/Custta'))
    assert.doesNotMatch(ler(f), /\.onAppear\s*\{\s*AccessibilityNotification\.Announcement/,
      `${f}: anuncie no .onChange(of:initial:); o 2º erro seguido não reaparece e o VoiceOver não o lê`);
});

test('escurecimento sob o vidro segue o esquema da tela: no claro, nenhum', () => {
  assert.match(ler('app-ios/Custta/Identidade/Vidro.swift'),
    /let escuro = esquema == \.dark\n[\s\S]*?paleta\.cor\(\.fundo\)\.opacity\(vidro\.escurecimento\(papel, escuro: escuro\)\)/,
    'a Superficie passa o esquema da tela ao escurecimento (o ImageRenderer não serve de guarda: o vidro dele varia)');
});

test('ícone junto de texto cresce com a letra: o dos Label, a seta da dica de entrar e o olho da senha', () => {
  // A auditoria de tipo dinâmico do Xcode só olha texto: um ícone de tamanho fixo passa por ela e vira um
  // ponto ao lado da letra grande (D7 da conferência da Tarefa 10; a legenda do gráfico e o olho, na revisão da 11).
  for(const f of arquivosSwift('app-ios/Custta'))
    for(const m of ler(f).matchAll(/icon: \{[^\n]*?\.frame\(width: ([^,]+), height: ([^)]+)\)/g))
      assert.doesNotMatch(`${m[1]} ${m[2]}`, /^\d|\s\d/, `${f}: ícone de Label em tamanho fixo (use @ScaledMetric)`);
  const dica = ler('app-ios/Custta/Telas/EntradaView.swift').match(/Text\("Role para entrar"\)\s*\n\s*Image\([^\n]*/);
  assert.ok(dica, 'a dica "Role para entrar" com a seta logo depois');
  assert.doesNotMatch(dica[0], /\.frame\(width: \d/, 'a seta da dica tem 1em no mockup: cresce com a letra (@ScaledMetric)');
  const olho = ler('app-ios/Custta/Identidade/Componentes.swift').match(/"Icones\/olho"\)\s*\n\s*\.resizable\(\)[^\n]*/);
  assert.ok(olho, 'o olho do campo de senha');
  assert.doesNotMatch(olho[0], /\.frame\(width: \d/, 'o olho da senha cresce com a letra do campo (@ScaledMetric)');
});

test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do Google e no indicador da barra', () => {
  // A auditoria de texto cortado do Xcode não vê dentro de um elemento que o VoiceOver lê inteiro (o cartão da
  // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
  // do Google (letra travada, fora da auditoria de tipo dinâmico) e o indicador de sincronização da barra.
  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao']);
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
      const dono = [...t.slice(0, m.index).matchAll(/^(?:private )?struct (\w+)/gm)].at(-1)?.[1];
      assert.ok(fixos.has(dono), `${f}: ${m[0]} em ${dono}; texto cortado se resolve deixando o texto crescer`);
    }
  }
});
